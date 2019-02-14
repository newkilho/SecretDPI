unit Start;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.WinXCtrls, Vcl.Buttons,
  JvExStdCtrls, JvHtControls, Vcl.StdCtrls;

type
  TFrmStart = class(TForm)
    LabelTitle: TLabel;
    LabelContent: TJvHTLabel;
    BtnStart: TSpeedButton;
    Indicator: TActivityIndicator;
    procedure FormCreate(Sender: TObject);
    procedure BtnStartClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmStart: TFrmStart;

implementation

{$R *.dfm}

uses Main;

procedure TFrmStart.BtnStartClick(Sender: TObject);
var
  Path: string;
begin
  case TOSVersion.Architecture of
    arIntelX86: Path := ExtractFilePath(Application.ExeName)+'vendor\x86';
    arIntelX64: Path := ExtractFilePath(Application.ExeName)+'vendor\x86_64';
  end;

  if BtnStart.Down then
  begin
    BtnStart.Caption := '';
    BtnStart.Enabled := False;
    Indicator.Visible := True;
    Indicator.Animate := True;

    FrmSecretDPI.Start;

    Indicator.Visible := False;
    Indicator.Animate := False;
    BtnStart.Caption := '실행중';
    BtnStart.Enabled := True;
  end
  else
  begin
    BtnStart.Caption := '';
    BtnStart.Enabled := False;
    Indicator.Visible := True;
    Indicator.Animate := True;

    FrmSecretDPI.Stop;

    Indicator.Visible := False;
    Indicator.Animate := False;
    BtnStart.Caption := '실행하기';
    BtnStart.Enabled := True;
  end;
end;

procedure TFrmStart.FormCreate(Sender: TObject);
begin
  Caption := FrmSecretDPI.Caption;

  DesktopFont := True;
  Indicator.Visible := False;
end;

end.
