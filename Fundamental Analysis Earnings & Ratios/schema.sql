CREATE TABLE Companies (
  company_id INT AUTO_INCREMENT PRIMARY KEY,
  symbol VARCHAR(10) NOT NULL,
  company_name VARCHAR(255) NOT NULL,
  sector VARCHAR(100),
  industry VARCHAR(100)
);
CREATE TABLE FinancialPeriods (
    period_id INT AUTO_INCREMENT PRIMARY KEY,
    year INT NOT NULL,
    quarter VARCHAR(3) NOT NULL,  -- e.g., 'CQ1', 'CQ2'
    UNIQUE (year, quarter)
);

CREATE TABLE FinancialMetrics (
    report_id INT AUTO_INCREMENT PRIMARY KEY,
    company_id INT NOT NULL,
    year INT NOT NULL,
    period_id INT NOT NULL,
    revenue DECIMAL(15, 2),
    net_income DECIMAL(15, 2),
    eps DECIMAL(10, 4),
    dividend DECIMAL(15, 2),
    market_cap DECIMAL(20, 2),
    
    FOREIGN KEY (company_id) REFERENCES Companies(company_id),
    FOREIGN KEY (period_id) REFERENCES FinancialPeriods(period_id),
    UNIQUE (company_id, period_id)
); 

-- Ratios Table
CREATE TABLE Ratios (
    ratio_id INT AUTO_INCREMENT PRIMARY KEY,
    company_id INT NOT NULL,
    period_id INT NOT NULL,
    pe_ratio DECIMAL(10, 2),
    dividend_yield DECIMAL(10, 8),
    profit_margin DECIMAL(8, 4),
    revenue_growth DECIMAL(8, 4),
    earnings_growth DECIMAL(8, 2),
	peg_ratio DECIMAL(10, 4),
    FOREIGN KEY (company_id) REFERENCES Companies(company_id),
    FOREIGN KEY (period_id) REFERENCES FinancialPeriods(period_id),
    UNIQUE (company_id, period_id)
);


INSERT INTO Ratios (
    company_id, 
    period_id, 
    pe_ratio,
    dividend_yield,
    profit_margin,
    revenue_growth,
    earnings_growth,
    peg_ratio
)
SELECT 
    f.company_id,
    f.period_id,

    -- P/E Ratio (Only for Q4)
    CASE 
        WHEN fp.quarter = 'CQ4' AND SUM(past.net_income) >= 10
        THEN ROUND(f.market_cap / SUM(past.net_income), 2)
        ELSE NULL
    END AS pe_ratio,

    -- Dividend Yield (Quarterly)
    CASE 
        WHEN f.market_cap > 0 
        THEN ROUND(f.dividend / f.market_cap, 8)
        ELSE NULL
    END AS dividend_yield,

    -- Profit Margin (Quarterly)
    CASE 
        WHEN f.revenue > 0 
        THEN ROUND(f.net_income / f.revenue, 4)
        ELSE NULL
    END AS profit_margin,

    -- Revenue Growth (Quarterly YoY %)
    CASE
        WHEN prev_fm.revenue IS NOT NULL AND prev_fm.revenue != 0
        THEN ROUND(((f.revenue - prev_fm.revenue) / prev_fm.revenue) * 100, 2)
        ELSE NULL
    END AS revenue_growth,

    -- EPS Growth (Quarterly YoY %)
    CASE
        WHEN prev_fm.eps IS NOT NULL AND prev_fm.eps != 0
        THEN ROUND(((f.eps - prev_fm.eps) / prev_fm.eps) * 100, 2)
        ELSE NULL
    END AS earnings_growth,

    -- PEG Ratio (Only if P/E exists and EPS Growth > 0)
    CASE
        WHEN fp.quarter = 'CQ4'
             AND SUM(past.net_income) >= 10
             AND prev_fm.eps IS NOT NULL 
             AND prev_fm.eps != 0
             AND ROUND(((f.eps - prev_fm.eps) / prev_fm.eps) * 100, 2) > 0
        THEN ROUND(
            (f.market_cap / SUM(past.net_income)) 
            / ROUND(((f.eps - prev_fm.eps) / prev_fm.eps) * 100, 2), 
        4)
        ELSE NULL
    END AS peg_ratio

FROM FinancialMetrics f

JOIN FinancialPeriods fp
    ON f.period_id = fp.period_id

JOIN FinancialMetrics past
    ON f.company_id = past.company_id
   AND past.period_id BETWEEN f.period_id - 3 AND f.period_id

LEFT JOIN FinancialPeriods prev_fp
    ON prev_fp.quarter = fp.quarter
   AND prev_fp.year = fp.year - 1

LEFT JOIN FinancialMetrics prev_fm
    ON prev_fm.company_id = f.company_id
   AND prev_fm.period_id = prev_fp.period_id

GROUP BY 
    f.company_id,
    f.period_id,
    fp.quarter,
    f.market_cap,
    f.dividend,
    f.net_income,
    f.revenue,
    f.eps,
    prev_fm.revenue,
    prev_fm.eps;