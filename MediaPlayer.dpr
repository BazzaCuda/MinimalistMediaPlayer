program MediaPlayer;

uses
  Vcl.Forms,
  main in 'main.pas' {UI},
  FormInputBox in 'FormInputBox.pas' {InputBoxForm},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Charcoal Dark Slate');
  Application.CreateForm(TUI, UI);
  try
    Application.Run;
  except

  end;
end.
