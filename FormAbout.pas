{   Minimalist Media Player
    Copyright (C) 2021 Baz Cuda
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
unit FormAbout;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls,
  Vcl.StdCtrls;

type
  TAboutForm = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    lblReleaseVersion: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lblWebsiteURL: TLabel;
    Bevel1: TBevel;
    btnOK: TButton;
    Bevel2: TBevel;
    Label6: TLabel;
    lblBuildVersion: TLabel;
    procedure lblWebsiteURLClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    { Private declarations }
  public
    function setBuildVersion(aBuild: string): boolean;
    function setReleaseVersion(aRelease: string): boolean;
  end;

var
  AboutForm: TAboutForm;

implementation

uses ShellAPI;

{$R *.dfm}

procedure TAboutForm.btnOKClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;

procedure TAboutForm.lblWebsiteURLClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'https://github.com/BazzaCuda/MinimalistMediaPlayer', '', '', SW_SHOW);
end;

function TAboutForm.setBuildVersion(aBuild: string): boolean;
begin
  lblBuildVersion.Caption := aBuild;
end;

function TAboutForm.setReleaseVersion(aRelease: string): boolean;
begin
  lblReleaseVersion.Caption := aRelease;
end;

end.
