const express = require('express');
const db = require('../config/database');
const router = express.Router();

// GET all portfolios with user names
router.get('/', (req, res) => {
  const sql = `
    SELECT p.*, u.Name as User_Name 
    FROM Portfolio p 
    JOIN UserProfile u ON p.User_ID = u.User_ID
  `;
  db.query(sql, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

// GET portfolio by ID
router.get('/:id', (req, res) => {
  const sql = 'SELECT * FROM Portfolio WHERE Portfolio_ID = ?';
  db.query(sql, [req.params.id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    if (results.length === 0) {
      return res.status(404).json({ message: 'Portfolio not found' });
    }
    res.json(results[0]);
  });
});

// CREATE new portfolio
router.post('/', (req, res) => {
  const { User_ID, Portfolio_Name, Portfolio_Type, Creation_Date, Risk_Level, Strategy, Current_Value } = req.body;
  const sql = `INSERT INTO Portfolio (User_ID, Portfolio_Name, Portfolio_Type, Creation_Date, Risk_Level, Strategy, Current_Value) 
               VALUES (?, ?, ?, ?, ?, ?, ?)`;
  
  db.query(sql, [User_ID, Portfolio_Name, Portfolio_Type, Creation_Date, Risk_Level, Strategy, Current_Value || 0], 
    (err, results) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({ message: 'Portfolio created successfully', id: results.insertId });
  });
});

// UPDATE portfolio
router.put('/:id', (req, res) => {
  const { Portfolio_Name, Portfolio_Type, Risk_Level, Strategy, Current_Value } = req.body;
  const sql = `UPDATE Portfolio SET Portfolio_Name=?, Portfolio_Type=?, Risk_Level=?, Strategy=?, Current_Value=? 
               WHERE Portfolio_ID=?`;
  
  db.query(sql, [Portfolio_Name, Portfolio_Type, Risk_Level, Strategy, Current_Value, req.params.id], 
    (err, results) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({ message: 'Portfolio updated successfully' });
  });
});

// DELETE portfolio
router.delete('/:id', (req, res) => {
  const sql = 'DELETE FROM Portfolio WHERE Portfolio_ID = ?';
  db.query(sql, [req.params.id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: 'Portfolio deleted successfully' });
  });
});

// Get total investment for portfolio (using function)
router.get('/:id/total-investment', (req, res) => {
  const sql = 'SELECT get_total_investment(?) as Total_Investment';
  db.query(sql, [req.params.id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results[0]);
  });
});

// Calculate ROI for portfolio
router.get('/:id/roi', (req, res) => {
  const sql = `
    SELECT 
      get_total_investment(?) as Total_Investment,
      (SELECT Current_Value FROM Portfolio WHERE Portfolio_ID = ?) as Current_Value,
      calc_roi(get_total_investment(?), (SELECT Current_Value FROM Portfolio WHERE Portfolio_ID = ?)) as ROI
  `;
  db.query(sql, [req.params.id, req.params.id, req.params.id, req.params.id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results[0]);
  });
});

// Get risk by portfolio
router.get('/:id/risk', (req, res) => {
  const sql = 'SELECT get_risk_by_portfolio(?) as Risk_Appetite';
  db.query(sql, [req.params.id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results[0]);
  });
});

module.exports = router;