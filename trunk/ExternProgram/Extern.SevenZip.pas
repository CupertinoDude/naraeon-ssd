unit Extern.SevenZip;

interface

uses
  SysUtils,
  OS.ProcessOpener, Getter.CodesignVerifier;

type
  TSevenZip = class
  private
    function BuildCommand
      (const SzipPath, SrcFile, DestFolder, Password: String): String;
    function VerifySevenZip(const SzipPath: String): Boolean;
  public
    function Extract
      (const SzipPath, SrcFile, DestFolder: String;
       const Password: String = ''): AnsiString;
    class function Create: TSevenZip;
  end;

var
  SevenZip: TSevenZip;

implementation

{ TSevenZip }

function TSevenZip.BuildCommand(const SzipPath, SrcFile, DestFolder,
  Password: String): String;
begin
  result :=
    '"' + SzipPath + '" e -y ' +
    '-o"' + DestFolder + '\" ' +
    '"' + SrcFile + '"';

  if Length(Password) = 0 then
    exit;

  result :=
    result + ' -p"' + Password + '"';
end;

function TSevenZip.VerifySevenZip(const SzipPath: String): Boolean;
var
  CodesignVerifier: TCodesignVerifier;
begin
  CodesignVerifier := TCodesignVerifier.Create;
  result := CodesignVerifier.VerifySignByPublisher(SzipPath, 'Minkyu Kim');
  FreeAndNil(CodesignVerifier);
end;

class function TSevenZip.Create: TSevenZip;
begin
  if SevenZip = nil then
    result := inherited Create as self
  else
    result := SevenZip;
end;

function TSevenZip.Extract
  (const SzipPath, SrcFile, DestFolder, Password: String): AnsiString;
begin
  result := '';
  if VerifySevenZip(SzipPath) then
    result :=
      ProcessOpener.OpenProcWithOutput('C:\',
        BuildCommand(SzipPath, SrcFile, DestFolder, Password));
end;

initialization
  SevenZip := TSevenZip.Create;
finalization
  SevenZip.Free;
end.
