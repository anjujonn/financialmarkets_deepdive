-- query 1: best-performing sector over time
SELECT s.sector,
    AVG(h.cumulative_return)*100 AS avg_sector_return
FROM Stocks s
JOIN Historical_Returns h ON s.stock_id = h.stock_id
GROUP BY s.sector
ORDER BY avg_sector_return DESC;

-- query 2: stocks w/ the lowest risk (return volitility)
SELECT
    s.symbol,
    s.company_name,
    s.sector,
    STDDEV(h.daily_return) AS raw_return_volitility,
    CONCAT(ROUND(STDDEV(h.daily_return) * 100, 2)'%') AS formatted_return_volitility
FROM Stocks s
JOIN Historical_Returns h ON s.stock_id = h.stock_id
GROUP BY s.symbol, s.company_name, s.sector
ORDER BY raw_return_volitility ASC;

-- query 3: portfolio returns based on diff stock weightings
-- formula: sum(dailyreturn * (allocation percentage/100))*100
SELECT p.portfolio_id, p.stock_id, s.symbol, s.sector,
    ROUND(SUM(hr.daily_return * (p.allocation_percentage/100))*100, 4)
    AS stock_contribution
FROM Portfolio p
JOIN Historical_Returns hr ON p.stock_id = hr.stock_id
JOIN Stocks s ON p.stock_id = s.stock_id
WHERE hr.date BETWEEN '2024-08-02' AND '2025-01-30'
GROUP BY p.portfolio_id, p.stock_id, s.symbol
ORDER BY p.portfolio_id, stock_contribution
DESC;