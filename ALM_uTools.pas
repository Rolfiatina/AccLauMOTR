// ��������������� ������
unit ALM_uTools;

interface

uses
  vcl.menus,
  system.Classes;

resourcestring
  rsNewPSWRegister = '���� ������ ������';
  rsNewPSW = '������� ������ ������';
  rsNewPSWPrompt = '����������� ������ ������';
  rsNewPSWOK = '����� ������ ������� ����������';
  rsErrorNewPSWEmptyPSW = '������ ������ ����������';
  rsErrorNewPSWNotEQ = '������ �� ���������';
  rsErrorWrongPassword = '�������� ������';
  rsMenuPSWNew = '������ ������ ������';
  rsMenuPSWEnter = '������ ������ ������';
  rsMenuExit = '�����';
  rsErrorLauCantFindWindows = '���� � ��������� �� �������';
  rsErrorLauEmptyHandle = '�� ��� ������ �������';
  rsErrorLauCantStartProcess = '������ ������� ��������. ��� ������ %D.';
  rsMenuNameSetup = '��������� ���������:';
  rsMenuNameAccoundAdd = '�������� ������� �������';
  rsMenuNameEdit = '�������������';
  rsMenuNameDelete = '�������';
  rsMenuNameAbout = 'Account Launcher MOTR (� ���������)';
  rsEditFormErrorCaption = '��� ���������� ���������� ��������� ������:'#13#10;
  rsEditFormErrorCheckStringVal = '- �������� ���� "%S" �� ������ ���� ������;'#13#10;
  rsAskDeleteAccount = '������������� ������� "%S" (%S)?';
  rsAboutCaption = '� ���������';
  rsAboutBodyDev = '�����������: Rolfiatina';
  rsAboutBodyTarget = '����������: ����������� �������� ����� � ����'#13#10'�� ����������� ����� ��������';
  rsAboutBodyVersion = 'Version: %S ��� 2024';
  rsAboutBodyTG = 'Telegram: t.me/rolfiatina';
  rsAboutBodyGitHub = 'GitHub: github.com/rolfiatina';

const
  // ������ ������ ������� ������� ������ � �������. ����� ����� �
  // ������ ��������� ��� �������
  cExeArr: array [0..1] of String = ('updater.exe', 'ragexea.exe');
  cIDEditLogin = 1045; // ��� ���������� ��� ����� ������ �� ����� ���������
  cIDEditPSW = 1046; // ��� ���������� ��� ����� ������ �� ����� ���������
  cIDButtonLaunch = 1; //��� ������ ��� ����� � ���� �� ����� ���������
  // ������ ������� ����������� �� ����� ���������
  cIDArr: array [0..2] of integer = (cIDEditLogin, cIDEditPSW, cIDButtonLaunch);
  // ������������ ���� ��������� ��� ������ ���� �� ��� ���������
  cWindowsName = 'MOTR Updater';
  // �������� ��� �������� ��������� ������������ ��������� ���������
  cProcCreateDelaySec = 5;
  // �������� ��� �������� �������� ���� �������� ����������
  cProcFindHandleDelaySec = 10;
  // ������������ ���������� ������ ����� ������������ ���������
  cFavoriveAccountsCountMax = 7;
  // ����� ����� ��� ����������
  cSKey = '10995ffce16d34539b629267a779e57b';
  // ���������� ��������� �������� �� ����������
  cCountAlg = 2;
type
  // ������ ��������� ���������: ��������� ���� � �����������, ��������� ���� ������, �������� ����� ������
  TWorkStage = (wsNeedFile, wsNeedPSW, wsWork);

type
  // ��������� ��������
  TAccountData = record
    sMenuName: string;
    sLogin: string;
    sPSW: string;
    sNote: string;
  end;

// ���������� �������� ������ ���� ����������� ������
function AddMenuItem(aMItem: TMenuItem; aTitle: String; aEvent: TNotifyEvent; aTag: integer = 0; aHint: string = ''): TMenuItem;
// ���������� ����������� ����� �������� ����
procedure AddMenuDelim(aMItem: TMenuItem);
// ���������� ����� ���� � ��������� ��������
procedure AddMenuInfo(aMItem: TMenuItem; aTitle: String);
// �������� ��� ����� � �����������
function GetDataFileName: string;
// �������� ������ �����
function GetFileVersion(aFileName: string): String;
// �������� ������� ������� �� �������� ��������� ���������
function GetSelfDir: string;
// ����������� ������ ������ �������
function Encode(aSource, aKey: AnsiString): AnsiString;
// ������������ ������ ������ �������
function Decode(aSource, aKey: AnsiString): AnsiString;
// ��������� ������ ������� ��� ����������
function ExecCommand(aCommandLine: string; aIsWaitEnd: boolean): boolean;

implementation

uses
  xml.XMLintf,
  xml.XMLDoc,
  vcl.Dialogs,
  system.SysUtils,
  vcl.Forms,
  winapi.Windows;

function AddMenuItem(aMItem: TMenuItem; aTitle: String; aEvent: TNotifyEvent; aTag: integer = 0; aHint: string = ''): TMenuItem;
begin
  Result := TMenuItem.Create(aMItem);
  with Result do
  try
    aMItem.Add(Result);
    Caption := aTitle;
    OnClick := aEvent;
    Tag     := aTag;
    Hint    := aHint;
  except
    Free;
    raise;
  end;
end;

procedure AddMenuDelim(aMItem: TMenuItem);
var
  eMI: TMenuItem;
begin
  eMI := TMenuItem.Create(aMItem);
  with eMI do
  try
    aMItem.add(eMI);
    Caption := '-';
  except
    free;
    raise;
  end;
end;

procedure AddMenuInfo(aMItem: TMenuItem; aTitle: String);
var
  eMI: TMenuItem;
begin
  eMI := TMenuItem.Create(aMItem);
  with eMI do
  try
    aMItem.add(eMI);
    Caption := aTitle;
    Enabled := false;
  except
    free;
    raise;
  end;
end;

function GetDataFileName: string;
begin
  result := ChangeFileExt(ExtractFileName(Application.ExeName), '.dat');
end;

function GetSelfDir: string;
begin
  result := ExtractFilePath(Application.ExeName);
end;

function GetFileVersion(aFilename: string): string;
var
  iNum, iLen: DWORD;
  sBuf: PChar;
  sValue: PChar;
begin
  Result := '';
  iNum := GetFileVersionInfoSize(PChar(aFilename), iNum);
  if (iNum > 0) then
  begin
    sBuf := AllocMem(iNum);
    try
      GetFileVersionInfo(PChar(aFilename), 0, iNum, sBuf);
      // ������� ������
      if (VerQueryValue(sBuf,
           pchar('StringFileInfo\040904E4\FileVersion'),
           Pointer(sValue),
           iLen))
      then
      begin
        Result := sValue;
      end;
    finally
      FreeMem(sBuf, iNum);
    end;
  end;
end;

function Encode(aSource, aKey: AnsiString): AnsiString;
var
  i: Integer;
  s: Byte;
begin
  Result := '';
  for i := 1 to Length(aSource) do
  begin
    if Length(aKey) > 0 then
    begin
      s := Byte(aKey[1 + ((i - 1) mod Length(aKey))]) xor Byte(aSource[i]);
    end else
    begin
      s := Byte(aSource[i]);
    end;
    Result := Result + AnsiLowerCase(IntToHex(s, 2));
  end;
end;

function Decode(aSource, aKey: AnsiString): AnsiString;
var
  i: Integer;
  s: AnsiChar;
begin
  Result := '';
  for i := 0 to Length(aSource) div 2 - 1 do
  begin
    s := AnsiChar(StrToIntDef('$' + Copy(aSource, (i * 2) + 1, 2), Ord(' ')));
    if Length(aKey) > 0 then
    begin
      s := AnsiChar(Byte(aKey[1 + (i mod Length(aKey))]) xor Byte(s));
    end;
    Result := Result + s;
  end;
end;

function ExecCommand(aCommandLine: string; aIsWaitEnd: boolean): boolean;
var
  vStartUpInfo: TStartupInfo;
  vProcessInfo: TProcessInformation;
begin
  result := false;
  FillChar(vStartupInfo, SizeOf(vStartupInfo), 0);
  FillChar(vProcessInfo, SizeOf(vProcessInfo), 0);
  vStartupInfo.wShowWindow := SW_SHOWMINIMIZED;
  if (aIsWaitEnd) then
  begin
    vStartupInfo.wShowWindow := SW_HIDE;
    vStartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  end;

  if (CreateProcess(nil, PChar(aCommandLine), nil, nil, False,
        CREATE_NEW_CONSOLE {0}, nil, nil, vStartupInfo, vProcessInfo))
  then
  begin
    if (aIsWaitEnd) then
    begin
      while WaitForSingleObject(vProcessInfo.hProcess, 10) > 0 do
      begin
        Application.ProcessMessages;
      end;
      CloseHandle(vProcessInfo.hProcess);
      CloseHandle(vProcessInfo.hThread);
    end;
  end;
  result := true;
end;

end.
