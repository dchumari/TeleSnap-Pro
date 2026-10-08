"""
TeleSnap Pro - Twitter/X Autonomous Poster & Engagement Agent
Attaches to live Google Chrome (Profile 1) session on localhost:9222 via Chrome DevTools Protocol (CDP).
"""

import sys
import time
import os

if sys.platform.startswith('win'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

def connect_and_post():
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("❌ Playwright not found. Install via: pip install playwright")
        return

    print("==================================================================")
    print("⚡ TELESNAP PRO — TWITTER / X AUTOMATION AGENT")
    print("Connecting to Chrome (Profile 1) on http://127.0.0.1:9222...")
    print("==================================================================")

    try:
        with sync_playwright() as p:
            try:
                browser = p.chromium.connect_over_cdp("http://127.0.0.1:9222")
            except Exception as e:
                print("\n❌ Could not connect to Chrome on port 9222.")
                print("👉 Please run 'launch_chrome_agent.bat' first so Chrome starts with debugging enabled!\n")
                return

            context = browser.contexts[0]
            page = context.new_page()
            
            print("🌐 Navigating to X (Twitter)...")
            page.goto("https://x.com/home", timeout=30000)
            page.wait_for_timeout(3000)

            # Check if logged in
            if "login" in page.url:
                print("⚠️ Not logged into Twitter in this profile. Please log in first.")
                return

            print("✅ Successfully attached to active Twitter/X profile!")
            print("\nAvailable Actions:")
            print("1. Draft Thread 1 (The 45-Second Slippage Hook)")
            print("2. Draft Thread 2 (The Nairobi to MQL5 Indie Builder Story)")
            print("3. Search & Inspect Forex/Gold Tweets for Engagement")
            print("4. Exit")

            choice = input("Select an option (1-4): ").strip()
            
            if choice == "1":
                tweet_text = (
                    "How Telegram signal providers lose 15–20 pips of slippage for their VIPs:\n\n"
                    "1. Look at MT5 setup 📉\n"
                    "2. Open Snipping Tool / Phone camera 📱\n"
                    "3. Crop & save image (25s)\n"
                    "4. Open Telegram, upload, type Entry, SL, TP (20s)\n\n"
                    "Total delay: 45s. On Gold, that trade is gone.\n\n"
                    "Here's how we fixed it with 1-click MT5 code: 👇🧵\n"
                    "https://www.youtube.com/watch?v=vw__LEKD1qs\n\n"
                    "#Forex #XAUUSD #MetaTrader5 #TradingSignals"
                )
                print("\n📝 Opening Tweet Composer...")
                page.goto("https://x.com/compose/post", timeout=30000)
                page.wait_for_timeout(2000)
                
                # Locate editor
                editor = page.locator('div[data-testid="tweetTextarea_0"]')
                if editor.is_visible():
                    editor.fill(tweet_text)
                    print("✅ Tweet text filled into composer!")
                    print("👉 Please review the browser window and click 'Post' (or automate posting).")
                else:
                    print("⚠️ Could not find tweet composer element. Please check browser.")

            elif choice == "2":
                tweet_text = (
                    "I got tired of clunky Python bots and risky Windows DLLs just to send an MT5 chart to Telegram.\n\n"
                    "So over the last few months, I built TeleSnap Pro from scratch in Nairobi.\n\n"
                    "Today, it's live on the global MetaQuotes MQL5 Marketplace.\n\n"
                    "Watch the 30s demonstration: 👇\n"
                    "https://www.youtube.com/watch?v=vw__LEKD1qs\n\n"
                    "#Forex #MQL5 #MT5 #AlgorithmicTrading #ForexKenya"
                )
                print("\n📝 Opening Tweet Composer...")
                page.goto("https://x.com/compose/post", timeout=30000)
                page.wait_for_timeout(2000)
                editor = page.locator('div[data-testid="tweetTextarea_0"]')
                if editor.is_visible():
                    editor.fill(tweet_text)
                    print("✅ Tweet text filled into composer!")
                else:
                    print("⚠️ Could not find tweet composer element.")

            elif choice == "3":
                query = "XAUUSD signal OR MT5 screenshot"
                print(f"🔍 Searching X for: {query}...")
                page.goto(f"https://x.com/search?q={query}&f=live", timeout=30000)
                page.wait_for_timeout(3000)
                print("✅ Search results loaded in browser! You can now engage with live traders.")

            input("\nPress [ENTER] to finish session...")
    except Exception as e:
        print(f"⚠️ Error: {e}")

if __name__ == "__main__":
    connect_and_post()
