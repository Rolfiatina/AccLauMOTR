// Модуль добавления\редактирования аккаунта
unit ALM_fEdit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, ALM_uTools,
  Vcl.Menus;

type
  TfEdit = class(TForm)
    pButton: TPanel;
    pMain: TPanel;
    bOK: TButton;
    bX: TButton;
    lbMenuName: TLabel;
    lbLogin: TLabel;
    lbPSW: TLabel;
    lbNote: TLabel;
    ePSW: TEdit;
    eLogin: TEdit;
    eMenuName: TEdit;
    eNote: TEdit;
    procedure bOKClick(Sender: TObject);
    procedure eLoginExit(Sender: TObject);
  private
    function GetLogin: string;
    function GetMenuName: string;
    function GetNote: string;
    function GetPSW: string;
    procedure SetLogin(const Value: string);
    procedure SetMenuName(const Value: string);
    procedure SetNote(const Value: string);
    procedure SetPSW(const Value: string);
    { Private declarations }
  public
    { Public declarations }
    property Login: string read GetLogin write SetLogin;
    property PSW: string read GetPSW write SetPSW;
    property MenuName: string read GetMenuName write SetMenuName;
    property Note: string read GetNote write SetNote;
  end;

var
  fEdit: TfEdit;

function RecordEdit(var aData: TAccountData): boolean;

implementation

{$R *.dfm}

function RecordEdit(var aData: TAccountData): boolean;
begin
  result := false;
  with TfEdit.create(application) do
  try
    login := aData.sLogin;
    PSW := aData.sPSW;
    MenuName := aData.sMenuName;
    Note := aData.sNote;
    result := (ShowModal = mrOK);
    if (result) then
    begin
      aData.sLogin := login;
      aData.sPSW := PSW;
      aData.sMenuName := MenuName;
      aData.sNote := Note;
    end;
  finally
    free;
  end;
end;

procedure TfEdit.bOKClick(Sender: TObject);
var
  sErrText: string;
begin
  sErrText := '';
  // Проверка полей на заполненность
  if (Login = '') then
  begin
    sErrText := sErrText + Format(rsEditFormErrorCheckStringVal, [lbLogin.Caption]);
  end;
  if (PSW = '') then
  begin
    sErrText := sErrText + Format(rsEditFormErrorCheckStringVal, [lbPSW.Caption]);
  end;
  if (MenuName = '') then
  begin
    sErrText := sErrText + Format(rsEditFormErrorCheckStringVal, [lbMenuName.Caption]);
  end;

  if (sErrText <> '') then
  begin
    sErrText := rsEditFormErrorCaption + sErrText;
    raise exception.create(sErrText);
  end;

  ModalResult := mrOK;
end;

procedure TfEdit.eLoginExit(Sender: TObject);
begin
  // Если ввели логин и наименование меню пустое то перенести туда логин
  if (MenuName = '') then
  begin
    MenuName := login;
  end;
end;

function TfEdit.GetLogin: string;
begin
  result := trim(eLogin.text);
end;

function TfEdit.GetMenuName: string;
begin
  result := trim(eMenuName.text);
end;

function TfEdit.GetNote: string;
begin
  result := trim(eNote.text);
end;

function TfEdit.GetPSW: string;
begin
  result := ePSW.text;
end;

procedure TfEdit.SetLogin(const Value: string);
begin
  eLogin.text := Value;
end;

procedure TfEdit.SetMenuName(const Value: string);
begin
  eMenuName.text := Value;
end;

procedure TfEdit.SetNote(const Value: string);
begin
  eNote.text := Value;
end;

procedure TfEdit.SetPSW(const Value: string);
begin
  ePSW.text := Value;
end;

end.
