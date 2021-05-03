program MediaPlayer;

uses
  Vcl.Forms,
  main in 'main.pas' {UI},
  FormInputBox in 'FormInputBox.pas' {InputBoxForm},
  Vcl.Themes,
  Vcl.Styles,
  bzUtils in '..\..\bzLib\bzUtils.pas',
  Mixer in 'Mixer.pas',
  MMDevApi_tlb in 'MMDevApi_tlb.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := TRUE;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TUI, UI);
  try
    Application.Run;
  except

  end;
end.
