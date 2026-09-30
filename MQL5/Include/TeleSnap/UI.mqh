//+------------------------------------------------------------------+
//|                                                           UI.mqh |
//|                                  Copyright 2026, TeleSnap Pro Team |
//|                                             https://telesnap.pro |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, TeleSnap Pro Team"
#property link      "https://telesnap.pro"
#property strict

#include "Config.mqh"

//+------------------------------------------------------------------+
//| Floating Chart HUD with On-Chart Note Box & Quick Snap Buttons   |
//+------------------------------------------------------------------+
class CTeleSnapUI
{
private:
   string            m_btnSnap;
   string            m_btnNoteSnap;
   string            m_lblPrompt;
   string            m_editNote;
   string            m_statusLabel;
   int               m_xPos;
   int               m_yPos;
   int               m_hotkey;
   long              m_chartId;

public:
   CTeleSnapUI() : m_btnSnap("TeleSnap_Btn_Snap"),
                   m_btnNoteSnap("TeleSnap_Btn_NoteSnap"),
                   m_lblPrompt("TeleSnap_Lbl_Prompt"),
                   m_editNote("TeleSnap_Edit_Note"),
                   m_statusLabel("TeleSnap_HUD_Status"),
                   m_xPos(25),
                   m_yPos(50),
                   m_hotkey(123),
                   m_chartId(0)
   {}

   ~CTeleSnapUI()
   {
      Destroy();
   }

   //--- Create complete floating control panel on chart
   bool Create(const long chartId, const int x = 25, const int y = 50, const int hotkeyKey = 123)
   {
      m_chartId = chartId;
      m_xPos = x;
      m_yPos = y;
      m_hotkey = hotkeyKey;

      Destroy();

      int btnHeight = 30;
      int editHeight = 24;
      int totalWidth = 270;

      // 1. Button 1: Quick Snap [F12]
      int btn1Width = 130;
      ObjectCreate(m_chartId, m_btnSnap, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_XDISTANCE, m_xPos);
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_YDISTANCE, m_yPos);
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_XSIZE, btn1Width);
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_YSIZE, btnHeight);
      ObjectSetString(m_chartId, m_btnSnap, OBJPROP_TEXT, "📸 SNAP [F12]");
      ObjectSetString(m_chartId, m_btnSnap, OBJPROP_FONT, "Segoe UI Semibold");
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_BGCOLOR, clrSteelBlue);
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_BORDER_COLOR, clrDodgerBlue);
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_STATE, false);
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_HIDDEN, true);

      // 2. Button 2: Send With Note
      int btn2Width = 135;
      ObjectCreate(m_chartId, m_btnNoteSnap, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_XDISTANCE, m_xPos + btn1Width + 5);
      ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_YDISTANCE, m_yPos);
      ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_XSIZE, btn2Width);
      ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_YSIZE, btnHeight);
      ObjectSetString(m_chartId, m_btnNoteSnap, OBJPROP_TEXT, "💬 SEND + NOTE");
      ObjectSetString(m_chartId, m_btnNoteSnap, OBJPROP_FONT, "Segoe UI Semibold");
      ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_BGCOLOR, C'35,50,75');
      ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_BORDER_COLOR, clrSteelBlue);
      ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_STATE, false);
      ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_HIDDEN, true);

      // 3. Prompt Label above Note Box
      ObjectCreate(m_chartId, m_lblPrompt, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartId, m_lblPrompt, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, m_lblPrompt, OBJPROP_XDISTANCE, m_xPos + 2);
      ObjectSetInteger(m_chartId, m_lblPrompt, OBJPROP_YDISTANCE, m_yPos + btnHeight + 4);
      ObjectSetString(m_chartId, m_lblPrompt, OBJPROP_FONT, "Segoe UI");
      ObjectSetInteger(m_chartId, m_lblPrompt, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(m_chartId, m_lblPrompt, OBJPROP_COLOR, clrSilver);
      ObjectSetString(m_chartId, m_lblPrompt, OBJPROP_TEXT, "📝 Custom Trade Note (click box below to type):");
      ObjectSetInteger(m_chartId, m_lblPrompt, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, m_lblPrompt, OBJPROP_HIDDEN, true);

      // 4. On-Chart Editable Note Box (Single Click Active Text Box)
      ObjectCreate(m_chartId, m_editNote, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_XDISTANCE, m_xPos);
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_YDISTANCE, m_yPos + btnHeight + 18);
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_XSIZE, totalWidth);
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_YSIZE, editHeight);
      ObjectSetString(m_chartId, m_editNote, OBJPROP_TEXT, "");
      ObjectSetString(m_chartId, m_editNote, OBJPROP_FONT, "Segoe UI");
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_ALIGN, ALIGN_LEFT);
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_BGCOLOR, C'20,26,38');
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_BORDER_COLOR, C'50,70,100');
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_READONLY, false);
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_SELECTABLE, false); // FALSE allows instant typing without selecting anchor boxes
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_SELECTED, false);
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_HIDDEN, true);

      // 5. Status Subtitle Label
      ObjectCreate(m_chartId, m_statusLabel, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartId, m_statusLabel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, m_statusLabel, OBJPROP_XDISTANCE, m_xPos + 2);
      ObjectSetInteger(m_chartId, m_statusLabel, OBJPROP_YDISTANCE, m_yPos + btnHeight + 18 + editHeight + 6);
      ObjectSetString(m_chartId, m_statusLabel, OBJPROP_FONT, "Segoe UI");
      ObjectSetInteger(m_chartId, m_statusLabel, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(m_chartId, m_statusLabel, OBJPROP_COLOR, clrSilver);
      ObjectSetString(m_chartId, m_statusLabel, OBJPROP_TEXT, "TeleSnap Active");
      ObjectSetInteger(m_chartId, m_statusLabel, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, m_statusLabel, OBJPROP_HIDDEN, true);

      ChartRedraw(m_chartId);
      return true;
   }

   void Destroy()
   {
      ObjectDelete(m_chartId, m_btnSnap);
      ObjectDelete(m_chartId, m_btnNoteSnap);
      ObjectDelete(m_chartId, m_lblPrompt);
      ObjectDelete(m_chartId, m_editNote);
      ObjectDelete(m_chartId, m_statusLabel);
      ChartRedraw(m_chartId);
   }

   //--- Read text entered by user in the on-chart edit box
   string GetUserNote()
   {
      string note = ObjectGetString(m_chartId, m_editNote, OBJPROP_TEXT);
      StringTrimLeft(note);
      StringTrimRight(note);
      if(StringFind(note, "⚠️") >= 0)
         return "";
      return note;
   }

   //--- Highlight text section in red/gold when SEND + NOTE is clicked without a note
   void HighlightNoteRequired()
   {
      ObjectSetString(m_chartId, m_editNote, OBJPROP_TEXT, "⚠️ Please type your note here first!");
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_COLOR, clrGold);
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_BGCOLOR, C'60,20,25'); // Alert dark red
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_BORDER_COLOR, clrOrangeRed);
      SetStatusText("⚠️ Note required! Type in box above, or use [SNAP]", clrTomato);
      ChartRedraw(m_chartId);
   }

   //--- Reset note box after successful send or when user clicks into it
   void ResetNoteBox(const bool clearText = true)
   {
      if(clearText)
         ObjectSetString(m_chartId, m_editNote, OBJPROP_TEXT, "");

      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_BGCOLOR, C'20,26,38');
      ObjectSetInteger(m_chartId, m_editNote, OBJPROP_BORDER_COLOR, C'50,70,100');
      ChartRedraw(m_chartId);
   }

   void SetStatusText(const string text, const color textColor = clrSilver)
   {
      ObjectSetString(m_chartId, m_statusLabel, OBJPROP_TEXT, text);
      ObjectSetInteger(m_chartId, m_statusLabel, OBJPROP_COLOR, textColor);
      ChartRedraw(m_chartId);
   }

   void SetStateProcessing()
   {
      ObjectSetString(m_chartId, m_btnSnap, OBJPROP_TEXT, "⏳ DISPATCHING");
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_BGCOLOR, clrDarkOrange);
      SetStatusText("Uploading snapshot to Telegram...", clrGold);
      ChartRedraw(m_chartId);
   }

   void SetStateSuccess(const uint elapsedMs, const string channel)
   {
      ObjectSetString(m_chartId, m_btnSnap, OBJPROP_TEXT, "✅ SENT! (" + IntegerToString(elapsedMs) + "ms)");
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_BGCOLOR, clrSeaGreen);
      SetStatusText("● Sent to " + channel, clrLimeGreen);
      ChartRedraw(m_chartId);
   }

   void SetStateFailed(const string errorShort = "Failed (Check Experts Tab)")
   {
      ObjectSetString(m_chartId, m_btnSnap, OBJPROP_TEXT, "❌ SEND FAILED");
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_BGCOLOR, clrCrimson);
      SetStatusText("⚠️ " + errorShort, clrTomato);
      ChartRedraw(m_chartId);
   }

   void ResetState(const string channel = "")
   {
      ObjectSetString(m_chartId, m_btnSnap, OBJPROP_TEXT, "📸 SNAP [F12]");
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_BGCOLOR, clrSteelBlue);
      ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_STATE, false);
      ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_STATE, false);

      if(StringLen(channel) > 0)
         SetStatusText("● Connected: " + channel, clrMediumSeaGreen);
      else
         SetStatusText("● Ready to Snap", clrSilver);

      ChartRedraw(m_chartId);
   }

   //--- Event Inspector
   int CheckTrigger(const int id, const long &lparam, const double &dparam, const string &sparam)
   {
      // 1. User clicked into the Edit box
      if(id == CHARTEVENT_OBJECT_CLICK && sparam == m_editNote)
      {
         string cur = ObjectGetString(m_chartId, m_editNote, OBJPROP_TEXT);
         if(StringFind(cur, "⚠️") >= 0)
         {
            ResetNoteBox(true);
         }
         else
         {
            ObjectSetInteger(m_chartId, m_editNote, OBJPROP_BORDER_COLOR, clrDodgerBlue);
            ChartRedraw(m_chartId);
         }
         return 0;
      }

      // 2. User finished editing text in Edit box
      if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == m_editNote)
      {
         string typed = GetUserNote();
         if(StringLen(typed) > 0)
         {
            ObjectSetInteger(m_chartId, m_editNote, OBJPROP_BORDER_COLOR, clrMediumSeaGreen);
            SetStatusText("● Note ready: \"" + typed + "\"", clrMediumSeaGreen);
         }
         else
         {
            ObjectSetInteger(m_chartId, m_editNote, OBJPROP_BORDER_COLOR, C'50,70,100');
         }
         ChartRedraw(m_chartId);
         return 0;
      }

      // 3. Quick Snap button [F12]
      if(id == CHARTEVENT_OBJECT_CLICK && sparam == m_btnSnap)
      {
         ObjectSetInteger(m_chartId, m_btnSnap, OBJPROP_STATE, false);
         return 1;
      }

      // 4. Send With Note button
      if(id == CHARTEVENT_OBJECT_CLICK && sparam == m_btnNoteSnap)
      {
         ObjectSetInteger(m_chartId, m_btnNoteSnap, OBJPROP_STATE, false);
         return 2;
      }

      // 5. Hotkey F12
      if(id == CHARTEVENT_KEYDOWN && lparam == m_hotkey)
      {
         return 1;
      }

      return 0;
   }
};
