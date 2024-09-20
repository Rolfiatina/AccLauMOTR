// �������� ������ �������� ��� �������� ������ ���������� ���� � ���������� ���� � ��
unit ALM_uMain;

interface

uses
  vcl.ExtCtrls,
  Vcl.Forms,
  vcl.menus,
  System.Classes,
  ALM_uTools,
  winapi.Windows,
  System.UITypes;

type
  TALM = class(TObject)
    // ������ � ��������� ����
    FTrayIcon: TTrayIcon;
    // ���������� ����
    FPopupMenu: TPopupMenu;
    // ������ ���������
    FAccountData: array of TAccountData;
    // ������� ������� ����
    FWorkStage: TWorkStage;
    // ������ ������
    FMasterPSW: string;
    // ������ ������� ����� ���������
    FHWNDArr: array of HWND;
    // ������ � ����� ������������� ����������
    FFavoriteAccounts: TList;
  private
    procedure TrayIconMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    // ����� ���� "�����"
    procedure MenuExit(Sender: TObject);
    // ����� ���� �������� ������
    procedure MenuPSWCreate(Sender: TObject);
    // ����� ���� ����� ������
    procedure MenuPSWEnter(Sender: TObject);
    // ����� ���� ������� ���������� ��������
    procedure MenuPSWAccounLaunch(Sender: TObject);
    // ����� ���� ����� ������ �������� ��������
    procedure MenuPSWAccountNew(Sender: TObject);
    // ����� ���� �������������� �������� ��������
    procedure MenuPSWAccountEdit(Sender: TObject);
    // ����� ���� �������� �������� ��������
    procedure MenuPSWAccountDelete(Sender: TObject);
    // ����� ���� "� ���������"
    procedure MenuAbout(Sender: TObject);
    // �������� �� ������� ����� � �����������
    function GetIsHaveFile: boolean;
    // �������� �� �������� ������ ������
    function GetIsPSWEntered: boolean;
    // ��������, �������� � ���������� ����� � �����������
    procedure DataFileBuild;
    // �������� ����� � ����������� � ��� �����������
    procedure DataFileload(aPSW: string);
    // ���������� ������ ���������
    procedure ProcessKill;
    // ������ �������� ���������
    procedure ProcessStart;
    // ����� ����������� �������� ���������
    procedure ProcessFind;
    // �������� �� ������� ������� ���� �������
    function ProcessCheck: boolean;
    // ������ ���������� ��������
    procedure ProcessLogin(aIndex: integer);
    // ���������� ������� �������
    procedure ProcessPrepare;
    // ���������� �������� � ����������������� ������
    procedure FavoriveAccountsAdd(aAccNum: integer);
    // �������� �������� �� ������ �����������������
    procedure FavoriveAccountsDelete(aAccNum: integer);
    // �������� �������������� ������
    function GetEncodePSW(aMasterPSW, aSol: string; aVersion: integer = 1): string;
  public
    // �������� �����
    procedure CheckStage;
  published
    constructor Create; overload; virtual;
    Destructor  Destroy; override;
    // ������
    procedure Start;
  public
    // �������� �� ������� ����� � �����������
    property IsHaveFile: boolean read GetIsHaveFile;
    // �������� �� �������� ������ ������
    property IsPSWEntered: boolean read GetIsPSWEntered;
  end;

implementation

{ TALM }
uses
  System.SysUtils,
  vcl.dialogs,
  System.hash,
  xml.XMLintf,
  xml.XMLDoc,
  Vcl.Controls,
  ShellApi,
  Messages,
  ALM_fEdit;

procedure TALM.DataFileBuild;
var
  eXMLDoc: IXMLDocument;
  eXMLNode: IXMLNode;
  i: integer;
  sXML: string;
  sHash: string;
  sData: string;
begin
  eXMLDoc := TXMLDocument.Create(nil);
  try
    eXMLDoc.Active := True;
    // �������� �����
    eXMLDoc.DocumentElement := eXMLDoc.CreateNode('DATA', ntElement, '');
    // ���������� �������� ACCOUNT � ���������� � �� ��������� ��������
    for i := low(FAccountData) to high(FAccountData) do
    begin
      eXMLNode := eXMLDoc.DocumentElement.AddChild('ACCOUNT', -1);
      eXMLNode.AddChild('S_MENUNAME').Text := FAccountData[i].sMenuName;
      eXMLNode.AddChild('S_LOGIN').Text := FAccountData[i].sLogin;
      eXMLNode.AddChild('S_PSW').Text := FAccountData[i].sPSW;
      eXMLNode.AddChild('S_NOTE').Text := FAccountData[i].sNote;
    end;

    sXML := '';
    // ���������� XML � ��������� ����������
    eXMLDoc.SaveToXML(sXML);
    // ������� MD5 �� ������ � XML
    sHash := THashMD5.GetHashString(sXML);
  finally
    if (assigned(eXMLDoc)) then
    begin
      //TXMLDocument(eXMLDoc).free;
    end;
  end;

  with TStringStream.Create do
  try
    Clear;
    // ������������ MD5 � XML ������ �������
    sData := Encode(sHash + sXML, FMasterPSW);
    // �������� ������ � �����
    WriteString(sData);
    // ��������� ����
    SaveToFile(GetDataFileName);
  finally
    free;
  end;
end;

procedure TALM.DataFileload(aPSW: string);
var
  sXML: string;
  eXMLDoc: IXMLDocument;
  eXMLNodeData: IXMLNode;
  eXMLNodeAccount: IXMLNode;
  eXMLNodeValue: IXMLNode;
  i, iIDX: integer;
  sDataEnc: string;
  bIsDecoded: boolean;
  bIsNeedReSave: boolean;

  function DecodeInner(aVersion: integer = 1): boolean;
  var
    sFull, sHash, sPSW: string;
  begin
    sXML := '';
    result := false;
    sPSW := GetEncodePSW(aPSW, cSKey, aVersion);
    // ����������� ������ �������
    sFull := Decode(sDataEnc, sPSW);
    // �������� MD5 �� ������
    sHash := Copy(sFull, 1, 32);
    Delete(sFull, 1, 32);
    if (sHash = THashMD5.GetHashString(sFull)) then
    begin
      sXML := sFull;
      result := true;
      // ��������� ������ �� ������ ����������� �������� ����������
      FMasterPSW := GetEncodePSW(aPSW, cSKey, cCountAlg);
      FWorkStage := wsWork;
    end;
  end;

begin
  bIsNeedReSave := false;
  SetLength(FAccountData, 0);
  with TStringStream.Create do
  try
    Clear;
    // �������� �� ����� � �����
    LoadFromFile(GetDataFileName);
    sDataEnc := ReadString(Size);
    for i := cCountAlg downto 1 do
    begin
      bIsDecoded := DecodeInner(i);
      if (bIsDecoded) then
      begin
        // ���� �� ��������� ������� ����������� �� ���� �������������
        bIsNeedReSave := (i <> cCountAlg);
        break;
      end;
    end;

    // ���� �� ������ ������������, ������ ���-�� �� ���
    if (not bIsDecoded) then
    begin
      raise exception.create(rsErrorWrongPassword);
    end;
  finally
    free;
  end;

  eXMLDoc := TXMLDocument.Create(nil);
  try
    eXMLDoc.Active := True;
    // ��������� XML
    eXMLDoc.LoadFromXML(sXML);
    eXMLNodeData := eXMLDoc.ChildNodes.FindNode('DATA');
    for I := 0 to eXMLNodeData.ChildNodes.Count - 1 do
    begin
      // ��������� ��� �������� �� ����� � ����������� � ��������� �� � ����
      eXMLNodeAccount := eXMLNodeData.ChildNodes.Nodes[i];
      SetLength(FAccountData, length(FAccountData) + 1);
      iIDX := high(FAccountData);
      // ������� ����� ��� ��������� ������
      Finalize(FAccountData[iIDX]);
      FillChar(FAccountData[iIDX], SizeOf(FAccountData[iIDX]), 0);
      with FAccountData[iIDX], eXMLNodeAccount do
      begin
        sMenuName := ChildNodes['S_MENUNAME'].text;
        sLogin    := ChildNodes['S_LOGIN'].text;
        sPSW      := ChildNodes['S_PSW'].text;
        sNote     := ChildNodes['S_NOTE'].text;
      end;
    end;

    // � ��� ���� ������� ������� ���������� �� ������������ � �����
    if (bIsNeedReSave) then
    begin
      DataFileBuild;
    end;

  finally
    if (assigned(eXMLDoc)) then
    begin
      //TXMLDocument(eXMLDoc).free;
    end;

  end;
end;

procedure TALM.CheckStage;
begin
  // ���� ����� �������� ������� ����� �� �������� ���� �� ��
  if (FWorkStage = wsNeedFile) then
  begin
    // ���� ���� ���� �� �������� ������� ������, ���� ����� ��� �� ������ ������
    if (IsHaveFile) then
    begin
      // ���� ������ ��� �� ������ ���� ���������� ����� ������, � ���� ���� �� ��������� ������
      if (FMasterPSW = '') then
      begin
        FWorkStage := wsNeedPSW;
      end else
      begin
        try
          DataFileload(FMasterPSW);
        except
          FMasterPSW := '';
          raise;
        end;
      end;
    end else
    begin
      FMasterPSW := '';
    end;
  end;
end;

constructor TALM.Create;
begin
  inherited Create;
  FTrayIcon := TTrayIcon.Create(Application);
  FTrayIcon.Visible := true;
  FPopupMenu := TPopupMenu.create(Application);
  FTrayIcon.OnMouseUp := TrayIconMouseUp;
  FFavoriteAccounts := TList.create;
  SetLength(FAccountData, 0);
end;

destructor TALM.Destroy;
begin
  SetLength(FAccountData, 0);
  if (assigned(FFavoriteAccounts)) then
  begin
    FFavoriteAccounts.free;
  end;
  if (assigned(FPopupMenu)) then
  begin
    FPopupMenu.free;
  end;
  FTrayIcon.Visible := false;
  if (assigned(FTrayIcon)) then
  begin
    FTrayIcon.free;
  end;
  inherited;
end;

procedure TALM.FavoriveAccountsAdd(aAccNum: integer);
var
  iIDX: integer;
begin
  iIDX := FFavoriteAccounts.IndexOf(pointer(aAccNum));
  // ���� ������� ��� � ��������� �� ������� ���
  if (iIDX <> -1) then
  begin
    FFavoriteAccounts.delete(iIDX);
  end;
  // �������� ������� � ������ ������
  FFavoriteAccounts.insert(0, pointer(aAccNum));
  // ���� ������� �� ������� ����������� ���������� ������ ��������� �� ������� ���������
  if (FFavoriteAccounts.Count > cFavoriveAccountsCountMax) then
  begin
    FFavoriteAccounts.delete(FFavoriteAccounts.Count - 1);
  end;
end;

procedure TALM.FavoriveAccountsDelete(aAccNum: integer);
var
  iIDX: integer;
  i: integer;
begin
  iIDX := FFavoriteAccounts.IndexOf(pointer(aAccNum));
  // ���� ��������� ������� � ������� �� ������
  if (iIDX <> -1) then
  begin
    FFavoriteAccounts.delete(iIDX);
  end;
  // ����� �������� �������� �� ��������� ������� �� ������ ��������� �� 1, ������� � ���
  for i := 0 to FFavoriteAccounts.Count - 1 do
  begin
    if (integer(FFavoriteAccounts[i]) > aAccNum) then
    begin
      FFavoriteAccounts[i] := pointer(integer(FFavoriteAccounts[i]) - 1);
    end;
  end;
end;

function TALM.GetEncodePSW(aMasterPSW, aSol: string; aVersion: integer = 1): string;
begin
  case aVersion of
    2: result := THashSHA2.GetHashString(aSol + aMasterPSW, SHA512);
  else
    result := aMasterPSW;
  end;

end;

function TALM.GetIsHaveFile: boolean;
begin
  result := FileExists(GetDataFileName);
end;

function TALM.GetIsPSWEntered: boolean;
begin
  result := FMasterPSW <> '';
end;

procedure TALM.MenuPSWAccounLaunch(Sender: TObject);
begin
  // ���������� � ���������
  FavoriveAccountsAdd(TMenuItem(Sender).Tag);
  // ������� �������� (�������� � ��������)
  ProcessKill;
  // ����� �������� ��������� � ������� ������� � ��
  ProcessFind;
  // ��������� ��������� �������
  ProcessLogin(TMenuItem(Sender).Tag);
end;

procedure TALM.MenuPSWAccountDelete(Sender: TObject);
var
  iIndex, i: integer;
begin
  iIndex := TMenuItem(Sender).Tag;
  if (MessageDlg(format(rsAskDeleteAccount, [FAccountData[i].sMenuName, FAccountData[i].sLogin]), mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
  begin
    FavoriveAccountsDelete(iIndex);
    // ������� ���� ������� ��������� �� 1 ������� ����
    for I := iIndex to High(FAccountData) - 1 do
    begin
      FAccountData[i] := FAccountData[i + 1];
    end;
    SetLength(FAccountData, High(FAccountData));
    // ����� ���������� �����
    DataFileBuild;
  end;
end;

procedure TALM.MenuPSWAccountEdit(Sender: TObject);
var
  iIndex: integer;
begin
  iIndex := TMenuItem(Sender).Tag;
  // ���� ��������������� ������� �� ��������� ����
  if (RecordEdit(FAccountData[iIndex])) then
  begin
    DataFileBuild;
  end;
end;

procedure TALM.MenuPSWAccountNew(Sender: TObject);
var
  eAccData: TAccountData;
begin
  finalize(eAccData);
  FillChar(eAccData, SizeOf(eAccData), 0);
  // ���� �������� ����� ������� �� ��������� ����
  if (RecordEdit(eAccData)) then
  begin
    SetLength(FAccountData, Length(FAccountData) + 1);
    FAccountData[high(FAccountData)] := eAccData;
    DataFileBuild;
  end;

end;

procedure TALM.MenuPSWCreate(Sender: TObject);
var
  sPSWNew, sPSWPrompt: string;
begin
  // ����������� ����� ������
  sPSWNew := InputBox(rsNewPSWRegister, #31 + rsNewPSW, '');
  if (sPSWNew = '') then
  begin
    raise exception.create(rsErrorNewPSWEmptyPSW);
  end;
  // ����������� ����� ������ ��������
  sPSWPrompt := InputBox(rsNewPSWRegister, #31 + rsNewPSWPrompt, '');
  // ���� ��� �� ��������� �� ������
  if (sPSWNew <> sPSWPrompt) then
  begin
    raise exception.create(rsErrorNewPSWNotEQ);
  end;
  // ���� �� ������ �� ������������� ������, ��������� ���� � ������ ����� ������
  FMasterPSW := sPSWNew;
  DataFileBuild;
  FWorkStage := wsWork;
  showmessage(rsNewPSWOK);
end;

procedure TALM.MenuPSWEnter(Sender: TObject);
var
  sPSW: string;
begin
  sPSW := InputBox(rsNewPSW, #31 + rsNewPSW, '');
  // ����������� ������ � �������� � ��� ��������� ������
  if (sPSW <> '') then
  begin
    DataFileload(sPSW);
  end;
end;

procedure TALM.ProcessFind;
var
  hMain: HWND;
  iCount: integer;

  procedure FindNextWnd(aHandle: HWND);
  var
    i: integer;
  Begin
    while (aHandle <> 0) do
    begin
      for i := low(FHWNDArr) to high(FHWNDArr) do
      begin
        if (FHWNDArr[i] = 0)
          and (cIDArr[i] = GetWindowLong(aHandle, GWL_ID))
        then
        begin
          FHWNDArr[i] := aHandle;
          break;
        end;
      end;
      FindNextWnd(GetWindow(aHandle, GW_CHILD));
      aHandle := GetNextWindow(aHandle, GW_HWNDNEXT);
    end;
  end;
begin
  // ������ �������� ���������
  ProcessStart;

  iCount := 0;
  repeat
    sleep(100);
    // ����� ������ ���� �� ����� � ���������� � 100 �� �� ���������� cProcCreateDelaySec ������
    hMain := FindWindow(nil, cWindowsName);
    inc(iCount);
  until (hMain <> 0)
     or (iCount * 100 > cProcCreateDelaySec * 1000);

  // ���� �� ����� ���� �� ������
  if (hMain = 0) then
  begin
    raise exception.Create(rsErrorLauCantFindWindows);
  end;

  iCount := 0;
  repeat
    sleep(100);
    // ���������� ������� ��� �������
    ProcessPrepare;
    // �������� ������� ������ ������
    FindNextWnd(GetWindow(hMain, GW_CHILD));
  until (ProcessCheck) // ��������� ��������� ������
     or (iCount * 100 > cProcFindHandleDelaySec * 1000);

  if (not ProcessCheck) then
  begin
    raise Exception.Create(rsErrorLauEmptyHandle);
  end;
end;

procedure TALM.ProcessKill;
var
  i: integer;
  sTMP: AnsiString;
begin
  // ��������� �� ������� ��������� ���������
  for i := low(cExeArr) to high(cExeArr) do
  begin
    sTMP := format('taskkill.exe /F /IM %S', [cExeArr[i]]);
    ExecCommand(sTMP, True);
    //winexec(@sTMP[1], SW_HIDE);
  end;
end;

procedure TALM.ProcessLogin(aIndex: integer);
begin
  // ���������� ��������� ���������
  SendMessage(FHWNDArr[0], WM_SETTEXT, length(FAccountData[aIndex].sLogin), cardinal(@FAccountData[aIndex].sLogin[1]));
  SendMessage(FHWNDArr[1], WM_SETTEXT, length(FAccountData[aIndex].sPSW), cardinal(@FAccountData[aIndex].sPSW[1]));
  SendMessage(FHWNDArr[2], BM_CLICK, 0, 0);

end;

procedure TALM.ProcessPrepare;
var
  i: integer;
begin
  SetLength(FHWNDArr, length(cIDArr));
  for I := Low(FHWNDArr) to High(FHWNDArr) do
  begin
    FillChar(FHWNDArr[i], SizeOf(FHWNDArr[i]), 0);
  end;
end;

function TALM.ProcessCheck: boolean;
var
  i: integer;
begin
  result := false;
  for I := Low(FHWNDArr) to High(FHWNDArr) do
  begin
    if (FHWNDArr[i] = 0) then
    begin
      exit;
    end;
  end;
  result := true;
end;

procedure TALM.ProcessStart;
begin
  ExecCommand(GetSelfDir + cExeArr[low(cExeArr)], False);
end;

procedure TALM.MenuAbout(Sender: TObject);
begin

  MessageBox(
    0,
    pchar(
        rsAboutBodyTarget + #13#10 + #13#10 +
        format(rsAboutBodyVersion, [ALM_uTools.GetFileVersion(application.ExeName)]) + #13#10 + #13#10 +
        rsAboutBodyDev + #13#10 +
        rsAboutBodyTG + #13#10 +
        rsAboutBodyGitHub),
    pchar(rsMenuNameAbout),
    MB_OK);
end;

procedure TALM.MenuExit(Sender: TObject);
begin
  application.Terminate;
end;

procedure TALM.Start;
begin
  FWorkStage := wsNeedFile;
  while True do
  begin
    sleep(50);
    application.ProcessMessages;
    if (application.Terminated) then
    begin
      break;
    end;
  end;
end;

procedure TALM.TrayIconMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i: integer;
  eMI, eMiSub: TMenuItem;
begin
  // ������ ���� �� ����� �� ������ � ����
  FPopupMenu.Items.Clear;
  AddMenuItem(FPopupMenu.Items, rsMenuNameAbout, MenuAbout);
  AddMenuDelim(FPopupMenu.Items);
  CheckStage;
  if (FWorkStage = wsNeedFile) then
  begin
    AddMenuItem(FPopupMenu.Items, rsMenuPSWNew, MenuPSWCreate);
  end;

  if (FWorkStage = wsNeedPSW) then
  begin
    AddMenuItem(FPopupMenu.Items, rsMenuPSWEnter, MenuPSWEnter);
  end;

  if (FWorkStage = wsWork) then
  begin

    // ���������� ������ ����� ������������ ���������
    if (length(FAccountData) > 0)
      and (FFavoriteAccounts.count > 0)
    then
    begin
      for i := 0 to FFavoriteAccounts.count - 1 do
      begin
        AddMenuItem(FPopupMenu.Items, FAccountData[integer(FFavoriteAccounts[i])].sMenuName, MenuPSWAccounLaunch, integer(FFavoriteAccounts[i]));
      end;
      AddMenuDelim(FPopupMenu.Items);
    end;

    // ���������� ���� ���������
    for i := low(FAccountData) to high(FAccountData) do
    begin
      AddMenuItem(FPopupMenu.Items, FAccountData[i].sMenuName, MenuPSWAccounLaunch, i);
    end;

    // ���������� ������ � ����������� ���������
    if (length(FAccountData) > 0) then
    begin
      AddMenuDelim(FPopupMenu.Items);
      eMI := AddMenuItem(FPopupMenu.Items, rsMenuNameSetup, nil);

      for i := low(FAccountData) to high(FAccountData) do
      begin
        eMiSub := AddMenuItem(eMI, FAccountData[i].sMenuName, nil);
        AddMenuInfo(eMiSub, FAccountData[i].sNote);
        AddMenuItem(eMiSub, rsMenuNameEdit, MenuPSWAccountEdit, i);
        AddMenuItem(eMiSub,rsMenuNameDelete, MenuPSWAccountDelete, i);
      end;
      AddMenuDelim(FPopupMenu.Items);
    end;

    // ���������� ������ ���������� ��������
    AddMenuItem(FPopupMenu.Items, rsMenuNameAccoundAdd, MenuPSWAccountNew);
  end;

  AddMenuDelim(FPopupMenu.Items);
  AddMenuItem(FPopupMenu.Items, rsMenuExit, MenuExit);
  FPopupMenu.Popup(X, Y);
end;

end.
