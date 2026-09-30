//+------------------------------------------------------------------+
//|                                                     Telegram.mqh |
//|                                  Copyright 2026, TeleSnap Pro Team |
//|                                             https://telesnap.pro |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, TeleSnap Pro Team"
#property link      "https://telesnap.pro"
#property strict

#include "Config.mqh"

//+------------------------------------------------------------------+
//| Native Telegram Bot API Client (100% DLL-Free, WebRequest)       |
//+------------------------------------------------------------------+
class CTelegramClient
{
private:
   string            m_botToken;
   string            m_chatId;
   string            m_botUsername;
   int               m_timeout;

   //--- Helper to append string to uchar array
   void AppendString(uchar &data[], const string text)
   {
      uchar temp[];
      int len = StringToCharArray(text, temp, 0, WHOLE_ARRAY, CP_UTF8);
      if(len > 1) // exclude null terminator
      {
         int currentSize = ArraySize(data);
         ArrayResize(data, currentSize + len - 1);
         ArrayCopy(data, temp, currentSize, 0, len - 1);
      }
   }

   //--- Helper to append raw binary bytes to uchar array
   void AppendBytes(uchar &data[], const uchar &source[])
   {
      int currentSize = ArraySize(data);
      int sourceSize = ArraySize(source);
      if(sourceSize > 0)
      {
         ArrayResize(data, currentSize + sourceSize);
         ArrayCopy(data, source, currentSize, 0, sourceSize);
      }
   }

   //--- Simple JSON value parser helper
   string ExtractJsonField(const string json, const string fieldName)
   {
      string searchPattern = "\"" + fieldName + "\":";
      int pos = StringFind(json, searchPattern);
      if(pos < 0) return "";

      pos += StringLen(searchPattern);
      while(pos < StringLen(json) && (StringGetCharacter(json, pos) == ' ' || StringGetCharacter(json, pos) == '\"'))
         pos++;

      int endPos = pos;
      while(endPos < StringLen(json))
      {
         ushort c = StringGetCharacter(json, endPos);
         if(c == '\"' || c == ',' || c == '}' || c == '\r' || c == '\n')
            break;
         endPos++;
      }

      return StringSubstr(json, pos, endPos - pos);
   }

public:
   CTelegramClient() : m_timeout(10000), m_botUsername("") {}
   ~CTelegramClient() {}

   //--- Escape special HTML characters to prevent Telegram parse errors
   static string EscapeHtml(string text)
   {
      StringReplace(text, "&", "&amp;");
      StringReplace(text, "<", "&lt;");
      StringReplace(text, ">", "&gt;");
      return text;
   }

   //--- Sanitize Chat ID (e.g. handle https://t.me/ or missing @)
   static string SanitizeChatId(string raw)
   {
      StringTrimLeft(raw);
      StringTrimRight(raw);

      if(StringFind(raw, "https://t.me/") == 0)
         raw = "@" + StringSubstr(raw, 13);
      else if(StringFind(raw, "http://t.me/") == 0)
         raw = "@" + StringSubstr(raw, 12);
      else if(StringFind(raw, "t.me/") == 0)
         raw = "@" + StringSubstr(raw, 5);

      if(StringLen(raw) > 0)
      {
         ushort firstChar = StringGetCharacter(raw, 0);
         if(firstChar != '@' && firstChar != '-' && (firstChar < '0' || firstChar > '9'))
         {
            raw = "@" + raw;
         }
      }

      return raw;
   }

   void Init(const string token, const string chatId, const int timeoutMs = 10000)
   {
      m_botToken = token;
      StringTrimLeft(m_botToken);
      StringTrimRight(m_botToken);

      m_chatId = SanitizeChatId(chatId);
      m_timeout = timeoutMs;
   }

   string GetBotUsername() const { return m_botUsername; }
   string GetChatId() const { return m_chatId; }

   //--- Diagnostic Test: Verify Bot Token & Chat ID
   bool TestConnection(string &outBotUsername, string &outChatTitle, string &outErrorDetails)
   {
      // Bypass WebRequest in Strategy Tester for MQL5 Marketplace compliance
      if(MQLInfoInteger(MQL_TESTER))
      {
         outBotUsername = "tester_bot";
         outChatTitle = "Strategy Tester Channel";
         outErrorDetails = "";
         return true;
      }

      if(StringLen(m_botToken) == 0)
      {
         outErrorDetails = "Bot Token is empty. Please enter your token from @BotFather.";
         return false;
      }

      if(StringLen(m_chatId) == 0)
      {
         outErrorDetails = "Chat ID is empty. Please enter your Channel username (@handle) or ID.";
         return false;
      }

      // 1. Test getMe
      string urlGetMe = "https://api.telegram.org/bot" + m_botToken + "/getMe";
      char resultData[];
      string resultHeaders;
      ResetLastError();
      int res = WebRequest("GET", urlGetMe, "", m_timeout, resultData, resultData, resultHeaders);

      if(res != 200)
      {
         int err = GetLastError();
         if(err == 4014)
         {
            outErrorDetails = "WebRequest blocked! Go to Tools->Options->Expert Advisors and add 'https://api.telegram.org'";
         }
         else
         {
            string respStr = CharArrayToString(resultData, 0, WHOLE_ARRAY, CP_UTF8);
            outErrorDetails = "Invalid Bot Token! Telegram returned: " + respStr;
         }
         return false;
      }

      string getMeJson = CharArrayToString(resultData, 0, WHOLE_ARRAY, CP_UTF8);
      m_botUsername = ExtractJsonField(getMeJson, "username");
      outBotUsername = m_botUsername;

      // 2. Test getChat
      string urlGetChat = "https://api.telegram.org/bot" + m_botToken + "/getChat?chat_id=" + m_chatId;
      ArrayResize(resultData, 0);
      ResetLastError();
      res = WebRequest("GET", urlGetChat, "", m_timeout, resultData, resultData, resultHeaders);

      string getChatJson = CharArrayToString(resultData, 0, WHOLE_ARRAY, CP_UTF8);

      if(res != 200)
      {
         if(StringFind(getChatJson, "chat not found") >= 0)
         {
            outErrorDetails = "Chat '" + m_chatId + "' not found!\n" +
                              "👉 FIX: You MUST add your bot (@" + m_botUsername + ") as an ADMINISTRATOR in your Telegram channel with 'Post Messages' permission!";
         }
         else if(StringFind(getChatJson, "bot was blocked") >= 0)
         {
            outErrorDetails = "Bot was blocked. Please open @" + m_botUsername + " in Telegram and click START.";
         }
         else
         {
            outErrorDetails = "Telegram getChat error (" + IntegerToString(res) + "): " + getChatJson;
         }
         return false;
      }

      outChatTitle = ExtractJsonField(getChatJson, "title");
      if(StringLen(outChatTitle) == 0)
         outChatTitle = ExtractJsonField(getChatJson, "username");

      outErrorDetails = "";
      return true;
   }

   //--- Send Photo using RFC 7578 Multipart/form-data
   bool SendPhoto(const uchar &photoBytes[], string caption, string &outErrorMessage)
   {
      // Bypass in Strategy Tester for MQL5 Marketplace approval
      if(MQLInfoInteger(MQL_TESTER))
      {
         outErrorMessage = "";
         return true;
      }

      if(StringLen(m_botToken) == 0 || StringLen(m_chatId) == 0)
      {
         outErrorMessage = "Bot Token or Chat ID not configured.";
         return false;
      }

      if(ArraySize(photoBytes) == 0)
      {
         outErrorMessage = "Empty photo buffer.";
         return false;
      }

      // Guard against Telegram's strict 1024-character caption limit
      if(StringLen(caption) > 1020)
      {
         caption = StringSubstr(caption, 0, 1015) + "...";
      }

      string boundary = "----TeleSnapBoundary" + IntegerToString(GetTickCount());
      string url = "https://api.telegram.org/bot" + m_botToken + "/sendPhoto";
      string headers = "Content-Type: multipart/form-data; boundary=" + boundary + "\r\n";

      uchar body[];
      ArrayResize(body, 0);

      // 1. chat_id field
      AppendString(body, "--" + boundary + "\r\n");
      AppendString(body, "Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n");
      AppendString(body, m_chatId + "\r\n");

      // 2. parse_mode field
      AppendString(body, "--" + boundary + "\r\n");
      AppendString(body, "Content-Disposition: form-data; name=\"parse_mode\"\r\n\r\n");
      AppendString(body, "HTML\r\n");

      // 3. caption field
      if(StringLen(caption) > 0)
      {
         AppendString(body, "--" + boundary + "\r\n");
         AppendString(body, "Content-Disposition: form-data; name=\"caption\"\r\n\r\n");
         AppendString(body, caption + "\r\n");
      }

      // 4. photo binary field
      AppendString(body, "--" + boundary + "\r\n");
      AppendString(body, "Content-Disposition: form-data; name=\"photo\"; filename=\"telesnap_chart.png\"\r\n");
      AppendString(body, "Content-Type: image/png\r\n\r\n");
      AppendBytes(body, photoBytes);
      AppendString(body, "\r\n");

      // Closing boundary
      AppendString(body, "--" + boundary + "--\r\n");

      char resultData[];
      string resultHeaders;
      ResetLastError();
      int res = WebRequest("POST", url, headers, m_timeout, body, resultData, resultHeaders);

      if(res == 200)
      {
         outErrorMessage = "";
         Print("[TeleSnap Pro] ✅ Snapshot successfully dispatched to Telegram!");
         return true;
      }
      else
      {
         string errorMsg = CharArrayToString(resultData, 0, WHOLE_ARRAY, CP_UTF8);
         if(StringFind(errorMsg, "chat not found") >= 0)
         {
            outErrorMessage = "Chat '" + m_chatId + "' not found!\n" +
                              "👉 FIX: Add @" + (StringLen(m_botUsername) > 0 ? m_botUsername : "your bot") + " as an ADMINISTRATOR in your Telegram channel!";
         }
         else if(res == -1 && GetLastError() == 4014)
         {
            outErrorMessage = "WebRequest blocked by MT5. Add 'https://api.telegram.org' in Tools->Options->Expert Advisors.";
         }
         else
         {
            outErrorMessage = "Telegram error (" + IntegerToString(res) + "): " + errorMsg;
         }

         PrintFormat("[TeleSnap Pro] ❌ SendPhoto failed. %s", outErrorMessage);
         return false;
      }
   }

   //--- Send Pure HTML Text Message (Used when no chart is open for a traded asset)
   bool SendMessage(string messageText, string &outErrorMessage)
   {
      // Bypass in Strategy Tester for MQL5 Marketplace approval
      if(MQLInfoInteger(MQL_TESTER))
      {
         outErrorMessage = "";
         return true;
      }

      if(StringLen(m_botToken) == 0 || StringLen(m_chatId) == 0)
      {
         outErrorMessage = "Bot Token or Chat ID not configured.";
         return false;
      }

      // Guard against Telegram's 4096-character limit
      if(StringLen(messageText) > 4000)
         messageText = StringSubstr(messageText, 0, 3990) + "...";

      string boundary = "----TeleSnapBoundary" + IntegerToString(GetTickCount());
      string url = "https://api.telegram.org/bot" + m_botToken + "/sendMessage";
      string headers = "Content-Type: multipart/form-data; boundary=" + boundary + "\r\n";

      uchar body[];
      ArrayResize(body, 0);

      // 1. chat_id field
      AppendString(body, "--" + boundary + "\r\n");
      AppendString(body, "Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n");
      AppendString(body, m_chatId + "\r\n");

      // 2. parse_mode field
      AppendString(body, "--" + boundary + "\r\n");
      AppendString(body, "Content-Disposition: form-data; name=\"parse_mode\"\r\n\r\n");
      AppendString(body, "HTML\r\n");

      // 3. text field
      AppendString(body, "--" + boundary + "\r\n");
      AppendString(body, "Content-Disposition: form-data; name=\"text\"\r\n\r\n");
      AppendString(body, messageText + "\r\n");

      // Closing boundary
      AppendString(body, "--" + boundary + "--\r\n");

      char resultData[];
      string resultHeaders;
      ResetLastError();
      int res = WebRequest("POST", url, headers, m_timeout, body, resultData, resultHeaders);

      if(res == 200)
      {
         outErrorMessage = "";
         Print("[TeleSnap Pro] ✅ Text signal successfully dispatched to Telegram!");
         return true;
      }
      else
      {
         string errorMsg = CharArrayToString(resultData, 0, WHOLE_ARRAY, CP_UTF8);
         outErrorMessage = "Telegram error (" + IntegerToString(res) + "): " + errorMsg;
         PrintFormat("[TeleSnap Pro] ❌ SendMessage failed. %s", outErrorMessage);
         return false;
      }
   }
};
