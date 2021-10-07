{   Minimalist Media Player
    Copyright (C) 2021 Baz Cuda <bazzacuda@gmx.com>

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
unit bzUtils;

interface

{ TODO : Split utils into VCL- and FMX-compliant }

uses
  WinAPI.Windows, VCL.Forms, System.Classes, VCL.ComCtrls, VCL.Graphics,
  System.SysUtils, idGlobalProtocols, WinAPI.Messages, Math, Winapi.CommCtrl, VCL.AxCtrls,
  TLHelp32, ShellAPI, VCL.StdCtrls, uxTheme, VCL.Controls, VCL.Dialogs, Generics.Collections, Spring, Spring.Collections, System.Diagnostics;

type
  BzUtilsException = class(Exception);

  IUtils = interface(IInterface)

  end;

  TFunc<T1, T2, TResult> = reference to function(x: T1; y: T2): TResult;

// Application
  function getAppVersion: string;
  function getExePath:    string;

// Controls
  function setupProgressBar(aProgressBar: TProgressBar): boolean;

// Dialogs
  function showOKCancelMsgDlg(const aMsg: string): TModalResult;

// Files
  function copyFile(const aSrcFilePath: string; const aDstFilePath: string; var aCancel: boolean; aLabel: TLabel = NIL; CopyDelete: boolean = FALSE): boolean;
  function findFilesInFolder(const aFolderPath: string; aFileList: TStrings; const aFileMask: string; IncludeDateStamps: boolean = FALSE): boolean;
  function findFilesInSubFolders(const aFolderPath: string; const aFileList: TStrings; const aFileMask: string; IncludeDateStamps: boolean = FALSE): boolean;
  function findFontFiles(const aFontList: TStrings; IncludePath: boolean = FALSE): boolean;
  function getFileDiskSize(const aFilePath: String): Int64;
  function getFileSize(const aFilePath: string): int64;
  function moveFile(const aSrcFilePath: string; const aDstFilePath: string; ReplaceExisting: boolean = FALSE): boolean;
  function rotThisFile(const aFilePath: string): boolean;
  function setFileOrFolderDateTime(const aFileOrFolderPath: string; aDT: TDateTime): boolean;

// File filters
  function getAllFilesFilter:   string;
  function getAudioFilter:      string;
  function getCustomFilter(const aFilterName: string; const aExts: string): string;
  function getImageFilter:      string;
  function isAudio(const aFileName: string):    boolean;
  function isImage(const aFileName: string):    boolean;
  function isMovie(const aFileName: string):    boolean;
  function isPlayList(const aFileName: string): boolean;
  function getPlayListFilter:  string;
  function getVideoFilter:     string;

// Folders
  function findSubFolders(const aFolderPath: string; const aFolderList: TStrings; IncludeHidden: boolean = FALSE): boolean;
  function ITBS(const aFolderPath: string): string;
  function rotThisFolder(const aFolderPath: string): boolean;
  function rotThisFoldersContents(const aFolderPath: string): boolean;
  function RTBS(const aFolderPath: string): string;

// Formatting
  function formatFileSize(aFS: int64): string;
  function formatPageNumber(aPageNumber: int64; aPageCount: int64): string;
  function formatTickCount(aTickCount: cardinal): string;
  function formatVideoTime(aPosInMs: int64; aLenInMs: int64): string;
  function formatVolume(aVolumeLevel: integer): string;

// General
  function Delay(dwMilliseconds:DWORD): boolean;

// Graphics
  function colorToRGB(aColor: Integer): String;
  function getScreenShot: TBitmap;
  function loadOleGraphic(aFilePath: string; aBitmap: TBitmap): boolean;

// Hardware

// Keyboard
  function isCapsLockOn: boolean;
  function isControlKeyDown: boolean;
  function isShiftKeyDown: boolean;

// Strings
  function getFileNameWithoutExt(const aFilePath: string): string;
  function YesOrNo(TrueOrFalse: boolean): string;

// Text
  function getTextWidth(const aText: string; const aFont: TFont): Integer;

// Tickers
  function tickerStart: TStopWatch;  { TODO : Change implementation to use TStopWatch (System.Diagnostics) }
  function tickerStop(aStopWatch: TStopWatch): boolean;
  function tickerTickCount(aStopWatch: TStopWatch): Cardinal;

// Windows and Processes
  function doCommandLine(const aCommandLine: string): boolean;
  function execProcessAndWait(const aFileName: string; const aParams: string; const aFolder: string; WaitUntilTerminated: boolean; WaitUntilIdle: boolean; RunMinimized: boolean; var ErrorCode: integer): boolean;
  function getProcessHWND(aPID: DWORD): DWORD;
  function getDesktopSize(var aWidth, aHeight: integer): boolean;
  function launchApp(const aAppFilePath: string; const aAppParams: string; const aAppFolder: string; SingleInstance: boolean): boolean;
  function processExists(const aAppFilePath: string; var aProcessID: cardinal): Boolean;
  function resizeMoveWindow(aHWND: HWND; aX: integer; aY: integer; aWidth: integer; aHeight: integer; center: boolean): boolean;
  function toggleStayOnTop(aHWND: HWND): boolean;

const
  IMAGE_EXTS      = '.jpe.jpg.jpeg.bmp.ico.emf.wmf.hips.hip.jp2.jpc.mng.pnm.pgm.ppm.png.ras.tif.cur.pcx.gif';
  VLC_AUDIO_EXTS1 = '.a52.aac.ac3.adt.adts.aif.aifc.aiff.amr.aob.ape.cda.dts.flac.it.m4a.m4p.mid.mka.mlp';
  VLC_AUDIO_EXTS2 = '.mod.mp1.mp2.mp3.mpc.oga.ogg.oma.rmi.s3m.spx.tta.voc.vqf.w64.wav.wma.wv.xa.xm';
  AUDIO_EXTS      = VLC_AUDIO_EXTS1 + VLC_AUDIO_EXTS2;

  VLC_VIDEO_EXTS1 = '.3g2.3gp.3gp2.3gpp.amv.asf.avi';             //  omitted .au
  VLC_VIDEO_EXTS2 = '.divx.dv.flv.gxf';                           //  omitted .bin .cue
  VLC_VIDEO_EXTS3 = '.m1v.m2t.m2ts.m2v.m4v.mkv.mov.mp2.mp2v';
  VLC_VIDEO_EXTS4 = '.mp4.mp4v.mpa.mpe.mpeg.mpeg1.mpeg2.mpeg4.mpg.mpv2.mts.mxf.nsv.nuv';
  VLC_VIDEO_EXTS5 = '.ogg.ogm.ogv.ogx.ps.rec.rm.rmvb.tod.ts.tts'; //  omitted .snd
  VLC_VIDEO_EXTS6 = '.vob.vro.webm.wmv';
  MOVIE_EXTS      = '.001' + VLC_VIDEO_EXTS1 + VLC_VIDEO_EXTS2 + VLC_VIDEO_EXTS3 + VLC_VIDEO_EXTS4 + VLC_VIDEO_EXTS5 + VLC_VIDEO_EXTS6;

  PLAYLIST_EXTS   = '.asx.b4s.ifo.m3u.m3u8.pls.ram.sdp.vlc.xspf'; //  omitted .iso .rar .zip

implementation

const
  APP_VERSION = '0.0';

//===== APPLICATION =====

function getAppVersion: string;
begin
  result := 'v' + APP_VERSION;
end;

function getExePath: string;
begin
  result := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
end;

//===== CONTROLS =====

function setupProgressBar(aProgressBar: TProgressBar): boolean;
var
  vStyle: integer;
begin
  SetThemeAppProperties(0); // This is preferable in FormCreate

  SendMessage(Application.Handle, WM_THEMECHANGED, 0, 0);
  SendMessage(Application.MainForm.Handle, CM_RECREATEWND, 0, 0);

  aProgressBar.Brush.Color := clBlack; // Set Background colour
  SendMessage (aProgressBar.Handle, PBM_SETBARCOLOR, 0, clDkGray); // Set bar colour

  vStyle  := GetWindowLong(aProgressBar.Handle, GWL_EXSTYLE);
  vStyle  := vStyle - WS_EX_STATICEDGE;
  SetWindowLong(aProgressBar.Handle, GWL_EXSTYLE, vStyle);

  // add thin border to fix redraw problems
  vStyle  := GetWindowLong(aProgressBar.Handle, GWL_STYLE);
  vStyle  := vStyle - WS_BORDER;
  SetWindowLong(aProgressBar.Handle, GWL_STYLE, vStyle);
end;

//===== DIALOGS =====

function showOKCancelMsgDlg(const aMsg: string): TModalResult;
begin
  with CreateMessageDialog(aMsg, mtConfirmation, MBOKCANCEL, MBCANCEL) do
  try
    Font.Name := 'Segoe UI';
    Font.Size := 12;
    Height    := Height + 50;
    Width     := width + 200;
    for var i := 0 to ControlCount - 1 do begin
      case Controls[i] is TLabel  of   TRUE: with Controls[i] as TLabel do Width := Width + 200; end;
      case Controls[i] is TButton of   TRUE: with Controls[i] as TButton do begin
                                                                                Top   := Top + 60;
                                                                                Left  := Left + 100;
                                                                            end;end;
    end;
    result := ShowModal;
  finally
    Free;
  end;
end;

//===== FILES =====

function copyFileCallBack(aTotalFileSize, aTotalBytesTransferred, aStreamSize, aStreamBytesTransferred: int64;
                          aStreamNumber, aCallbackReason: Dword;
                          aSourceFile, aDestinationFile: THandle;
                          aLabel: TLabel): DWord; stdcall;
var
  vProgressPercent: int64;
begin
  Result := PROGRESS_CONTINUE;
  case aCallbackReason = CALLBACK_CHUNK_FINISHED of TRUE: begin
    vProgressPercent := trunc(aTotalBytesTransferred / aTotalFileSize * 100);
    case aLabel = NIL of FALSE: aLabel.Caption := format('Saving...%d%%', [vProgressPercent]); end;end;end;
  application.ProcessMessages;
end;

function copyFile(const aSrcFilePath: string; const aDstFilePath: string; var aCancel: boolean; aLabel: TLabel = NIL; CopyDelete: boolean = FALSE): boolean;
begin
  result := CopyFileEx(PChar(aSrcFilePath), PChar(aDstFilePath), @copyFileCallback, pointer(aLabel), @aCancel, 0);
  case result and CopyDelete of TRUE: result := DeleteFile(aSrcFilePath); end;
end;

function findFilesInFolder(const aFolderPath: string; aFileList: TStrings; const aFileMask: string; IncludeDateStamps: boolean = FALSE): boolean;
var
  sr: TSearchRec;
  vFolderPath: string;
begin
  aFileList.clear;
  vFolderPath := ITBS(aFolderPath);
  case FindFirst(vFolderPath + aFileMask, faAnyFile, sr) = 0 of TRUE:
    repeat  case ((sr.Attr and faDirectory) = faDirectory) of
              FALSE:  case IncludeDateStamps of
                         TRUE: aFileList.AddObject(sr.Name, TObject(trunc(sr.TimeStamp * 100000)));
                        FALSE: aFileList.Add(sr.Name);
                      end;end;
    until   FindNext(sr) <> 0; end;
  FindClose(sr);
end;

function findFilesInSubFolders(const aFolderPath: string; const aFileList: TStrings; const aFileMask: string; IncludeDateStamps: boolean = FALSE): boolean;
var
  sr: TSearchRec;
  vFolderPath: string;
begin
  vFolderPath := ITBS(aFolderPath);
  case FindFirst(vFolderPath + aFileMask, faAnyFile, sr) = 0 of TRUE:
    repeat  case ((sr.Attr and faDirectory) = faDirectory) of
               TRUE:  case (sr.Name <> '.') AND (sr.Name <> '..') of
                         TRUE: FindFilesInSubFolders(vFolderPath + sr.Name, aFileList, aFileMask, IncludeDateStamps); end;
              FALSE:  case IncludeDateStamps of
                         TRUE: aFileList.AddObject(vFolderPath + sr.Name, TObject(trunc(sr.TimeStamp * 100000)));
                        FALSE: aFileList.Add(vFolderPath + sr.Name);
                      end;end;
    until   FindNext(sr) <> 0; end;
  FindClose(sr);
end;

function findFontFiles(const aFontList: TStrings; IncludePath: boolean = FALSE): boolean;
var
  vWinFontDir: string;
  sr: TSearchRec;
begin
  aFontList.Clear;
  vWinFontDir := GetEnvironmentVariable('windir') + '\Fonts\';

  case FindFirst(vWinFontDir + '*.ttf', faAnyFile, sr) = 0 of
    TRUE: repeat  case IncludePath of  TRUE: aFontList.Add(vWinFontDir + sr.Name);
                                      FALSE: aFontList.Add(sr.Name); end;
          until   FindNext(sr) <> 0;
  end;

  FindClose(sr);
end;

function getFileDiskSize(const aFilePath: String): Int64;
var
  info: TWin32FileAttributeData;
begin
  case integer(GetFileAttributesEx(PWideChar(aFilePath), GetFileExInfoStandard, @info)) <> 0 of
    FALSE:  result := -1;
     TRUE:  begin
              Int64Rec(Result).Lo := Info.nFileSizeLow;
              Int64Rec(Result).Hi := Info.nFileSizeHigh; end;end;
end;

function getFileSize(const aFilePath: string): int64;
var
  vHandle:  THandle;
  vRec:     TWin32FindData;
begin
  vHandle := FindFirstFile(PChar(aFilePath), vRec);
  case vHandle <> INVALID_HANDLE_VALUE of TRUE: begin
                                                  WinAPI.Windows.FindClose(vHandle);
                                                  case (vRec.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 of TRUE:
                                                    result := (Int64(vRec.nFileSizeHigh) shl 32) + vRec.nFileSizeLow; end;end;end;

//  result := FileSizeByName(aFilePath);
end;

function moveFile(const aSrcFilePath: string; const aDstFilePath: string; ReplaceExisting: boolean = FALSE): boolean;
begin
  case ReplaceExisting of
     TRUE:  result := MoveFileEx(PChar(aSrcFilePath), PChar(aDstFilePath), MOVEFILE_REPLACE_EXISTING);
    FALSE:  result := MoveFileEx(PChar(aSrcFilePath), PChar(aDstFilePath), 0);
  end;
end;

function rotThisFile(const aFilePath: string): boolean;
begin
  result := DoCommandLine('rot -nobanner -p 1 -r "' + aFilePath + '"');
end;

function setFileOrFolderDateTime(const aFileOrFolderPath: string; aDT: TDateTime): boolean;
// Handles folders and files
var
  vhDir:       THandle;
  vSystemTime: TSystemTime;
  vFileTime:   TFiletime;
begin
  vhDir := CreateFile(PChar(aFileOrFolderPath),
                     GENERIC_READ or GENERIC_WRITE,
                     0,
                     nil,
                     OPEN_EXISTING,
                     FILE_FLAG_BACKUP_SEMANTICS,
                     0);
  case vhDir <> INVALID_HANDLE_VALUE of
    TRUE:   try
              DateTimeToSystemTime(aDT, vSystemTime);
              SystemTimeToFileTime(vSystemTime, vFileTime);
              result := SetFileTime(vhDir, @vFileTime, @vFileTime, @vFileTime);
            finally
              CloseHandle(vhDir);
            end;
   FALSE:  result := FALSE;
  end;
end;

//===== FILE FILTERS =====

function getAllFilesFilter:  string;
begin
  result := 'All Files (*.*)|*.*|' + GetImageFilter + '|' + GetVideoFilter + '|' +  GetAudioFilter + '|' + GetPlayListFilter;
end;

function getAudioFilter: string;
begin
  result := GetCustomFilter('Audio Files', AUDIO_EXTS);
end;

function getCustomFilter(const aFilterName: string; const aExts: string): string;
var
  vDotIx: integer;
  vExt:   string;
  vExts:  string;
begin
  result  := '';
  vExts   := aExts;
  while vExts <> '' do begin
    vDotIx   := LastDelimiter('.', vExts);
    vExt     := copy(vExts, vDotIx, 255);
    result  := '*' + vExt + ';' + result;
    delete(vExts, vDotIx, 255);
  end;
  delete(result, length(result), 1);  //  delete the final semicolon
  result := aFilterName + ' (' + result + ')|' + result;
end;

function getImageFilter: string;
begin
  result := GetCustomFilter('Image Files', IMAGE_EXTS);
end;

function isAudio(const aFileName: string): boolean;
begin
  result := pos(LowerCase(ExtractFileExt(aFileName)), AUDIO_EXTS) > 0
end;

function isImage(const aFileName: string): boolean;
begin
  result := pos(LowerCase(ExtractFileExt(aFileName)), IMAGE_EXTS) > 0
end;

function isMovie(const aFileName: string): boolean;
begin
  result := pos(LowerCase(ExtractFileExt(aFileName)), MOVIE_EXTS) > 0
end;

function isPlayList(const aFileName: string): boolean;
begin
  result := pos(LowerCase(ExtractFileExt(aFileName)), PLAYLIST_EXTS) > 0
end;

function getPlayListFilter: string;
begin
  result := GetCustomFilter('Playlists', PLAYLIST_EXTS);
end;

function getVideoFilter: string;
begin
  result := GetCustomFilter('Video Files', MOVIE_EXTS);
end;

//===== FOLDERS =====

function ITBS(const aFolderPath: string): string;
begin
  result := IncludeTrailingBackslash(aFolderPath);
end;

function findSubFolders(const aFolderPath: string; const aFolderList: TStrings; IncludeHidden: boolean = FALSE): boolean;
var
  sr: TSearchRec;
  vAttr: integer;
  vFolderPath: string;
begin
  aFolderList.Clear;
  vFolderPath := ITBS(aFolderPath);
  vAttr := faDirectory;
  case IncludeHidden of TRUE: vAttr := vAttr or faHidden; end;
  case FindFirst(vFolderPath + '*.*', vAttr, sr) = 0 of TRUE:
  repeat
    case (sr.Attr and faDirectory) = faDirectory of TRUE:
      case (sr.Name <> '.') and (sr.Name <> '..') of TRUE: aFolderList.Add(vFolderPath + sr.Name + '\'); end;end;
  until FindNext(sr) <> 0;
  end;
  FindClose(sr);
end;

function rotThisFolder(const aFolderPath: string): boolean;
begin
  result := DoCommandLine('rot -nobanner -p 1 -r -s "' + RTBS(aFolderPath) + '"');
end;

function rotThisFoldersContents(const aFolderPath: string): boolean;
begin
  result := DoCommandLine('rot -nobanner -p 1 -r -s "' + ITBS(aFolderPath) + '*.*"');
end;

function RTBS(const aFolderPath: string): string;
begin
  result := aFolderPath;
  case (length(result) > 1)
        AND CharInSet(result[length(result)], ['\','/'])
        AND ((length(result) <> 3) OR (result[2] <> ':')) of
    TRUE: SetLength(result, length(result) - 1); end;
end;

//===== FORMATTING =====

function formatFileNumber(aFileNumber: int64; aFileCount: int64): string;
begin
  result := format(' %d / %d ', [aFileNumber, aFileCount])
end;

function formatFileSize(aFS: int64): string;
var
 vx: double;
begin
  case aFS > (1024 * 1024 * 1024) of
    TRUE: begin vx := RoundTo(aFS / (1024 * 1024 * 1024), -2);
                result := format('%.2f', [vx]) + ' Gb'; end;
   FALSE: case aFS > (1024 * 1024) of
            TRUE: begin vx := RoundTo(aFS / (1024 * 1024), -2);
                        result := format('%.2f', [vx]) + ' Mb'; end;
           FALSE: begin vx := aFS / 1024;
                  result := format('%d', [trunc(vx)]) + ' Kb'; end;end;end;
end;

function formatPageNumber(aPageNumber: int64; aPageCount: int64): string;
begin
  result := format('page %d / %d', [aPageNumber, aPageCount]);
end;

function formatTickCount(aTickCount: cardinal): string;
begin
  result := format('%.3fs', [aTickCount / 1000]);
end;

function formatVideoTime(aPosInMs: int64; aLenInMs: int64): string;
var
  dd, hh, mm, ss, ms: word;
  fmt: string;

  function w2s(w: word): string;
  begin
    case (w < 10) of TRUE: Result := '0' + IntToStr(w);
                    FALSE: Result := IntToStr(w); end;
  end;

  function doFormat(TimeInMs: int64): string;
  begin
    ms := timeInMs mod 1000; timeInMs := timeInMs div 1000;
    ss := timeInMs mod 60;   timeInMs := timeInMs div 60;
    mm := timeInMs mod 60;   timeInMs := timeInMs div 60;
    hh := timeInMs mod 24;   timeInMs := timeInMs div 24;
    dd := timeInMs;

    Result := fmt;
    Result := StringReplace(Result, 'dd',  w2s(dd), [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, 'hh',  w2s(hh), [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, 'mm',  w2s(mm), [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, 'ss',  w2s(ss), [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, 'ms',  w2s(ms), [rfReplaceAll, rfIgnoreCase]);
  end;
begin
  case aLenInMs < 3600000 of  TRUE: fmt := 'mm:ss';
                             FALSE: fmt := 'hh:mm:ss'; end;

  result := doFormat(aPosInMs) + ' / ' + doFormat(aLenInMs);
end;

function formatVolume(aVolumeLevel: integer): string;
begin
  result := format('+%d', [aVolumeLevel]);
end;

//===== GENERAL =====
function Delay(dwMilliseconds:DWORD): boolean;
var
  iStart, iStop: DWORD;
begin
  iStart := GetTickCount;
  repeat
    iStop  := GetTickCount;
    Application.ProcessMessages;
  until (iStop  -  iStart) >= dwMilliseconds;
end;

//===== GRAPHICS =====

function colorToRGB(aColor: Integer): String;
var
  r, g, b: String;
begin
  r := IntToHex(aColor and $0000FF, 2);
  g := IntToHex((aColor and $00FF00) shr 8,  2);
  b := IntToHex((aColor and $FF0000) shr 16, 2);
  result := r + g + b;
end;

function getScreenShot: TBitmap;
var
  vhDesktop: HDC;
begin
  result  := TBitmap.Create;
  vhDesktop := GetDC(0);
  try
    try
      result.PixelFormat := pf32bit;
      result.Width := Screen.Width;
      result.Height := Screen.Height;
      BitBlt(result.Canvas.Handle, 0, 0, result.Width, result.Height, vhDesktop, 0, 0, SRCCOPY);
      result.Modified := True;
    finally
      ReleaseDC(0, vhDesktop);
    end;
  except
    result.Free;
    result := nil;
  end;
end;

function loadOleGraphic(aFilePath: string; aBitmap: TBitmap): boolean;
var
  vOleGraphic: TOleGraphic;
  vFS: TFileStream;
  vTI: TWICImage;
begin
  vTI := TWICImage.Create;
  try
      vTI.LoadFromFile(aFilePath);
      ABitmap.Assign(vTI);
  finally
    VTI.Free;
  end;
  result := TRUE;
end;

//===== HARDWARE =====

//===== INI FILES =====

//===== KEYBOARD =====

function isCapsLockOn: boolean;
begin
  result := GetKeyState(VK_CAPITAL) <> 0;
end;

function isControlKeyDown: boolean;
// If the high-order bit is 1, the key is down, otherwise it is up.
// If the low-order bit is 1, the key is toggled.
// A key, such as the CAPS LOCK key, is toggled if it is turned on.
// The key is off and untoggled if the low-order bit is 0. A toggled key's indicator light (if any)
// on the keyboard will be on when the key is toggled, and off when the key is untoggled.
// Check high-order bit of state...
begin
  result := (GetKeyState(VK_CONTROL) AND $80) <> 0;
end;

function isShiftKeyDown: boolean;
begin
  result := (GetKeyState(VK_SHIFT) AND $80) <> 0;
end;

//===== STRINGS =====
function getFileNameWithoutExt(const aFilePath: string): string;
begin
  var vFN:string  := ExtractFileName(aFilePath);
  var vExt:string := ExtractFileExt(aFilePath);
  result          := copy(vFN, 1, pos(vExt, vFN) - 1);
end;

function YesOrNo(TrueOrFalse: boolean): string;
const YesNo: array[FALSE..TRUE] of string = ('No', 'Yes');
begin
  result := YesNo[TrueOrFalse];
end;

//===== TEXT =====
function getTextWidth(const aText: string; const aFont: TFont): Integer;
var
  vCanvas: TCanvas;
begin
  vCanvas := TCanvas.Create;
  try
    vCanvas.Handle := GetDC(0);
    try
      vCanvas.Font.Assign(aFont);
      result := vCanvas.TextWidth(aText);
    finally
      ReleaseDC(0, vCanvas.Handle);
    end;
  finally
    vCanvas.Free;
  end;
end;

//===== TICKERS =====
function tickerStart: TStopWatch;
begin
  result := TStopWatch.StartNew;
end;

function tickerStop(aStopWatch: TStopWatch): boolean;
begin
  aStopWatch.Stop;
end;

function tickerTickCount(aStopWatch: TStopWatch): Cardinal;
begin
  result := aStopWatch.ElapsedMilliseconds;
end;

//=====  WINDOWS AND PROCESSES

function doCommandLine(const aCommandLine: string): boolean;
var
  vStartInfo:  TStartupInfo;
  vProcInfo:   TProcessInformation;
  vCmd:        string;
  vParams:     string;
begin
  result := FALSE;
  case trim(aCommandLine) = '' of TRUE: EXIT; end;

  FillChar(vStartInfo, SizeOf(TStartupInfo), #0);
  FillChar(vProcInfo, SizeOf(TProcessInformation), #0);
  vStartInfo.cb          := SizeOf(TStartupInfo);
  vStartInfo.wShowWindow := SW_HIDE;
  vStartInfo.dwFlags     := STARTF_USESHOWWINDOW;

  vCmd := 'c:\windows\system32\cmd.exe';
  vParams := '/c ' + aCommandLine;

  result := boolean(CreateProcess(PWideChar(vCmd), PWideChar(vParams), nil, nil, FALSE,
                          CREATE_NEW_PROCESS_GROUP + NORMAL_PRIORITY_CLASS, nil, PWideChar(GetExePath),
                          vStartInfo, vProcInfo));
end;

function execProcessAndWait(const aFileName: string; const aParams: string; const aFolder: string; WaitUntilTerminated: boolean; WaitUntilIdle: boolean; RunMinimized: boolean; var ErrorCode: integer): boolean;
var
  vCmdLine:     string;
  vWorkingDirP: PChar;
  vStartupInfo: TStartupInfo;
  vProcessInfo: TProcessInformation;
  vFolder:      string;
begin
  result  := TRUE;
  vFolder := aFolder;

  vCmdLine := '"' + aFileName + '" ' + aParams;
  case vFolder = '' of TRUE: vFolder := RTBS(ExtractFilePath(aFileName)); end;

  Fillchar(vStartupInfo, SizeOf(vStartupInfo), #0);
  vStartupInfo.cb := SizeOf(vStartupInfo);

  case RunMinimized of TRUE:  begin
                                vStartupInfo.dwFlags      := STARTF_USESHOWWINDOW;
                                vStartupInfo.wShowWindow  := SW_SHOWMINIMIZED;
                              end;end;

  case vFolder <> '' of  TRUE:  vWorkingDirP := PChar(vFolder);
                        FALSE:  vWorkingDirP := nil; end;

  case boolean(CreateProcess(nil, PChar(vCmdLine), nil, nil, false, 0, nil, vWorkingDirP, vStartupInfo, vProcessInfo)) of
    FALSE:  begin
              Result := false;
              ErrorCode := GetLastError;
              EXIT;
            end;
     TRUE:  with vProcessInfo do begin
              CloseHandle(hThread);
              case WaitUntilIdle        of TRUE:  WaitForInputIdle(hProcess, INFINITE); end;
              case WaitUntilTerminated  of TRUE:  repeat  Application.ProcessMessages;
                                                  until   MsgWaitForMultipleObjects(1, hProcess, false, INFINITE, QS_ALLINPUT)
                                                            <> WAIT_OBJECT_0 + 1; end;
              CloseHandle(hProcess); end;end;
end;

function getDesktopSize(var aWidth, aHeight: integer): boolean;
 var
  vhRect: TRect;
begin
  SystemParametersInfo(SPI_GETWORKAREA, 0, @vhRect, 0);
  aWidth  := vhRect.Right - vhRect.Left;
  aHeight := vhRect.Bottom - vhRect.Top;
end;

// NB You cannot pass a nested function as a parameter to another function in the 64-bit compiler
//    EnumWindowsProc will not work correctly in 64-bit if it's nested
type
  PEnumInfo = ^TEnumInfo;
  TEnumInfo = record
    ProcessID: DWORD;
    HWND     : HWND;
  end;

    function enumWindowsProc(Wnd: HWND;  Param : LPARAM): Bool; stdcall;
    var
      PID: DWORD;
      PEI: PEnumInfo;
    begin
      PEI := PEnumInfo(Param);
      GetWindowThreadProcessID(Wnd, @PID);

      Result := (PID <> PEI^.ProcessID) or
              (not IsWindowVisible(WND)) or
              (not IsWindowEnabled(WND));

      if not Result then PEI^.HWND := WND; //break on return FALSE
    end;

function getProcessHWND(aPID: DWORD): DWORD;
var
  EI : TEnumInfo;
begin
  EI.ProcessID := aPID;
  EI.HWND := 0;
  EnumWindows(@enumWindowsProc, LPARAM(@EI));
  Result := EI.HWND;
end;

function launchApp(const aAppFilePath: string; const aAppParams: string; const aAppFolder: string; SingleInstance: boolean): boolean;
var
  vProcessID:  DWORD;
  vAppWnd:     HWND;
  vMyPopup:    HWND;
begin
  case SingleInstance of TRUE:  case ProcessExists(aAppFilePath, vProcessID) of
                                   TRUE:  begin
                                            vAppWnd := GetProcessHWND(vProcessID);
                                            BringWindowToTop(vAppWnd);
                                            vMyPopup := GetLastActivePopup(vAppWnd);
                                            case IsIconic(vMyPopup) of   TRUE: ShowWindow(vMyPopup,SW_RESTORE);
                                                                        FALSE: SetForegroundWindow(vMyPopup); end;
                                            EXIT;
                                          end;
                                  FALSE:  end;end;
  ShellExecute(GetDesktopWindow, 'open', pchar(aAppFilePath), pchar(aAppParams), pchar(aAppFolder), SW_SHOW);
end;

function processExists(const aAppFilePath: string; var aProcessID: cardinal): Boolean;
var
  vContinueLoop: BOOL;
  vSnapshotHandle: THandle;
  vProcessEntry32: TProcessEntry32;
  vExeFile: string;
  vExeName: string;
  vAppName: string;
begin
  vAppName := LowerCase(ExtractFileName(aAppFilePath));
  vSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  vProcessEntry32.dwSize := SizeOf(vProcessEntry32);
  aProcessID := 0;

  vContinueLoop := Process32First(vSnapshotHandle, vProcessEntry32);
  try
    Result := False;
    while Integer(vContinueLoop) <> 0 do begin
      vExeFile := LowerCase(vProcessEntry32.szExeFile);
      vExeName := LowerCase(ExtractFileName(vProcessEntry32.szExeFile));
      result :=  (vAppName = vExeFile) or (vAppName = vExeName);
      case result of TRUE: begin
        aProcessID := vProcessEntry32.th32ProcessID;
        EXIT;
      end;end;
      vContinueLoop := Process32Next(vSnapshotHandle, vProcessEntry32);
    end;
  finally
    CloseHandle(vSnapshotHandle);
  end;
end;

function resizeMoveWindow(aHWND: HWND; aX: integer; aY: integer; aWidth: integer; aHeight: integer; center: boolean): boolean;
var
  vR: TRect;
begin
  case center of
     TRUE: begin
            SetWindowPos(aHWND, 0, 0, 0, aWidth, aHeight, SWP_NOZORDER + SWP_NOMOVE + SWP_NOREDRAW);
            GetWindowRect(aHWND, vR);
            SetWindowPos(aHWND, 0,
                           (GetSystemMetrics(SM_CXVIRTUALSCREEN) - (vR.Right - vR.Left)) div 2,
                           (GetSystemMetrics(SM_CYVIRTUALSCREEN) - (vR.Bottom - vR.Top)) div 2, 0, 0, SWP_NOZORDER + SWP_NOSIZE);
            end;
    FALSE:  SetWindowPos(aHWND, 0, aX, aY, aWidth, aHeight, SWP_NOZORDER);
  end;
end;

var
  FKeepOnTop: boolean;

function toggleStayOnTop(aHWND: HWND): boolean;
begin
  FKeepOnTop := not FKeepOnTop;
  case FKeepOnTop of  TRUE: SetWindowPos(aHWND, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE);
                     FALSE: SetWindowPos(aHWND, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE); end;
end;

//=====

initialization
  FKeepOnTop := FALSE;

finalization

end.
