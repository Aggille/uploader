program Aggille.Uploader;

uses
  System.StartUpCopy,
  FMX.Forms,
  Aggille.Uploader.Main in 'Aggille.Uploader.Main.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
