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
   int               m_xPos;
   int               m_yPos;
   int               m_width;
   int               m_height;
   int               m_hotkey;
   long              m_chartId;

public:
   CTeleSnapUI() : m_btnName("TeleSnap_HUD_Button"),
                   m_xPos(25),
                   m_yPos(50),
                   m_width(170),
                   m_height(36),
                   m_hotkey(123), // 123 is Virtual Key code for F12
                   m_chartId(0)
   {}

   ~CTeleSnapUI()
   {
      Destroy();
   }

   //--- Create floating HUD button
   bool Create(const long chartId, const int x = 25, const int y = 50, const int hotkeyKey = 123)
   {
      m_chartId = chartId;
      m_xPos = x;
      m_yPos = y;
      m_hotkey = hotkeyKey;

      ObjectDelete(m_chartId, m_btnName);

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
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_BGCOLOR, clrSteelBlue);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_BORDER_COLOR, clrDodgerBlue);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_STATE, false);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_HIDDEN, true);

      ChartRedraw(m_chartId);
      return true;
   }

   void Destroy()
   {
      ObjectDelete(m_chartId, m_btnName);
      ChartRedraw(m_chartId);
   }

   //--- Set visual state
   void SetStateProcessing()
   {
      ObjectSetString(m_chartId, m_btnName, OBJPROP_TEXT, "⏳ DISPATCHING...");
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_BGCOLOR, clrDarkOrange);
      ChartRedraw(m_chartId);
   }

   void SetStateSuccess(const uint elapsedMs)
   {
      ObjectSetString(m_chartId, m_btnName, OBJPROP_TEXT, "✅ SENT! (" + IntegerToString(elapsedMs) + "ms)");
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_BGCOLOR, clrSeaGreen);
      ChartRedraw(m_chartId);
   }

   void SetStateFailed()
   {
      ObjectSetString(m_chartId, m_btnName, OBJPROP_TEXT, "❌ SEND FAILED");
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_BGCOLOR, clrCrimson);
      ChartRedraw(m_chartId);
   }

   void ResetState()
   {
      ObjectSetString(m_chartId, m_btnName, OBJPROP_TEXT, "📸 SNAP & SEND [F12]");
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_BGCOLOR, clrSteelBlue);
      ObjectSetInteger(m_chartId, m_btnName, OBJPROP_STATE, false);
      ChartRedraw(m_chartId);
   }

   //--- Event Inspector
   bool IsTriggered(const int id, const long &lparam, const double &dparam, const string &sparam)
   {
      // 1. Mouse Click on Button
      if(id == CHARTEVENT_OBJECT_CLICK && sparam == m_btnName)
      {
         // Reset button press state immediately
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
