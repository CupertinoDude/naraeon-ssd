unit Getter.PhysicalDriveList;

interface

uses
  Device.PhysicalDrive.List;

type
  TPhysicalDriveListGetter = class abstract
  public
    PhysicalDriveList: TPhysicalDriveList;
    function GetPhysicalDriveList: TPhysicalDriveList; virtual; abstract;
  end;

implementation

end.
