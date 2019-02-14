unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls,
  Vcl.Buttons, Vcl.StdCtrls, System.Win.ComObj, Winapi.ShellAPI, ActiveX,
  DosCommand, K.Strings, K.HTTP;

type
  TFrmSecretDPI = class(TForm)
    PanelMenu: TPanel;
    BtnStart: TSpeedButton;
    BtnConfig: TSpeedButton;
    ImageLogo: TImage;
    PanelMain: TPanel;
    DosCommand: TDosCommand;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    procedure Init;
  public
    GoodbyeDPI: string;
    GoodByeDPI_Option: string;
    MTUSize:  Integer;
    IsRun: Boolean;

    procedure Start;
    procedure Stop;
    procedure MTUFragment(MTU: Integer);
  end;

var
  FrmSecretDPI: TFrmSecretDPI;

const
  VER = '0.92';

implementation

{$R *.dfm}

uses Start;

function GetHTTP(URL: String; Json: String=''): string;
var
  Thread: TThread;
  Data: string;
begin
  Thread := TThread.CreateAnonymousThread(
    procedure
    var
      HTTP: THTTP;
    begin
      HTTP := THTTP.Create;
      HTTP.ConnectionTimeOut := 5000;
      HTTP.CustomHeaders['User-Version'] := VER;

      if Json = '' then
        Data := HTTP.Get(URL)
      else
        begin
          HTTP.ContentType := 'application/json';
          Data := HTTP.Get(URL, Json);
        end;

      HTTP.Free;
    end
  );

  Thread.FreeOnTerminate := True;
  Thread.Start;
  while (not Thread.Finished) and (not Application.Terminated) do Application.ProcessMessages;

  Result := Data;
end;

procedure ShellExecuteWait(FileName, Params: string);
var
  ExeInfo: TShellExecuteInfo;
begin
  FillChar(ExeInfo, SizeOf(ExeInfo), 0);
  ExeInfo.cbSize := SizeOf(ExeInfo);
  ExeInfo.fMask := See_Mask_NoCloseProcess;
  ExeInfo.lpVerb := 'Open';
  ExeInfo.lpFile := pWideChar(FileName);
  ExeInfo.lpParameters := pWideChar(Params);
  ExeInfo.nShow := SW_HIDE;

  if ShellExecuteEx(@ExeInfo) then
    while WaitForSingleObject(ExeInfo.hProcess, INFINITE) <> WAIT_OBJECT_0 do
      Application.ProcessMessages;
end;

procedure TFrmSecretDPI.Init;
var
  Data, Item: string;
begin
  Data := GetHTTP('http://secretdpi.kilho.net/api.init.php');

  if Data = '' then
  begin
    FrmStart.LabelContent.Caption := '<BR><BR><ALIGN CENTER><FONT COLOR="clRED">서버에서 정보를 받지 못했습니다.</FONT></ALIGN>';
  end
  else
  begin
    FrmStart.LabelContent.Caption := EscapeDecode(Parsing(Data, '"content":"', '"'));

    Item := EscapeDecode(Parsing(Data, '"update":"', '"'));
    if Item <> '' then
      if MessageBox(Application.Handle, '업데이트가 정보가 있습니다.'+#13#13+'안정적으로 사용하기 위해 새로 다운받고 실행하는걸 권장합니다.'+#13#13+'다운받으시겠습니까?', PChar(Caption), MB_YESNO or MB_SYSTEMMODAL) = IDYES then
      begin
        ShellExecute(Application.Handle, 'open', pChar(Item), nil, nil, SW_SHOWNORMAL);
        Halt;
      end;

    GoodByeDPI_Option := EscapeDecode(Parsing(Data, '"option":"', '"'));
    MTUSize := StrToIntDef(Parsing(Data, '"mtu":"', '"'), 200);
  end;
end;

procedure TFrmSecretDPI.MTUFragment(MTU: Integer);
const
  WbemUser = '';
  WbemPassword = '';
  WbemComputer = 'localhost';
  wbemFlagForwardOnly = $00000020;
var
  ElementCount: LongWord;
  FWMIService: OleVariant;
  FWbemObject: OleVariant;
  EnumVariant: IEnumVARIANT;
  FSWbemLocator: OleVariant;
  FWbemObjectSet: OleVariant;

  Name, Index: string;
begin;
  try
    FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
    FWMIService := FSWbemLocator.ConnectServer(WbemComputer, 'root\CIMV2', WbemUser, WbemPassword);
    FWbemObjectSet := FWMIService.ExecQuery('SELECT * FROM Win32_NetworkAdapter WHERE PhysicalAdapter = 1', 'WQL', wbemFlagForwardOnly);
    EnumVariant := IUnknown(FWbemObjectSet._NewEnum) as IEnumVariant;
    while EnumVariant.Next(1, FWbemObject, ElementCount) = 0 do
    begin
      Name := LowerCase(VarToStr(FWbemObject.Name));
      if Pos('vmware', Name)>0 then Continue;
      if Pos('bluetooth', Name)>0 then Continue;
      if Pos('virtual', Name)>0 then Continue;
      if Pos('usb', Name)>0 then Continue;
      if Pos('wireless', Name)>0 then Continue;
      if Pos('sharing', Name)>0 then Continue;
      if Pos('mobile', Name)>0 then Continue;

      Index := VarToStr(FWbemObject.InterfaceIndex);

      ShellExecuteWait('netsh', 'interface ipv4 set subinterface "'+Index+'" mtu='+MTU.ToString+' store=persistent');

      FWbemObject := Unassigned;
    end;
  except
  end;
end;

procedure TFrmSecretDPI.Start;
begin
  if not FileExists(GoodbyeDPI) then
  begin
    MTUFragment(MTUSize);
  end
  else
  begin
    DosCommand.CommandLine := '"'+GoodbyeDPI+'" '+GoodByeDPI_Option;
    DosCommand.Execute;
  end;

  IsRun := True;
end;

procedure TFrmSecretDPI.Stop;
begin
  if not FileExists(GoodbyeDPI) then
    FrmSecretDPI.MTUFragment(1500)
  else
    FrmSecretDPI.DosCommand.Stop;

  IsRun := False;
end;

procedure TFrmSecretDPI.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if IsRun then Stop;
end;

procedure TFrmSecretDPI.FormCreate(Sender: TObject);
begin
  Application.Title := Caption;
  Caption := Caption+' v '+VER;
  DesktopFont := True;

  case TOSVersion.Architecture of
    arIntelX86: GoodByeDPI := ExtractFilePath(Application.ExeName)+'vendor\x86\goodbyedpi.exe';
    arIntelX64: GoodByeDPI := ExtractFilePath(Application.ExeName)+'vendor\x86_64\goodbyedpi.exe';
  end;
  GoodByeDPI_Option := '';

  MTUSize := 200;

  IsRun := False;

  FrmStart := TFrmStart.Create(PanelMain);
  with FrmStart do
  begin
    Parent := PanelMain;
    Left := 0;
    Top := 0;
    BorderStyle := bsNone;
    LabelContent.Caption := '<BR><BR><ALIGN CENTER><FONT COLOR="clBLUE">준비중...</FONT></ALIGN>';
    Visible := True;
  end;

  Init;

  BtnStart.Enabled := True;
end;

end.
