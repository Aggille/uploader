unit Aggille.Uploader.Main;

interface

uses
  System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,System.Zip,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Memo,System.IniFiles, ZipMstr, Aggille.Util.Zip, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase,
  IdFTP, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, FMX.Objects;

type

  TFrmMain = class(TForm)
    edtMessage: TMemo;
    lblMensagem: TLabel;
    pb1: TProgressBar;
    pb2: TProgressBar;
    lblPb1: TLabel;
    lblPb2: TLabel;
    StyleBook1: TStyleBook;
    img1: TImage;
    Rectangle1: TRectangle;
    rectStart: TRectangle;
    RectExit: TRectangle;
    lblBtnStart: TLabel;
    lblBtnStart1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure lblBtnStartClick(Sender: TObject);
    procedure Mensagem( aMensagem:String );
    procedure EnviaFtp();
    procedure RectExitClick(Sender: TObject);
  private
    { Private declarations }
    FIniFile:TIniFile;
    FUploadFiles,
    FFiles,
    FFolders:TStringList;
    FExeVersion,
    FZipFileName:String;
    FZipFile:TZipMaster;
    procedure LoadFiles;
    procedure LoadFolders;
    procedure LoadUploadFiles;
    procedure AddFilesToZip;
    procedure AddFoldersToZip;
    procedure ZipFileMessage(Sender: TObject; ErrCode: Integer;const Message: String);
    procedure ZipFileProgress(Sender: TObject; details: TZMProgressDetails);
    procedure ZipFileTick(Sender: TObject);
    function VersaoExe( aExe:String ):String;
    function FileSize( aFile:String ):Integer;
    procedure FtpWork(ASender: TObject; AWorkMode: TWorkMode;AWorkCount: Int64);
  public
    { Public declarations }
  protected
    FNewCount: Integer;
  end;

const
 INI_NAME = 'AggilleUploader.ini';
 SECTION_FTP = 'Ftp';
 SECTION_ZIPFILE = 'ZipFile';
 SECTION_UPLOAD_FILES = 'UploadFiles';
 SECTION_FILES = 'FilesToZip';
 SECTION_FOLDERS = 'FoldersToZip';
 SECTION_EXEFILE = 'Exefile';
 SECTION_VERSION_FILE = 'VersionFile';
var
  FrmMain: TFrmMain;

implementation

uses
  Winapi.Windows, IdFTPCommon, System.SysUtils;

{$R *.fmx}

procedure TFrmMain.AddFilesToZip;
var
i:Integer;
aFile:String;
begin

  try
    with FZipFile do
    begin
      for i := 0 to FFiles.Count - 1 do
        begin
          aFile := FFiles.ValueFromIndex[i];
          FSpecArgs.Add( aFile );
        end;
    end;

  finally

  end;

end;

procedure TFrmMain.AddFoldersToZip;
var
i:Integer;
aFolder:String;
begin

  try
    with FZipFile do
    begin
      for i := 0 to FFolders.Count - 1 do
        begin
          aFolder := AppendSlash(FFolders.ValueFromIndex[i] ) + '*.*';
          FSpecArgs.Add( aFolder );
        end;
    end;

  finally

  end;

end;

procedure TFrmMain.lblBtnStartClick(Sender: TObject);
var
i:Integer;
aExeName:String;
begin

  try
    aExeName := FIniFile.ReadString(SECTION_EXEFILE, 'File' , 'erp.exe' );
    FExeVersion := VersaoExe( aExeName );
    Mensagem( 'Versão do Sistema: '+ FExeVersion );
    Mensagem( 'Compactação Iniciada' );
    lblPb2.Text := 'Progresso total da compactação';
    rectStart.Enabled := False;
    rectExit.Enabled := false;
    FZipFile.FSpecArgs.Clear;
    LoadFiles;
    LoadFolders;
    LoadUploadFiles;
    AddFilesToZip();
    AddFoldersToZip();
    FZipFile.Add();
    Mensagem( 'Compactação Concluída' );
    pb1.Value := 0;
    pb2.Value := 0;
    lblPb2.Text := '';
    Mensagem( 'Enviando para o FTP' );
    pb1.Value := 0;
    pb2.Value := 0;
    lblPb1.Text := 'OK';
    lblPb1.Text := 'OK';

    EnviaFtp();
    Mensagem( 'Envio Concluído' );

  finally
    rectStart.Enabled := true;
    rectExit.Enabled := true;
  end;
end;

procedure TFrmMain.EnviaFtp;
var
aFtp:TIdFtp;
aHandler:TIDioHandlerStack;
aTam,
i:Integer;
aFileVersion,
aFile:String;
aVersionFile:TStringList;
begin
  try
    aFileVersion := FIniFile.ReadString(SECTION_VERSION_FILE, 'File' , '');

    aVersionFile := TStringList.Create;
    aVersionFile.Clear;
    aVersionFile.Add( FExeVersion );
    aVersionFile.SaveToFile(aFileVersion);
    aHandler := TIDioHandlerStack.Create(self);
    aFtp := TIdFtp.Create();
    aFtp.OnWork := FtpWork;
    aFtp.IoHandler := aHandler;
    aFtp.Host      := FIniFile.ReadString( SECTION_FTP, 'Host' , '' );
    aFtp.UserName  := FIniFile.ReadString( SECTION_FTP, 'User' , '' );;
    aFtp.Password  := FIniFile.ReadString( SECTION_FTP, 'Password' , '' );
    aFtp.Passive := false; { usa modo ativo }
    aFtp.IOHandler.RecvBufferSize := 8192;
    aFtp.TransferType := ftBinary;
    aFtp.Passive := true;
    aFtp.Connect();

    try

      begin
        for i := 0 to FUploadFiles.Count - 1 do
          begin
            aFile := FUploadFiles.ValueFromIndex[i];
            aTam :=  FileSize( aFile );
            if( aTam < 0 ) then aTam := 0;
            pb1.Max := aTam;
            lblMensagem.Text := 'Enviando arquivo ' + aFile;
            aFtp.Put (aFile, ExtractFileName( aFile), false);
          end;
      end;

    finally

    end;

    try
      aFtp.Delete( 'Aggille.zip' );
    except
      on e:Exception do
        Mensagem( 'Erro ao excluir arquivo do ftp ' + e.Message );
    end;
    aftp.Rename(ExtractFileName( FZipFileName ), 'Aggille.zip');

    aFtp.Disconnect();

  finally
    FreeAndNil( aFtp );
    FreeAndNil( aHandler );
    FreeAndNil( aVersionFile );
  end;
end;

function TFrmMain.FileSize(aFile: String): Integer;
begin
 with TFileStream.Create(aFile, fmOpenRead or fmShareExclusive) do
  try
    Result := Size;
  finally
   Free;
  end;
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin

  edtMessage.Lines.Clear;
  lblMensagem.Text := '';
  lblPb1.text := '';
  lblPb2.text := '';


  if( not FileExists( INI_NAME ) ) then
    raise Exception.Create('Arquivo de configuração inexistente');

  FIniFile := TIniFile.Create(ExtractFileDir(ParamStr(0))+'\'+INI_NAME);;

  FZipFileName := FIniFile.ReadString( SECTION_ZIPFILE, 'File', '' );

  if( not FileExists( FZipFileName ) ) then
    raise Exception.Create('Arquivo ZIP inexistente');

  FFiles := TSTringList.Create;
  FFolders := TStringList.Create;
  FUploadFiles := TStringList.Create;
  FZipFile := TZipMaster.Create( self );
  FZipFile.ZipFileName := FZipFileName;
  FZipFile.Active := True;
  FZipFile.OnMessage := ZipFileMessage;
  FZipFile.OnProgress := ZipFileProgress;
  FZipFile.OnTick := ZipFileTick;
  FZipFile.AddOptions := [AddRecurseDirs,AddDirNames];

end;

procedure TFrmMain.FtpWork(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
begin

   if( aWorkCount = 0 ) then exit;
   pb1.Value := aWorkCount ;
   lblPb1.Text:= FloatToStrF( aWorkcount / 1024, ffNumber, 10 , 0 )
                      + 'Kb de '
                      +  FloatToStrF( pb1.max / 1024 , ffNumber, 10 , 0 ) +  'Kb';
   pb1.Value := aWorkCount;
   application.ProcessMessages;

end;

procedure TFrmMain.LoadFiles;
begin
  FFiles.Clear;
  FIniFile.ReadSectionValues(SECTION_FILES, FFiles);
end;

procedure TFrmMain.LoadFolders;
begin
  FFolders.Clear;
  FIniFile.ReadSectionValues(SECTION_FOLDERS, FFolders );
end;


procedure TFrmMain.LoadUploadFiles;
begin
  FUploadFiles.Clear;
  FIniFile.ReadSectionValues(SECTION_UPLOAD_FILES, FUploadFiles );
end;

procedure TFrmMain.Mensagem(aMensagem: String);
begin
  edtMessage.Lines.Add( aMensagem );
  application.ProcessMessages();
end;

procedure TFrmMain.RectExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

function TFrmMain.VersaoExe(aExe: String): String;
type
PFFI = ^vs_FixedFileInfo;
var
F : PFFI;
Handle : Dword;
Len : Longint;
Data : Pchar;
Buffer : Pointer;
Tamanho : Dword;
Parquivo: Pchar;
Arquivo : String;
begin
  Arquivo := aExe;
  Parquivo := StrAlloc(Length(Arquivo) + 1);
  StrPcopy(Parquivo, Arquivo);
  Len := GetFileVersionInfoSize(Parquivo, Handle);
  Result := '';
  if Len > 0 then

  begin
    Data:=StrAlloc(Len+1);


    if GetFileVersionInfo(Parquivo,Handle,Len,Data) then
      begin
        VerQueryValue(Data, '\',Buffer,Tamanho);
        F := PFFI(Buffer);
        Result := Format('%d.%d.%d.%d',
        [HiWord(F^.dwFileVersionMs),
        LoWord(F^.dwFileVersionMs),
        HiWord(F^.dwFileVersionLs),
        Loword(F^.dwFileVersionLs)]
        );

      end;

    StrDispose(Data);
  end;

  StrDispose(Parquivo);

end;

procedure TFrmMain.ZipFileMessage(Sender: TObject; ErrCode: Integer;const Message: String);
begin
    lblMensagem.Text := message;
    Application.ProcessMessages();
    If (ErrCode > 0) And Not FZipFile.Unattended Then
      ShowMessage('Error Msg: ' + Message);

end;

procedure TFrmMain.ZipFileProgress(Sender: TObject;details: TZMProgressDetails);
begin
  Case details.Order Of
    TotalSize2Process:
      Begin
        //Mensagem( 'Tamanho Total: ' + IntToStr(details.TotalSize Div 1024) + ' Kb' );
        pb1.Value:= 1;
        pb1.Max := 100;
        pb2.Max := 100;
      End;
    TotalFiles2Process:
      Begin
        Mensagem( IntToStr(details.TotalCount) + ' arquivos selecionados' );
      End;
    NewFile:
      Begin
        //lblPb1.Text := 'Compactando ' + details.ItemName;
        //Mensagem( details.ItemName );
      End;
    ProgressUpdate:
      Begin
        pb1.Value := details.ItemPerCent;
        lblpb1.Text := Format( '%d%s' , [details.ItemPerCent, '%'] ) ;
        pb2.Value := details.TotalPerCent;
        lblPb2.Text := format( 'Arquivo %d de %d:(%d%s) concluído', [details.ItemNumber, details.TotalCount, details.TotalPerCent, '%'] ) ;
      End;
    EndOfBatch: // Reset the progress bar and filename.
      Begin
        pb1.Value := 1;
        pb2.Value := 1;
      End;
  End;

end;

procedure TFrmMain.ZipFileTick(Sender: TObject);
begin
  FNewCount := succ(FNewCount);
  if (FNewCount and 7) = 0 then
  begin
    FNewCount := FNewCount and 127;
    //lblSize.Text := 'Tamanho do Arquivo:' + IntToStr(FNewCount);
  end;
end;

end.
