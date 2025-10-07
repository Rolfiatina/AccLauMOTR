unit SYS_fDebug;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfDebug = class(TForm)
    p1: TPanel;
    mDebug: TMemo;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fDebug: TfDebug = nil;
  procedure WriteLog(aStr: string);

implementation

{$R *.dfm}
  procedure WriteLog(aStr: string);
  begin
    if (not assigned(fDebug))  then exit;
    fDebug.mDebug.Lines.Add(format('%S: %S', [DateTimeToStr(now()), aStr]));
    fDebug.Show;
  end;

initialization
  fDebug := TfDebug.create(nil);
  fDebug.mDebug.Clear;
finalization
  FreeAndNil(fDebug);
end.
