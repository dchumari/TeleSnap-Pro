//+------------------------------------------------------------------+
//|                                                      Storage.mqh |
//|                                  Copyright 2026, TeleSnap Pro Team |
//|                                             https://telesnap.pro |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, TeleSnap Pro Team"
#property link      "https://telesnap.pro"
#property strict

#include "Config.mqh"

//+------------------------------------------------------------------+
//| Global Settings Persistence Engine (FILE_COMMON Storage)         |
//| Saves Bot Token, Chat ID, and preferences across all charts/MT5  |
//+------------------------------------------------------------------+
class CTeleSnapStorage
{
private:
   string            m_filename;

public:
   CTeleSnapStorage() : m_filename("TeleSnap/global_settings.ini") {}
   ~CTeleSnapStorage() {}

   //--- Save settings to common terminal storage accessible by ALL charts
   bool SaveSettings(const string botToken,
                     const string chatId,
                     const string channelTag,
                     const string inviteLink,
                     const int triggerMode,
                     const int resolution,
                     const int captionStyle)
   {
      // Open in common directory shared across all charts and terminals
      int handle = FileOpen(m_filename, FILE_WRITE | FILE_TXT | FILE_COMMON);
      if(handle == INVALID_HANDLE)
      {
         PrintFormat("[TeleSnap Storage] Failed to write settings file. Error: %d", GetLastError());
         return false;
      }

      FileWriteString(handle, "[TeleSnap_Config]\r\n");
      FileWriteString(handle, "bot_token=" + botToken + "\r\n");
      FileWriteString(handle, "chat_id=" + chatId + "\r\n");
      FileWriteString(handle, "channel_tag=" + channelTag + "\r\n");
      FileWriteString(handle, "invite_link=" + inviteLink + "\r\n");
      FileWriteString(handle, "trigger_mode=" + IntegerToString(triggerMode) + "\r\n");
      FileWriteString(handle, "resolution=" + IntegerToString(resolution) + "\r\n");
      FileWriteString(handle, "caption_style=" + IntegerToString(captionStyle) + "\r\n");

      FileClose(handle);
      Print("[TeleSnap Storage] ✅ Settings successfully saved to global shared storage!");
      return true;
   }

   //--- Check if global settings exist
   bool HasSettings()
   {
      return FileIsExist(m_filename, FILE_COMMON);
   }

   //--- Load settings from common terminal storage
   bool LoadSettings(string &outBotToken,
                     string &outChatId,
                     string &outChannelTag,
                     string &outInviteLink,
                     int &outTriggerMode,
                     int &outResolution,
                     int &outCaptionStyle)
   {
      if(!HasSettings())
         return false;

      int handle = FileOpen(m_filename, FILE_READ | FILE_TXT | FILE_COMMON);
      if(handle == INVALID_HANDLE)
         return false;

      while(!FileIsEnding(handle))
      {
         string line = FileReadString(handle);
         StringTrimLeft(line);
         StringTrimRight(line);

         if(StringFind(line, "=") > 0)
         {
            int eqPos = StringFind(line, "=");
            string key = StringSubstr(line, 0, eqPos);
            string val = StringSubstr(line, eqPos + 1);
            StringTrimLeft(key);
            StringTrimRight(key);
            StringTrimLeft(val);
            StringTrimRight(val);

            if(key == "bot_token" && StringLen(val) > 0)
               outBotToken = val;
            else if(key == "chat_id" && StringLen(val) > 0)
               outChatId = val;
            else if(key == "channel_tag" && StringLen(val) > 0)
               outChannelTag = val;
            else if(key == "invite_link")
               outInviteLink = val;
            else if(key == "trigger_mode")
               outTriggerMode = (int)StringToInteger(val);
            else if(key == "resolution")
               outResolution = (int)StringToInteger(val);
            else if(key == "caption_style")
               outCaptionStyle = (int)StringToInteger(val);
         }
      }

      FileClose(handle);
      return (StringLen(outBotToken) > 0 && StringLen(outChatId) > 0);
   }
};
