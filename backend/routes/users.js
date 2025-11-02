const express = require('express');
const db = require('../config/database');
const router = express.Router();

// GET all users
router.get('/', (req, res) => {
  const sql = 'SELECT * FROM UserProfile';
  db.query(sql, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

// GET user by ID
router.get('/:id', (req, res) => {
  const sql = 'SELECT * FROM UserProfile WHERE User_ID = ?';
  db.query(sql, [req.params.id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    if (results.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(results[0]);
  });
});

// CREATE new user
router.post('/', (req, res) => {
  const { Name, Email, Phone_No, Address, Age, Investment_Goals, Risk_Appetite } = req.body;
  const sql = `INSERT INTO UserProfile (Name, Email, Phone_No, Address, Age, Investment_Goals, Risk_Appetite) 
               VALUES (?, ?, ?, ?, ?, ?, ?)`;
  
  db.query(sql, [Name, Email, Phone_No, Address, Age, Investment_Goals, Risk_Appetite], 
    (err, results) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({ message: 'User created successfully', id: results.insertId });
  });
});

// UPDATE user
router.put('/:id', (req, res) => {
  const { Name, Email, Phone_No, Address, Age, Investment_Goals, Risk_Appetite } = req.body;
  const sql = `UPDATE UserProfile SET Name=?, Email=?, Phone_No=?, Address=?, Age=?, 
               Investment_Goals=?, Risk_Appetite=? WHERE User_ID=?`;
  
  db.query(sql, [Name, Email, Phone_No, Address, Age, Investment_Goals, Risk_Appetite, req.params.id], 
    (err, results) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({ message: 'User updated successfully' });
  });
});

// DELETE user
router.delete('/:id', (req, res) => {
  const sql = 'DELETE FROM UserProfile WHERE User_ID = ?';
  db.query(sql, [req.params.id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: 'User deleted successfully' });
  });
});

module.exports = router;