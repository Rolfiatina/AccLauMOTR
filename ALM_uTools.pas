// Вспомогательный модуль
unit ALM_uTools;

interface

uses
  vcl.menus,
  system.Classes;

resourcestring
  rsNewPSWRegister = 'Ввод нового пароля';
  rsNewPSW = 'Введите мастер пароль';
  rsNewPSWPrompt = 'Подтвердите мастер пароль';
  rsNewPSWOK = 'Новый пароль успешно установлен';
  rsErrorNewPSWEmptyPSW = 'Пустой пароль недопустим';
  rsErrorNewPSWNotEQ = 'Пароли не совпадают';
  rsErrorWrongPassword = 'Неверный пароль';
  rsMenuPSWNew = 'Задать мастер пароль';
  rsMenuPSWEnter = 'Ввести мастер пароль';
  rsMenuExit = 'Выход';
  rsErrorLauCantFindWindows = 'Окно с лаунчером не найдено';
  rsErrorLauEmptyHandle = 'Не все хэндлы найдены';
  rsErrorLauCantStartProcess = 'Ошибка запуска процесса. Код ошибки %D.';
  rsMenuNameSetup = 'Настройка аккаунтов:';
  rsMenuNameAccoundAdd = 'Добавить игровой аккаунт';
  rsMenuNameEdit = 'Редактировать';
  rsMenuNameDelete = 'Удалить';
  rsMenuNameAbout = 'Account Launcher MOTR (О программе)';
  rsEditFormErrorCaption = 'При сохранении обнаружены следующие ошибки:'#13#10;
  rsEditFormErrorCheckStringVal = '- значение поля "%S" не должно быть пустым;'#13#10;
  rsAskDeleteAccount = 'Действительно удалить "%S" (%S)?';
  rsAboutCaption = 'О программе';
  rsAboutBodyDev = 'Разработчик: Rolfiatina';
  rsAboutBodyTarget = 'Назначение: Возможность быстрого входа в игру'#13#10'по сохранённому ранее аккаунту';
  rsAboutBodyVersion = 'Version: %S год 2024';
  rsAboutBodyTG = 'Telegram: t.me/rolfiatina';
  rsAboutBodyGitHub = 'GitHub: github.com/rolfiatina';

const
  // Массив файлов которые следует искать и убивать. Также певый в
  // списке требуется для запуска
  cExeArr: array [0..1] of String = ('updater.exe', 'ragexea.exe');
  cIDEditLogin = 1045; // Код компонента для ввода логина на форме апдейтера
  cIDEditPSW = 1046; // Код компонента для ввода пароля на форме апдейтера
  cIDButtonLaunch = 1; //Код кнопки для входа в игру на форме апдейтера
  // Массив айдишек компонентов на форме апдейтера
  cIDArr: array [0..2] of integer = (cIDEditLogin, cIDEditPSW, cIDButtonLaunch);
  // Наименование окна апдейтера для поиска окна по его заголовку
  cWindowsName = 'MOTR Updater';
  // Задержка для ожидания появления запускаемого экзешника апдейтера
  cProcCreateDelaySec = 5;
  // Задержка для ожидания создания всех объектов приложения
  cProcFindHandleDelaySec = 10;
  // Максимальное количество списка часто используемых аккаунтов
  cFavoriveAccountsCountMax = 7;
  // Часть ключа для шифрования
  cSKey = '10995ffce16d34539b629267a779e57b';
  // Количиство возможных подходов по шифрованию
  cCountAlg = 2;
type
  // Массив состояний программы: Требуется файл с настройками, требуется ввод пароля, основной режим работы
  TWorkStage = (wsNeedFile, wsNeedPSW, wsWork);

type
  // Структура аккаунта
  TAccountData = record
    sMenuName: string;
    sLogin: string;
    sPSW: string;
    sNote: string;
  end;

// Добавление обычного пункта меню выпадающего списка
function AddMenuItem(aMItem: TMenuItem; aTitle: String; aEvent: TNotifyEvent; aTag: integer = 0; aHint: string = ''): TMenuItem;
// Добавление разделителя между пунктами меню
procedure AddMenuDelim(aMItem: TMenuItem);
// Добавления пунта меню с описанием аккаунта
procedure AddMenuInfo(aMItem: TMenuItem; aTitle: String);
// Получить имя файла с настройками
function GetDataFileName: string;
// Получить версию файла
function GetFileVersion(aFileName: string): String;
// Получить рабочий каталог из которого запущенна программа
function GetSelfDir: string;
// Зашифровать строку мастер паролем
function Encode(aSource, aKey: AnsiString): AnsiString;
// Расшифровать строку мастер паролем
function Decode(aSource, aKey: AnsiString): AnsiString;
// Выполнить запуск команды или приложения
function ExecCommand(aCommandLine: string; aIsWaitEnd: boolean): boolean;
// Сортировка пунктов меню
procedure SortMenuItem(aMenuItems: TMenuItem; aStartPos: Integer = 0; aEndPos: Integer = 0);

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
      // Извлечь версию
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

procedure SortMenuItem(aMenuItems: TMenuItem; aStartPos: Integer = 0; aEndPos: Integer = 0);
var
  i: Integer;
  sl: TStringList;
begin
  if (not Assigned(aMenuItems)) then Exit;
  // Если не указали по какую позицию сортировать, то сортируем до конца
  if (aEndPos = 0) then
  begin
    aEndPos := aMenuItems.Count - 1;
  end;
  if (aStartPos >= aEndPos) then Exit;
  sl := TStringList.Create;
  try
    sl.Sorted := true;
    // Добавляем пункты меню в StringList с сортировкой
    for i := aStartPos to aEndPos do
    begin
      sl.AddObject(aMenuItems[i].Caption, aMenuItems[i]);
    end;

    // Переназначаем порядок в зависимости от сорртировки
    for i := 0 to sl.Count - 1 do
    begin
      TMenuItem(sl.Objects[i]).MenuIndex := i + aStartPos;
    end;
  finally
    if (assigned(sl)) then
    begin
      sl.Free;
    end;
  end;
end;

end.
