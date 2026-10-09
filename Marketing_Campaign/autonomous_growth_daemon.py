"""
TeleSnap Pro - Autonomous Growth & Marketing Daemon
Executes automated Telegram outreach, Twitter/X posting via zendriver, and conversion logging.
"""

import os
import sys
import time
import json
import csv
import random
import asyncio
import subprocess

if sys.platform.startswith('win'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LEADS_JSON = os.path.join(BASE_DIR, "telegram_leads_150.json")
LEADS_CSV  = os.path.join(BASE_DIR, "telegram_leads_150.csv")
LOG_FILE   = os.path.join(BASE_DIR, "campaign_history.log")
STATE_FILE = os.path.join(BASE_DIR, "campaign_state.json")

YOUTUBE_URL = "https://www.youtube.com/watch?v=vw__LEKD1qs"
MQL5_FREE_URL = "https://www.mql5.com/en/market/product/198951"
MQL5_PRO_URL  = "https://www.mql5.com/en/market/product/198931"

def log_event(message):
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
    entry = f"[{timestamp}] {message}"
    print(entry)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(entry + "\n")

def load_state():
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {"last_tweet_index": 0, "total_dms_sent": 0, "last_run": None}

def save_state(state):
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)

def load_leads():
    with open(LEADS_JSON, "r", encoding="utf-8") as f:
        return json.load(f)

def save_leads(leads):
    with open(LEADS_JSON, "w", encoding="utf-8") as f:
        json.dump(leads, f, indent=2, ensure_ascii=False)
    
    fieldnames = ["id", "channel_name", "telegram_link", "username", "admin_contact", "category", "geography", "audience_tier", "outreach_hook", "priority", "status", "contacted_at"]
    with open(LEADS_CSV, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()
        for row in leads:
            writer.writerow(row)

# =========================================================================
# MODULE 1: AUTONOMOUS TELEGRAM OUTREACH ENGINE
# =========================================================================
def generate_personalized_message(lead):
    category = lead.get("category", "")
    admin = lead.get("admin_contact", "")
    channel = lead.get("channel_name", "")
    admin_name = admin.replace("@", "").split("_")[0] if admin else "Chief"

    if "Gold" in category:
        return (
            f"Hey {admin_name}, love the clean Gold setups on {channel}!\n\n"
            "Quick observation: On fast XAUUSD spikes, taking 45 seconds to crop charts and type Entry/SL/TP often costs your VIP members 10–20 pips of slippage before they can get filled.\n\n"
            "I built an institutional MT5 utility called TeleSnap Pro to solve this:\n"
            "• 1-Click F12 chart snapshot sent to your channel in 300ms\n"
            "• Auto-stamps your channel watermark (stops signal piracy)\n"
            "• Auto-calculates floating pips, R:R, and SL/TP levels\n\n"
            f"Watch the 30s demonstration on MT5: {YOUTUBE_URL}\n\n"
            "Giving 5 verified Gold admins lifetime access for $39 today ($99 on MQL5 Market) in exchange for honest feedback. Would this save you time on your daily updates?"
        )
    elif "Prop" in category or "SMC" in category:
        return (
            f"Hey {admin_name}, solid execution on those setups on {channel}!\n\n"
            "As someone managing funded traders through prop challenges, you know trade journaling and visual proof are critical.\n\n"
            "TeleSnap Pro automates your entire Telegram signal feed directly from MT5:\n"
            "1. 1-Click F12 chart snapper with on-chart trader commentary notes\n"
            "2. Automated snapshots on trade entry, breakeven, and take-profit\n"
            "3. End-of-Day Daily Recap: Automatically audits and posts your daily win rate & total pips every evening\n"
            "4. 100% compliant with prop rules (Zero DLLs, native WebRequest)\n\n"
            f"Watch the 30s workflow demo: {YOUTUBE_URL}\n\n"
            "Happy to give you a demo activation to test on your live/challenge terminal. Open to checking it out?"
        )
    elif "Kenya" in category or "East Africa" in category:
        return (
            f"Habari {admin_name}, nimeona kazi safi unayofanya kwa channel yako ya {channel}!\n\n"
            "Mimi ni software engineer na trader hapa Nairobi. Nimeunda utility ya MetaTrader 5 inaitwa TeleSnap Pro inayotuma charts na trade alerts kwa Telegram instantly kwa 300ms bila snipping tool.\n\n"
            "• F12 tu inapiga snapshot na kuweka watermark ya channel yako\n"
            "• Inahesabu pips na kuweka Entry/SL/TP mara moja kwa Telegram\n"
            "• Ina Daily Performance Recap inayotumwa kila jioni kuonyesha matokeo ya siku\n\n"
            f"Cheki hii 30-second demo video: {YOUTUBE_URL}\n"
            f"Iko live pia kwenye official MQL5 Market: {MQL5_FREE_URL}\n\n"
            "Kama local trader mwenzangu, ningependa kukupa license ya Pro ujaribu au discount maalum kwa ajili ya feedback yako. Unasemaje?"
        )
    else:
        return (
            f"Hello {admin_name},\n\n"
            f"I manage development for TeleSnap Pro, an institutional MT5 communication utility for trading communities like {channel}.\n\n"
            "TeleSnap Pro resolves latency and signal piracy:\n"
            "• Dispatches watermarked HD chart captures in sub-300ms via native MT5 WebRequest\n"
            "• Embeds your custom brand logo and channel link directly into the image\n"
            "• Automatically audits and posts an End-of-Day PnL recap to retain VIP members\n\n"
            f"Short 30s overview: {YOUTUBE_URL}\n"
            f"Official MQL5 Store: {MQL5_PRO_URL}\n\n"
            "We are providing pilot licenses to selected desks this week. Would you like a demo activation for your terminal?"
        )

def execute_telegram_batch(batch_size=5):
    log_event(f"🚀 Initializing Autonomous Telegram Outreach (Target Batch: {batch_size} leads)...")
    leads = load_leads()
    pending = [l for l in leads if l.get("status", "Pending Outreach") == "Pending Outreach"]

    if not pending:
        log_event("✅ All 155 leads in the database have already been contacted!")
        return 0

    batch = pending[:batch_size]
    sent_count = 0

    try:
        import pyautogui
        import pyperclip
        pyautogui.FAILSAFE = False
    except ImportError:
        log_event("⚠️ pyautogui or pyperclip missing, installing...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "pyautogui", "pyperclip"])
        import pyautogui
        import pyperclip
        pyautogui.FAILSAFE = False

    for lead in batch:
        admin_handle = lead.get("admin_contact", "").replace("@", "").strip()
        channel = lead.get("channel_name", "")
        lead_id = lead.get("id")

        if not admin_handle:
            continue

        message = generate_personalized_message(lead)
        log_event(f"📤 Preparing DM for Lead #{lead_id} ({channel} - @{admin_handle})...")

        # Copy to clipboard
        pyperclip.copy(message)

        # Summon Telegram chat via Windows protocol
        tg_url = f"tg://resolve?domain={admin_handle}"
        os.system(f"start {tg_url}")

        # Wait for Telegram desktop window to open and focus
        time.sleep(3.5)

        # Paste message and send
        try:
            pyautogui.hotkey('ctrl', 'v')
            time.sleep(1.0)
            pyautogui.press('enter')
            log_event(f"✅ Dispatched DM to @{admin_handle} via Telegram Desktop!")
            sent_count += 1

            lead["status"] = "Contacted"
            lead["contacted_at"] = time.strftime('%Y-%m-%d %H:%M:%S')
            save_leads(leads)

        except Exception as e:
            log_event(f"⚠️ Error sending to @{admin_handle}: {e}")

        # Safe randomized anti-spam delay
        delay = random.uniform(6.0, 10.0)
        log_event(f"⏳ Cooling down for {delay:.1f}s to preserve account safety...")
        time.sleep(delay)

    log_event(f"🎉 Telegram batch completed: {sent_count} messages sent successfully.")
    return sent_count

# =========================================================================
# MODULE 2: AUTONOMOUS TWITTER / X POSTING ENGINE (ZENDRIVER)
# =========================================================================
TWITTER_PROMPTS = [
    (
        "How Telegram signal providers lose 15–20 pips of slippage for their VIPs:\n\n"
        "1. Spot MT5 setup 📉\n"
        "2. Open Snipping Tool (20s)\n"
        "3. Crop & save image (15s)\n"
        "4. Upload to Telegram, type Entry/SL/TP (20s)\n\n"
        "Total delay: 55 seconds. On Gold, that trade is gone.\n\n"
        "Here's how we fixed it with 1-click MT5 code: 👇🧵\n"
        f"{YOUTUBE_URL}\n\n"
        "#Forex #XAUUSD #MetaTrader5 #TradingSignals"
    ),
    (
        "Tired of clunky Python bots and risky Windows DLLs just to send an MT5 chart to Telegram.\n\n"
        "So over the last few months, I built TeleSnap Pro from scratch in Nairobi.\n\n"
        "Today, it's live on the global MetaQuotes MQL5 Marketplace.\n\n"
        f"Watch the 30s demonstration: 👇\n{YOUTUBE_URL}\n\n"
        "#Forex #MQL5 #MT5 #AlgorithmicTrading #ForexKenya"
    ),
    (
        "If you run a VIP Forex or Gold signal channel in 2026, stop taking photos of your laptop with your phone 📸📱\n\n"
        "TeleSnap Pro snaps your MT5 chart in 300ms, calculates live pips, and watermarks your brand automatically.\n\n"
        f"Free Community Edition on MQL5 Market:\n👉 {MQL5_FREE_URL}\n\n"
        "#TradingSignals #PropFirm #FTMO #GoldSignals"
    )
]

async def execute_twitter_post():
    log_event("🐦 Checking Autonomous Twitter / X Posting Bridge...")
    import urllib.request
    
    # Check if Chrome Remote Debugging port 9222 is active
    port_open = False
    try:
        with urllib.request.urlopen("http://127.0.0.1:9222/json/version", timeout=1.5) as resp:
            if resp.status == 200:
                port_open = True
    except Exception:
        port_open = False

    if not port_open:
        log_event("ℹ️ Chrome debugging bridge on port 9222 not active. Run 'launch_chrome_agent.bat' once to enable live Twitter thread dispatching.")
        return

    try:
        import zendriver as zd
    except ImportError:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "zendriver"])
        import zendriver as zd

    state = load_state()
    tweet_idx = state.get("last_tweet_index", 0) % len(TWITTER_PROMPTS)
    tweet_content = TWITTER_PROMPTS[tweet_idx]

    try:
        browser = await zd.start(host="127.0.0.1", port=9222)
        page = await browser.get("https://x.com/compose/post")
        await asyncio.sleep(3)

        editor = await page.select('div[data-testid="tweetTextarea_0"]')
        if editor:
            log_event(f"📝 Publishing Tweet #{tweet_idx + 1}...")
            await editor.send_keys(tweet_content)
            await asyncio.sleep(2)

            post_btn = await page.select('button[data-testid="tweetButton"]')
            if post_btn:
                await post_btn.click()
                log_event("✅ Successfully posted tweet to Twitter / X!")
                state["last_tweet_index"] = tweet_idx + 1
                save_state(state)
        else:
            log_event("⚠️ Tweet composer not detected in active tab.")

        await browser.stop()
    except Exception as e:
        log_event(f"⚠️ Twitter posting note: {e}")

# =========================================================================
# MASTER DISPATCHER
# =========================================================================
def run_autonomous_cycle():
    log_event("==================================================================")
    log_event("⚡ TELESNAP PRO — AUTONOMOUS MARKETING CYCLE TRIGGERED")
    log_event("==================================================================")

    state = load_state()
    state["last_run"] = time.strftime('%Y-%m-%d %H:%M:%S')

    # Step 1: Telegram Outreach (5 leads per execution)
    sent = execute_telegram_batch(batch_size=5)
    state["total_dms_sent"] = state.get("total_dms_sent", 0) + sent

    # Step 2: Twitter Campaign
    try:
        asyncio.run(execute_twitter_post())
    except Exception as e:
        log_event(f"Twitter cycle note: {e}")

    save_state(state)
    log_event("==================================================================")
    log_event("🎉 Autonomous marketing cycle finished successfully.")
    log_event("==================================================================")

if __name__ == "__main__":
    run_autonomous_cycle()
