unit uAverageWriteLogger;

interface

uses uAverageLogger;

type
  TAverageWriteLogger = class(TAverageLogger)
  protected
    function GetUnit: Double; override;
  end;

implementation

function TAverageWriteLogger.GetUnit: Double; 
begin
  result := 0.064;
end;
end.
