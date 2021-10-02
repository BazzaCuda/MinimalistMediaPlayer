unit main;

interface

uses
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons,
  System.Classes, WMPLib_TLB, Vcl.AppEvnts, WinApi.Messages, WinApi.Windows;

type
  TUI = class(TForm)
    pnlBackground: TPanel;
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
  private
    procedure setupProgressBar;
  protected
  public
    function  fullScreen: boolean;
    function  repositionWMP: boolean;
    function  toggleControls(Shift: TShiftState): boolean;
  end;

var
  UI: TUI;  // User Interface

implementation

uses
  WinApi.CommCtrl,  WinApi.uxTheme,
  System.SysUtils, System.Generics.Collections, System.Math, System.Variants,
  FormInputBox, bzUtils, MMSystem, Mixer, VCL.Graphics, clipbrd, System.IOUtils;

type
  TGV = class
  strict private
    FBlackOut: boolean;
    FBlankRate: boolean;
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
    property    blankRate:    boolean       read FBlankRate write FBlankRate;
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

  TFX = class
  private
    function adjustAspectRatio: boolean;
    function blackOut: boolean;
    function clearMediaMetaData: boolean;
    function clipboardCurrentFileName: boolean;
    function deleteThisFile(AFilePath: string; Shift: TShiftState): boolean;
    function doCentreHorizontal: boolean;
    function doCommandLine(aCommandLIne: string): boolean;
    function doMuteUnmute: boolean;
    function deleteCurrentFile(Shift: TShiftState): boolean;
    function fetchMediaMetaData: boolean;
    function findMediaFilesInFolder(aFilePath: string; aFileList: TList<string>; MinFileSize: int64 = 0): integer;
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
    function speedDecrease: boolean;
    function speedIncrease: boolean;
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
// This attempts to resize the window height to match its width in the same proportion as the video dimensions,
// in order to eliminate the black bars above and below the video.
// Usage: size the window to the required width then press J to ad-J-ust the window's height to match the aspect ratio
var
  vRatio:   double;
  X, Y:     integer;
  style:    longint;
  htTitle:  integer;
  delta:    integer;
begin
  X := UI.WMP.currentMedia.imageSourceWidth;
  Y := UI.WMP.currentMedia.imageSourceHeight;

  case (X = 0) OR (Y = 0) of TRUE: EXIT; end;

  vRatio := Y / X;

  htTitle := GetSystemMetrics(SM_CYCAPTION);
  style := GetWindowLong(UI.Handle, GWL_STYLE);
  case (style and WS_CAPTION) = WS_CAPTION of  TRUE: delta := htTitle + 7;
                                              FALSE: delta := 8; end;

  UI.Height := trunc(UI.Width * vRatio) + delta;

  UI.repositionWMP;
end;

function TFX.blackOut: boolean;
begin
  GV.blackOut             := NOT GV.blackOut;
  UI.progressBar.Visible  := NOT GV.blackOut;
  UI.repositionWMP;

  case isControlKeyDown of TRUE:  begin
                                    showHideTitleBar;
                                    adjustAspectRatio;
                                  end;end;
end;

function TFX.clearMediaMetaData: boolean;
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

function TFX.deleteCurrentFile(Shift: TShiftState): boolean;
var
  vMsg: string;
begin
  UI.WMP.controls.pause;
  vMsg := 'DELETE '#13#10#13#10'Folder: ' + ExtractFilePath(GV.files[GV.fileIx]);
  case ssCtrl in Shift of  TRUE: vMsg := vMsg + '*.*';
                          FALSE: vMsg := vMsg + #13#10#13#10'File: '            + ExtractFileName(GV.files[GV.fileIx]); end;

  case ShowOkCancelMsgDlg(vMsg) = IDOK of
    TRUE: begin
            deleteThisFile(GV.files[GV.fileIx], Shift);

            case isLastFile or (ssCtrl in Shift) of TRUE: begin UI.CLOSE; EXIT; end;end;  // close app after deleting final file or deleting folder contents

            GV.files.Delete(GV.fileIx);
            GV.fileIx := GV.fileIx - 1;

            playNextFile;
          end;
  end;
end;

function TFX.deleteThisFile(AFilePath: string; Shift: TShiftState): boolean;
begin
  case ssCtrl in Shift of  TRUE: doCommandLine('rot -nobanner -p 1 -r "' + ExtractFilePath(AFilePath) + '*.* "');
                          FALSE: doCommandLine('rot -nobanner -p 1 -r "' + AFilePath + '"');
  end;
end;

function TFX.doCentreHorizontal: boolean;
var
  vR: TRect;
begin
  GetWindowRect(UI.Handle, vR);

  SetWindowPos(UI.Handle, 0,  (GetSystemMetrics(SM_CXVIRTUALSCREEN) - (vR.Right - vR.Left)) div 2,
                              (GetSystemMetrics(SM_CYVIRTUALSCREEN) - (vR.Bottom - vR.Top)) div 2, 0, 0, SWP_NOZORDER + SWP_NOSIZE);
end;

function TFX.doCommandLine(aCommandLIne: string): boolean;
var
  vStartInfo:  TStartupInfo;
  vProcInfo:   TProcessInformation;
  vCmd:        string;
  vParams:     string;
begin
  result := FALSE;
  case trim(aCommandLIne) = ''  of TRUE: EXIT; end;

  FillChar(vStartInfo, SizeOf(TStartupInfo), #0);
  FillChar(vProcInfo, SizeOf(TProcessInformation), #0);
  vStartInfo.cb          := SizeOf(TStartupInfo);
  vStartInfo.wShowWindow := SW_HIDE;
  vStartInfo.dwFlags     := STARTF_USESHOWWINDOW;

  vCmd := 'c:\windows\system32\cmd.exe';
  vParams := '/c ' + aCommandLIne;

  result := CreateProcess(PWideChar(vCmd), PWideChar(vParams), nil, nil, FALSE,
                          CREATE_NEW_PROCESS_GROUP + NORMAL_PRIORITY_CLASS, nil, PWideChar(ExtractFilePath(application.ExeName)),
                          vStartInfo, vProcInfo);
end;

function TFX.doMuteUnmute: boolean;
begin
  GV.mute := NOT GV.mute;
  g_mixer.muted := GV.mute;
  case GV.mute of
     TRUE:  UI.lblMuteUnmute.Caption  := 'Unmute';
    FALSE:  UI.lblMuteUnmute.Caption  := 'Mute';
  end;
end;

function TFX.fetchMediaMetaData: boolean;
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
const EXTS_FILTER = '.wmv.mp4.avi.flv.mpg.mpeg.mkv.3gp.mov.m4v.vob.ts.webm.divx.m4a.mp3.wav.aac.m2ts.flac.mts.rm.asf';
var
  sr:           TSearchRec;
  vFolderPath:  string;

  function isFileSizeOK: boolean;
  begin
    result := (MinFileSize <= 0) OR (AFilePath = vFolderPath + sr.Name) OR (GetFileSize(vFolderPath + sr.Name) >= MinFileSize);
  end;

  function isFileExtOK: boolean;
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

function TFX.getINIname: string;
begin
  result := ExtractFileName(GV.files[GV.fileIx]);
  result := ChangeFileExt(result, '.ini');
  result := ExtractFilePath(GV.files[GV.fileIx]) + result;
end;

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
begin
  result := (GetKeyState(VK_MENU) AND $80) <> 0;
end;

function TFX.isCapsLockOn: boolean;
begin
  result := GetKeyState(VK_CAPITAL) <> 0;
end;

function TFX.isControlKeyDown: boolean;
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
begin
  result := GV.fileIx = GV.files.Count - 1;
end;

function TFX.isShiftKeyDown: boolean;
begin
  result := (GetKeyState(VK_SHIFT) AND $80) <> 0;
end;

function TFX.keepCurrentFile: boolean;
var
  vFileName: string;
  vExt:      string;
  vFilePath: string;
begin
  UI.WMP.controls.pause;
  delay(250);
  vFileName  := '_' + ExtractFileName(GV.files[GV.fileIx]);
  vFilePath := ExtractFilePath(GV.files[GV.fileIx]) + vFileName;
  case RenameFile(GV.files[GV.fileIx], vFilePath) of FALSE: ShowMessage('Rename failed:' + #13#10 +  SysErrorMessage(getlasterror));
                                                      TRUE: GV.files[GV.fileIx] := vFilePath; end;
  windowCaption;
  UI.WMP.controls.play;
end;

function TFX.matchVideoWidth: boolean;
var X,Y: integer;
begin
  X := UI.WMP.currentMedia.imageSourceWidth;
  Y := UI.WMP.currentMedia.imageSourceHeight;

  UI.Width := X; // + 10;
end;

function TFX.openWithShotcut: boolean;
// mklink C:\ProgramFiles "C:\Program Files"
begin
  UI.WMP.controls.pause;
  doCommandLine('C:\ProgramFiles\Shotcut\shotcut.exe "' + GV.files[GV.fileIx] + '"');
end;

function TFX.playCurrentFile: boolean;
begin
  case (GV.fileIx < 0) OR (GV.fileIx > GV.files.Count - 1) of TRUE: EXIT; end;

  case FileExists(GV.files[GV.fileIx]) of TRUE: begin
    windowCaption;
    UI.WMP.URL := 'file://' + GV.files[GV.fileIx];
    unZoom;
    GV.blankRate := TRUE;
    WMPplay;
  end;end;
end;

function TFX.playFirstFile: boolean;
begin
  case GV.files.Count > 0 of TRUE:  begin
                                      GV.fileIx := 0;
                                      playCurrentFile;
                                    end;
  end;
end;

function TFX.playLastFile: boolean;
begin
  case GV.files.Count > 0 of TRUE:  begin
                                      GV.fileIx := GV.files.Count - 1;
                                      playCurrentFile;
                                    end;
  end;
end;

function TFX.playNextFile: boolean;
begin
  case isLastFile of TRUE: begin UI.CLOSE; EXIT; end;end;

  case GV.fileIx < GV.files.Count - 1 of TRUE:  begin
                                                  GV.fileIx := GV.fileIx + 1;
                                                  playCurrentFile;
                                                end;
  end;
end;

function TFX.playPrevFile: boolean;
begin
  case GV.fileIx > 0 of TRUE:   begin
                                  GV.fileIx := GV.fileIx - 1;
                                  playCurrentFile;
                                end;
  end;
end;

function TFX.playWithPotPlayer: boolean;
begin
  UI.WMP.controls.pause;
  doCommandLine('B:\Tools\Pot\PotPlayerMini64.exe "' + GV.files[GV.fileIx] + '"');
end;

function TFX.rateReset: boolean;
begin
  UI.WMP.settings.rate    := 1;
  FX.updateRateLabel;
  UI.tmrRateLabel.Enabled := TRUE;
end;

function TFX.reloadMediaFiles: boolean;
var vCurrentFile: string;
begin
  vCurrentFile := GV.files[GV.fileIx];
  findMediaFilesInFolder(vCurrentFile, GV.files);
  GV.fileIx    := GV.files.IndexOf(vCurrentFile);
  windowCaption;
end;

function TFX.renameCurrentFile: boolean;
var
  vOldFileName: string;
  vExt:         string;
  s:            string;
  vNewFilePath: string;
begin
  UI.WMP.controls.pause;
  try
    vOldFileName  := ExtractFileName(GV.files[GV.fileIx]);
    vExt          := ExtractFileExt(vOldFileName);
    vOldFileName  := copy(vOldFileName, 1, pos(vExt, vOldFileName) - 1);

    GV.inputBox   := TRUE;
    try
      s           := InputBoxForm(vOldFileName);
    finally
      GV.inputBox := FALSE;
    end;
  except
    s := '';
  end;
  case (s = '') OR (s = vOldFileName) of TRUE: EXIT; end;
  vNewFilePath := ExtractFilePath(GV.files[GV.fileIx]) + s + vExt;
  case RenameFile(GV.files[GV.fileIx], vNewFilePath) of FALSE: ShowMessage('Rename failed:' + #13#10 +  SysErrorMessage(getlasterror));
                                                         TRUE: GV.files[GV.fileIx] := vNewFilePath; end;
  windowCaption;
end;

function TFX.resizeWindow1: boolean;
begin
  UI.Width   := trunc(780 * 1.5);
  UI.Height  := trunc(460 * 1.5);
end;

function TFX.resizeWindow2: boolean;
// size so that two videos can be positioned side-by-side horizontally by the user
begin
  UI.width   := 970;
  UI.height  := 640;
end;

function TFX.resizeWindow3: boolean;
begin
  case isControlKeyDown of
     TRUE: SetWindowPos(UI.Handle, 0, 0, 0, UI.Width - 100, UI.Height - 60, SWP_NOZORDER + SWP_NOMOVE + SWP_NOREDRAW);
    FALSE: SetWindowPos(UI.Handle, 0, 0, 0, UI.Width + 100, UI.Height + 60, SWP_NOZORDER + SWP_NOMOVE + SWP_NOREDRAW);
  end;

  doCentreHorizontal;

  windowCaption;
end;

function TFX.resumePosition: boolean;
begin
  case FileExists(getINIname) of FALSE: EXIT; end;

  var sl := TStringList.Create;
  sl.LoadFromFile(getINIname);
  UI.WMP.controls.currentPosition := StrToFloat(sl[0]);
  sl.Free;
end;

function TFX.sampleVideo: boolean;
begin
  case GV.sampling of TRUE: begin GV.sampling := FALSE; EXIT; end;end;

  GV.sampling := TRUE;
  try
    repeat
      UI.WMP.controls.currentPosition := UI.WMP.controls.currentPosition + (UI.WMP.currentMedia.duration / 10);
      delay(3000);
    until GV.Closing OR NOT GV.sampling OR (UI.WMP.controls.currentPosition >= (UI.wmp.currentMedia.duration * 0.90));
  finally
//    GV.sampling := FALSE;
  end;
end;

function TFX.saveCurrentPosition: boolean;
begin
  var sl := TStringList.Create;
  sl.Add(FloatToStr(UI.WMP.controls.currentPosition));
  sl.SaveToFile(getINIname);
  sl.Free;
end;

function TFX.SpeedDecrease: boolean;
begin
  UI.WMP.settings.rate    := UI.WMP.settings.rate - 0.1;
  FX.UpdateRateLabel;
  UI.tmrRateLabel.Enabled := TRUE;
end;

function TFX.SpeedIncrease: boolean;
begin
  UI.WMP.settings.rate    := UI.WMP.settings.rate + 0.1;
  FX.UpdateRateLabel;
  UI.tmrRateLabel.Enabled := TRUE;
end;

function TFX.startOver: boolean;
begin
  UI.WMP.controls.currentPosition := 0;
  UI.WMP.controls.play;
end;

function TFX.TabForwardsBackwards: boolean;
//  Default   = 100th
//  SHIFT     = 20th
//  ALT       = 50th
//  CAPS LOCK = 10th
//  CTRL      = reverse
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
  case isControlKeyDown of TRUE: UI.lblTab.Caption := '<< ' + UI.lblTab.Caption; end;
  UI.tmrTab.Enabled   := TRUE;
end;

function TFX.UIKey(var Key: Word; Shift: TShiftState): boolean;
// Keys that can be pressed singly or held down for repeat action
begin
  result := TRUE;

  case (ssCtrl in Shift) AND GV.zoomed of
     TRUE:  case key in [VK_RIGHT, VK_LEFT, VK_UP, 191, VK_DOWN, 220] of
               TRUE:  begin
                        case Key of
                          VK_RIGHT:     FX.GoRight;                      // Move zoomed WMP right
                          VK_LEFT:      FX.GoLeft;                       // Move zoomed WMP left
                          VK_UP, 191:   FX.GoUp;                         // Move zoomed WMP up
                          VK_DOWN, 220: FX.GoDown;                       // Move zoomed WMP down
                        end;
                        Key := 0;
                        EXIT;
                      end;end;end;

  case (ssCtrl in Shift) and NOT GV.zoomed of
     TRUE:  case Key in [VK_UP, 191, VK_DOWN, 220] of
               TRUE:  begin
                        case Key of
                          VK_UP, 191:   g_mixer.Volume := g_mixer.Volume + (65535 div 100);  // volume up 1%
                          VK_DOWN, 220: g_mixer.Volume := g_mixer.Volume - (65535 div 100);  // volume down 1%
                        end;
                        UpdateVolumeDisplay;
                        UI.tmrVol.Enabled := TRUE;
                        Key := 0;
                        EXIT;
                      end;end;end;

  case Key in [VK_RIGHT, VK_LEFT, ord('i'), ord('I'), ord('o'), ord('O')] of
     TRUE:  begin
              case Key of
                VK_RIGHT: IWMPControls2(UI.WMP.controls).step(1);        // Frame forwards
                VK_LEFT:  IWMPControls2(UI.WMP.controls).step(-1);       // Frame backwards
                ord('i'), ord('I'): FX.ZoomIn;                           // Zoom In
                ord('o'), ord('O'): FX.ZoomOut;                          // Zoom Out
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
    VK_SPACE:  case UI.WMP.playState of wmppsPlaying:   UI.WMP.controls.pause;    // Pause / Play
                                        wmppsPaused,
                                        wmppsStopped:   WMPplay; end;

    VK_UP, 191 {Slash}:         SpeedIncrease;                // Speed up
    VK_DOWN, 220 {Backslash}:   SpeedDecrease;                // Slow down

    VK_F12: openWithShotcut;

//    187               : clipboardCurrentFileName;             // =   copy current filename to clipboard
    ord('a'), ord('A'): PlayFirstFile;                        // A = Play first
    ord('b'), ord('B'): BlackOut;                             // B = Blackout                       Mods: Ctrl-B
    ord('c'), ord('C'): UI.ToggleControls(Shift);             // C = Control Panel show/hide        Mods: Ctrl-C
    ord('d'), ord('D'), VK_DELETE: deleteCurrentFile(Shift);  // D = Delete File                    Mods: Ctrl-C
    ord('e'), ord('E'): DoMuteUnmute;                         // E = (Ears)Mute/Unmute
    ord('f'), ord('F'): UI.Fullscreen;                        // F = Fullscreen
    ord('g'), ord('G'): ResizeWindow3;                        // G = Greater window size            Mods: Ctrl-G
    ord('h'), ord('H'): doCentreHorizontal;                   // H = centre window Horizontally
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
    ord('t'), ord('T'): TabForwardsBackwards;                 // T = Tab forwards/backwards n%      Mods: SHIFT-T, ALT-T, CAPSLOCK, Ctrl-T
    ord('u'), ord('U'): UnZoom;                               // U = Unzoom
    ord('v'), ord('V'): WindowMaximizeRestore;                // V = View Maximize/Restore
    ord('w'), ord('W'): PlayNextFile;                         // W = Watch next in folder
    ord('x'), ord('X'): UI.CLOSE;                             // X = eXit app
    ord('y'), ord('Y'): sampleVideo;                          // Y = trYout video
    ord('z'), ord('Z'): PlayLastFile;                         // Z = Play last in folder
    ord('0')          : ShowHideTitleBar;                     // 0 = Show/Hide window title bar
    ord('1')          : RateReset;                            // 1 = Rate 1[00%]
    ord('2')          : ResizeWindow2;                        // 2 = resize so that two videos can be positioned side-by-side horizontally by the user
    ord('5')          : saveCurrentPosition;                  // 5 = save current media position to an ini file
    ord('6')          : resumePosition;                       // 6 = resume video from saved media position
    ord('9')          : matchVideoWidth;                      // 9 = match window width to video width
  end;
  UpdateTimeDisplay;
  UI.tmrRateLabel.Enabled := TRUE;
  Key := 0;
end;

function TFX.UnZoom: boolean;
begin
  GV.zoomed := FALSE;
  UI.repositionWMP;
  UI.Width := UI.Width + 1; // fix bizarre problem of WMP not repositioning after zooming
  UI.Width := UI.Width - 1; // fix bizarre problem of WMP not repositioning after zooming
end;

function TFX.UpdateRateLabel: boolean;
begin
  case GV.BlankRate of   TRUE:  begin
                                  UI.lblRate.Caption  := '';
                                  GV.BlankRate        := FALSE;
                                end;
                        FALSE:  UI.lblRate.Caption  := IntToStr(round(UI.WMP.settings.rate * 100)) + '%';
  end;
end;

function TFX.UpdateTimeDisplay: boolean;
begin
  UI.lblTimeDisplay.Caption := UI.WMP.controls.currentPositionString + ' / ' + UI.WMP.currentMedia.durationString;

  UI.ProgressBar.Max        := trunc(UI.WMP.currentMedia.duration);
  UI.ProgressBar.Position   := trunc(UI.WMP.controls.currentPosition);
end;

function TFX.UpdateVolumeDisplay: boolean;
begin
  UI.lblVol.Caption := IntToStr(trunc(g_mixer.volume / 65535 * 100))  + '%';
  UI.lblVol.Visible := TRUE;
end;

function TFX.WindowCaption: boolean;
begin
  case GV.Files.Count = 0 of TRUE: EXIT; end;
  UI.Caption := format('[%d/%d] %s', [GV.FileIx + 1, GV.Files.Count, ExtractFileName(GV.Files[GV.FileIx])]);
end;

function TFX.WindowMaximizeRestore: boolean;
begin
  case UI.WindowState = wsMaximized of TRUE: UI.WindowState := wsNormal;
                                      FALSE: UI.WindowState := wsMaximized; end;
end;

function TFX.WMPplay: boolean;
begin
  try
    UI.tmrMetaData.Enabled := FALSE;
    ClearMediaMetaData;
    UI.WMP.controls.play;
    UI.tmrMetaData.Enabled := TRUE;
  except begin
    ShowMessage('Oops!');
    UI.WMP.controls.stop;
  end;end;
end;

function TFX.ZoomIn: boolean;
begin
  GV.zoomed := TRUE;

  UI.WMP.Width    := trunc(UI.WMP.Width * 1.1);
  UI.WMP.Height   := trunc(UI.WMP.Height * 1.1);
  UI.WMP.Top      := UI.pnlBackground.Top - ((UI.WMP.Height - UI.pnlBackground.Height) div 2);
  UI.WMP.Left     := UI.pnlBackground.Left - ((UI.WMP.Width - UI.pnlBackground.Width) div 2);
end;

function TFX.ZoomOut: boolean;
begin
  GV.zoomed := TRUE;

  UI.WMP.Width    := trunc(UI.WMP.Width * 0.9);
  UI.WMP.Height   := trunc(UI.WMP.Height * 0.9);
  UI.WMP.Top      := UI.pnlBackground.Top - ((UI.WMP.Height - UI.pnlBackground.Height) div 2);   // zero minus a negative = a positive
  UI.WMP.Left     := UI.pnlBackground.Left - ((UI.WMP.Width - UI.pnlBackground.Width) div 2);    // zero minus a negative = a positive
end;

function TFX.clipboardCurrentFileName: boolean;
begin
  clipboard.AsText := TPath.GetFileNameWithoutExtension(GV.Files[GV.FileIx]);
end;

function TFX.ShowHideTitleBar: boolean;
var
  style: longint;
begin
  style := GetWindowLong(UI.Handle, GWL_STYLE);

  case (style and WS_CAPTION) = WS_CAPTION of TRUE: begin
    case UI.BorderStyle of
      bsSingle, bsSizeable:
        SetWindowLong(UI.Handle, GWL_STYLE, style and (not (WS_CAPTION)) or WS_BORDER);
      bsDialog:
        SetWindowLong(UI.Handle, GWL_STYLE, style and (not (WS_CAPTION)) or DS_MODALFRAME or WS_DLGFRAME);
    end;
    UI.Refresh;
  end;end;

  case (style and WS_CAPTION) = WS_CAPTION of FALSE: begin
    case UI.BorderStyle of
      bsSingle, bsSizeable:
        SetWindowLong(UI.Handle, GWL_STYLE, style or WS_CAPTION or WS_BORDER);
      bsDialog:
        SetWindowLong(UI.Handle, GWL_STYLE, style or WS_CAPTION or DS_MODALFRAME or WS_DLGFRAME);
    end;
    UI.Height := UI.Height + 1;  // fix Windows bug and force title bar to repaint properly
    UI.Height := UI.Height - 1;  // fix Windows bug and force title bar to repaint properly
    UI.Refresh;
  end;end;

  adjustAspectRatio;
  windowCaption;
end;

function TFX.ShowOKCancelMsgDlg(aMsg: string): TModalResult;
var
  i: Integer;
begin
  with CreateMessageDialog(aMsg, mtConfirmation, MBOKCANCEL, MBCANCEL) do
  try
    Font.Name := 'Segoe UI';
    Font.Size := 12;
    Height    := Height + 50;
    Width     := width + 200;
    for i := 0 to ControlCount - 1 do begin
      case Controls[i] is TLabel  of   TRUE: with Controls[i] as TLabel   do    Width := Width + 200; end;
      case Controls[i] is TButton of   TRUE: with Controls[i] as TButton  do  begin
                                                                                Top   := Top + 60;
                                                                                Left  := Left + 100;
                                                                              end;end;
    end;
    result := ShowModal;
  finally
    Free;
  end;
end;

//===== UI Event Handlers =====

{$R *.dfm}

procedure TUI.applicationEventsMessage(var Msg: tagMSG; var Handled: Boolean);
var
  Key: word;
  shiftState: TShiftState;
begin
  case GV.inputBox of  TRUE: EXIT; end;

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
begin
  WMP.controls.stop;
  CanClose := TRUE;
  GV.Closing := TRUE;
end;

procedure TUI.FormCreate(Sender: TObject);
begin
  case FX.isCapsLockOn of    TRUE:  FX.ResizeWindow2; // size so that two videos can be positioned side-by-side horizontally by the user
                            FALSE:  FX.ResizeWindow1; end;


  pnlBackground.Color := clBlack;

  WMP.uiMode          := 'none';
  WMP.windowlessVideo := TRUE;
  WMP.stretchToFit    := TRUE;
  WMP.settings.volume := 100;

  lblMuteUnmute.Parent    := WMP;
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

  setupProgressBar;

  case g_mixer.muted of TRUE: FX.DoMuteUnmute; end; // GV.Mute starts out FALSE; this brings it in line with the system

  case {FX.isCapsLockOn} TRUE = FALSE of
     TRUE: GV.FileIx := FX.FindMediaFilesInFolder(ParamStr(1), GV.Files, 100000000);
    FALSE: GV.FileIx := FX.FindMediaFilesInFolder(ParamStr(1), GV.Files);
  end;

  FX.PlayCurrentFile;

  GV.startup := TRUE;
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
begin
  FX.WindowCaption;

  case GV.StartUp AND FX.isCapsLockOn of  TRUE: SetWindowPos(self.Handle, 0, -6, 200, 0, 0, SWP_NOZORDER + SWP_NOSIZE); end; // left justify
  GV.startup := FALSE;

  repositionWMP;
end;

function TUI.Fullscreen: boolean;
begin
  case WMP.fullScreen of   TRUE: WMP.fullScreen := FALSE;
                          FALSE: WMP.fullScreen := TRUE;  end;
end;

procedure TUI.lblMuteUnmuteClick(Sender: TObject);
begin
  FX.DoMuteUnmute;
end;

procedure TUI.progressBarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  newPosition: integer;
begin
  case ssShift in Shift of TRUE:  begin
                                    ProgressBar.Cursor            := crHSplit;
                                    newPosition                   := Round(X * (ProgressBar.Max / ProgressBar.ClientWidth));
                                    ProgressBar.Position          := newPosition;
                                    WMP.controls.currentPosition  := newPosition;
                                  end;
                          FALSE: ProgressBar.Cursor := crDefault;
  end;
  FX.UpdateTimeDisplay;
end;

procedure TUI.progressBarMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  newPosition : integer;
begin
  ProgressBar.Cursor            := crHSplit;
  newPosition                   := Round(x * ProgressBar.Max / ProgressBar.ClientWidth) ;
  ProgressBar.Position          := newPosition;
  WMP.controls.currentPosition  := newPosition;
  FX.UpdateTimeDisplay;
end;

function TUI.repositionWMP: boolean;
begin
  WMP.Left    := pnlBackground.Left - 1;
  WMP.Height  := pnlBackground.Height + 2;
  WMP.Width   := pnlBackground.Width + 2;
  WMP.Top     := pnlBackground.Top - 1;
end;

procedure TUI.tmrRateLabelTimer(Sender: TObject);
begin
  tmrRateLabel.Enabled  := FALSE;
  case lblRate.Visible of FALSE:  begin
                                    lblRate.Visible       := TRUE;
                                    tmrRateLabel.Interval := 500; // delay showing to allow WMP time to adjust the rate internally
                                    tmrRateLabel.Enabled  := TRUE;
                                  end;
                           TRUE:  begin
                                    lblRate.Visible := FALSE;
                                    tmrRateLabel.Interval := 100; // hide it quickly so that the rate can be adjusted quickly in succession
                                  end;
  end;
end;

procedure TUI.tmrMetaDataTimer(Sender: TObject);
begin
  FX.FetchMediaMetaData;
  WMP.Cursor := crNone;
end;

procedure TUI.tmrPlayNextTimer(Sender: TObject);
begin
  tmrPlayNext.Enabled := FALSE;
  FX.PlayNextFile;
end;

procedure TUI.tmrTabTimer(Sender: TObject);
begin
  tmrTab.Enabled := FALSE;
  case lblTab.Visible of FALSE:  begin
                                    lblTab.Visible := TRUE;
                                    tmrTab.Interval := 1000; // hide slow
                                    tmrTab.Enabled  := TRUE;
                                  end;
                           TRUE:  begin
                                    lblTab.Visible := FALSE;
                                    tmrTab.Interval := 100;  // show quick
                                  end;end;
end;

procedure TUI.tmrTimeDisplayTimer(Sender: TObject);
begin
  FX.UpdateTimeDisplay;
end;

procedure TUI.tmrVolTimer(Sender: TObject);
begin
  tmrVol.Enabled := FALSE;
  lblVol.Visible := FALSE;
end;

function TUI.ToggleControls(Shift: TShiftState): boolean;
var vVisible: boolean;
begin
  lblRate.Caption := '';
  lblTab.Caption  := '';
  lblVol.Caption  := '';

  case (ssCtrl in Shift) AND lblTimeDisplay.Visible and NOT lblXY.Visible of TRUE: begin
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

  vVisible := NOT lblMuteUnmute.Visible;

  lblMuteUnmute.Visible   := vVisible;
  lblTimeDisplay.Visible  := vVisible;

  case (ssCtrl in Shift) or NOT vVisible of TRUE: begin
    lblXY.Visible           := vVisible;
    lblXY2.Visible          := vVisible;
    lblFrameRate.Visible    := vVisible;
    lblBitRate.Visible      := vVisible;
    lblAudioBitRate.Visible := vVisible;
    lblVideoBitRate.Visible := vVisible;
    lblXYRatio.Visible      := vVisible;
    lblFileSize.Visible     := vVisible;
  end;end;
end;

procedure TUI.setupProgressBar;
var
  ProgressBarStyle: Integer;
begin
  SetThemeAppProperties(0);
  ProgressBar.Brush.Color := clBlack;
  // Set Background colour
  SendMessage(ProgressBar.Handle, PBM_SETBARCOLOR, 0, clDkGray);
  // Set bar colour
  ProgressBarStyle := GetWindowLong(ProgressBar.Handle, GWL_EXSTYLE);
  ProgressBarStyle := ProgressBarStyle - WS_EX_STATICEDGE;
  SetWindowLong(ProgressBar.Handle, GWL_EXSTYLE, ProgressBarStyle);
  // add thin border to fix redraw problems
  ProgressBarStyle := GetWindowLong(ProgressBar.Handle, GWL_STYLE);
  ProgressBarStyle := ProgressBarStyle - WS_BORDER;
  SetWindowLong(ProgressBar.Handle, GWL_STYLE, ProgressBarStyle);
end;

procedure TUI.WMPClick(ASender: TObject; nButton, nShiftState: SmallInt; fX, fY: Integer);
begin
  case WMP.playState of
    wmppsPlaying:               WMP.controls.pause;
    wmppsPaused, wmppsStopped:  main.FX.WMPplay;
  end;
end;

procedure TUI.WMPKeyDown(ASender: TObject; nKeyCode, nShiftState: SmallInt);
var Key: WORD;
begin
  Key := nKeyCode;
  FX.UIKey(Key, TShiftState(nShiftState));
end;

procedure TUI.WMPKeyUp(ASender: TObject; nKeyCode, nShiftState: SmallInt);
var Key: WORD;
begin
  Key := nKeyCode;
  FX.UIKeyUp(Key, TShiftState(nShiftState));
end;

procedure TUI.WMPMouseMove(ASender: TObject; nButton, nShiftState: SmallInt; fX, fY: Integer);
begin
  WMP.cursor := crDefault;
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
  case NewState of wmppsPlaying: tmrTimeDisplay.Enabled     := True;

                   wmppsStopped,
                   wmppsPaused,
                   wmppsMediaEnded: tmrTimeDisplay.Enabled  := FALSE; end;

  case NewState of wmppsMediaEnded: tmrPlayNext.Enabled     := TRUE; end;
end;

{ TGV }

constructor TGV.Create;
begin
  inherited;
  FFiles := TList<string>.Create;
end;

destructor TGV.Destroy;
begin
  case FFiles <> NIL of TRUE: FFiles.Free; end;
  inherited;
end;

function TGV.GetExePath: string;
begin
  result := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
end;

initialization
  SetExceptionMask(exAllArithmeticExceptions);
  GV := TGV.Create;
  FX := TFX.Create;

finalization
  case GV <> NIL of TRUE: begin GV.Free; end;end;
  case FX <> NIL of TRUE: begin FX.Free; end;end;

end.
