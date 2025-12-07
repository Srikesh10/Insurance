import requests
import json
from datetime import datetime, timedelta
import statistics

# Free APIs - no authentication needed
def get_bitcoin_data():
    """Get Bitcoin price data from CoinGecko (free, no auth)"""
    url = "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart"
    params = {
        'vs_currency': 'usd',
        'days': '90',  # Last 90 days
        'interval': 'daily'
    }
    try:
        response = requests.get(url, params=params, timeout=10)
        data = response.json()
        prices = data['prices']
        return [(datetime.fromtimestamp(p[0]/1000), p[1]) for p in prices]
    except Exception as e:
        print(f"Error fetching Bitcoin data: {e}")
        return []

def calculate_daily_returns(prices):
    """Calculate daily percentage returns"""
    returns = []
    for i in range(1, len(prices)):
        prev_price = prices[i-1][1]
        curr_price = prices[i][1]
        daily_return = ((curr_price - prev_price) / prev_price) * 100
        returns.append((prices[i][0], daily_return))
    return returns

def analyze_volatility(returns):
    """Analyze Bitcoin volatility"""
    return_values = [r[1] for r in returns]
    avg_return = statistics.mean(return_values)
    volatility = statistics.stdev(return_values)
    
    # Count large movements
    large_moves = [r for r in return_values if abs(r) > 5]
    
    return {
        'avg_daily_return': avg_return,
        'volatility': volatility,
        'large_moves_count': len(large_moves),
        'max_gain': max(return_values),
        'max_loss': min(return_values)
    }

print("Fetching Bitcoin data...")
btc_prices = get_bitcoin_data()

if btc_prices:
    print(f"\nGot {len(btc_prices)} days of Bitcoin price data")
    print(f"Date range: {btc_prices[0][0].date()} to {btc_prices[-1][0].date()}")
    print(f"Price range: ${btc_prices[0][1]:,.0f} to ${btc_prices[-1][1]:,.0f}")
    
    returns = calculate_daily_returns(btc_prices)
    stats = analyze_volatility(returns)
    
    print("\n=== Bitcoin Statistics (Last 90 Days) ===")
    print(f"Average Daily Return: {stats['avg_daily_return']:.2f}%")
    print(f"Daily Volatility (StdDev): {stats['volatility']:.2f}%")
    print(f"Days with >5% movement: {stats['large_moves_count']}")
    print(f"Largest single-day gain: {stats['max_gain']:.2f}%")
    print(f"Largest single-day loss: {stats['max_loss']:.2f}%")
    
    # Show recent large movements
    print("\n=== Recent Large Bitcoin Movements (>5%) ===")
    large_moves = [(r[0], r[1]) for r in returns if abs(r[1]) > 5][-10:]
    for date, return_pct in large_moves:
        direction = "📈 UP" if return_pct > 0 else "📉 DOWN"
        print(f"{date.date()}: {direction} {abs(return_pct):.2f}%")
else:
    print("Failed to fetch Bitcoin data")

print("\n=== Next Step ===")
print("To test correlation with stocks like Nvidia (NVDA), MicroStrategy (MSTR),")
print("we need stock price data. Unfortunately, free stock APIs have rate limits.")
print("\nBUT - we can see Bitcoin has significant volatility and large movements.")
print("This is the first step in testing if these movements predict stock prices.")
