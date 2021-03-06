unit PrerequisiteChecker;

interface

uses
  Forms, SysUtils, Windows,
  Form.Alert, Global.LanguageString, OS.EnvironmentVariable, Getter.OS.Version;

procedure CheckPrerequisite;

implementation

uses Form.Main;

procedure CheckVersion;
begin
  if VersionHelper.Version.FMajorVer < 5 then
  begin
    AlertCreate(fMain, AlrtOSError[CurrLang]);
    Application.Terminate;
  end;
end;

procedure CheckEssentialDir;
begin
  if FileExists(EnvironmentVariable.AppPath + 'Setup.exe') then
    SysUtils.DeleteFile(EnvironmentVariable.AppPath + 'Setup.exe');
  if not DirectoryExists(EnvironmentVariable.AppPath + 'Image') then
    CreateDirectory(PChar(EnvironmentVariable.AppPath + 'Image'), nil);
  if not DirectoryExists(EnvironmentVariable.AppPath + 'Erase') then
    CreateDirectory(PChar(EnvironmentVariable.AppPath + 'Erase'), nil);
  if not DirectoryExists(EnvironmentVariable.AppPath + 'Rufus') then
    CreateDirectory(PChar(EnvironmentVariable.AppPath + 'Rufus'), nil);
end;

procedure CheckPrerequisite;
begin
  CheckVersion;
  CheckEssentialDir;
end;
end.
