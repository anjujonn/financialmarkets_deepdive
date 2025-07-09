-- query 1: most profitable companies
SELECT 
    company_id,
    pe_ratio,
    
    -- inverted P/E score to reward low P/E
    ROUND(1.0 / NULLIF(pe_ratio, 0), 4) AS pe_score,

    -- normalize values
    ROUND(profit_margin, 2) AS margin_score,
    ROUND(earnings_growth, 2) AS growth_score,

    -- weighted score
    ROUND( 
        (1.0 / NULLIF(pe_ratio, 0)) * 0.4 +
        profit_margin * 0.3 +
        earnings_growth * 0.3, 
        4
    ) AS profitability_score

FROM ratios
WHERE pe_ratio > 0
ORDER BY profitability_score DESC
LIMIT 10;


-- query 2: best dividend-paying stocks
-- rank dividend yield for a base-level idea
SELECT * 
FROM ratios
ORDER BY dividend_yield DESC
LIMIT 3; 

-- filter out based on low profit margin
SELECT * 
FROM ratios
WHERE profit_margin > 0.05
ORDER BY dividend_yield DESC
LIMIT 3;

-- filter based on reasonable p/e ratio --> is better when ratio is between 20 and 25
SELECT c.company_name, c.sector, pe_ratio, dividend_yield, profit_margin
FROM ratios r
JOIN companies c ON r.company_id = c.company_id
WHERE (c.sector = 'Information Technology') 
		AND (r.profit_margin > 0.05) 
        AND (r.pe_ratio >= 15 AND r.pe_ratio <= 40) 
ORDER BY r.dividend_yield DESC;

SELECT c.company_name, c.sector, pe_ratio, dividend_yield, profit_margin
FROM ratios r
JOIN companies c ON r.company_id = c.company_id
WHERE (c.sector = 'Energy') 
	AND (r.profit_margin > 0.05) 
    AND (r.pe_ratio >= 5 AND r.pe_ratio <= 20) 
ORDER BY r.dividend_yield DESC;

SELECT c.company_name, c.sector, pe_ratio, dividend_yield, profit_margin
FROM ratios r
JOIN companies c ON r.company_id = c.company_id
WHERE (c.sector = 'Industrials') 
	AND (r.profit_margin > 0.05) 
    AND (r.pe_ratio >= 10 AND r.pe_ratio <= 30) 
ORDER BY r.dividend_yield DESC;

SELECT c.company_name, ROUND(AVG(r.dividend_yield), 4) AS avg_dividend_yield,
FROM ratios r
JOIN companies c ON r.company_id = c.company_id
WHERE r.dividend_yield IS NOT NULL
GROUP BY r.company_id, c.company_name
ORDER BY avg_dividend_yield DESC
LIMIT 10;

-- query 3: companies with highest revenue growth
-- quarterly
SELECT * 
FROM ratios
ORDER BY revenue_growth DESC
LIMIT 6;

-- query 4:
SELECT
  c.symbol,
  c.company_name,
  c.company_id,
  p.year AS current_year,
  p.quarter AS current_quarter,
  f.revenue AS current_revenue,
  f.eps AS current_eps,
  f_prev.revenue AS prev_revenue,
  f_prev.eps AS prev_eps,

  -- Revenue Growth
  CASE
    WHEN f_prev.revenue IS NOT NULL AND f_prev.revenue != 0
      THEN ROUND((f.revenue - f_prev.revenue) / f_prev.revenue * 100, 2)
    ELSE NULL
  END AS revenue_growth,

  -- EPS Growth
  CASE
    WHEN f_prev.eps IS NOT NULL AND f_prev.eps != 0
      THEN ROUND((f.eps - f_prev.eps) / f_prev.eps * 100, 2)
    ELSE NULL
  END AS eps_growth

FROM FinancialMetrics f
JOIN FinancialPeriods p ON f.period_id = p.period_id
JOIN Companies c ON f.company_id = c.company_id

-- Join previous year’s same quarter
JOIN FinancialMetrics f_prev
  ON f.company_id = f_prev.company_id
  AND p.year = f_prev.year + 1
  AND p.quarter = f_prev.quarter
  AND f.period_id = f_prev.period_id + 4

ORDER BY c.symbol, p.year, p.quarter;
    
    
-- query 5
SELECT
    c.company_name,
    fp.year,
    fp.quarter,
	r.earnings_growth,
    r.pe_ratio,
    r.peg_ratio,
    CASE
        WHEN r.peg_ratio IS NULL THEN 'N/A'
        WHEN r.peg_ratio < 1 THEN 'Undervalued Growth'
        WHEN r.peg_ratio BETWEEN 1 AND 2 THEN 'Fair Value'
        ELSE 'Overvalued'
    END AS peg_category
FROM Ratios r
JOIN Companies c 
    ON r.company_id = c.company_id
JOIN FinancialPeriods fp
    ON r.period_id = fp.period_id
WHERE fp.year != 2023