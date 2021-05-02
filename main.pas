unit main;

interface

uses
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons,
  System.Classes, WMPLib_TLB;

type
  TUI = class(TForm)
    btnNo: TLabel;
    btnPrev: TLabel;
    btnYes: TLabel;
    lblTimeDisplay: TLabel;
    pnlControls: TPanel;
    Panel2: TPanel;
    ProgressBar: TProgressBar;
    tmrPlayNext: TTimer;
    tmrTimeDisplay: TTimer;
    WMP: TWindowsMediaPlayer;
    lblRate: TLabel;
    tmrRateLabel: TTimer;
    lblMuteUnmute: TLabel;
    Panel3: TPanel;
    lblXY: TLabel;
    tmrMetaData: TTimer;
    lblFrameRate: TLabel;
    lblVideoBitRate: TLabel;
    lblAudioBitRate: TLabel;
    lblFileSize: TLabel;
    lblXYRatio: TLabel;
    lblBitRate: TLabel;
    tmrTab: TTimer;
    procedure btnNoClick(Sender: TObject);
    procedure btnPrevClick(Sender: TObject);
    procedure btnYesClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ProgressBarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ProgressBarMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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
  private
  public
    function  Fullscreen: boolean;
    function  ToggleControlPanel: boolean;
  end;

var
  UI: TUI;  // User Interface

implementation

uses
  WinApi.CommCtrl, WinApi.Windows, WinApi.Messages, WinApi.uxTheme,
  System.SysUtils, System.Generics.Collections, System.Math, System.Variants,
  FormInputBox, bzUtils;

type
  TGV = class
  strict private
    FFileIx:  integer;
    FFiles:   TList<string>;
    FMute:    boolean;
    function  GetExePath: string;
  public
    constructor Create;
    destructor  Destroy;  override;
    property    ExePath:  string        read GetExePath;
    property    FileIx:   integer       read FFileIx  write FFileIx;
    property    Files:    TList<string> read FFiles;
    property    Mute:     boolean       read FMute    write FMute;
  end;

  TFX = class
  private
    function ClearMediaMetaData: boolean;
    function DeleteThisFile(AFilePath: string): boolean;
    function DoCommandLine(aCommandLIne: string): boolean;
    function DoNightTime(AFolderPath: string): boolean;
    function DoMuteUnmute: boolean;
    function DoNOFile: boolean;
    function DoYESFile: boolean;
    function FetchMediaMetaData: boolean;
    function FindMediaFilesInFolder(aFilePath: string; aFileList: TList<string>; MinFileSize: int64 = 0): integer;
    function GoLeft: boolean;
    function GoRight: boolean;
    function GoUp: boolean;
    function GoDown: boolean;
    function isAltKeyDown: boolean;
    function isCapsLockOn: boolean;
    function isControlKeyDown: boolean;
    function isLastFile: boolean;
    function isShiftKeyDown: boolean;
    function PlayCurrentFile: boolean;
    function PlayFirstFile: boolean;
    function PlayLastFile: boolean;
    function PlayNextFile: boolean;
    function PlayPrevFile: boolean;
    function PlayWithPotPlayer: boolean;
    function RateDecrease: boolean;
    function RateIncrease: boolean;
    function RateReset: boolean;
    function RenameCurrentFile: boolean;
    function ResizeWindow: boolean;
    function SetDateTimes(aFileOrFolderPath: string; aDT: TDateTime): Boolean;
    function ShowOKCancelMsgDlg(aMsg: string): TModalResult;
    function TabForwardsBackwards: boolean;
    function UIKeyUp(var Key: Word; Shift: TShiftState): boolean;
    function UnZoom: boolean;
    function UpdateRateLabel: boolean;
    function UpdateTimeDisplay: boolean;
    function WindowCaption: boolean;
    function WindowMaximizeRestore: boolean;
    function WMPplay: boolean;
    function ZoomIn: boolean;
    function ZoomOut: boolean;
  end;

var
  FX: TFX;  // Functions
  GV: TGV;  // Global Variables

{ TFX }

function TFX.ClearMediaMetaData: boolean;
begin
  UI.lblXY.Caption            := format('XY:', []);
  UI.lblFrameRate.Caption     := format('FR:', []);
  UI.lblBitRate.Caption       := format('BR:', []);
  UI.lblAudioBitRate.Caption  := format('AR:', []);
  UI.lblVideoBitRate.Caption  := format('VR:', []);
  UI.lblXYRatio.Caption       := format('XY:', []);
  UI.lblFileSize.Caption      := format('FS:', []);
end;

function TFX.DeleteThisFile(AFilePath: string): boolean;
begin
  DoCommandLine('rot -nobanner -p 1 -r "' + AFilePath + '"');
end;

function TFX.DoCommandLine(aCommandLIne: string): boolean;
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

function TFX.DoMuteUnmute: boolean;
begin
  GV.Mute := NOT GV.Mute;
  UI.WMP.settings.mute := GV.Mute;
  case GV.Mute of
     TRUE:  UI.lblMuteUnmute.Caption  := 'Unmute';
    FALSE:  UI.lblMuteUnmute.Caption  := 'Mute';
  end;
  case GV.Mute of  TRUE: with TStringList.Create do begin SaveToFile(GV.ExePath + 'muted'); Free; end;
                  FALSE: DeleteFile(GV.ExePath + 'muted'); end;
end;

function TFX.DoNightTime(AFolderPath: string): boolean;
const
  DayTime   = 42049;
  NightTime = 2;
  StrDbsys  = '.db.sys';
var
  sr: TSearchRec;
begin
  case DirectoryExists(AFolderPath) of FALSE: EXIT; end;

  SetDateTimes(AFolderPath, DayTime);
  case isControlKeyDown of FALSE: FileSetAttr(AFolderPath, NightTime); end;

  case FindFirst(AFolderPath + '*.*', faAnyFile, sr) = 0 of  TRUE:
    repeat

      case (sr.Attr AND faDirectory) = faDirectory of
        TRUE: case (sr.Name <> '.') AND (sr.Name <> '..') of TRUE: DoNightTime(AFolderPath + sr.Name + '\'); end;
       FALSE: case pos(ExtractFileExt(sr.Name), StrDbsys) >= 0 of
                TRUE:  begin  SetDateTimes(AFolderPath + sr.Name, DayTime);
                              case isControlKeyDown of
                                FALSE: FileSetAttr(AFolderPath + sr.Name, NightTime); end;end;end;end;

      application.ProcessMessages;
    until FindNext(sr) <> 0;
  end;

  FindClose(sr);
end;

function TFX.DoNOFile: boolean;
var
  vMsg: string;
begin
  UI.WMP.controls.pause;
  vMsg := 'DELETE '#13#10#13#10'Folder: ' + ExtractFilePath(GV.Files[GV.FileIx])
        + #13#10#13#10'File: '            + ExtractFileName(GV.Files[GV.FileIx]);

  case ShowOkCancelMsgDlg(vMsg) = IDOK of
    TRUE: begin
            DeleteThisFile(GV.Files[GV.FileIx]);

            case isLastFile of TRUE: begin UI.CLOSE; EXIT; end;end;  // close app after deleting final file

            GV.Files.Delete(GV.FileIx);
            GV.FileIx := GV.FileIx - 1;

            PlayNextFile;
          end;
  end;
end;

function TFX.DoYESFile: boolean;
begin
  case isLastFile of TRUE: begin UI.CLOSE; EXIT; end;end;  // Close app after approving final file

  PlayNextFile;
end;

function TFX.FetchMediaMetaData: boolean;
begin
  UI.lblXY.Caption                := format('XY:  %s / %s', [UI.WMP.currentMedia.getItemInfo('WM/VideoWidth'), UI.WMP.currentMedia.getItemInfo('WM/VideoHeight')]);
  try UI.lblFrameRate.Caption     := format('FR:  %f fps', [StrToFloat(UI.WMP.currentMedia.getItemInfo('FrameRate')) / 1000]); except end;
  try UI.lblBitRate.Caption       := format('BR:  %d Kb/s', [trunc(StrToFloat(UI.WMP.currentMedia.getItemInfo('BitRate')) / 1024)]); except end;
  try UI.lblAudioBitRate.Caption  := format('AR:  %d Kb/s', [trunc(StrToFloat(UI.WMP.currentMedia.getItemInfo('AudioBitRate')) / 1024)]); except end;
  try UI.lblVideoBitRate.Caption  := format('VR:  %d Kb/s', [trunc(StrToFloat(UI.WMP.currentMedia.getItemInfo('VideoBitRate')) / 1024)]); except end;
  try UI.lblXYRatio.Caption       := format('XY:  %s:%s', [UI.WMP.currentMedia.getItemInfo('PixelAspectRatioX'), UI.WMP.currentMedia.getItemInfo('PixelAspectRatioY')]); except end;
  try UI.lblFileSize.Caption      := format('FS:  %d MB', [trunc(StrToFloat(UI.WMP.currentMedia.getItemInfo('FileSize')) / 1024 / 1024)]); except end;
//  ShowMessage(UI.WMP.currentMedia.getItemInfo('WM/VideoFormat'));
end;

function TFX.FindMediaFilesInFolder(aFilePath: string; aFileList: TList<string>; MinFileSize: int64 = 0): integer;
const EXTS_FILTER = '.wmv.mp4.avi.flv.mpg.mpeg.mkv.3gp.mov.m4v.vob.ts.webm.divx.m4a.mp3.wav.aac.m2ts';
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

const MOVE_PIXELS = 10;
function TFX.GoDown: boolean;
begin
  UI.WMP.Top := UI.WMP.Top + MOVE_PIXELS;
end;

function TFX.GoLeft: boolean;
begin
  UI.WMP.Left := UI.WMP.Left - MOVE_PIXELS;
end;

function TFX.GoRight: boolean;
begin
  UI.WMP.Left := UI.WMP.left + MOVE_PIXELS;
end;

function TFX.GoUp: boolean;
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
// If the high-order bit is 1, the key is down, otherwise it is up.
// If the low-order bit is 1, the key is toggled.
// A key, such as the CAPS LOCK key, is toggled if it is turned on.
// The key is off and untoggled if the low-order bit is 0. A toggled key's indicator light (if any)
// on the keyboard will be on when the key is toggled, and off when the key is untoggled.
// Check high-order bit of state...
begin
  result := (GetKeyState(VK_CONTROL) AND $80) <> 0;
end;

function TFX.isLastFile: boolean;
begin
  result := GV.FileIx = GV.Files.Count - 1;
end;

function TFX.isShiftKeyDown: boolean;
begin
  result := (GetKeyState(VK_SHIFT) AND $80) <> 0;
end;

function TFX.PlayCurrentFile: boolean;
begin
  case (GV.FileIx < 0) OR (GV.FileIx > GV.Files.Count - 1) of TRUE: EXIT; end;

  case FileExists(GV.Files[GV.FileIx]) of TRUE: begin
    WindowCaption;
    UI.WMP.URL := 'file://' + GV.Files[GV.FileIx];
    WMPplay;
  end;end;
end;

function TFX.PlayFirstFile: boolean;
begin
  case GV.Files.Count > 0 of TRUE:  begin
                                      GV.FileIx := 0;
                                      PlayCurrentFile;
                                    end;
  end;
end;

function TFX.PlayLastFile: boolean;
begin
  case GV.Files.Count > 0 of TRUE:  begin
                                      GV.FileIx := GV.Files.Count - 1;
                                      PlayCurrentFile;
                                    end;
  end;
end;

function TFX.PlayNextFile: boolean;
begin
  case GV.FileIx < GV.Files.Count - 1 of TRUE:  begin
                                                  GV.FileIx := GV.FileIx + 1;
                                                  PlayCurrentFile;
                                                end;
  end;
end;

function TFX.PlayPrevFile: boolean;
begin
  case GV.FileIx > 0 of TRUE:   begin
                                  GV.FileIx := GV.FileIx - 1;
                                  PlayCurrentFile;
                                end;
  end;
end;

function TFX.PlayWithPotPlayer: boolean;
//
begin
  DoCommandLine('B:\Tools\Pot\PotPlayerMini64.exe "' + GV.Files[GV.FileIx] + '"');
end;

function TFX.RateDecrease: boolean;
begin
  UI.WMP.settings.rate    := UI.WMP.settings.rate - 0.1;
  UI.tmrRateLabel.Enabled := TRUE;
end;

function TFX.RateIncrease: boolean;
begin
  UI.WMP.settings.rate    := UI.WMP.settings.rate + 0.1;
  UI.tmrRateLabel.Enabled := TRUE;
end;

function TFX.RateReset: boolean;
begin
  UI.WMP.settings.rate    := 1;
  UI.tmrRateLabel.Enabled := TRUE;
end;

function TFX.RenameCurrentFile: boolean;
var
  vOldFileName: string;
  vExt:         string;
  s:            string;
  vNewFilePath: string;
begin
  UI.WMP.controls.pause;
  try
    vOldFileName  := ExtractFileName(GV.Files[GV.FileIx]);
    vExt          := ExtractFileExt(vOldFileName);
    vOldFileName  := copy(vOldFileName, 1, pos(vExt, vOldFileName) - 1);
    s             := InputBoxForm(vOldFileName);
  except
    s := '';
  end;
  case (s = '') OR (s = vOldFileName) of TRUE: EXIT; end;
  vNewFilePath := ExtractFilePath(GV.Files[GV.FileIx]) + s + vExt;
  case RenameFile(GV.Files[GV.FileIx], vNewFilePath) of FALSE: ShowMessage('Rename failed:' + #13#10 +  SysErrorMessage(getlasterror));
                                                         TRUE: GV.Files[GV.FileIx] := vNewFilePath; end;
  WindowCaption;
end;

function TFX.ResizeWindow: boolean;
var
  vR: TRect;
begin
  case isControlKeyDown of
     TRUE: SetWindowPos(UI.Handle, 0, 0, 0, UI.Width - 100, UI.Height - 60, SWP_NOZORDER + SWP_NOMOVE + SWP_NOREDRAW);
    FALSE: SetWindowPos(UI.Handle, 0, 0, 0, UI.Width + 100, UI.Height + 60, SWP_NOZORDER + SWP_NOMOVE + SWP_NOREDRAW);
  end;

  GetWindowRect(UI.Handle, vR);

  SetWindowPos(UI.Handle, 0,  (GetSystemMetrics(SM_CXVIRTUALSCREEN) - (vR.Right - vR.Left)) div 2,
                              (GetSystemMetrics(SM_CYVIRTUALSCREEN) - (vR.Bottom - vR.Top)) div 2, 0, 0, SWP_NOZORDER + SWP_NOSIZE);
end;

function TFX.SetDateTimes(aFileOrFolderPath: string; aDT: TDateTime): Boolean;
// Folders and Files
var
  vHandle:      THandle;
  vSystemTime:  TSystemTime;
  vFileTime:    TFiletime;
begin
  vHandle := CreateFile(PChar(aFileOrFolderPath),
                     GENERIC_READ or GENERIC_WRITE,
                     0,
                     nil,
                     OPEN_EXISTING,
                     FILE_FLAG_BACKUP_SEMANTICS,
                     0);
  case vHandle <> INVALID_HANDLE_VALUE of
    TRUE:   try
              DateTimeToSystemTime(aDT, vSystemTime);
              SystemTimeToFileTime(vSystemTime, vFileTime);
              result := SetFileTime(vHandle, @vFileTime, @vFileTime, @vFileTime);
            finally
              CloseHandle(vHandle);
            end;
   FALSE:  result := FALSE;
  end;
end;

function TFX.TabForwardsBackwards: boolean;
//  Default   = 10th
//  SHIFT     = 20th
//  ALT       = 50th
//  CAPS LOCK = 100th
//  CTRL      = reverse
var
  vFactor: integer;
begin
  case isShiftKeyDown of
     TRUE:  vFactor := 20;
    FALSE:  case isAltKeyDown of
               TRUE:  vFactor := 50;
              FALSE:  case isCapsLockOn of
                         TRUE: vFactor := 100;
                        FALSE: vFactor := 10;
                      end;end;end;

  case isControlKeyDown of
    TRUE: UI.WMP.controls.currentPosition := UI.WMP.controls.currentPosition - (UI.WMP.currentMedia.duration / vFactor);
   FALSE: UI.WMP.controls.currentPosition := UI.WMP.controls.currentPosition + (UI.WMP.currentMedia.duration / vFactor);
  end;

  UI.lblRate.Caption  := format('%dth', [vFactor]);
  UI.tmrTab.Enabled   := TRUE;
end;

function TFX.UIKeyUp(var Key: Word; Shift: TShiftState): boolean;
const
  StrTestInternalFolder = 'B:\AudioLibrary\system\';
begin
  case ssCtrl in Shift of
     TRUE:  begin
              case Key of
                VK_RIGHT:     GoRight;
                VK_LEFT:      GoLeft;
                191, VK_UP:   GoUp;
                220, VK_DOWN: GoDown;
              end;
              Key := 0;
              EXIT;
            end;
  end;

  case Key of
//    VK_ESCAPE: case UI.WMP.fullScreen of FALSE: UI.CLOSE; end; // eXit app  - needs work
    VK_SPACE:  case UI.WMP.playState of                      // Pause / Play
                                  wmppsPlaying:               UI.WMP.controls.pause;
                                  wmppsPaused, wmppsStopped:  WMPplay; end;
    VK_RIGHT: IWMPControls2(UI.WMP.controls).step(1);        // Frame forwards
    VK_LEFT:  IWMPControls2(UI.WMP.controls).step(-1);       // Frame backwards
    191, VK_UP:         RateIncrease; // Slash               // Speed up
    220, VK_DOWN:       RateDecrease; // Backslash           // Slow down

    VK_NUMPAD8:         GoUp;
    VK_NUMPAD2:         GoDown;
    ord('k'), ord('K'): GoLeft;
    ord('l'), ord('L'): GoRight;

    ord('#'), 222     : DoNightTime(StrTestInternalFolder);   // # = NightTime                      Mods: Ctrl-#
    ord('1')          : RateReset;                            // 1 = Rate 1[00%]
    ord('a'), ord('A'): PlayFirstFile;                        // A = Play first
    ord('c'), ord('C'): UI.ToggleControlPanel;                // C = Control Panel show/hide
    ord('d'), ord('D'): DoNOFile;                             // D = Delete File
    ord('e'), ord('E'): DoMuteUnmute;                         // E = (Ears)Mute/Unmute
    ord('f'), ord('F'): UI.Fullscreen;                        // F = Fullscreen
    ord('g'), ord('G'): ResizeWindow;                         // G = Greater window size            Mods: Ctrl-G
    ord('i'), ord('I'): ZoomIn;                               // I = zoom In
    ord('m'), ord('M'): WindowMaximizeRestore;                // M = Maximize/Restore
    ord('n'), ord('N'): application.Minimize;                 // N = miNimize
    ord('o'), ord('O'): ZoomOut;                              // I = zoom Out
    ord('p'), ord('P'): PlayWithPotPlayer;                    // P = Play current video with Pot Player
    ord('q'), ord('Q'): PlayPrevFile;                         // Q = Play previous in folder
    ord('r'), ord('R'): RenameCurrentFile;                    // R = Rename
    ord('s'), ord('S'): UI.WMP.controls.currentPosition := 0; // S = start-over
    ord('t'), ord('T'): TabForwardsBackwards;                 // T = Tab forwards/backwards n%     Mods: SHIFT-T, ALT-T, CAPSLOCK, Ctrl-T,
    ord('u'), ord('U'): UnZoom;                               // U = Unzoom
    ord('v'), ord('V'): WindowMaximizeRestore;                // V = View Maximize/Restore
    ord('w'), ord('W'): PlayNextFile;                         // W = Watch next in folder
    ord('x'), ord('X'): UI.CLOSE;                             // X = eXit app
    ord('y'), ord('Y'): DoYESFile;                            // Y = Yes file
    ord('z'), ord('Z'): PlayLastFile;                         // Z = Play last in folder
  end;
  UpdateTimeDisplay;
  Key := 0;
end;

function TFX.UnZoom: boolean;
begin
  UI.WMP.Width  := UI.Panel2.Width -1;
  UI.WMP.Height := UI.Panel2.Height -1;
  UI.WMP.Top    := UI.Panel2.Top + 1;
  UI.WMP.Left   := UI.Panel2.Left + 1;
  UI.WMP.Align  := alClient;
end;

function TFX.UpdateRateLabel: boolean;
begin
  UI.lblRate.Caption  := IntToStr(round(UI.WMP.settings.rate * 100)) + '%';
end;

function TFX.UpdateTimeDisplay: boolean;
begin
  UI.lblTimeDisplay.Caption := UI.WMP.controls.currentPositionString + ' / ' + UI.WMP.currentMedia.durationString;

  UI.ProgressBar.Max        := trunc(UI.WMP.currentMedia.duration);
  UI.ProgressBar.Position   := trunc(UI.WMP.controls.currentPosition);
end;

function TFX.WindowCaption: boolean;
begin
  UI.caption := '[' + IntToStr(GV.FileIx + 1) + '/' + IntToStr(GV.Files.Count) + '] ' + ExtractFileName(GV.Files[GV.FileIx]);
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
    Unzoom;
    UI.WMP.controls.play;
    UI.WMP.settings.mute := GV.Mute;
    UI.tmrMetaData.Enabled := TRUE;
  except begin
    ShowMessage('Oops!');
    UI.WMP.controls.stop;
  end;end;
end;

function TFX.ZoomIn: boolean;
begin
  case UI.WMP.Align = alClient of TRUE: begin
                                          UI.WMP.Align    := alNone;
                                          UI.WMP.Height   := UI.Panel2.Height;
                                          UI.WMP.Width    := UI.Panel2.Width;
  end;end;

  UI.WMP.Width    := trunc(UI.WMP.Width * 1.1);
  UI.WMP.Height   := trunc(UI.WMP.Height * 1.1);
  UI.WMP.Top      := UI.Panel2.Top - ((UI.WMP.Height - UI.Panel2.Height) div 2);
  UI.WMP.Left     := UI.Panel2.Left - ((UI.WMP.Width - UI.Panel2.Width) div 2);
end;

function TFX.ZoomOut: boolean;
begin
  UI.WMP.Width    := trunc(UI.WMP.Width * 0.9);
  UI.WMP.Height   := trunc(UI.WMP.Height * 0.9);
  UI.WMP.Top      := UI.Panel2.Top - ((UI.WMP.Height - UI.Panel2.Height) div 2);
  UI.WMP.Left     := UI.Panel2.Left - ((UI.WMP.Width - UI.Panel2.Width) div 2);
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

//=====================

{$R *.dfm}

procedure TUI.btnNoClick(Sender: TObject);
begin
  FX.DoNOFile;
end;

procedure TUI.btnPrevClick(Sender: TObject);
begin
  FX.PlayPrevFile;
end;

procedure TUI.btnYesClick(Sender: TObject);
begin
  FX.DoYESFile;
end;

procedure TUI.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  WMP.controls.stop;
  CanClose := TRUE;
end;

procedure TUI.FormCreate(Sender: TObject);
var
  ProgressBarStyle: integer;
begin
  width   := trunc(780 * 1.5);
  height  := trunc(460 * 1.5);

  WMP.uiMode          := 'none';
  WMP.windowlessVideo := TRUE;
  WMP.settings.volume := 100;

  SetThemeAppProperties(0);
  ProgressBar.Brush.Color := clBlack; // Set Background colour
  SendMessage(ProgressBar.Handle, PBM_SETBARCOLOR, 0, clDkGray); // Set bar colour

  lblTimeDisplay.Caption := '';

  ProgressBarStyle  := GetWindowLong(ProgressBar.Handle, GWL_EXSTYLE);
  ProgressBarStyle  := ProgressBarStyle - WS_EX_STATICEDGE;
  SetWindowLong(ProgressBar.Handle, GWL_EXSTYLE, ProgressBarStyle);

  // add thin border to fix redraw problems
  ProgressBarStyle  := GetWindowLong(ProgressBar.Handle, GWL_STYLE);
  ProgressBarStyle  := ProgressBarStyle - WS_BORDER;
  SetWindowLong(ProgressBar.Handle, GWL_STYLE, ProgressBarStyle);

  case FileExists(GV.ExePath + 'muted') of TRUE: FX.DoMuteUnmute; end;

  case FX.isCapsLockOn of
     TRUE: GV.FileIx := FX.FindMediaFilesInFolder(ParamStr(1), GV.Files, 100000000);
    FALSE: GV.FileIx := FX.FindMediaFilesInFolder(ParamStr(1), GV.Files);
  end;

  FX.PlayCurrentFile;
end;

procedure TUI.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case ssCtrl in Shift of
     TRUE:  begin
              case Key of
                VK_RIGHT:     FX.GoRight;
                VK_LEFT:      FX.GoLeft;
                191, VK_UP:   FX.GoUp;
                220, VK_DOWN: FX.GoDown;
              end;
              Key := 0;
              EXIT;
            end;
  end;

  case Key of
    VK_RIGHT: IWMPControls2(UI.WMP.controls).step(1);        // Frame forwards
    VK_LEFT:  IWMPControls2(UI.WMP.controls).step(-1);       // Frame backwards
    VK_NUMPAD8: FX.GoUp;
    VK_NUMPAD2: FX.GoDown;
    ord('i'), ord('I'): FX.ZoomIn;
    ord('o'), ord('O'): FX.ZoomOut;
    ord('k'), ord('K'): FX.GoLeft;
    ord('l'), ord('L'): FX.GoRight;
  end;
end;

procedure TUI.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  FX.UIKeyUp(Key, Shift);
end;

procedure TUI.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  WMP.cursor := crDefault;
end;

function TUI.Fullscreen: boolean;
begin
  WMP.fullScreen := TRUE
end;

procedure TUI.lblMuteUnmuteClick(Sender: TObject);
begin
  FX.DoMuteUnmute;
end;

procedure TUI.ProgressBarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
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

procedure TUI.ProgressBarMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  newPosition : integer;
begin
  ProgressBar.Cursor            := crHSplit;
  newPosition                   := Round(x * ProgressBar.Max / ProgressBar.ClientWidth) ;
  ProgressBar.Position          := newPosition;
  WMP.controls.currentPosition  := newPosition;
  FX.UpdateTimeDisplay;
end;

procedure TUI.tmrRateLabelTimer(Sender: TObject);
begin
  tmrRateLabel.Enabled  := FALSE;
  FX.UpdateRateLabel;
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
  case lblRate.Visible of FALSE:  begin
                                    lblRate.Visible := TRUE;
                                    tmrTab.Interval := 1000; // hide slow
                                    tmrTab.Enabled  := TRUE;
                                  end;
                           TRUE:  begin
                                    lblRate.Visible := FALSE;
                                    tmrTab.Interval := 100;  // show quick
                                  end;end;
end;

procedure TUI.tmrTimeDisplayTimer(Sender: TObject);
begin
  FX.UpdateTimeDisplay;
end;

function TUI.ToggleControlPanel: boolean;
begin
  pnlControls.Visible := NOT pnlControls.Visible;
end;

procedure TUI.WMPClick(ASender: TObject; nButton, nShiftState: SmallInt; fX, fY: Integer);
begin
  case WMP.playState of
    wmppsPlaying:               WMP.controls.pause;
    wmppsPaused, wmppsStopped:  main.FX.WMPplay;
  end;
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
