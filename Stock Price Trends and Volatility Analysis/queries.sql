-- query 1: most volitile stocks based on % change
SELECT sp.stock_id, s.symbol, s.company_name,
    CONCAT(ROUND(AVG((sp.high - sp.low)/(sp.low  * 100)), 2), '%') AS avg_volitility
FROM Stock_Prices sp
JOIN Stocks s ON sp.stock_id = s.stock_id
GROUP BY sp.stock_id
ORDER BY AVG((sp.high - sp.low)/sp.low * 100) DESC;

-- query 2: stocks with the highest average trading volume
SELECT sp.stock_id, s.symbol, s.company_name, 
    CONCAT(ROUND(AVG(sp.volume) / POW(10, FLOOR(LOG10(AVG(sp.volume)))), 2), 
    'e+',
    FLOOR(LOG10(AVG(sp.volume)))
    ) AS avg_daily_trading_volume
FROM Stock_Prices sp
JOIN Stocks s ON sp.stock_id = s.stock_id
GROUP BY sp.stock_id
ORDER BY AVG(sp.volume) DESC;

-- query 3:
SELECT * FROM (
    SELECT 
        sp.stock_id, 
        sp.symbol, 
        sp.date, 
        sp.close_price, 
        ma.five_day_avg, 
        ma.twenty_day_avg,
            CASE
                WHEN sp.close_price > ma.five_day_avg 
                    AND LAG(sp.close_price) OVER (PARTITION BY sp.stock_id ORDER BY sp.date) <= LAG(ma.five_day_avg) OVER (PARTITION BY sp.stock_id ORDER BY sp.date) 
                THEN 'Crossed Above 5-Day'
                
                WHEN sp.close_price < ma.five_day_avg 
                    AND LAG(sp.close_price) OVER (PARTITION BY sp.stock_id ORDER BY sp.date) >= LAG(ma.five_day_avg) OVER (PARTITION BY sp.stock_id ORDER BY sp.date) 
                THEN 'Crossed Below 5-Day'
                
                WHEN sp.close_price > ma.twenty_day_avg 
                    AND LAG(sp.close_price) OVER (
                            PARTITION BY sp.stock_id 
                            ORDER BY sp.date
                        ) <= LAG(ma.twenty_day_avg) OVER (
                            PARTITION BY sp.stock_id ORDER BY sp.date) 
                    THEN 'Crossed Above 20-Day'

                    WHEN sp.close_price < ma.twenty_day_avg
                        AND LAG(sp.close_price) OVER (
                                PARTITION BY sp.stock_id 
                                ORDER BY sp.date 
                            ) >= LAG(ma.twenty_day_avg) OVER (PARTITION BY sp.stock_id ORDER BY sp.date)
                        THEN 'Crossed Below 20-Day'
                
                    ELSE 'No Cross'
                END AS cross_status
    FROM
        Stock_Prices sp
    JOIN
        Stocks s ON sp.stock_id = s.stock_id
    JOIN
        Moving_Average ma 
        ON sp.stock_id = ma.stock_id 
        AND sp.date = ma.date
    WHERE
        sp.date BETWEEN '2024-09-01' AND '2025-02-28'
    ORDER BY
        sp.date
) AS temp
WHERE cross_status != 'No Cross';

-- MACD
SELECT sp.stock_id, s.symbol, sp.date, sp.close_price,
    md.MACD, md.Signal_Line, md.Trading_Signal
FROM Stock_Prices sp
JOIN Stocks s ON sp.stock_id = s.stock_id
JOIN MACD_Data md ON sp.stock_id = md.stock_id AND sp.date = md.date
ORDER BY sp.date;