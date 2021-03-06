unit UMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
    System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
      Vcl.ExtCtrls, Vcl.Menus, System.DateUtils, System.IniFiles, Data.DB,
  Data.Win.ADODB, System.Win.Registry;

type
  TFMain = class(TForm)
    trayMain: TTrayIcon;
    pmTray: TPopupMenu;
    tmrMain: TTimer;
    pmiTraySettings: TMenuItem;
    pmiTrayClose: TMenuItem;
    pmiTrayStatistic: TMenuItem;
    dsStatistic: TDataSource;
    conStatistic: TADOConnection;
    qryStatistic: TADOQuery;
    qryStatisticS_ID: TAutoIncField;
    qryStatisticS_Title: TWideStringField;
    qryStatisticS_Time: TDateTimeField;
    qryStatisticS_StartDate: TDateTimeField;
    dtmfldStatisticS_StartTime: TDateTimeField;
    pmiTimerControl: TMenuItem;
    wdstrngfldStatisticS_UserName: TWideStringField;
    procedure FormCreate(Sender: TObject);
    procedure pmiTraySettingsClick(Sender: TObject);
    procedure pmiTrayCloseClick(Sender: TObject);
    procedure tmrMainTimer(Sender: TObject);
    procedure trayMainBalloonClick(Sender: TObject);
    procedure pmiTrayStatisticClick(Sender: TObject);
    procedure pmiTimerControlClick(Sender: TObject);
    procedure WMQueryEndSession(var Msg : TWMQueryEndSession);
                message WM_QueryEndSession;
    procedure Autorun(Flag:boolean; NameParam, Path:String);
    function ExtractFileNameEX(const AFileName:String): String;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FMain: TFMain;
type
  TWorkTime = record
    FTitle: string[255];
    FTime: TTime;
    FStartTime: TTime;
    FStartDate: TDate;
  end;

var
  ActiveHandle: THandle;
  AWorkTime: array of TWorkTime;
  intAmount: integer = 0;
  vCurrentTitle: string = '0';
  vPrevTitle: string = '1';
  WorkTime: TTime;
  WorkEnabled: Boolean = True;

implementation

uses USettings, UStatistic, USecurity;

{$R *.dfm}

// Name.txt --> Name
function TFMain.ExtractFileNameEX(const AFileName:String): String;
var
  i: integer;
begin
  i := Pos('.', AFileName);
  if i <> 0 then
    Result := ExtractFileName(Copy(AFileName,1,i-1))
  else
    Result := AFileName;
end;

// Operation when windows shutdown or restart.
procedure TFMain.WMQueryEndSession(var Msg : TWMQueryEndSession) ;
begin
   Msg.Result := 1 ;
   conStatistic.Connected := False;
end;

// Get current user name.
function GetUserFromWindows: string;
var
  UserName : string;
  UserNameLen : Dword;
begin
  UserNameLen := 255;
  SetLength(userName, UserNameLen);
  if GetUserName(PChar(UserName), UserNameLen) then
    Result := Copy(UserName,1,UserNameLen - 1)
  else
    Result := 'Unknown';
end;

//Get name of OS.
function WinInfo(Root_Key: HKEY; Key_Open, Key_Read: string): string;
var
  registry: TRegistry;
  WinVers: string;
begin
  WinVers := 'Software\Microsoft\Windows\CurrentVersion';
  if ((GetVersion and $80000000)=0) and (Key_Open=WinVers) then
    Key_Open:='SOFTWARE\Microsoft\Windows NT\CurrentVersion';
  Registry := TRegistry.Create;
  try
    Registry.RootKey := Root_Key;
    Registry.OpenKey(Key_Open, False);
    Result := Registry.ReadString(Key_Read);
  finally
    Registry.Free;
  end;
end;


// Enable/disable autorun;
procedure TFMain.Autorun(Flag:boolean; NameParam, Path:String);
var
  Reg:TRegistry;
  WinVers: string;
begin
  WinVers := 'Software\Microsoft\Windows\CurrentVersion';
  Reg := TRegistry.Create;
  try
    //if Pos('XP',WinInfo(HKEY_LOCAL_MACHINE,WinVers,'ProductName')) <> 0 then
      //Reg.RootKey := HKEY_CURRENT_USER
    //else
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    Reg.OpenKey('\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', false);
    if Flag then
      Reg.WriteString(NameParam, Path)
    else
      Reg.DeleteValue(NameParam);
  finally
    Reg.Free;
  end;
end;

procedure TFMain.FormCreate(Sender: TObject);
var
  vIniFile: TIniFile;
  vAutorunCheck: Boolean;
begin
  // Minimaize to tray.
  trayMain.Visible := True;

  // Set autorun if ini-file not exist or if checked in settings.
  vIniFile := TIniFile.Create(ExtractFilePath(ParamStr(0))+'Settings.ini');
  vAutorunCheck := vIniFile.ReadBool('Settings','Autorun',True);
  if vAutorunCheck then
    FSettings.Autorun(vAutorunCheck,'Canalis',Application.ExeName);
  vIniFile.Free;

  // Connect to DB.
  conStatistic.LoginPrompt := False;
  conStatistic.Connected := False;
  conStatistic.ConnectionString := 'Provider=Microsoft.Jet.OLEDB.4.0;' +
    'Data Source="' + ExtractFilePath(ParamStr(0)) + 'data\Database.db";' +
      'Persist Security Info=False; Jet OLEDB:Database Password="1"';
  conStatistic.Connected := True;

  qryStatistic.Active:=True;

  trayMain.PopupMenu := pmTray;

  SetLength(AWorkTime, 100);

  // Start work.
  tmrMain.Enabled := True;
end;

procedure TFMain.pmiTrayStatisticClick(Sender: TObject);
begin
  if USecurity.PasswordCheck then
  begin
    // Stop working whem Statistic showing.
    WorkEnabled := False;
    MessageBox(handle, PChar('����������� ������� �����.'+#13+
      '��������� ����-�����.'),PChar(''), MB_ICONWARNING+MB_OK);
    FStatistic.Show;
  end
  else
    MessageBox(handle, PChar('�������� ������ �����'),
      PChar('������� ������'), MB_ICONERROR+MB_OK);
end;

procedure TFMain.pmiTimerControlClick(Sender: TObject);
begin
  if USecurity.PasswordCheck then
  if pmiTimerControl.Tag = 0 then
  begin
    tmrMain.Enabled := False;
    pmiTimerControl.Caption := '��������';
    pmiTimerControl.Tag := 1;
  end
  else
  begin
    tmrMain.Enabled := True;
    pmiTimerControl.Caption := '���������';
    pmiTimerControl.Tag := 0;
  end;
end;

procedure TFMain.pmiTrayCloseClick(Sender: TObject);
begin
  if USecurity.PasswordCheck then
  begin
    FMain.Close;
  end
  else
    MessageBox(handle, PChar(''),PChar('������� ������'), MB_ICONERROR+MB_OK);
end;

procedure TFMain.pmiTraySettingsClick(Sender: TObject);
begin
  if USecurity.PasswordCheck then
  begin
    FSettings.Show;
  end
  else
    MessageBox(handle, PChar('�������� ������ �����'),
      PChar('������� ������'), MB_ICONERROR+MB_OK);
end;

// Get title of active window.
function GetHandleCaption: string;
var
  vHandle: THandle;
  vLen: LongInt;
  vTitle: string;
begin
  vHandle := GetForegroundWindow;
  if vHandle <> 0 then
  begin
    vLen := GetWindowTextLength(vHandle) + 1;
    SetLength(vTitle, vLen);
    GetWindowText(vHandle, PChar(vTitle), vLen);
    if Length(vTitle) >= 255 then
      vTitle := Copy(vTitle, 0, 254);
    Result := vTitle;
  end
  else
    Result := '';
end;

// Delete symbols to avoid SQL errors.
function SpecSymbolsDelete(s: string):string;
begin
  Result := s;
  if (Pos('[',Result) <> 0) then
    Result := StringReplace(Result, '[',' ', [rfReplaceAll]);
  if (Pos(']',Result) <> 0) then
    Result := StringReplace(Result, ']', ' ', [rfReplaceAll]);
  if (Pos('?',Result) <> 0) then
    Result := StringReplace(Result, '?', ' ', [rfReplaceAll]);
end;

procedure TFMain.tmrMainTimer(Sender: TObject);
begin
  vCurrentTitle := GetHandleCaption;
  // Work if Statistic closed.
  if WorkEnabled then
  begin
    // Add new entry only if previous title not the same as current.
    if (vCurrentTitle <> vPrevTitle) and (vCurrentTitle <> '') then
    begin
      vPrevTitle := vCurrentTitle;
      WorkTime := StrToTime('0:00:01');

      qryStatistic.Insert;
      qryStatistic.FieldByName('S_Title').AsString := SpecSymbolsDelete(vCurrentTitle);
      qryStatistic.FieldByName('S_StartTime').AsDateTime := TimeOf(System.SysUtils.Time);
      qryStatistic.FieldByName('S_StartDate').AsDateTime := System.SysUtils.Now;;
      qryStatistic.FieldByName('S_Time').AsString := TimeToStr(WorkTime);
      qryStatistic.FieldByName('S_UserName').AsString := GetUserFromWindows();
      qryStatistic.Post;
      qryStatistic.Edit;
    end;
    WorkTime := IncSecond(WorkTime, 1);
    qryStatistic.FieldByName('S_Time').AsString :=  TimeToStr(WorkTime);
  end;
end;

procedure TFMain.trayMainBalloonClick(Sender: TObject);
begin
  pmiTraySettings.Click;
end;

end.
