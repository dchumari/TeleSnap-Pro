# ⚡ TeleSnap Lite (v2.00) — Installation & Quick Start Guide

Welcome to **TeleSnap Lite**! TeleSnap automatically captures high-definition chart snapshots and delivers structured trade alert cards to your Telegram channels, groups, and forum topics in real-time.

---

## 🚀 3-Minute Quick Setup

### Step 1: Copy File to MetaTrader 5
1. Open your **MetaTrader 5** terminal.
2. In the top menu, click **File ➔ Open Data Folder**.
3. Open the **`MQL5`** folder, then open the **`Experts`** folder.
4. Copy `TeleSnap_Lite.ex5` into `MQL5/Experts/`.
5. Return to MT5, find the **Navigator** window (Ctrl+N), right-click **Expert Advisors**, and click **Refresh**.

---

### Step 2: Enable WebRequest for Telegram
MetaTrader 5 requires permission to communicate with Telegram:
1. In MT5, go to **Tools ➔ Options** (or press Ctrl+O).
2. Click the **Expert Advisors** tab.
3. Check the box: **"Allow WebRequest for listed URL"**.
4. Double-click the list below it, add this exact URL, and press Enter:
   ```text
   https://api.telegram.org
   ```
5. Click **OK**.

---

### Step 3: Get Your Bot Token & Chat ID
1. **Create a Bot:**
   * Open Telegram and message `@BotFather`.
   * Send `/newbot`, follow the prompts, and copy your **HTTP API Token** (e.g. `7891234567:AAHxxxxxx...`).
2. **Add Bot to Your Channel or Group:**
   * Open your Telegram Channel or Supergroup.
   * Go to Administrators ➔ Add Administrator ➔ Search for your bot username ➔ Grant admin permissions (Post Messages).
3. **Get Your Chat ID:**
   * For public channels: Your `@username` (e.g. `@myforexchannel`).
   * For private channels/groups: Forward a message from the channel to `@userinfobot` or `@getmyid_bot` to get the numeric ID starting with `-100` (e.g. `-1001928374650`).

---

### Step 4: Attach TeleSnap & Start Snapping!
1. Open any chart in MT5 (e.g., EURUSD).
2. From the **Navigator** panel, drag **TeleSnap Lite** onto the chart.
3. In the **Inputs** tab:
   * **InpBotToken:** Paste your Bot Token.
   * **InpChatId:** Enter your Channel/Group ID.
   * **InpMessageThreadId:** Enter Topic ID if using a Telegram Forum (leave `0` for general chat).
4. Click **OK**.
5. The **Command Center Dashboard** will appear. All your active charts are automatically detected and linked with on-chart **[ 📸 SNAP ]** and **[ 💬 SEND + NOTE ]** buttons!

---

## 🌟 Key Features
* 🖥️ **Multi-Chart Command Center:** Manage all open charts from one central window.
* 📸 **Interactive On-Chart HUD:** Instant 1-click snap button directly on your trading charts.
* 🤖 **Auto-Event Snapping:** Automatically captures entry setups, TP hits, SL hits, partial closes, and breakeven exits.
* 📊 **Daily Performance Recap:** Click `[ 📊 POST RECAP ]` on the Command Center to post a verified daily win/loss summary card to your Telegram channel.
* 🛡️ **100% Zero-DLL Safe:** Native MQL5 network stack, completely safe and reliable.

---

### 👑 Need Custom Watermarks, Milestones & Remote Commands?
Upgrade to **TeleSnap Pro** on the MQL5 Marketplace:
* Custom Brand Watermark & VIP Invite Links
* Target Milestone Auto-Snapping (+50, +100, +200 pips)
* Telegram Inbound Commands (`/snap EURUSD`, `/recap`, `/status`)
* Priority Support & Multi-Channel Routing

👉 **Get TeleSnap Pro:** [https://www.mql5.com/](https://www.mql5.com/)  
⚡ **Support Bot:** `@TeleSnap`
