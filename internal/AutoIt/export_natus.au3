; export_natus
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

#RequireAdmin
AutoItSetOption ("TrayIconDebug", 1); sets autoit to display line that generates errors when they happen
AutoItSetOption ("WinWaitDelay", 1000); sets delay throughout script after every window operation
AutoItSetOption ("WinTitleMatchMode", 2); sets matching of window names such that you can call any part of the window name to manipulate it
$myNatusFile = _Args("/NatusFile", "@"); use this when using command line or calling script from matlab; otherwise need to index directly to file and path as above
$myOutputDirectory = _Args("/OutputDirectory", "@")
If Not $myNatusFile Then
   $myNatusFile = "C:\Users\Spencer\Documents\Data\Keck\Bernal Jennifer_12017_Ph2D3\BERNAL~ JENNIF_0b8d1e98-b465-429a-a304-d9be46836da2.eeg"
EndIf
If Not $myOutputDirectory Then
   $myOutputDirectory = "C:\Users\Spencer\Documents\Data\source\P001\20170118-PH2\data\"
EndIf
Global $NatusWindowTitle = "Natus NeuroWorks EEG"
Global $logFile = False
Global $StatusFileName = False

; split the directory from the file itself
Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
_PathSplit ($myNatusFile, $sDrive, $sDir, $sFileName, $sExtension)
Local $myNatusDir = $sDrive & $sDir
$myNatusBasename = $sFileName
$myNatusFile = $sFileName & $sExtension

;MsgBox ($MB_OK, "NatusFile", $myNatusFile); use this type of message box if you want to check the value of a var (script will pause until manual input given)
;MsgBox ($MB_OK, "NatusDir", $myNatusDir)
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

; initialize file paths/names
Local Const $DataBaseName = $myOutputDirectory & $myNatusBasename & "_data"
Local Const $LogFileName = $myOutputDirectory & $myNatusBasename & "_log.txt"
Local Const $EventFileName = $myOutputDirectory & $myNatusBasename & "_event.txt"
Local Const $ChannelFileName = $myOutputDirectory & $myNatusBasename & "_channel.txt"
If FileExists($LogFileName) Or FileExists($EventFileName) Or FileExists($ChannelFileName) Then

	; create new filenames with current timestamp
	$newnow = stringregexpreplace(_NowTime(), ':', '-')
	Local $NewDataBaseName = $myOutputDirectory & $myNatusBasename & "_" & $newnow & "_data"
	Local $NewLogFileName = $myOutputDirectory & $myNatusBasename & "_" & $newnow & "_log.txt"
	Local $NewEventFileName = $myOutputDirectory & $myNatusBasename & "_" & $newnow & "_event.txt"
	Local $NewChannelFileName = $myOutputDirectory & $myNatusBasename & "_" & $newnow & "_channel.txt"

	; update timestamp until the new filename is unique
	; making an assumption here that data files would not exist without one
	; the log, event, or channel files also existing (problem is that with
	; multiple recording blocks, there may be one or more data files)
	While FileExists($NewLogFileName) Or FileExists($NewEventFileName) Or FileExists($NewChannelFileName)
		Sleep( 1000 ) ; wait 1 sec
		$newnow = stringregexpreplace(_NowTime(), ':', '-')
		$NewDataBaseName = $myOutputDirectory & $myNatusBasename & "_" & $newnow & "_data"
		$NewLogFileName = $myOutputDirectory & $myNatusBasename & "_" & $newnow & "_log.txt"
		$NewEventFileName = $myOutputDirectory & $myNatusBasename & "_" & $newnow & "_event.txt"
		$NewChannelFileName = $myOutputDirectory & $myNatusBasename & "_" & $newnow & "_channel.txt"
	WEnd

	; "rename" the files by moving them
	Local $idx = 1
	Local $OldDataFile = $DataBaseName & "_" & StringFormat("%03d", $idx) & ".txt"
	Local $NewDataFile = $NewDataBaseName & "_" & StringFormat("%03d", $idx) & ".txt"
	While FileExists($OldDataFile)
		FileMove($OldDataFile,$NewDataFile)
		If @error Then _ProcessError("Could not rename data file " & $OldDataFile & " to " & $NewDataFile,@error,@extended) EndIf
		$idx += 1
		Local $OldDataFile = $DataBaseName & "_" & StringFormat("%03d", $idx) & ".txt"
		Local $NewDataFile = $NewDataBaseName & "_" & StringFormat("%03d", $idx) & ".txt"
	WEnd
	If FileExists($LogFileName) Then
		FileMove($LogFileName,$NewLogFileName)
		If @error Then _ProcessError("Could not rename data file " & $LogFileName & " to " & $NewLogFileName,@error,@extended) EndIf
	EndIf
	If FileExists($EventFileName) Then
		FileMove($EventFileName,$NewEventFileName)
		If @error Then _ProcessError("Could not rename data file " & $EventFileName & " to " & $NewEventFileName,@error,@extended) EndIf
	EndIf
	If FileExists($ChannelFileName) Then
		FileMove($ChannelFileName,$NewChannelFileName)
		If @error Then _ProcessError("Could not rename data file " & $ChannelFileName & " to " & $NewChannelFileName,@error,@extended) EndIf
	EndIf
EndIf




;=================;
; create log file ;
;=================;

; open file
$logFile = FileOpen($LogFileName, 2); will overwrite just in case

; initialize log file
_LogMessage("Begin Log")
_LogMessage("Natus File = " & $myNatusFile)
_LogMessage("Natus Dir = " & $myNatusDir)
_LogMessage("Output Dir = " & $myOutputDirectory)
_LogMessage("Data Basename = " & $DataBaseName)
_LogMessage("Event File = " & $EventFileName)
_LogMessage("Channel File = " & $ChannelFileName)




;============;
; open Natus ;
;============;

; use the shell execute function (no way to open Natus directly so use Windows file association)
FileChangeDir($myNatusDir); move to the parent directory of the Natus file
Local $iPID = ShellExecute($myNatusFile)
If @error Then _ProcessError("Could not run Natus",@error,@extended) EndIf
_LogMessage("PID of the Natus process is " & $iPID)
_ActivateWindow($NatusWindowTitle)
If @error Then _ProcessError("Natus window could not activate",@error,@extended) EndIf




;==============================;
; export events into text file ;
;==============================;

_CreateEventsFile($EventFileName,$myNatusBasename)
If @error Then _ProcessError("Could not create event file",@error,@extended) EndIf
_LogMessage("Created events file " & $EventFileName)
_ActivateWindow($NatusWindowTitle)
If @error Then _ProcessError("Natus window could not activate",@error,@extended) EndIf
Sleep(100) ; to ensure the file is available for reading




;=============================;
; Get record start/stop times ;
;=============================;

Local $NumRecordStart = _GetNumRecordStarts($EventFileName)
If @error Then _ProcessError("Could not create event file",@error,@extended) EndIf
Local $RecordStartTimes[$NumRecordStart] = [0]
Local $RecordStopTimes[$NumRecordStart] = [0]
_GetRecordStartStopTimes($EventFileName,$RecordStartTimes,$RecordStopTimes)
Local $GlobalRecordStartTime = $RecordStartTimes[0]
Local $GlobalRecordStopTime = $RecordStopTimes[UBound($RecordStopTimes)-1]
_LogMessage("Set GlobalRecordStartTime to " & $GlobalRecordStartTime)
_LogMessage("Set GlobalRecordStopTime to " & $GlobalRecordStopTime)


;===========================;
; export data to ASCII file ;
;===========================;

; loop over recording blocks
Local $SliderPixelMarginsLeftRight = 14
Local $SliderPixelMarginsTopBottom = 10
For $RecordBlock = 0 to $NumRecordStart-1
	Local $LocalDataFileName = $DataBaseName & "_" & StringFormat("%03d", $RecordBlock+1) & ".txt"
	Local $blockstr = "Block " & $RecordBlock+1 & ": "
	Local $BlockStartTime = $RecordStartTimes[$RecordBlock]
	Local $BlockStopTime = $RecordStopTimes[$RecordBlock]
	_LogMessage($blockstr & "Expected time span " & $BlockStartTime & " to " & $BlockStopTime)


	; OPEN EXPORT DIALOG

	; trigger menu command
	Send("!fe")
	_ActivateWindow("Save As")
	If @error Then _ProcessError("Could not activate Save As dialog",@error,@extended) EndIf
	_LogMessage($blockstr & "Started Export/Save-As dialog")

	; set the output file
	ControlSetText("Save As", "Export", "[CLASS:Edit; INSTANCE:1]", $LocalDataFileName)
	If @error Then _ProcessError("Could not set export file in Save As dialog",@error,@extended) EndIf
	_LogMessage($blockstr & "Set export file to " & $LocalDataFileName)

	; click the save button
	ControlClick("Save As", "&Save", "[CLASS:Button; INSTANCE:2]")
	If @error Then _ProcessError("Could not click save button",@error,@extended) EndIf
	_LogMessage($blockstr & "Clicked Save button")

	; wait for export file window to load then activate it
	_ActivateWindow("Export File")
	If @error Then _ProcessError("Could not open the Export File dialog",@error,@extended) EndIf
	_LogMessage($blockstr & "Opened the Export File window")
	
	; move to first time field



	; PROCESS START TIME

	; get sliders to the right date, then use text fields to enter specific time
	Send("{TAB 4}") ; move to slider1
	Local $ActualSliderTime = _InitSlider($BlockStartTime,"Static1",$blockstr,"{LEFT}")
	If @error Then _ProcessError("Could not set slider to a reasonable value",@error,@extended) EndIf
	_LogMessage($blockstr & "Successfully set slider for start time to " & $ActualSliderTime)

	; set the time fields to the exact times requested for the current recording block
	Send("+{TAB}") ; move back to time field
	Local $ActualTime = _InitTime($BlockStartTime,"Static1",$GlobalRecordStartTime,$GlobalRecordStopTime,$blockstr,"{LEFT}")
	If @error Then _ProcessError("Could not set start time",@error,@extended) EndIf
	_LogMessage($blockstr & "Successfully set the export start time to " & $ActualTime)



	; PROCESS STOP TIME

	; get sliders to the right date, then use text fields to enter specific time
	Send("{TAB 3}") ; move to slider2
	$ActualSliderTime = _InitSlider($BlockStopTime,"Static2",$blockstr,"{RIGHT}")
	If @error Then _ProcessError("Could not set slider to a reasonable value",@error,@extended) EndIf
	_LogMessage($blockstr & "Successfully set slider for stop time to " & $ActualSliderTime)

	; set the time fields to the exact times requested for the current recording block
	Send("+{TAB}") ; move back to second time field
	$ActualTime = _InitTime($BlockStopTime,"Static2",$GlobalRecordStartTime,$GlobalRecordStopTime,$blockstr,"{RIGHT}")
	If @error Then _ProcessError("Could not set stop time",@error,@extended) EndIf
	_LogMessage($blockstr & "Successfully set the export stop time to " & $ActualTime)



	; START EXPORT

	; hit the OK button and wait for exporting file window to activate and close
	ControlClick("Export File", "OK", "[CLASS:Button; INSTANCE:11]")
	_ActivateWindow("Exporting File")
	WinWaitClose("Exporting File")
	If @error Then _ProcessError("Could not finish export",@error,@extended) EndIf
	_LogMessage($blockstr & "Finished export of block " & $RecordBlock+1 & "/" & $NumRecordStart)
Next





;==========================================;
; export channel nomenclature to text file ;
;==========================================;

_CreateChannelMontageFile($ChannelFileName,$myNatusFile,$myNatusDir,$myOutputDirectory)
If @error Then _ProcessError("Could not create channel montage file",@error,@extended) EndIf
_LogMessage("Created channel montage file " & $ChannelFileName)





;==================;
; cleanup and exit ;
;==================;

; close the Natus window
WinClose("Natus")
If @error Then _ProcessError("Could not close Natus window",@error,@extended) EndIf
_LogMessage("Closed Natus window")
_SetScriptStatus("SUCCESS," & $NumRecordStart)
















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
; Activate the Natus window
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
; _GetCurrentTime
; Force update of and read the current time. Note the "time" field must
; be the currently selected GUI element in the Natus data export dialog
;=============================================================================
Func _GetCurrentTime($ctrlname,$key)

	; Force update of static control text
	; require current active control element to be the time field
	Sleep(100)
	Send("{TAB}") ; move to slider
	Sleep(100)
	Send($key) ; force keypress handler to update static text control
	Sleep(100)
	Send("+{TAB}") ; move back to time field
	Sleep(100)

	; get static field text and rearrange to autoit-style date
	$currtime = ControlGetText ( "Export File", "", $ctrlname )
	$currtime = StringRegExpReplace($currtime, "^(\d{2})/(\d{2})/(\d{4})\s+(\d{2}):(\d{2}):(\d{2})$","$3/$1/$2 $4:$5:$6")
	Return $currtime

EndFunc ; _GetCurrentTime





;=============================================================================
; _InitSlider
; Set slider in the Natus export data dialog box to a value that allows
; entering the exact time in the time fields
; note the slider must be already selected prior to running this function
;=============================================================================
Func _InitSlider($recordtime,$ctrlname,$blockstr,$key)
	Local $fcnstr = $blockstr & "(_InitSlider) "

	; get the current time
	Send("+{TAB}") ; move to the time field
	Local $currtime = _GetCurrentTime($ctrlname,$key)
	Send("{TAB}") ; move to slider
	_LogMessage($fcnstr & "Current slider time is " & $currtime)

	; initialize date offset - we need the month/day to be the same
	Local $DateOffset = _DateDiff('d',StringLeft($currtime,10),StringLeft($recordtime,10))
	_LogMessage($fcnstr & "Difference in dates " & $currtime & ", " & $recordtime & " is " & $DateOffset)

	; while the month/day is not the same, keep trying to move the sliders
	Local $LoopCounter = 0 ; keep track of the number of attempts
	Local $MaxTries = 100 ; only allow 100 tries
	While $DateOffset <> 0

		; check the loop counter against the max number of tries
		$LoopCounter = $LoopCounter + 1
		If $LoopCounter > $MaxTries Then
			SetError(1,1)
			Return
		EndIf

		; keep track of the time when we started attempting to move the slider
		Local $tmptime = $currtime

		; keep trying PGUP/PGDN until it moves and updates the static text field
		While Not StringCompare($currtime,$tmptime)

			; move the slider using PGUP/PGDN keys
			If $DateOffset < 0 Then
				_LogMessage($fcnstr & "Negative offset: sending PGUP")
				Send("{PGUP}") ; move one slider position left
				Sleep(100)
			ElseIf $DateOffset > 0 Then
				_LogMessage($fcnstr & "Positive offset: sending PGDN")
				Send("{PGDN}") ; move one slider position right
				Sleep(100)
			EndIf

			; get the updated time
			Send("+{TAB}") ; move to the time field
			Local $tmptime = _GetCurrentTime($ctrlname,$key)
			Send("{TAB}") ; move to slider
			_LogMessage($fcnstr & "New slider position is " & $tmptime)
		WEnd

		; update current time
		$currtime = $tmptime

		; update date offset
		$DateOffset = _DateDiff('d',StringLeft($currtime,10),StringLeft($recordtime,10))
		_LogMessage($fcnstr & "Difference in dates " & $currtime & ", " & $recordtime & " is " & $DateOffset)
	WEnd

	; note the current position of the slider
	_LogMessage($fcnstr & "Final slider position is " & $currtime)

	; return the current time
	Return $currtime

EndFunc ; _InitSlider





;=============================================================================
; _InitTime
; Enter specific times into the time fields of the Natus data export dialog
; note the time field must be already selected prior to running this function
;   - recordtime: desired time to start the export at
;   - ctrlname: name of the static text control (to read the current time)
;   - globalstart: global start date/time of the data recording
;   - globalstop: global end date/time of the data recording
;   - blockstr: string to prepend log messages with recording block information
;=============================================================================
Func _InitTime($recordtime,$ctrlname,$globalstart,$globalstop,$blockstr,$key)
	Local $fcnstr = $blockstr & "(_InitTime) "
	_LogMessage($fcnstr & "recordtime set to " & $recordtime)
	_LogMessage($fcnstr & "ctrlname set to " & $ctrlname)
	_LogMessage($fcnstr & "globalstart set to " & $globalstart)
	_LogMessage($fcnstr & "globalstop set to " & $globalstop)

	; get the current time
	Local $currtime = _GetCurrentTime($ctrlname,$key)

	; compute 12-hour desired time (with meridiem)
	Local $myDesiredTime = StringRegExpReplace($recordtime,"^\d{4}/\d{2}/\d{2}\s+(\d{2}:\d{2}:\d{2})$","$1")
	Local $myDesiredMeridiem = "AM"
	If Number(StringLeft($myDesiredTime,2)) >= 12 Then
		$myDesiredTime = StringRegExpReplace($myDesiredTime,"^\d{2}(.*)$",StringFormat("%02d",Number(StringLeft($myDesiredTime,2))-12) & "$1")
		$myDesiredMeridiem = "PM"
	EndIf
	_LogMessage($fcnstr & "Desired time is " & $myDesiredTime & " " & $myDesiredMeridiem & " based on datetime " & $recordtime)

	; compute 12-hour current time (with meridiem)
	Local $myCurrentTime = StringRegExpReplace($currtime,"^\d{4}/\d{2}/\d{2}\s+(\d{2}:\d{2}:\d{2})$","$1")
	Local $myCurrentMeridiem = "AM"
	If Number(StringLeft($myCurrentTime,2)) >= 12 Then
		$myCurrentTime = StringRegExpReplace($myCurrentTime,"^\d{2}(.*)$",StringFormat("%02d",Number(StringLeft($myCurrentTime,2))-12) & "$1")
		$myCurrentMeridiem = "PM"
	EndIf
	_LogMessage($fcnstr & "Current time is " & $myCurrentTime & " " & $myCurrentMeridiem & " based on datetime " & $currtime)

	; construct desired time, current meridiem with date of current time
	Local $DTCM = $myDesiredTime
	If Not StringCompare($myCurrentMeridiem, "PM") Then
		$DTCM = StringRegExpReplace($DTCM,"^\d{2}(.*)$",StringFormat("%02d",Number(StringLeft($DTCM,2))+12) & "$1")
	EndIf
	$DTCM = StringLeft($currtime,10) & " " & $DTCM ; prepend the year of the current datetime
	Local $diffStartDTCM = _DateDiff('s',$globalstart,$DTCM)
	Local $diffDTCMStop = _DateDiff('s',$DTCM,$globalstop)
	_LogMessage($fcnstr & "desired time with current meridiem is " & $DTCM & " (datediff is " & $diffStartDTCM & " / " & $diffDTCMStop & ")")

	; construct current time, desired meridiem with date of current time
	Local $CTDM = $myCurrentTime
	If Not StringCompare($myDesiredMeridiem, "PM") Then
		$CTDM = StringRegExpReplace($CTDM,"^\d{2}(.*)$",StringFormat("%02d",Number(StringLeft($CTDM,2))+12) & "$1")
	EndIf
	$CTDM = StringLeft($currtime,10) & " " & $CTDM ; prepend the year of the current datetime
	Local $diffStartCTDM = _DateDiff('s',$globalstart,$CTDM)
	Local $diffCTDMStop = _DateDiff('s',$CTDM,$globalstop)
	_LogMessage($fcnstr & "current time with desired meridiem is " & $CTDM & " (datediff is " & $diffStartCTDM & " / " & $diffCTDMStop & ")")

	; if the desired time, current meridiem is outside the range of recording times, we need to set the meridiem first
	; but if the current time, desired meridiem is outside the range of recording times, we need to set the time first
	If $diffStartDTCM >= 0 And $diffDTCMStop >= 0 Then

		; it's okay to update in the left-to-right order: hours, minutes, seconds, meridiem
		_LogMessage($fcnstr & "Sending time in left-to-right order")
		Send($myDesiredTime & "{RIGHT}" & $myDesiredMeridiem) ; set hours/minutes/seconds/meridiem
	ElseIf $diffStartCTDM >=0 And $diffCTDMStop >= 0 Then

		; it's okay to update meridiem first then hours, minutes, seconds
		_LogMessage($fcnstr & "Sending time meridiem first, then hours/minutes/seconds")
		Send("{RIGHT 3}") ; move to meridiem position
		Send($myDesiredMeridiem) ; set the meridiem
		Send("{LEFT 3}") ; move back to hours position
		Send($myDesiredTime) ; send hours/minutes/seconds
	Else

		; we don't have a way to handle this situation yet...
		_LogMessage($fcnstr & "No logical way to enter a valid time!")
		SetError(1,1)
		Return
	EndIf

	; verify the selected start datetime
	Local $ErrorInTime = _ValidateTime($ctrlname,$recordtime)
	If @error Then _ProcessError("Validation failed for time (error is " & $ErrorInTime & " seconds)",@error,@extended) EndIf
	_LogMessage($fcnstr & "Time validation succeeded (error is " & $ErrorInTime & " seconds)")

	; get final value of the time
	Return _GetCurrentTime($ctrlname,$key)

EndFunc ; _InitTime





;=============================================================================
; _GetAbsoluteStartTime
; Get the absolute start time of the data file
; first time field should be currently selected GUI element
;=============================================================================
Func _GetAbsoluteStartTime($RecStartTimes)

	Local $TimeAtEntry = _GetCurrentTime("Static1","{LEFT}")

	Send("{TAB 1}") ; move to slider1
	Send("{PGUP 5}") ; move slider1 to extreme left position
	Send("+{TAB}") ; move to first time field
	Local $starttime = _GetCurrentTime("Static1","{LEFT}") ; arrow keys do in fact move the sliders in VERY small increments
	_LogMessage($blockstr & "Current start time is " & $starttime)
	
	
	

		; keep trying PGUP/PGDN until it moves and updates the static text field
		While Not StringCompare($currtime,$tmptime)

			; move the slider using PGUP/PGDN keys
			If $DateOffset < 0 Then
				_LogMessage($fcnstr & "Negative offset: sending PGUP")
				Send("{PGUP}") ; move one slider position left
				Sleep(100)
			ElseIf
				_LogMessage($fcnstr & "Positive offset: sending PGDN")
				Send("{PGDN}") ; move one slider position right
				Sleep(100)
			EndIf

			; get the updated time
			Send("+{TAB}") ; move to the time field
			Local $tmptime = _GetCurrentTime($ctrlname,$key)
			Send("{TAB}") ; move to slider
			_LogMessage($fcnstr & "New slider position is " & $tmptime)
		WEnd
EndFunc ; _GetAbsoluteStartTime





;=============================================================================
; _GetAbsoluteStopTime
; Get the absolute stop time of the data file
; slider2 should be currently selected GUI element
;=============================================================================
Func _GetAbsoluteStopTime($RecStopTimes)


	; get absolute stop
	Send("{TAB 3}"); move to slider2
	Send("{PGDN 5}") ; move slider2 to extreme right position
	Send("+{TAB}") ; move to second time field
	Local $stoptime = _GetCurrentTime("Static2","{RIGHT}") ; arrow keys do in fact move the sliders in VERY small increments
	_LogMessage($blockstr & "Current stop time is " & $stoptime)
EndFunc ; _GetAbsoluteStopTime





;=============================================================================
; _ValidateTime
; Validate the current times entered into the static time fields of the
; Natus data export dialog box
;=============================================================================
Func _ValidateTime($ctrlname,$destime)

	; Force update of static control text
	; require current active control element to be the time field
	Sleep(100)
	Send("{TAB}") ; move to slider
	Sleep(100)
	Send("{RIGHT}") ; force keypress handler to update static text control
	Sleep(100)
	Send("+{TAB}") ; move back to time field
	Sleep(100)

	; grab control text (current time)
	$currtime = ControlGetText ( "Export File", "", $ctrlname )
	$currtime = StringRegExpReplace($currtime, "^(\d{2})/(\d{2})/(\d{4})\s+(\d{2}):(\d{2}):(\d{2})$","$3/$1/$2 $4:$5:$6")

	; check current time against desired time
	$ErrorInCurrentTime = Abs(_DateDiff('s',$destime,$currtime))
	If $ErrorInCurrentTime > 2 Then
		SetError(1,1)
		Return $ErrorInCurrentTime
	EndIf

	; return the error between the current and desired time
	Return $ErrorInCurrentTime

EndFunc ; _ValidateTimes





;=============================================================================
; _CreateEventsFile
; Create the event text file
;=============================================================================
Func _CreateEventsFile($eventfile,$basename)
	$fcnstr = "(_CreateEventsFile) "

	; get separate directory/filename from EventFileName
	Local $eDrive = "", $eDir = "", $eFileName = "", $eExtension = ""
	_PathSplit ($eventfile, $eDrive, $eDir, $eFileName, $eExtension)
	Local $myEventDir = $eDrive & $eDir
	Local $myEventFile = $eFileName & $eExtension
	_LogMessage($fcnstr & "Event file is " & $myEventFile & " in directory " & $myEventDir)

	; right click on events list
	ControlClick($NatusWindowTitle, "", "[CLASS:SysListView32; INSTANCE:1]", "right", 1, 100, 200)
	Local $ClickCounter = 0
	Local $LoopCounter = 0
	While True ; wait for context menu to appear
		Sleep(10)
		If WinActive($NatusWindowTitle) Then ; make sure we're looking for Natus-associated context menu
			If WinExists("[CLASS:#32768]") Then ; look for context menu
				ExitLoop
			EndIf
		Else
			_ActivateWindow($NatusWindowTitle)
			ControlClick($NatusWindowTitle, "", "[CLASS:SysListView32; INSTANCE:1]", "right", 1, 100, 200)
			$ClickCounter = $ClickCounter + 1
		EndIf
		$LoopCounter = $LoopCounter + 1
		If $LoopCounter > 1000 Then
			If $ClickCounter > 100 Then
				SetError(1,1)
				Return
			Else
				_ActivateWindow($NatusWindowTitle)
				ControlClick($NatusWindowTitle, "", "[CLASS:SysListView32; INSTANCE:1]", "right", 1, 100, 200)
				$ClickCounter = $ClickCounter + 1
				$LoopCounter = 0
			EndIf
		EndIf
	WEnd
	If @error Then _ProcessError("Could not execute right-click on Annotation Viewer dock",@error,@extended) EndIf
	_LogMessage($fcnstr & "Right-clicked on Annotation Viewer dock and found the context menu (LoopCounter = " & $LoopCounter & ", ClickCounter = " & $ClickCounter)

	; set all events to visible
	Send("+v")
	$LoopCounter = 0
	While True ; wait for context menu to close
		Sleep(10)
		If WinActive($NatusWindowTitle) Then
			If Not WinExists("[CLASS:#32768]") Then
				ExitLoop
			EndIf
		EndIf
		$LoopCounter = $LoopCounter + 1
		If $LoopCounter > 1000 Then
			SetError(1,2)
			Return
		EndIf
	WEnd
	_LogMessage($fcnstr & "Set all events visible")

	; right click on events list again
	ControlClick($NatusWindowTitle, "", "[CLASS:SysListView32; INSTANCE:1]", "right", 1, 100, 200)
	$LoopCounter = 0
	$ClickCounter = 0
	While True ; wait for context menu to appear
		Sleep(10)
		If WinActive($NatusWindowTitle) Then ; make sure we're looking for Natus-associated context menu
			If WinExists("[CLASS:#32768]") Then ; look for context menu
				ExitLoop
			EndIf
		Else
			_ActivateWindow($NatusWindowTitle)
			ControlClick($NatusWindowTitle, "", "[CLASS:SysListView32; INSTANCE:1]", "right", 1, 100, 200)
			$ClickCounter = $ClickCounter + 1
		EndIf
		$LoopCounter = $LoopCounter + 1
		If $LoopCounter > 1000 Then
			If $ClickCounter > 100 Then
				SetError(1,3)
				Return
			Else
				_ActivateWindow($NatusWindowTitle)
				ControlClick($NatusWindowTitle, "", "[CLASS:SysListView32; INSTANCE:1]", "right", 1, 100, 200)
				$ClickCounter = $ClickCounter + 1
				$LoopCounter = 0
			EndIf
		EndIf
	WEnd
	If @error Then _ProcessError("Could not execute right-click on Annotation Viewer dock",@error,@extended) EndIf
	_LogMessage($fcnstr & "Right-clicked on Annotation Viewer dock and found the context menu (LoopCounter = " & $LoopCounter & ", ClickCounter = " & $ClickCounter)

	; export to text
	Send("+e")
	$LoopCounter = 0
	While True ; wait for context menu to close
		Sleep(10)
		If WinActive($NatusWindowTitle) Then
			If Not WinExists("[CLASS:#32768]") Then
				ExitLoop
			EndIf
		EndIf
		$LoopCounter = $LoopCounter + 1
		If $LoopCounter > 1000 Then
			SetError(1,4)
			Return
		EndIf
	WEnd
	_LogMessage($fcnstr & "Initiated annotation export to text")

	; switch to Notepad window
	_ActivateWindow($basename & ".ent.txt - Notepad")
	If @error Then _ProcessError("Could not get Notepad window",@error,@extended) EndIf

	; open save-as dialog
	WinMenuSelectItem("[ACTIVE; CLASS:Notepad]", "", "&File", "Save &As" )
	If @error Then _ProcessError("Could not select save-as from Notepad menus",@error,@extended) EndIf

	; populate save-as dialog with folder
	Send($myEventDir & "{ENTER}")
	If @error Then _ProcessError("Could not send folder to Notepad save-as dialog",@error,@extended) EndIf
	Sleep(100)

	; send filename
	Send($myEventFile & "{ENTER}")
	If @error Then _ProcessError("Could not send filename to Notepad save-as dialog",@error,@extended) EndIf
	Sleep(100)

	; close Notepad
	Send("!fx")
	If @error Then _ProcessError("Could not exit Notepad",@error,@extended) EndIf
	_LogMessage($fcnstr & "Closed Notepad window")

EndFunc ; _CreateEventsFile





;=============================================================================
; _GetNumRecordStarts
; Count the number of record starts from the event file
;=============================================================================
Func _GetNumRecordStarts($eventfile)
	$fcnstr = "(_GetNumRecordStarts) "

	; read event data into an array
	Local $EventData = "a";
	_FileReadToArray($eventfile, $EventData)
	If @error Then _ProcessError("Could not read events file " & $eventfile,@error,@extended) EndIf
	_LogMessage($fcnstr & "Read event file")

	; pull out the creation date/time from the top few lines of the file (which includes the year/month/day)
	; count how many times "Record Start" appears in the file
	Local $NumRecordStart = 0
	Local $pos
	For $line in $EventData
		$pos = StringInStr($line,"Start Recording")
		if $pos <> 0 Then
			$NumRecordStart += 1
		EndIf
	Next
	If @error Then _ProcessError("Could not determine number of record starts",@error,@extended) EndIf
	If $NumRecordStart < 1 Then
		SetError(1,1)
		Return $NumRecordStart
	EndIf
	_LogMessage($fcnstr & "Found " & $NumRecordStart & " record starts in the file")
	Return $NumRecordStart

EndFunc ; _GetNumRecordStarts





;=============================================================================
; _CreateChannelMontageFile
; Create the channel montage output text file
;=============================================================================
Func _CreateChannelMontageFile($channelfile,$natusfile,$natusdir,$outputdir)
	$fcnstr = "(_CreateChannelMontageFile) "

	; click on montage viewer icon
	ControlClick("Natus", " ", "[CLASS:Button; INSTANCE:1]")
	If @error Then _ProcessError("Could not click the Montage viewer icon",@error,@extended) EndIf
	_LogMessage($fcnstr & "Clicked on Montage Viewer icon")

	; wait for edit settings window to load then activate it
	_ActivateWindow("Edit Settings")
	If @error Then _ProcessError("Could not activate Edit Settings window",@error,@extended) EndIf
	_LogMessage($fcnstr & "Loaded and activated Edit Settings window")

	; tab over to channel labels window
	ControlCommand("Edit Settings", " ", "[CLASS:SysTabControl32; INSTANCE:2]", "TabRight")
	If @error Then _ProcessError("Could not open Channel Labels tab",@error,@extended) EndIf
	_LogMessage($fcnstr & "Open Channel Labels tab")

	; load channel labels from Montage
	Send("!m")
	If @error Then _ProcessError("Could not load labels from montage",@error,@extended) EndIf
	_LogMessage($fcnstr & "Loaded channel labels from montage")

	; create channel nomenclature text file
	Local $myChannelFile = FileOpen($channelfile, 2); will overwrite any previous log file with same name
	FileWrite($myChannelFile, "Channel Nomenclature" & @CRLF); this will be the first line of the channel nomenclature text file
	FileWrite($myChannelFile, "Natus File = " & $natusfile & @CRLF)
	FileWrite($myChannelFile, "Natus Dir = " & $natusdir & @CRLF)
	FileWrite($myChannelFile, "Output Dir = " & $outputdir & @CRLF)
	FileWrite($myChannelFile, "NatusIndex,ChannelNumber,ChannelName" & @CRLF)

	; write channel names and labels to the nomenclature text file
	Local $hndl = ControlGetHandle("Edit Settings", " ", "[CLASS:ListBox; INSTANCE:1]")
	Local $CountLB = _GUICtrlListBox_GetCount($hndl)
	Local $channelText = ""
	For $n = 0 To $CountLB - 1
	   $channelText &= $n & "," & _GUICtrlListBox_GetText($hndl, $n) & @CRLF
	Next
	$channelText = stringregexpreplace($channelText, '	' ,',')
	$channelText = stringregexpreplace($channelText, '(?m),$','')
	FileWrite($myChannelFile, $channelText)
	If @error Then _ProcessError("Could not write the channel montage file",@error,@extended) EndIf

	; update
	_LogMessage($fcnstr & "Wrote channel names and labels to Channel Nomenclature text file")

EndFunc ; _CreateChannelMontageFile





;=============================================================================
; _GetRecordStartStopTimes
; Get the start and stop times for each recording block in the file
;=============================================================================
Func _GetRecordStartStopTimes($eventfile, ByRef $RecordStartTimes, ByRef $RecordStopTimes)
	$fcnstr = "(_GetRecordStartStopTimes) "

	; read event data into an array
	Local $EventData = "a";
	_FileReadToArray($eventfile, $EventData)
	If @error Then _ProcessError("Could not read events file " & $eventfile,@error,@extended) EndIf
	_LogMessage($fcnstr & "Read event file")

	; get the create datetime which has both date and time
	Local $CreationDateTime = 0;
	Local $pos
	For $line in $EventData

		$pos = StringInStr($line,"Creation Date")
		if $pos <> 0 Then
			$CreationDateTime = StringRegExpReplace($line,"^Creation Date:\s+(.*)$","$1")
		EndIf
	Next
	_LogMessage($fcnstr & "Pulled out creation date/time from event file: " & $CreationDateTime)

	; re-arrange and re-format date/time into the format expected by AutoIT
	Local $CreationTime = StringRegExpReplace($CreationDateTime,"^(\d{2}):(\d{2}):(\d{2})\s+(\w+)\s+(\d+),\s+(\d+)$","$1:$2:$3")
	Local $CreationYear = StringRegExpReplace($CreationDateTime,"^(\d{2}):(\d{2}):(\d{2})\s+(\w+)\s+(\d+),\s+(\d+)$","$6")
	Local $TempCreationMonth = StringRegExpReplace($CreationDateTime,"^(\d{2}):(\d{2}):(\d{2})\s+(\w+)\s+(\d+),\s+(\d+)$","$4")
	$CreationMonth = _MonthStringToNum($TempCreationMonth)
	If @error Then _ProcessError("Could not interpret month string '" & $TempCreationMonth & "'",@error,@extended) EndIf
	Local $CreationDay = StringRegExpReplace($CreationDateTime,"^(\d{2}):(\d{2}):(\d{2})\s+(\w+)\s+(\d+),\s+(\d+)$","$5")
	$CreationDateTime = $CreationYear & "/" & $CreationMonth & "/" & $CreationDay & " " & $CreationTime
	$CreationDate = $CreationYear & "/" & $CreationMonth & "/" & $CreationDay
	_LogMessage($fcnstr & "CreationTime: " & $CreationTime)
	_LogMessage($fcnstr & "CreationYear: " & $CreationYear)
	_LogMessage($fcnstr & "CreationMonth: " & $CreationMonth)
	_LogMessage($fcnstr & "CreationDay: " & $CreationDay)
	_LogMessage($fcnstr & "CreationDateTime: " & $CreationDateTime)
	_LogMessage($fcnstr & "CreationDate: " & $CreationDate)

	; loop over each line of the file and pull out the timestamp if
	; the line contains events "Record Start", "Record Stop", or
	; "End of Study" (the last recording end only has "End of Study").
	Local $stopTimeIndex = 0
	Local $startTimeIndex = 0
	Local $pos
	Local $CurrentDate = $CreationDate
	Local $lastTime = StringLeft($EventData[1],8)
	Local $currTime
	For $line in $EventData
	
		; update "currTime" and check for date rollover
		$currTime = StringLeft($line,8)
		If _DateDiff('s', $CurrentDate & " " & $lastTime, $CurrentDate & " " & $currTime ) < 0 Then
			$CurrentDate = _DateAdd('d',1,$CurrentDate)
			_LogMessage($fcnstr & "Identified a date rollover and updated current date to " & $CurrentDate)
		ElseIf _DateDiff('s', $CurrentDate & " " & $lastTime, $CurrentDate & " " & $currTime ) > 24*3600 Then
			_LogMessage($fcnstr & "Warning! There is a gap of more than 24 hours between consecutive events and the date inferral is likely inaccurate")
		EndIf

		; check for "Start Recording" event
		$pos = StringInStr($line,"Start Recording")
		If $pos <> 0 Then
			Local $EventTime = StringLeft($line,8)
			Local $TestDateTime = $CurrentDate & " " & $EventTime;
			Local $SecondsFromCreation = _DateDiff('s',$CreationDateTime,$TestDateTime)
			While $SecondsFromCreation < 0
				$CurrentDate = _DateAdd('d',1,$CurrentDate)
				$TestDateTime = $CurrentDate & " " & $EventTime;
				$SecondsFromCreation = _DateDiff('s',$CreationDateTime,$TestDateTime)
			WEnd
			$RecordStartTimes[$startTimeIndex] = $TestDateTime
			$startTimeIndex += 1
			_LogMessage($fcnstr & "Found start time " & $TestDateTime)
		EndIf

		; check for "Stop Recording" event
		$pos = StringInStr($line,"Stop Recording")
		If $pos <> 0 Then
			Local $EventTime = StringLeft($line,8)
			Local $TestDateTime = $CurrentDate & " " & $EventTime;
			Local $SecondsFromCreation = _DateDiff('s',$CreationDateTime,$TestDateTime)
			While $SecondsFromCreation < 0
				$CurrentDate = _DateAdd('d',1,$CurrentDate)
				$TestDateTime = $CurrentDate & " " & $EventTime;
				$SecondsFromCreation = _DateDiff('s',$CreationDateTime,$TestDateTime)
			WEnd
			$RecordStopTimes[$stopTimeIndex] = $TestDateTime
			$stopTimeIndex += 1
			_LogMessage($fcnstr & "Found stop time " & $TestDateTime)
		EndIf

		; check for "End of Study" event
		$pos = StringInStr($line,"End of Study")
		If $pos <> 0 Then
			Local $EventTime = StringLeft($line,8)
			Local $TestDateTime = $CurrentDate & " " & $EventTime;
			Local $SecondsFromCreation = _DateDiff('s',$CreationDateTime,$TestDateTime)
			While $SecondsFromCreation < 0
				$CurrentDate = _DateAdd('d',1,$CurrentDate)
				$TestDateTime = $CurrentDate & " " & $EventTime;
				$SecondsFromCreation = _DateDiff('s',$CreationDateTime,$TestDateTime)
			WEnd
			$RecordStopTimes[$stopTimeIndex] = $TestDateTime
			$stopTimeIndex += 1
			_LogMessage($fcnstr & "Found stop time " & $TestDateTime)
		EndIf
		
		; update "lastTime"
		$lastTime = $currTime
	Next
EndFunc ; _GetRecordStartStopTimes





;=============================================================================
; _MonthStringToNum
; Convert a three-character string "MMM" to two-digit number "MM"
;=============================================================================
Func _MonthStringToNum($CreationMonth)
	If Not StringCompare($CreationMonth, "Jan") Then
		$CreationMonth = "01"
	ElseIf Not StringCompare($CreationMonth, "Feb") Then
		$CreationMonth = "02"
	ElseIf Not StringCompare($CreationMonth, "Mar") Then
		$CreationMonth = "03"
	ElseIf Not StringCompare($CreationMonth, "Apr") Then
		$CreationMonth = "04"
	ElseIf Not StringCompare($CreationMonth, "May") Then
		$CreationMonth = "05"
	ElseIf Not StringCompare($CreationMonth, "Jun") Then
		$CreationMonth = "06"
	ElseIf Not StringCompare($CreationMonth, "Jul") Then
		$CreationMonth = "07"
	ElseIf Not StringCompare($CreationMonth, "Aug") Then
		$CreationMonth = "08"
	ElseIf Not StringCompare($CreationMonth, "Sep") Then
		$CreationMonth = "09"
	ElseIf Not StringCompare($CreationMonth, "Oct") Then
		$CreationMonth = "10"
	ElseIf Not StringCompare($CreationMonth, "Nov") Then
		$CreationMonth = "11"
	ElseIf Not StringCompare($CreationMonth, "Dec") Then
		$CreationMonth = "12"
	Else
		$CreationMonth = "00"
		SetError(1,1)
	EndIf
	Return $CreationMonth
EndFunc ; _MonthStringToNum





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