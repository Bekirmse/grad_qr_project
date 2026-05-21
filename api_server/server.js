const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const dataPath = path.join(__dirname, 'data', 'prices.json');

function loadData() {
  const raw = fs.readFileSync(dataPath, 'utf-8');
  return JSON.parse(raw);
}

app.get('/', (req, res) => {
  res.json({
    name: 'ScanWiser Price API',
    version: '1.0.0',
    endpoints: [
      'GET /api/products',
      'GET /api/prices/:barcode',
      'GET /api/supermarkets',
    ],
  });
});

app.get('/api/supermarkets', (req, res) => {
  const data = loadData();
  res.json({ success: true, supermarkets: data.supermarkets });
});

app.get('/api/products', (req, res) => {
  const data = loadData();
  const { category, search } = req.query;

  let products = data.products.map((p) => ({
    barcode: p.barcode,
    productName: p.productName,
    brand: p.brand,
    category: p.category,
    imageUrl: p.imageUrl,
  }));

  if (category && category !== 'All') {
    products = products.filter(
      (p) => p.category.toLowerCase() === category.toLowerCase()
    );
  }

  if (search) {
    const q = search.toLowerCase();
    products = products.filter(
      (p) =>
        p.productName.toLowerCase().includes(q) ||
        p.brand.toLowerCase().includes(q)
    );
  }

  res.json({ success: true, count: products.length, products });
});

app.get('/api/prices/:barcode', (req, res) => {
  const data = loadData();
  const { barcode } = req.params;

  const product = data.products.find((p) => p.barcode === barcode);

  if (!product) {
    return res.status(404).json({ success: false, message: 'Product not found' });
  }

  const enrichedPrices = product.prices.map((price) => {
    const market = data.supermarkets.find((s) => s.id === price.marketId);
    return {
      marketId: price.marketId,
      marketName: market ? market.name : price.marketId,
      marketLogoUrl: market ? market.logoUrl : '',
      price: price.price,
      currency: price.currency,
    };
  });

  enrichedPrices.sort((a, b) => a.price - b.price);

  res.json({
    success: true,
    barcode: product.barcode,
    productName: product.productName,
    brand: product.brand,
    category: product.category,
    imageUrl: product.imageUrl,
    prices: enrichedPrices,
  });
});

app.get('/api/categories', (req, res) => {
  const data = loadData();
  const categories = [...new Set(data.products.map((p) => p.category))].sort();
  res.json({ success: true, categories });
});

app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

app.listen(PORT, () => {
  console.log(`ScanWiser Price API running on port ${PORT}`);
});
