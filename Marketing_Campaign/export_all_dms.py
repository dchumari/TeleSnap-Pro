import json
import os
import sys

if sys.platform.startswith('win'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import dm_outreach_assistant as d

leads_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "telegram_leads_150.json")
export_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ALL_155_PERSONALIZED_DMS.txt")

with open(leads_path, "r", encoding="utf-8") as f:
    leads = json.load(f)

with open(export_path, "w", encoding="utf-8") as f:
    for lead in leads:
        f.write("==================================================================\n")
        f.write(f"LEAD #{lead['id']} | Channel: {lead['channel_name']} | Admin: {lead['admin_contact']}\n")
        f.write(f"Link: {lead['telegram_link']} | Niche: {lead['category']} ({lead['geography']})\n")
        f.write(f"Audience: {lead['audience_tier']} | Hook: {lead['outreach_hook']}\n")
        f.write("------------------------------------------------------------------\n")
        f.write(d.generate_dm_script(lead) + "\n\n")

print(f"✅ Successfully compiled all {len(leads)} personalized DMs into {export_path}")
