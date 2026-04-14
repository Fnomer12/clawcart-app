require('dotenv').config();

const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

const SERP_API_KEY = process.env.SERPAPI_KEY;

app.get('/', (req, res) => {
  res.send('Backend is running');
});

app.post('/recommend', async (req, res) => {
  try {
    const { prompt, location, minPrice, maxPrice } = req.body;

    if (!prompt || prompt.trim() === '') {
      return res.status(400).json({ error: 'Prompt is required' });
    }

    const query = `${prompt} ${location ?? ''}`.trim();

    const response = await axios.get('https://serpapi.com/search.json', {
      params: {
        engine: 'google_shopping',
        q: query,
        api_key: SERP_API_KEY,
      },
    });

    const products = (response.data.shopping_results || []).map((item) => ({
      name: item.title,
      price: item.price,
      rating: item.rating,
      store: item.source,
      url: item.link,
      image: item.thumbnail,
      reason: `Price: ${item.price} • Rating: ${item.rating ?? 'N/A'}`,
    }));

    res.json({
      result: {
        summary: `Found ${products.length} products`,
        products,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch products' });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on http://127.0.0.1:${PORT}`);
});