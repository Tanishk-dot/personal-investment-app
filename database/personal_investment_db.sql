-- ============================================================
-- PERSONAL INVESTMENT MANAGEMENT SYSTEM - COMPLETE DATABASE SETUP
-- ============================================================

-- Create Database
CREATE DATABASE IF NOT EXISTS PersonalInvestmentDB;
USE PersonalInvestmentDB;

-- ============================================================
-- TABLE CREATION (DDL)
-- ============================================================

-- User Profile Table
CREATE TABLE UserProfile (
    User_ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100) UNIQUE,
    Phone_No VARCHAR(20),
    Address VARCHAR(255),
    Age INT,
    Investment_Goals VARCHAR(255),
    Risk_Appetite VARCHAR(50)
);

-- Portfolio Table
CREATE TABLE Portfolio (
    Portfolio_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT,
    Portfolio_Name VARCHAR(100),
    Portfolio_Type VARCHAR(50),
    Creation_Date DATE,
    Risk_Level VARCHAR(50),
    Strategy VARCHAR(255),
    Current_Value DECIMAL(15,2),
    FOREIGN KEY (User_ID) REFERENCES UserProfile(User_ID)
);

-- Asset Table
CREATE TABLE Asset (
    Asset_ID INT AUTO_INCREMENT PRIMARY KEY,
    Asset_Name VARCHAR(100),
    Asset_Type VARCHAR(50),
    Sector VARCHAR(100),
    Market_Price DECIMAL(15,2),
    Risk_Rating VARCHAR(50),
    Hold_Status VARCHAR(50)
);

-- Transaction Table
CREATE TABLE Transaction (
    Transaction_ID INT AUTO_INCREMENT PRIMARY KEY,
    Portfolio_ID INT,
    Asset_ID INT,
    Transaction_Type ENUM('BUY','SELL'),
    Quantity INT,
    Price_Per_Unit DECIMAL(15,2),
    Transaction_Date DATE,
    Amount DECIMAL(15,2),
    FOREIGN KEY (Portfolio_ID) REFERENCES Portfolio(Portfolio_ID),
    FOREIGN KEY (Asset_ID) REFERENCES Asset(Asset_ID)
);

-- Transaction Detail Table
CREATE TABLE TransactionDetail (
    Detail_No INT AUTO_INCREMENT PRIMARY KEY,
    Transaction_ID INT,
    Tax DECIMAL(10,2),
    Charges DECIMAL(10,2),
    Settlement_Date DATE,
    Notes VARCHAR(255),
    FOREIGN KEY (Transaction_ID) REFERENCES Transaction(Transaction_ID)
);

-- Holds Table
CREATE TABLE Holds (
    Portfolio_ID INT,
    Asset_ID INT,
    Units_Held INT,
    Avg_Cost DECIMAL(15,2),
    Exit_Buy_Date DATE,
    PRIMARY KEY (Portfolio_ID, Asset_ID),
    FOREIGN KEY (Portfolio_ID) REFERENCES Portfolio(Portfolio_ID),
    FOREIGN KEY (Asset_ID) REFERENCES Asset(Asset_ID)
);

-- Portfolio Dashboard Table
CREATE TABLE PortfolioDashboard (
    Dashboard_ID INT AUTO_INCREMENT PRIMARY KEY,
    Portfolio_ID INT,
    Report_Type VARCHAR(50),
    ROI DECIMAL(6,2),
    CAGR DECIMAL(6,2),
    Beta DECIMAL(6,2),
    Alpha DECIMAL(6,2),
    Benchmark VARCHAR(100),
    Generate_Date DATE,
    FOREIGN KEY (Portfolio_ID) REFERENCES Portfolio(Portfolio_ID)
);

-- Query Table
CREATE TABLE Query (
    Query_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT,
    Query_Type VARCHAR(100),
    Description VARCHAR(255),
    Status VARCHAR(50),
    Date_Raised DATE,
    Date_Resolved DATE,
    FOREIGN KEY (User_ID) REFERENCES UserProfile(User_ID)
);

-- Beneficiary Table
CREATE TABLE Beneficiary (
    Beneficiary_Tag INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT,
    Name VARCHAR(100),
    Relationship VARCHAR(100),
    Share_Per DECIMAL(5,2),
    FOREIGN KEY (User_ID) REFERENCES UserProfile(User_ID)
);

-- Investment Goals Table
CREATE TABLE InvestmentGoals (
    User_ID INT,
    Plans VARCHAR(255),
    PRIMARY KEY (User_ID, Plans),
    FOREIGN KEY (User_ID) REFERENCES UserProfile(User_ID)
);

-- ============================================================
-- DATABASE FUNCTIONS
-- ============================================================

DELIMITER //
CREATE FUNCTION get_total_investment(pid INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(15,2);
    SELECT SUM(Amount) INTO total FROM Transaction WHERE Portfolio_ID = pid AND Transaction_Type='BUY';
    RETURN IFNULL(total,0);
END;
//
DELIMITER ;

DELIMITER //
CREATE FUNCTION calc_roi(invested DECIMAL(15,2), current_val DECIMAL(15,2))
RETURNS DECIMAL(6,2)
DETERMINISTIC
BEGIN
    RETURN ROUND(((current_val - invested)/invested)*100,2);
END;
//
DELIMITER ;

DELIMITER //
CREATE FUNCTION get_risk_by_portfolio(pid INT)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE risk VARCHAR(50);
    SELECT u.Risk_Appetite INTO risk
    FROM UserProfile u JOIN Portfolio p ON u.User_ID=p.User_ID
    WHERE p.Portfolio_ID=pid;
    RETURN risk;
END;
//
DELIMITER ;

-- ============================================================
-- TRIGGERS
-- ============================================================

DELIMITER //
CREATE TRIGGER after_transaction_insert
AFTER INSERT ON Transaction
FOR EACH ROW
BEGIN
    DECLARE total DECIMAL(15,2);
    SELECT SUM(Amount) INTO total FROM Transaction WHERE Portfolio_ID=NEW.Portfolio_ID;
    UPDATE Portfolio SET Current_Value=IFNULL(total,0) WHERE Portfolio_ID=NEW.Portfolio_ID;
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER after_portfolio_update
AFTER UPDATE ON Portfolio
FOR EACH ROW
BEGIN
    DECLARE invest DECIMAL(15,2);
    DECLARE roi DECIMAL(6,2);
    SET invest = get_total_investment(NEW.Portfolio_ID);
    SET roi = calc_roi(invest, NEW.Current_Value);
    UPDATE PortfolioDashboard SET ROI = roi WHERE Portfolio_ID = NEW.Portfolio_ID;
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER check_beneficiary_share
BEFORE INSERT ON Beneficiary
FOR EACH ROW
BEGIN
    DECLARE total DECIMAL(5,2);
    SELECT SUM(Share_Per) INTO total FROM Beneficiary WHERE User_ID=NEW.User_ID;
    IF (total + NEW.Share_Per) > 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Total Beneficiary Share exceeds 100%';
    END IF;
END;
//
DELIMITER ;

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

DELIMITER //
CREATE PROCEDURE add_transaction(IN pid INT, IN aid INT, IN ttype ENUM('BUY','SELL'), IN qty INT, IN price DECIMAL(15,2), IN tdate DATE)
BEGIN
    DECLARE amt DECIMAL(15,2);
    SET amt = qty * price;
    INSERT INTO Transaction (Portfolio_ID, Asset_ID, Transaction_Type, Quantity, Price_Per_Unit, Transaction_Date, Amount)
    VALUES (pid, aid, ttype, qty, price, tdate, amt);
END;
//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE generate_dashboard(IN pid INT)
BEGIN
    DECLARE invested DECIMAL(15,2);
    DECLARE current_val DECIMAL(15,2);
    DECLARE roi DECIMAL(6,2);
    SELECT SUM(Amount) INTO invested FROM Transaction WHERE Portfolio_ID=pid AND Transaction_Type='BUY';
    SELECT Current_Value INTO current_val FROM Portfolio WHERE Portfolio_ID=pid;
    SET roi = calc_roi(invested, current_val);
    INSERT INTO PortfolioDashboard (Portfolio_ID, Report_Type, ROI, CAGR, Beta, Alpha, Benchmark, Generate_Date)
    VALUES (pid, 'Auto', roi, 0, 0, 0, 'System', CURDATE());
END;
//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE user_summary(IN uid INT)
BEGIN
    SELECT p.Portfolio_Name,
           get_total_investment(p.Portfolio_ID) AS Total_Investment,
           p.Current_Value,
           calc_roi(get_total_investment(p.Portfolio_ID), p.Current_Value) AS ROI
    FROM Portfolio p
    WHERE p.User_ID = uid;
END;
//
DELIMITER ;

-- ============================================================
-- SAMPLE DATA INSERTION
-- ============================================================

-- Clear existing data
DELETE FROM TransactionDetail;
DELETE FROM Transaction;
DELETE FROM Holds;
DELETE FROM PortfolioDashboard;
DELETE FROM Query;
DELETE FROM Beneficiary;
DELETE FROM InvestmentGoals;
DELETE FROM Portfolio;
DELETE FROM Asset;
DELETE FROM UserProfile;

-- Insert Users
INSERT INTO UserProfile (Name, Email, Phone_No, Address, Age, Investment_Goals, Risk_Appetite) VALUES
('Tanishk Maheshwari', 'tanishk@example.com', '9998887777', 'Goa, India', 20, 'Wealth Creation', 'High'),
('Aarav Sharma', 'aarav@example.com', '8887776666', 'Delhi, India', 25, 'Long-term Growth', 'Moderate'),
('Riya Patel', 'riya@example.com', '7776665555', 'Mumbai, India', 27, 'Retirement Planning', 'Low'),
('Ananya Verma', 'ananya@example.com', '9991112222', 'Bangalore, India', 23, 'Education Fund', 'Moderate'),
('Priya Singh', 'priya.singh@example.com', '8889990001', 'Chennai, India', 32, 'Retirement Planning', 'Moderate'),
('Rahul Kumar', 'rahul.kumar@example.com', '7778889992', 'Hyderabad, India', 28, 'Wealth Accumulation', 'High'),
('Sneha Gupta', 'sneha.gupta@example.com', '6667778883', 'Pune, India', 35, 'Children Education', 'Low'),
('Vikram Joshi', 'vikram.joshi@example.com', '9990001114', 'Kolkata, India', 45, 'Tax Saving', 'Moderate'),
('Neha Reddy', 'neha.reddy@example.com', '8881112225', 'Bangalore, India', 29, 'Real Estate Investment', 'High'),
('Arjun Mehta', 'arjun.mehta@example.com', '7772223336', 'Mumbai, India', 38, 'International Diversification', 'Moderate');

-- Insert Assets
INSERT INTO Asset (Asset_Name, Asset_Type, Sector, Market_Price, Risk_Rating, Hold_Status) VALUES
('Apple Inc', 'Stock', 'Technology', 175.50, 'Medium', 'Hold'),
('Bitcoin', 'Crypto', 'Blockchain', 60000.00, 'High', 'Hold'),
('HDFC Bank', 'Stock', 'Finance', 1600.00, 'Low', 'Hold'),
('Tata Motors', 'Stock', 'Automobile', 920.00, 'Medium', 'Hold'),
('Tesla Inc', 'Stock', 'Automobile', 250.75, 'High', 'Hold'),
('Gold ETF', 'ETF', 'Commodities', 55.20, 'Low', 'Hold');

-- Insert Portfolios
INSERT INTO Portfolio (User_ID, Portfolio_Name, Portfolio_Type, Creation_Date, Risk_Level, Strategy, Current_Value) VALUES
(1, 'Tech Growth', 'Equity', '2025-01-01', 'High', 'Aggressive Growth', 165000.00),
(2, 'Balanced Fund', 'Hybrid', '2025-02-15', 'Moderate', 'Diversified Mix', 95000.00),
(3, 'Safe Haven', 'Debt', '2025-03-20', 'Low', 'Capital Preservation', 115000.00),
(4, 'Crypto Vision', 'Crypto', '2025-04-05', 'High', 'High-Risk Crypto Mix', 75000.00),
(1, 'Long Term', 'Equity', '2025-05-10', 'Moderate', 'Value Investing', 58000.00),
(5, 'Retirement Fund', 'Debt', '2025-06-01', 'Low', 'Fixed Income Focus', 120000.00),
(6, 'Aggressive Growth', 'Equity', '2025-06-15', 'High', 'Small Cap Focus', 95000.00),
(7, 'Education Corpus', 'Hybrid', '2025-07-01', 'Moderate', 'Balanced Approach', 110000.00),
(8, 'Tax Saver', 'ELSS', '2025-07-15', 'High', 'Tax Efficient', 85000.00),
(9, 'Property Fund', 'Real Estate', '2025-08-01', 'Moderate', 'REIT Investment', 135000.00),
(10, 'Global Diversified', 'International', '2025-08-15', 'High', 'Global Markets', 105000.00);

-- Insert Transactions
INSERT INTO Transaction (Portfolio_ID, Asset_ID, Transaction_Type, Quantity, Price_Per_Unit, Transaction_Date, Amount) VALUES
(1, 1, 'BUY', 100, 150.00, '2025-03-01', 15000.00),
(1, 2, 'BUY', 2, 58000.00, '2025-04-01', 116000.00),
(2, 3, 'BUY', 50, 1550.00, '2025-02-20', 77500.00),
(2, 5, 'BUY', 40, 240.00, '2025-03-15', 9600.00),
(3, 4, 'BUY', 80, 850.00, '2025-03-25', 68000.00),
(3, 6, 'BUY', 1000, 52.00, '2025-04-10', 52000.00),
(4, 2, 'BUY', 1, 59000.00, '2025-04-05', 59000.00),
(4, 1, 'BUY', 20, 160.00, '2025-05-01', 3200.00),
(5, 3, 'BUY', 30, 1580.00, '2025-05-10', 47400.00),
(5, 5, 'BUY', 25, 245.00, '2025-05-20', 6125.00),
(6, 3, 'BUY', 60, 1620.00, '2025-06-05', 97200.00),
(6, 6, 'BUY', 500, 54.00, '2025-06-10', 27000.00),
(7, 1, 'BUY', 80, 245.00, '2025-06-20', 19600.00),
(7, 5, 'BUY', 100, 255.00, '2025-06-25', 25500.00),
(8, 2, 'BUY', 0.5, 61000.00, '2025-07-05', 30500.00),
(8, 4, 'BUY', 40, 940.00, '2025-07-10', 37600.00),
(9, 1, 'BUY', 50, 240.00, '2025-07-20', 12000.00),
(9, 3, 'BUY', 30, 1650.00, '2025-07-25', 49500.00),
(10, 6, 'BUY', 800, 53.50, '2025-08-05', 42800.00),
(10, 2, 'BUY', 0.3, 60500.00, '2025-08-10', 18150.00),
(11, 5, 'BUY', 120, 250.00, '2025-08-20', 30000.00),
(11, 1, 'BUY', 100, 242.00, '2025-08-25', 24200.00);

-- Insert Transaction Details
INSERT INTO TransactionDetail (Transaction_ID, Tax, Charges, Settlement_Date, Notes) VALUES
(1, 150.00, 50.00, '2025-03-03', 'Initial purchase of Apple stock'),
(2, 500.00, 100.00, '2025-04-03', 'Crypto asset purchase'),
(3, 200.00, 75.00, '2025-02-25', 'Bank stock investment'),
(4, 96.00, 30.00, '2025-03-18', 'Automobile sector'),
(5, 136.00, 45.00, '2025-03-28', 'Indian auto stock'),
(6, 104.00, 25.00, '2025-04-12', 'Gold investment'),
(7, 118.00, 50.00, '2025-04-07', 'Bitcoin purchase'),
(8, 32.00, 15.00, '2025-05-03', 'Additional tech stock'),
(9, 94.80, 35.00, '2025-05-12', 'Banking sector'),
(10, 61.25, 20.00, '2025-05-22', 'EV company stock'),
(11, 194.40, 65.00, '2025-06-07', 'Bank stock for retirement'),
(12, 54.00, 20.00, '2025-06-12', 'Gold ETF addition'),
(13, 39.20, 25.00, '2025-06-22', 'Tech stock purchase'),
(14, 51.00, 30.00, '2025-06-27', 'EV sector investment'),
(15, 61.00, 50.00, '2025-07-07', 'Crypto diversification'),
(16, 75.20, 35.00, '2025-07-12', 'Auto sector exposure'),
(17, 24.00, 15.00, '2025-07-22', 'ELSS qualifying investment'),
(18, 99.00, 40.00, '2025-07-27', 'Financial sector'),
(19, 85.60, 30.00, '2025-08-07', 'Commodity exposure'),
(20, 36.30, 25.00, '2025-08-12', 'Digital gold'),
(21, 60.00, 35.00, '2025-08-22', 'International tech'),
(22, 48.40, 28.00, '2025-08-27', 'US market exposure');

-- Insert Holds Data
INSERT INTO Holds VALUES
(1, 1, 100, 150.00, '2025-03-01'),
(1, 2, 2, 58000.00, '2025-04-01'),
(2, 3, 50, 1550.00, '2025-02-20'),
(2, 5, 40, 240.00, '2025-03-15'),
(3, 4, 80, 850.00, '2025-03-25'),
(3, 6, 1000, 52.00, '2025-04-10'),
(4, 2, 1, 59000.00, '2025-04-05'),
(4, 1, 20, 160.00, '2025-05-01'),
(5, 3, 30, 1580.00, '2025-05-10'),
(5, 5, 25, 245.00, '2025-05-20'),
(6, 3, 60, 1620.00, '2025-06-05'),
(6, 6, 500, 54.00, '2025-06-10'),
(7, 1, 80, 245.00, '2025-06-20'),
(7, 5, 100, 255.00, '2025-06-25'),
(8, 2, 0.5, 61000.00, '2025-07-05'),
(8, 4, 40, 940.00, '2025-07-10'),
(9, 1, 50, 240.00, '2025-07-20'),
(9, 3, 30, 1650.00, '2025-07-25'),
(10, 6, 800, 53.50, '2025-08-05'),
(10, 2, 0.3, 60500.00, '2025-08-10'),
(11, 5, 120, 250.00, '2025-08-20'),
(11, 1, 100, 242.00, '2025-08-25');

-- Insert Portfolio Dashboard Data
INSERT INTO PortfolioDashboard (Portfolio_ID, Report_Type, ROI, CAGR, Beta, Alpha, Benchmark, Generate_Date) VALUES
(1, 'Monthly', 25.95, 12.50, 1.10, 0.80, 'NASDAQ', '2025-09-30'),
(2, 'Quarterly', 9.07, 5.50, 0.95, 0.70, 'NIFTY50', '2025-09-30'),
(3, 'Monthly', -4.17, 3.20, 0.60, 0.40, 'CRISIL', '2025-09-30'),
(4, 'Monthly', 20.58, 15.00, 1.25, 1.10, 'CryptoIndex', '2025-09-30'),
(5, 'Quarterly', 8.36, 8.50, 0.85, 0.65, 'S&P500', '2025-09-30'),
(6, 'Quarterly', 6.50, 3.20, 0.55, 0.35, 'CRISIL', '2025-09-30'),
(7, 'Monthly', 22.00, 11.50, 1.15, 0.90, 'NIFTY Smallcap', '2025-09-30'),
(8, 'Monthly', 14.50, 7.80, 0.88, 0.60, 'NIFTY50', '2025-09-30'),
(9, 'Quarterly', 18.20, 9.50, 1.08, 0.75, 'ELSS Index', '2025-09-30'),
(10, 'Monthly', 8.80, 4.50, 0.72, 0.48, 'REIT Index', '2025-09-30'),
(11, 'Monthly', 16.50, 8.20, 1.02, 0.68, 'MSCI World', '2025-09-30');

-- Insert Queries
INSERT INTO Query (User_ID, Query_Type, Description, Status, Date_Raised, Date_Resolved) VALUES
(1, 'Portfolio Performance', 'Need detailed performance report', 'Resolved', '2025-09-20', '2025-09-22'),
(2, 'Transaction Issue', 'Duplicate transaction detected', 'Open', '2025-09-25', NULL),
(3, 'Add Asset', 'Requesting new asset entry', 'Pending', '2025-09-18', NULL),
(4, 'ROI Report', 'ROI mismatch in dashboard', 'Resolved', '2025-09-10', '2025-09-12'),
(5, 'Withdrawal Process', 'How to withdraw from retirement fund?', 'Pending', '2025-09-28', NULL),
(6, 'Portfolio Review', 'Need professional portfolio review', 'Open', '2025-09-26', NULL),
(7, 'SIP Setup', 'Want to setup systematic investment', 'Resolved', '2025-09-22', '2025-09-24'),
(8, 'Tax Query', 'Clarification on 80C benefits', 'Pending', '2025-09-25', NULL),
(9, 'Real Estate Advice', 'REIT vs physical real estate', 'Open', '2025-09-27', NULL),
(10, 'International Investing', 'Best international funds', 'Resolved', '2025-09-20', '2025-09-23');

-- Insert Beneficiaries
INSERT INTO Beneficiary (User_ID, Name, Relationship, Share_Per) VALUES
(1, 'Aditi Maheshwari', 'Sister', 40.00),
(1, 'Rajesh Maheshwari', 'Father', 60.00),
(2, 'Neha Sharma', 'Spouse', 100.00),
(3, 'Karan Patel', 'Brother', 50.00),
(4, 'Parents', 'Parents', 100.00),
(5, 'Spouse', 'Spouse', 70.00),
(5, 'Children', 'Children', 30.00),
(6, 'Parents', 'Parents', 100.00),
(7, 'Daughter', 'Daughter', 100.00),
(8, 'Wife', 'Spouse', 60.00),
(8, 'Son', 'Son', 40.00),
(9, 'Family Trust', 'Trust', 100.00),
(10, 'Charity Foundation', 'Charity', 30.00),
(10, 'Siblings', 'Siblings', 70.00);

-- Insert Investment Goals
INSERT INTO InvestmentGoals VALUES
(1, 'Buy a House'),
(1, 'Start a Business'),
(2, 'Retirement Corpus'),
(3, 'Education Fund'),
(4, 'World Tour'),
(5, 'Comfortable Retirement'),
(5, 'Healthcare Fund'),
(6, 'Early Retirement'),
(6, 'Startup Funding'),
(7, 'Daughter Education'),
(7, 'Daughter Marriage'),
(8, 'Tax Optimization'),
(8, 'Wealth Transfer'),
(9, 'Commercial Property'),
(9, 'Passive Income'),
(10, 'Global Exposure'),
(10, 'Currency Diversification');

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

SELECT '=== DATABASE VERIFICATION ===' as '';
SELECT 'Users:' as Table_Name, COUNT(*) as Count FROM UserProfile
UNION SELECT 'Portfolios:', COUNT(*) FROM Portfolio
UNION SELECT 'Assets:', COUNT(*) FROM Asset
UNION SELECT 'Transactions:', COUNT(*) FROM Transaction
UNION SELECT 'Transaction Details:', COUNT(*) FROM TransactionDetail
UNION SELECT 'Holds:', COUNT(*) FROM Holds
UNION SELECT 'Portfolio Dashboard:', COUNT(*) FROM PortfolioDashboard
UNION SELECT 'Queries:', COUNT(*) FROM Query
UNION SELECT 'Beneficiaries:', COUNT(*) FROM Beneficiary
UNION SELECT 'Investment Goals:', COUNT(*) FROM InvestmentGoals;

SELECT '=== DATABASE FUNCTIONS TEST ===' as '';
SELECT 
    p.Portfolio_Name,
    get_total_investment(p.Portfolio_ID) as Total_Investment,
    p.Current_Value,
    calc_roi(get_total_investment(p.Portfolio_ID), p.Current_Value) as ROI,
    get_risk_by_portfolio(p.Portfolio_ID) as Risk_Appetite
FROM Portfolio p
LIMIT 5;

SELECT '=== COMPLEX QUERIES DEMO ===' as '';
-- Portfolio Performance (Join + Aggregate)
SELECT 
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
LIMIT 5;

-- High Risk Users (Nested Query)
SELECT u.Name, u.Email, p.Portfolio_Name, p.Risk_Level, p.Current_Value
FROM UserProfile u
JOIN Portfolio p ON u.User_ID = p.User_ID
WHERE p.Risk_Level = 'High'
AND u.User_ID IN (
    SELECT User_ID 
    FROM UserProfile 
    WHERE Risk_Appetite = 'High'
);

SELECT '=== DATABASE SETUP COMPLETE ===' as '';