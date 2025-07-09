#old
import yfinance as yf
import numpy as np

# Stocks
STOCKS = [
    {"symbol": "AAPL", "company_name": "Apple Inc.", "sector": "Technology"},
    {"symbol": "MSFT", "company_name": "Microsoft Corporation", "sector": "Technology"},
    {"symbol": "GOOGL", "company_name": "Alphabet Inc.", "sector": "Communication Services"},
    {"symbol": "AMZN", "company_name": "Amazon.com Inc.", "sector": "Consumer Discretionary"},
    {"symbol": "TSLA", "company_name": "Tesla Inc.", "sector": "Consumer Discretionary"},
    {"symbol": "META", "company_name": "Meta Platforms Inc.", "sector": "Communication Services"},
    {"symbol": "NVDA", "company_name": "Nvidia Corporation", "sector": "Technology"},
    {"symbol": "AMD", "company_name": "Advanced Micro Devices Inc.", "sector": "Technology"},
    {"symbol": "COST", "company_name": "Costco Wholesale Corporation", "sector": "Consumer Staples"},
    {"symbol": "TSM", "company_name": "Taiwan Semiconductor Manufacturing Company Ltd.", "sector": "Technology"}
]

# 6 month period
start_date = "2024-08-01"
end_date = "2025-01-31"

# SQL Table Creation Statements
sql_create_tables = """\
CREATE TABLE Stocks (
    stock_id INT PRIMARY KEY,
    symbol VARCHAR(10) NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    sector VARCHAR(50) NOT NULL
);

CREATE TABLE Historical_Returns (
    return_id INT PRIMARY KEY,
    stock_id INT REFERENCES Stocks(stock_id),
    date DATE NOT NULL,
    daily_return DECIMAL(10, 4),
    cumulative_return DECIMAL(10, 4)
);

CREATE TABLE Portfolio (
    portfolio_id INT PRIMARY KEY,
    stock_id INT REFERENCES Stocks(stock_id),
    allocation_percentage DECIMAL(5, 2)
);
"""

# SQL INSERT statements
insert_stocks = []
insert_returns = []
insert_portfolio = []

return_id_counter = 1
volatility = {}

# Fetch and process stock data
for i, stock in enumerate(STOCKS, start=1):
    symbol = stock["symbol"]

    # stock name
    insert_stocks.append(
        f"INSERT INTO Stocks (stock_id, symbol, company_name, sector) VALUES "
        f"({i}, '{symbol}', '{stock['company_name']}', '{stock['sector']}');"
    )

    data = yf.Ticker(symbol).history(start=start_date, end=end_date)

    if data.empty:
        print(f"Warning: No data found for {symbol}. Skipping.")
        continue

    dates = list(data.index)
    closes = list(data["Close"])

    cumulative_return = 0
    daily_returns = []

    # daily and cumulative returns
    for j in range(1, len(closes)):
        date = dates[j].strftime('%Y-%m-%d')
        prev_close = closes[j - 1]
        curr_close = closes[j]

        if prev_close == 0:
            daily_return = 0
        else:
            daily_return = (curr_close - prev_close) / prev_close

        daily_returns.append(daily_return)
        cumulative_return = (1 + daily_return) * (1 + cumulative_return) - 1

        # historical returns
        insert_returns.append(
            f"INSERT INTO Historical_Returns (return_id, stock_id, date, daily_return, cumulative_return) VALUES "
            f"({return_id_counter}, {i}, '{date}', {daily_return:.4f}, {cumulative_return:.4f});"
        )
        return_id_counter += 1  

    # Find the stock's volatility
    if daily_returns:
        volatility[symbol] = np.std(daily_returns)
    else:
        volatility[symbol] = 1 

# inverse volatility
inv_vol = {s: 1 / v for s, v in volatility.items() if v > 0}  
total_inv_vol = sum(inv_vol.values())

# Calculate allocation percentage
for i, stock in enumerate(STOCKS, start=1):
    symbol = stock["symbol"]
    weight = (inv_vol.get(symbol, 0) / total_inv_vol) * 100  
    
    insert_portfolio.append(
        f"INSERT INTO Portfolio (portfolio_id, stock_id, allocation_percentage) VALUES "
        f"({i}, {i}, {weight:.2f});"
    )

# Save SQL statements to a file
with open("insert_statements.sql", "w") as f:
    f.write(sql_create_tables + "\n\n")
    f.write("\n".join(insert_stocks) + "\n\n")
    f.write("\n".join(insert_returns) + "\n\n")
    f.write("\n".join(insert_portfolio))

print("SQL INSERT statements generated! Copy and paste them into SQL Playground.")