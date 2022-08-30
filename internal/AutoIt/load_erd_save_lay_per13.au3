; Load in .erd and save out .Erd
; 1. export first the whole data file as a text file
; 2. will then export the channel names and numbers as a separate text file
; 3. finally export the event markers as another text file
; all three will have specific extensions and be exported to same folder as patient data
; also will create a running log file of all steps to same folder, and successful execution will have line reading "Success!" at the end

#include <Array.au3>
#include <File.au3>; includes additional functions called in script
#include <Date.au3>
#include <GuiListBox.au3>
#include <GuiMenu.au3>
#include <Constants.au3>
#include <WinAPI.au3>
#include <MsgBoxConstants.au3>

#RequireAdmin
AutoItSetOption ("TrayIconDebug", 1); sets autoit to display line that generates errors when they happen
AutoItSetOption ("WinWaitDelay", 1000); sets delay throughout script after every window operation
AutoItSetOption ("WinTitleMatchMode", 2); sets matching of window names such that you can call any part of the window name to manipulate it
$myErdFile = _Args("/ErdFile", "@"); use this when using command line or calling script from matlab; otherwise need to index directly to file and path as above
$myOutputDirectory = _Args("/OutputDirectory", "@")
;DriveMapAdd("X:", "\\striatum\Data")
DriveMapAdd("Z:", "\\striatum\Data", $DMA_DEFAULT, "striatum\asturias", "4st0r14s")

If Not $myErdFile Then
   $myErdFile = "Z:\neural\incoming\unsorted\keck\SHAFFER~ ISAAC_02058b53-8634-4478-89c4-2259794701b4\SHAFFER~ ISAAC_02058b53-8634-4478-89c4-2259794701b4.erd"
EndIf

;Create hard link to file on serv

If Not $myOutputDirectory Then
   $myOutputDirectory = "Z:\neural\working\p13\"
EndIf
;Global $ErdWindowTitle = "Persyst - [RIOS, GERALDINE ; Station: Uscuheegport2; Date: 2015.03.26; Start: 07:36:11; Duration: 19:30:47; File: RIOS~ GERALDIN_8d7488dd-e761-4bb9-8994-00101]"
Global $logFile = False
Global $StatusFileName = False

; split the directory from the file itself
Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
_PathSplit ($myErdFile, $sDrive, $sDir, $sFileName, $sExtension)
Local $myErdDir = $sDrive & $sDir
$myErdBasename = $sFileName
$myErdFile = $sFileName & $sExtension

;MsgBox($MB_SYSTEMMODAL, "", "Drive Z: is mapped to: " & DriveMapGet("Z:"))

;MsgBox ($MB_OK, "ErdFile", $myErdFile); use this type of message box if you want to check the value of a var (script will pause until manual input given)
;MsgBox ($MB_OK, "ErdDir", $myErdDir)
;MsgBox ($MB_OK, "OutputDir", $myOutputDirectory)




;====================;
; create status file ;
;====================;

; create file
$StatusFileName = $myOutputDirectory & $sFileName & ".STATUS"
_SetScriptStatus("RUNNING")



;======================================;
; establish output directory/filenames ;
;======================================;

; make sure output directory exists
If DirGetSize ($myOutputDirectory) = -1 Then ; folder does not exist
	Local $bStatus = DirCreate($myOutputDirectory)
	If @error Then _ProcessError("Could not create output directory",@error,@extended) EndIf
	If Not $bStatus Then
		_SetScriptStatus("ERROR")
		Exit(1)
	EndIf
EndIf

;======================================;
; establish logfile ;
;======================================;
Local Const $LogFileName = $myOutputDirectory & $myErdBasename & "_log.txt"
If FileExists($LogFileName) Then

	; create new filenames with current timestamp
	$newnow = stringregexpreplace(_NowTime(), ':', '-')
	Local $NewLogFileName = $myOutputDirectory & $myErdBasename & "_" & $newnow & "_log.txt"

	; update timestamp until the new filename is unique
	; making an assumption here that data files would not exist without one
	; the log, event, or channel files also existing (problem is that with
	; multiple recording blocks, there may be one or more data files)
	While FileExists($NewLogFileName)
		Sleep( 1000 ) ; wait 1 sec
		$newnow = stringregexpreplace(_NowTime(), ':', '-')
		$NewLogFileName = $myOutputDirectory & $myErdBasename & "_" & $newnow & "_log.txt"
	WEnd

	If FileExists($LogFileName) Then
		FileMove($LogFileName,$NewLogFileName)
		If @error Then _ProcessError("Could not rename data file " & $LogFileName & " to " & $NewLogFileName,@error,@extended) EndIf
	EndIf
EndIf




;=================;
; open log file ;
;=================;

; open file
$logFile = FileOpen($LogFileName, 2); will overwrite just in case

; initialize log file
_LogMessage("Begin Log")
_LogMessage("Erd File = " & $myErdFile)
_LogMessage("Erd Dir = " & $myErdDir)
_LogMessage("Output Dir = " & $myOutputDirectory)






;============;
; open .erd File ;
;============;

; use the shell execute function (no way to open Erd directly so use Windows file association)
FileChangeDir($myErdDir); move to the parent directory of the Erd file
Local $iPID = ShellExecute($myErdFile)
Sleep(5000)

If @error Then _ProcessError("Could not run Erd",@error,@extended) EndIf
_LogMessage("PID of the Erd process is " & $iPID)

;if using trial persyst 13, this will help get rid of the pop up window to get to the file
Sleep(5000)
Send("{ENTER}")
Sleep(2000)

Global $ErdWindowTitle = WinGetTitle("[ACTIVE]")
_ActivateWindow($ErdWindowTitle)
If @error Then _ProcessError("Erd window could not activate",@error,@extended) EndIf




;==============================;
; Save out .lay;
;==============================;

_CreateLayFile($myErdBasename)
If @error Then _ProcessError("Could not create event file",@error,@extended) EndIf
;_ActivateWindow($ErdWindowTitle)
If @error Then _ProcessError("Erd window could not activate",@error,@extended) EndIf
Sleep(3000) ; to ensure the file is available for reading




;==================;
; cleanup and exit ;
;==================;

; close the Persyst window
MouseClick($MOUSE_CLICK_LEFT, 1900, 10, 2)
If WinExists($ErdWindowTitle) Then
   WinClose($ErdWindowTitle)
EndIf
If @error Then _ProcessError("Could not close Erd window",@error,@extended) EndIf
If Not WinExists($ErdWindowTitle) Then
   _SetScriptStatus("SUCCESS ")
   _LogMessage("Finished Processing ERD")
Else
   _LogMessage("Failed to close ERD Window")
EndIf
FileClose($LogFileName)










;=============================================================================
; _Args
; Get script input arguments
;=============================================================================
Func _Args($argument, $delimiter)
	If Ubound($CmdLine) > 1 Then
		For $i = 1 To UBound($CmdLine)-1 Step 1
			If StringInStr($CmdLine[$i], $argument, 0) Then
				If StringInStr($CmdLine[$i], $delimiter, 0) Then
					$value = StringSplit($CmdLine[$i], $delimiter)
					Return $value[2]
				EndIf
			EndIf
		Next
	EndIf
EndFunc ; _Args




;=============================================================================
; _ActivateWindow
; Activate the Erd window
;=============================================================================
Func _ActivateWindow($title)
	Local $fcnstr = "(_ActivateWindow) "
	_LogMessage($fcnstr & "Attempting to activate window with title '" & $title & "'")

	; activate the window
	WinActivate($title)
	WinWaitActive($title)
	Sleep(100)

	; check for problems
	If @error Then
		SetError(1,1)
		Return
	EndIf

	; log the result
	_LogMessage($fcnstr & "Activated window with title '" & $title & "'")
EndFunc




;=============================================================================
; _ProcessError
; Process errors occuring in the script or functions
;=============================================================================
Func _ProcessError($msg,$err,$ext)
	_SetScriptStatus("ERROR")
	_LogMessage("ERR-" & $err & ", EXT-" & $ext & ": " & $msg)
	Exit(1)
EndFunc ; _ProcessError




;=============================================================================
; _SetScriptStatus
; Set the status of the script in a special status file
;=============================================================================
Func _SetScriptStatus($st)
	If Not $StatusFileName Then
		MsgBox($MB_OK,"Script Status",$st)
	Else
		If Not FileExists($StatusFileName) Then
			FileWrite($StatusFileName,$st) ; open and close the file in one call
		Else
			_FileWriteToLine($StatusFileName,1,$st,True) ; overwrite existing contents
		EndIf
	EndIf
EndFunc ; _SetScriptStatus





;=============================================================================
; _LogMessage
; Write a new message to the log file
;=============================================================================
Func _LogMessage($msg)
	If Not $logFile Then
		MsgBox($MB_OK,"Log Message",$msg)
	Else
		_FileWriteLog($logFile,$msg)
	EndIf
 EndFunc ; _LogMessage


;=============================================================================
; _CreateLayFile
; save out an .lay file from an .erd file
;=============================================================================
Func _CreateLayFile($basename)
	$fcnstr = "(_CreateLaysFile) "

;~ 	; get separate directory/filename from EventFileName
;~ 	Local $eDrive = "", $eDir = "", $eFileName = "", $eExtension = ""
;~ 	_PathSplit ($eventfile, $eDrive, $eDir, $eFileName, $eExtension)
;~ 	Local $myEventDir = $eDrive & $eDir
;~ 	Local $myEventFile = $eFileName & $eExtension
;~ 	_LogMessage($fcnstr & "Event file is " & $myEventFile & " in directory " & $myEventDir)

	;make sure that "recorded" montage is selected
	_ActivateWindow($ErdWindowTitle)
	sleep(100)
	ControlClick($ErdWindowTitle, "", "[CLASS:XTPToolBar; INSTANCE:3]", "left", 1, 35,20 )
	sleep(1000)
	MouseClick($MOUSE_CLICK_LEFT, 135, 70, 1)

	; left click to open tools
	ControlClick($ErdWindowTitle, "", "[CLASS:XTPToolBar; INSTANCE:2]", "left", 1, 40,460 )

	;open clip/export window
	MouseClick($MOUSE_CLICK_LEFT, 180, 700, 1)
	Sleep(1000)

	;select clip/export button on Persyst Clip/Export### window
    Global $clipWindow =WinGetTitle("[ACTIVE]")
	_ActivateWindow($clipWindow)
	ControlClick($clipWindow, "", "[CLASS:Button; INSTANCE:1]", "left", 1, 50, 10)
	Sleep(10)

	;Activate clip exportwindow and save out .lay
	_ActivateWindow('Archive: Choose the Output File')

    ;change output directory
	ControlClick('Archive: Choose the Output File', "", "[CLASS:ToolbarWindow32; INSTANCE:4]", "left", 1, 700, 10)
	Send($myOutputDirectory)
	Sleep(3000)
    Send("{ENTER}")
	Sleep(1000)

	;change output filename
	ControlClick('Archive: Choose the Output File', "", "[CLASS:Edit; INSTANCE:1]", "left", 1, 775, 10)
	Sleep(100)

	;send output filename, but remeber to keep below 64 Characters or file will truncate!
	;$identifier='rec'
	$split=StringSplit($myErdBasename, '_')
	$filename=$split[2]
	;Send($identifier & StringMid($split[2],1,7) & '.lay')
	Send($filename & '.lay')
	Send("{ENTER}")
	Sleep(1000)

;~ 	;save file
	ControlClick('Archive: Choose the Output File', "", "[CLASS:Button; INSTANCE:2]", "left", 1, 50, 15)
	sleep(100000)
    Global $vidProbWindow =WinGetTitle("[ACTIVE]")
	_ActivateWindow($vidProbWindow)
    ControlClick($vidProbWindow, "", "[CLASS:Button; INSTANCE:1]", "left", 1, 50, 10)

;~ 	If  StringLen($myOutputDirectory & $myErdBasename) >= 64 Then
;~ 	   _ActivateWindow('Archive')
;~ 	   ControlClick('Archive', "", "[CLASS:Button; INSTANCE:1]", "left", 1, 35, 10)
;~ 	   Sleep(5000)
;~     EndIf
	;If  FileExists($myOutputDirectory & '\' & $identifier & $myErdBasename & '.lay') Then
	If  FileExists($myOutputDirectory & '\' & $filename & '.lay') Then
	   Sleep(1000)
	   ;_ActivateWindow('Archive')
	   ControlClick('Archive', "", "[CLASS:Button; INSTANCE:2]", "left", 1, 40, 10)
	   Sleep(1000)
	   _ActivateWindow($clipWindow)
	   ControlClick($clipWindow, "", "[CLASS:Button; INSTANCE:2]", "left", 1, 50, 10)
    Else
	   Sleep(3000)
	   	WinWaitClose($clipWindow)
;~ 		While WinExists($clipWindow)
;~ 		    If WinExists("Persyst") Then
;~ 		      ControlClick("Persyst", "", "[CLASS:Button; INSTANCE:1]", "left", 1, 50, 10)
;~ 			  sleep(1000)
;~ 			  	ControlClick('Clip/Export: Choose the Output File', "", "[CLASS:Button; INSTANCE:2]", "left", 1, 50, 15)
;~ 		      _LogMessage("Cannot set start Date/Time, continued with conversion")
;~ 			  WinWaitClose($clipWindow)
;~ 		    EndIf
;~ 	    WEnd
	    WinClose($clipWindow)
    EndIf
EndFunc ; _CreateLayFile