const express = require('express');
const db = require('../config/database');
const router = express.Router();

// GET all assets
router.get('/', (req, res) => {
  const sql = 'SELECT * FROM Asset';
  db.query(sql, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

module.exports = router;