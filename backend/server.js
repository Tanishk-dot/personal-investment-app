const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/users', require('./routes/users'));
app.use('/api/portfolios', require('./routes/portfolios'));
app.use('/api/assets', require('./routes/assets'));
app.use('/api/transactions', require('./routes/transactions'));
app.use('/api/queries', require('./routes/queries'));
app.use('/api/advanced', require('./routes/advanced'));

// Basic route
app.get('/', (req, res) => {
  res.json({ message: 'Personal Investment Management System API' });
});

// Test database connection route
app.get('/api/test-db', (req, res) => {
  const db = require('./config/database');
  db.query('SELECT 1 + 1 AS solution', (err, results) => {
    if (err) {
      return res.status(500).json({ error: 'Database connection failed: ' + err.message });
    }
    res.json({ message: 'Database connected successfully', result: results[0].solution });
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});