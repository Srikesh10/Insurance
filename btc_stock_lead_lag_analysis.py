"""
Bitcoin → Crypto-Exposed Stock Lead-Lag Analysis
=================================================

This shows the STRUCTURE of how to test if Bitcoin price movements
PREDICT stock movements in crypto-exposed companies.

Data needed:
- Bitcoin hourly/daily prices
- Stock prices for: NVDA, MSTR, COIN, MARA, RIOT
- Time period: 2022-2025 (covers both crises)

Analysis steps:
"""

import pandas as pd
import numpy as np
from scipy import stats

# ============================================
# STEP 1: Calculate Returns
# ============================================

def calculate_returns(prices):
    """
    Convert prices to percentage returns

    Example:
    Day 1: BTC = $50,000, NVDA = $300
    Day 2: BTC = $52,000, NVDA = $305

    BTC return = (52000-50000)/50000 = 4%
    NVDA return = (305-300)/300 = 1.67%
    """
    returns = prices.pct_change() * 100  # Convert to percentage
    return returns.dropna()


# ============================================
# STEP 2: Test Lead-Lag Relationship
# ============================================

def test_btc_leads_stock(btc_returns, stock_returns, lag_hours=6):
    """
    Test if Bitcoin returns PREDICT stock returns X hours later

    Hypothesis: If Bitcoin moves up 5% at 10 AM,
                does NVDA move up at 4 PM (6 hours later)?

    Method: Correlation between BTC(t) and NVDA(t+lag)
    """

    # Shift stock returns forward to align with earlier BTC moves
    stock_lagged = stock_returns.shift(-lag_hours)

    # Calculate correlation
    correlation = btc_returns.corr(stock_lagged)

    # Statistical test
    n = len(btc_returns)
    t_stat = correlation * np.sqrt(n - 2) / np.sqrt(1 - correlation**2)
    p_value = stats.t.sf(abs(t_stat), n-2) * 2  # Two-tailed test

    return {
        'lag_hours': lag_hours,
        'correlation': correlation,
        'p_value': p_value,
        'significant': p_value < 0.05
    }


# ============================================
# STEP 3: Granger Causality Test
# ============================================

def granger_causality(btc_returns, stock_returns, max_lag=24):
    """
    Granger Causality: Does past BTC help predict future stock movement?

    This is the "gold standard" test for lead-lag relationships

    Result interpretation:
    - p < 0.05: Bitcoin DOES Granger-cause stock movement
    - p > 0.05: No evidence Bitcoin predicts stock
    """
    # This would use statsmodels.tsa.stattools.grangercausalitytests
    # Requires: pip install statsmodels
    pass


# ============================================
# STEP 4: Event Study - Large Movements
# ============================================

def event_study_large_btc_moves(btc_returns, stock_returns, threshold=5):
    """
    Focus on LARGE Bitcoin movements (>5%) and see what happens to stocks

    Example:
    - Find all days where BTC moved >5%
    - Check if NVDA moved significantly 6, 12, 24 hours later

    This is more practical than continuous correlation
    """

    # Find large BTC moves
    large_moves = btc_returns[abs(btc_returns) > threshold]

    results = []
    for timestamp in large_moves.index:
        btc_move = large_moves[timestamp]

        # Check stock movement 6h, 12h, 24h later
        for lag in [6, 12, 24]:
            future_time = timestamp + pd.Timedelta(hours=lag)
            if future_time in stock_returns.index:
                stock_move = stock_returns[future_time]
                results.append({
                    'btc_move': btc_move,
                    'stock_move': stock_move,
                    'lag_hours': lag
                })

    return pd.DataFrame(results)


# ============================================
# STEP 5: Crisis-Specific Analysis
# ============================================

def crisis_analysis(btc_returns, stock_returns):
    """
    Test if lead-lag is stronger DURING crises

    Compare:
    - Normal periods: weak or no relationship
    - Crisis periods: strong BTC → stock relationship

    This is your UNIQUE contribution if true
    """

    # Define crisis windows
    crisis_periods = [
        ('2022-02-24', '2022-03-31', 'Russia-Ukraine'),
        ('2025-04-02', '2025-05-07', 'Tariff Crisis')
    ]

    results = {}
    for start, end, name in crisis_periods:
        # Filter to crisis period
        crisis_btc = btc_returns[start:end]
        crisis_stock = stock_returns[start:end]

        # Test relationship
        correlation = crisis_btc.corr(crisis_stock.shift(-6))  # 6-hour lag

        results[name] = correlation

    return results


# ============================================
# EXPECTED RESULTS (My Prediction)
# ============================================

print("""
WHAT YOU'LL PROBABLY FIND:
==========================

1. NVIDIA (NVDA):
   - Weak correlation (~0.2-0.3)
   - Bitcoin doesn't really predict NVDA
   - NVDA moves on chip demand, not crypto prices

2. MICROSTRATEGY (MSTR):
   - STRONG correlation (~0.7-0.8)
   - MSTR literally holds Bitcoin on balance sheet
   - Probably SIMULTANEOUS, not predictive (they move together)

3. COINBASE (COIN):
   - Medium correlation (~0.5-0.6)
   - Trading volume drives COIN, Bitcoin price drives volume
   - Might see 2-6 hour lag

4. MINING STOCKS (MARA, RIOT):
   - Strong correlation (~0.6-0.7)
   - Bitcoin price → mining profitability → stock price
   - Possible 6-12 hour lag as market digests

5. DURING CRISES:
   - Correlations STRONGER during crisis
   - Lead-lag timing SHORTER (faster reaction)
   - This is your novel finding if true

BOTTOM LINE:
- Bitcoin probably doesn't PREDICT most stocks
- It CORRELATES with crypto-exposed stocks
- During CRISIS, reaction is faster and stronger
- This is worth documenting even if not predictive
""")


# ============================================
# YOUR RESEARCH QUESTION (Refined)
# ============================================

print("""
RECOMMENDED RESEARCH QUESTION:
==============================

"Do crypto-exposed equity securities exhibit differential sensitivity
to Bitcoin price shocks during geopolitical crisis periods?"

Translation:
When Bitcoin crashes 10% during a crisis, do stocks like MSTR/COIN/MARA
crash HARDER and FASTER than during normal periods?

WHY THIS IS GOOD:
- Testable with public data
- Novel angle (crisis amplification)
- Connects DeFi (Bitcoin) to TradFi (stocks)
- Doesn't require prediction (just correlation analysis)
- Guaranteed to find SOMETHING (relationship definitely exists)

DATA YOU NEED:
- Bitcoin hourly prices (CoinGecko API - free)
- Stock hourly prices (Alpha Vantage API - free tier)
- Crisis dates (you already have these)

TIME TO EXECUTE:
- 1 week: Data collection
- 1 week: Analysis (correlation, Granger, event study)
- 1 week: Write-up
- = 3 weeks total

DIFFICULTY: Medium
- Easier than DeFi wallet analysis (no bot filtering!)
- Harder than just descriptive stats (need time series methods)
- Granger causality is learnable in 2-3 days
""")