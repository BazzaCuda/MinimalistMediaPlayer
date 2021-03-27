unit FormInputBox;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TInputBoxForm = class(TForm)
    edtInputBox: TEdit;
    btnModalResultmrOK: TButton;
    btnModalResultmrCancel: TButton;
  private
    { Private declarations }
  public
  end;

function InputBoxForm(APrompt: string): string;

implementation

{$R *.dfm}

{ TInputBoxForm }

function InputBoxForm(APrompt: string): string;
var
  vInputBoxForm: TInputBoxForm;
begin
  vInputBoxForm := TInputBoxForm.Create(NIL);
  try
    with vInputBoxForm do begin
      edtInputBox.Text  := APrompt;
      result            := APrompt;
      case ShowModal = mrOK of TRUE: result := edtInputBox.Text; end;
    end;
  finally
    vInputBoxForm.Free;
  end;
end;

end.
