unit Aggille.Util.Zip;

interface

uses
System.Zip, System.Classes;

type
  IUtilZip = interface
    ['{32E75378-F934-4E83-B234-F70F854B1C34}']
    function AddFile( aValue:String ):IUtilZip;
    function AddFolder( aValue:String ):IUtilZip;
    function FileZipName( aValue:String ):IUtilZip;
    function Password( aValue:String ):IUtilZip;
    function Comment( aValue:String ):IUtilZip;
    function CreateZipFile:IUtilZip;
    function ExtractAll(aPath:String;aCreateSubDirs:boolean=true):IutilZip;
    function ExtractFile( aValue:String; aPath:String;aCreateSubDirs:boolean=true ):IUtilZip;
  end;

  TUtilZip = Class( TInterfacedObject,IUtilZip )
    private
      FFileNames,
      FFolderNames:TStringList;
      FPassword,
      FComment,
      FZipName:String;
      FZip:TZipFile;
      procedure AddFiles;
      procedure AddFolders;
      procedure OpenZipFile;
    public
      constructor create;
      destructor destroy;override;
      class function new:IUtilZip;
      function AddFile( aValue:String ):IUtilZip;
      function AddFolder( aValue:String ):IUtilZip;
      function FileZipName( aValue:String ):IUtilZip;
      function CreateZipFile:IUtilZip;
      function ExtractAll(aPath:String;aCreateSubDirs:boolean=true):IutilZip;
      function ExtractFile( aValue:String; aPath:String;aCreateSubDirs:boolean=true ):IUtilZip;
      function Password( aValue:String ):IUtilZip;
      function Comment( aValue:String ):IUtilZip;
  End;

implementation

uses
  System.SysUtils;

{ TUtilZip }

function TUtilZip.AddFile(aValue: String): IUtilZip;
begin
  result := self;
  FFileNames.Add( aValue );
end;

procedure TUtilZip.AddFiles;
var
aFile:STring;
begin
  for aFile in FFileNames do
    FZip.Add( aFile );
end;

function TUtilZip.AddFolder(aValue: String): IUtilZip;
begin
  result := self;
  FFolderNames.Add( aValue );
end;

procedure TUtilZip.AddFolders;
var
aFolder:String;
begin
  for aFolder in FFolderNames do
    FZip.ZipDirectoryContents ( FZipName,aFolder );
end;

function TUtilZip.Comment(aValue: String): IUtilZip;
begin
  result := self;
  FComment := aValue;
end;

constructor TUtilZip.create;
begin
  FFileNames    := TStringList.Create;
  FFolderNames  := TStringList.Create;
  FZip          := TZipFile.Create;
end;

function TUtilZip.CreateZipFile: IUtilZip;
begin

  result := self;

  try
    OPenZipFile();
    AddFiles;
    FZip.Close();
    AddFolders;
  finally
    Fzip.Close;
  end;
end;

destructor TUtilZip.destroy;
begin
  FFileNames.Free;
  FFolderNames.Free;
  FZip.Free;
  inherited;
end;


function TUtilZip.ExtractAll(aPath: String;aCreateSubDirs: boolean): IutilZip;
begin
  result := self;
  try
    //FZip.Open(FZipName, TZipMode.zmRead);
    OpenZipFile;
    FZip.ExtractAll( aPath );
  finally
    FZip.Close;
  end;
end;

function TUtilZip.ExtractFile(aValue, aPath: String;aCreateSubDirs: boolean): IUtilZip;
begin
  result := self;
  try
    //FZip.Open(FZipName, TZipMode.zmRead);
    OpenZipFile;
    FZip.Extract( aValue,aPath, aCreateSubDirs );
  finally
    FZip.Close;
  end;

end;

function TUtilZip.FileZipName(aValue: String): IUtilZip;
begin
  result := Self;
  FZipName := aValue;
end;

class function TUtilZip.new: IUtilZip;
begin
  result := self.Create;
end;


procedure TUtilZip.OpenZipFile;
begin
  if( FileExists( FZipName ) ) then
    FZip.Open(FZipName, TZipMode.zmReadWrite)
  else
    FZip.Open(FZipName, TZipMode.zmWrite);
end;

function TUtilZip.Password(aValue: String): IUtilZip;
begin
  result := self;
  FPassword := aValue;
end;

end.

