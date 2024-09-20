unit ALM_fMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    PopupMenu1: TPopupMenu;
    a1: TMenuItem;
    vvv: TMenuItem;
    TrayIcon1: TTrayIcon;
    procedure a1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.a1Click(Sender: TObject);
begin
//
end;

end.
