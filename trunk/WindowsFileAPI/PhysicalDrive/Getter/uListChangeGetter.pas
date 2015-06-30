unit uListChangeGetter;

interface

uses
  SysUtils, Classes,
  uPhysicalDrive, uPhysicalDriveList, uPhysicalDriveListGetter;

type
  TChangesList = record
    Added: TPhysicalDriveList;
    Deleted: TStringList;
  end;
  
  TListChangeGetter = class
  private
    type
      TRefreshedListAndChanges = record
        RefreshedList: TPhysicalDriveList;
        Changes: TChangesList;
      end;
  private
    InnerIsOnlyGetSupportedDrives: Boolean;
    IsResultNeeded: Boolean;
    ListToRefresh: TPhysicalDriveList;
    CurrentPhysicalDriveList: TPhysicalDriveList;
    procedure GetCurrentPhysicalDriveList(IsService: Boolean);
    function GetListChangeByCurrentPhysicalDriveList:
      TRefreshedListAndChanges;
    function IsSupportedOrNotNeededToCheck(
      IsSupported: Boolean): Boolean;
    function ReturnAddedListAndRefreshList(
      var NewList: TPhysicalDriveList): TPhysicalDriveList;
    function ReturnDeletedListAndRefreshList(
      var NewList: TPhysicalDriveList): TStringList;
    function InnerRefreshListWithResultFrom(
      var ListToRefresh: TPhysicalDriveList; IsService: Boolean): TChangesList;
    function GetPhysicalDriveListGetter(
      IsService: Boolean): TPhysicalDriveListGetter;
  public
    property IsOnlyGetSupportedDrives: Boolean
      read InnerIsOnlyGetSupportedDrives write InnerIsOnlyGetSupportedDrives;
    procedure RefreshListWithoutResultFrom(
      var ListToRefresh: TPhysicalDriveList);
    function RefreshListWithResultFrom(
      var ListToRefresh: TPhysicalDriveList): TChangesList;
    function ServiceRefreshListWithResultFrom(
      var ListToRefresh: TPhysicalDriveList): TChangesList;
  end;

implementation

uses
  uAutoPhysicalDriveListGetter, uBruteForcePhysicalDriveListGetter;

function TListChangeGetter.IsSupportedOrNotNeededToCheck(
  IsSupported: Boolean): Boolean;
begin
  result :=
    (IsSupported) or
    (not IsOnlyGetSupportedDrives);
end;
  
procedure TListChangeGetter.RefreshListWithoutResultFrom(
  var ListToRefresh: TPhysicalDriveList);
begin
  IsResultNeeded := false;
  RefreshListWithResultFrom(ListToRefresh);
end;

function TListChangeGetter.GetPhysicalDriveListGetter(IsService: Boolean):
  TPhysicalDriveListGetter;
begin
  if not IsService then
    result := TAutoPhysicalDriveListGetter.Create
  else
    result := TBruteForcePhysicalDriveListGetter.Create;
end;

procedure TListChangeGetter.GetCurrentPhysicalDriveList(IsService: Boolean);
var
  PhysicalDriveListGetter: TPhysicalDriveListGetter;
begin
  PhysicalDriveListGetter := GetPhysicalDriveListGetter(IsService);
  CurrentPhysicalDriveList := PhysicalDriveListGetter.GetPhysicalDriveList;
  FreeAndNil(PhysicalDriveListGetter);
end;
  
function TListChangeGetter.RefreshListWithResultFrom(
  var ListToRefresh: TPhysicalDriveList): TChangesList;
begin
  result := InnerRefreshListWithResultFrom(ListToRefresh, false);
end;

function TListChangeGetter.ServiceRefreshListWithResultFrom(
  var ListToRefresh: TPhysicalDriveList): TChangesList;
begin
  result := InnerRefreshListWithResultFrom(ListToRefresh, true);
end;

function TListChangeGetter.InnerRefreshListWithResultFrom(
  var ListToRefresh: TPhysicalDriveList; IsService: Boolean): TChangesList;
var
  RefreshedListAndChanges: TRefreshedListAndChanges;
begin
  IsResultNeeded := true;
  self.ListToRefresh := ListToRefresh;
  GetCurrentPhysicalDriveList(IsService);
  RefreshedListAndChanges := GetListChangeByCurrentPhysicalDriveList;
  FreeAndNil(ListToRefresh);
  ListToRefresh := RefreshedListAndChanges.RefreshedList;
  result := RefreshedListAndChanges.Changes;
  FreeAndNil(CurrentPhysicalDriveList);
end;
  
function TListChangeGetter.ReturnAddedListAndRefreshList(
  var NewList: TPhysicalDriveList): TPhysicalDriveList;
var
  CurrentEntry: TPhysicalDrive;
  IsExistsInPreviousList: Boolean;
begin
  result := TPhysicalDriveList.Create;

  for CurrentEntry in CurrentPhysicalDriveList do
  begin
    IsExistsInPreviousList := ListToRefresh.IsExists(CurrentEntry);

    if IsSupportedOrNotNeededToCheck(CurrentEntry.SupportStatus.Supported) then
      NewList.Add(TPhysicalDrive.Create
        (StrToInt(CurrentEntry.GetPathOfFileAccessingWithoutPrefix)));

    if not IsResultNeeded then
      Continue;
      
    if (not IsExistsInPreviousList) and
       (IsSupportedOrNotNeededToCheck(CurrentEntry.SupportStatus.Supported))
       then
      result.Add(TPhysicalDrive.Create
        (StrToInt(CurrentEntry.GetPathOfFileAccessingWithoutPrefix)));
  end;
end;
  
function TListChangeGetter.ReturnDeletedListAndRefreshList(
  var NewList: TPhysicalDriveList): TStringList;
var
  ItemIndexOfListToRefresh: Integer;
  IsExistsInNewList: Boolean;
begin
  result := nil;
  if not IsResultNeeded then
    exit;
    
  result := TStringList.Create;

  for ItemIndexOfListToRefresh := 0 to ListToRefresh.Count - 1 do
  begin
    IsExistsInNewList :=
      NewList.IsExists(ListToRefresh[ItemIndexOfListToRefresh]);

    if not IsExistsInNewList then
      result.Add(ListToRefresh[ItemIndexOfListToRefresh].
        GetPathOfFileAccessing);
  end;
end;

function TListChangeGetter.GetListChangeByCurrentPhysicalDriveList:
  TRefreshedListAndChanges;
begin
  result.RefreshedList := TPhysicalDriveList.Create;
  result.Changes.Added :=
    ReturnAddedListAndRefreshList(result.RefreshedList);
  result.Changes.Deleted :=
    ReturnDeletedListAndRefreshList(result.RefreshedList);
end;
end.