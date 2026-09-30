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
//| Floating Chart HUD & Keyboard Event Controller                   |
//+------------------------------------------------------------------+
class CTeleSnapUI
{
private:
   string            m_btnName;
   string            m_statusName;
   int               m_xPos;
   int               m_yPos;
   int               m_width;
   int               m_height;
   int               m_hotkey;
   long              m_chartId;

public:
   CTeleSnapUI() : m_btnName("TeleSnap_HUD_Button"),
                   m_statusName("TeleSnap_HUD_Status"),
                   m_xPos(25),
                   m_yPos(50),
                   m_width(185),
                   m_height(34),
                   m_hotkey(123), // 123 is Virtual Key code for F12
                   m_chartId(0)
   {}

   ~CTeleSnapUI()
   {
      Destroy();
   }

   //--- Create floating HUD button and status indicator
   bool Create(const long chartId, const int x = 25, const int y = 50, const int hotkeyKey = 123)
   {
      m_chartId = chartId;
      m_xPos = x;
      m_yPos = y;
      m_hotkey = hotkeyKey;

      Destroy();

      // 1. Create Main Action Button
      if(!ObjectCreate(m_chartId, m_btnName, OBJ_BUTTON, 0, 0, 0))
      {
         PrintFormat("[TeleSnap Pro] Failed to create HUD button. Error: %d", GetLastError());
         return false;
      }

      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_XDISTANCE, m_xPos);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_YDISTANCE, m_yPos);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_XSIZE, m_width);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_YSIZE, m_height);

      ObjectSetString(m_chartId, m_btnName, OBJPROP_TEXT, "📸 SNAP & SEND [F12]");
      ObjectSetString(m_chartId, m_btnName, OBJPROP_FONT, "Segoe UI Semibold");
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_BGCOLOR, clrSteelBlue);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_BORDER_COLOR, clrDodgerBlue);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_STATE, false);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_HIDDEN, true);

      // 2. Create Status Subtitle Label
      ObjectCreate(m_chartId, m_statusName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartId, m_statusName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, m_statusName, OBJPROP_XDISTANCE, m_xPos + 2);
      ObjectSetInteger(m_chartId, m_statusName, OBJPROP_YDISTANCE, m_yPos + m_height + 4);
      ObjectSetString(m_chartId, m_statusName, OBJPROP_FONT, "Segoe UI");
      ObjectSetInteger(m_chartId, m_statusName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(m_chartId, m_statusName, OBJPROP_COLOR, clrSilver);
      ObjectSetString(m_chartId, m_statusName, OBJPROP_TEXT, "TeleSnap Active");
      ObjectSetInteger(m_chartId, m_statusName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, m_statusName, OBJPROP_HIDDEN, true);

      ChartRedraw(m_chartId);
      return true;
   }

   void Destroy()
   {
      ObjectDelete(m_chartId, m_btnName);
      ObjectDelete(m_chartId, m_statusName);
      ChartRedraw(m_chartId);
   }

   //--- Set status message under button
   void SetStatusText(const string text, const color textColor = clrSilver)
   {
      ObjectSetString(m_chartId, m_statusName, OBJPROP_TEXT, text);
      ObjectSetInteger(m_chartId, m_statusName, OBJPROP_COLOR, textColor);
      ChartRedraw(m_chartId);
   }

   //--- Visual state animations
   void SetStateProcessing()
   {
      ObjectSetString(m_chartId, m_btnName, OBJPROP_TEXT, "⏳ DISPATCHING...");
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_BGCOLOR, clrDarkOrange);
      SetStatusText("Uploading to Telegram...", clrGold);
      ChartRedraw(m_chartId);
   }

   void SetStateSuccess(const uint elapsedMs, const string channel)
   {
      ObjectSetString(m_chartId, m_btnName, OBJPROP_TEXT, "✅ SENT! (" + IntegerToString(elapsedMs) + "ms)");
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_BGCOLOR, clrSeaGreen);
      SetStatusText("● Sent to " + channel, clrLimeGreen);
      ChartRedraw(m_chartId);
   }

   void SetStateFailed(const string errorShort = "Failed (Check Experts Tab)")
   {
      ObjectSetString(m_chartId, m_btnName, OBJPROP_TEXT, "❌ SEND FAILED");
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_BGCOLOR, clrCrimson);
      SetStatusText("⚠️ " + errorShort, clrTomato);
      ChartRedraw(m_chartId);
   }

   void ResetState(const string channel = "")
   {
      ObjectSetString(m_chartId, m_btnName, OBJPROP_TEXT, "📸 SNAP & SEND [F12]");
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_BGCOLOR, clrSteelBlue);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_STATE, false);
      
      if(StringLen(channel) > 0)
         SetStatusText("● Connected: " + channel, clrMediumSeaGreen);
      else
         SetStatusText("● Ready to Snap", clrSilver);

      ChartRedraw(m_chartId);
   }

   //--- Event Inspector
   bool IsTriggered(const int id, const long &lparam, const double &dparam, const string &sparam)
   {
      // 1. Mouse Click on Button
      if(id == CHARTEVENT_OBJECT_CLICK && sparam == m_btnName)
      {
         ObjectSetInteger(m_chartId, m_btnName, OBJPROP_STATE, false);
         return true;
      }

      // 2. Keyboard Hotkey (F12 or configured key)
      if(id == CHARTEVENT_KEYDOWN && lparam == m_hotkey)
      {
         return true;
      }

      return false;
   }
};
