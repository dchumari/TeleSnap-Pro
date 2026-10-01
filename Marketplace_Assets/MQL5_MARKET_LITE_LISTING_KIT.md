# 🌟 TeleSnap Lite: Official MQL5 Market Listing Kit

---

## 1. Product Setup Details (Common Tab)

* **Product Title:** (Strictly 48 characters, starts with capital, compliant with MQL5 naming rules)
  ```text
  TeleSnap Lite Telegram Signal and Multi Chart Hub
  ```
  *(Note: Do not put the word "Free" or version numbers like "v2.0" in the title; MetaQuotes automated title filters reject them).*

* **Product Category:** Select **`Utilities`**
* **Utility Type:** Check the following 3 boxes:
  * ☑️ **`Informers`**
  * ☑️ **`Panels`**
  * ☑️ **`Chart management`**

* **Pricing:**
  * ☑️ Check the box for **`Free`** (Zero USD).

---

## 2. Product Icon & Screenshots

* **Icon (200x200 px):**
  Use: `D:\Projects\TeleSnap-Pro\Marketplace_Assets\icon_200x200.png`
* **Screenshots:**
  Use the high-resolution showcase graphics in `Marketplace_Assets\`:
  1. `showcase_command_center.jpg`
  2. `showcase_telegram_delivery.jpg`
  3. `terminal_live_command_center.png`
  4. `terminal_chart_hud.png`

---

## 3. Product Binary File (Versions Tab)

* **Upload File:**
  ```text
  D:\Projects\TeleSnap-Pro\MQL5\Experts\TeleSnap_Lite.ex5
  ```

---

## 4. Product Description (Copy & Paste directly into Description Tab)

```html
<p><b>TeleSnap Lite</b> is the free, high-performance Telegram trade notification and multi-chart monitoring utility for MetaTrader 5. It bridges your terminal directly to your Telegram channels and personal groups with zero human latency.</p>

<p>Whether you execute trades manually or run algorithmic robots, TeleSnap Lite tracks your positions, captures HD charts with entry/SL/TP annotations, and dispatches them to your mobile Telegram in under 300 milliseconds.</p>

<h3>⚡ Key Features</h3>
<ul>
  <li><b>High-Speed Multi-Chart Dispatcher:</b> Operates from a single host chart and monitors your open terminal charts.</li>
  <li><b>Sub-300ms Native Networking:</b> Built with pure native MQL5 WebRequest—zero third-party DLLs, zero external installations, and 100% cloud VPS friendly.</li>
  <li><b>Interactive Floating HUD:</b> On-chart <b>[SNAP]</b> and <b>[SEND + NOTE]</b> buttons allow 1-click instant screenshot delivery to Telegram.</li>
  <li><b>Auto Trade Snapping:</b> Automatically detects when you open, close, or modify positions and captures the exact chart state at that millisecond.</li>
  <li><b>Trade Analytics & P/L Metrics:</b> Every alert includes net profit, risk-to-reward, execution price, and duration.</li>
  <li><b>Local Encrypted Storage:</b> Saves your Bot Token and Chat ID safely so other charts load them automatically.</li>
</ul>

<h3>🚀 TeleSnap Edition Comparison</h3>
<table border="1" cellpadding="6" cellspacing="0">
  <tr bgcolor="#f0f0f0">
    <th>Feature</th>
    <th>TeleSnap Lite (Free)</th>
    <th>TeleSnap Pro (Commercial)</th>
  </tr>
  <tr>
    <td><b>Chart Snapping Speed</b></td>
    <td>⚡ Under 300ms</td>
    <td>⚡ Under 300ms</td>
  </tr>
  <tr>
    <td><b>Telegram Signal Dispatching</b></td>
    <td>✅ Full Support</td>
    <td>✅ Full Support</td>
  </tr>
  <tr>
    <td><b>Floating Chart HUD Buttons</b></td>
    <td>✅ Included</td>
    <td>✅ Included</td>
  </tr>
  <tr>
    <td><b>Automatic Entry/Close Detection</b></td>
    <td>✅ Included</td>
    <td>✅ Included</td>
  </tr>
  <tr>
    <td><b>Multi-Chart Command Center Dashboard</b></td>
    <td>Standard Hub</td>
    <td>👑 Advanced Interactive Matrix</td>
  </tr>
  <tr>
    <td><b>Floating Profit Milestones (Pips)</b></td>
    <td>❌ Disabled</td>
    <td>👑 Auto-Snap Every +25/50/100 Pips</td>
  </tr>
  <tr>
    <td><b>End-of-Day Performance Recap</b></td>
    <td>❌ Disabled</td>
    <td>👑 Full Win Rate, Profit Factor & Breakdown</td>
  </tr>
  <tr>
    <td><b>Custom VIP Channel Watermarking</b></td>
    <td>Standard Badge</td>
    <td>👑 Fully Custom Handle, Invite Link & Styling</td>
  </tr>
  <tr>
    <td><b>Remote Inbound Telegram Commands (/snap)</b></td>
    <td>❌ Disabled</td>
    <td>👑 Full 2-Way Bot Control</td>
  </tr>
</table>

<p>👉 <i>Need custom branding, profit milestone auto-snaps, daily performance summaries, and 2-way remote commands? Upgrade to <b>TeleSnap Pro</b> in the Market!</i></p>

<h3>🔧 Quick 2-Minute Setup</h3>
<ol>
  <li>In MT5, click <b>Tools >> Options >> Expert Advisors</b>.</li>
  <li>Check <b>"Allow WebRequest for listed URL"</b> and add:
      <br><code>https://api.telegram.org</code></li>
  <li>Create a Telegram bot via <b>@BotFather</b> and copy the API Token.</li>
  <li>Add your bot to your target channel or group as an Administrator.</li>
  <li>Attach <b>TeleSnap Lite</b> to any chart, enter your Bot Token and Chat ID, and click OK!</li>
</ol>

<h3>🛡️ 100% Safe & Clean Code</h3>
<ul>
  <li>Zero DLL imports (strictly compliant with MQL5 Market security standards).</li>
  <li>Zero speculative trading on your real accounts—it only monitors and broadcasts.</li>
  <li>Lightweight event-driven architecture designed for zero CPU lag.</li>
</ul>
```
