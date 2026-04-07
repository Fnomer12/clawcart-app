require("dotenv").config();

const functions = require("firebase-functions");
const OpenAI = require("openai");

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

exports.recommend = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    const { prompt } = req.body || {};

    if (!prompt || !prompt.trim()) {
      return res.status(400).json({ error: "Prompt is required" });
    }

    const response = await client.responses.create({
      model: "gpt-5.4-mini",
      input: [
        {
          role: "system",
          content: `
You are ClawCart AI, a smart shopping assistant.

Your task:
- Understand what the user wants to buy
- Extract budget if present
- Identify key priorities
- Suggest 3 relevant product examples
- Return valid JSON only

Return exactly this JSON shape:
{
  "category": "string",
  "budget": number | null,
  "priorities": ["string"],
  "suggestedProducts": ["string"],
  "summary": "string"
}

Rules:
- Do not include markdown
- Do not include explanations outside JSON
- If budget is not stated, use null
- Keep summary short and useful
          `.trim(),
        },
        {
          role: "user",
          content: prompt,
        },
      ],
    });

    const text = response.output_text?.trim();

    if (!text) {
      return res.status(500).json({
        success: false,
        error: "Empty response from AI",
      });
    }

    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch (parseError) {
      return res.status(500).json({
        success: false,
        error: "AI returned invalid JSON",
        raw: text,
      });
    }

    return res.json({
      success: true,
      result: parsed,
    });
  } catch (error) {
  console.error("AI recommendation error:", error);

  // ✅ Fallback response (so app never crashes)
  return res.json({
    success: true,
    result: {
      category: "general",
      budget: null,
      priorities: ["value", "quality"],
      suggestedProducts: [
        "Sample Product 1",
        "Sample Product 2",
        "Sample Product 3"
      ],
      summary: "AI is temporarily unavailable. Showing default recommendations.",
    },
  });
}
});