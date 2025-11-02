const express = require('express');
const db = require('../config/database');
const router = express.Router();

// Call Stored Procedure - Add Transaction
router.post('/add-transaction', (req, res) => {
  const { portfolio_id, asset_id, transaction_type, quantity, price_per_unit, transaction_date } = req.body;
  
  const sql = 'CALL add_transaction(?, ?, ?, ?, ?, ?)';
  db.query(sql, [portfolio_id, asset_id, transaction_type, quantity, price_per_unit, transaction_date], 
    (err, results) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({ message: 'Transaction added successfully via stored procedure' });
  });
});

// Call Stored Procedure - Generate Dashboard
router.post('/generate-dashboard/:portfolio_id', (req, res) => {
  const sql = 'CALL generate_dashboard(?)';
  db.query(sql, [req.params.portfolio_id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: 'Dashboard generated successfully' });
  });
});

// Call Stored Procedure - User Summary
router.get('/user-summary/:user_id', (req, res) => {
  const sql = 'CALL user_summary(?)';
  db.query(sql, [req.params.user_id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results[0]);
  });
});

// Complex Query - Portfolio Performance (Join + Aggregate + Function)
router.get('/portfolio-performance', (req, res) => {
  const sql = `
    SELECT 
      p.Portfolio_ID,
      p.Portfolio_Name,
      u.Name as User_Name,
      get_total_investment(p.Portfolio_ID) as Total_Investment,
      p.Current_Value,
      calc_roi(get_total_investment(p.Portfolio_ID), p.Current_Value) as ROI,
      pd.Beta,
      pd.Alpha
    FROM Portfolio p
    JOIN UserProfile u ON p.User_ID = u.User_ID
    LEFT JOIN PortfolioDashboard pd ON p.Portfolio_ID = pd.Portfolio_ID
    ORDER BY ROI DESC
  `;
  
  db.query(sql, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

// Nested Query - Users with High Risk Portfolios
router.get('/high-risk-users', (req, res) => {
  const sql = `
    SELECT u.Name, u.Email, p.Portfolio_Name, p.Risk_Level, p.Current_Value
    FROM UserProfile u
    JOIN Portfolio p ON u.User_ID = p.User_ID
    WHERE p.Risk_Level = 'High'
    AND u.User_ID IN (
      SELECT User_ID 
      FROM UserProfile 
      WHERE Risk_Appetite = 'High'
    )
  `;
  
  db.query(sql, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

// Aggregate Query - Sector-wise Investment Summary
router.get('/sector-summary', (req, res) => {
  const sql = `
    SELECT 
      a.Sector,
      COUNT(DISTINCT h.Asset_ID) as Total_Assets,
      SUM(h.Units_Held * a.Market_Price) as Total_Value,
      AVG(a.Risk_Rating) as Avg_Risk_Rating
    FROM Asset a
    JOIN Holds h ON a.Asset_ID = h.Asset_ID
    GROUP BY a.Sector
    ORDER BY Total_Value DESC
  `;
  
  db.query(sql, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

// Trigger Test - Add beneficiary with share validation
router.post('/test-trigger', (req, res) => {
  const { user_id, name, relationship, share_per } = req.body;
  
  const sql = 'INSERT INTO Beneficiary (User_ID, Name, Relationship, Share_Per) VALUES (?, ?, ?, ?)';
  db.query(sql, [user_id, name, relationship, share_per], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: 'Beneficiary added successfully' });
  });
});

module.exports = router;

// Update the portfolio-performance route
router.get('/portfolio-performance', (req, res) => {
  const sql = `
    SELECT 
      p.Portfolio_ID,
      p.Portfolio_Name,
      u.Name as User_Name,
      COALESCE(get_total_investment(p.Portfolio_ID), 0) as Total_Investment,
      COALESCE(p.Current_Value, 0) as Current_Value,
      COALESCE(calc_roi(COALESCE(get_total_investment(p.Portfolio_ID), 0), COALESCE(p.Current_Value, 0)), 0) as ROI,
      COALESCE(pd.Beta, 0) as Beta,
      COALESCE(pd.Alpha, 0) as Alpha
    FROM Portfolio p
    JOIN UserProfile u ON p.User_ID = u.User_ID
    LEFT JOIN PortfolioDashboard pd ON p.Portfolio_ID = pd.Portfolio_ID
    ORDER BY ROI DESC
  `;
  
  db.query(sql, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

// Add these new routes for testing functions and triggers
router.get('/test-function/:portfolio_id', (req, res) => {
  const sql = 'SELECT get_total_investment(?) as Total_Investment';
  db.query(sql, [req.params.portfolio_id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results[0]);
  });
});

router.get('/test-roi/:portfolio_id', (req, res) => {
  const sql = 'SELECT calc_roi(get_total_investment(?), (SELECT Current_Value FROM Portfolio WHERE Portfolio_ID = ?)) as ROI';
  db.query(sql, [req.params.portfolio_id, req.params.portfolio_id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results[0]);
  });
});

// Test beneficiary trigger
router.post('/test-beneficiary-trigger', (req, res) => {
  const { user_id, name, relationship, share_per } = req.body;
  
  const sql = 'INSERT INTO Beneficiary (User_ID, Name, Relationship, Share_Per) VALUES (?, ?, ?, ?)';
  db.query(sql, [user_id, name, relationship, share_per], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: 'Beneficiary added successfully' });
  });
});

// Generate dashboard for portfolio
router.post('/generate-dashboard/:portfolio_id', (req, res) => {
  const sql = 'CALL generate_dashboard(?)';
  db.query(sql, [req.params.portfolio_id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: 'Dashboard generated successfully', data: results });
  });
});

// Get user summary
router.get('/user-summary/:user_id', (req, res) => {
  const sql = 'CALL user_summary(?)';
  db.query(sql, [req.params.user_id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results[0]);
  });
});

// Fix the portfolio-performance route
router.get('/portfolio-performance', (req, res) => {
  const sql = `
    SELECT 
      p.Portfolio_ID,
      p.Portfolio_Name,
      u.Name as User_Name,
      COALESCE((
        SELECT SUM(Amount) 
        FROM Transaction 
        WHERE Portfolio_ID = p.Portfolio_ID AND Transaction_Type = 'BUY'
      ), 0) as Total_Investment,
      COALESCE(p.Current_Value, 0) as Current_Value,
      COALESCE(
        CASE 
          WHEN (
            SELECT SUM(Amount) 
            FROM Transaction 
            WHERE Portfolio_ID = p.Portfolio_ID AND Transaction_Type = 'BUY'
          ) > 0 
          THEN ROUND(
            ((p.Current_Value - (
              SELECT SUM(Amount) 
              FROM Transaction 
              WHERE Portfolio_ID = p.Portfolio_ID AND Transaction_Type = 'BUY'
            )) / (
              SELECT SUM(Amount) 
              FROM Transaction 
              WHERE Portfolio_ID = p.Portfolio_ID AND Transaction_Type = 'BUY'
            )) * 100, 
            2
          )
          ELSE 0 
        END, 
        0
      ) as ROI,
      COALESCE(pd.Beta, 0) as Beta,
      COALESCE(pd.Alpha, 0) as Alpha
    FROM Portfolio p
    JOIN UserProfile u ON p.User_ID = u.User_ID
    LEFT JOIN PortfolioDashboard pd ON p.Portfolio_ID = pd.Portfolio_ID
    ORDER BY ROI DESC
  `;
  
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

// Get dashboard statistics
router.get('/dashboard-stats', (req, res) => {
  const statsSql = `
    SELECT 
      (SELECT COUNT(*) FROM UserProfile) as totalUsers,
      (SELECT COUNT(*) FROM Portfolio) as totalPortfolios,
      (SELECT COUNT(*) FROM Asset) as totalAssets,
      (SELECT COUNT(*) FROM Transaction) as totalTransactions,
      (SELECT COALESCE(SUM(Current_Value), 0) FROM Portfolio) as totalValue,
      (SELECT COALESCE(AVG(ROI), 0) FROM PortfolioDashboard) as averageROI
  `;
  
  db.query(statsSql, (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: err.message });
    }
    
    // Ensure all values are numbers
    const stats = results[0];
    stats.totalUsers = parseInt(stats.totalUsers) || 0;
    stats.totalPortfolios = parseInt(stats.totalPortfolios) || 0;
    stats.totalAssets = parseInt(stats.totalAssets) || 0;
    stats.totalTransactions = parseInt(stats.totalTransactions) || 0;
    stats.totalValue = parseFloat(stats.totalValue) || 0;
    stats.averageROI = parseFloat(stats.averageROI) || 0;
    
    res.json(stats);
  });
});