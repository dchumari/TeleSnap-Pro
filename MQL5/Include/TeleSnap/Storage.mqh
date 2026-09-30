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
//| Local PC Settings Persistence Engine (FILE_COMMON Storage)       |
//| Stores Bot Token & Chat ID locally on PC across charts & sessions|
//| NOTE: Stored strictly in local AppData - NEVER pushed to Git     |
//+------------------------------------------------------------------+
class CTeleSnapStorage
{
private:
   string            m_filename;

public:
   CTeleSnapStorage() : m_filename("TeleSnap/local_config.ini") {}
   ~CTeleSnapStorage() {}

   //--- Securely wipe local configuration from disk
   bool WipeCredentials()
   {
      if(FileIsExist(m_filename, FILE_COMMON))
      {
         FileDelete(m_filename, FILE_COMMON);
         Print("[TeleSnap Storage] 🔒 Local credentials file removed from disk.");
         return true;
      }
      return false;
   }

   //--- Save credentials to local PC common storage
   bool SaveCredentials(const string botToken,
                        const string chatId,
                        const string channelTag = "",
                        const string inviteLink = "",
                        const long threadId = 0)
   {
      if(StringLen(botToken) == 0 || StringLen(chatId) == 0)
         return false;

      int handle = FileOpen(m_filename, FILE_WRITE | FILE_TXT | FILE_COMMON);
      if(handle == INVALID_HANDLE)
      {
         PrintFormat("[TeleSnap Storage] Failed to open local_config.ini for writing. Error: %d", GetLastError());
         return false;
      }

      FileWriteString(handle, "[TeleSnap_Local_Config]\r\n");
      FileWriteString(handle, "bot_token=" + botToken + "\r\n");
      FileWriteString(handle, "chat_id=" + chatId + "\r\n");
      FileWriteString(handle, "thread_id=" + IntegerToString(threadId) + "\r\n");
      FileWriteString(handle, "channel_tag=" + channelTag + "\r\n");
      FileWriteString(handle, "invite_link=" + inviteLink + "\r\n");

      FileClose(handle);
      string topicMsg = (threadId > 0) ? (" (Topic ID: " + IntegerToString(threadId) + ")") : "";
      PrintFormat("[TeleSnap Storage] 💾 Saved Bot Token & Chat ID%s to local PC storage (FILE_COMMON).", topicMsg);
      return true;
   }

   //--- Check if saved configuration exists
   bool HasCredentials()
   {
      return FileIsExist(m_filename, FILE_COMMON);
   }

   //--- Load credentials from local PC common storage (with bound thread ID)
   bool LoadCredentials(string &outBotToken,
                        string &outChatId,
                        string &outChannelTag,
                        string &outInviteLink,
                        long &outThreadId)
   {
      outThreadId = 0;
      if(!HasCredentials())
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
            else if(key == "thread_id" && StringLen(val) > 0)
               outThreadId = StringToInteger(val);
            else if(key == "channel_tag" && StringLen(val) > 0)
               outChannelTag = val;
            else if(key == "invite_link" && StringLen(val) > 0)
               outInviteLink = val;
         }
      }

      FileClose(handle);
      return (StringLen(outBotToken) > 0 && StringLen(outChatId) > 0);
   }

   //--- Overload for backwards compatibility
   bool LoadCredentials(string &outBotToken,
                        string &outChatId,
                        string &outChannelTag,
                        string &outInviteLink)
   {
      long dummyThread = 0;
      return LoadCredentials(outBotToken, outChatId, outChannelTag, outInviteLink, dummyThread);
   }
};
