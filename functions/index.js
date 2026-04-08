require("dotenv").config();



const functions = require("firebase-functions");
const OpenAI = require("openai");
const fetch = require("node-fetch");


const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

function extractBudget(prompt) {
  const match = prompt.match(/\$?(\d{2,5})/);
  return match ? Number(match[1]) : null;
}

function getLocationConfig(location) {
  switch ((location || "US").toUpperCase()) {
    case "GH":
      return { gl: "gh", hl: "en" };
    case "UK":
      return { gl: "uk", hl: "en" };
    case "US":
    default:
      return { gl: "us", hl: "en" };
  }
}

async function searchProducts(query, location, minPrice, maxPrice) {
  const apiKey = process.env.SERPAPI_KEY;

  if (!apiKey) {
    throw new Error("Missing SERPAPI_KEY in functions/.env");
  }

  const { gl, hl } = getLocationConfig(location);

  const params = new URLSearchParams({
    engine: "google_shopping",
    q: query,
    api_key: apiKey,
    gl,
    hl,
  });

    if (typeof minPrice === "number" && minPrice > 0) {
    params.set("min_price", String(Math.round(minPrice)));
  }

    if (typeof maxPrice === "number" && maxPrice > 0) {
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
  } catch (e) {
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

    console.log(
  "SERP SAMPLE:",
  shoppingResults.slice(0, 2).map((item) => ({
    title: item.title,
    link: item.link,
    product_link: item.product_link,
    serpapi_link: item.serpapi_link,
    inline_shopping_link: item.inline_shopping_link,
  }))
);

return shoppingResults.slice(0, 8).map((item) => ({
  name: item.title ?? "Unknown product",
  price:
    typeof item.extracted_price === "number" ? item.extracted_price : null,
  store: item.source ?? item.store ?? "Unknown store",
  rating: typeof item.rating === "number" ? item.rating : null,
  image: item.thumbnail ?? item.thumbnails?.[0] ?? "",
  url:
    item.product_link ??
    item.link ??
    item.serpapi_link ??
    item.inline_shopping_link ??
    "",
}));
}

exports.recommend = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    const { prompt, location, minPrice, maxPrice } = req.body || {};

    if (!prompt || !prompt.trim()) {
      return res.status(400).json({ error: "Prompt is required" });
    }

    const inferredBudget = extractBudget(prompt);
    const effectiveMaxPrice =
      typeof maxPrice === "number" ? maxPrice : inferredBudget;

    const fetchedProducts = await searchProducts(
      prompt,
      location,
      typeof minPrice === "number" ? minPrice : null,
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
- understand the category
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
- If budget is not stated, use null
          `.trim(),
        },
        {
          role: "user",
          content: JSON.stringify({
            prompt,
            location: location || "US",
            minPrice: typeof minPrice === "number" ? minPrice : null,
            maxPrice: effectiveMaxPrice,
            products: fetchedProducts,
          }),
        },
      ],
    });

    const text = aiResponse.output_text?.trim();

    if (!text) {
      return res.status(500).json({
        success: false,
        error: "Empty response from AI",
      });
    }

    const parsed = JSON.parse(text);

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