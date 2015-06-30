unit uDiagnosisService;

interface

uses
  Classes, SysUtils, ShlObj, Windows,
  uPhysicalDrive, uPhysicalDriveList, uLanguageSettings, uPathManager,
  uListChangeGetter, uDatasizeUnit, uLogSystem, uNSTSupport,
  uPartitionListGetter, uExeFunctions;

type
  TDiagnosisService = class
  private
    PhysicalDriveList: TPhysicalDriveList;
    LastChanges: TChangesList;
    IsFirstDiagnosis: Boolean;
    ErrorFilePath: String;
    procedure SetPhysicalDriveList;
    procedure FreeLastChanges;
    function GetLogLine(Timestamp: TDateTime; Content: String): String;
    function IsNeedDiagnosis: Boolean;
    procedure WriteBufferCheck;
    procedure LogAndCheckSMART;
    procedure RefreshReplacedSectorLog(Entry: TPhysicalDrive);
    procedure RefreshTotalWriteLog(Entry: TPhysicalDrive);
    procedure IfNeedToAlertCreateAlertFile(Entry: TPhysicalDrive;
      IsReplacedSectorDifferent: Boolean);
    function GetAlertFile: TStringList;
    function GetPartitionLetters(Entry: TPhysicalDrive): String;
  public
    constructor Create;
    destructor Destroy; override;
    procedure InitializePhysicalDriveList;
    procedure Diagnosis;
    function IsThereAnySupportedDrive: Boolean;
  end;

implementation

{ TDiagnosisService }

constructor TDiagnosisService.Create;
begin
  TPathManager.SetPath(nil);
  DetermineLanguage;
  ErrorFilePath := TPathManager.AllDesktopPath + '\!!!SSDError!!!.err';
end;

procedure TDiagnosisService.SetPhysicalDriveList;
var
  ListChangeGetter: TListChangeGetter;
begin
  FreeLastChanges;
  if PhysicalDriveList = nil then
    PhysicalDriveList := TPhysicalDriveList.Create;
  ListChangeGetter := TListChangeGetter.Create;
  ListChangeGetter.IsOnlyGetSupportedDrives := true;
  LastChanges :=
    ListChangeGetter.ServiceRefreshListWithResultFrom(PhysicalDriveList);
  FreeAndNil(ListChangeGetter);
end;

procedure TDiagnosisService.InitializePhysicalDriveList;
begin
  SetPhysicalDriveList;
end;

procedure TDiagnosisService.FreeLastChanges;
begin
  if LastChanges.Added <> nil then
    FreeAndNil(LastChanges.Added);
  if LastChanges.Deleted <> nil then
    FreeAndNil(LastChanges.Deleted);
end;

function TDiagnosisService.IsThereAnySupportedDrive: Boolean;
begin
  result := PhysicalDriveList.Count > 0;
end;

function TDiagnosisService.GetLogLine(Timestamp: TDateTime;
  Content: String): String;
begin
  result := FormatDateTime('[yy/mm/dd hh:nn:ss]', Timestamp) + Content;
end;

function TDiagnosisService.IsNeedDiagnosis: Boolean;
begin
  result := IsFirstDiagnosis or (FormatDateTime('mm', Now) = '00');
  if IsFirstDiagnosis = false then
    IsFirstDiagnosis := true;
end;

procedure TDiagnosisService.WriteBufferCheck;
var
  WriteBufferErrors: TStringList;
  AlertFile: TStringList;
  CurrentLine: Integer;
begin
  WriteBufferErrors := uExeFunctions.WriteBufferCheck;
  if WriteBufferErrors.Count > 0 then
  begin
    AlertFile := GetAlertFile;
    for CurrentLine := 0 to WriteBufferErrors.Count - 1 do
      AlertFile.Add(GetLogLine(Now,
        ' !!!!! ' + WriteBufferErrors[CurrentLine] + ' ' +
        CapWrongBuf[CurrLang] + ' !!!!! ' + CapWrongBuf2[CurrLang]));
    AlertFile.SaveToFile(ErrorFilePath);
    FreeAndNil(AlertFile);
  end;
  FreeAndNil(WriteBufferErrors);
end;

procedure TDiagnosisService.RefreshTotalWriteLog(Entry: TPhysicalDrive);
var
  TotalWriteLog: TNSTLog;
begin
  if Entry.SupportStatus.TotalWriteType <>
     TTotalWriteType.WriteSupportedAsValue then
      exit;

  TotalWriteLog := TNSTLog.Create(
    TPathManager.AppPath,
    Entry.IdentifyDeviceResult.Serial,
    UIntToStr(
      MBToLiteONUnit(
        Entry.SMARTInterpreted.TotalWrite.InValue.ValueInMiB)),
    false);
  FreeAndNil(TotalWriteLog);
end;

function TDiagnosisService.GetAlertFile: TStringList;
begin
  result := TStringList.Create;
  if FileExists(ErrorFilePath) then
    result.LoadFromFile(ErrorFilePath);
end;

function TDiagnosisService.GetPartitionLetters(Entry: TPhysicalDrive): String;
var
  PartitionList: TPartitionList;
  CurrentPartition: Integer;
begin
  PartitionList := Entry.GetPartitionList;
  result := '';
  for CurrentPartition := 0 to (PartitionList.Count - 1) do
    result := result + ' ' + PartitionList[CurrentPartition].Letter;
  FreeAndNil(PartitionList);
end;

procedure TDiagnosisService.IfNeedToAlertCreateAlertFile(Entry: TPhysicalDrive;
  IsReplacedSectorDifferent: Boolean);
var
  AlertFile: TStringList;
  AllMountedPartitions: String;
begin
  if (Entry.SMARTInterpreted.SMARTAlert.ReplacedSector = false) or
     (not IsReplacedSectorDifferent) then
     exit;

  AlertFile := GetAlertFile;
  AllMountedPartitions := GetPartitionLetters(Entry);
  AlertFile.Add(
    GetLogLine(Now, ' !!!!! ' +
      AllMountedPartitions + ' ' + CapBck[CurrLang] + ' !!!!! ' +
      CapBck2[CurrLang] + '(' +
      UIntToStr(Entry.SMARTInterpreted.ReplacedSectors) +
      CapCount[CurrLang] + ') ' + CapOcc[CurrLang]));
  AlertFile.SaveToFile(ErrorFilePath);
  FreeAndNil(AlertFile);
end;

procedure TDiagnosisService.RefreshReplacedSectorLog(Entry: TPhysicalDrive);
var
  ReplacedSectorLog: TNSTLog;
begin
  ReplacedSectorLog := TNSTLog.Create(
    TPathManager.AppPath,
    Entry.IdentifyDeviceResult.Serial,
    false);
  IfNeedToAlertCreateAlertFile(Entry,
    ReplacedSectorLog.ReadBothFiles(UIntToStr(
      Entry.SMARTInterpreted.ReplacedSectors)));
  FreeAndNil(ReplacedSectorLog);
end;

procedure TDiagnosisService.LogAndCheckSMART;
var
  CurrentEntry: TPhysicalDrive;
begin
  for CurrentEntry in PhysicalDriveList do
  begin
    if not CurrentEntry.IsDriveAvailable then
    begin
      SetPhysicalDriveList;
      exit;
    end;

    RefreshTotalWriteLog(CurrentEntry);
    RefreshReplacedSectorLog(CurrentEntry);
  end;
end;

procedure TDiagnosisService.Diagnosis;
begin
  if not IsNeedDiagnosis then
    exit;
  WriteBufferCheck;
  LogAndCheckSMART;
end;

destructor TDiagnosisService.Destroy;
begin
  FreeLastChanges;
  if PhysicalDriveList <> nil then
    FreeAndNil(PhysicalDriveList);
end;

end.