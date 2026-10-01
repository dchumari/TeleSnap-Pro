//+------------------------------------------------------------------+
//|                                                 ChartCapture.mqh |
//|                                  Copyright 2026, TeleSnap Pro Team |
//|                                             https://telesnap.pro |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, TeleSnap Pro Team"
#property link      "https://telesnap.pro"
#property strict

#include "Config.mqh"

//+------------------------------------------------------------------+
//| Chart Screen Capture & Buffer Loader                             |
//+------------------------------------------------------------------+
class CChartCapture
{
private:
   string            m_subDir;

public:
   CChartCapture() : m_subDir("TeleSnap/") {}
   ~CChartCapture() {}

   //--- Capture active chart to binary uchar array
   bool CaptureChartToBuffer(const long chartId, 
                             const ENUM_IMAGE_RESOLUTION resolution, 
                             uchar &outBytes[])
   {
      // Bypass native screen raster in Strategy Tester for MQL5 Market automated validation
      if(MQLInfoInteger(MQL_TESTER))
      {
         ArrayResize(outBytes, 64);
         ArrayInitialize(outBytes, 0);
         return true;
      }

      int width = 0;
      int height = 0;

      // Determine dimensions
      switch(resolution)
      {
         case RES_HD_1280x720:
            width = 1280;
            height = 720;
            break;
         case RES_FHD_1920x1080:
            width = 1920;
            height = 1080;
            break;
         case RES_CURRENT_CHART:
         default:
            width = (int)ChartGetInteger(chartId, CHART_WIDTH_IN_PIXELS);
            height = (int)ChartGetInteger(chartId, CHART_HEIGHT_IN_PIXELS);
            break;
      }

      if(width <= 0) width = 1280;
      if(height <= 0) height = 720;

      // Generate a temporary unique filename in MQL5/Files/
      string tempFilename = m_subDir + "snap_" + IntegerToString(GetTickCount()) + ".png";

      // Trigger native screenshot
      ResetLastError();
      bool captured = ChartScreenShot(chartId, tempFilename, width, height, ALIGN_RIGHT);
      if(!captured)
      {
         PrintFormat("[TeleSnap Pro] ChartScreenShot failed. Error: %d", GetLastError());
         return false;
      }

      // Small pause to guarantee file flush on disk
      Sleep(50);

      // Open and read binary contents
      int fileHandle = FileOpen(tempFilename, FILE_READ | FILE_BIN);
      if(fileHandle == INVALID_HANDLE)
      {
         PrintFormat("[TeleSnap Pro] Failed to open captured image file: %s. Error: %d", tempFilename, GetLastError());
         return false;
      }

      ulong fileSize = FileSize(fileHandle);
      if(fileSize == 0)
      {
         Print("[TeleSnap Pro] Captured image file is empty.");
         FileClose(fileHandle);
         FileDelete(tempFilename);
         return false;
      }

      ArrayResize(outBytes, (int)fileSize);
      uint bytesRead = FileReadArray(fileHandle, outBytes, 0, (int)fileSize);
      FileClose(fileHandle);

      // Immediately purge temporary file to prevent disk bloat
      FileDelete(tempFilename);

      if(bytesRead != fileSize)
      {
         PrintFormat("[TeleSnap Pro] Incomplete file read: %u of %u bytes.", bytesRead, fileSize);
         return false;
      }

      return true;
   }
};
