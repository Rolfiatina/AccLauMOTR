program AccLauMOTR;

uses
  Vcl.Forms,
  vcl.Dialogs,
  ALM_uMain in 'ALM_uMain.pas',
  ALM_uTools in 'ALM_uTools.pas',
  ALM_fEdit in 'ALM_fEdit.pas' {fEdit};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Account Launcher MOTR';
  Application.Run;
  with TALM.Create do
  try
    start;
  finally
    free;
  end;

end.
