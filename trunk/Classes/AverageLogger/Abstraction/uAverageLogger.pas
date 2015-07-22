unit uAverageLogger;

interface

uses Classes, Sysutils, Dialogs, Windows, Math, uUINT64;

type
  TAveragePeriod = (Days30, Days90, Days180);
  
  TPeriodAverage = record
    Period: TAveragePeriod;
    FormattedAverageValue: String;
  end;
  
  TAverageLogger = abstract class
  private
    LastDateInLog: String;
    LastValueInLog: UInt64;
    MaxPeriodAverage: TPeriodAverage;
    PassedDaysFromFirst: Integer;
    TodayDelta: Integer;
    UserDefaultFormat: TFormatSettings;
    TimestampedValueList: TStringList;
    FileName: String;
    procedure ChangeLastRecordedPeriodToNow;
    procedure AddNewRecordWithTimestamp(NewValue: String);
    procedure ReadFileOrCreateNew(FileName: String);
    function IsNewValueInvalid(NewValue: String): Boolean;
    procedure InitializeAverageTodayDelta;
    procedure ReadAndSetAverageTodayDelta(NewValue: String);
    procedure SetAverage(NewValue: String);
    procedure RefreshFile(NewValue: String);
    procedure DisposeExpiredRecords;
    procedure SaveToFile;
  protected
    function GetUnit: Double; virtual; abstract; 
  public
    constructor Create(FileName: String);
    procedure ReadAndRefresh(NewValue: String);
    function GetFormattedTodayDelta: String;  
    function GetMaxPeriodFormattedAverage: TPeriodAverage;  
    class function BuildFileName(Folder, Serial: String): String;
  end;

implementation

procedure TAverageLogger.ReadFileOrCreateNew(FileName: String);
begin
  self.FileName := FileName;
  if not FileExists(FileName) then
    TimestampedValueList.SaveToFile(FileName)
  else
    TimestampedValueList.LoadFromFile(FileName);
  if TimestampedValueList.Count > 0 then
    DisposeExpiredRecords;
end;

constructor TAverageLogger.Create(FileName: String);
begin
  TimestampedValueList := TStringList.Create;
  UserDefaultFormat := TFormatSettings.Create(GetUserDefaultLCID);
  UserDefaultFormat.DateSeparator := '-';
  ReadFileOrCreateNew(FileName);
end;

destructor TAverageLogger.Destroy;
begin
  FreeAndNil(TimestampedValueList);
end;

function TAverageLogger.IsNewValueInvalid(NewValue: String): Boolean;
var
  NewValueInUInt64: UInt64;
begin
  result :=
    (not (TryStrToUInt64(NewValue, NewValueInUInt64))) or
    (NewValueInUInt64 = 0);
end;

procedure TAverageLogger.InitializeAverageTodayDelta;
begin
  LastDateInLog := '';
  LastValueInLog := 0;
  PassedDaysFromFirst := 0;
  InnerMaxPeriodAverage.Period := TAveragePeriod.Days30;
  InnerMaxPeriodAverage.FormattedAverageValue := '';
  TodayDelta := 0;
end;

procedure TAverageLogger.SetAverage(NewValue: String);
const
  AvgMax = 2;
  AveragePeriodInInteger: Array[TAveragePeriod] of Integer = (30, 90, 180);
  IntegerToAveragePeriod: Array[0..AvgMax] of TAveragePeriod =
    (Days30, Days90, Days180);
var
  FirstValueInLog: Integer;
  CurrentAveragePeriod: Integer;
  AverageValue: Double;
begin
  FirstValueInLog := 
    StrToUInt64(TimestampedValueList.Count - 1]);
  if StrToUInt64(NewValue) = (FirstValueInLog) then
    exit;
    
  for CurrentAveragePeriod := AvgMax downto 0 do
    if PassedDaysFromFirst <= AveragePeriodInInteger[CurrentAveragePeriod] then
    begin
      MaxPeriodAverage.Period :=
        IntegerToAveragePeriod[CurrentAveragePeriod];
      AverageValue :=
        (StrToUInt64(NewValue) - (StrToUInt64(FirstValueInLog))) /
        PassedDaysFromFirst *
        GetUnit;
      MaxPeriodAverage.FormattedAverageValue :=
        Format('%.1f', [AverageValue]);
      break;  
    end;
end;

function TAverageLogger.GetFormattedTodayDelta: String;  
begin
  result := Format('%.1f', [TodayDelta]);
end;

function TAverageLogger.GetMaxPeriodFormattedAverage: TPeriodAverage;  
begin
  result := MaxPeriodAverage;
end;

procedure TAverageLogger.ReadAndSetAverageTodayDelta(NewValue: String);
begin
  InitializeAverageTodayDelta;
  if TimestampedValueList.Count = 0 then
    exit;
  
  LastDateInLog := TimestampedValueList[0];
  LastValueInLog := StrToUInt64(TimestampedValueList[1]);
  PassedDaysFromFirst :=
    Ceil(Now - StrToDateTime(
      TimestampedValueList[
        TimestampedValueList.Count - 2], UserDefaultFormat));
  TodayDelta :=
    (StrToUInt64(CurrGig) - StrToUInt64(TimestampedValueList[1])) * GetUnit;
  SetAverage(NewValue);
end;


procedure TAverageLogger.RefreshFile(NewValue: String);
begin
  if LastDateInLog = FormatDateTime('yy/mm/dd', Now) then
    exit;
    
  LastDateInLog := FormatDateTime('yy/mm/dd', Now);
  LastOneGig := StrToUInt64(NewValue);
  if TodayDelta > 0 then AddNewRecordWithTimestamp(NewValue)
  else ChangeLastRecordedPeriodToNow;
end;

procedure TAverageLogger.ReadAndRefresh(NewValue: String);
begin
  if IsNewValueInvalid(NewValue) then
    exit;

  ReadAndSetAverageTodayDelta(NewValue);
  RefreshFile(NewValue);
end;

procedure TAverageLogger.DisposeExpiredRecords;
begin
  while (Now - 181) >
    StrToDateTime(
      TimestampedValueList[TimestampedValueList.Count - 2],
      UserDefaultFormat) do
  begin
    TimestampedValueList.Delete(TimestampedValueList.Count - 1);
    TimestampedValueList.Delete(TimestampedValueList.Count - 1);
  end;
end;

procedure TAverageLogger.ChangeLastRecordedPeriodToNow;
begin
  TimestampedValueList[0] := FormatDateTime('yy/mm/dd', Now);
  SaveToFile;
end;

procedure TAverageLogger.AddNewRecordWithTimestamp(NewValue: String);
begin
  TimestampedValueList.Insert(0, NewValue);
  TimestampedValueList.Insert(0, FormatDateTime('yy/mm/dd', Now));
  SaveToFile;
end;

procedure TAverageLogger.SaveToFile;
begin
  TimestampedValueList.SaveToFile(FileName);
end;

class function TAverageLogger.BuildFileName(Folder, Serial: String): String;
begin
  result := Folder + 'WriteLog' + Serial + '.txt';
end;
end.