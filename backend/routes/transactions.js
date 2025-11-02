const express = require('express');
const db = require('../config/database');
const router = express.Router();

// GET all transactions with portfolio and asset details
router.get('/', (req, res) => {
  const sql = `
    SELECT t.*, p.Portfolio_Name, a.Asset_Name 
    FROM Transaction t
    JOIN Portfolio p ON t.Portfolio_ID = p.Portfolio_ID
    JOIN Asset a ON t.Asset_ID = a.Asset_ID
    ORDER BY t.Transaction_Date DESC
  `;
  db.query(sql, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

// DELETE transaction
router.delete('/:id', (req, res) => {
  const sql = 'DELETE FROM Transaction WHERE Transaction_ID = ?';
  db.query(sql, [req.params.id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: 'Transaction deleted successfully' });
  });
});

module.exports = router;