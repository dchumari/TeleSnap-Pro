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

public:
   CTelegramClient() : m_timeout(10000) {}
   ~CTelegramClient() {}

   void Init(const string token, const string chatId, const int timeoutMs = 10000)
   {
      m_botToken = token;
      m_chatId = chatId;
      m_timeout = timeoutMs;
   }

   //--- Send plain text message via HTML parse mode
   bool SendMessage(const string message)
   {
      if(StringLen(m_botToken) == 0 || StringLen(m_chatId) == 0)
      {
         Print("[TeleSnap Pro] Error: Bot Token or Chat ID not configured.");
         return false;
      }

      string url = "https://api.telegram.org/bot" + m_botToken + "/sendMessage";
      string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
      string postData = "chat_id=" + m_chatId + 
                        "&text=" + message + 
                        "&parse_mode=HTML" + 
                        "&disable_web_page_preview=true";

      uchar postBytes[];
      StringToCharArray(postData, postBytes, 0, WHOLE_ARRAY, CP_UTF8);
      int postSize = ArraySize(postBytes);
      if(postSize > 0 && postBytes[postSize - 1] == 0)
         ArrayResize(postBytes, postSize - 1);

      char resultData[];
      string resultHeaders;
      ResetLastError();
      int res = WebRequest("POST", url, headers, m_timeout, postBytes, resultData, resultHeaders);

      if(res == 200)
      {
         return true;
      }
      else
      {
         PrintFormat("[TeleSnap Pro] SendMessage WebRequest failed. Code: %d, Error: %d. Check Tools->Options->Expert Advisors URL whitelist.", res, GetLastError());
         return false;
      }
   }

   //--- Send Photo using RFC 7578 Multipart/form-data
   bool SendPhoto(const uchar &photoBytes[], const string caption)
   {
      if(StringLen(m_botToken) == 0 || StringLen(m_chatId) == 0)
      {
         Print("[TeleSnap Pro] Error: Bot Token or Chat ID not configured.");
         return false;
      }

      if(ArraySize(photoBytes) == 0)
      {
         Print("[TeleSnap Pro] Error: Empty photo buffer.");
         return false;
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
         Print("[TeleSnap Pro] Snapshot successfully dispatched to Telegram!");
         return true;
      }
      else
      {
         string errorMsg = CharArrayToString(resultData, 0, WHOLE_ARRAY, CP_UTF8);
         PrintFormat("[TeleSnap Pro] SendPhoto failed. HTTP Status: %d, System Error: %d\nResponse: %s", res, GetLastError(), errorMsg);
         return false;
      }
   }
};
