Minimalist Media Player
=====================

A simple but very effective media player built around the Windows Media Player ActiveX control.

``Minimalist Media Player`` provides both a minimalist/keyboard-operated user interface (so that on-screen controls don't detract from the video) and the controls with which to view the video in a minimalist window with no borders, window title bar/caption, progress bar, video timestamp, etc, and with the window resized to fit the video perfectly, eliminating ugly black borders/bands around the video, particularly above and below. This provides an immersive viewing experience even when played in window mode rather than full-screen.

### Keyboard Controls
---------------------

Control | Action
------- | ------
`SPACEBAR` 				| pause/resume playback
`Ctrl-Up Arrow` 		| increase playback speed 10%
`/`						| increase playback speed 10%
`Ctrl-Down Arrow`		| decrease playback speed 10%
`\`						| decrease playback speed 10%
`F12`					| open video in third party video editor
`=`						| copy video file name to clipboard
`A`						| play first video in the list
`B`						| [B]lackout/restore progress bar
`Ctrl-B`				| [B]lackout/restore window caption/title bar and all on-screen artifacts
`C`						| show/Hide on-screen [C]ontrols and video timestamp
`Ctrl-C`				| show/Hide all on-screen controls, video timestamp and video metadata
`D` and `DEL`			| [D]elete current video file (after confirmation)
`Ctrl-D and Ctrl-DEL`	| [D]elete all files in the current video's folder (after confirmation)
`E`						| [E]ars - Mute/Unmute sound
`F`						| show/cancel [F]ullScreen mode
`G`						| [G]reater window size
`Ctrl-G`				| reduce (un[G]reater) window size
`H`						| position the window [H]orizontally (and Vertically) in the center of the screen
`I`						| zoom [I]n by 10% of the video's height and width
`J`						| ad[J]ust the window's aspect ratio to match the video's.
`K`						| mark this video as [K]eep
`L`						| re[L]oad the list of supported video files from the current folder
`M`						| [M]aximize / restore window
`N`						| mi[N]imize window to the Windows taskbar
`O`						| zoom [O]ut by 10% of video's height and width
`P` 					| pause the video and play it instead with [P]otplayer, if installed
`Q`						| play the previous video in the [Q]ueue/list
`R`						| [R]ename the current video file
`S`						| re[S]tart the current video from the beginning, aka [S]tartover
`T`						| [T]ab through the video a 100th (default), 50th, 20th or 10th of its duration (use ALT, SHIFT, CAPS LOCK to modify)
`Ctrl-T`				| [T]ab back through the video a 100th (default), 50th, 20th or 10th of its duration (use ALT, SHIFT, CAPS LOCK to modify)
`U`						| [U]nzoom, i.e. fit the video to the window
`V`						| maximize / restore [V]iew, same as [M]
`W`						| [W]atch the next video in the list
`X`						| e[X]it the application
`Y`						| tr[Y]out the video by sampling it at various stages
`Z`						| watch the last video in the liat
`Arrow Up`				| increase the volume by 1%
`Arrow Down`			| decrease the volume by 1%
`Ctrl-Up Arrow`			| increase the playback speed by 10%
`Ctrl-Down Arrow`		| decrease the playback speed by 10%
`0`						| hide(zero) or show the window title bar / caption
`1`						| reset the playback speed to normal, i.e. [1]00%
`2`						| resize the window so that 2 instances of the application can be placed side-by-side
`5`						| save the current video timestamp to an INI file
`6`						| retrieve a saved video timestamp from an INI file and continue playback from that point
`8`						| set the video to 1-pixel larger than the window on all four sides
`9`						| resize the window to the dimensions of the video
`RIGHT ARROW`			| step forwards one frame
`LEFT ARROW`			| step backwards one frame
Zoom|
`CTRL-RIGHT ARROW`		| when zoomed in/out, move video RIGHT inside the window
`CTRL-LEFT ARROW`		| when zoomed in/out, move video LEFT inside the window
`CTRL-UP ARROW`			| when zoomed in/out, move video UP inside the window
`CTRL-DOWN ARROW`		| when zoomed in/out, move video DOWN inside the window

Media File Formats
==================

Rather than simply taking Microsoft's word that the Windows Media Player ActiveX control supports their published list of media file formats, I have tested many file formats and ``Minimalist Media Player`` explicitly supports the following formats and file extensions:

`.wmv` `.mp4` `.avi` `.flv` `.mpg` `.mpeg` `.mkv` `.3gp` `.mov` `.m4v` `.vob` `.ts` `.webm` `.divx` `.m4a` `.mp3` `.wav` `.aac` `.m2ts` `.flac` `.mts` `.rm` `.asf`
 


Notes concerning the code
=========================




