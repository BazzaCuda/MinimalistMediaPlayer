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
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
  end;

function InputBoxForm(APrompt: string): string;

implementation

uses VCL.Themes, VCL.Styles;

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

procedure TInputBoxForm.FormCreate(Sender: TObject);
begin
  TStyleManager.LoadFromFile('C:\Users\Public\Documents\Embarcadero\Studio\20.0\Styles\CharcoalDarkSlate.vsf');
//  TStyleManager.SetStyle('Charcoal Dark Slate');
//  styleName := 'Charcoal Dark Slate'; // might be a 10.4 thing
//  var style: string;
//  for style in TStyleManager.StyleNames do
//    ShowMessage(style);

end;

end.
