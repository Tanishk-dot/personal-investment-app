const express = require('express');
const db = require('../config/database');
const router = express.Router();

// GET all queries
router.get('/', (req, res) => {
  const sql = 'SELECT * FROM Query';
  db.query(sql, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

module.exports = router;