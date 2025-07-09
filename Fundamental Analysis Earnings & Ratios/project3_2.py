import yfinance as yf
import pandas as pd
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import time

tickers = ['MSFT', 'AAPL', 'AVGO', 'XOM', 'ORCL', 'CVX', 'CRM', 'CSCO', 'CAT', 'QCOM', 'INTU', 'IBM', 'GE', 'COP']
START_YEAR = 2023
END_YEAR = 2024
QUARTERS = ['Q1', 'Q2', 'Q3', 'Q4']

SEC_HEADERS = {'User-Agent': 'DataScraper/1.0'}

def map_date_to_quarter(date):
    month = date.month
    if 1 <= month <= 3:
        return 'CQ1'
    elif 4 <= month <= 6:
        return 'CQ2'
    elif 7 <= month <= 9:
        return 'CQ3'
    else:
        return 'CQ4'

financial_periods = []
period_lookup = {}
period_id = 1
for year in range(START_YEAR, END_YEAR + 1):
    for q in QUARTERS:
        quarter_code = 'C' + q
        financial_periods.append({'period_id': period_id, 'year': year, 'quarter': quarter_code})
        period_lookup[(year, quarter_code)] = period_id
        period_id += 1

companies = []
financial_metrics = []
ratios = []

def get_sec_financials(ticker):
    try:
        cik_lookup = requests.get(f"https://www.sec.gov/files/company_tickers.json", headers=SEC_HEADERS).json()
        cik = None
        for record in cik_lookup.values():
            if record['ticker'].upper() == ticker.upper():
                cik = str(record['cik_str']).zfill(10)
                break
        if not cik:
            return None
        
        filings = requests.get(f"https://data.sec.gov/submissions/CIK{cik}.json", headers=SEC_HEADERS).json()
        reports = filings.get('filings', {}).get('recent', {})
        accession_numbers = reports.get('accessionNumber', [])
        forms = reports.get('form', [])
        filing_dates = reports.get('filingDate', [])

        results = {}

        for i, form in enumerate(forms):
            if form != '10-Q':
                continue
            filing_date = datetime.strptime(filing_dates[i], "%Y-%m-%d")
            year = filing_date.year
            quarter = map_date_to_quarter(filing_date)

            if (year, quarter) not in period_lookup:
                continue

            acc_num = accession_numbers[i].replace('-', '')
            url = f"https://www.sec.gov/Archives/edgar/data/{int(cik)}/{acc_num}/Financial_Report.xml"

            try:
                r = requests.get(url, headers=SEC_HEADERS)
                soup = BeautifulSoup(r.text, 'lxml')

                revenue = None
                net_income = None
                eps = None

                for tag in soup.find_all():
                    name = tag.name.lower()
                    text = tag.text.strip().replace(',', '')

                    if not text or not text.isdigit():
                        continue

                    value = float(text)

                    if 'revenues' in name or 'sales' in name:
                        revenue = value
                    if 'netincome' in name:
                        net_income = value
                    if 'eps' in name:
                        eps = value

                results[(year, quarter)] = {
                    'revenue': revenue,
                    'net_income': net_income,
                    'eps': eps
                }
            except Exception as e:
                print(f"Error fetching SEC data for {ticker}: {e}")

        return results

    except Exception as e:
        print(f"Error in SEC fetching: {e}")
        return None

company_id = 1
for symbol in tickers:
    print(f"Processing {symbol}...")
    ticker = yf.Ticker(symbol)
    info = ticker.info

    companies.append({
        'company_id': company_id,
        'symbol': symbol,
        'company_name': info.get('shortName', symbol),
        'sector': info.get('sector', None),
        'industry': info.get('industry', None)
    })

    sec_data = get_sec_financials(symbol)
    time.sleep(1)

    yf_data = {}
    try:
        quarterly_financials = ticker.quarterly_financials.T
        for idx, row in quarterly_financials.iterrows():
            date = idx
            year = date.year
            quarter = map_date_to_quarter(date)
            if (year, quarter) not in period_lookup:
                continue

            yf_data[(year, quarter)] = {
                'revenue': row.get('Total Revenue', None),
                'net_income': row.get('Net Income', None),
                'eps': None
            }
    except Exception as e:
        print(f"Error fetching YF data for {symbol}: {e}")

    all_periods = set(list(yf_data.keys()) + list(sec_data.keys() if sec_data else []))

    for (year, quarter) in all_periods:
        yf_entry = yf_data.get((year, quarter), {})
        sec_entry = sec_data.get((year, quarter), {}) if sec_data else {}

        revenue = yf_entry.get('revenue') or sec_entry.get('revenue')
        net_income = yf_entry.get('net_income') or sec_entry.get('net_income')
        eps = yf_entry.get('eps') or sec_entry.get('eps')

        financial_metrics.append({
            'company_id': company_id,
            'year': year,
            'period_id': period_lookup[(year, quarter)],
            'revenue': revenue,
            'net_income': net_income,
            'eps': eps,
            'dividend': info.get('dividendRate', 0),
            'market_cap': info.get('marketCap', 0)
        })

    try:
        latest_period_id = max(period_lookup.values())

        ratios.append({
            'company_id': company_id,
            'period_id': latest_period_id,
            'pe_ratio': info.get('trailingPE', None),
            'dividend_yield': info.get('dividendYield', None),
            'profit_margin': info.get('profitMargins', None),
            'revenue_growth': info.get('revenueGrowth', None),
            'earnings_growth': info.get('earningsGrowth', None),
            'peg_ratio': info.get('pegRatio', None)
        })
    except Exception as e:
        print(f"Error fetching ratios for {symbol}: {e}")

    company_id += 1

companies_df = pd.DataFrame(companies)
periods_df = pd.DataFrame(financial_periods)
metrics_df = pd.DataFrame(financial_metrics)
ratios_df = pd.DataFrame(ratios)

companies_df.to_csv("companies.csv", index=False)
periods_df.to_csv("financial_periods.csv", index=False)
metrics_df.to_csv("financial_metrics.csv", index=False)
ratios_df.to_csv("ratios.csv", index=False)

print("All data scraped and saved")
