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
unit main;

interface

uses
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons,
  System.Classes, WMPLib_TLB, Vcl.AppEvnts, WinApi.Messages, WinApi.Windows;

type
  TUI = class(TForm)
    applicationEvents: TApplicationEvents;
    lblAudioBitRate: TLabel;
    lblBitRate: TLabel;
    lblFileSize: TLabel;
    lblFrameRate: TLabel;
    lblInfo: TLabel;
    lblTimeDisplay: TLabel;
    lblVideoBitRate: TLabel;
    lblXY: TLabel;
    lblXY2: TLabel;
    lblXYRatio: TLabel;
    progressBar: TProgressBar;
    tmrInfo: TTimer;
    tmrMetaData: TTimer;
    tmrPlayNext: TTimer;
    tmrTimeDisplay: TTimer;
    WMP: TWindowsMediaPlayer;
    lblMediaCaption: TLabel;
    tmrMediaCaption: TTimer;
    procedure applicationEventsMessage(var Msg: tagMSG; var Handled: Boolean);
    procedure FormActivate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure lblMuteUnmuteClick(Sender: TObject);
    procedure progressBarMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure progressBarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure tmrInfoTimer(Sender: TObject);
    procedure tmrMetaDataTimer(Sender: TObject);
    procedure tmrPlayNextTimer(Sender: TObject);
    procedure tmrTimeDisplayTimer(Sender: TObject);
    procedure WMPClick(ASender: TObject; nButton, nShiftState: SmallInt; fX, fY: Integer);
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
    procedure WMPKeyDown(ASender: TObject; nKeyCode, nShiftState: SmallInt);
    procedure WMPKeyUp(ASender: TObject; nKeyCode, nShiftState: SmallInt);
    procedure WMPMouseDown(ASender: TObject; nButton, nShiftState: SmallInt; fX, fY: Integer);
    procedure WMPMouseMove(ASender: TObject; nButton, nShiftState: SmallInt; fX, fY: Integer);
    procedure WMPPlayStateChange(ASender: TObject; NewState: Integer);
    procedure WMSysCommand(var Message : TWMSysCommand); Message WM_SYSCOMMAND;
    procedure tmrMediaCaptionTimer(Sender: TObject);
  private
    function  addMenuItem: boolean;
    function  setupProgressBar: boolean;
    function  showAboutBox: boolean;
  protected
  public
    // UI Functions only - application logic is in TFX
    function  hideLabels: boolean;
    function  repositionLabels: boolean;
    function  repositionTimeDisplay: boolean;
    function  repositionWMP: boolean;
    function  resizeWindow1: boolean;
    function  resizeWindow2: boolean;
    function  resizeWindow3(Shift: TShiftState): boolean;
    function  showInfo(aInfo: string): boolean;
    function  showMediaCaption: boolean;
    function  toggleControls(Shift: TShiftState): boolean;
  end;

var
  UI: TUI;  // User Interface

implementation

uses
  WinApi.CommCtrl,  WinApi.uxTheme,
  System.SysUtils, System.Generics.Collections, System.Math, System.Variants,
  FormInputBox, MMSystem, Mixer, VCL.Graphics, clipbrd, System.IOUtils, ShellAPI, FormAbout;

const
  MENU_ID     = 1001;

type
  TGV = class                        // Global [application-wide] Variables
  strict private                     // force code to use the properties
    FBlackOut:      boolean;
    FClosing:       boolean;
    FplayIx:        integer;
    Fplaylist:      TList<string>;
    FInputBox:      boolean;
    FmetaDataCount: integer;
    FMute:          boolean;
    FnewMediaFile:  boolean;
    FSampling:      boolean;
    FStartUp:       boolean;
    FZoomed:        boolean;
    function  getExePath: string;
    function  getAppBuildVersion: string;
    function  getAppReleaseVersion: string;
    function  getFileVersion(const aFilePath: string = ''; const fmt: string = '%d.%d.%d.%d'): string;
  private
  public
    constructor create;
    destructor  destroy;  override;
    function    invalidPlayIx: boolean;
    property    appBuildVersion:    string        read getAppBuildVersion;
    property    appReleaseVersion:  string        read getAppReleaseVersion;
    property    blackOut:           boolean       read FBlackOut      write FBlackOut;
    property    closing:            boolean       read FClosing       write FClosing;
    property    exePath:            string        read GetExePath;
    property    inputBox:           boolean       read FInputBox      write FInputBox;
    property    mute:               boolean       read FMute          write FMute;
    property    metaDataCount:      integer       read FmetaDataCount write FmetaDataCount;
    property    newMediaFile:       boolean       read FnewMediaFile  write FnewMediaFile;
    property    playIx:             integer       read FplayIx        write FplayIx;
    property    playlist:           TList<string> read Fplaylist;
    property    sampling:           boolean       read FSampling      write FSampling;
    property    startup:            boolean       read FStartUp       write FStartUp;
    property    zoomed:             boolean       read FZoomed        write FZoomed;
  end;

  TFX = class                        // application Functions aka program/business logic
  private
    function adjustAspectRatio: boolean;
    function blackOut: boolean;
    function clearMediaMetaData: boolean;
    function clipboardCurrentFileName: boolean;
    function currentFilePath: string;
    function Delay(dwMilliseconds:DWORD): boolean;
    function deleteBookmark: boolean;
    function deleteCurrentFile(Shift: TShiftState): boolean;
    function deleteThisFile(AFilePath: string; Shift: TShiftState): boolean;
    function doCentreWindow: boolean;
    function doCommandLine(aCommandLIne: string): boolean;
    function doMiniWindow: boolean;
    function doMuteUnmute: boolean;
    function doPausePlay: boolean;
    function fetchMediaMetaData: boolean;
    function findMediaFilesInFolder(aFilePath: string; aFileList: TList<string>; MinFileSize: int64 = 0): integer;
    function formatSeconds(seconds: integer): string;
    function fullScreen: boolean;
    function getFileSize(const aFilePath: string): int64;
    function getINIname: string;
    function goDown: boolean;
    function goLeft: boolean;
    function goRight: boolean;
    function goUp: boolean;
    function greaterWindow(Shift: TShiftState): boolean;
    function hasMediaFiles: boolean;
    function hasMetaData: boolean;
    function isAltKeyDown: boolean;
    function isCapsLockOn: boolean;
    function isControlKeyDown: boolean;
    function isLastFile: boolean;
    function isShiftKeyDown: boolean;
    function isVideoOffscreen: boolean;
    function keepCurrentFile: boolean;
    function matchVideoWidth: boolean;
    function noMediaFiles: boolean;
    function openWithShotcut: boolean;
    function playCurrentFile: boolean;
    function playFirstFile: boolean;
    function playLastFile: boolean;
    function playNextFile: boolean;
    function playPrevFile: boolean;
    function playWithPotPlayer: boolean;
    function rateReset: boolean;
    function reloadMediaFiles: boolean;
    function renameCurrentFile: boolean;
    function resumeBookmark: boolean;
    function sampleVideo: boolean;
    function saveBookmark: boolean;
    function ShowOKCancelMsgDlg(aMsg: string;
                                msgDlgType: TMsgDlgType = mtConfirmation;
                                msgDlgButtons: TMsgDlgButtons = MBOKCANCEL;
                                defButton: TMsgDlgBtn = MBCANCEL): TModalResult;
    function speedDecrease(Shift: TShiftState): boolean;
    function speedIncrease(Shift: TShiftState): boolean;
    function startOver: boolean;
    function tabForwardsBackwards(aFactor: integer = 0): boolean;
    function UIKey(var Key: Word; Shift: TShiftState; KeyUp: boolean = FALSE): boolean;
    function UIKeyDown(var Key: Word; Shift: TShiftState): boolean;
    function UIKeyUp(var Key: Word; Shift: TShiftState): boolean;
    function unZoom: boolean;
    function updateRateLabel: boolean;
    function updateTimeDisplay: boolean;
    function updateVolumeDisplay: boolean;
    function windowCaption: boolean;
    function windowMaximizeRestore: boolean;
    function WMPplay: boolean;
    function zoomIn: boolean;
    function zoomOut: boolean;
  end;

var
  FX: TFX;  // Functions
  GV: TGV;  // Global Variables

{ TFX }

function TFX.adjustAspectRatio: boolean;
// [J] = ad[J]ust aspect ratio
// This attempts to resize the window height to match its width in the same ratio as the video dimensions,
// in order to eliminate the black bars above and below the video.
// Usage: size the window to the required width then press J to ad-J-ust the window's height to match the aspect ratio
// On other diplays, the magic numbers may need to be configured via an application INI file.
var
  X, Y:         integer;
  vRatio:       double;
  vHeightTitle: integer;
  vDelta:       integer;
begin
  case noMediaFiles of TRUE: EXIT; end;

  X := UI.WMP.currentMedia.imageSourceWidth;
  Y := UI.WMP.currentMedia.imageSourceHeight;

  case (X = 0) OR (Y = 0) of TRUE: EXIT; end;

  vRatio := Y / X;

  UI.Height := trunc(UI.Width * vRatio);
end;

function TFX.blackOut: boolean;
// [B] = [B]lackout i.e. Show/Hide Progress[B]ar
begin
  GV.blackOut             := NOT GV.blackOut;
  UI.progressBar.Visible  := NOT GV.blackOut;
  UI.repositionWMP;
  UI.repositionLabels;
end;

function TFX.clearMediaMetaData: boolean;
// palette cleanser :D
// performed each time a new video is played or unpaused
begin
  UI.lblXY.Caption            := format('XY:', []);
  UI.lblXY2.Caption           := format('XY:', []);
  UI.lblFrameRate.Caption     := format('FR:', []);
  UI.lblBitRate.Caption       := format('BR:', []);
  UI.lblAudioBitRate.Caption  := format('AR:', []);
  UI.lblVideoBitRate.Caption  := format('VR:', []);
  UI.lblXYRatio.Caption       := format('XY:', []);
  UI.lblFileSize.Caption      := format('FS:', []);
end;

function TFX.clipboardCurrentFileName: boolean;
// [=] copy name of current video file (without the extension) to the clipboard
// This can be useful, before opening the file in ShotCut, for naming the edited video
begin
  clipboard.AsText := TPath.GetFileNameWithoutExtension(currentFilePath);
end;

function TFX.currentFilePath: string;
// returns the current file in the list
begin
  case noMediaFiles of TRUE: EXIT; end;
  result := GV.playlist[GV.playIx];
end;

function TFX.Delay(dwMilliseconds: DWORD): boolean;
// Used to delay an operation; "sleep()" would suspend the thread, which is not what is required
var
  iStart, iStop: DWORD;
begin
  iStart := GetTickCount;
  repeat
    iStop  := GetTickCount;
    Application.ProcessMessages;
  until (iStop  -  iStart) >= dwMilliseconds;
end;

function TFX.deleteBookmark: boolean;
begin
  DeleteFile(getINIname);
  UI.showInfo('bookmark deleted');
end;

function TFX.deleteCurrentFile(Shift: TShiftState): boolean;
// [D] / DEL = [D]elete the current file
// Ctrl-D / Ctrl-DEL = Delete the entire contents of the current file's folder (doesn't touch subfolders)
begin
  case noMediaFiles of TRUE: EXIT; end;

  UI.WMP.controls.pause;
  var vMsg := 'DELETE '#13#10#13#10'Folder: ' + ExtractFilePath(currentFilePath);
  case ssCtrl in Shift of  TRUE: vMsg := vMsg + '*.*';
                          FALSE: vMsg := vMsg + #13#10#13#10'File: ' + ExtractFileName(currentFilePath); end;

  case showOkCancelMsgDlg(vMsg) = IDOK of
    TRUE: begin
            deleteThisFile(currentFilePath, Shift);

            case isLastFile or (ssCtrl in Shift) of TRUE: begin UI.CLOSE; EXIT; end;end;  // close app after deleting final file or deleting folder contents

            GV.playlist.Delete(GV.playIx);
            GV.playIx := GV.playIx - 1;

            playNextFile;
          end;
  end;
end;

function TFX.deleteThisFile(AFilePath: string; Shift: TShiftState): boolean;
// performs (in a separate process) the actual file/folder deletion initiated by deleteCurrentFile
begin
  case ssCtrl in Shift of  TRUE: doCommandLine('rot -nobanner -p 1 -r "' + ExtractFilePath(AFilePath) + '*.* "'); // folder contents but not subfolders
                          FALSE: doCommandLine('rot -nobanner -p 1 -r "' + AFilePath + '"'); end;                 // one individual file
end;

function TFX.doCentreWindow: boolean;
// [H] = [H]orizontal
// Position the window centrally, both horizontally and vertically.
// Originally, the window was only positioned horizontally, hence [H].
// Later, this was changed to centre the window on the screen.
var
  vR: TRect;
begin
  GetWindowRect(UI.Handle, vR);

  SetWindowPos(UI.Handle, 0,  (GetSystemMetrics(SM_CXVIRTUALSCREEN) - (vR.Right - vR.Left)) div 2,
                              (GetSystemMetrics(SM_CYVIRTUALSCREEN) - (vR.Bottom - vR.Top)) div 2, 0, 0, SWP_NOZORDER + SWP_NOSIZE);
end;

function TFX.doCommandLine(aCommandLIne: string): boolean;
// Create a cmd.exe process to execute any command line
// "Current Directory" defaults to the folder containing this application's executable.
var
  vStartInfo:  TStartupInfo;
  vProcInfo:   TProcessInformation;
begin
  result := FALSE;
  case trim(aCommandLIne) = ''  of TRUE: EXIT; end;

  FillChar(vStartInfo,  SizeOf(TStartupInfo), #0);
  FillChar(vProcInfo,   SizeOf(TProcessInformation), #0);
  vStartInfo.cb          := SizeOf(TStartupInfo);
  vStartInfo.wShowWindow := SW_HIDE;
  vStartInfo.dwFlags     := STARTF_USESHOWWINDOW;

  var vCmd := 'c:\windows\system32\cmd.exe';
  var vParams := '/c ' + aCommandLIne;

  result := CreateProcess(PWideChar(vCmd), PWideChar(vParams), nil, nil, FALSE,
                          CREATE_NEW_PROCESS_GROUP + NORMAL_PRIORITY_CLASS, nil, PWideChar(GV.exePath), vStartInfo, vProcInfo);
end;

function TFX.doMiniWindow: boolean;
// [4] = Mini Window top right corner of screen, to one of the [4] corners
var
  vR: TRect;
begin
  GetWindowRect(UI.Handle, vR);
  SetWindowPos(UI.Handle, 0,  (GetSystemMetrics(SM_CXVIRTUALSCREEN) - (vR.Right - vR.Left)) div 2,
                              (GetSystemMetrics(SM_CYVIRTUALSCREEN) - (vR.Bottom - vR.Top)) div 2, 400, 400, SWP_NOZORDER);
  adjustAspectRatio;

  GetWindowRect(UI.Handle, vR);
  SetWindowPos(UI.Handle, 0,  (GetSystemMetrics(SM_CXVIRTUALSCREEN) - UI.Width - 18),
                              (0 + 30), 0, 0, SWP_NOZORDER + SWP_NOSIZE);
end;

function TFX.doMuteUnmute: boolean;
// [E]ars = mute / unmute system sound
begin
  GV.mute       := NOT GV.mute;
  g_mixer.muted := GV.mute;
end;

function TFX.doPausePlay: boolean;
// [SpaceBar] or double-click on video = Pause / Play
begin
  case UI.WMP.playState of
                          wmppsPlaying:   UI.WMP.controls.pause;
                          wmppsPaused,
                          wmppsStopped:   WMPplay; end;
end;

function TFX.fetchMediaMetaData: boolean;
// Called from the tmrMetaDataTimer event handler.
// There is a delay after a video starts playing before its metadata becomes available.
// Consequently, when a video starts playing, tmrMetaData is started to delay an attempt to access it.
// For some very large media files, e.g. 7GB, WMP doesn't report a file size(!), so we do it ourselves.
begin
  UI.lblXY.Caption                := format('XY:  %s x %s', [UI.WMP.currentMedia.getItemInfo('WM/VideoWidth'), UI.WMP.currentMedia.getItemInfo('WM/VideoHeight')]);
  case trim(UI.lblXY.Caption) = 'XY:   x' of TRUE: UI.lblXY.Caption := 'XY:'; end;
  UI.lblXY2.Caption               := format('XY:  %d x %d', [UI.WMP.currentMedia.imageSourceWidth, UI.WMP.currentMedia.imageSourceHeight]);
  try UI.lblFrameRate.Caption     := format('FR:  %f fps', [StrToFloat(UI.WMP.currentMedia.getItemInfo('FrameRate')) / 1000]); except end;
  try UI.lblBitRate.Caption       := format('BR:  %d Kb/s', [trunc(StrToFloat(UI.WMP.currentMedia.getItemInfo('BitRate')) / 1024)]); except end;
  try UI.lblAudioBitRate.Caption  := format('AR:  %d Kb/s', [trunc(StrToFloat(UI.WMP.currentMedia.getItemInfo('AudioBitRate')) / 1024)]); except end;
  try UI.lblVideoBitRate.Caption  := format('VR:  %d Kb/s', [trunc(StrToFloat(UI.WMP.currentMedia.getItemInfo('VideoBitRate')) / 1024)]); except end;
  try UI.lblXYRatio.Caption       := format('XY:  %s:%s', [UI.WMP.currentMedia.getItemInfo('PixelAspectRatioX'), UI.WMP.currentMedia.getItemInfo('PixelAspectRatioY')]); except end;

  var vSize := getFileSize(currentFilePath);
  case vSize >= 1052266987 of  TRUE:   try UI.lblFileSize.Caption := format('FS:  %.3f GB', [vSize / 1024 / 1024 / 1024]); except end;  // >= 0.98 of 1GB
                              FALSE:   try UI.lblFileSize.Caption := format('FS:  %d MB', [trunc(vSize / 1024 / 1024)]); except end;end;
end;

function TFX.findMediaFilesInFolder(aFilePath: string; aFileList: TList<string>; MinFileSize: int64 = 0): integer;
// Called from FormCreate and reloadVideoFiles.
// Standard Functionality: Clicking a video file type associated with this application causes MediaPlayer to run and play the video.
// All supported video file types in that video's folder will be added to aFileList (subfolders aren't processed).
// The function returns the aFileList index of the clicked video file.
// This list of supported file types was created manually after confirming they are playable by Windows Media Player.
// It sometimes has problems playing an flv video but, bizarrely, will play it if the file is renamed to, for example, .m4v
// PotPlayer has no such problems playing the same .flv video.
const EXTS_FILTER = '.wmv.mp4.avi.flv.mpg.mpeg.mkv.3gp.mov.m4v.vob.ts.webm.divx.m4a.mp3.wav.aac.m2ts.flac.mts.rm.asf';
var
  sr:           TSearchRec;
  vFolderPath:  string;

  function isFileSizeOK: boolean;
  // If a minimum file size has been stipulated by the caller, this filters out those that don't apply
  begin
    result := (MinFileSize <= 0) OR (AFilePath = vFolderPath + sr.Name) OR (GetFileSize(vFolderPath + sr.Name) >= MinFileSize);
  end;

  function isFileExtOK: boolean;
  // Filter out all but the explicity-supported file types
  begin
    result := EXTS_FILTER.Contains(LowerCase(ExtractFileExt(sr.Name)));
  end;
begin
  result := -1;
  case FileExists(AFilePath) of FALSE: EXIT; end;

  aFileList.Clear;
  aFileList.Sort;

  vFolderPath := ExtractFilePath(AFilePath);

  case FindFirst(vFolderPath + '*.*', faAnyFile, sr) = 0 of  TRUE:
    repeat
      case (sr.Attr AND faDirectory) = faDirectory of FALSE:
        case isFileSizeOK AND isFileExtOK of TRUE: aFileList.Add(vFolderPath + sr.Name); end;end;
    until FindNext(sr) <> 0;
  end;

  FindClose(sr);

  aFileList.Sort;
  result := aFileList.IndexOf(aFilePath);
end;

function TFX.formatSeconds(seconds: integer): string;
begin
  case seconds < 60 of  TRUE: result := format('%ds', [seconds]);
                       FALSE: result := format('%d:%.2d', [seconds div 60, seconds mod 60]);
  end;
end;

function TFX.fullScreen: boolean;
// [F] = Tell WMP to diplay fullScreen.
// The video timestamp and metadata displays etc. won't show until fullScreen mode is exited.
begin
  case noMediaFiles of TRUE: EXIT; end;

  case UI.WMP.fullScreen of   TRUE: UI.WMP.fullScreen := FALSE;
                             FALSE: UI.WMP.fullScreen := TRUE;  end;
end;

function TFX.getFileSize(const aFilePath: string): int64;
var
  vHandle:  THandle;
  vRec:     TWin32FindData;
begin
  vHandle := FindFirstFile(PChar(aFilePath), vRec);
  case vHandle <> INVALID_HANDLE_VALUE of TRUE: begin
                                                  WinAPI.Windows.FindClose(vHandle);
                                                  case (vRec.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 of TRUE:
                                                    result := (Int64(vRec.nFileSizeHigh) shl 32) + vRec.nFileSizeLow; end;end;end;
end;

function TFX.getINIname: string;
// A video timestamp bookmark can be saved to and retrieved from an INI file, named after the video file.
begin
  result := ExtractFileName(currentFilePath);
  result := ChangeFileExt(result, '.ini');
  result := ExtractFilePath(currentFilePath) + result;
end;

// When the video is zoomed in or out, the CTRL key plus the UP, DOWN, LEFT, RIGHT arrow keys can be used to reposition the video
// Bizarrely, if WMP is paused and repositioned, it will revert its position when playback is resumed;
//            if WMP is repositioned during zoomed playback then paused, it will revert its position.
const MOVE_PIXELS = 10;
function TFX.goDown: boolean;
begin
  UI.WMP.Top := UI.WMP.Top + MOVE_PIXELS;
end;

function TFX.goLeft: boolean;
begin
  UI.WMP.Left := UI.WMP.Left - MOVE_PIXELS;
end;

function TFX.goRight: boolean;
begin
  UI.WMP.Left := UI.WMP.left + MOVE_PIXELS;
end;

function TFX.goUp: boolean;
begin
  UI.WMP.Top := UI.WMP.Top - MOVE_PIXELS;
end;

function TFX.hasMediaFiles: boolean;
begin
  result := GV.playlist.Count > 0;
end;

function TFX.hasMetaData: boolean;
// is the media file's meta data ready to be accessed from WMP
begin
  result := (UI.WMP.currentMedia.imageSourceWidth <> 0) AND (UI.WMP.currentMedia.imageSourceHeight <> 0);
end;

function TFX.isAltKeyDown: boolean;
// Did the user hold down the ALT key while pressing another key?
begin
  result := (GetKeyState(VK_MENU) AND $80) <> 0;
end;

function TFX.isCapsLockOn: boolean;
// Is the CAPS LOCK key toggled on?
begin
  result := GetKeyState(VK_CAPITAL) <> 0;
end;

function TFX.isControlKeyDown: boolean;
// Did the user hold down the CTRL key while pressing another key?
//
// see VCL.Forms.KeyboardStateToShiftState and KeyDataToShiftState
// If the high-order bit is 1, the key is down, otherwise it is up.
// If the low-order bit is 1, the key is toggled.
// A key, such as the CAPS LOCK key, is toggled if it is turned on.
// The key is off and untoggled if the low-order bit is 0.
// A toggled key's indicator light (if any) on the keyboard will be on when the key is toggled, and off when the key is untoggled.
// Check high-order bit of state...
begin
  result := (GetKeyState(VK_CONTROL) AND $80) <> 0;
end;

function TFX.isLastFile: boolean;
// Is the current video file the last in the list?
begin
  result := GV.playIx = GV.playlist.Count - 1;
end;

function TFX.isShiftKeyDown: boolean;
// Did the user hold down a SHIFT key while pressing another key?
begin
  result := (GetKeyState(VK_SHIFT) AND $80) <> 0;
end;

function TFX.isVideoOffscreen: boolean;
var
  vR: TRect;
  vS: TRect;
begin
  GetWindowRect(UI.Handle, vR);

  vS :=  UI.ClientToScreen(vR);

  result := vS.Bottom > GetSystemMetrics(SM_CYVIRTUALSCREEN);
end;

function TFX.keepCurrentFile: boolean;
// [K] = [K]eep current file
// When examining a folder to determine which videos to keep or delete,
//    this provides a convenient way to mark a video to be kept by renaming the file, prefixing an underscore to its filename.
// This causes all such files to gravitate to the top of the displayed folder thus making it easy to select all the other files and delete them.
// Occasionally, Windows or WMP will prevent the file from being renamed while WMP has it open.
// There is no apparent pattern to when the rename is allowed and when it isn't.
begin
  case noMediaFiles of TRUE: EXIT; end;

  UI.WMP.controls.pause;
  delay(250);   // give WMP time to register internally that the video has been paused (delay() doesn't "sleep()" the thread).
  var vFileName := '_' + ExtractFileName(currentFilePath);
  var vFilePath := ExtractFilePath(currentFilePath) + vFileName;
  case RenameFile(currentFilePath, vFilePath) of FALSE: ShowMessage('Rename failed:' + #13#10 +  SysErrorMessage(getlasterror));
                                                  TRUE: GV.playlist[GV.playIx] {currentFilePath} := vFilePath; end; // reflect the new name in the list
  windowCaption;
  UI.WMP.controls.play;
end;

function TFX.matchVideoWidth: boolean;
// [9] = resize the width of the window to match the video width.
// Judicious use of [9], ad[J]ust, [H]orizontal and [G]reater can be used to obtain the optimum window to match the video.
begin
  case noMediaFiles of TRUE: EXIT; end;

  var X := UI.WMP.currentMedia.imageSourceWidth;
  var Y := UI.WMP.currentMedia.imageSourceHeight;

  UI.Width := X;
end;

function TFX.noMediaFiles: boolean;
begin
  result := GV.playlist.Count = 0;
end;

function TFX.openWithShotcut: boolean;
// [F12] = open the video in the ShotCut* video editor
// mklink C:\ProgramFiles "C:\Program Files"
// The above command line allows C:\Program Files\ to be referenced in programs without the annoying space.
// This can simpifly things when multiple nested double quotes and apostrophes are being used to construct a command line
// At some point, the user's preferred video editor needs to be configurable via an application INI file.
// *https://shotcut.org/
begin
  case noMediaFiles of TRUE: EXIT; end;

  UI.WMP.controls.pause;
  doCommandLine('C:\ProgramFiles\Shotcut\shotcut.exe "' + currentFilePath + '"');
end;

function TFX.playCurrentFile: boolean;
// CurrentFile is the one whose index in the playList equals playIx
begin
  case GV.invalidPlayIx of TRUE: EXIT; end;             // sanity check

  case FileExists(currentFilePath) of TRUE: begin       // i.e. if file *still* exists :D
    windowCaption;

    UI.lblMediaCaption.Visible  := TRUE;

    // If the user switches several media files quickly in succession, we need to cancel the previous timer event and re-enable the timer,
    // otherwise tmrMediaCaptionTimer will prematurely cancel the display of this media file's caption.
    UI.tmrMediaCaption.Enabled  := FALSE;
    UI.tmrMediaCaption.Enabled  := TRUE;

    UI.WMP.URL := 'file://' + currentFilePath;
    unZoom;
    GV.newMediaFile   := TRUE;
    GV.metaDataCount  := 0;     // tmrMetaData will be enabled in WMPplay after playback commences
    WMPplay;
  end;end;
end;

function TFX.playFirstFile: boolean;
// [A] = play the first video in the list
begin
  case hasMediaFiles of TRUE: begin
                                GV.playIx := 0;
                                playCurrentFile;
                              end;end;
end;

function TFX.playLastFile: boolean;
// [Z] = play the last video in the list
begin
  case hasMediaFiles of TRUE: begin
                                GV.playIx := GV.playlist.Count - 1;
                                playCurrentFile;
                              end;end;
end;

function TFX.playNextFile: boolean;
// W = [W]atch the next video in the list
begin
  case isLastFile of TRUE: begin UI.CLOSE; EXIT; end;end;

  GV.playIx := GV.playIx + 1;
  playCurrentFile;
end;

function TFX.playPrevFile: boolean;
// [Q] = play the previous video in the list
begin
  case GV.playIx > 0 of TRUE:   begin
                                  GV.playIx := GV.playIx - 1;
                                  playCurrentFile;
                                end;
  end;
end;

function TFX.playWithPotPlayer: boolean;
// [P] = Play with [P]otPlayer
// At some point, the user's preferred alternative media player needs to be picked up from a mediaplayer.ini file
begin
  UI.WMP.controls.pause;
  doCommandLine('B:\Tools\Pot\PotPlayerMini64.exe "' + currentFilePath + '"');
end;

function TFX.rateReset: boolean;
// [1] = reset the playback rate to 100%
begin
  UI.WMP.settings.rate    := 1;
  FX.updateRateLabel;
end;

function TFX.reloadMediaFiles: boolean;
// [L] = re[L]oad the list of video files from the current folder
// Previously, a facility existed whereby if MediaPlayer was launched with the CAPS LOCK key on,
//    only video files greater than 100MB in size would be loaded into the file list.
// This allowed folders to be examined to quicly keep or delete the largest videos.
// This reloadMediaFiles function could than be used to re-find all files in the current folder regardless of size,
//    without having to close and restart the app *without* the CAPS LOCK key on.
// Typically, this was actually because the user had launched MediaPlayer forgetting that the CAPS LOCK key was on.
// The CAPS LOCK key has now been repurposed for something else (see FormCreate) so for the time being this function isn't as useful as it was.
begin
  GV.playIx := findMediaFilesInFolder(currentFilePath, GV.playlist);
  windowCaption;
end;

function TFX.renameCurrentFile: boolean;
// [R] = [R]ename current file
// Occasionally, Windows or WMP will prevent the file from being renamed while WMP has it open.
// There is no apparent pattern to when the rename is allowed and when it isn't.
var
  vOldFileName: string;
  vExt:         string;
  s:            string;
  vNewFilePath: string;
begin
  case noMediaFiles of TRUE: EXIT; end;

  UI.WMP.controls.pause;
  try
    vOldFileName  := ExtractFileName(currentFilePath);
    vExt          := ExtractFileExt(vOldFileName);
    vOldFileName  := copy(vOldFileName, 1, pos(vExt, vOldFileName) - 1); // strip the file extension; the user can edit the main part of the filename

    GV.inputBox   := TRUE; // ignore keystrokes. Let the InputBoxForm handle them
    try
      s           := InputBoxForm(vOldFileName); // the form returns the edited filename or the original if the user pressed cancel
    finally
      GV.inputBox := FALSE;
    end;
  except
    s := '';   // any funny business, force the rename to be abandoned
  end;
  case (s = '') OR (s = vOldFileName) of TRUE: EXIT; end; // nothing to do

  vNewFilePath := ExtractFilePath(currentFilePath) + s + vExt;  // construct the full path and new filename with the original extension
  case RenameFile(currentFilePath, vNewFilePath) of FALSE: ShowMessage('Rename failed:' + #13#10 +  SysErrorMessage(getlasterror));
                                                         TRUE: GV.playlist[GV.playIx] {currentFilePath} := vNewFilePath; end;
  windowCaption; // update the caption with the new name
end;

function TFX.greaterWindow(Shift: TShiftState): boolean;
// [G]reater  = increase size of window
// Ctrl-G     = decrease size of window
begin
  UI.resizeWindow3(Shift);
  adjustAspectRatio;
  doCentreWindow;
  windowCaption;
end;

function TFX.resumeBookmark: boolean;
// [6] = read the saved video position from the INI file and continue playing from that position
begin
  case noMediaFiles of TRUE: EXIT; end;

  case FileExists(getINIname) of FALSE: begin UI.showInfo('no bookmark'); EXIT; end;end;

  var sl := TStringList.Create;
  sl.LoadFromFile(getINIname);
  UI.WMP.controls.currentPosition := StrToFloat(sl[0]);
  sl.Free;
  UI.showInfo('resumed from bookmark');
end;

function TFX.sampleVideo: boolean;
// [Y] = sample/tr[Y]out the video by playing a few seconds then skipping 10% of the video
// This will stop once the current video position is more than 90% the way through the video
// If the next video is played, sampling will continue until Y is pressed again to cancel sampling
begin
  case noMediaFiles of TRUE: EXIT; end;
  case GV.sampling of TRUE: begin GV.sampling := FALSE; EXIT; end;end;

  GV.sampling := TRUE;
  try
    repeat
      UI.WMP.controls.currentPosition := UI.WMP.controls.currentPosition + (UI.WMP.currentMedia.duration / 10);
      delay(3000); // let the video play for 3 seconds before skipping (delay() doesn't "sleep()" the thread).
    until GV.Closing OR NOT GV.sampling OR (UI.WMP.controls.currentPosition >= (UI.wmp.currentMedia.duration * 0.90));
  finally
  end;
end;

function TFX.saveBookmark: boolean;
// [5] = save current video position to an ini file
begin
  case noMediaFiles of TRUE: EXIT; end;

  case FileExists(getINIname) of
    TRUE: case MessageDlg('Do you want to overwrite the previous bookmark?', TMsgDlgType.mtConfirmation, [mbYes, mbNo], 0) = mrNo of TRUE: EXIT; end;end;

  var sl := TStringList.Create;
  sl.Add(FloatToStr(UI.WMP.controls.currentPosition));
  sl.SaveToFile(getINIname);
  sl.Free;
  UI.showInfo('bookmarked');
end;

function TFX.speedDecrease(Shift: TShiftState): boolean;
// Ctrl-DownArrow = decrease playback speed by 10%
begin
  case ssCtrl in Shift of FALSE: EXIT; end;

  UI.WMP.settings.rate := UI.WMP.settings.rate - 0.1;
  FX.updateRateLabel;
end;

function TFX.speedIncrease(Shift: TShiftState): boolean;
// Ctrl-UpArrow = increase playback speed by 10%
begin
  case ssCtrl in Shift of FALSE: EXIT; end;

  UI.WMP.settings.rate := UI.WMP.settings.rate + 0.1;
  FX.updateRateLabel;
end;

function TFX.startOver: boolean;
// [S] = StartOver; play the current video from the beginning
begin
  case noMediaFiles of TRUE: EXIT; end;

  UI.WMP.controls.currentPosition := 0;
  UI.WMP.controls.play;
end;

function TFX.tabForwardsBackwards(aFactor: integer = 0): boolean;
// [T] = Tab Forward or Ctrl-T = Tab Backward through a fraction of the video.
// The fraction to jump can be modified using the following keys:
//    TAB key             = 200th
//    T (default)         = 100th
//    ALT-T               = 50th
//    SHIFT-T             = 20th
//    T with CAPS LOCK on = 10th
//  CTRL = reverse
var
  vFactor: integer;
begin
  case noMediaFiles of TRUE: EXIT; end;

  case aFactor <> 0 of  TRUE: vFactor := aFactor;
                       FALSE: case isShiftKeyDown of
                                 TRUE: vFactor := 20;
                                FALSE: case isAltKeyDown of
                                          TRUE: vFactor := 50;
                                         FALSE: case isCapsLockOn of
                                                  TRUE: vFactor := 10;
                                                 FALSE: vFactor := 100;
  end;end;end;end;

  case isControlKeyDown of
    TRUE: UI.WMP.controls.currentPosition := UI.WMP.controls.currentPosition - (UI.WMP.currentMedia.duration / vFactor);
   FALSE: UI.WMP.controls.currentPosition := UI.WMP.controls.currentPosition + (UI.WMP.currentMedia.duration / vFactor);
  end;

  var newInfo := format('%dth = %s', [vFactor, formatSeconds(round(UI.WMP.currentMedia.duration / vFactor))]);
  case isControlKeyDown of  TRUE: newInfo := '<< ' + newInfo;
                           FALSE: newInfo := '>> ' + newInfo;
  end;
  UI.showInfo(newInfo);        // confirm the fraction jumped (and the direction) for the user
end;

function TFX.UIKey(var Key: Word; Shift: TShiftState; KeyUp: boolean = FALSE): boolean;
// Keys that can be pressed singly or held down for repeat action
begin
  result := TRUE;

  case (ssCtrl in Shift) AND GV.zoomed of                                // when zoomed, Ctrl-up/down/left/right moves the video around the window
     TRUE:  case key in [VK_RIGHT, VK_LEFT, VK_UP, VK_DOWN] of
               TRUE:  begin
                        case KeyUp of TRUE: EXIT; end;                  // don't allow KeyUp to repeat the KeyDown action
                        case Key of
                          VK_RIGHT:     FX.GoRight;                      // Move zoomed WMP right
                          VK_LEFT:      FX.GoLeft;                       // Move zoomed WMP left
                          VK_UP:        FX.GoUp;                         // Move zoomed WMP up
                          VK_DOWN:      FX.GoDown;                       // Move zoomed WMP down
                        end;
                        Key := 0;
                        EXIT;
                      end;end;end;

  case (NOT (ssCtrl in Shift)) AND (NOT GV.zoomed) of                    // when not zoomed, up/down increases or decreases the volume by 1%
     TRUE:  case Key in [VK_UP, VK_DOWN] of
               TRUE:  begin
                        case KeyUp of TRUE: EXIT; end;                   // don't allow KeyUp to repeat the KeyDown action
                        case Key of
                          VK_UP:   g_mixer.Volume := g_mixer.Volume + (65535 div 100);  // volume up 1%
                          VK_DOWN: g_mixer.Volume := g_mixer.Volume - (65535 div 100);  // volume down 1%
                        end;
                        UpdateVolumeDisplay;
                        Key := 0;
                        EXIT;
                      end;end;end;

  case Key in [VK_RIGHT, VK_LEFT, ord('i'), ord('I'), ord('o'), ord('O')] of
     TRUE:  begin
              case KeyUp of TRUE: EXIT; end;                             // don't allow KeyUp to repeat the KeyDown action
              case Key of
                VK_RIGHT: IWMPControls2(UI.WMP.controls).step(1);        // Frame forwards   - generally, yes
                VK_LEFT:  IWMPControls2(UI.WMP.controls).step(-1);       // Frame backwards  - WMP goes back about 1 second not 1 frame!
                ord('i'), ord('I'): FX.ZoomIn;                           // Zoom [I]n
                ord('o'), ord('O'): FX.ZoomOut;                          // Zoom [O]ut
              end;
              Key := 0;
              EXIT
            end;end;

  result := FALSE;
end;

function TFX.UIKeyDown(var Key: Word; Shift: TShiftState): boolean;
begin
  UIKey(Key, Shift);
end;

function TFX.UIKeyUp(var Key: Word; Shift: TShiftState): boolean;
begin
try
//  case key = 18 of TRUE: tabForwardsBackwards(50); end;
  case UIKey(Key, Shift, TRUE) of TRUE: EXIT; end;  // Keys that can be pressed singly or held down for repeat action: don't process the KeyUp as well as the KeyDown

  case Key of
    VK_ESCAPE: case UI.WMP.fullScreen of  TRUE: fullScreen;    // eXit fullscreen mode, or...
                                         FALSE: UI.CLOSE; end; // eXit app

    VK_SPACE:  doPausePlay;                         // Pause / Play

    VK_UP:            SpeedIncrease(Shift);         // Ctrl-UpArrow = Speed up
    VK_DOWN:          SpeedDecrease(Shift);         // Ctrl-DnArrow = Slow down
    191 {Slash}:      SpeedIncrease([ssCtrl]);      // Ctrl-UpArrow = Speed up
    220 {Backslash}:  SpeedDecrease([ssCtrl]);      // Ctrl-DnArrow = Slow down

    VK_F12: openWithShotcut;

    9:                  tabForwardsBackwards(200);            // TAB tab forwards/backwards 1/200th   Mods: Ctrl-TAB
    187               : clipboardCurrentFileName;             // =   copy current filename to clipboard
    ord('a'), ord('A'): PlayFirstFile;                        // A = Play first
    ord('b'), ord('B'): BlackOut;                             // B = Blackout                       Mods: Ctrl-B
    ord('c'), ord('C'): UI.ToggleControls(Shift);             // C = Control Panel show/hide        Mods: Ctrl-C
    ord('d'), ord('D'), VK_DELETE: deleteCurrentFile(Shift);  // D = Delete File                    Mods: Ctrl-D / Ctrl-DEL
    ord('e'), ord('E'): DoMuteUnmute;                         // E = (Ears)Mute/Unmute
    ord('f'), ord('F'): fullScreen;                           // F = Fullscreen
    ord('g'), ord('G'): greaterWindow(Shift);                 // G = Greater window size            Mods: Ctrl-G
    ord('h'), ord('H'): doCentreWindow;                       // H = centre window Horizontally
                                                              // I = zoom In
    ord('j'), ord('J'): adjustAspectRatio;                    // J = adJust aspect ratio
    ord('k'), ord('K'): keepCurrentFile;                      // K = Keep current file
    ord('l'), ord('L'): reloadMediaFiles;                     // L = re-Load media files
    ord('m'), ord('M'): WindowMaximizeRestore;                // M = Maximize/Restore
    ord('n'), ord('N'): application.Minimize;                 // N = miNimize
                                                              // O = zoom Out
    ord('p'), ord('P'): PlayWithPotPlayer;                    // P = Play current video with Pot Player
    ord('q'), ord('Q'): PlayPrevFile;                         // Q = Play previous in folder
    ord('r'), ord('R'): RenameCurrentFile;                    // R = Rename
    ord('s'), ord('S'): startOver;                            // S = Start-over
    ord('t'), ord('T'): TabForwardsBackwards;                 // T = Tab forwards/backwards n%      Mods: ALT-T, SHIFT-T, CAPSLOCK, Ctrl-T
    ord('u'), ord('U'): UnZoom;                               // U = Unzoom
    ord('v'), ord('V'): WindowMaximizeRestore;                // V = View Maximize/Restore
    ord('w'), ord('W'): PlayNextFile;                         // W = Watch next in folder
    ord('x'), ord('X'): UI.CLOSE;                             // X = eXit app
    ord('y'), ord('Y'): sampleVideo;                          // Y = trYout video
    ord('z'), ord('Z'): PlayLastFile;                         // Z = Play last in folder
    ord('0')          : UI.showMediaCaption;                  // 0 = briefly show media caption
    ord('1')          : RateReset;                            // 1 = Rate 1[00%]
    ord('2')          : UI.ResizeWindow2;                     // 2 = resize so that two videos can be positioned side-by-side horizontally by the user
    ord('4')          : doMiniWindow;                         // 4 = mini window top right corner of screen
    ord('5')          : saveBookmark;                         // 5 = save current media position to an INI file     (bookmark)
    ord('6')          : resumeBookmark;                       // 6 = resume video from saved media position         (bookmark)
    ord('7')          : deleteBookmark;                       // 7 = delete INI file containing bookmarked position (bookmark)
    ord('8')          : UI.repositionWMP;                     // 8 = reposition WMP to eliminate border pixels
    ord('9')          : matchVideoWidth;                      // 9 = match window width to video width
  end;
finally
  UpdateTimeDisplay;
  Key := 0;
end;
end;

function TFX.unZoom: boolean;
// [U] = [U]nzoom; re-fit the video to the window
begin
  GV.zoomed := FALSE;
  UI.repositionWMP;
  UI.Width := UI.Width + 1; // fix bizarre problem of WMP not repositioning after zooming
  UI.Width := UI.Width - 1; // fix bizarre problem of WMP not repositioning after zooming
end;

function TFX.updateRateLabel: boolean;
// Confirm to the user the new playback rate/speed.
// We briefly delay accessing the new rate so that it registers internally within WMP, otherwise we'll still get the old rate
begin
  delay(100);             // delay() doesn't "sleep()"/suspend the thread
  UI.showInfo(IntToStr(round(UI.WMP.settings.rate * 100)) + '%');
end;

function TFX.updateTimeDisplay: boolean;
// Update the video timestamp display regardless of whether it's visible or not
// Also update the progress bar to match the current video position
begin
  case noMediaFiles of TRUE: EXIT; end;

  UI.lblTimeDisplay.Caption := UI.WMP.controls.currentPositionString + ' / ' + UI.WMP.currentMedia.durationString;

  UI.ProgressBar.Max        := trunc(UI.WMP.currentMedia.duration);
  UI.ProgressBar.Position   := trunc(UI.WMP.controls.currentPosition);
end;

function TFX.updateVolumeDisplay: boolean;
begin
  UI.showInfo(IntToStr(trunc(g_mixer.volume / 65535 * 100))  + '%'); // briefly confirm the new volume setting for the user
end;

function TFX.windowCaption: boolean;
begin
  case noMediaFiles of TRUE: EXIT; end;

  UI.Caption                  := format('[%d/%d] %s', [GV.playIx + 1, GV.playlist.Count, ExtractFileName(currentFilePath)]);
  UI.lblMediaCaption.Caption  := UI.Caption;
end;

function TFX.windowMaximizeRestore: boolean;
// [M] = [M]aximize/Restore window
// [V] = Maximize/Restore window/[V]iew
begin
  case UI.WindowState = wsMaximized of TRUE: UI.WindowState := wsNormal;
                                      FALSE: UI.WindowState := wsMaximized; end;
end;

function TFX.WMPplay: boolean;
// Called to both start and resume the playing of a video
begin
  case noMediaFiles of TRUE: EXIT; end;

  try
    clearMediaMetaData;              // "Out with the old..."
    UI.WMP.controls.play;
    UI.tmrMetaData.Enabled := TRUE;  // necessary delay before trying to access video metadata from WMP
  except begin
    ShowMessage('Oops!');
    UI.WMP.controls.stop;
  end;end;
end;

function TFX.zoomIn: boolean;
// [I] = Zoom [I]n by 10%
begin
  GV.zoomed := TRUE;

  UI.WMP.Width    := trunc(UI.WMP.Width * 1.1);
  UI.WMP.Height   := trunc(UI.WMP.Height * 1.1);
  UI.WMP.Top      := -(UI.WMP.Height - UI.Height) div 2;
  UI.WMP.Left     := -(UI.WMP.Width - UI.Width) div 2;

  UI.hideLabels;  // now that WMP's dimensions bear no relation to the window's, label positioning gets too complicated
end;

function TFX.zoomOut: boolean;
// [O] = Zoom [O]ut by 10%
begin
  GV.zoomed := TRUE;

  UI.WMP.Width    := trunc(UI.WMP.Width * 0.9);
  UI.WMP.Height   := trunc(UI.WMP.Height * 0.9);
  UI.WMP.Top      := -(UI.WMP.Height - UI.ClientHeight) div 2;
  UI.WMP.Left     := -(UI.WMP.Width - UI.ClientWidth) div 2;

  UI.hideLabels;  // now that WMP's dimensions bear no relation to the window's, label positioning gets too complicated
end;

function TFX.showOKCancelMsgDlg(aMsg: string;
                                msgDlgType: TMsgDlgType = mtConfirmation;
                                msgDlgButtons: TMsgDlgButtons = MBOKCANCEL;
                                defButton: TMsgDlgBtn = MBCANCEL): TModalResult;
// used for displaying the delete file/folder confirmation dialog
// We modify the standard dialog to make everything bigger, especially the width so that long folder names and files display properly
// The standard dialog would unhelpfully truncate them.
begin
  with CreateMessageDialog(aMsg, msgDlgType, msgDlgButtons, defButton) do
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

//===== UI Event Handlers and Functions =====

{$R *.dfm}

function TUI.addMenuItem: boolean;
var vSysMenu: HMENU;
begin
  vSysMenu := GetSystemMenu(Handle, False);
  AppendMenu(vSysMenu, MF_SEPARATOR, 0, '');
  AppendMenu(vSysMenu, MF_STRING, MENU_ID, '&About Minimalist Media Player…');
end;

procedure TUI.applicationEventsMessage(var Msg: tagMSG; var Handled: Boolean);
// main event handler for capturing keystrokes
var
  Key: word;
  shiftState: TShiftState;
begin
  case GV.inputBox of  TRUE: EXIT; end;    // don't trap keystrokes when the inputBoxForm is being displayed

  case MSG.message = WM_KEYDOWN of   TRUE:  begin
                                              shiftState  := KeyboardStateToShiftState;
                                              Key         := Msg.WParam;
                                              FX.UIKeyDown(Key, shiftState);
                                              Handled     := TRUE;
                                            end;end;
  case MSG.message = WM_KEYUP   of   TRUE:  begin
                                              shiftState  := KeyboardStateToShiftState;
                                              Key         := Msg.WParam;
                                              FX.UIKeyUp(Key, shiftState);
                                              Handled     := TRUE;
                                            end;end;
end;

procedure TUI.FormActivate(Sender: TObject);
begin
  showInfo(GV.appReleaseVersion);
end;

procedure TUI.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
// make sure to stop video playback before exiting the app or WMP can get upset
begin
  WMP.controls.stop;
  CanClose := TRUE;
  GV.Closing := TRUE;
  DragAcceptFiles(UI.Handle, FALSE);
end;

procedure TUI.FormCreate(Sender: TObject);
//var
//  TW: TWMPEqualizerSettingsCtrl;
//  EQ: IWMPEqualizerSettingsCtrl;
begin
  addMenuItem;
  SetWindowLong(UI.Handle, GWL_STYLE, GetWindowLong(UI.Handle, GWL_STYLE) OR WS_CAPTION AND (NOT (WS_BORDER)));
  DragAcceptFiles(UI.Handle, TRUE);

  case FX.isCapsLockOn of    TRUE:  resizeWindow2; // size so that two videos can be positioned side-by-side horizontally by the user
                            FALSE:  resizeWindow1; // otherwise, default size
  end;

  color := clBlack; // background color of the window's client area, so zooming-out doesn't show the design-time color

  setupProgressBar;

  case ParamCount = 0 of TRUE:  begin
                                  FX.ShowOKCancelMsgDlg('Typically, you would use "Open with..." in your File Explorer / Manager, to open a media file'#13#10
                                                      + 'or to permanently associate media file types with this application.'#13#10#13#10
                                                      + 'Alternatively, you can drag and drop a media file onto the window background',
                                                        mtInformation, [MBOK]);
                                end;end;

  WMP.uiMode          := 'none';
  WMP.windowlessVideo := TRUE;
  WMP.stretchToFit    := TRUE;
  WMP.settings.volume := 100;
//  EQ := WMP as IWMPEqualizerSettingsCtrl;
//  EQ.truBassLevel := 100;
//  TW := TWMPEqualizerSettingsCtrl.Create(self);
//  EQ := TW.GetDefaultInterface;
//  EQ.truBassLevel := 100;



// the only way for these to display is to make them child controls of WMP
  lblMediaCaption.Parent  := WMP;
  lblXY.Parent            := WMP;
  lblXY2.Parent           := WMP;
  lblFrameRate.Parent     := WMP;
  lblBitRate.Parent       := WMP;
  lblAudioBitRate.Parent  := WMP;
  lblVideoBitRate.Parent  := WMP;
  lblXYRatio.Parent       := WMP;
  lblFileSize.Parent      := WMP;
  lblInfo.Parent          := WMP;
  lblTimeDisplay.Parent   := WMP;

  lblTimeDisplay.Caption  := '';

  repositionLabels;

  case g_mixer.muted of TRUE: FX.DoMuteUnmute; end; // GV.Mute starts out FALSE; this brings it in line with the system

  case {FX.isCapsLockOn} TRUE = FALSE of            // CAPS LOCK repurposed to choose window size on startup; see start of procedure
     TRUE: GV.playIx := FX.findMediaFilesInFolder(ParamStr(1), GV.playlist, 100000000);
    FALSE: GV.playIx := FX.findMediaFilesInFolder(ParamStr(1), GV.playlist); // <==  Always executed
  end;

  FX.playCurrentFile;                               // automatically start the clicked video

  GV.startup := TRUE;                               // used in FormResize to initially left-justify the application window if required
end;

procedure TUI.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  WMP.cursor := crDefault;  // gets reset to crNone in tmrTimeDisplay event
end;

procedure TUI.FormResize(Sender: TObject);
begin
  FX.windowCaption;

  case GV.startup AND FX.isCapsLockOn of  TRUE: SetWindowPos(UI.Handle, 0, -6, 200, 0, 0, SWP_NOZORDER + SWP_NOSIZE); end; // left justify on screen
  GV.startup := FALSE;  // don't left justify the window on the screen every time the user resizes it

  repositionLabels;
  repositionWMP;
end;

function TUI.hideLabels: boolean;
// called from ZoomIn and ZoomOut
begin
  case lblTimeDisplay.Visible of TRUE: toggleControls([]); end;
end;

procedure TUI.lblMuteUnmuteClick(Sender: TObject);
// The user clicked the Mute/Unmute label in the top right corner of the window
// Currently, this label isn't operational.
begin
  FX.doMuteUnmute;
end;

procedure TUI.progressBarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
// When a SHIFT key is held down, calculate a new video position based on where the mouse is on the prograss bar.
// This *was* intended to allow dragging/scrubbing through the video.
// Unfortunately, WMP can't cope. It doesn't react to the new positions fast enough and gets itself in a right pickle.
// Consequently, this functionality is unusable while WMP is used as the media playing component.
begin
  progressBar.Cursor := crHandPoint;

//  case ssShift in Shift of TRUE:  begin
//                                    progressBar.Cursor            := crHSplit;
//                                    var vNewPosition: integer     := Round(X * (progressBar.Max / progressBar.ClientWidth));
//                                    progressBar.Position          := vNewPosition;
//                                    WMP.controls.currentPosition  := vNewPosition;
//                                  end;
//                          FALSE:  progressBar.Cursor := crDefault;
//  end;
//  FX.updateTimeDisplay;
end;

procedure TUI.progressBarMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
// calculate a new video position based on where the progress bar is clicked
begin
  case FX.noMediaFiles of TRUE: EXIT; end; // prevent invalid call to WMP when there's no video and the user still clicks the progressBar anyway

  var vNewPosition: integer     := Round(x * progressBar.Max / progressBar.ClientWidth);
  progressBar.Position          := vNewPosition;
  WMP.controls.currentPosition  := vNewPosition;
  FX.updateTimeDisplay;
end;

function TUI.repositionLabels: boolean;
// called from FormResize
// Delphi 10.4 seems to have a problem with Anchors = [akRight, akBottom] and placed all the labels offscreen about 1000 pixels too far to the right.
// I now position them manually.
// On other displays, the magic numbers may need to be adjusted and configurable via an application INI file.
// See also repositionTimeDisplay
var
  vBase:  integer;
begin
  lblMediaCaption.Top   := 4;
  lblMediaCaption.Left  := 4;

  lblXY.Left            := 4;
  lblXY2.Left           := 4;
  lblFrameRate.Left     := 4;
  lblBitRate.Left       := 4;
  lblAudioBitRate.Left  := 4;
  lblVideoBitRate.Left  := 4;
  lblXYRatio.Left       := 4;
  lblFileSize.Left      := 4;

  case progressBar.Visible of  TRUE:  vBase := progressBar.Top;
                              FALSE:  vBase := UI.Height - 7; end;    // magic number

  lblXY.Top             := vBase - 125;
  lblXY2.Top            := vBase - 109;
  lblFrameRate.Top      := vBase -  93;
  lblBitRate.Top        := vBase -  77;
  lblAudioBitRate.Top   := vBase -  61;
  lblVideoBitRate.Top   := vBase -  45;
  lblXYRatio.Top        := vBase -  29;
  lblFileSize.Top       := vBase -  13;

  lblInfo.Left          := Width - lblInfo.Width - 20;

  lblInfo.Top           := vBase - lblTimeDisplay.Height - lblInfo.Height;

  repositionTimeDisplay;
end;

function TUI.repositionTimeDisplay: boolean;
// We always want the timestamp display to be sat either on top of the progressBar or sat on the bottom edge of the window
// On other displays, the magic numbers may need to be adjusted and configurable via an application INI file
begin
  lblTimeDisplay.Left := width - lblTimeDisplay.Width - 20; // NB: text aignment is taRightJustify in the Object Inspector
  case progressBar.Visible of  TRUE:  lblTimeDisplay.Top := progressBar.Top - lblTimeDisplay.Height;
                              FALSE:  lblTimeDisplay.Top := UI.Height - lblTimeDisplay.Height - 7; end; // magic number
end;

function TUI.repositionWMP: boolean;
// Set WMP to be 1 pixel bigger than the window on all four sides.
// This [in theory] eliminates any chance of a border pixel on the left and right of the window
// Windows still insists on drawing a 1-pixel border!
// I was tempted to make the window a borderless dialog frame, but this would then make it non-resizable by the user.
begin
  WMP.Height  := UI.Height + 2;
  WMP.Width   := UI.Width + 2;
  WMP.Left    := -1;
  WMP.Top     := -1;
end;

function TUI.resizeWindow1: boolean;
// default window size, called by FormCreate when the CAPS LOCK key isn't down
begin
  UI.Width   := trunc(780 * 1.5);
  UI.Height  := trunc(460 * 1.5);
end;

function TUI.resizeWindow2: boolean;
// [2] = resize so that two videos can be positioned side-by-side horizontally by the user on a 1920-width screen
// If the user opens two video files simultaneously from Explorer with the CAPS LOCK key on, two instances of MediaPlayer will be launched.
// FormCreate will call resizeWindow2 to allow both videos to be positioned by the user alongside each other on a 1920-pixel-width monitor.
// FormResize will left-justify both windows on the monitor, leaving the user to drag one window to the right of the other.
// This allows two seemingly identical videos to be compared for picture quality, duration, etc., so the user can decide which to keep.
// This is also useful when Handbrake* has been used to reduce the resolution of a video to free up disk space, to ensure that the lower-resolution
// video is of sufficient quality to warrant deleting the original.
// *https://handbrake.fr/
begin
  UI.width   := 970;
  UI.height  := 640;
end;

function TUI.resizeWindow3(Shift: TShiftState): boolean;
// [G]reater  = increase size of window
// Ctrl-G     = decrease size of window
// Called from TFX.greaterWindow
begin
  case ssCtrl in Shift of
     TRUE: SetWindowPos(UI.Handle, 0, 0, 0, UI.Width - 100, UI.Height - 60, SWP_NOZORDER + SWP_NOMOVE + SWP_NOREDRAW);
    FALSE: SetWindowPos(UI.Handle, 0, 0, 0, UI.Width + 100, UI.Height + 60, SWP_NOZORDER + SWP_NOMOVE + SWP_NOREDRAW);
  end;
end;

function TUI.setupProgressBar: boolean;
// change the Progress Bar from it's Windows default characteristics to a minimalist display
begin
  SetThemeAppProperties(0);
  ProgressBar.Brush.Color := clBlack;
  // Set Background colour
  SendMessage(ProgressBar.Handle, PBM_SETBARCOLOR, 0, clDkGray);
  // Set bar colour
  var vProgressBarStyle := GetWindowLong(ProgressBar.Handle, GWL_EXSTYLE);
  vProgressBarStyle := vProgressBarStyle - WS_EX_STATICEDGE;
  SetWindowLong(ProgressBar.Handle, GWL_EXSTYLE, vProgressBarStyle);

  UI.Width := UI.Width - 1; // force the progressBar to redraw. If the app is launched by clicking the EXE,
  UI.Width := UI.Width + 1; // the progressBar gets a nasty 1-pixel border, despite the above code.
end;

function TUI.showAboutBox: boolean;
begin
  with TAboutForm.Create(NIL) do
  try
    setReleaseVersion('v' + GV.appReleaseVersion);
    setBuildVersion('v' + GV.appBuildVersion);
    ShowModal;
  finally
    Free;
  end;
end;

function TUI.showMediaCaption: boolean;
begin
  lblMediaCaption.Visible := TRUE;
  tmrMediaCaption.Enabled := TRUE;
end;

function TUI.showInfo(aInfo: string): boolean;
begin
  lblInfo.Caption := aInfo;
  lblInfo.Visible := TRUE;
  tmrInfo.Enabled := FALSE; // prevent a previous timer event from cancelling this one prematurely
  tmrInfo.Enabled := TRUE;
end;

procedure TUI.tmrInfoTimer(Sender: TObject);
// We want the feedback info to only be shown briefly. So, we use a timer to hide it again.
begin
  tmrInfo.Enabled := FALSE;
  lblInfo.Visible := FALSE;
end;

procedure TUI.tmrMediaCaptionTimer(Sender: TObject);
begin
  tmrMediaCaption.Enabled := FALSE;
  lblMediaCaption.Visible := FALSE;
end;

procedure TUI.tmrMetaDataTimer(Sender: TObject);
// We use this timer to delay fetching the video metadata from WMP. Trying to access it too soon after playback commences can cause WMP internal problems.
// Some metadata is available quickly, like the source dimensions. Other bits take longer, like the various bitrates, which can take up to 3 seconds.
// As soon as we have the source dimensions, we can call adjustAspectRatio.
// We allow the timer to fire 3 more times (Interval = 1000ms), then we disable the timer so it's not firing all the way through playback.
// The timer will be enabled for one firing of the event when playback is resumed after being paused.
// metaDataCount only gets reset in playCurrentFile when the media file changes.
begin
  FX.FetchMediaMetaData;
  case FX.hasMetaData of  TRUE: begin
                                  case GV.newMediaFile of  TRUE:  begin
                                                                    FX.adjustAspectRatio;
                                                                    GV.newMediaFile := FALSE; end;end;

                                  GV.metaDataCount := GV.metaDataCount + 1;                                   // fire 3 more times to get the rest of the metadata
                                  case GV.metaDataCount >= 3 of TRUE: tmrMetaData.Enabled := FALSE; end;      // WMP should have determined all the metadata by now.

                                  case NOT FX.isCapsLockOn AND FX.isVideoOffscreen of TRUE: FX.doCentreWindow; end;  // Mainly because the lower part of a 4:3 video can be off the screen
  end;end;
end;

procedure TUI.tmrPlayNextTimer(Sender: TObject);
// At the end of a video, WMP behaves better (internal to itself) if we use a timer to slightly delay playing the next video in the list
begin
  tmrPlayNext.Enabled := FALSE;
  FX.PlayNextFile;
end;

procedure TUI.tmrTimeDisplayTimer(Sender: TObject);
// update the video timestamp display
begin
  FX.UpdateTimeDisplay;
  WMP.Cursor := crNone;
end;

function TUI.toggleControls(Shift: TShiftState): boolean;
// [C] = Show the timestamp display and the Mute/Unmute button OR Hide all displayed controls/metadata
// Ctrl-C Show/Hide all displayed controls/metadata
// If the timestamp and Mute/Unmute button are already being displayed, Ctrl-C will also display all the metadata info
begin
  case (ssCtrl in Shift) AND lblTimeDisplay.Visible and NOT lblXY.Visible of TRUE: begin // add the metadata to the currently displayed timestamp etc
    lblXY.Visible           := TRUE;
    lblXY2.Visible          := TRUE;
    lblFrameRate.Visible    := TRUE;
    lblBitRate.Visible      := TRUE;
    lblAudioBitRate.Visible := TRUE;
    lblVideoBitRate.Visible := TRUE;
    lblXYRatio.Visible      := TRUE;
    lblFileSize.Visible     := TRUE;
    EXIT;
  end;end;

  var vVisible := NOT lblTimeDisplay.Visible;

  lblTimeDisplay.Visible  := vVisible;

  case (ssCtrl in Shift) or NOT vVisible of TRUE: begin // toggle the metadata display status if CTRL-C was pressed
    lblXY.Visible           := vVisible;
    lblXY2.Visible          := vVisible;
    lblFrameRate.Visible    := vVisible;
    lblBitRate.Visible      := vVisible;
    lblAudioBitRate.Visible := vVisible;
    lblVideoBitRate.Visible := vVisible;
    lblXYRatio.Visible      := vVisible;
    lblFileSize.Visible     := vVisible;
  end;end;

  repositionLabels;
end;

procedure TUI.WMDropFiles(var Msg: TWMDropFiles);
// Allow a media file to be dropped onto the window.
// The playlist will be entirely refreshed using the contents of this media file's folder.
var vFilePath: string;
begin
  inherited;
  var hDrop := Msg.Drop;
  try
    var DroppedFileCount := DragQueryFile(hDrop, $FFFFFFFF, nil, 0);
    for var i := 0 to Pred(DroppedFileCount) do begin
      var FileNameLength := DragQueryFile(hDrop, I, nil, 0);
      SetLength(vFilePath, FileNameLength);
      DragQueryFile(hDrop, I, PChar(vFilePath), FileNameLength + 1);
      GV.playIx := FX.findMediaFilesInFolder(vFilePath, GV.playlist);
      FX.playCurrentFile;
      BREAK;              // we currently only process the first file if multiple files are dropped
    end;
  finally
    DragFinish(hDrop);
  end;
  Msg.Result := 0;
end;

procedure TUI.WMPClick(ASender: TObject; nButton, nShiftState: SmallInt; fX, fY: Integer);
// Standard functionality: Play/Pause a video when the user left-clicks on it
begin
  main.FX.doPausePlay;
end;

procedure TUI.WMPKeyDown(ASender: TObject; nKeyCode, nShiftState: SmallInt);
// Handle a KeyDown message from the media player
var Key: WORD;
begin
  Key := nKeyCode;
  FX.UIKey(Key, TShiftState(nShiftState));
end;

procedure TUI.WMPKeyUp(ASender: TObject; nKeyCode, nShiftState: SmallInt);
// Handle a KeyUp message from the media player
var Key: WORD;
begin
  Key := nKeyCode;
  FX.UIKeyUp(Key, TShiftState(nShiftState));
end;

procedure TUI.WMPMouseDown(ASender: TObject; nButton, nShiftState: SmallInt; fX, fY: Integer);
// If there is no window caption you can still drag the window around by holding down a CTRL key and dragging with the left mouse button on the video.
// Edit: Removed CTRL key so that just dragging the window with the left mouse button now matches what happens when you do that with the title bar of any window.
// A side effect of this change is that media files can be paused/resumed using a left double-click, but no longer with a single left click.
const
  SC_DRAGMOVE = $F012;
begin
  Perform(WM_SYSCOMMAND, SC_DRAGMOVE, 0);
end;

procedure TUI.WMPMouseMove(ASender: TObject; nButton, nShiftState: SmallInt; fX, fY: Integer);
// Handle a MouseMove message from the media player: display the standard mouse cursor
begin
  WMP.cursor := crDefault; // this is changed back to crNone when tmrTimeDisplay fires
end;

procedure TUI.WMPPlayStateChange(ASender: TObject; NewState: Integer);
{*
wmppsUndefined	    Windows Media Player is in an undefined state.
wmppsStopped	      Playback is stopped.
wmppsPaused	        Playback is paused.
wmppsPlaying	      Stream is playing.
wmppsScanForward    Stream is scanning forward.
wmppsScanReverse	  Stream is scanning backward.
wmppsBuffering	    Stream is being buffered.
wmppsWaiting	      Waiting for streaming data.
wmppsMediaEnded	    The end of the media item has been reached.
wmppsTransitioning	Preparing new media item.
wmppsReady	        Ready to begin playing.
wmppsReconnecting	  Trying to reconnect for streaming data.
wmppsLast	          Last enumerated value. Not a valid state.
*}
begin
  case NewState of wmppsPlaying: tmrTimeDisplay.Enabled     := True;              // update the video timestamp display during playback

                   wmppsStopped,
                   wmppsPaused,
                   wmppsMediaEnded: tmrTimeDisplay.Enabled  := FALSE; end;        // prevent possibly erroneous timestamps from being displayed

  case NewState of wmppsMediaEnded: tmrPlayNext.Enabled     := TRUE; end;         // WMP needs a thread break before initiating the next video cleanly
end;

procedure TUI.WMSysCommand(var Message: TWMSysCommand);
begin
  inherited;
  case Message.CmdType of MENU_ID:  showAboutBox; end;
end;

{ TGV }

constructor TGV.create;
begin
  inherited;
  Fplaylist := TList<string>.Create;
end;

destructor TGV.destroy;
begin
  case Fplaylist <> NIL of TRUE: Fplaylist.Free; end;
  inherited;
end;

function TGV.getAppBuildVersion: string;
begin
  result :=  getFileVersion;
end;

function TGV.getAppReleaseVersion: string;
begin
  result :=  getFileVersion('', '%d.%d');
end;

function TGV.getExePath: string;
begin
  result := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
end;

function TGV.getFileVersion(const aFilePath: string = ''; const fmt: string = '%d.%d.%d.%d'): string;
var
  vFilePath: string;
  iBufferSize: DWORD;
  iDummy: DWORD;
  pBuffer: Pointer;
  pFileInfo: Pointer;
  iVer: array[1..4] of Word;
begin
  // set default value
  Result := '';
  // get filename of exe/dll if no filename is specified
  vFilePath := aFilePath;
  case vFilePath = '' of TRUE:  begin
                                  // prepare buffer for path and terminating #0
                                  SetLength(vFilePath, MAX_PATH + 1);
                                  SetLength(vFilePath, GetModuleFileName(hInstance, PChar(vFilePath), MAX_PATH + 1));
                                end;end;

  // get size of version info (0 if no version info exists)
  iBufferSize := GetFileVersionInfoSize(PChar(vFilePath), iDummy);

  case iBufferSize > 0 of TRUE:   begin
                                    GetMem(pBuffer, iBufferSize);
                                    try
                                      // get fixed file info (language independent)
                                      GetFileVersionInfo(PChar(vFilePath), 0, iBufferSize, pBuffer);
                                      VerQueryValue(pBuffer, '\', pFileInfo, iDummy);
                                      // read version blocks
                                      iVer[1] := HiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
                                      iVer[2] := LoWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
                                      iVer[3] := HiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
                                      iVer[4] := LoWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
                                    finally
                                      FreeMem(pBuffer);
                                    end;
                                    // format result string
                                    Result := Format(Fmt, [iVer[1], iVer[2], iVer[3], iVer[4]]);
                                  end;end;
end;

function TGV.invalidPlayIx: boolean;
begin
  result := (GV.playIx < 0) OR (GV.playIx > GV.playlist.Count - 1);
end;

initialization
  SetExceptionMask(exAllArithmeticExceptions);  // prevent WMP from generating a continuous stream of exception dialog boxes during playback
  GV := TGV.Create;
  FX := TFX.Create;

finalization
  case GV <> NIL of TRUE: begin GV.Free; end;end;
  case FX <> NIL of TRUE: begin FX.Free; end;end;

end.
