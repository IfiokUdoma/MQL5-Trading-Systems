# Khokmah Trading Systems

**Algorithmic trading systems, custom indicators, alerts, and trade-management tools built with MQL5 for MetaTrader 5.**

Khokmah Trading Systems is a collection of trading software and automation tools developed in **MQL5** using the **MetaTrader 5 (MT5)** platform.

The repository contains Expert Advisors, custom trading alerts, indicator-confluence systems, Telegram-integrated notifications, and automated trade analytics.

The goal is to turn trading strategies and workflows into structured, automated software.

---

## Systems

### 1. Khokmah Trading Bot

An automated trading system developed for MetaTrader 5.

The system is designed to translate defined trading logic into an executable Expert Advisor capable of monitoring market conditions and managing trading decisions programmatically.

Key capabilities may include:

* Automated market monitoring
* Strategy-based trade execution
* Configurable trading parameters
* Entry and exit logic
* Risk and trade-management controls
* Position monitoring
* Automated execution through MT5

The bot is designed to reduce the need for manual execution once the defined trading conditions are satisfied.

---

### 2. TradeSync Confluence Pro

**Multi-indicator trading confluence system for MetaTrader 5.**

TradeSync Confluence Pro combines multiple technical indicators into a unified decision framework rather than relying on a single indicator independently.

The system can evaluate signals from indicators such as:

* Moving Average (MA)
* MACD
* RSI
* Additional technical conditions

The objective is to identify situations where multiple technical conditions align.

### Confluence Concept

Instead of treating each indicator as an isolated signal:

**MA**

↓

**MACD**

↓

**RSI**

↓

**Additional Conditions**

↓

**Confluence**

↓

**Trading Signal**

This approach is intended to filter weaker signals and provide a more structured interpretation of market conditions.

---

### 3. Custom Price Alert

A custom MT5 alert system designed to monitor market conditions using multiple technical indicators.

The alert engine combines several indicators, including:

* Moving Average
* MACD
* RSI
* Additional technical conditions

When configured conditions are satisfied, the system can generate alerts rather than requiring the trader to continuously monitor the chart.

### Telegram Integration

The alert system includes **Telegram integration**, allowing trading alerts to be delivered externally.

This enables a workflow such as:

**Market Data**

→ **Indicator Analysis**

→ **Condition Matching**

→ **Alert Trigger**

→ **Telegram Notification**

This makes the system useful for traders who want to monitor opportunities without remaining continuously in front of MetaTrader 5.

---

### 4. TradeStats Pro

**Virtual Financial Secretary**

TradeStats Pro is an automated trade-journaling and reporting system designed to function as a virtual financial secretary for trading activity.

Rather than requiring every trade to be manually recorded and analyzed, the system monitors trading activity and generates structured reports and analytics.

### Trade Journal

The system can track trading activity and organize information such as:

* Trades
* Entries
* Exits
* Profit and loss
* Trading performance
* Account activity
* Historical results

### Automated Reports

TradeStats Pro supports configurable reporting periods.

Current report settings include:

* Daily summary
* Weekly report
* Monthly statement
* Configurable report time

Example configuration:

```text
Daily Report:    Disabled
Weekly Report:   Enabled
Monthly Report:  Enabled
Report Time:     17:00
```

The system is designed to transform raw trading activity into understandable performance information.

---

## Technology

The systems in this repository are developed using:

* **MQL5**
* **MetaTrader 5**
* MetaEditor
* Technical indicators
* Automated trading logic
* Trading APIs / platform functions
* Telegram integration
* Automated reporting and analytics

---

## System Architecture

The overall ecosystem can be viewed as four complementary components:

```text
                 KHOKMAH TRADING SYSTEMS

                        ┌───────────────┐
                        │   Market Data │
                        └───────┬───────┘
                                │
                 ┌──────────────┴──────────────┐
                 │                             │
                 ▼                             ▼
        ┌─────────────────┐          ┌──────────────────┐
        │ Trading Systems │          │ Alert Systems    │
        │                 │          │                  │
        │ Khokmah Bot     │          │ Price Alert      │
        │ TradeSync       │          │ + Telegram       │
        └────────┬────────┘          └─────────┬────────┘
                 │                             │
                 └──────────────┬──────────────┘
                                ▼
                       ┌──────────────────┐
                       │ Trading Activity │
                       └────────┬─────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │ TradeStats Pro   │
                       │                  │
                       │ Journal          │
                       │ Analytics        │
                       │ Reports          │
                       └──────────────────┘
```

---

## Repository Structure

The repository contains the individual MQL5 systems as separate source files:

```text
khokmah-trading-systems/
│
├── Khokmah-Trading-Bot.mq5
├── TradeSync-Confluence-Pro.mq5
├── Custom-Price-Alert.mq5
├── TradeStats-Pro.mq5
│
└── README.md
```

---

## Development Philosophy

These systems are built around a simple principle:

> **Turn trading ideas into executable systems.**

The projects explore different layers of algorithmic trading technology:

**Strategy**

Convert defined trading rules into executable logic.

**Confluence**

Combine multiple technical conditions to improve signal filtering.

**Automation**

Reduce repetitive manual monitoring and execution.

**Communication**

Deliver important market events through external notifications such as Telegram.

**Analytics**

Convert trading activity into structured reports and performance information.

---

## Use Cases

The systems can support:

* Algorithmic trading research
* Strategy development
* Technical-analysis automation
* Market monitoring
* Trading alerts
* Automated trade journaling
* Performance analysis
* Trading reports
* Telegram-based notifications
* MT5 workflow automation

---

## Development Status

**Active Development**

The systems are experimental and continuously being refined as trading logic, automation features, analytics, and integrations evolve.

---

## Important Disclaimer

These systems are software projects for trading automation, research, experimentation, and analysis.

They **do not guarantee profitability** and should not be interpreted as financial advice.

Automated trading involves significant financial risk. Strategies should be properly tested through backtesting, forward testing, and appropriate risk controls before being used with real capital.

Never expose broker credentials, trading-account credentials, API keys, Telegram bot tokens, or other sensitive information in this repository.

---

## Author

**Ifiok Essienubong Udoma**

Product Developer • Software Developer • Chemical Engineer • Venture Builder

GitHub: https://github.com/IfiokUdoma

---

## License

MIT License
