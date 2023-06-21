-- create and use the database:
create database `Portfolio`;
use Portfolio;

-- create the investment table
CREATE TABLE Investment (
	investment_ID    INT NOT NULL AUTO_INCREMENT,
	investment_name  VARCHAR(255) NOT NULL,
    investment_type  VARCHAR(255) CHECK(investment_type IN ("stock", "commodity", "bonds", "FD")),
	shares_held      INT NOT NULL CHECK(shares_held > 0),
    CONSTRAINT pk_investment PRIMARY KEY (investment_ID)
);

-- create the risk level table
CREATE TABLE Risk_Level (
	risk_level_ID     INT NOT NULL AUTO_INCREMENT,
	risk_level        DECIMAL(4,3),
    total_return      DECIMAL(10,3),
    annualized_return DECIMAL(10,3),
    CONSTRAINT pk_risk PRIMARY KEY(risk_level_ID)
);

-- create the performance metrics table
CREATE TABLE Performance_Metrics (
	metric_ID      INT NOT NULL AUTO_INCREMENT,
    investment_ID  INT NOT NULL,
    risk_level_ID  INT NOT NULL,
    CONSTRAINT pk_metric     PRIMARY KEY (metric_ID),
    CONSTRAINT fk_investment FOREIGN KEY (investment_ID) REFERENCES Investment(investment_ID) ON DELETE CASCADE,
    CONSTRAINT fk_risk       FOREIGN KEY (risk_level_ID) REFERENCES Risk_Level(risk_level_ID) ON DELETE CASCADE
);

-- create the market data table
CREATE TABLE Market_Data (
	market_ID       INT NOT NULL AUTO_INCREMENT,
    metric_ID       INT NOT NULL,
    market_date     DATE NOT NULL,
	stock_price     DECIMAL(10,3),
    exchange_rate   DECIMAL(10,3),
    commodity_price DECIMAL(10,3),
    CONSTRAINT pk_market PRIMARY KEY (market_ID),
    CONSTRAINT fk_metric FOREIGN KEY (metric_ID) REFERENCES Performance_Metrics(metric_ID) ON DELETE CASCADE
);

-- create the other financial information table
CREATE TABLE Other_Financial_Information (
	fin_ID INT NOT NULL AUTO_INCREMENT,
    fin_date DATE NOT NULL,
    investment_ID INT NOT NULL,
    interest_rate DECIMAL(5,3),
    inflation_rate DECIMAL(5,3),
    GDP_growth_rate DECIMAL(5,3),
    CONSTRAINT pk_fin        PRIMARY KEY (fin_ID),
    CONSTRAINT fk_fin_investment FOREIGN KEY (investment_ID) REFERENCES Investment(investment_ID) ON DELETE CASCADE
);


-- stored procedures
DELIMITER $$
CREATE PROCEDURE add_investment(IN i_name VARCHAR(255), IN i_type VARCHAR(255), IN shares INT, IN risk DECIMAL(4,3), IN stock_price DECIMAL(10,3), 
		IN exchange_rate DECIMAL(10,3), IN commodity_price DECIMAL(10,3), IN interest DECIMAL(5,3), IN inflation DECIMAL(5,3), IN GDP DECIMAL(5,3))
	MODIFIES SQL DATA
    DETERMINISTIC
    COMMENT "Add a new investment"
BEGIN
	INSERT INTO Investment(investment_name, investment_type, shares_held) VALUES 
		(i_name, i_type, shares);
	
	INSERT INTO Risk_Level(risk_level, total_return, annualized_return) VALUES
		(risk, shares * stock_price, shares * stock_price);

	INSERT INTO Performance_Metrics(investment_ID, risk_level_ID) VALUES
		( (SELECT investment_ID FROM Investment WHERE (investment_name = i_name)), (SELECT risk_level_ID FROM Risk_Level WHERE risk_level = risk));

	INSERT INTO Market_Data(metric_ID, market_date, stock_price, exchange_rate, commodity_price) VALUES
		( (SELECT metric_ID FROM Performance_Metrics WHERE risk_level_ID = (SELECT risk_level_ID FROM Performance_Metrics WHERE investment_ID = 
(SELECT investment_ID FROM Investment WHERE (investment_name = i_name)))), CURDATE(), stock_price, exchange_rate, commodity_price);
		
	INSERT INTO Other_Financial_Information(fin_date, investment_ID, interest_rate, inflation_rate, GDP_growth_rate) VALUES
		(CURDATE(), (SELECT investment_ID FROM Investment WHERE (investment_name = i_name)), interest, inflation, GDP);
END$$


DELIMITER $$
CREATE PROCEDURE add_investment_with_date(IN i_name VARCHAR(255), IN i_type VARCHAR(255), IN shares INT, IN risk DECIMAL(4,3), IN stock_price DECIMAL(10,3), 
		IN exchange_rate DECIMAL(10,3), IN commodity_price DECIMAL(10,3), IN interest DECIMAL(5,3), IN inflation DECIMAL(5,3), IN GDP DECIMAL(5,3), IN datevar DATE)
	MODIFIES SQL DATA
    DETERMINISTIC
    COMMENT "Add a new investment"
BEGIN
	INSERT INTO Investment(investment_name, investment_type, shares_held) VALUES 
		(i_name, i_type, shares);

	INSERT INTO Risk_Level(risk_level, total_return, annualized_return) VALUES
		(risk, shares * stock_price, shares * stock_price);

	INSERT INTO Performance_Metrics(investment_ID, risk_level_ID) VALUES
		( (SELECT investment_ID FROM Investment WHERE (investment_name = i_name)), (SELECT risk_level_ID FROM Risk_Level WHERE risk_level = risk));

	INSERT INTO Market_Data(metric_ID, market_date, stock_price, exchange_rate, commodity_price) VALUES
		( (SELECT metric_ID FROM Performance_Metrics WHERE risk_level_ID = (SELECT risk_level_ID FROM Performance_Metrics WHERE investment_ID = 
			(SELECT investment_ID FROM Investment WHERE (investment_name = i_name)))), datevar, stock_price, exchange_rate, commodity_price);
		
	INSERT INTO Other_Financial_Information(fin_date, investment_ID, interest_rate, inflation_rate, GDP_growth_rate) VALUES
		(datevar, (SELECT investment_ID FROM Investment WHERE (investment_name = i_name)), interest, inflation, GDP);
END$$


DELIMITER $$
CREATE PROCEDURE delete_investment(IN i_id INT)
	MODIFIES SQL DATA
    DETERMINISTIC
    COMMENT "Delete an investment"
BEGIN
	DELETE FROM Risk_Level WHERE risk_level_ID = (SELECT risk_level_ID FROM Performance_Metrics WHERE investment_ID = i_id);
    DELETE FROM Investment WHERE investment_ID = i_ID;
END$$


-- insert an investment
CALL add_investment("Tata", "stock", 2, 2.00, 140, NULL, NULL, 0.65, 0.54, 0.23);

-- update the shares in the investment table
UPDATE Investment SET shares_held = 3 WHERE investment_ID = 1;

-- delete the above investment
CALL delete_investment(1);


-- create more investments
-- in the order: investment_name, investment_type, shares, risk_level, stock_price, exchange_rate, commodity_price, interest_rate, inflation_rate, GDP_growth_rate
CALL add_investment_with_date("Tata", "stock", 30, 2.01, 140, 1.21, NULL, 0.65, 0.54, 0.23, "2023-01-17");
CALL add_investment_with_date("VI", "stock", 15, 1.21, 320, NULL, NULL, 0.22, 0.12, 0.3, "2023-01-11");
CALL add_investment_with_date("Taj", "stock", 300, 1, 120, 1.8, NULL, 0.65, 0.54, 0.23, "2023-01-19");
CALL add_investment_with_date("Reliance", "stock", 40, 2, 210, NULL, NULL, 0.15, 0.74, 0.21, "2023-03-19");
CALL add_investment_with_date("Titan", "stock", 320, 1.01, 110, NULL, NULL, 0.35, 0.14, 0.3, "2023-01-13");
CALL add_investment_with_date("Gold", "commodity", 310, 0.12, 432, NULL, 432, 0.45, 0.12, 0.1, "2023-04-13");
CALL add_investment_with_date("Oil", "commodity", 90, 0.61, 900, NULL, 900, 0.95, 0.84, 0.1, "2023-01-13");
CALL add_investment_with_date("Diamonds", "commodity", 1120, 4.01, 650, 3.21, NULL, 0.6, 0.1, 0.21, "2023-03-17");


-- add more market data
INSERT INTO Market_Data(metric_ID, market_date, stock_price, exchange_rate, commodity_price) VALUES
	(2, "2023-01-31", 170, 1.23, NULL), (2, "2023-02-13", 210, 2.11, NULL), (3, "2023-02-01", 450, NULL, NULL),
    (3, "2023-03-15", 360, NULL, NULL), (4, "2023-02-01", 450, NULL, NULL), (4, "2023-02-15", 450, NULL, NULL),
	(5, "2023-01-25", 130, NULL, NULL), (5, "2023-02-07", 145, NULL, NULL), (6, "2023-03-18", 90, NULL, NULL), 
    (6, "2023-04-01", 60, NULL, NULL), (7, "2023-05-11", 600, NULL, 600), (7, "2023-06-15", 900, NULL, 900),
    (8, "2023-01-23", 450, NULL, 450), (8, "2023-02-01", 500, NULL, 500), (9, "2023-04-01", 450, NULL, NULL)




-- ###################################################################################

-- SQL QUERIES

-- Join the investments table with the risk level table to retrieve the total return for each investment.
SELECT Investment.investment_name, Investment.investment_type, Risk_Level.total_return 
FROM Investment 
INNER JOIN Performance_Metrics ON Investment.investment_ID = Performance_Metrics.investment_ID 
INNER JOIN Risk_Level ON Risk_Level.risk_level_ID = Performance_Metrics.risk_level_ID;

-- Join the investments table with the market data table to retrieve the stock prices for a particular date.
SELECT Market_Data.stock_price, Market_Data.market_date, Investment.investment_name
FROM Investment
INNER JOIN Performance_Metrics ON Investment.investment_ID = Performance_Metrics.investment_ID 
INNER JOIN Market_Data on Performance_Metrics.metric_ID = Market_Data.metric_ID;

-- Group the investments by type and retrieve the average annualized return for each type.
SELECT Investment.investment_type, AVG(Risk_Level.annualized_return) AS average_annualized_return  
FROM Investment 
INNER JOIN Performance_Metrics ON Investment.investment_ID = Performance_Metrics.investment_ID 
INNER JOIN Risk_Level ON Risk_Level.risk_level_ID = Performance_Metrics.risk_level_ID
GROUP BY Investment.investment_type;

-- Filter the investments by risk level and retrieve the top-performing investments.
SELECT Investment.investment_name, Investment.investment_type, Risk_Level.risk_level 
FROM Investment 
INNER JOIN Performance_Metrics ON Investment.investment_ID = Performance_Metrics.investment_ID 
INNER JOIN Risk_Level ON Risk_Level.risk_level_ID = Performance_Metrics.risk_level_ID
ORDER BY Risk_Level.risk_level;

-- Calculate the total value of all investments based on the number of shares held and the current stock prices from the market data table.
SELECT SUM(Investment.shares_held) * SUM(Market_Data.stock_price) AS total_value
FROM Investment
INNER JOIN Performance_Metrics ON Investment.investment_ID = Performance_Metrics.investment_ID 
INNER JOIN Market_Data on Performance_Metrics.metric_ID = Market_Data.metric_ID;

-- Calculate the portfolio’s overall annualized return based on the investments’ individual returns and the number of shares held.
SELECT SUM(annualized_return) AS overall_annualized_return
FROM Risk_Level;

-- Retrieve the most recent inflation rate from the other financial information table.
SELECT inflation_rate 
FROM Other_Financial_Information
ORDER BY fin_date
DESC LIMIT 1;

-- Calculate the percentage change in stock prices for a particular investment between two dates.
SELECT Investment.investment_name, Market_Data.stock_price
FROM Investment
INNER JOIN Performance_Metrics ON Investment.investment_ID = Performance_Metrics.investment_ID 
INNER JOIN Market_Data on Performance_Metrics.metric_ID = Market_Data.metric_ID
WHERE Market_Data.market_date > "2023-01-01" AND Market_Data.market_date < "2023-06-01" AND Investment.investment_ID = 3;

-- Filter the market data table by date range and retrieve the stock prices for a particular investment (ID 3).
SELECT Market_Data.stock_price
FROM Investment
INNER JOIN Performance_Metrics ON Investment.investment_ID = Performance_Metrics.investment_ID 
INNER JOIN Market_Data on Performance_Metrics.metric_ID = Market_Data.metric_ID
WHERE Investment.investment_ID = 3;


-- Retrieve the top-performing investments based on annualized return and risk level.
SELECT Investment.investment_name, Investment.investment_type, Risk_Level.annualized_return, Risk_Level.risk_level 
FROM Investment 
INNER JOIN Performance_Metrics ON Investment.investment_ID = Performance_Metrics.investment_ID 
INNER JOIN Risk_Level ON Risk_Level.risk_level_ID = Performance_Metrics.risk_level_ID
ORDER BY (Risk_Level.annualized_return AND Risk_Level.risk_level);

-- Group the investments by type and retrieve the total number of shares held for each type
SELECT investment_type, SUM(shares_held) as total_number_of_shares
FROM Investment
GROUP BY investment_type;