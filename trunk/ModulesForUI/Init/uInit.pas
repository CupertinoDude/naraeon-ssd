unit uInit;

interface

uses
  Forms, SysUtils, StdCtrls, ExtCtrls, Windows, Classes, Graphics, Controls,
  WinCodec,
  uAlert, uButtonGroup, uPathManager, uLanguageSettings;

procedure InitializeMainForm;
procedure RefreshOptimizeList;

implementation

uses uMain;

type
  THackControl = class(TControl);
  THackMainForm = class(TfMain);

  TMainformInitializer = class
  public
    constructor Create(MainformToInitialize: TfMain);
    procedure InitializeMainform;
  private
    Mainform: THackMainForm;

    procedure CreateButtonGroup;
    procedure RefreshOptimizeList;
    procedure LoadBGImage;
    procedure SetFormSize;
    procedure SetIcon;
    procedure AddButtonsToButtonGroup;
    procedure SetMessageFontAsApplicationFont;
    procedure FixFontToApplicationFont;
    procedure FixMainformSize;
    procedure LoadLogoImage;
    procedure LoadAndProportionalStretchLogoXP;
    procedure LoadAndProportionalStretchLogo;
  end;

procedure InitializeMainForm;
var
  MainformInitializer: TMainformInitializer;
begin
  MainformInitializer := TMainformInitializer.Create(fMain);
  MainformInitializer.InitializeMainform;
  FreeAndNil(MainformInitializer);
end;

procedure RefreshOptimizeList;
var
  MainformInitializer: TMainformInitializer;
begin
  MainformInitializer := TMainformInitializer.Create(fMain);
  MainformInitializer.RefreshOptimizeList;
  FreeAndNil(MainformInitializer);
end;

{ TMainformInitializer }

constructor TMainformInitializer.Create(MainformToInitialize: TfMain);
begin
  Mainform := THackMainForm(MainformToInitialize);
end;

procedure TMainformInitializer.InitializeMainform;
begin
  CreateButtonGroup;
  AddButtonsToButtonGroup;
  LoadBGImage;
  LoadLogoImage;
  SetFormSize;
  SetIcon;
  RefreshOptimizeList;
  SetMessageFontAsApplicationFont;
  FixFontToApplicationFont;
  FixMainformSize;
end;

procedure TMainformInitializer.CreateButtonGroup;
begin
  Mainform.ButtonGroup :=
      TButtonGroup.Create(fMain, MaximumSize, MinimumSize,
        Mainform.ClientWidth, Mainform.ClientWidth);
end;

procedure TMainformInitializer.AddButtonsToButtonGroup;
begin
  Mainform.ButtonGroup.AddEntry(
    False, Mainform.iFirmUp, Mainform.lFirmUp, Mainform.gFirmware, nil);
  Mainform.ButtonGroup.AddEntry(
    False, Mainform.iErase, Mainform.lErase, Mainform.gErase, nil);
  Mainform.ButtonGroup.AddEntry(
    False, Mainform.iAnalytics, Mainform.lAnalytics, Mainform.gAnalytics, nil);
  Mainform.ButtonGroup.AddEntry(
    False, Mainform.iTrim, Mainform.lTrim, Mainform.gTrim, nil);
  Mainform.ButtonGroup.AddEntry(
    False, Mainform.iOptimize, Mainform.lOptimize, Mainform.gOpt, nil);
end;

procedure TMainformInitializer.SetFormSize;
begin
  Mainform.Constraints.MaxHeight := 0;
  Mainform.Constraints.MinHeight := 0;
  Mainform.ClientHeight := MinimumSize;
  Mainform.Constraints.MaxHeight := Mainform.Height;
  Mainform.Constraints.MinHeight := Mainform.Height;
end;

procedure TMainformInitializer.SetIcon;
begin
  Mainform.Icon := Application.Icon;
end;

procedure TMainformInitializer.RefreshOptimizeList;
var
  CurrItem: Integer;
begin
  Mainform.lList.Items.Assign(Mainform.Optimizer.Descriptions);
  for CurrItem := 0 to (Mainform.Optimizer.Descriptions.Count - 1) do
  begin
    Mainform.lList.Checked[CurrItem] :=
      (not Mainform.Optimizer.Optimized[CurrItem]) and
      (not Mainform.Optimizer.Selective[CurrItem]);

    if Mainform.Optimizer.Optimized[CurrItem] then
      Mainform.lList.Items[CurrItem] :=
        Mainform.lList.Items[CurrItem] +
        CapAlreadyCompleted[CurrLang];
  end;
end;

procedure TMainformInitializer.SetMessageFontAsApplicationFont;
begin
  Application.DefaultFont := Screen.MessageFont;
end;


procedure TMainformInitializer.FixFontToApplicationFont;
  procedure SetFontName(Control: TControl; const FontName: String);
  begin
    THackControl(Control).Font.Name := FontName;
  end;
var
  CurrCompNum: Integer;
  CurrComponent: TComponent;
begin
  Mainform.Font.Name := Application.DefaultFont.Name;

  for CurrCompNum := 0 to Mainform.ComponentCount - 1 do
  begin
    CurrComponent := Mainform.Components[CurrCompNum];
    if CurrComponent is TControl then
      SetFontName(TControl(CurrComponent), Mainform.Font.Name);
  end;
end;

procedure TMainformInitializer.FixMainformSize;
begin
  Mainform.Constraints.MaxWidth := Mainform.Width;
  Mainform.Constraints.MaxHeight := Mainform.Height;
  Mainform.Constraints.MinWidth := Mainform.Width;
  Mainform.Constraints.MinHeight := Mainform.Height;
end;

procedure TMainformInitializer.LoadBGImage;
begin
  if FileExists(TPathManager.AppPath + 'Image\bg.png') then
    fMain.iBG.Picture.LoadFromFile(TPathManager.AppPath + 'Image\bg.png');
end;

procedure TMainformInitializer.LoadAndProportionalStretchLogo;
var
  ImageToStretch: TWICImage;
  Scaler: IWICBitmapScaler;
  ScaledImage: IWICBitmap;
begin
  if fMain.WICImage <> nil then
    ImageToStretch := fMain.WICImage
  else
    ImageToStretch := TWICImage.Create;

  ImageToStretch.LoadFromFile(TPathManager.AppPath + 'Image\logo.png');
  ImageToStretch.ImagingFactory.CreateBitmapScaler
    (Scaler);
  Scaler.Initialize(ImageToStretch.Handle,
    fMain.iLogo.Width,
    fMain.iLogo.Height,
    WICBitmapInterpolationModeFant);
  ImageToStretch.ImagingFactory.CreateBitmapFromSourceRect(
    Scaler, 0, 0,
    fMain.iLogo.Width,
    fMain.iLogo.Height,
    ScaledImage);
  ImageToStretch.Handle := ScaledImage;
  fMain.iLogo.Picture.Bitmap.Assign(ImageToStretch);

  fMain.WICImage := ImageToStretch;
end;

procedure TMainformInitializer.LoadAndProportionalStretchLogoXP;
begin
  fMain.iLogo.Proportional := true;
  if FileExists(TPathManager.AppPath + 'Image\logo.png') then
    fMain.iLogo.Picture.LoadFromFile(TPathManager.AppPath + 'Image\logo.png');
end;

procedure TMainformInitializer.LoadLogoImage;
begin
  if Win32MajorVersion = 5 then
    LoadAndProportionalStretchLogoXP
  else
    LoadAndProportionalStretchLogo;
end;

end.
