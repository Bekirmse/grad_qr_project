const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const MARKET_ID = process.env.MARKET_ID || null;

app.use(cors());
app.use(express.json());

const dataPath = path.join(__dirname, 'data', 'prices.json');

function loadData() {
  return JSON.parse(fs.readFileSync(dataPath, 'utf-8'));
}

app.get('/', (req, res) => {
  const data = loadData();
  const market = MARKET_ID ? data.supermarkets.find((s) => s.id === MARKET_ID) : null;
  res.json({
    name: market ? `${market.name} Price API` : 'ScanWiser Price API',
    marketId: MARKET_ID || 'all',
    version: '2.0.0',
    endpoints: MARKET_ID
      ? ['GET /api/prices/:barcode', 'GET /api/products']
      : [
          'GET /api/products',
          'GET /api/prices/:barcode',
          'GET /api/supermarkets',
          'GET /api/categories',
          'GET /api/market/:marketId/prices/:barcode',
          'GET /api/market/:marketId/products',
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
  const targetMarket = MARKET_ID;

  let products = data.products
    .filter((p) => !targetMarket || p.prices.some((pr) => pr.marketId === targetMarket))
    .map((p) => {
      const priceEntry = targetMarket
        ? p.prices.find((pr) => pr.marketId === targetMarket)
        : null;
      return {
        barcode: p.barcode,
        productName: p.productName,
        brand: p.brand,
        category: p.category,
        imageUrl: p.imageUrl,
        ...(priceEntry ? { price: priceEntry.price, currency: priceEntry.currency } : {}),
      };
    });

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

app.get('/api/categories', (req, res) => {
  const data = loadData();
  const categories = [...new Set(data.products.map((p) => p.category))].sort();
  res.json({ success: true, categories });
});

app.get('/api/prices/:barcode', (req, res) => {
  const data = loadData();
  const { barcode } = req.params;
  const product = data.products.find((p) => p.barcode === barcode);

  if (!product) {
    return res.status(404).json({ success: false, message: 'Product not found' });
  }

  if (MARKET_ID) {
    const market = data.supermarkets.find((s) => s.id === MARKET_ID);
    const priceEntry = product.prices.find((p) => p.marketId === MARKET_ID);

    if (!priceEntry) {
      return res.status(404).json({ success: false, message: 'Price not available at this market' });
    }

    return res.json({
      success: true,
      barcode: product.barcode,
      productName: product.productName,
      brand: product.brand,
      category: product.category,
      imageUrl: product.imageUrl,
      marketId: MARKET_ID,
      marketName: market ? market.name : MARKET_ID,
      marketLogoUrl: market ? market.logoUrl : '',
      price: priceEntry.price,
      currency: priceEntry.currency,
    });
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

app.get('/api/market/:marketId/prices/:barcode', (req, res) => {
  const data = loadData();
  const { marketId, barcode } = req.params;

  const market = data.supermarkets.find((s) => s.id === marketId);
  if (!market) {
    return res.status(404).json({ success: false, message: 'Market not found' });
  }

  const product = data.products.find((p) => p.barcode === barcode);
  if (!product) {
    return res.status(404).json({ success: false, message: 'Product not found' });
  }

  const priceEntry = product.prices.find((p) => p.marketId === marketId);
  if (!priceEntry) {
    return res.status(404).json({ success: false, message: 'Price not available at this market' });
  }

  res.json({
    success: true,
    barcode: product.barcode,
    productName: product.productName,
    brand: product.brand,
    category: product.category,
    imageUrl: product.imageUrl,
    marketId: market.id,
    marketName: market.name,
    marketLogoUrl: market.logoUrl,
    price: priceEntry.price,
    currency: priceEntry.currency,
  });
});

app.get('/api/market/:marketId/products', (req, res) => {
  const data = loadData();
  const { marketId } = req.params;

  const market = data.supermarkets.find((s) => s.id === marketId);
  if (!market) {
    return res.status(404).json({ success: false, message: 'Market not found' });
  }

  const products = data.products
    .filter((p) => p.prices.some((pr) => pr.marketId === marketId))
    .map((p) => {
      const priceEntry = p.prices.find((pr) => pr.marketId === marketId);
      return {
        barcode: p.barcode,
        productName: p.productName,
        brand: p.brand,
        category: p.category,
        imageUrl: p.imageUrl,
        price: priceEntry.price,
        currency: priceEntry.currency,
      };
    });

  res.json({ success: true, marketId, marketName: market.name, count: products.length, products });
});

app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

app.listen(PORT, () => {
  const data = loadData();
  const market = MARKET_ID ? data.supermarkets.find((s) => s.id === MARKET_ID) : null;
  console.log(`${market ? market.name : 'ScanWiser'} Price API running on port ${PORT}`);
});
