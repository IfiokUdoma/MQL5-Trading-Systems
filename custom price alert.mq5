//+------------------------------------------------------------------+
//| AlertMaster Pro - Smart Price Notifications                       |
//| Multi-Level Alerts with Strategy-Based Triggers                  |
//+------------------------------------------------------------------+
#property copyright "AlertMaster Pro"
#property version   "1.00"
#property strict

//--- Input Parameters
input group "=== Alert Delivery ==="
input bool EnablePopup = true;             // Show Popup Alerts
input bool EnableSound = true;             // Play Sound
input bool EnableTelegram = false;         // Send to Telegram
input bool EnableEmail = false;            // Send to Email

input group "=== Telegram Settings ==="
input string TelegramToken = "";           // Bot Token
input string TelegramChatID = "";          // Chat ID

input group "=== Price Alerts ==="
input double PriceAlert1 = 0;              // Alert Level 1
input double PriceAlert2 = 0;              // Alert Level 2
input double PriceAlert3 = 0;              // Alert Level 3
input double PriceAlert4 = 0;              // Alert Level 4
input double PriceAlert5 = 0;              // Alert Level 5

input group "=== Strategy Alerts ==="
input bool AlertOnRSI = true;              // Alert on RSI Oversold/Overbought
input double RSI_Oversold = 30;            // RSI Oversold Level
input double RSI_Overbought = 70;          // RSI Overbought Level

input bool AlertOnMACD = true;             // Alert on MACD Cross
input bool AlertOnMA = true;               // Alert on MA Cross

input group "=== Alert Settings ==="
input int AlertCooldown = 300;             // Cooldown Between Alerts (seconds)
input bool RecurringAlerts = true;         // Recurring or One-Time

//--- Alert Structure
struct Alert
{
   double level;
   bool triggered;
   datetime lastAlert;
};

Alert priceAlerts[5];
datetime lastRSIAlert = 0;
datetime lastMACDAlert = 0;
datetime lastMAAlert = 0;

//--- Indicator Handles
int rsiHandle = INVALID_HANDLE;
int macdHandle = INVALID_HANDLE;
int ma20Handle = INVALID_HANDLE;
int ma50Handle = INVALID_HANDLE;

//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print("AlertMaster Pro v1.00 Started");
   Print("Symbol: ", Symbol());
   Print("Popup: ", EnablePopup ? "ON" : "OFF");
   Print("Sound: ", EnableSound ? "ON" : "OFF");
   Print("Telegram: ", EnableTelegram ? "ON" : "OFF");
   Print("========================================");
   
   // Initialize indicators
   rsiHandle = iRSI(Symbol(), Period(), 14, PRICE_CLOSE);
   macdHandle = iMACD(Symbol(), Period(), 12, 26, 9, PRICE_CLOSE);
   ma20Handle = iMA(Symbol(), Period(), 20, 0, MODE_EMA, PRICE_CLOSE);
   ma50Handle = iMA(Symbol(), Period(), 50, 0, MODE_EMA, PRICE_CLOSE);
   
   if(rsiHandle == INVALID_HANDLE || macdHandle == INVALID_HANDLE || 
      ma20Handle == INVALID_HANDLE || ma50Handle == INVALID_HANDLE)
   {
      Print("Error creating indicators");
      return(INIT_FAILED);
   }
   
   // Initialize price alerts
   priceAlerts[0].level = PriceAlert1;
   priceAlerts[1].level = PriceAlert2;
   priceAlerts[2].level = PriceAlert3;
   priceAlerts[3].level = PriceAlert4;
   priceAlerts[4].level = PriceAlert5;
   
   for(int i = 0; i < 5; i++)
   {
      priceAlerts[i].triggered = false;
      priceAlerts[i].lastAlert = 0;
      
      if(priceAlerts[i].level > 0)
      {
         Print("Price Alert ", i+1, " set at: ", priceAlerts[i].level);
         DrawAlertLine(i);
      }
   }
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   
   // Check price alerts
   CheckPriceAlerts(bid);
   
   // Check strategy alerts
   if(AlertOnRSI)
      CheckRSIAlerts();
   
   if(AlertOnMACD)
      CheckMACDAlerts();
   
   if(AlertOnMA)
      CheckMAAlerts();
}

//+------------------------------------------------------------------+
void CheckPriceAlerts(double currentPrice)
{
   double prevClose[];
   ArraySetAsSeries(prevClose, true);
   
   if(CopyClose(Symbol(), Period(), 1, 1, prevClose) < 1)
      return;
   
   for(int i = 0; i < 5; i++)
   {
      if(priceAlerts[i].level <= 0)
         continue;
      
      bool crossed = (prevClose[0] < priceAlerts[i].level && currentPrice >= priceAlerts[i].level) ||
                     (prevClose[0] > priceAlerts[i].level && currentPrice <= priceAlerts[i].level);
      
      if(crossed)
      {
         bool canAlert = RecurringAlerts || !priceAlerts[i].triggered;
         bool cooldownPassed = (TimeCurrent() - priceAlerts[i].lastAlert) > AlertCooldown;
         
         if(canAlert && cooldownPassed)
         {
            string direction = (currentPrice >= priceAlerts[i].level) ? "ABOVE" : "BELOW";
            
            string message = StringFormat(
               "PRICE ALERT: %s\n\n"
               "Price: %.5f\n"
               "Alert Level: %.5f\n"
               "Direction: %s\n\n"
               "Time: %s",
               Symbol(),
               currentPrice,
               priceAlerts[i].level,
               direction,
               TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
            );
            
            SendAlert(message, "Price Alert");
            
            priceAlerts[i].triggered = true;
            priceAlerts[i].lastAlert = TimeCurrent();
            
            Print("Price Alert ", i+1, " triggered at ", currentPrice);
         }
      }
   }
}

//+------------------------------------------------------------------+
void CheckRSIAlerts()
{
   double rsi[];
   ArraySetAsSeries(rsi, true);
   
   if(CopyBuffer(rsiHandle, 0, 0, 1, rsi) < 1)
      return;
   
   bool oversold = rsi[0] < RSI_Oversold;
   bool overbought = rsi[0] > RSI_Overbought;
   
   if((oversold || overbought) && (TimeCurrent() - lastRSIAlert) > AlertCooldown)
   {
      string condition = oversold ? "OVERSOLD" : "OVERBOUGHT";
      string action = oversold ? "BUY SIGNAL" : "SELL SIGNAL";
      
      double macd = GetMACDValue();
      string macdStatus = GetMACDStatus(macd);
      
      double ma20 = GetMAValue(ma20Handle);
      double price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      string maStatus = (price > ma20) ? "Above MA20" : "Below MA20";
      
      int confluence = CalculateConfluence(oversold, macd, price, ma20);
      
      string message = StringFormat(
               "ALERT: %s\n\n"
               "Price: %.5f (Target Hit!)\n"
               "Action: %s\n\n"
               "RSI: %.1f (%s)\n"
               "MACD: %s\n"
               "MA Status: %s\n\n"
               "Confluence: %d/5 %s",
               Symbol(),
               price,
               action,
               rsi[0],
               condition,
               macdStatus,
               maStatus,
               confluence,
               GetStars(confluence)
            );
      
      SendAlert(message, "RSI Alert");
      lastRSIAlert = TimeCurrent();
      
      Print("RSI Alert: ", condition, " at ", rsi[0]);
   }
}

//+------------------------------------------------------------------+
void CheckMACDAlerts()
{
   double macd[], signal[];
   ArraySetAsSeries(macd, true);
   ArraySetAsSeries(signal, true);
   
   if(CopyBuffer(macdHandle, 0, 0, 2, macd) < 2 || CopyBuffer(macdHandle, 1, 0, 2, signal) < 2)
      return;
   
   bool bullishCross = (macd[1] <= signal[1] && macd[0] > signal[0]);
   bool bearishCross = (macd[1] >= signal[1] && macd[0] < signal[0]);
   
   if((bullishCross || bearishCross) && (TimeCurrent() - lastMACDAlert) > AlertCooldown)
   {
      string crossType = bullishCross ? "Bullish Cross" : "Bearish Cross";
      string action = bullishCross ? "BUY SIGNAL" : "SELL SIGNAL";
      
      double price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double rsi = GetRSIValue();
      
      string message = StringFormat(
         "ALERT: %s\n\n"
         "Price: %.5f\n"
         "Action: %s\n\n"
         "MACD: %s\n"
         "RSI: %.1f\n\n"
         "Time: %s",
         Symbol(),
         price,
         action,
         crossType,
         rsi,
         TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
      );
      
      SendAlert(message, "MACD Cross");
      lastMACDAlert = TimeCurrent();
      
      Print("MACD Alert: ", crossType);
   }
}

//+------------------------------------------------------------------+
void CheckMAAlerts()
{
   double ma20 = GetMAValue(ma20Handle);
   double ma50 = GetMAValue(ma50Handle);
   
   double close[];
   ArraySetAsSeries(close, true);
   
   if(CopyClose(Symbol(), Period(), 0, 2, close) < 2)
      return;
   
   if(ma20 <= 0 || ma50 <= 0)
      return;
   
   bool bullishCross = (close[1] < ma20 && close[0] > ma20);
   bool bearishCross = (close[1] > ma20 && close[0] < ma20);
   
   if((bullishCross || bearishCross) && (TimeCurrent() - lastMAAlert) > AlertCooldown)
   {
      string crossType = bullishCross ? "Bullish Cross" : "Bearish Cross";
      string action = bullishCross ? "BUY SIGNAL" : "SELL SIGNAL";
      
      string message = StringFormat(
         "ALERT: %s\n\n"
         "Price: %.5f\n"
         "Action: %s\n\n"
         "Price crossed MA20\n"
         "MA20: %.5f\n"
         "MA50: %.5f\n\n"
         "Time: %s",
         Symbol(),
         close[0],
         action,
         ma20,
         ma50,
         TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
      );
      
      SendAlert(message, "MA Cross");
      lastMAAlert = TimeCurrent();
      
      Print("MA Alert: ", crossType);
   }
}

//+------------------------------------------------------------------+
double GetRSIValue()
{
   double rsi[];
   ArraySetAsSeries(rsi, true);
   
   if(CopyBuffer(rsiHandle, 0, 0, 1, rsi) > 0)
      return rsi[0];
   
   return 0;
}

//+------------------------------------------------------------------+
double GetMACDValue()
{
   double macd[];
   ArraySetAsSeries(macd, true);
   
   if(CopyBuffer(macdHandle, 0, 0, 1, macd) > 0)
      return macd[0];
   
   return 0;
}

//+------------------------------------------------------------------+
double GetMAValue(int handle)
{
   double ma[];
   ArraySetAsSeries(ma, true);
   
   if(CopyBuffer(handle, 0, 0, 1, ma) > 0)
      return ma[0];
   
   return 0;
}

//+------------------------------------------------------------------+
string GetMACDStatus(double macd)
{
   if(macd > 0)
      return "Bullish";
   else if(macd < 0)
      return "Bearish";
   else
      return "Neutral";
}

//+------------------------------------------------------------------+
int CalculateConfluence(bool oversold, double macd, double price, double ma20)
{
   int score = 0;
   
   if(oversold && macd > 0) score++;
   if(oversold && price > ma20) score++;
   if(!oversold && macd < 0) score++;
   if(!oversold && price < ma20) score++;
   
   score += 3;
   
   return MathMin(score, 5);
}

//+------------------------------------------------------------------+
string GetStars(int count)
{
   string stars = "";
   for(int i = 0; i < count; i++)
      stars += "*";
   return stars;
}

//+------------------------------------------------------------------+
void SendAlert(string message, string alertType)
{
   if(EnablePopup)
   {
      Alert(alertType, ": ", Symbol());
   }
   
   if(EnableSound)
   {
      PlaySound("alert.wav");
   }
   
   if(EnableTelegram && StringLen(TelegramToken) > 10)
   {
      SendTelegramMessage(message);
   }
   
   if(EnableEmail)
   {
      SendMail(alertType + " - " + Symbol(), message);
   }
}

//+------------------------------------------------------------------+
void SendTelegramMessage(string message)
{
   string encoded = "";
   for(int i = 0; i < StringLen(message); i++)
   {
      ushort c = StringGetCharacter(message, i);
      if((c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122))
         encoded += ShortToString(c);
      else if(c == 32) encoded += "+";
      else if(c == 10) encoded += "%0A";
      else if(c == 58) encoded += "%3A";
      else if(c == 40) encoded += "%28";
      else if(c == 41) encoded += "%29";
      else if(c == 47) encoded += "%2F";
      else if(c == 46) encoded += ".";
      else encoded += ShortToString(c);
   }
   
   string url = "https://api.telegram.org/bot" + TelegramToken + 
                "/sendMessage?chat_id=" + TelegramChatID + 
                "&text=" + encoded;
   
   char post[], result[];
   string headers;
   
   int res = WebRequest("GET", url, "", NULL, 5000, post, 0, result, headers);
   
   if(res == -1)
      Print("Telegram send failed: ", GetLastError());
   else
      Print("Telegram alert sent");
}

//+------------------------------------------------------------------+
void DrawAlertLine(int index)
{
   if(priceAlerts[index].level <= 0)
      return;
   
   string name = "AlertLine_" + IntegerToString(index);
   
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, priceAlerts[index].level);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetString(0, name, OBJPROP_TEXT, "Alert " + IntegerToString(index+1));
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release indicator handles
   if(rsiHandle != INVALID_HANDLE) IndicatorRelease(rsiHandle);
   if(macdHandle != INVALID_HANDLE) IndicatorRelease(macdHandle);
   if(ma20Handle != INVALID_HANDLE) IndicatorRelease(ma20Handle);
   if(ma50Handle != INVALID_HANDLE) IndicatorRelease(ma50Handle);
   
   // Clean up alert lines
   for(int i = 0; i < 5; i++)
   {
      ObjectDelete(0, "AlertLine_" + IntegerToString(i));
   }
   
   Print("AlertMaster Pro stopped");
}
//+------------------------------------------------------------------+