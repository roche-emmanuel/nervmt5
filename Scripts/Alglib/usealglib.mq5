//+------------------------------------------------------------------+
//|                                                    UseAlglib.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Подключение библиотек                                            |
//+------------------------------------------------------------------+
#include <Math\Alglib\alglib.mqh>
#include <Trade\DealInfo.mqh>
#include <Arrays\ArrayDouble.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   CDealInfo     deal;          // объект для доступа к информации о сделках
   CArrayDouble *profit;        // объект для хранения прибыли/убытка по каждой сделке
   CArrayDouble *balance_total; // объект для хранения баланса
   double        balance=0;     // первоначальный баланс
//--- создаем динамические объекты
   profit=new CArrayDouble;
   if(CheckPointer(profit)==POINTER_INVALID)
     {
      PrintFormat("Ошибка создания динамического объекта для хранения прибылей/убытков: %d",GetLastError());
      return;
     }
   balance_total=new CArrayDouble;
   if(CheckPointer(balance_total)==POINTER_INVALID)
     {
      PrintFormat("Ошибка создания динамического объекта для хранения баланса: %d",GetLastError());
      delete profit;
      return;
     }
//--- получение торговой истории
   HistorySelect(0,TimeCurrent());
//--- общее количество сделок
   int deals_total=HistoryDealsTotal();
//--- получение данных о прибыли и балансе по сделкам
   for(int i=0;i<deals_total;i++)
     {
      deal.SelectByIndex(i);
      //--- получение первоначального баланса
      if(deal.DealType()==DEAL_TYPE_BALANCE)
        {
         if(NormalizeDouble(deal.Profit()+deal.Swap(),2)>=0.0)
            if(balance==0.0)
               balance=deal.Profit();
        }
      //--- получение данных по прибыли и балансу
      if(deal.DealType()==DEAL_TYPE_BUY || deal.DealType()==DEAL_TYPE_SELL)
         if(deal.Entry()==DEAL_ENTRY_OUT || deal.Entry()==DEAL_ENTRY_INOUT)
           {
            profit.Add(NormalizeDouble(deal.Profit()+deal.Swap()+deal.Commission(),2));
            balance_total.Add(balance);
            balance=balance+NormalizeDouble(deal.Profit()+deal.Swap()+deal.Commission(),2);
           }
     }
//--- проверим наличие торговых операций в истории
   if(balance_total.Total()==0 || profit.Total()==0)
     {
      Print("Не найдено завершенных торговых операций в истории торговли");
      delete balance_total;
      delete profit;
      return;
     }
   balance_total.Add(balance_total.At(balance_total.Total()-1)+profit.At(balance_total.Total()-1));
//--- подготовим данные для расчета линейной регрессии
   double arr_balance[];
   double arr_profit[];
   ArrayResize(arr_balance,balance_total.Total());
   ArrayResize(arr_profit,profit.Total());
//--- копирование данных баланса в массив типа double
   for(int i=0;i<balance_total.Total();i++)
      arr_balance[i]=balance_total.At(i);
//--- копирование данных прибыли в массив типа double
   for(int i=0;i<profit.Total();i++)
      arr_profit[i]=profit.At(i);
//--- расчитаем линейную регресcию
   int nvars=1;                       // количество независимых переменных
   int npoints=balance_total.Total(); // объем выборки
   CMatrixDouble xy(npoints,nvars+1); // матрица параметров для линейной регрессии
   int info;             // результат вычисления коэффициента линейной регрессии
   CLinearModelShell lm;
   CLRReportShell    ar;
   double lr_coeff[];
   double lr_values[];
   ArrayResize(lr_values,npoints);
//--- заполнение матрицы параметров для линейной регрессии
   for(int i=0;i<npoints;i++)
     {
      xy[i].Set(0,i);
      xy[i].Set(1,arr_balance[i]);
     }
//--- вычисление коэффициентов линейной регрессии
   CAlglib::LRBuild(xy,npoints,nvars,info,lm,ar);
//--- проверим результат вычисления
   if(info!=1)
     {
      PrintFormat("Ошибка вычисления коэффициентов линейной регрессии: %d",info);
      delete balance_total;
      delete profit;
      return;
     }
//--- получение коэффициентов линейной регрессии
   CAlglib::LRUnpack(lm,lr_coeff,nvars);
//--- получение восстановленных значений линейной регрессии
   for(int i=0;i<npoints;i++)
      lr_values[i]=lr_coeff[0]*i+lr_coeff[1];
//--- вычисление Expected Payoff
   double exp_payoff,tmp1,tmp2,tmp3;
   CAlglib::SampleMoments(arr_profit,exp_payoff,tmp1,tmp2,tmp3);
//--- вычисление массива HPR
   double HPR[];
   ArrayResize(HPR,balance_total.Total()-1);
   for(int i=0;i<balance_total.Total()-1;i++)
      HPR[i]=balance_total.At(i+1)/balance_total.At(i);
//--- вычисление стандартного отклонения и мат.ожидания от HPR
   double AHPR,SD;
   CAlglib::SampleMoments(HPR,AHPR,SD,tmp2,tmp3);
   SD=MathSqrt(SD);
//--- вычисление LR Correlation
   double lr_corr=CAlglib::PearsonCorr2(arr_balance,lr_values);
//--- получение LR Standard Error
   double lr_stand_err=0;
   for(int i=0;i<npoints;i++)
     {
      double delta=MathAbs(arr_balance[i]-lr_values[i]);
      lr_stand_err=lr_stand_err+delta*delta;
     }
   lr_stand_err=MathSqrt(lr_stand_err/(npoints-2));
//--- вычисление Sharpe Ratio
   double sharpe_ratio=(AHPR-1)/SD;
//--- выводим отчет
   PrintFormat("-----------------------------------------------");
   PrintFormat("Функция зависимости: y = %.2fx + %.2f",lr_coeff[0],lr_coeff[1]);
//--- параметры
   PrintFormat("Expected Payoff = %.2f",exp_payoff);
   PrintFormat("AHPR = %.4f",AHPR);
   PrintFormat("Sharpe Ratio = %.2f",sharpe_ratio);
   PrintFormat("LR Correlation = %.2f",lr_corr);
   PrintFormat("LR Standard Error = %.2f",lr_stand_err);
   PrintFormat("-----------------------------------------------");
//--- удаление динамических объектов
   delete profit;
   delete balance_total;
  }
//+------------------------------------------------------------------+
