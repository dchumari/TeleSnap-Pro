# 📦 MQL5 MARKET OFFICIAL PRODUCT SUBMISSION KIT

---

## 1. Product Listing Essentials

* **Product Title (Max 60 chars):**  
  `TeleSnap: Telegram Auto Trader Sniper & Multi-Chat Hub` (53 chars)
  
* **Short Description (Tagline):**  
  `Enterprise trade dispatcher & signal broadcaster. Transmits instant HD chart snapshots, trade event cards, and breakeven alerts directly to Telegram.`

* **Category:**  
  `Experts` ➔ `Utilities`

* **Pricing & Licenses:**  
  * **1-Month Rental:** `$29.00 USD`  
  * **3-Month Rental:** `$59.00 USD`  
  * **Unlimited Lifetime Purchase:** `$79.00 USD`  
  * **Activations:** `10 Activations` (standard hardware-locked activations)

* **Icon Asset:**  
  `Marketplace_Assets/icon_200x200.png` (200x200 PNG with the official glassmorphic camera aperture shutter design)

---

## 2. Full Product Description (Copy & Paste for MQL5 Market Editor)

```text
TeleSnap is an institutional-grade MetaTrader 5 trade communication hub and automated signal dispatcher. It connects your MT5 terminal directly to your Telegram channels, VIP supergroups, and forum topics with zero human latency.

Unlike traditional signal utilities that require attaching an EA to every single asset chart, TeleSnap features a centralized Command Center Dashboard. From a single host window, TeleSnap dynamically monitors all open terminal charts, injects interactive on-chart HUD widgets, and broadcasts high-definition chart snapshots whenever orders are executed, modified, or closed.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌟 KEY CAPABILITIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Centralized Command Center Hub:
   Attach TeleSnap to just ONE host chart. It automatically discovers every active trading window in your terminal and lets you link, unlink, or control charts with a single click.

2. Automated Event Snapping:
   Instant, automated high-definition chart captures sent directly to Telegram upon:
   • New Order Placed (Market & Pending Limits/Stops)
   • Stop Loss & Take Profit Modifications
   • Real-Time Breakeven Movements ($0.00 Risk Alerts)
   • Trailing Stop Profit Lock-in Notifications
   • Take Profit Hit, Stop Loss Hit, or Manual Position Closure
   • Milestone Floating Profit Alerts (+50, +100, +150 pips)

3. Interactive On-Chart HUD:
   Every linked chart receives a floating, draggable control bar featuring:
   • [SNAP (F12)]: One-click instant manual chart capture.
   • [COMMENT BOX]: Type customized technical analysis or trader notes directly on the chart and dispatch it seamlessly to your community.

4. Daily Performance Recap:
   Automatically compiles an End-of-Day audited breakdown of all trades, win rate, net profit, and profit factor, delivered straight to your channel at the close of the trading day.

5. Two-Way Telegram Inbound Commands:
   Remotely control your terminal from anywhere in the world using authorized bot commands:
   • /snap — Takes an instant snapshot of the active chart.
   • /snap [Symbol] — Captures a specific symbol chart remotely.
   • /recap — Posts the day's performance summary on demand.
   • /status — Verifies terminal heartbeat and connected charts.

6. 100% Native MQL5 (Zero Windows DLLs):
   TeleSnap utilizes native WebRequest communication. There are zero third-party DLL dependencies, ensuring maximum security, lightning-fast execution, and seamless compatibility with all VPS and Windows environments.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ 3-MINUTE QUICK SETUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1: Whitelist Telegram API in MetaTrader 5
1. Go to Tools -> Options -> Expert Advisors (or press Ctrl + O).
2. Check "Allow WebRequest for listed URL".
3. Add: https://api.telegram.org
4. Click OK.

Step 2: Create Telegram Bot & Obtain Credentials
1. Message @BotFather on Telegram and type /newbot.
2. Copy your Bot Token.
3. Add your Bot as an Administrator with "Post Messages" permission in your channel or supergroup.

Step 3: Attach TeleSnap
1. Open any chart and attach TeleSnap.
2. Enter your InpBotToken and InpChatId in the Inputs tab.
3. Credentials are saved locally—you never have to re-enter them again!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚙️ INPUT PARAMETERS GUIDE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• InpEnableCommandCenter (default: true) — Enables the dark-mode Command Center dashboard on host chart.
• InpAutoLinkOpenCharts (default: true) — Automatically links all open terminal charts.
• InpBotToken — Your Telegram Bot API token.
• InpChatId — Channel username (@channel) or numeric Chat ID (-100xxxxxxxxx).
• InpMessageThreadId (default: 0) — Supergroup Forum Topic ID (leave 0 for regular channels).
• InpMilestoneStepPips (default: 50) — Auto-snaps when floating profit crosses milestone intervals (+50, +100 pips). Set 0 to disable.
• InpEnableDailyRecap (default: true) — Dispatches an End-of-Day trading performance report.
• InpDailyRecapHour (default: 23) — Server hour for daily recap dispatch.
• InpResolution (default: 1280x720 HD) — Chart capture resolution (Current Chart, HD 720p, or FHD 1080p).
• InpCaptionStyle (default: Institutional) — Layout formatting (Minimal, Detailed, Institutional).
• InpHotkeyKey (default: 123) — Virtual keyboard shortcut for manual snapshots (123 = F12).

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛡️ SUPPORT & ASSISTANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Need help configuring your Telegram bot or channel? Please feel free to reach out via the Comments tab or send a direct message through the MQL5 community portal.
```

---

## 3. Screenshots Checklist for Upload

When creating the product on MQL5 Market, upload the following image files:
1. **Showcase 1 (Dashboard Overview):** `Marketplace_Assets/showcase_command_center.jpg`
2. **Showcase 2 (Mobile Delivery / Real-time alerts):** `Marketplace_Assets/showcase_telegram_delivery.jpg`
3. **Live MT5 Capture 1 (Command Center Matrix):** `Marketplace_Assets/terminal_live_command_center.png`
4. **Live MT5 Capture 2 (Chart HUD & Trade Alerts):** `Marketplace_Assets/terminal_chart_hud.png`
5. **Additional live trade screenshots** as you capture them.

---

## 4. How to Submit on MQL5 Market

1. Log into your MQL5 account under `dchumari@gmail.com` at:  
   👉 `https://www.mql5.com/en/market/add`
2. Choose **Category:** `Expert Advisors` ➔ `Utilities`.
3. Enter Title: `TeleSnap: Telegram Auto Trader Sniper & Multi-Chat Hub`.
4. Upload Icon: Select `icon_200x200.png`.
5. Upload Screenshots: Select the showcase and live terminal screenshots.
6. Paste the Full Product Description from Section 2 above.
7. Set Prices:
   * Purchase: `$79`
   * 1-Month Rent: `$29`
   * 3-Month Rent: `$59`
   * Activations: `10`
8. Upload Code: Upload `TeleSnap_Pro.mq5` (located at `C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\TeleSnap_Pro.mq5`).
9. Click **Save** and click **Submit for Moderation**.
