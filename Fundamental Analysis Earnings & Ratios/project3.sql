CREATE TABLE Companies (
  company_id INT AUTO_INCREMENT PRIMARY KEY,
  symbol VARCHAR(10) NOT NULL,
  company_name VARCHAR(255) NOT NULL,
  sector VARCHAR(100),
  industry VARCHAR(100)
);
CREATE TABLE Financials (
  report_id INT AUTO_INCREMENT PRIMARY KEY,
  company_id INT NOT NULL,
  report_year INT NOT NULL,
  revenue DECIMAL(15, 2),
  net_income DECIMAL(15, 2),
  eps DECIMAL(10, 4),
  dividend DECIMAL(10, 4),
  market_cap DECIMAL(15, 2),
  FOREIGN KEY (company_id) REFERENCES Companies(company_id)
);

CREATE TABLE Ratios (
  ratio_id INT AUTO_INCREMENT PRIMARY KEY,
  company_id INT NOT NULL,
  report_year INT NOT NULL,
  pe_ratio DECIMAL(10, 2),
  dividend_yield DECIMAL(15, 8),
  profit_margin DECIMAL(10, 4),
  FOREIGN KEY (company_id) REFERENCES Companies(company_id)
);

INSERT INTO Ratios (company_id, report_year, pe_ratio, dividend_yield, profit_margin)
SELECT 
    company_id,
    report_year,
    -- P/E Ratio
    CASE 
        WHEN net_income != 0 THEN ROUND(market_cap / net_income, 2)
        ELSE NULL
    END AS pe_ratio,
    -- Dividend Yield 
    CASE 
        WHEN market_cap != 0 THEN ROUND(dividend / market_cap, 8)
        ELSE NULL
    END AS dividend_yield,
    -- Profit Margin
    CASE 
        WHEN revenue != 0 THEN ROUND(net_income / revenue, 4)
        ELSE NULL
    END AS profit_margin
FROM Financials;

SELECT * 
FROM ratios
ORDER BY dividend_yield DESC;
-- LIMIT 3;

-- rank dividend yield for a base-level idea
SELECT * 
FROM ratios
ORDER BY dividend_yield DESC;

-- filter out based on low profit margin
SELECT * 
FROM ratios
WHERE profit_margin > 0.05
ORDER BY dividend_yield DESC;

-- filter based on reasonable p/e ratio --> is better when ratio is between 20 and 25
SELECT * 
FROM ratios r
JOIN companies c ON r.company_id = c.company_id
WHERE (c.sector = 'Information Technology') AND (r.profit_margin > 0.05) AND (r.pe_ratio >= 20 AND r.pe_ratio <= 35) 
ORDER BY r.dividend_yield DESC;

SELECT * 
FROM ratios r
JOIN companies c ON r.company_id = c.company_id
WHERE (c.sector = 'Energy') AND (r.profit_margin > 0.05) AND (r.pe_ratio >= 7 AND r.pe_ratio <= 15) 
ORDER BY r.dividend_yield DESC;

SELECT * 
FROM ratios r
JOIN companies c ON r.company_id = c.company_id
WHERE (c.sector = 'Industrials') AND (r.profit_margin > 0.05) AND (r.pe_ratio >= 15 AND r.pe_ratio <= 25) 
ORDER BY r.dividend_yield DESC;

-- companies with highest revenue growth
SELECT * ,
	CASE 
		ROUND((revenue))
FROM financials