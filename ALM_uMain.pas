// Основной модуль прогрммы для создании иконки системного трея и размещения меню в нём
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
    // Иконка в системном трее
    FTrayIcon: TTrayIcon;
    // Выпадающее меню
    FPopupMenu: TPopupMenu;
    // Массив аккаунтов
    FAccountData: array of TAccountData;
    // Текущий рабочий этап
    FWorkStage: TWorkStage;
    // Мастер пароль
    FMasterPSW: string;
    // Массив хэндлов формы апдейтера
    FHWNDArr: array of HWND;
    // Массив с часто используемыми аккаунтами
    FFavoriteAccounts: TList;
  private
    procedure TrayIconMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    // Пункт меню "Выход"
    procedure MenuExit(Sender: TObject);
    // Пункт меню создания пароля
    procedure MenuPSWCreate(Sender: TObject);
    // Пункт меню ввода пароля
    procedure MenuPSWEnter(Sender: TObject);
    // Пункт меню запуска выбранного аккаунта
    procedure MenuPSWAccounLaunch(Sender: TObject);
    // Пункт меню ввода нового игрового аккаунта
    procedure MenuPSWAccountNew(Sender: TObject);
    // Пункт меню редактирования игрового аккаунта
    procedure MenuPSWAccountEdit(Sender: TObject);
    // Пункт меню удаления игрового аккаунта
    procedure MenuPSWAccountDelete(Sender: TObject);
    // Пункт меню "О программе"
    procedure MenuAbout(Sender: TObject);
    // Проверка на наличие файла с настройками
    function GetIsHaveFile: boolean;
    // Проверка на введённый мастер пароль
    function GetIsPSWEntered: boolean;
    // Создание, нифровка и сохранение файла с настройками
    procedure DataFileBuild;
    // Загрузка файла с настройками и его расшифровка
    procedure DataFileload(aPSW: string);
    // Прибивание лишних процессов
    procedure ProcessKill;
    // Запуск процесса апдейтера
    procedure ProcessStart;
    // Поиск запущенного процесса апдейтера
    procedure ProcessFind;
    // Проверка на предмет наличия всех хендлов
    function ProcessCheck: boolean;
    // Запуск выбранного аккаунта
    procedure ProcessLogin(aIndex: integer);
    // Подготовка массива хэндлов
    procedure ProcessPrepare;
    // Добавление аккаунта в частоиспользуемый список
    procedure FavoriveAccountsAdd(aAccNum: integer);
    // Удаление аккаунта из списка частоиспользуемых
    procedure FavoriveAccountsDelete(aAccNum: integer);
    // Получить закодированный пароль
    function GetEncodePSW(aMasterPSW, aSol: string; aVersion: integer = 1): string;
  public
    // Проверка этапа
    procedure CheckStage;
  published
    constructor Create; overload; virtual;
    Destructor  Destroy; override;
    // Запуск
    procedure Start;
  public
    // Проверка на наличие файла с настройками
    property IsHaveFile: boolean read GetIsHaveFile;
    // Проверка на введённый мастер пароль
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
    // Создание корня
    eXMLDoc.DocumentElement := eXMLDoc.CreateNode('DATA', ntElement, '');
    // Добавление элемента ACCOUNT и наполнение в нём структуру аккаунта
    for i := low(FAccountData) to high(FAccountData) do
    begin
      eXMLNode := eXMLDoc.DocumentElement.AddChild('ACCOUNT', -1);
      eXMLNode.AddChild('S_MENUNAME').Text := FAccountData[i].sMenuName;
      eXMLNode.AddChild('S_LOGIN').Text := FAccountData[i].sLogin;
      eXMLNode.AddChild('S_PSW').Text := FAccountData[i].sPSW;
      eXMLNode.AddChild('S_NOTE').Text := FAccountData[i].sNote;
    end;

    sXML := '';
    // Сохранение XML в строковую переменную
    eXMLDoc.SaveToXML(sXML);
    // Извлечь MD5 из строки с XML
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
    // Закодировать MD5 и XML мастер паролем
    sData := Encode(sHash + sXML, FMasterPSW);
    // Записать данные в поток
    WriteString(sData);
    // Сохранить файл
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
    // Расшифровка мастер паролем
    sFull := Decode(sDataEnc, sPSW);
    // Отделяем MD5 из строки
    sHash := Copy(sFull, 1, 32);
    Delete(sFull, 1, 32);
    if (sHash = THashMD5.GetHashString(sFull)) then
    begin
      sXML := sFull;
      result := true;
      // Сохраняем пароль по самому актуальному варианту шифрования
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
    // Загрузка из файла в поток
    LoadFromFile(GetDataFileName);
    sDataEnc := ReadString(Size);
    for i := cCountAlg downto 1 do
    begin
      bIsDecoded := DecodeInner(i);
      if (bIsDecoded) then
      begin
        // Если не последний вариант кодирования то надо пересохранить
        bIsNeedReSave := (i <> cCountAlg);
        break;
      end;
    end;

    // Если не смогли расшифровать, значит что-то не так
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
    // Загружаем XML
    eXMLDoc.LoadFromXML(sXML);
    eXMLNodeData := eXMLDoc.ChildNodes.FindNode('DATA');
    for I := 0 to eXMLNodeData.ChildNodes.Count - 1 do
    begin
      // Извлекаем все аккаунты из файла с настройками и сохраняем их к себе
      eXMLNodeAccount := eXMLNodeData.ChildNodes.Nodes[i];
      SetLength(FAccountData, length(FAccountData) + 1);
      iIDX := high(FAccountData);
      // Очистка строк для избежания утечек
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

    // У нас файл старого образца шифрования то пересохраним с новым
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
  // Если режим проверки наличия файла то проверим есть ли он
  if (FWorkStage = wsNeedFile) then
  begin
    // Если файл есть то проверим наличие пароля, если файла нет то чистим пароль
    if (IsHaveFile) then
    begin
      // Если пароля нет то ставим этап требования ввода пароля, а если есть то загружаем данные
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
  // Если аккаунт уже в избранном то удаляем его
  if (iIDX <> -1) then
  begin
    FFavoriteAccounts.delete(iIDX);
  end;
  // Добавлем аккаунт в начало списка
  FFavoriteAccounts.insert(0, pointer(aAccNum));
  // Если вылезли за границы максимально возможного списка избранных то удаляем последний
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
  // Ищем удаляемый аккаунт и удаляем из списка
  if (iIDX <> -1) then
  begin
    FFavoriteAccounts.delete(iIDX);
  end;
  // После удаления аккаунта из основного массива их номера смещаются на 1, смещаем и тут
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
  // Добавление в избранное
  FavoriveAccountsAdd(TMenuItem(Sender).Tag);
  // Убиваем процессы (апдейтер и рагнарок)
  ProcessKill;
  // Поиск процесса апдейтера с поиском хэндлов в нём
  ProcessFind;
  // Запускаем выбранный аккаунт
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
    // Перенос всех старших уккаунтов на 1 позицию вниз
    for I := iIndex to High(FAccountData) - 1 do
    begin
      FAccountData[i] := FAccountData[i + 1];
    end;
    SetLength(FAccountData, High(FAccountData));
    // Вызов сохранения фойла
    DataFileBuild;
  end;
end;

procedure TALM.MenuPSWAccountEdit(Sender: TObject);
var
  iIndex: integer;
begin
  iIndex := TMenuItem(Sender).Tag;
  // Если отредактировали аккаунт то сохраняем файл
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
  // Если добавили новый аккаунт то сохланяем файл
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
  // Запрашиваем новый пароль
  sPSWNew := InputBox(rsNewPSWRegister, #31 + rsNewPSW, '');
  if (sPSWNew = '') then
  begin
    raise exception.create(rsErrorNewPSWEmptyPSW);
  end;
  // Запрашиваем новый пароль повторно
  sPSWPrompt := InputBox(rsNewPSWRegister, #31 + rsNewPSWPrompt, '');
  // Если они не совпадают то ошибка
  if (sPSWNew <> sPSWPrompt) then
  begin
    raise exception.create(rsErrorNewPSWNotEQ);
  end;
  // Если всё хорошо то устанавливаем пароль, сохраняем файл и меняем режим работы
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
  // Запрашиваем пароль и пытаемся с ним загрузить данные
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
  // Запуск процесса апдейтера
  ProcessStart;

  iCount := 0;
  repeat
    sleep(100);
    // Поиск хэндла окна по имени с интервалом в 100 мс на протяжении cProcCreateDelaySec секунд
    hMain := FindWindow(nil, cWindowsName);
    inc(iCount);
  until (hMain <> 0)
     or (iCount * 100 > cProcCreateDelaySec * 1000);

  // Если не нашли окно то ошибка
  if (hMain = 0) then
  begin
    raise exception.Create(rsErrorLauCantFindWindows);
  end;

  iCount := 0;
  repeat
    sleep(100);
    // Подготовка массива для хэндлов
    ProcessPrepare;
    // Пытаемся извлечь нужные хэндлы
    FindNextWnd(GetWindow(hMain, GW_CHILD));
  until (ProcessCheck) // Проверяем найденный хэндлы
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
  // Прибиваем по массиву процессов требуемое
  for i := low(cExeArr) to high(cExeArr) do
  begin
    sTMP := format('taskkill.exe /F /IM %S', [cExeArr[i]]);
    ExecCommand(sTMP, True);
    //winexec(@sTMP[1], SW_HIDE);
  end;
end;

procedure TALM.ProcessLogin(aIndex: integer);
begin
  // Отправляем сообщения апдейтеру
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
  // Рисуем меню по клику на иконке в трее
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

    // Добавление списка часто используемых аккаунтов
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

    // Добавление всех аккаунтов
    for i := low(FAccountData) to high(FAccountData) do
    begin
      AddMenuItem(FPopupMenu.Items, FAccountData[i].sMenuName, MenuPSWAccounLaunch, i);
    end;

    // Добавления пункта с настройками аккаунтов
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

    // Добавление кнопки добавления аккаунта
    AddMenuItem(FPopupMenu.Items, rsMenuNameAccoundAdd, MenuPSWAccountNew);
  end;

  AddMenuDelim(FPopupMenu.Items);
  AddMenuItem(FPopupMenu.Items, rsMenuExit, MenuExit);
  FPopupMenu.Popup(X, Y);
end;

end.
