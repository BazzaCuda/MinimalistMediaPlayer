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
program MinimalistMediaPlayer;

uses
  Vcl.Forms,
  main in 'main.pas' {MMPUI},
  FormInputBox in 'FormInputBox.pas' {InputBoxForm},
  Vcl.Themes,
  Vcl.Styles,
  Mixer in 'Mixer.pas',
  MMDevApi_tlb in 'MMDevApi_tlb.pas',
  FormAbout in 'FormAbout.pas' {AboutForm},
  WMPLib_TLB in 'B:\Documents\Embarcadero\Studio\21.0\Imports\WMPLib_TLB.pas',
  FormHelp in 'FormHelp.pas' {HelpForm},
  _debugWindow in '..\DebugWindow\_debugWindow.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := TRUE;

  debugClear;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMMPUI, UI);
  try
    Application.Run;
  except

  end;
end.
