
require("dotenv").config();

const express = require("express");
const cors = require("cors");
const axios = require("axios");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const SERP_API_KEY = process.env.SERPAPI_KEY;

app.get("/", (req, res) => {
  res.json({ message: "ClawCart backend is running" });
});

const countryConfig = {
  GH: {
    gl: "us",
    currencyCode: "GHS",
    currencySymbol: "GH₵",
    label: "Ghana",
    sites: {
      cars: "(site:jiji.com.gh OR site:tonaton.com)",
      fashion: "(site:jumia.com.gh OR site:jiji.com.gh)",
      groceries: "(site:jumia.com.gh OR site:melcom.com)",
      electronics: "(site:jumia.com.gh OR site:jiji.com.gh OR site:compughana.com)",
      general: "(site:jumia.com.gh OR site:jiji.com.gh OR site:tonaton.com OR site:melcom.com)"
    }
  },

  UK: {
    gl: "uk",
    currencyCode: "GBP",
    currencySymbol: "£",
    label: "United Kingdom",
    sites: {
      cars: "(site:autotrader.co.uk OR site:motors.co.uk OR site:cinch.co.uk)",
      fashion: "(site:asos.com OR site:next.co.uk OR site:marksandspencer.com)",
      groceries: "(site:tesco.com OR site:sainsburys.co.uk OR site:asda.com)",
      electronics: "(site:currys.co.uk OR site:argos.co.uk OR site:amazon.co.uk)",
      general: "(site:amazon.co.uk OR site:argos.co.uk OR site:ebay.co.uk)"
    }
  },

  US: {
    gl: "us",
    currencyCode: "USD",
    currencySymbol: "$",
    label: "United States",
    sites: {
      cars: "(site:cars.com OR site:autotrader.com OR site:cargurus.com)",
      fashion: "(site:nike.com OR site:zara.com OR site:macys.com)",
      groceries: "(site:walmart.com OR site:target.com OR site:kroger.com)",
      electronics: "(site:bestbuy.com OR site:walmart.com OR site:amazon.com)",
      general: "(site:amazon.com OR site:walmart.com OR site:target.com OR site:bestbuy.com)"
    }
  }
};

function getSearchType(prompt) {
  const text = prompt.toLowerCase();
  if (/\b(car|cars|vehicle|toyota|honda|bmw|benz|nissan)\b/i.test(text)) return "cars";
  if (/\b(shoes|shirt|dress|fashion|watch|bag)\b/i.test(text)) return "fashion";
  if (/\b(rice|oil|food|water|grocery|groceries)\b/i.test(text)) return "groceries";
  if (/\b(phone|iphone|laptop|tv|camera|tablet|computer)\b/i.test(text)) return "electronics";
  return "general";
}

function buildSearchPrompt(prompt, searchType) {
  if (searchType === "cars") return `${prompt} used cars for sale price`;
  if (searchType === "fashion") return `${prompt} buy online price`;
  if (searchType === "groceries") return `${prompt} supermarket price`;
  if (searchType === "electronics") return `${prompt} latest price buy online`;
  return `${prompt} buy online price`;
}

const rateCache = {};

function extractPrice(text) {
  if (!text) return null;

  const patterns = [
    /GH₵\s?[0-9,.]+/i,
    /GHS\s?[0-9,.]+/i,
    /₵\s?[0-9,.]+/i,
    /\$\s?[0-9,.]+/i,
    /USD\s?[0-9,.]+/i,
    /£\s?[0-9,.]+/i,
    /GBP\s?[0-9,.]+/i,
  ];

  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (match) return match[0];
  }

  return null;
}

function detectCurrency(priceText) {
  if (!priceText) return null;

  const text = priceText.toString().toUpperCase();

  if (text.includes("GH₵") || text.includes("GHS") || text.includes("₵")) {
    return "GHS";
  }

  if (text.includes("£") || text.includes("GBP")) return "GBP";
  if (text.includes("$") || text.includes("USD")) return "USD";

  return null;
}

function extractNumber(priceText) {
  if (!priceText) return null;

  const cleaned = priceText
    .toString()
    .replace(/,/g, "")
    .replace(/[^\d.]/g, "");

  const number = Number(cleaned);

  return Number.isFinite(number) ? number : null;
}

async function getRates(baseCurrency) {
  if (rateCache[baseCurrency]) return rateCache[baseCurrency];

  try {
    const response = await axios.get(
      `https://open.er-api.com/v6/latest/${baseCurrency}`,
      { timeout: 10000 }
    );

    const rates = response.data.rates || {};
    rateCache[baseCurrency] = rates;

    return rates;
  } catch (error) {
    console.log("Currency API error:", error.message);
    return {};
  }
}

async function convertPrice(priceText, targetCurrency, targetSymbol) {
  const amount = extractNumber(priceText);
  const fromCurrency = detectCurrency(priceText);

  if (!amount || !fromCurrency) {
    return {
      displayPrice: priceText || null,
      numericPrice: null,
      originalPrice: priceText || null,
    };
  }

  if (fromCurrency === targetCurrency) {
    return {
      displayPrice: `${targetSymbol}${amount.toLocaleString(undefined, {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      })}`,
      numericPrice: amount,
      originalPrice: priceText,
    };
  }

  const rates = await getRates(fromCurrency);
  const rate = rates[targetCurrency];

  if (!rate) {
    return {
      displayPrice: priceText,
      numericPrice: amount,
      originalPrice: priceText,
    };
  }

  const converted = amount * rate;

  return {
    displayPrice: `${targetSymbol}${converted.toLocaleString(undefined, {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`,
    numericPrice: converted,
    originalPrice: priceText,
  };
}

function normalizeProduct(item, sourceType = "web") {
  const price =
    item.price ||
    item.extracted_price ||
    item.price_str ||
    extractPrice(item.snippet) ||
    extractPrice(item.title) ||
    null;

  return {
    name: item.title || item.name || "Unknown product",
    price,
    originalPrice: price,
    numericPrice: extractNumber(price),
    rating: item.rating || "Marketplace",
    store: item.source || item.merchant || item.displayed_link || "Online store",
    url: item.product_link || item.link || "",
    image: item.thumbnail || item.image || item.serpapi_thumbnail || "",
    score: 0,
    badge: "Check Details",
    reason: sourceType === "shopping" ? "Live shopping result" : "Found from search"
  };
}

function removeDuplicates(products) {
  const seen = new Set();
  return products.filter((product) => {
    const key = `${product.name}-${product.store}`.toLowerCase();
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function scoreProduct(product) {
  let score = 0;
  if (product.image) score += 30;
  if (product.price) score += 30;
  if (product.url) score += 20;
  product.score = score;
  product.badge = score >= 70 ? "Best Pick" : score >= 50 ? "Good Option" : "Check Details";
}


app.post("/recommend", async (req, res) => {
  try {
    const { prompt, location = "GH", city = "", minPrice, maxPrice } = req.body;

    if (!prompt || prompt.trim() === "") {
      return res.status(400).json({ error: "Prompt is required" });
    }

    if (!SERP_API_KEY) {
      return res.status(500).json({ error: "Missing SERPAPI_KEY in .env" });
    }

    const config = countryConfig[location] || countryConfig.GH;
    const cleanPrompt = prompt.trim();
    const searchType = getSearchType(cleanPrompt) || "general";
    const locationText = city ? `${city} ${config.label}` : config.label;

    const siteFilter =
      config.sites[searchType] || config.sites.general || "";

    const searchPrompt =
      searchType === "general"
        ? `${cleanPrompt} buy online price`
        : buildSearchPrompt(cleanPrompt, searchType);

    const badWords =
      searchType === "cars"
        ? ["toy", "diecast", "hot wheels", "lego", "miniature", "model", "rc"]
        : ["case", "cover", "box", "charger", "cable", "protector", "screen", "parts", "sticker"];

    const shoppingRequest =
      searchType !== "cars"
        ? axios
            .get("https://serpapi.com/search.json", {
              params: {
                engine: "google_shopping",
                q: `${searchPrompt} ${locationText}`,
                gl: config.gl,
                hl: "en",
                api_key: SERP_API_KEY,
              },
              timeout: 15000,
            })
            .catch(() => ({ data: { shopping_results: [] } }))
        : Promise.resolve({ data: { shopping_results: [] } });

    const webRequest = axios
      .get("https://serpapi.com/search.json", {
        params: {
          engine: "google",
          q: `${searchPrompt} ${locationText} ${siteFilter}`,
          gl: config.gl,
          hl: "en",
          api_key: SERP_API_KEY,
        },
        timeout: 15000,
      })
      .catch(() => ({ data: { organic_results: [] } }));

    const [shoppingResponse, webResponse] = await Promise.all([
      shoppingRequest,
      webRequest,
    ]);

    const shoppingResults = shoppingResponse.data.shopping_results || [];
    const organicResults = webResponse.data.organic_results || [];

    let allProducts = [
      ...shoppingResults.slice(0, 10).map((item) => normalizeProduct(item, "shopping")),
      ...organicResults.slice(0, 12).map((item) => normalizeProduct(item, "web")),
    ];

    allProducts = removeDuplicates(allProducts);

    for (const product of allProducts) {
      const converted = await convertPrice(
        product.price,
        config.currencyCode,
        config.currencySymbol
      );

      product.originalPrice = converted.originalPrice;
      product.price = converted.displayPrice;
      product.numericPrice = converted.numericPrice;
    }

    allProducts = allProducts.filter((product) => {
      const title = product.name.toLowerCase();

      if (badWords.some((word) => title.includes(word))) return false;

      if (product.numericPrice) {
        if (minPrice && product.numericPrice < Number(minPrice)) return false;
        if (maxPrice && product.numericPrice > Number(maxPrice)) return false;
      }

      return true;
    });

    allProducts.forEach(scoreProduct);
    allProducts.sort((a, b) => b.score - a.score);

    const products = allProducts.slice(0, 12);

    res.json({
      result: {
        category: cleanPrompt,
        searchType,
        location,
        budget: maxPrice || null,
        summary: `Found ${products.length} options for ${cleanPrompt} in ${config.label}.`,
        suggestions: [
          `Compare prices for ${cleanPrompt}`,
          `Show cheaper ${cleanPrompt}`,
          `Best ${cleanPrompt} under budget`,
          `Find trusted stores for ${cleanPrompt}`,
          `Find alternatives to ${cleanPrompt}`,
        ],
        products,
        bestProduct: products[0] || null,
      },
    });
  } catch (err) {
    console.error("BACKEND ERROR:", err.response?.data || err.message);

    res.status(500).json({
      error: "Failed to fetch products. Please try again.",
      details: err.response?.data || err.message,
    });
  }
});


app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 ClawCart backend running on http://0.0.0.0:${PORT}`);
});