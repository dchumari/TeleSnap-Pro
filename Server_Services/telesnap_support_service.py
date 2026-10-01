"""
TeleSnap Pro - Customer Support, Subscription & Inquiry Telegram Bot Service
Bot: @telesnap_pro_bot
"""

import os
import sys
import time
import json
import urllib.request
import urllib.parse
import threading
import py_compile

# Ensure UTF-8 output encoding and line buffering for real-time logging
if sys.platform.startswith('win'):
    try:
        sys.stdout.reconfigure(encoding='utf-8', line_buffering=True)
        sys.stderr.reconfigure(encoding='utf-8', line_buffering=True)
    except Exception:
        pass

def load_bot_token():
    """Load Telegram bot token from environment variable or local .env file."""
    # 1. Check OS environment variable
    token = os.environ.get("TELEGRAM_SUPPORT_BOT_TOKEN", "").strip()
    if token:
        return token
    
    # 2. Check local .env file in project root
    base_dir = os.path.dirname(os.path.abspath(__file__))
    candidates = [
        os.path.join(base_dir, ".env"),
        os.path.join(base_dir, "..", ".env")
    ]
    for env_path in candidates:
        if os.path.exists(env_path):
            try:
                with open(env_path, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if line.startswith("TELEGRAM_SUPPORT_BOT_TOKEN="):
                            val = line.split("=", 1)[1].strip()
                            return val.strip('"').strip("'")
            except Exception:
                pass
    return ""

BOT_TOKEN = load_bot_token()
if not BOT_TOKEN:
    print("[ERROR] TELEGRAM_SUPPORT_BOT_TOKEN not found in environment or .env file.")
    print("Please set TELEGRAM_SUPPORT_BOT_TOKEN in .env or run with environment variable set.")
    sys.exit(1)

API_URL = f"https://api.telegram.org/bot{BOT_TOKEN}"
INQUIRY_LOG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "customer_inquiries.log")

# Official MQL5 Market & GitHub Links
MQL5_FREE_URL = "https://www.mql5.com/en/market/product/198951?source=Site+Market+MT5+Utility+Search+Rating007%3Atelesnap"
MQL5_PRO_URL  = "https://www.mql5.com/en/market/product/198931?source=Site+Market+MT5+Utility+Search+Rating007%3Atelesnap"
MQL5_ALL_URL  = "https://www.mql5.com/en/market/mt5/utility?filter=telesnap"
GITHUB_RELEASES_URL = "https://github.com/dchumari/TeleSnap-Pro/releases"

def call_telegram_api(method, params=None):
    url = f"{API_URL}/{method}"
    headers = {"Content-Type": "application/json"}
    data = json.dumps(params).encode('utf-8') if params else None
    req = urllib.request.Request(url, data=data, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode('utf-8'))
    except Exception as e:
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] API Error on {method}: {e}")
        return None

def send_message(chat_id, text, reply_markup=None):
    payload = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": "HTML",
        "disable_web_page_preview": False
    }
    if reply_markup:
        payload["reply_markup"] = reply_markup
    return call_telegram_api("sendMessage", payload)

def get_main_menu_keyboard():
    return {
        "inline_keyboard": [
            [
                {"text": "⚡ What is TeleSnap?", "callback_data": "menu_about"},
                {"text": "💎 Pricing & License", "callback_data": "menu_pricing"}
            ],
            [
                {"text": "🛠️ 3-Min Setup Guide", "callback_data": "menu_setup"},
                {"text": "📥 Download Free Lite", "callback_data": "menu_download"}
            ],
            [
                {"text": "👑 Buy TeleSnap Pro (MT5)", "url": MQL5_PRO_URL},
                {"text": "🎁 Get Free Lite (MT5)", "url": MQL5_FREE_URL}
            ],
            [
                {"text": "🌐 Browse All on MQL5", "url": MQL5_ALL_URL},
                {"text": "💬 Talk to Support", "callback_data": "menu_support"}
            ]
        ]
    }

def format_welcome_message(first_name):
    return (
        f"👋 <b>Welcome to TeleSnap Official Customer Support, {first_name}!</b>\n\n"
        "⚡ <b>TeleSnap Pro</b> is the institutional MetaTrader 5 trading communication hub.\n"
        "It connects your MT5 terminal directly to your Telegram channels, VIP supergroups, and forum topics with <b>zero human latency</b>.\n\n"
        "🚀 <b>Core Superpowers:</b>\n"
        "• <b>Centralized Command Center:</b> Monitor all charts from 1 window\n"
        "• <b>Instant Chart Snapping:</b> Real-time HD screenshots on trade entries, TPs, SLs & Breakeven\n"
        "• <b>Interactive On-Chart HUD:</b> 1-click snapshot + custom trader notes\n"
        "• <b>Daily Performance Recap:</b> Automated End-of-Day win rate & PnL audits\n"
        "• <b>Two-Way Remote Bot:</b> Control your MT5 terminal from Telegram!\n\n"
        "👇 <i>Select an option below for instant assistance:</i>"
    )

def format_pricing_message():
    return (
        "💎 <b>TeleSnap Pro — Licensing & Pricing Options</b>\n"
        "━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        "Choose the plan that fits your trading journey:\n\n"
        "🟢 <b>1-Month Starter License:</b>\n"
        "• <b>$35.00 USD / month</b>\n"
        "• Full access to Command Center & all updates\n\n"
        "🔵 <b>3-Month Trader License:</b>\n"
        "• <b>$79.00 USD / quarter</b>\n"
        "• Recommended for active community signal providers\n\n"
        "🔥 <b>Unlimited Lifetime License:</b>\n"
        "• <b>$99.00 USD (Best Value)</b>\n"
        "• One-time payment, perpetual updates, 10 MT5 terminal activations!\n\n"
        "━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"👑 <b>Direct Purchase Link:</b>\n👉 <a href=\"{MQL5_PRO_URL}\">Buy TeleSnap Pro on MQL5 Market</a>\n\n"
        f"🎁 <b>Free Community Version:</b>\n👉 <a href=\"{MQL5_FREE_URL}\">Get Free Lite on MQL5 Market</a>\n\n"
        "🛡️ <i>All licenses are protected & delivered instantly via MetaQuotes MQL5 Market.</i>"
    )

def format_setup_message():
    return (
        "🛠️ <b>TeleSnap 3-Minute Fast Setup Guide</b>\n"
        "━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        "<b>Step 1: Whitelist Telegram API in MT5</b>\n"
        "1. In MT5, press <code>Ctrl + O</code> (Tools ➔ Options ➔ Expert Advisors)\n"
        "2. Check <b>\"Allow WebRequest for listed URL\"</b>\n"
        "3. Add: <code>https://api.telegram.org</code>\n\n"
        "<b>Step 2: Connect Your Telegram Bot</b>\n"
        "1. Message @BotFather on Telegram and type <code>/newbot</code>\n"
        "2. Copy the generated Bot API Token\n"
        "3. Add your bot as an <b>Administrator</b> with \"Post Messages\" in your channel or supergroup\n\n"
        "<b>Step 3: Attach TeleSnap</b>\n"
        "1. Drag TeleSnap onto any MT5 chart\n"
        "2. Paste your <b>InpBotToken</b> and <b>InpChatId</b>\n"
        "3. Credentials are saved locally—you never have to re-enter them again!\n\n"
        "💬 <i>Need help? Reply with your question right here and our team will assist you!</i>"
    )

def format_about_message():
    return (
        "⚡ <b>TeleSnap Pro vs TeleSnap Lite</b>\n"
        "━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        "• <b>TeleSnap Lite (Free):</b>\n"
        "  - Instant manual [F12] chart snaps\n"
        "  - Auto-snapping on trade events\n"
        "  - On-chart trader commentary notes\n"
        "  - Permitted for personal channels with TeleSnap watermark\n\n"
        "• <b>TeleSnap Pro (Flagship):</b>\n"
        "  - Centralized Command Center Hub (Manage 10+ charts from 1 window)\n"
        "  - 100% Whitelabel Custom Branding & Watermark\n"
        "  - Automated Profit Milestones (+50, +100, +150 pips)\n"
        "  - Automated End-of-Day Daily Performance Recap\n"
        "  - Inbound Remote Bot Commands (/snap, /recap, /status)\n"
        "  - Priority VIP Customer Support"
    )

def handle_incoming_message(msg):
    chat_id = msg.get("chat", {}).get("id")
    user = msg.get("from", {})
    first_name = user.get("first_name", "Trader")
    username = user.get("username", "Unknown")
    text = msg.get("text", "").strip()

    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Received from @{username} ({chat_id}): {text}")

    if text.startswith("/start") or text.lower() == "hi" or text.lower() == "hello":
        send_message(chat_id, format_welcome_message(first_name), get_main_menu_keyboard())
    elif text.startswith("/pricing") or "price" in text.lower() or "cost" in text.lower() or "buy" in text.lower():
        send_message(chat_id, format_pricing_message(), get_main_menu_keyboard())
    elif text.startswith("/setup") or "setup" in text.lower() or "install" in text.lower():
        send_message(chat_id, format_setup_message(), get_main_menu_keyboard())
    elif text.startswith("/help") or "help" in text.lower():
        send_message(chat_id, format_about_message(), get_main_menu_keyboard())
    else:
        # User is submitting an inquiry/question
        log_entry = f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] INQUIRY from @{username} (ID: {chat_id}): {text}\n"
        with open(INQUIRY_LOG_FILE, "a", encoding="utf-8") as f:
            f.write(log_entry)
        
        reply = (
            f"✅ <b>Thank you, {first_name}! Your inquiry has been received.</b>\n\n"
            f"<i>\"{text}\"</i>\n\n"
            "Our developer and support team has been notified and will reply directly to your chat shortly.\n"
            "Meanwhile, you can explore our setup guide and pricing options below:"
        )
        send_message(chat_id, reply, get_main_menu_keyboard())

def handle_callback_query(callback):
    callback_id = callback.get("id")
    data = callback.get("data")
    message = callback.get("message", {})
    chat_id = message.get("chat", {}).get("id")
    
    # Acknowledge callback
    call_telegram_api("answerCallbackQuery", {"callback_query_id": callback_id})

    if data == "menu_about":
        send_message(chat_id, format_about_message(), get_main_menu_keyboard())
    elif data == "menu_pricing":
        send_message(chat_id, format_pricing_message(), get_main_menu_keyboard())
    elif data == "menu_setup":
        send_message(chat_id, format_setup_message(), get_main_menu_keyboard())
    elif data == "menu_download":
        download_text = (
            "📥 <b>Download TeleSnap (Free Edition)</b>\n\n"
            "Choose your preferred download method:\n\n"
            "1️⃣ <b>MetaTrader 5 Market (1-Click Terminal Install):</b>\n"
            f"👉 <a href=\"{MQL5_FREE_URL}\">Get Free Lite on MQL5 Market</a>\n\n"
            "2️⃣ <b>GitHub Official Release (Standalone .ex5 + Suite):</b>\n"
            f"👉 <a href=\"{GITHUB_RELEASES_URL}\">Download from GitHub Releases</a>\n\n"
            "3️⃣ <b>Need Custom Branding & Command Center?</b>\n"
            f"👉 <a href=\"{MQL5_PRO_URL}\">Upgrade to TeleSnap Pro ($99)</a>\n\n"
            "Includes <code>TeleSnap_Lite.ex5</code>, setup guides, and complete manual."
        )
        send_message(chat_id, download_text, get_main_menu_keyboard())
    elif data == "menu_support":
        prompt_text = (
            "💬 <b>TeleSnap Direct Developer Support</b>\n\n"
            "Please type your question, issue, or feature request right here in this chat!\n"
            "Your message will be instantly recorded and reviewed by our engineering team."
        )
        send_message(chat_id, prompt_text)

def is_running_as_service():
    """Detect if running as a Windows Service (Session 0) under NSSM."""
    if sys.platform.startswith('win'):
        try:
            import ctypes
            session_id = ctypes.c_uint32()
            if ctypes.windll.kernel32.ProcessIdToSessionId(os.getpid(), ctypes.byref(session_id)):
                return session_id.value == 0
        except Exception:
            pass
    return not sys.stdin or not hasattr(sys.stdin, "isatty") or not sys.stdin.isatty()

def is_valid_python(file_path):
    """Ensure python file has valid syntax before triggering a reload."""
    if not file_path.endswith('.py'):
        return True
    try:
        py_compile.compile(file_path, doraise=True)
        return True
    except py_compile.PyCompileError as e:
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] ⚠️ Syntax error in {os.path.basename(file_path)}, reload postponed: {e}")
        return False
    except Exception:
        return False

def reload_service(changed_file):
    """Gracefully restart the service on file change."""
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    rel_path = os.path.relpath(changed_file, base_dir)
    print("\n==================================================")
    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] 🔄 File change detected: {rel_path}")
    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] ⚡ Auto-reloading TeleSnap Support Service...")
    print("==================================================")
    sys.stdout.flush()
    sys.stderr.flush()
    time.sleep(0.5)

    if is_running_as_service():
        # NSSM supervisor automatically restarts the service upon process termination
        os._exit(0)
    else:
        # Running in interactive development terminal
        try:
            os.execv(sys.executable, [sys.executable] + sys.argv)
        except Exception as e:
            print(f"Failed to execv: {e}, exiting.")
            os._exit(0)

class AutoReloader:
    """Monitors service scripts and .env files for changes and reloads automatically."""
    def __init__(self, watch_dirs=None, watch_files=None, poll_interval=1.0):
        self.watch_dirs = watch_dirs or []
        self.watch_files = watch_files or []
        self.poll_interval = poll_interval
        self._mtimes = {}
        self._running = True
        self._snapshot()

    def _get_tracked_files(self):
        files = set()
        for f in self.watch_files:
            if os.path.exists(f):
                files.add(os.path.abspath(f))
        for d in self.watch_dirs:
            if os.path.isdir(d):
                for root, _, filenames in os.walk(d):
                    if "__pycache__" in root:
                        continue
                    for fname in filenames:
                        if fname.endswith(".py") or fname == ".env":
                            files.add(os.path.abspath(os.path.join(root, fname)))
        return files

    def _snapshot(self):
        for f in self._get_tracked_files():
            try:
                self._mtimes[f] = os.path.getmtime(f)
            except OSError:
                pass

    def check_for_changes(self):
        current_files = self._get_tracked_files()
        for f in current_files:
            try:
                current_mtime = os.path.getmtime(f)
                if f not in self._mtimes:
                    # New file added
                    if is_valid_python(f):
                        return f
                elif current_mtime > self._mtimes[f]:
                    # File modified
                    if is_valid_python(f):
                        return f
            except OSError:
                pass
        return None

    def start(self, on_change_callback):
        def _loop():
            while self._running:
                time.sleep(self.poll_interval)
                changed = self.check_for_changes()
                if changed:
                    self._running = False
                    on_change_callback(changed)
                    break
        t = threading.Thread(target=_loop, daemon=True, name="TeleSnap-AutoReloader")
        t.start()
        return t

def run_service():
    print("==================================================")
    print("⚡ Starting TeleSnap Support Bot Service")
    print(f"🤖 Bot: @telesnap_pro_bot")
    mode_str = "Windows Service (NSSM Session 0)" if is_running_as_service() else "Interactive Terminal"
    print(f"⚙️ Mode: {mode_str}")
    print("==================================================")

    # Initialize auto-reloader for code & env changes
    server_services_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(server_services_dir, ".."))
    watch_files = [
        os.path.join(project_root, ".env"),
        os.path.join(server_services_dir, ".env"),
        os.path.abspath(__file__)
    ]
    reloader = AutoReloader(watch_dirs=[server_services_dir], watch_files=watch_files, poll_interval=1.0)
    reloader.start(reload_service)
    print("🔄 Auto-Reloader active: changes to Python files or .env will reload service automatically.")

    # Verify bot connectivity
    me = call_telegram_api("getMe")
    if not me or not me.get("ok"):
        print("❌ Error: Failed to connect to Telegram Bot API. Check token in .env.")
        sys.exit(1)

    bot_info = me.get("result", {})
    print(f"✅ Connected as: @{bot_info.get('username')} ({bot_info.get('first_name')})")

    # Set bot commands menu in Telegram
    commands = [
        {"command": "start", "description": "Open Main Menu & TeleSnap Overview"},
        {"command": "pricing", "description": "View TeleSnap Pro Pricing & Licenses"},
        {"command": "setup", "description": "3-Minute Fast MT5 Setup Guide"},
        {"command": "help", "description": "TeleSnap Features & FAQ"}
    ]
    call_telegram_api("setMyCommands", {"commands": commands})
    print("✅ Registered bot command menu with Telegram.")

    last_offset = 0
    print("🚀 Listening for customer inquiries & messages (Press Ctrl+C to stop)...")

    while True:
        try:
            updates = call_telegram_api("getUpdates", {"offset": last_offset, "timeout": 5})
            if updates and updates.get("ok"):
                for item in updates.get("result", []):
                    last_offset = item["update_id"] + 1
                    if "message" in item:
                        handle_incoming_message(item["message"])
                    elif "callback_query" in item:
                        handle_callback_query(item["callback_query"])
            time.sleep(0.5)
        except KeyboardInterrupt:
            print("\n🛑 Service stopped by user.")
            break
        except Exception as e:
            print(f"⚠️ Polling loop error: {e}")
            time.sleep(3)

if __name__ == "__main__":
    run_service()
