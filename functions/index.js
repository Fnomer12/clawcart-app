require("dotenv").config();

const express = require("express");
const cors = require("cors");
const OpenAI = require("openai");
const fetch = require("node-fetch");

const app = express();

app.use(cors());
app.use(express.json());

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

function extractBudget(prompt) {
  if (!prompt || typeof prompt !== "string") return null;

  const match = prompt.match(/\$?(\d{2,6})/);
  return match ? Number(match[1]) : null;
}

function toNumberOrNull(value) {
  if (typeof value === "number" && Number.isFinite(value)) return value;

  if (typeof value === "string" && value.trim() !== "") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }

  return null;
}

function getLocationConfig(location) {
  switch ((location || "US").toUpperCase()) {
    case "GH":
      return {
        countryCode: "GH",
        gl: null,
        hl: "en",
        googleDomain: "google.com",
        currencySymbol: "GH₵",
      };

    case "UK":
      return {
        countryCode: "UK",
        gl: "uk",
        hl: "en",
        googleDomain: "google.co.uk",
        currencySymbol: "£",
      };

    case "US":
    default:
      return {
        countryCode: "US",
        gl: "us",
        hl: "en",
        googleDomain: "google.com",
        currencySymbol: "$",
      };
  }
}

function cleanUrl(url) {
  if (!url || typeof url !== "string") return "";
  return url.trim();
}

function pickBestUrl(item) {
  return (
    cleanUrl(item.product_link) ||
    cleanUrl(item.link) ||
    cleanUrl(item.serpapi_link) ||
    cleanUrl(item.inline_shopping_link) ||
    ""
  );
}

function normalizeProduct(item) {
  return {
    name: item.title ?? "Unknown product",
    price:
      typeof item.extracted_price === "number" ? item.extracted_price : null,
    store: item.source ?? item.store ?? "Unknown store",
    rating: typeof item.rating === "number" ? item.rating : null,
    image: item.thumbnail ?? item.thumbnails?.[0] ?? "",
    url: pickBestUrl(item),
  };
}

async function searchProducts(query, location, minPrice, maxPrice) {
  const apiKey = process.env.SERPAPI_KEY;

  if (!apiKey) {
    throw new Error("Missing SERPAPI_KEY");
  }

  const { gl, hl, googleDomain } = getLocationConfig(location);

  const params = new URLSearchParams({
    engine: "google_shopping",
    q: query,
    api_key: apiKey,
    hl,
    google_domain: googleDomain,
  });

  if (gl) {
    params.set("gl", gl);
  }

  if (typeof minPrice === "number" && Number.isFinite(minPrice) && minPrice > 0) {
    params.set("min_price", String(Math.round(minPrice)));
  }

  if (typeof maxPrice === "number" && Number.isFinite(maxPrice) && maxPrice > 0) {
    params.set("max_price", String(Math.round(maxPrice)));
  }

  const url = `https://serpapi.com/search.json?${params.toString()}`;
  console.log("SERPAPI URL:", url.replace(apiKey, "HIDDEN_KEY"));

  const response = await fetch(url);
  const rawText = await response.text();

  console.log("SERPAPI STATUS:", response.status);
  console.log("SERPAPI BODY:", rawText);

  let data;
  try {
    data = JSON.parse(rawText);
  } catch (error) {
    throw new Error(`SerpApi returned non-JSON response: ${rawText}`);
  }

  if (!response.ok) {
    throw new Error(
      `SerpApi request failed: ${response.status} - ${data.error || rawText}`
    );
  }

  const shoppingResults = Array.isArray(data.shopping_results)
    ? data.shopping_results
    : [];

  return shoppingResults.slice(0, 8).map(normalizeProduct);
}

async function generateAIResult({
  prompt,
  location,
  minPrice,
  maxPrice,
  fetchedProducts,
}) {
  const aiResponse = await client.responses.create({
    model: "gpt-5.4-mini",
    input: [
      {
        role: "system",
        content: `
You are ClawCart AI, a shopping assistant.

You will receive:
1. the user's shopping request
2. a list of real fetched products

Your job:
- identify the category
- infer priorities from the prompt
- choose the single best product from the provided list
- explain why it is the best
- add a short reason for each product
- return valid JSON only

Return exactly this JSON shape:
{
  "category": "string",
  "budget": number | null,
  "priorities": ["string"],
  "summary": "string",
  "bestProduct": {
    "name": "string",
    "reason": "string"
  },
  "products": [
    {
      "name": "string",
      "price": number | null,
      "store": "string",
      "rating": number | null,
      "image": "string",
      "url": "string",
      "reason": "string"
    }
  ]
}

Rules:
- Return JSON only
- Do not include markdown
- Do not invent products outside the provided list
- Keep products limited to the provided list
- Choose bestProduct from the provided products
- Preserve image and url fields exactly as given
- Preserve price, store, and rating from the provided products
- If budget is not stated, use null
        `.trim(),
      },
      {
        role: "user",
        content: JSON.stringify({
          prompt,
          location,
          minPrice,
          maxPrice,
          products: fetchedProducts,
        }),
      },
    ],
  });

  const text = aiResponse.output_text?.trim();

  if (!text) {
    throw new Error("Empty response from AI");
  }

  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch (error) {
    console.log("AI RAW OUTPUT:", text);
    throw new Error("AI returned invalid JSON");
  }

  return parsed;
}

app.get("/", (req, res) => {
  res.status(200).json({
    success: true,
    message: "ClawCart backend is running",
  });
});

app.post("/recommend", async (req, res) => {
  try {
    const { prompt, location, minPrice, maxPrice } = req.body || {};

    if (!prompt || !String(prompt).trim()) {
      return res.status(400).json({
        success: false,
        error: "Prompt is required",
      });
    }

    if (!process.env.OPENAI_API_KEY) {
      return res.status(500).json({
        success: false,
        error: "Missing OPENAI_API_KEY",
      });
    }

    const cleanPrompt = String(prompt).trim();
    const normalizedLocation = (location || "US").toUpperCase();

    const parsedMinPrice = toNumberOrNull(minPrice);
    const parsedMaxPrice = toNumberOrNull(maxPrice);
    const inferredBudget = extractBudget(cleanPrompt);

    const effectiveMaxPrice =
      parsedMaxPrice !== null ? parsedMaxPrice : inferredBudget;

    const fetchedProducts = await searchProducts(
      cleanPrompt,
      normalizedLocation,
      parsedMinPrice,
      effectiveMaxPrice
    );

    if (fetchedProducts.length === 0) {
      return res.json({
        success: true,
        result: {
          category: "general",
          budget: effectiveMaxPrice ?? null,
          priorities: ["value", "quality"],
          summary: "No matching products were found for this request.",
          bestProduct: null,
          products: [],
        },
      });
    }

    const parsed = await generateAIResult({
      prompt: cleanPrompt,
      location: normalizedLocation,
      minPrice: parsedMinPrice,
      maxPrice: effectiveMaxPrice,
      fetchedProducts,
    });

    if (!Array.isArray(parsed.products)) {
      parsed.products = fetchedProducts.map((product) => ({
        ...product,
        reason: "A relevant option based on your request.",
      }));
    }

    if (
      parsed.bestProduct &&
      typeof parsed.bestProduct === "object" &&
      parsed.bestProduct.name
    ) {
      const existsInProducts = parsed.products.some(
        (product) => product.name === parsed.bestProduct.name
      );

      if (!existsInProducts && parsed.products.length > 0) {
        parsed.bestProduct = {
          name: parsed.products[0].name,
          reason: parsed.bestProduct.reason || "Top available option.",
        };
      }
    }

    return res.json({
      success: true,
      result: parsed,
    });
  } catch (error) {
    console.log("========== ERROR START ==========");
    console.log(error);
    console.log("MESSAGE:", error?.message);
    console.log("STACK:", error?.stack);
    console.log("========== ERROR END ==========");

    return res.status(500).json({
      success: false,
      error: error?.message || "Unknown error",
    });
  }
});

const PORT = 3000;

const server = app.listen(PORT, () => {
  const actualPort = server.address().port;
  console.log(`ClawCart backend running on port ${actualPort}`);
});