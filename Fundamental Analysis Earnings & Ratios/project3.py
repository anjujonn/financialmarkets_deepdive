import yfinance as yf
import pandas as pd
from datetime import datetime

tickers = ['MSFT', 'AAPL', 'AVGO', 'XOM', 'ORCL', 'CVX', 'CRM', 'CSCO', 'CAT', 'QCOM', 'INTU', 'IBM', 'GE', 'COP']
companies_data = []
financial_metrics_data = []
ratios_data = []

company_id_map = {}
period_id_map = {}
company_counter = 1

valid_periods = [
    (2023, 'CQ1'), (2023, 'CQ2'), (2023, 'CQ3'), (2023, 'CQ4'),
    (2024, 'CQ1'), (2024, 'CQ2'), (2024, 'CQ3'), (2024, 'CQ4')
]

for idx, (year, quarter) in enumerate(valid_periods, start=1):
    period_id_map[(year, quarter)] = idx

for ticker in tickers:
    stock = yf.Ticker(ticker)
    info = stock.info

    symbol = info.get('symbol', ticker)
    name = info.get('longName', '')
    sector = info.get('sector', '')
    industry = info.get('industry', '')
    market_cap = info.get('marketCap')
    shares_outstanding = info.get('sharesOutstanding')

    company_id = company_counter
    company_id_map[symbol] = company_id
    companies_data.append((company_id, symbol, name, sector, industry))
    company_counter += 1

    try:
        financials = stock.quarterly_financials.T
    except Exception:
        continue

    try:
        dividends = stock.dividends
    except:
        dividends = pd.Series()

    for date in financials.index:
        dt = pd.to_datetime(date)
        year = dt.year
        month = dt.month
        quarter_num = (month - 1) // 3 + 1
        quarter = f"CQ{quarter_num}"

        if (year, quarter) in period_id_map:
            period_id = period_id_map[(year, quarter)]

            revenue = financials.loc[date].get("Total Revenue")
            net_income = financials.loc[date].get("Net Income")

            eps = None
            if net_income is not None and shares_outstanding:
                eps = float(net_income) / shares_outstanding

            dividend_val = float(dividends.loc[date]) if date in dividends.index else 0

            financial_metrics_data.append({
                'company_id': company_id,
                'period_id': period_id,
                'year': year,
                'revenue': revenue,
                'net_income': net_income,
                'eps': eps,
                'dividend': dividend_val,
                'market_cap': market_cap
            })

            pe_ratio = None
            dividend_yield = None
            profit_margin = None

            if net_income and market_cap:
                try:
                    pe_ratio = market_cap / net_income
                except ZeroDivisionError:
                    pe_ratio = None

            if eps and eps != 0:
                try:
                    dividend_yield = dividend_val / eps
                except ZeroDivisionError:
                    dividend_yield = None

            if revenue and net_income:
                try:
                    profit_margin = net_income / revenue
                except ZeroDivisionError:
                    profit_margin = None

            ratios_data.append({
                'company_id': company_id,
                'period_id': period_id,
                'pe_ratio': pe_ratio,
                'dividend_yield': dividend_yield,
                'profit_margin': profit_margin,
                'revenue_growth': None,
                'earnings_growth': None,
                'peg_ratio': None
            })

df_companies = pd.DataFrame(companies_data, columns=['company_id', 'symbol', 'company_name', 'sector', 'industry'])

df_periods = pd.DataFrame([
    {'period_id': period_id_map[(year, quarter)], 'year': year, 'quarter': quarter}
    for (year, quarter) in valid_periods
])

df_metrics = pd.DataFrame(financial_metrics_data)
df_ratios = pd.DataFrame(ratios_data)

df_companies = df_companies.sort_values('company_id')
df_periods = df_periods.sort_values('period_id')
df_metrics = df_metrics.sort_values(['company_id', 'period_id'])
df_ratios = df_ratios.sort_values(['company_id', 'period_id'])

df_companies.to_csv("companies.csv", index=False)
df_periods.to_csv("financial_periods.csv", index=False)
df_metrics.to_csv("financial_metrics.csv", index=False)
# df_ratios.to_csv("ratios.csv", index=False)

print("CSV files generated: companies.csv, financial_periods.csv, financial_metrics.csv, ratios.csv")
