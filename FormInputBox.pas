{   Minimalist Media Player
    Copyright (C) 2021 Baz Cuda <bazzacuda@gmx.com>
    https://github.com/BazzaCuda/MinimalistMediaPlayer

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307, USA
}
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
// NB We had to disable themes in setupProgressBar in order to override the standard ProgressBar characteristics
begin
//  try
//    TStyleManager.LoadFromFile('C:\Users\Public\Documents\Embarcadero\Studio\20.0\Styles\CharcoalDarkSlate.vsf');
//  except
//
//  end;
//  TStyleManager.SetStyle('Charcoal Dark Slate');
//  styleName := 'Charcoal Dark Slate';
//  var style: string;
//  for style in TStyleManager.StyleNames do
//    ShowMessage(style);

end;

end.
