import os
import shutil
import zipfile

base_dir = r"d:\Projects\TeleSnap-Pro"
pkg_dir = os.path.join(base_dir, "Release_Packages", "TeleSnap_Pro_Gumroad_Edition")
if os.path.exists(pkg_dir):
    shutil.rmtree(pkg_dir)
os.makedirs(pkg_dir, exist_ok=True)

# 1. Experts folder
experts_dir = os.path.join(pkg_dir, "MQL5", "Experts")
os.makedirs(experts_dir, exist_ok=True)
shutil.copy2(os.path.join(base_dir, "MQL5", "Experts", "TeleSnap_Pro.ex5"), os.path.join(experts_dir, "TeleSnap_Pro.ex5"))
shutil.copy2(os.path.join(base_dir, "MQL5", "Experts", "TeleSnap_Lite.ex5"), os.path.join(experts_dir, "TeleSnap_Lite.ex5"))

# 2. Scripts folder
scripts_dir = os.path.join(pkg_dir, "MQL5", "Scripts")
os.makedirs(scripts_dir, exist_ok=True)
if os.path.exists(os.path.join(base_dir, "MQL5", "Scripts", "Open_TeleSnap_Hub.ex5")):
    shutil.copy2(os.path.join(base_dir, "MQL5", "Scripts", "Open_TeleSnap_Hub.ex5"), os.path.join(scripts_dir, "Open_TeleSnap_Hub.ex5"))

# 3. Presets folder
presets_dir = os.path.join(pkg_dir, "Presets")
os.makedirs(presets_dir, exist_ok=True)

scalper_set = """// TeleSnap Pro Preset: Ultra-Fast Scalper
InpCaptureTimeframe=1
InpIncludeCandles=120
InpWatermarkEnabled=true
InpAutoEntrySnap=true
InpAutoTPSnap=true
InpAutoSLSnap=true
InpMilestone50Pips=true
InpMilestone100Pips=true
InpSendDelayMs=50
"""
with open(os.path.join(presets_dir, "Fast_Scalper_M1_M5.set"), "w", encoding="utf-8") as f:
    f.write(scalper_set)

vip_set = """// TeleSnap Pro Preset: VIP Signal Channel Branded
InpCaptureTimeframe=0
InpIncludeCandles=100
InpWatermarkEnabled=true
InpWatermarkText=@midcodes
InpAutoEntrySnap=true
InpAutoTPSnap=true
InpAutoSLSnap=true
InpDailyRecapEnabled=true
InpRecapHourUTC=22
"""
with open(os.path.join(presets_dir, "VIP_Branded_Channel.set"), "w", encoding="utf-8") as f:
    f.write(vip_set)

prop_set = """// TeleSnap Pro Preset: Prop Firm Safe & Stealth
InpCaptureTimeframe=0
InpIncludeCandles=80
InpWatermarkEnabled=false
InpAutoEntrySnap=true
InpAutoTPSnap=true
InpAutoSLSnap=true
InpDailyRecapEnabled=true
"""
with open(os.path.join(presets_dir, "PropFirm_Stealth.set"), "w", encoding="utf-8") as f:
    f.write(prop_set)

# 4. Quick Start & Setup Guide
setup_guide = """# ⚡ TeleSnap Pro v2.0 - Complete Setup & Installation Guide

Thank you for purchasing **TeleSnap Pro**!

Follow this 2-minute setup to start broadcasting sub-300ms trading signals and chart snapshots directly from MetaTrader 5 to Telegram.

---

## 🚀 1-Minute Installation

1. Open your **MetaTrader 5** terminal.
2. In the top menu, click **File >> Open Data Folder**.
3. Copy the `MQL5` folder from this download and paste it into your Data Folder (it will merge into `MQL5/Experts` and `MQL5/Scripts`).
4. In MT5, locate the **Navigator** panel on the left (press `Ctrl + N` if hidden).
5. Right-click on **Expert Advisors** and select **Refresh**.
6. You will see **TeleSnap_Pro** listed!

---

## ⚙️ Step 1: Whitelist Telegram API in MT5 (CRITICAL)

MetaTrader 5 requires permission before sending HTTP WebRequests:
1. In MT5, press `Ctrl + O` (or click **Tools >> Options**).
2. Go to the **Expert Advisors** tab.
3. Check **"Allow WebRequest for listed URL"**.
4. Double-click the green `+` icon and type:
   ```text
   https://api.telegram.org
   ```
5. Click **OK**.

---

## 🤖 Step 2: Create Your Telegram Bot (Takes 30 Seconds)

1. Open Telegram and search for **@BotFather**.
2. Send `/newbot` and follow the prompts to choose a bot name and username.
3. Copy the **HTTP API Token** provided by BotFather (looks like: `7123456789:AAFx9...`).
4. Create or open your destination Telegram Channel or Group.
5. Add your new bot as an **Administrator** with permission to **Post Messages**.

---

## 🎯 Step 3: Attach TeleSnap Pro

1. Drag **TeleSnap_Pro** from the Navigator panel onto any open chart window (e.g. EURUSD, GBPUSD, or Gold).
2. In the **Inputs** tab:
   - **InpBotToken**: Paste your Telegram Bot Token.
   - **InpChatId**: Enter your Channel username (e.g., `@YourChannel`) or Chat ID (e.g., `-100192837465`).
   - **InpWatermarkText**: Enter your channel brand or link (e.g. `@midcodes`).
3. Click **OK**.
4. The chart HUD will turn green: `✅ TELEGRAM CONNECTED!`
5. TeleSnap Pro automatically saves your credentials securely — any other chart window will auto-sync without retyping!

---

## ⌨️ Hotkeys & Features

- **[F12] Key**: Instantly captures and sends the current chart to Telegram.
- **Floating [SNAP] HUD**: Click the on-chart HUD button for one-click manual signal broadcasts.
- **Auto-Execution Snaps**: TeleSnap automatically captures the setup the millisecond you or an EA open a trade.
- **Auto TP / SL Snaps**: Delivers proof-of-profit screenshots the moment Take Profit or Stop Loss triggers.
- **Daily Recap Report**: Generates an end-of-day institutional performance summary.

---

## 💬 Support & Community

- **Telegram Customer Service**: https://t.me/telesnap_pro_bot
- **Official Telegram Group**: https://t.me/midcodes
- **YouTube Channel**: https://youtube.com/@mid-code
- **GitHub Repository**: https://github.com/dchumari/TeleSnap-Pro
- **Gumroad Store**: https://dchumari.gumroad.com/l/yinlew

Happy Trading & High Profits!
"""
with open(os.path.join(pkg_dir, "QUICK_START_GUIDE.md"), "w", encoding="utf-8") as f:
    f.write(setup_guide)

license_txt = """=============================================================
TELESNAP PRO v2.0 - COMMERCIAL LICENSE & CUSTOMER SUPPORT
=============================================================

Product: TeleSnap Pro - Institutional MT5 to Telegram Dispatcher
Author: Derrick Chumari (@mid-code)
Official Store: https://dchumari.gumroad.com/l/yinlew
Repository: https://github.com/dchumari/TeleSnap-Pro

CUSTOMER SUPPORT & CHANNELS:
- 🤖 Customer Service Bot: https://t.me/telesnap_pro_bot
- 💬 Community & Discussion Group: https://t.me/midcodes
- 📺 Official YouTube Channel: https://youtube.com/@mid-code

LICENSE TERMS:
This commercial package grants you a single-user lifetime license 
to run TeleSnap Pro across your personal MetaTrader 5 trading accounts, 
prop firm evaluation accounts, and private VPS environments. 

Redistribution, reselling, or public file-sharing of the compiled 
commercial binary is strictly prohibited under international copyright.

Thank you for supporting independent financial software engineering!
=============================================================
"""
with open(os.path.join(pkg_dir, "LICENSE_&_SUPPORT.txt"), "w", encoding="utf-8") as f:
    f.write(license_txt)

# 5. Create the ZIP files
zip_rel = os.path.join(base_dir, "Release_Packages", "TeleSnap_Pro_v2.0_Gumroad.zip")
zip_root = os.path.join(base_dir, "TeleSnap_Pro_Gumroad.zip")

for target_zip in [zip_rel, zip_root]:
    with zipfile.ZipFile(target_zip, "w", zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(pkg_dir):
            for file in files:
                full_p = os.path.join(root, file)
                rel_p = os.path.relpath(full_p, pkg_dir)
                zipf.write(full_p, rel_p)

print("ZIP generated successfully at:")
print(zip_rel, os.path.getsize(zip_rel), "bytes")
print(zip_root, os.path.getsize(zip_root), "bytes")
