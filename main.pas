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
unit main;

interface

uses
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons,
  System.Classes, WMPLib_TLB, Vcl.AppEvnts, WinApi.Messages, WinApi.Windows;

type
  TUI = class(TForm)
    progressBar: TProgressBar;
    tmrPlayNext: TTimer;
    tmrTimeDisplay: TTimer;
    WMP: TWindowsMediaPlayer;
    tmrRateLabel: TTimer;
    tmrMetaData: TTimer;
    tmrTab: TTimer;
    lblMuteUnmute: TLabel;
    lblRate: TLabel;
    lblTimeDisplay: TLabel;
    lblXY: TLabel;
    lblFrameRate: TLabel;
    lblBitRate: TLabel;
    lblAudioBitRate: TLabel;
    lblVideoBitRate: TLabel;
    lblXYRatio: TLabel;
    lblFileSize: TLabel;
    lblXY2: TLabel;
    lblTab: TLabel;
    lblVol: TLabel;
    tmrVol: TTimer;
    applicationEvents: TApplicationEvents;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure progressBarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure progressBarMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure tmrPlayNextTimer(Sender: TObject);
    procedure tmrTimeDisplayTimer(Sender: TObject);
    procedure WMPClick(ASender: TObject; nButton, nShiftState: SmallInt; fX, fY: Integer);
    procedure WMPPlayStateChange(ASender: TObject; NewState: Integer);
    procedure tmrRateLabelTimer(Sender: TObject);
    procedure lblMuteUnmuteClick(Sender: TObject);
    procedure tmrMetaDataTimer(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure WMPMouseMove(ASender: TObject; nButton, nShiftState: SmallInt; fX, fY: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure tmrTabTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure WMPKeyUp(ASender: TObject; nKeyCode, nShiftState: SmallInt);
    procedure WMPKeyDown(ASender: TObject; nKeyCode, nShiftState: SmallInt);
    procedure tmrVolTimer(Sender: TObject);
    procedure applicationEventsMessage(var Msg: tagMSG; var Handled: Boolean);
    procedure WMPMouseDown(ASender: TObject; nButton, nShiftState: SmallInt; afX, fY: Integer);
  private
    procedure setupProgressBar;
  protected
  public
    // UI Functions only - application logic is in TFX
    function  hideLabels: boolean;
    function  isWindowCaptionVisible: boolean;
    function  repositionLabels: boolean;
    function  repositionTimeDisplay: boolean;
    function  repositionWMP: boolean;
    function  toggleControls(Shift: TShiftState): boolean;
  end;

var
  UI: TUI;  // User Interface

implementation

uses
  WinApi.CommCtrl,  WinApi.uxTheme,
  System.SysUtils, System.Generics.Collections, System.Math, System.Variants,
  FormInputBox, MMSystem, Mixer, VCL.Graphics, clipbrd, System.IOUtils;

type
  TGV = class                        // Global [application-wide] Variables
  strict private                     // force code to use the properties
    FBlackOut: boolean;
    FClosing: boolean;
    FFileIx:  integer;
    FFiles:   TList<string>;
    FInputBox: boolean;
    FMute:    boolean;
    FSampling: boolean;
    FStartUp: boolean;
    FZoomed: boolean;
    function  GetExePath: string;
  private
  public
    constructor create;
    destructor  destroy;  override;
    property    blackOut:     boolean       read FBlackOut  write FBlackOut;
    property    closing:      boolean       read FClosing   write FClosing;
    property    exePath:      string        read GetExePath;
    property    fileIx:       integer       read FFileIx    write FFileIx;
    property    files:        TList<string> read FFiles;
    property    inputBox:     boolean       read FInputBox  write FInputBox;
    property    mute:         boolean       read FMute      write FMute;
    property    sampling:     boolean       read FSampling  write FSampling;
    property    startup:      boolean       read FStartUp   write FStartUp;
    property    zoomed:       boolean       read FZoomed    write FZoomed;
  end;

  TFX = class                        // application Functions
  private
    function adjustAspectRatio: boolean;
    function blackOut: boolean;
    function clearMediaMetaData: boolean;
    function clipboardCurrentFileName: boolean;
    function currentFilePath: string;
    function Delay(dwMilliseconds:DWORD): boolean;
    function deleteBookmarkedPosition: boolean;
    function deleteCurrentFile(Shift: TShiftState): boolean;
    function deleteThisFile(AFilePath: string; Shift: TShiftState): boolean;
    function doCentreWindow: boolean;
    function doCommandLine(aCommandLIne: string): boolean;
    function doMuteUnmute: boolean;
    function doPausePlay: boolean;
    function fetchMediaMetaData: boolean;
    function findMediaFilesInFolder(aFilePath: string; aFileList: TList<string>; MinFileSize: int64 = 0): integer;
    function fullScreen: boolean;
    function getFileSize(const aFilePath: string): int64;
    function getINIname: string;
    function goDown: boolean;
    function goLeft: boolean;
    function goRight: boolean;
    function goUp: boolean;
    function isAltKeyDown: boolean;
    function isCapsLockOn: boolean;
    function isControlKeyDown: boolean;
    function isLastFile: boolean;
    function isShiftKeyDown: boolean;
    function keepCurrentFile: boolean;
    function matchVideoWidth: boolean;
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
    function resizeWindow1: boolean;
    function resizeWindow2: boolean;
    function resizeWindow3: boolean;
    function resumePosition: boolean;
    function sampleVideo: boolean;
    function saveCurrentPosition: boolean;
    function showHideTitleBar: boolean;
    function ShowOKCancelMsgDlg(aMsg: string): TModalResult;
    function speedDecrease(Shift: TShiftState): boolean;
    function speedIncrease(Shift: TShiftState): boolean;
    function startOver: boolean;
    function tabForwardsBackwards: boolean;
    function UIKey(var Key: Word; Shift: TShiftState): boolean;
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
  X := UI.WMP.currentMedia.imageSourceWidth;
  Y := UI.WMP.currentMedia.imageSourceHeight;

  case (X = 0) OR (Y = 0) of TRUE: EXIT; end;

  vRatio := Y / X;

  vHeightTitle := GetSystemMetrics(SM_CYCAPTION);
  case UI.isWindowCaptionVisible of  TRUE: vDelta := vHeightTitle + 7; // magic number
                                    FALSE: vDelta := 8; end;           // magic number

  UI.Height := trunc(UI.Width * vRatio) + vDelta;
  UI.Width  := UI.Width - 1; // experimental

  UI.repositionWMP;
end;

function TFX.blackOut: boolean;
// [B] = [B]lackout i.e. Show/Hide ProgressBar
// Ctrl-B = total [B]lackOut: i.e. also show/hide the window title bar and adjust the window's aspect ratio
begin
  GV.blackOut             := NOT GV.blackOut;
  UI.progressBar.Visible  := NOT GV.blackOut;
  UI.repositionWMP;

  case isControlKeyDown of TRUE:  begin
                                    case UI.isWindowCaptionVisible XOR GV.blackOut of FALSE: showHideTitleBar; end; // has user has already hidden title bar?
                                    adjustAspectRatio;
                                  end;end;
  UI.repositionLabels;
  UI.repositionTimeDisplay;
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
  result := GV.files[GV.fileIx];
end;

function TFX.Delay(dwMilliseconds: DWORD): boolean;
// Used to delay an operation; "sleep()" would pause the thread, which is not what is required
var
  iStart, iStop: DWORD;
begin
  iStart := GetTickCount;
  repeat
    iStop  := GetTickCount;
    Application.ProcessMessages;
  until (iStop  -  iStart) >= dwMilliseconds;
end;

function TFX.deleteBookmarkedPosition: boolean;
begin
  DeleteFile(getINIname);
end;

function TFX.deleteCurrentFile(Shift: TShiftState): boolean;
// [D] / DEL = [D]elete the current file
// Ctrl-D / Ctrl-DEL = Delete the entire contents of the current file's folder (doesn't touch subfolders)
begin
  UI.WMP.controls.pause;
  var vMsg := 'DELETE '#13#10#13#10'Folder: ' + ExtractFilePath(currentFilePath);
  case ssCtrl in Shift of  TRUE: vMsg := vMsg + '*.*';
                          FALSE: vMsg := vMsg + #13#10#13#10'File: ' + ExtractFileName(currentFilePath); end;

  case showOkCancelMsgDlg(vMsg) = IDOK of
    TRUE: begin
            deleteThisFile(currentFilePath, Shift);

            case isLastFile or (ssCtrl in Shift) of TRUE: begin UI.CLOSE; EXIT; end;end;  // close app after deleting final file or deleting folder contents

            GV.files.Delete(GV.fileIx);
            GV.fileIx := GV.fileIx - 1;

            playNextFile;
          end;
  end;
end;

function TFX.deleteThisFile(AFilePath: string; Shift: TShiftState): boolean;
// performs the actual file/folder deletion initiated by deleteCurrentFile
begin
  case ssCtrl in Shift of  TRUE: doCommandLine('rot -nobanner -p 1 -r "' + ExtractFilePath(AFilePath) + '*.* "'); // folder contents but not subfolders
                          FALSE: doCommandLine('rot -nobanner -p 1 -r "' + AFilePath + '"'); end;                 // one individual file
end;

function TFX.doCentreWindow: boolean;
// H = [H]orizontal
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
                          CREATE_NEW_PROCESS_GROUP + NORMAL_PRIORITY_CLASS, nil, PWideChar(ExtractFilePath(application.ExeName)),
                          vStartInfo, vProcInfo);
end;

function TFX.doMuteUnmute: boolean;
// [E]ars = mute / unmute system sound
begin
  GV.mute       := NOT GV.mute;
  g_mixer.muted := GV.mute;
  case GV.mute of
     TRUE:  UI.lblMuteUnmute.Caption  := 'Unmute';
    FALSE:  UI.lblMuteUnmute.Caption  := 'Mute';
  end;
end;

function TFX.doPausePlay: boolean;
// [SpaceBar] or click on video = Pause / Play
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
begin
  UI.lblXY.Caption                := format('XY:  %s x %s', [UI.WMP.currentMedia.getItemInfo('WM/VideoWidth'), UI.WMP.currentMedia.getItemInfo('WM/VideoHeight')]);
  UI.lblXY2.Caption               := format('XY:  %d x %d', [UI.WMP.currentMedia.imageSourceWidth, UI.WMP.currentMedia.imageSourceHeight]);
  try UI.lblFrameRate.Caption     := format('FR:  %f fps', [StrToFloat(UI.WMP.currentMedia.getItemInfo('FrameRate')) / 1000]); except end;
  try UI.lblBitRate.Caption       := format('BR:  %d Kb/s', [trunc(StrToFloat(UI.WMP.currentMedia.getItemInfo('BitRate')) / 1024)]); except end;
  try UI.lblAudioBitRate.Caption  := format('AR:  %d Kb/s', [trunc(StrToFloat(UI.WMP.currentMedia.getItemInfo('AudioBitRate')) / 1024)]); except end;
  try UI.lblVideoBitRate.Caption  := format('VR:  %d Kb/s', [trunc(StrToFloat(UI.WMP.currentMedia.getItemInfo('VideoBitRate')) / 1024)]); except end;
  try UI.lblXYRatio.Caption       := format('XY:  %s:%s', [UI.WMP.currentMedia.getItemInfo('PixelAspectRatioX'), UI.WMP.currentMedia.getItemInfo('PixelAspectRatioY')]); except end;
  try UI.lblFileSize.Caption      := format('FS:  %d MB', [trunc(StrToFloat(UI.WMP.currentMedia.getItemInfo('FileSize')) / 1024 / 1024)]); except end;
  case trim(UI.lblXY.Caption) = 'XY:   x' of TRUE: UI.lblXY.Caption := 'XY:'; end;
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

function TFX.fullScreen: boolean;
// [F] = Tell WMP to diplay fullScreen.
// The video timestamp and metadata displays etc. won't show until fullScreen mode is exited.
begin
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
// A video timestamp can be saved to and retrieved from an INI file, named after the video file.
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
  result := GV.fileIx = GV.files.Count - 1;
end;

function TFX.isShiftKeyDown: boolean;
// Did the user hold down a SHIFT key while pressing another key?
begin
  result := (GetKeyState(VK_SHIFT) AND $80) <> 0;
end;

function TFX.keepCurrentFile: boolean;
// K = [K]eep current file
// When examining a folder to determine which videos to keep or delete,
//    this provides a convenient way to mark a video to be kept by renaming the file, prefixing an underscore to its filename.
// This causes all such files to gravitate to the top of the displayed folder thus making it easy to select all the other files and delete them.
// Occasionally, Windows or WMP will prevent the file from being renamed while WMP has it open.
// There is no apparent pattern to when the rename is allowed and when it isn't.
begin
  UI.WMP.controls.pause;
  delay(250);   // give WMP time to register internally that the video has been paused (delay() doesn't "sleep()" the thread).
  var vFileName := '_' + ExtractFileName(currentFilePath);
  var vFilePath := ExtractFilePath(currentFilePath) + vFileName;
  case RenameFile(currentFilePath, vFilePath) of FALSE: ShowMessage('Rename failed:' + #13#10 +  SysErrorMessage(getlasterror));
                                                  TRUE: GV.files[GV.fileIx] {currentFilePath} := vFilePath; end; // reflect the new name in the list
  windowCaption;
  UI.WMP.controls.play;
end;

function TFX.matchVideoWidth: boolean;
// [9] = resize the width of the window to match the video width.
// Judicious use of [9], [J], [H] and [G] can be used to obtain the optimum window to match the video.
begin
  var X := UI.WMP.currentMedia.imageSourceWidth;
  var Y := UI.WMP.currentMedia.imageSourceHeight;

  UI.Width := X;
end;

function TFX.openWithShotcut: boolean;
// [F12] = open the video in the ShotCut* video editor
// mklink C:\ProgramFiles "C:\Program Files"
// The above command line allows C:\Program Files\ to be referenced in programs without the annoying space.
// This can simpifly things when multiple nested double quotes and apostrophes are being used to construct a command line
// At some point, the user's preferred video editor needs to be configurable via an application INI file.
// *https://shotcut.org/
begin
  UI.WMP.controls.pause;
  doCommandLine('C:\ProgramFiles\Shotcut\shotcut.exe "' + currentFilePath + '"');
end;

function TFX.playCurrentFile: boolean;
// CurrentFile is the one whose index in the list equals fileIx
begin
  case (GV.fileIx < 0) OR (GV.fileIx > GV.files.Count - 1) of TRUE: EXIT; end;  // sanity check

  case FileExists(currentFilePath) of TRUE: begin                               // i.e. if file *still* exists :D
    windowCaption;
    UI.WMP.URL := 'file://' + currentFilePath;
    unZoom;
    WMPplay;
  end;end;
end;

function TFX.playFirstFile: boolean;
// A = play the first video in the list
begin
  case GV.files.Count > 0 of TRUE:  begin
                                      GV.fileIx := 0;
                                      playCurrentFile;
                                    end;
  end;
end;

function TFX.playLastFile: boolean;
// Z = play the last video in the list
begin
  case GV.files.Count > 0 of TRUE:  begin
                                      GV.fileIx := GV.files.Count - 1;
                                      playCurrentFile;
                                    end;
  end;
end;

function TFX.playNextFile: boolean;
// W = [W]atch the next video in the list
begin
  case isLastFile of TRUE: begin UI.CLOSE; EXIT; end;end;

  case GV.fileIx < GV.files.Count - 1 of TRUE:  begin
                                                  GV.fileIx := GV.fileIx + 1;
                                                  playCurrentFile;
                                                end;
  end;
end;

function TFX.playPrevFile: boolean;
// Q = play the previous video in the list
begin
  case GV.fileIx > 0 of TRUE:   begin
                                  GV.fileIx := GV.fileIx - 1;
                                  playCurrentFile;
                                end;
  end;
end;

function TFX.playWithPotPlayer: boolean;
// P = Play with [P]otPlayer
// At some point, the user's preferred alternative media player needs to be picked up from a mediaplayer.ini file
begin
  UI.WMP.controls.pause;
  doCommandLine('B:\Tools\Pot\PotPlayerMini64.exe "' + currentFilePath + '"');
end;

function TFX.rateReset: boolean;
// 1 = reset the playback rate to 100%
begin
  UI.WMP.settings.rate    := 1;
  FX.updateRateLabel;
end;

function TFX.reloadMediaFiles: boolean;
// L = re[L]oad the list of video files from the current folder
// Previously, a facility existed whereby if MediaPlayer was launched with the CAPS LOCK key on,
//    only video files greater than 100MB in size would be loaded into the file list.
// This allowed folders to be examined to quicly keep or delete the largest videos.
// This reloadMediaFiles function could than be used to find all files in the current folder regardless of size,
//    without having to close and restart the app *without* the CAPS LOCK key on.
// Typically, this was actually because the user had launched MediaPlayer forgetting that the CAPS LOCK key was on.
// The CAPS LOCK key has now been repurposed for something else (see FormCreate) so for the time being this function isn't called or useful
begin
  GV.fileIx := findMediaFilesInFolder(currentFilePath, GV.files);
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
                                                         TRUE: GV.files[GV.fileIx] {currentFilePath} := vNewFilePath; end;
  windowCaption; // update the caption with the new name
end;

function TFX.resizeWindow1: boolean;
// default window size, called by FormCreate when the CAPS LOCK key isn't down
begin
  UI.Width   := trunc(780 * 1.5);
  UI.Height  := trunc(460 * 1.5);
end;

function TFX.resizeWindow2: boolean;
// [2] = resize so that two videos can be positioned side-by-side horizontally by the user
begin
  UI.width   := 970;
  UI.height  := 640;
end;

function TFX.resizeWindow3: boolean;
// [G]reater  = increase size of window
// Ctrl-G     = decrease size of window
begin
  case isControlKeyDown of
     TRUE: SetWindowPos(UI.Handle, 0, 0, 0, UI.Width - 100, UI.Height - 60, SWP_NOZORDER + SWP_NOMOVE + SWP_NOREDRAW);
    FALSE: SetWindowPos(UI.Handle, 0, 0, 0, UI.Width + 100, UI.Height + 60, SWP_NOZORDER + SWP_NOMOVE + SWP_NOREDRAW);
  end;

  doCentreWindow;

  windowCaption;
end;

function TFX.resumePosition: boolean;
// [6] = read the saved video position from the INI file and continue playing from that position
begin
  case FileExists(getINIname) of FALSE: EXIT; end;

  var sl := TStringList.Create;
  sl.LoadFromFile(getINIname);
  UI.WMP.controls.currentPosition := StrToFloat(sl[0]);
  sl.Free;
end;

function TFX.sampleVideo: boolean;
// [Y] = sample/tr[Y]out the video by playing a few seconds then skipping 10% of the video
// This will stop once the current video position is more than 90% the way through the video
// If the next video is played, sampling will continue until Y is pressed again to cancel sampling
begin
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

function TFX.saveCurrentPosition: boolean;
// [5] = save current video position to an ini file
begin
  case FileExists(getINIname) of
    TRUE: case MessageDlg('Do you want to overwrite the previous bookmark?', TMsgDlgType.mtConfirmation, [mbYes, mbNo], 0) = mrNo of TRUE: EXIT; end;end;

  var sl := TStringList.Create;
  sl.Add(FloatToStr(UI.WMP.controls.currentPosition));
  sl.SaveToFile(getINIname);
  sl.Free;
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
  UI.WMP.controls.currentPosition := 0;
  UI.WMP.controls.play;
end;

function TFX.tabForwardsBackwards: boolean;
// [T] = Tab Forward or Ctrl-T = Tab Backward through a fraction of the video.
// The fraction to jump can be modified using the following keys:
//    Default   = 100th
//    ALT       = 50th
//    SHIFT     = 20th
//    CAPS LOCK = 10th
//  CTRL = reverse
var
  vFactor: integer;
begin
  UI.lblTab.Caption  := '';

  case isShiftKeyDown of
     TRUE:  vFactor := 20;
    FALSE:  case isAltKeyDown of
               TRUE:  vFactor := 50;
              FALSE:  case isCapsLockOn of
                         TRUE: vFactor := 10;
                        FALSE: vFactor := 100;
                      end;end;end;

  case isControlKeyDown of
    TRUE: UI.WMP.controls.currentPosition := UI.WMP.controls.currentPosition - (UI.WMP.currentMedia.duration / vFactor);
   FALSE: UI.WMP.controls.currentPosition := UI.WMP.controls.currentPosition + (UI.WMP.currentMedia.duration / vFactor);
  end;

  UI.lblTab.Caption  := format('%dth', [vFactor]);
  case isControlKeyDown of  TRUE: UI.lblTab.Caption := '<< ' + UI.lblTab.Caption;
                           FALSE: UI.lblTab.Caption := '>> ' + UI.lblTab.Caption;
  end;
  UI.lblTab.Visible := TRUE;
  UI.tmrTab.Enabled := TRUE;      // confirm the fraction jumped (and the direction) for the user
end;

function TFX.UIKey(var Key: Word; Shift: TShiftState): boolean;
// Keys that can be pressed singly or held down for repeat action
begin
  result := TRUE;

  case (ssCtrl in Shift) AND GV.zoomed of                                // when zoomed, Ctrl-up/down/left/right moves the video around the window
     TRUE:  case key in [VK_RIGHT, VK_LEFT, VK_UP, VK_DOWN] of
               TRUE:  begin
                        case Key of
                          VK_RIGHT:     FX.GoRight;                      // Move zoomed WMP right
                          VK_LEFT:      FX.GoLeft;                       // Move zoomed WMP left
                          VK_UP:        FX.GoUp;                         // Move zoomed WMP up
                          VK_DOWN:      FX.GoDown;                       // Move zoomed WMP down
                        end;
                        Key := 0;
                        EXIT;
                      end;end;end;

  case NOT (ssCtrl in Shift) and NOT GV.zoomed of                        // when not zoomed, up/down increases or decreases the volume by 1%
     TRUE:  case Key in [VK_UP, VK_DOWN] of
               TRUE:  begin
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
              case Key of
                VK_RIGHT: IWMPControls2(UI.WMP.controls).step(1);        // Frame forwards
                VK_LEFT:  IWMPControls2(UI.WMP.controls).step(-1);       // Frame backwards
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
  case UIKey(Key, Shift) of TRUE: EXIT; end;  // Keys that can be pressed singly or held down for repeat action

  case Key of
//    VK_ESCAPE: case UI.WMP.fullScreen of FALSE: UI.CLOSE; end; // eXit app  - WMP doesn't allow this key to be re-used

    VK_SPACE:  doPausePlay;                         // Pause / Play

    VK_UP:            SpeedIncrease(Shift);         // Ctrl-UpArrow = Speed up
    VK_DOWN:          SpeedDecrease(Shift);         // Ctrl-DnArrow = Slow down
    191 {Slash}:      SpeedIncrease([ssCtrl]);      // Ctrl-UpArrow = Speed up
    220 {Backslash}:  SpeedDecrease([ssCtrl]);      // Ctrl-DnArrow = Slow down

    VK_F12: openWithShotcut;

    187               : clipboardCurrentFileName;             // =   copy current filename to clipboard
    ord('a'), ord('A'): PlayFirstFile;                        // A = Play first
    ord('b'), ord('B'): BlackOut;                             // B = Blackout                       Mods: Ctrl-B
    ord('c'), ord('C'): UI.ToggleControls(Shift);             // C = Control Panel show/hide        Mods: Ctrl-C
    ord('d'), ord('D'), VK_DELETE: deleteCurrentFile(Shift);  // D = Delete File                    Mods: Ctrl-D / Ctrl-DEL
    ord('e'), ord('E'): DoMuteUnmute;                         // E = (Ears)Mute/Unmute
    ord('f'), ord('F'): fullScreen;                           // F = Fullscreen
    ord('g'), ord('G'): ResizeWindow3;                        // G = Greater window size            Mods: Ctrl-G
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
    ord('0')          : ShowHideTitleBar;                     // 0 = Hide(zero)/show window title bar
    ord('1')          : RateReset;                            // 1 = Rate 1[00%]
    ord('2')          : ResizeWindow2;                        // 2 = resize so that two videos can be positioned side-by-side horizontally by the user
    ord('5')          : saveCurrentPosition;                  // 5 = save current media position to an INI file     (bookmark)
    ord('6')          : resumePosition;                       // 6 = resume video from saved media position         (bookmark)
    ord('7')          : deleteBookmarkedPosition;             // 7 = delete INI file containing bookmarked position (bookmark)
    ord('8')          : UI.repositionWMP;                     // 8 = reposition WMP to eliminate border pixels
    ord('9')          : matchVideoWidth;                      // 9 = match window width to video width
  end;
  UpdateTimeDisplay;
  Key := 0;
end;

function TFX.unZoom: boolean;
// U = [U]nzoom; re-fit the video to the window
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
  delay(100);             // delay() doesn't "sleep()" the thread
  UI.lblRate.Caption      := IntToStr(round(UI.WMP.settings.rate * 100)) + '%';
  UI.lblRate.Visible      := TRUE;
  UI.tmrRateLabel.Enabled := TRUE; // briefly display the new speed
end;

function TFX.updateTimeDisplay: boolean;
// Update the video timestamp display regardless of whether it's visible or not
// Also update the progress bar to match the current video position
begin
  UI.lblTimeDisplay.Caption := UI.WMP.controls.currentPositionString + ' / ' + UI.WMP.currentMedia.durationString;

  UI.ProgressBar.Max        := trunc(UI.WMP.currentMedia.duration);
  UI.ProgressBar.Position   := trunc(UI.WMP.controls.currentPosition);
end;

function TFX.updateVolumeDisplay: boolean;
begin
  UI.lblVol.Caption := IntToStr(trunc(g_mixer.volume / 65535 * 100))  + '%';
  UI.lblVol.Visible := TRUE;
  UI.tmrVol.Enabled := TRUE; // briefly confirm the new volume setting for the user
end;

function TFX.windowCaption: boolean;
begin
  case GV.Files.Count = 0 of TRUE: EXIT; end;
  UI.Caption := format('[%d/%d] %s', [GV.FileIx + 1, GV.Files.Count, ExtractFileName(currentFilePath)]);
end;

function TFX.windowMaximizeRestore: boolean;
// M = [M]aximize/Restore window
begin
  case UI.WindowState = wsMaximized of TRUE: UI.WindowState := wsNormal;
                                      FALSE: UI.WindowState := wsMaximized; end;
end;

function TFX.WMPplay: boolean;
// Called to both start and resume the playing of a video
begin
  try
    UI.tmrMetaData.Enabled := FALSE; // prevent the display of invalid metadata while we [potentially] switch videos
    clearMediaMetaData;              // "Out with the old..."
    UI.WMP.controls.play;
    UI.tmrMetaData.Enabled := TRUE;  // necessary delay before trying to access video metadata from WMP
  except begin
    ShowMessage('Oops!');
    UI.WMP.controls.stop;
  end;end;
end;

function TFX.zoomIn: boolean;
// I = Zoom [I]n by 10%
begin
  GV.zoomed := TRUE;

  UI.WMP.Width    := trunc(UI.WMP.Width * 1.1);
  UI.WMP.Height   := trunc(UI.WMP.Height * 1.1);
  UI.WMP.Top      := -(UI.WMP.Height - UI.Height) div 2;
  UI.WMP.Left     := -(UI.WMP.Width - UI.Width) div 2;

  UI.hideLabels;  // now that WMP's dimensions bear no relation to the window's, label positioning gets too complicated
end;

function TFX.zoomOut: boolean;
// O = Zoom [O]ut by 10%
begin
  GV.zoomed := TRUE;

  UI.WMP.Width    := trunc(UI.WMP.Width * 0.9);
  UI.WMP.Height   := trunc(UI.WMP.Height * 0.9);
  UI.WMP.Top      := -(UI.WMP.Height - UI.ClientHeight) div 2;
  UI.WMP.Left     := -(UI.WMP.Width - UI.ClientWidth) div 2;

  UI.hideLabels;  // now that WMP's dimensions bear no relation to the window's, label positioning gets too complicated
end;

function TFX.showHideTitleBar: boolean;
// [0] = Show or Hide(i.e. zero) the window title bar
// Part of this application's attempt to provide an entirely borderless window for the video without displaying fullScreen.
// Unfortunately, this is only partially successful as WMP insists on showing a 7-pixel (approx.) black border along the top of every video
// I mitigate this myself by having a Windows desktop wallpaper image* which is almost entirely black, and a desktop that contains no icons at all.
// *https://c4.wallpaperflare.com/wallpaper/68/50/540/lamborghini-car-vehicle-wallpaper-preview.jpg
begin
  var vStyle := GetWindowLong(UI.Handle, GWL_STYLE);

  case (vStyle and WS_CAPTION) = WS_CAPTION of TRUE: begin
    case UI.BorderStyle of
      bsSingle, bsSizeable:
        SetWindowLong(UI.Handle, GWL_STYLE, vStyle AND (NOT (WS_CAPTION)) and (NOT (WS_BORDER))); //  or WS_BORDER);
      bsDialog:
        SetWindowLong(UI.Handle, GWL_STYLE, vStyle AND (NOT (WS_CAPTION)) OR DS_MODALFRAME OR WS_DLGFRAME);
    end;
    UI.Refresh;
  end;end;

  case (vStyle and WS_CAPTION) = WS_CAPTION of FALSE: begin
    case UI.BorderStyle of
      bsSingle, bsSizeable:
        SetWindowLong(UI.Handle, GWL_STYLE, vStyle OR WS_CAPTION OR WS_BORDER);
      bsDialog:
        SetWindowLong(UI.Handle, GWL_STYLE, vStyle OR WS_CAPTION OR DS_MODALFRAME OR WS_DLGFRAME);
    end;
    UI.Height := UI.Height + 1;  // fix Windows bug and force title bar to repaint properly
    UI.Height := UI.Height - 1;  // fix Windows bug and force title bar to repaint properly
    UI.Refresh;
  end;end;

  adjustAspectRatio;             // save the user the effort of doing this manually
  windowCaption;
end;

function TFX.showOKCancelMsgDlg(aMsg: string): TModalResult;
// used for displaying the delete file/folder confirmation dialog
// We modify the standard dialog to make everything bigger, especially the width so that long folder names and files display properly
// The standard dialog would unhelpfully truncate them.
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

//===== UI Event Handlers and Functions =====

{$R *.dfm}

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

procedure TUI.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
// make sure to stop video playback before exiting the app or WMP can get upset
begin
  WMP.controls.stop;
  CanClose := TRUE;
  GV.Closing := TRUE;
end;

procedure TUI.FormCreate(Sender: TObject);
begin
  SetWindowLong(UI.Handle, GWL_STYLE, GetWindowLong(UI.Handle, GWL_STYLE) OR WS_CAPTION AND (NOT (WS_BORDER)));

  case FX.isCapsLockOn of    TRUE:  FX.resizeWindow2; // size so that two videos can be positioned side-by-side horizontally by the user
                            FALSE:  FX.resizeWindow1; // otherwise, default size
  end;

  color := clBlack; // background color of the window's client area, so zooming-out doesn't show the design-time color

  lblMuteUnmute.Visible := FALSE; // I suddenly took a dislike to this being displayed when all I actually wanted was the video timestamp.

  WMP.uiMode          := 'none';
  WMP.windowlessVideo := TRUE;
  WMP.stretchToFit    := TRUE;
  WMP.settings.volume := 100;

  lblMuteUnmute.Parent    := WMP;    // the only way for these to display is to make them child controls of WMP
  lblXY.Parent            := WMP;
  lblXY2.Parent           := WMP;
  lblFrameRate.Parent     := WMP;
  lblBitRate.Parent       := WMP;
  lblAudioBitRate.Parent  := WMP;
  lblVideoBitRate.Parent  := WMP;
  lblXYRatio.Parent       := WMP;
  lblFileSize.Parent      := WMP;
  lblRate.Parent          := WMP;
  lblTab.Parent           := WMP;
  lblVol.Parent           := WMP;
  lblTimeDisplay.Parent   := WMP;

  lblRate.Caption         := '';
  lblTab.Caption          := '';
  lblVol.Caption          := '';
  lblTimeDisplay.Caption  := '';

//  progressBar.Parent      := WMP;  // this is ok until you start zooming in: then you lose the progressBar altogether

  setupProgressBar;
  repositionLabels;

  case g_mixer.muted of TRUE: FX.DoMuteUnmute; end; // GV.Mute starts out FALSE; this brings it in line with the system

  case {FX.isCapsLockOn} TRUE = FALSE of            // CAPS LOCK repurposed to choose window size; see start of procedure
     TRUE: GV.FileIx := FX.findMediaFilesInFolder(ParamStr(1), GV.Files, 100000000);
    FALSE: GV.FileIx := FX.findMediaFilesInFolder(ParamStr(1), GV.Files);
  end;

  FX.playCurrentFile;                               // automatically start the clicked video

  GV.startup := TRUE;                               // used in FormResize to initially left-justify the application window if required
end;

procedure TUI.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
// superseded by ApplicationEventsMessage
begin
  FX.UIKeyDown(Key, Shift);
end;

procedure TUI.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
// superseded by ApplicationEventsMessage
begin
  FX.UIKeyUp(Key, Shift);
end;

procedure TUI.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  WMP.cursor := crDefault;
end;

procedure TUI.FormResize(Sender: TObject);
// If the user opens two video files simultaneously from Explorer with the CAPS LOCK key on, two instances of MediaPlayer will be launched.
// FormCreate will call resizeWindow2 to allow both videos to be positioned by the user alongside each other on a 1920-pixel-width monitor.
// FormResize will left-justify both windows on the monitor, leaving the user to drag one window to the right of the other.
// This allows two seemingly identical videos to be compared for picture quality, duration, etc., so the user can decide which to keep.
// This is also useful when Handbrake* has been used to reduce the resolution of a video to free up disk space, to ensure that the lower-resolution
// video is of sufficient quality to warrant deleting the original.
// *https://handbrake.fr/
begin
  FX.windowCaption;

  case GV.startup AND FX.isCapsLockOn of  TRUE: SetWindowPos(self.Handle, 0, -6, 200, 0, 0, SWP_NOZORDER + SWP_NOSIZE); end; // left justify on screen
  GV.startup := FALSE;

  repositionLabels;

  repositionWMP;
end;

function TUI.hideLabels: boolean;
// called from ZoomIn and ZoomOut
begin
  case lblTimeDisplay.Visible of TRUE: toggleControls([]); end;
end;

function TUI.isWindowCaptionVisible: boolean;
begin
  result := GetWindowLong(UI.Handle, GWL_STYLE) AND WS_CAPTION = WS_CAPTION;
end;

procedure TUI.lblMuteUnmuteClick(Sender: TObject);
// The user clicked the Mute/Unmute label in the top right corner of the window
begin
  FX.doMuteUnmute;
end;

procedure TUI.progressBarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
// When a SHIFT key is held down, calculate a new video position based on where the mouse is on the prograss bar.
// This *was* intended to allow dragging/scrubbing through the video.
// Unfortunately, WMP can't cope. It doesn't react to the new positions fast enough and gets itself into a right pickle.
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
  lblMuteUnmute.Left := UI.Width - lblMuteUnmute.Width - 16;       // NB: text alignment is taCenter in the Object Inspector

  lblXY.Left            := 4;
  lblXY2.Left           := 4;
  lblFrameRate.Left     := 4;
  lblBitRate.Left       := 4;
  lblAudioBitRate.Left  := 4;
  lblVideoBitRate.Left  := 4;
  lblXYRatio.Left       := 4;
  lblFileSize.Left      := 4;

  case progressBar.Visible of  TRUE:  vBase := progressBar.Top;
                              FALSE:  case isWindowCaptionVisible of
                                        TRUE: vBase := UI.Height - GetSystemMetrics(SM_CYCAPTION) - 14;  // magic number;
                                       FALSE: vBase := UI.Height - GetSystemMetrics(SM_CYCAPTION) + 9;   // magic number;
                                      end;end;

  lblXY.Top             := vBase - 128;
  lblXY2.Top            := vBase - 112;
  lblFrameRate.Top      := vBase -  96;
  lblBitRate.Top        := vBase -  80;
  lblAudioBitRate.Top   := vBase -  64;
  lblVideoBitRate.Top   := vBase -  48;
  lblXYRatio.Top        := vBase -  32;
  lblFileSize.Top       := vBase -  16;

  lblRate.Left          := Width - lblRate.Width  - 20;
  lblTab.Left           := Width - lblTab.Width   - 30;
  lblVol.Left           := Width - lblVol.Width   - 20;

  lblRate.Top           := vBase - lblTimeDisplay.Height - lblRate.Height;
  lblTab.Top            := vBase - lblTimeDisplay.Height - lblTab.Height;
  lblVol.Top            := vBase - lblTimeDisplay.Height - lblVol.Height;

  repositionTimeDisplay;
end;

function TUI.repositionTimeDisplay: boolean;
// We always want the timestamp display to be sat either on top of the progressBar or sat on the bottom edge of the window
// On other displays, the magic numbers may need to be adjusted and configurable via an application INI file
begin
  lblTimeDisplay.Left := width - lblTimeDisplay.Width - 20; // NB: text aignment is taRightJustify in the Object Inspector
  case progressBar.Visible of  TRUE:  lblTimeDisplay.Top := progressBar.Top - lblTimeDisplay.Height;
                              FALSE:  case isWindowCaptionVisible of
                                         TRUE: lblTimeDisplay.Top := UI.Height - lblTimeDisplay.Height - GetSystemMetrics(SM_CYCAPTION) - 14; // magic number
                                        FALSE: lblTimeDisplay.Top := UI.Height - lblTimeDisplay.Height - GetSystemMetrics(SM_CYCAPTION) + 9;  // magic number
                                      end;end;
end;

function TUI.repositionWMP: boolean;
// Set WMP to be 1 pixel to the left of the window and 1-pixel too wide on the right
// This [in theory] eliminates any chance of a border pixel on the left and right of the window
// Windows still insists on drawing a 1-pixel border!
// I was tempted to make the window a borderless dialog frame, but this would then make it non-resizable by the user.
begin
  WMP.Height  := UI.Height + 2;
  WMP.Width   := UI.Width + 2;
  WMP.Left    := -1;
  WMP.Top     := -1;
end;

procedure TUI.tmrRateLabelTimer(Sender: TObject);
// There is a delay between a change of playback speed, and WMP reporting the amended speed.
// So, we delay showing the change to hopefully report the correct speed.
begin
  tmrRateLabel.Enabled  := FALSE;
  lblRate.Visible       := FALSE;
end;

procedure TUI.tmrMetaDataTimer(Sender: TObject);
// We used this timer to delay fetching the video metadata from WMP. Trying to access it too soon after playback commences can cause WMP internal problems.
begin
  FX.FetchMediaMetaData;
  WMP.Cursor := crNone;
end;

procedure TUI.tmrPlayNextTimer(Sender: TObject);
// At the end of a video, WMP behaves better (internal to itself) if we use a timer to slightly delay playing the next video in the list
begin
  tmrPlayNext.Enabled := FALSE;
  FX.PlayNextFile;
end;

procedure TUI.tmrTabTimer(Sender: TObject);
// We want the tab feedback info to only be shown briefly. So, we use a timer to both show it and hide it again.
begin
  tmrTab.Enabled := FALSE;
  lblTab.Visible := FALSE;
end;

procedure TUI.tmrTimeDisplayTimer(Sender: TObject);
// update the video timestamp display
begin
  FX.UpdateTimeDisplay;
end;

procedure TUI.tmrVolTimer(Sender: TObject);
// Hide the Volume setting when the timer fires
begin
  tmrVol.Enabled := FALSE;
  lblVol.Visible := FALSE;
end;

function TUI.toggleControls(Shift: TShiftState): boolean;
// [C] = Show the timestamp display and the Mute/Unmute button OR Hide all displayed controls/metadata
// Ctrl-C Show/Hide all displayed controls/metadata
// If the timestamp and Mute/Unmute button are already being displayed, Ctrl-C will also display all the metadata info
begin
  lblRate.Caption := '';      // These are only valid at the time the user presses the appropriate key to change them
  lblTab.Caption  := '';
  lblVol.Caption  := '';

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

//  lblMuteUnmute.Visible   := vVisible;      // toggle their display status
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

procedure TUI.setupProgressBar;
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

// add thin border to fix redraw problems
// in keeping with the minimalist nature of the app, this border isn't necessary:
//        the bar becomes more pronounced as the video progresses
//        the change of cursor in progressBarMouseMove makes its presence and location obvious
//  vProgressBarStyle := GetWindowLong(ProgressBar.Handle, GWL_STYLE);
//  vProgressBarStyle := vProgressBarStyle - WS_BORDER;
//  SetWindowLong(ProgressBar.Handle, GWL_STYLE, vProgressBarStyle);
end;

procedure TUI.WMPClick(ASender: TObject; nButton, nShiftState: SmallInt; fX, fY: Integer);
// Standard functionality: Play/Pause a video when the user left-clicks on it
begin
  case WMP.playState of
    wmppsPlaying:               WMP.controls.pause;
    wmppsPaused, wmppsStopped:  main.FX.WMPplay;
  end;
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

procedure TUI.WMPMouseDown(ASender: TObject; nButton, nShiftState: SmallInt; afX, fY: Integer);
// When there is no window caption you can drag the window around by holding down a CTRL key and the left mouse button on the video.
// If the CTRL is not down, the mouse click triggers a standard Pause/Play operation.
const
  SC_DRAGMOVE = $F012;
begin
  case FX.isControlKeyDown of FALSE: begin FX.doPausePlay; EXIT; end;end;

  ReleaseCapture;
  Perform(WM_SYSCOMMAND, SC_DRAGMOVE, 0);
end;

procedure TUI.WMPMouseMove(ASender: TObject; nButton, nShiftState: SmallInt; fX, fY: Integer);
// Handle a MouseMove message from the media player: display the standard mouse cursor
begin
  WMP.cursor := crDefault; // this is changed to crNone when tmrMetaData fires
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

{ TGV }

constructor TGV.create;
begin
  inherited;
  FFiles := TList<string>.Create;
end;

destructor TGV.destroy;
begin
  case FFiles <> NIL of TRUE: FFiles.Free; end;
  inherited;
end;

function TGV.getExePath: string;
begin
  result := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
end;

initialization
  SetExceptionMask(exAllArithmeticExceptions);  // prevent WMP from generating a continuous stream of exception dialog boxes during playback
  GV := TGV.Create;
  FX := TFX.Create;

finalization
  case GV <> NIL of TRUE: begin GV.Free; end;end;
  case FX <> NIL of TRUE: begin FX.Free; end;end;

end.
