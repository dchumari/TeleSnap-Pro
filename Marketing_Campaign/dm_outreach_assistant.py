"""
TeleSnap Pro - High-Velocity Telegram Outreach Assistant
Automates loading leads, personalizing scripts, opening chat windows, and tracking conversion pipeline.
"""

import json
import csv
import os
import sys
import subprocess
import time

if sys.platform.startswith('win'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

LEADS_JSON = os.path.join(os.path.dirname(os.path.abspath(__file__)), "telegram_leads_150.json")
LEADS_CSV  = os.path.join(os.path.dirname(os.path.abspath(__file__)), "telegram_leads_150.csv")

def copy_to_clipboard(text):
    """Copy text to Windows clipboard using PowerShell."""
    try:
        process = subprocess.Popen(['powershell', '-Command', '$input | Set-Clipboard'], stdin=subprocess.PIPE)
        process.communicate(input=text.encode('utf-8'))
        return True
    except Exception as e:
        print(f"⚠️ Clipboard error: {e}")
        return False

def open_telegram_chat(admin_handle):
    """Open Telegram desktop or browser directly to chat with admin."""
    clean_handle = admin_handle.replace("@", "").strip()
    url = f"https://t.me/{clean_handle}"
    if sys.platform.startswith('win'):
        os.system(f'start {url}')
    else:
        os.system(f'xdg-open {url}')

def generate_dm_script(lead):
    category = lead.get("category", "")
    admin = lead.get("admin_contact", "")
    channel = lead.get("channel_name", "")
    admin_name = admin.replace("@", "").split("_")[0] if admin else "Chief"

    if "Gold" in category:
        return (
            f"Hey {admin_name}, love the clean Gold setups on {channel}!\n\n"
            "Quick observation: On fast XAUUSD spikes (especially London & NY sessions), taking 45 seconds to crop charts and type Entry/SL/TP often costs your VIP members 10–20 pips of slippage before they can even get filled.\n\n"
            "I’m an MT5 developer and I built TeleSnap Pro specifically to solve this:\n"
            "• With 1 keypress (F12) or on-chart click, it takes an instant HD chart snapshot\n"
            "• Auto-stamps your channel watermark (stops signal thieves)\n"
            "• Auto-calculates floating pips, R:R, and SL/TP levels\n"
            "• Sends directly to your VIP channel in 300 milliseconds with zero DLLs\n\n"
            "Here’s a 30-second video demo showing how fast it broadcasts from MT5:\n"
            "👉 https://www.youtube.com/watch?v=vw__LEKD1qs\n\n"
            "I’m offering 5 verified Gold channel admins lifetime access for $39 today (listed at $99 on MQL5 Market) in exchange for honest feedback.\n\n"
            "Would this save you time on your daily updates?"
        )
    elif "Prop" in category or "SMC" in category:
        return (
            f"Hey {admin_name}, solid execution on those order block setups on {channel}!\n\n"
            "As someone managing funded traders and mentoring students through prop challenges, you know trade journaling and visual proof are everything.\n\n"
            "I built an institutional MT5 utility called TeleSnap:\n"
            "1. 1-Click F12 chart snapper with on-chart trader commentary notes\n"
            "2. Automated snapshots on trade entry, breakeven, and take-profit hits\n"
            "3. End-of-Day Daily Recap: Automatically audits and posts your daily win rate & total pips to your Telegram group every evening\n"
            "4. 100% compliant with prop firm rules (zero DLLs, pure native MQL5)\n\n"
            "Watch the 30s workflow demo here:\n"
            "👉 https://www.youtube.com/watch?v=vw__LEKD1qs\n\n"
            "I can set you up with the free community edition or give your team a VIP license to test on your live/challenge accounts. Would you be open to checking out a quick demo?"
        )
    elif "Kenya" in category or "East Africa" in category:
        return (
            f"Habari {admin_name}, nimeona kazi safi unayofanya kwa channel yako ya {channel}!\n\n"
            "Mimi ni software engineer na trader hapa Nairobi. Nimeunda utility mpya ya MetaTrader 5 inaitwa TeleSnap Pro inayosaidia signal providers kutuma charts na trade alerts kwa Telegram instantly kwa 300ms.\n\n"
            "Hakuna haja ya kupiga picha ya laptop na simu au kupoteza muda na snipping tool:\n"
            "• Unabonyeza F12 tu kwa chart ya MT5, inapiga snapshot na kuweka watermark ya channel yako\n"
            "• Inahesabu pips na kuweka Entry/SL/TP mara moja kwa Telegram\n"
            "• Ina Daily Performance Recap inayotumwa kila jioni kuonyesha matokeo ya siku kwa members wako\n\n"
            "Cheki hii 30-second demo video niliyotengeneza:\n"
            "👉 https://www.youtube.com/watch?v=vw__LEKD1qs\n\n"
            "Tumeiweka live kwenye official MetaQuotes MQL5 Market:\n"
            "👉 https://www.mql5.com/en/market/product/198951 (Free Lite)\n\n"
            "Kama local trader mwenzangu, ningependa kukupa license ya Pro ujaribu bila malipo au discount maalum kwa ajili ya feedback yako. Unasemaje nikikutumia package ujaribu kwa MT5 yako?"
        )
    elif "Indices" in category:
        return (
            f"Hey {admin_name}, great calls on the index open on {channel}!\n\n"
            "On US30 and NAS100, a 10-second delay in posting a signal is the difference between a 40-point gain and a breakeven exit for your followers.\n\n"
            "We developed an ultra-low latency MT5 broadcaster called TeleSnap Pro:\n"
            "• 300ms transmission directly from MT5 to your Telegram VIP channels\n"
            "• 1-Click F12 shortcut: snaps chart + calculates current points + formats message instantly\n"
            "• Central Command Center: monitor and broadcast from 10 different charts without switching windows\n"
            "• Built-in profit milestone alerts (+50, +100 points)\n\n"
            "See the live 30s demonstration:\n"
            "👉 https://www.youtube.com/watch?v=vw__LEKD1qs\n\n"
            "I'd love to get your thoughts on it. Happy to give you a demo version to run during today's NY session. Would that be helpful?"
        )
    else:
        return (
            f"Hello {admin_name},\n\n"
            f"I manage development for TeleSnap Pro, an institutional communication utility for MetaTrader 5 signal desks and trading communities.\n\n"
            f"We noticed many established Telegram channels like {channel} struggle with signal latency during high-impact news and unauthorized signal piracy.\n\n"
            "TeleSnap Pro resolves both:\n"
            "• Dispatches watermarked HD chart captures in sub-300ms via native MT5 WebRequest\n"
            "• Embeds your custom brand logo and channel link directly into the image\n"
            "• Automatically audits and posts an End-of-Day PnL recap to retain VIP members\n"
            "• 100% Zero-DLL security compliance\n\n"
            "Short 30s overview video:\n"
            "👉 https://www.youtube.com/watch?v=vw__LEKD1qs\n\n"
            "Available directly on MetaQuotes MQL5 Market:\n"
            "👉 https://www.mql5.com/en/market/product/198931\n\n"
            "We are providing pilot licenses to selected signal desks this week. Would you like a demo activation for your terminal?"
        )

def save_leads(leads):
    with open(LEADS_JSON, "w", encoding="utf-8") as f:
        json.dump(leads, f, indent=2, ensure_ascii=False)
    
    fieldnames = ["id", "channel_name", "telegram_link", "username", "admin_contact", "category", "geography", "audience_tier", "outreach_hook", "priority", "status"]
    with open(LEADS_CSV, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in leads:
            writer.writerow(row)

def run_interactive_assistant():
    if not os.path.exists(LEADS_JSON):
        print(f"❌ Error: {LEADS_JSON} not found. Run build_leads_database.py first.")
        return

    with open(LEADS_JSON, "r", encoding="utf-8") as f:
        leads = json.load(f)

    print("==================================================================")
    print("⚡ TELESNAP PRO — TELEGRAM OUTREACH ACCELERATOR")
    print(f"📊 Total Leads Loaded: {len(leads)}")
    print("==================================================================")
    print("Options:")
    print("1. Start Batch Outreach (Batch 1: Gold Leads #1-25)")
    print("2. Filter Leads by Niche (Gold, Prop, Kenya, Indices, Global)")
    print("3. Export All 155 Personalized Scripts to a Single File")
    print("4. View Conversion Progress & Stats")
    print("5. Exit")
    print("==================================================================")

    choice = input("Select an option (1-5) [Default: 1]: ").strip() or "1"

    if choice == "3":
        export_path = os.path.join(os.path.dirname(LEADS_JSON), "ALL_155_PERSONALIZED_DMS.txt")
        with open(export_path, "w", encoding="utf-8") as f:
            for lead in leads:
                f.write(f"==================================================================\n")
                f.write(f"LEAD #{lead['id']} | Channel: {lead['channel_name']} | Admin: {lead['admin_contact']}\n")
                f.write(f"Link: {lead['telegram_link']} | Niche: {lead['category']} ({lead['geography']})\n")
                f.write(f"------------------------------------------------------------------\n")
                f.write(generate_dm_script(lead) + "\n\n")
        print(f"\n✅ All 155 customized DMs exported to: {export_path}")
        return

    if choice == "4":
        statuses = {}
        for l in leads:
            st = l.get("status", "Pending Outreach")
            statuses[st] = statuses.get(st, 0) + 1
        print("\n📈 Pipeline Status:")
        for k, v in statuses.items():
            print(f"  • {k}: {v}")
        return

    # Batch or filtered outreach
    selected_leads = leads
    if choice == "1":
        selected_leads = leads[:25]
    elif choice == "2":
        cat = input("Enter keyword (Gold / Prop / Kenya / Indices / Global): ").strip().lower()
        selected_leads = [l for l in leads if cat in l.get("category", "").lower() or cat in l.get("geography", "").lower()]

    print(f"\n🚀 Ready to process {len(selected_leads)} leads.")
    print("For each lead, pressing ENTER will:")
    print("1. Auto-copy the customized DM to your clipboard.")
    print("2. Open the Telegram chat with the admin in your browser/app.")
    print("3. Mark the lead as 'Contacted' in the database.")
    print("Type 'q' anytime to return.\n")

    for lead in selected_leads:
        print(f"\n------------------------------------------------------------------")
        print(f"[{lead['id']}/{len(leads)}] {lead['channel_name']} | Admin: {lead['admin_contact']}")
        print(f"Category: {lead['category']} | Hook: {lead['outreach_hook']}")
        print(f"------------------------------------------------------------------")
        
        script = generate_dm_script(lead)
        print("📝 Script Preview:")
        print(script[:180] + "...\n")

        cmd = input("Press [ENTER] to Copy DM & Open Telegram (or 's' to skip, 'q' to quit): ").strip().lower()
        if cmd == 'q':
            break
        if cmd == 's':
            continue

        copy_to_clipboard(script)
        print("📋 Copied personalized DM to Clipboard!")
        open_telegram_chat(lead['admin_contact'])
        print(f"🌐 Opening chat: https://t.me/{lead['admin_contact'].replace('@', '')}")
        
        # Update status
        lead["status"] = "Contacted"
        save_leads(leads)
        print("✅ Status updated to 'Contacted'.")

    print("\n🎉 Batch session complete! All progress saved to database.")

if __name__ == "__main__":
    run_interactive_assistant()
