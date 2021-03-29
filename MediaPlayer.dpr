program MediaPlayer;

uses
  Vcl.Forms,
  main in 'main.pas' {UI},
  FormInputBox in 'FormInputBox.pas' {InputBoxForm},
  Vcl.Themes,
  Vcl.Styles,
  TUtilsClass in '..\AppTemplate\TUtilsClass.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TUI, UI);
  try
    Application.Run;
  except

  end;
end.
