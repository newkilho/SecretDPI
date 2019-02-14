program SecretDPI;

uses
  Vcl.Forms,
  Main in 'Main.pas' {FrmSecretDPI},
  Start in 'Start.pas' {FrmStart},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Tablet Light');
  Application.Title := '';
  Application.CreateForm(TFrmSecretDPI, FrmSecretDPI);
  Application.CreateForm(TFrmStart, FrmStart);
  Application.Run;
end.
