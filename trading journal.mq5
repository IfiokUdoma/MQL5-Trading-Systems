//+------------------------------------------------------------------+
//| TradeStats Pro - Virtual Financial Secretary                     |
//| Automatic Trade Journal with Reports & Analytics                 |
//+------------------------------------------------------------------+
#property copyright "TradeStats Pro"
#property version   "1.00"
#property strict

//--- Input Parameters
input group "=== Report Settings ==="
input bool EnableDailyReport = false;      // Daily Summary
input bool EnableWeeklyReport = true;      // Weekly Report
input bool EnableMonthlyReport = true;     // Monthly Statement
input int ReportHour = 17;                 // Report Time (Hour)

input group "=== Delivery Options ==="
input bool SendToTelegram = true;          // Send to Telegram
input bool SendToEmail = true;            // Send to Email
input bool ShowDashboard = true;           // Show Dashboard on Chart

input group "=== Telegram Settings ==="
input string TelegramToken = "";           // Bot Token
input string TelegramChatID = "";          // Chat ID

input group "=== Email Settings ==="
input string EmailAddress = "";            // Your Email

//--- Trade Structure
struct TradeRecord
{
   long ticket;
   datetime openTime;
   datetime closeTime;
   string symbol;
   int type;
   double lots;
   double openPrice;
   double closePrice;
   double profit;
   double pips;
   int duration;
};

TradeRecord trades[];
int totalTrades = 0;

//--- Statistics
int winningTrades = 0;
int losingTrades = 0;
double totalProfit = 0;
double totalLoss = 0;
double totalPips = 0;
double bestTrade = 0;
double worstTrade = 0;
string bestPair = "";
string worstPair = "";

datetime lastDailyReport = 0;
datetime lastWeeklyReport = 0;
datetime lastMonthlyReport = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print("TradeStats Pro v1.00 Started");
   Print("Monitoring account: ", AccountInfoInteger(ACCOUNT_LOGIN));
   Print("Daily Report: ", EnableDailyReport ? "ON" : "OFF");
   Print("Weekly Report: ", EnableWeeklyReport ? "ON" : "OFF");
   Print("Monthly Report: ", EnableMonthlyReport ? "ON" : "OFF");
   Print("========================================");
   
   // Load trade history
   LoadTradeHistory();
   
   // Set timer for dashboard updates
   EventSetTimer(10);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnTimer()
{
   // Update dashboard
   if(ShowDashboard)
   {
      UpdateDashboard();
   }
   
   // Check if it's time to send reports
   CheckReportTime();
}

//+------------------------------------------------------------------+
void OnTick()
{
   // Monitor for closed trades
   CheckForClosedTrades();
}

//+------------------------------------------------------------------+
void LoadTradeHistory()
{
   Print("Loading trade history...");
   
   // Get history from account
   HistorySelect(0, TimeCurrent());
   
   int dealsTotal = HistoryDealsTotal();
   ArrayResize(trades, 0);
   totalTrades = 0;
   
   for(int i = 0; i < dealsTotal; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0)
      {
         long dealEntry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(dealEntry == DEAL_ENTRY_OUT) // Only closed trades
         {
            long orderTicket = HistoryDealGetInteger(ticket, DEAL_ORDER);
            
            // Find matching entry deal
            ulong entryTicket = FindEntryDeal(orderTicket);
            if(entryTicket > 0)
            {
               RecordTrade(entryTicket, ticket);
            }
         }
      }
   }
   
   CalculateStatistics();
   Print("Loaded ", totalTrades, " trades");
}

//+------------------------------------------------------------------+
ulong FindEntryDeal(long orderTicket)
{
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0)
      {
         long order = HistoryDealGetInteger(ticket, DEAL_ORDER);
         long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(order == orderTicket && entry == DEAL_ENTRY_IN)
         {
            return ticket;
         }
      }
   }
   return 0;
}

//+------------------------------------------------------------------+
void RecordTrade(ulong entryTicket, ulong exitTicket)
{
   TradeRecord trade;
   
   trade.ticket = (long)exitTicket;
   trade.openTime = (datetime)HistoryDealGetInteger(entryTicket, DEAL_TIME);
   trade.closeTime = (datetime)HistoryDealGetInteger(exitTicket, DEAL_TIME);
   trade.symbol = HistoryDealGetString(exitTicket, DEAL_SYMBOL);
   trade.type = (int)HistoryDealGetInteger(entryTicket, DEAL_TYPE);
   trade.lots = HistoryDealGetDouble(entryTicket, DEAL_VOLUME);
   trade.openPrice = HistoryDealGetDouble(entryTicket, DEAL_PRICE);
   trade.closePrice = HistoryDealGetDouble(exitTicket, DEAL_PRICE);
   trade.profit = HistoryDealGetDouble(exitTicket, DEAL_PROFIT);
   
   // Calculate pips
   double point = SymbolInfoDouble(trade.symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(trade.symbol, SYMBOL_DIGITS);
   double pipValue = (digits == 3 || digits == 5) ? point * 10 : point;
   
   if(trade.type == DEAL_TYPE_BUY)
      trade.pips = (trade.closePrice - trade.openPrice) / pipValue;
   else
      trade.pips = (trade.openPrice - trade.closePrice) / pipValue;
   
   trade.duration = (int)(trade.closeTime - trade.openTime) / 60; // Minutes
   
   // Add to array
   int size = ArraySize(trades);
   ArrayResize(trades, size + 1);
   trades[size] = trade;
   totalTrades++;
}

//+------------------------------------------------------------------+
void CheckForClosedTrades()
{
   static int lastDealsCount = 0;
   
   HistorySelect(0, TimeCurrent());
   int currentDealsCount = HistoryDealsTotal();
   
   if(currentDealsCount > lastDealsCount)
   {
      Print("New trade detected, reloading history...");
      LoadTradeHistory();
   }
   
   lastDealsCount = currentDealsCount;
}

//+------------------------------------------------------------------+
void CalculateStatistics()
{
   winningTrades = 0;
   losingTrades = 0;
   totalProfit = 0;
   totalLoss = 0;
   totalPips = 0;
   bestTrade = 0;
   worstTrade = 0;
   
   for(int i = 0; i < totalTrades; i++)
   {
      if(trades[i].profit > 0)
      {
         winningTrades++;
         totalProfit += trades[i].profit;
         if(trades[i].profit > bestTrade)
         {
            bestTrade = trades[i].profit;
            bestPair = trades[i].symbol;
         }
      }
      else
      {
         losingTrades++;
         totalLoss += trades[i].profit;
         if(trades[i].profit < worstTrade)
         {
            worstTrade = trades[i].profit;
            worstPair = trades[i].symbol;
         }
      }
      
      totalPips += trades[i].pips;
   }
}

//+------------------------------------------------------------------+
void UpdateDashboard()
{
   int x = 10, y = 30, spacing = 15;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double todayPL = CalculateTodayPL();
   double weekPL = CalculateWeekPL();
   double monthPL = CalculateMonthPL();
   double winRate = (totalTrades > 0) ? (double)winningTrades / totalTrades * 100 : 0;
   
   CreateLabel("tj_title", "=== TRADESTATS PRO ===", x, y, clrWhite, 9); y += spacing;
   CreateLabel("tj_balance", "Balance: $" + DoubleToString(balance, 2), x, y, clrWhite, 8); y += spacing;
   CreateLabel("tj_equity", "Equity: $" + DoubleToString(equity, 2), x, y, clrGold, 8); y += spacing;
   CreateLabel("tj_line1", "------------------------", x, y, clrWhite, 8); y += spacing;
   CreateLabel("tj_today", "Today: $" + DoubleToString(todayPL, 2), x, y, todayPL >= 0 ? clrLime : clrRed, 8); y += spacing;
   CreateLabel("tj_week", "Week: $" + DoubleToString(weekPL, 2), x, y, weekPL >= 0 ? clrLime : clrRed, 8); y += spacing;
   CreateLabel("tj_month", "Month: $" + DoubleToString(monthPL, 2), x, y, monthPL >= 0 ? clrLime : clrRed, 8); y += spacing;
   CreateLabel("tj_line2", "------------------------", x, y, clrWhite, 8); y += spacing;
   CreateLabel("tj_trades", "Total Trades: " + IntegerToString(totalTrades), x, y, clrWhite, 8); y += spacing;
   CreateLabel("tj_winrate", "Win Rate: " + DoubleToString(winRate, 1) + "%", x, y, clrLime, 8); y += spacing;
   CreateLabel("tj_pips", "Total Pips: " + DoubleToString(totalPips, 1), x, y, totalPips >= 0 ? clrLime : clrRed, 8);
}

//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color clr, int size)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
double CalculateTodayPL()
{
   double pl = 0;
   datetime todayStart = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   
   for(int i = 0; i < totalTrades; i++)
   {
      if(trades[i].closeTime >= todayStart)
         pl += trades[i].profit;
   }
   return pl;
}

//+------------------------------------------------------------------+
double CalculateWeekPL()
{
   double pl = 0;
   datetime weekStart = TimeCurrent() - 7 * 24 * 3600;
   
   for(int i = 0; i < totalTrades; i++)
   {
      if(trades[i].closeTime >= weekStart)
         pl += trades[i].profit;
   }
   return pl;
}

//+------------------------------------------------------------------+
double CalculateMonthPL()
{
   double pl = 0;
   datetime monthStart = TimeCurrent() - 30 * 24 * 3600;
   
   for(int i = 0; i < totalTrades; i++)
   {
      if(trades[i].closeTime >= monthStart)
         pl += trades[i].profit;
   }
   return pl;
}

//+------------------------------------------------------------------+
void CheckReportTime()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   if(dt.hour == ReportHour && dt.min == 0)
   {
      datetime today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
      
      // Daily
      if(EnableDailyReport && lastDailyReport != today)
      {
         SendDailyReport();
         lastDailyReport = today;
      }
      
      // Weekly (Sunday)
      if(EnableWeeklyReport && dt.day_of_week == 0 && lastWeeklyReport != today)
      {
         SendWeeklyReport();
         lastWeeklyReport = today;
      }
      
      // Monthly (1st day)
      if(EnableMonthlyReport && dt.day == 1 && lastMonthlyReport != today)
      {
         SendMonthlyReport();
         lastMonthlyReport = today;
      }
   }
}

//+------------------------------------------------------------------+
void SendDailyReport()
{
   double todayPL = CalculateTodayPL();
   string report = GenerateDailyReport(todayPL);
   
   if(SendToTelegram && StringLen(TelegramToken) > 10)
   {
      SendTelegramMessage("DAILY TRADING SUMMARY\n\n" + report);
   }
   
   Print("Daily report generated: $", todayPL);
}

//+------------------------------------------------------------------+
void SendWeeklyReport()
{
   double weekPL = CalculateWeekPL();
   string report = GenerateWeeklyReport(weekPL);
   
   if(SendToTelegram && StringLen(TelegramToken) > 10)
   {
      SendTelegramMessage("WEEKLY TRADING REPORT\n\n" + report);
   }
   
   Print("Weekly report generated: $", weekPL);
}

//+------------------------------------------------------------------+
void SendMonthlyReport()
{
   double monthPL = CalculateMonthPL();
   string report = GenerateMonthlyReport(monthPL);
   
   if(SendToTelegram && StringLen(TelegramToken) > 10)
   {
      SendTelegramMessage("MONTHLY TRADING STATEMENT\n\n" + report);
   }
   
   Print("Monthly report generated: $", monthPL);
}

//+------------------------------------------------------------------+
string GenerateDailyReport(double todayPL)
{
   double winRate = (totalTrades > 0) ? (double)winningTrades / totalTrades * 100 : 0;
   
   return StringFormat(
      "Date: %s\n"
      "P/L: $%.2f\n"
      "Balance: $%.2f\n"
      "Trades Today: %d\n"
      "Win Rate: %.1f%%\n"
      "Total Pips: %.1f",
      TimeToString(TimeCurrent(), TIME_DATE),
      todayPL,
      AccountInfoDouble(ACCOUNT_BALANCE),
      CountTradesToday(),
      winRate,
      totalPips
   );
}

//+------------------------------------------------------------------+
string GenerateWeeklyReport(double weekPL)
{
   double winRate = (totalTrades > 0) ? (double)winningTrades / totalTrades * 100 : 0;
   double avgWin = (winningTrades > 0) ? totalProfit / winningTrades : 0;
   double avgLoss = (losingTrades > 0) ? totalLoss / losingTrades : 0;
   
   return StringFormat(
      "Week Ending: %s\n\n"
      "P/L: $%.2f\n"
      "Balance: $%.2f\n\n"
      "Total Trades: %d\n"
      "Winning: %d\n"
      "Losing: %d\n"
      "Win Rate: %.1f%%\n\n"
      "Best Trade: $%.2f (%s)\n"
      "Worst Trade: $%.2f (%s)\n"
      "Avg Win: $%.2f\n"
      "Avg Loss: $%.2f\n\n"
      "Total Pips: %.1f",
      TimeToString(TimeCurrent(), TIME_DATE),
      weekPL,
      AccountInfoDouble(ACCOUNT_BALANCE),
      totalTrades,
      winningTrades,
      losingTrades,
      winRate,
      bestTrade, bestPair,
      worstTrade, worstPair,
      avgWin, avgLoss,
      totalPips
   );
}

//+------------------------------------------------------------------+
string GenerateMonthlyReport(double monthPL)
{
   return GenerateWeeklyReport(monthPL); // Same format, different period
}

//+------------------------------------------------------------------+
int CountTradesToday()
{
   int count = 0;
   datetime todayStart = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   
   for(int i = 0; i < totalTrades; i++)
   {
      if(trades[i].closeTime >= todayStart)
         count++;
   }
   return count;
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
      else if(c == 36) encoded += "%24";
      else if(c == 37) encoded += "%25";
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
      Print("Telegram report sent successfully");
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0, "tj_");
   Print("TradeStats Pro stopped");
}
//+------------------------------------------------------------------+