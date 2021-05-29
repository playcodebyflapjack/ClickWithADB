#include-once
#include <AutoItConstants.au3>
#include <StringConstants.au3>
#include <GDIPlus.au3>
#include <Array.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>


Func adb_swipe($path, $devicePort, $x1, $y1, $x2, $y2)
	Local $iPID = Run($path&"adb -s 127.0.0.1:"&$devicePort&" shell input swipe "&$x1&" "&$y1&" "&$x2&" "&$y2, "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
EndFunc

Func adb_tap($path, $devicePort, $posX, $posY)
	Local $iPID = Run($path&"adb -s 127.0.0.1:"&$devicePort&" shell input tap "&$posX&" "&$posY, "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
EndFunc

Func adb_tapdevice($path, $devicePort, $posX, $posY)
	Local $iPID = Run($path&"adb -s "&$devicePort&" shell input tap "&$posX&" "&$posY, "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
EndFunc

Func adb_screencap($pathADB,$fullPathFile,$devicePort)
    Local $iPID = Run($pathADB&"adb.exe -s 127.0.0.1:"&$devicePort&" shell screencap -p /sdcard/Pictures/adb_pic.png", "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
    $path2 = StringReplace($fullPathFile, "\", "/")
	ConsoleWrite($path2&@CRLF)
    $iPID = Run($pathADB&"adb.exe -s 127.0.0.1:"&$devicePort&" pull /sdcard/Pictures/adb_pic.png "&String($path2), "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	ConsoleWrite(StdoutRead($iPID)&@CRLF)
	$iPID = Run($pathADB&"adb.exe -s 127.0.0.1:"&$devicePort&" shell rm /sdcard/Pictures/adb_pic.png", "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
EndFunc

Func adb_screencap_device($pathADB,$fullPathFile,$devicePort)
    Local $iPID = Run($pathADB&"adb.exe -s "&$devicePort&" shell screencap -p /sdcard/Pictures/adb_pic.png", "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
    $path2 = StringReplace($fullPathFile, "\", "/")
    $iPID = Run($pathADB&"adb.exe -s "&$devicePort&" pull /sdcard/Pictures/adb_pic.png "&String($path2), "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	$iPID = Run($pathADB&"adb.exe -s "&$devicePort&" shell rm /sdcard/Pictures/adb_pic.png", "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
EndFunc


Func memu_path()
	$pid = ProcessExists("MEmu.exe")
	If $pid <> 0 Then
		Local $data_pid = _ProcessListProperties($pid)
		Local $dataREP = StringRegExpReplace($data_pid[1][5], "(MEmu.exe)", "")
		$dataREP = StringStripWS($dataREP, $STR_STRIPSPACES)
		Return $dataREP
	Else
		Return False
	EndIf
EndFunc

Func adb_devices_port($path)
	Local $ret[0]
	Local $iPID = Run($path&"\adb.exe devices", "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	$dataD = StdoutRead($iPID)
	Local $dataREP = StringRegExpReplace($dataD, "(127.0.0.1)[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz]", "")
	Local $dataArray = StringSplit($dataREP, ":")
	For $i = 1 To UBound($dataArray)-1 Step +1
		If Int($dataArray[$i]) > 1 Then
			_ArrayAdd($ret, Int($dataArray[$i]))
		EndIf
	Next
	Return $ret
EndFunc

Func _GetpixelBitMap($iX, $iY)
	_GDIPlus_Startup()
	Local $iColor = 0
	Local $hHBmp = _GDIPlus_ImageLoadFromFile(@ScriptDir&"\adb_pic\adb_pic.jpg")
	$iColor = _GDIPlus_BitmapGetPixel($hHBmp, $iX, $iY)
	_GDIPlus_ImageDispose($hHBmp)
	_GDIPlus_Shutdown()
	Return "0x"&Hex($iColor,6)
EndFunc

Func _ProcessListProperties($Process = "", $sComputer = ".")
    Local $sUserName, $sMsg, $sUserDomain, $avProcs, $dtmDate
    Local $avProcs[1][2] = [[0, ""]], $n = 1
    If StringIsInt($Process) Then $Process = Int($Process)
    $oWMI = ObjGet("winmgmts:{impersonationLevel=impersonate,authenticationLevel=pktPrivacy, (Debug)}!\\" & $sComputer & "\root\cimv2")
    If IsObj($oWMI) Then
        If $Process = "" Then
            $colProcs = $oWMI.ExecQuery("select * from win32_process")
        ElseIf IsInt($Process) Then
            $colProcs = $oWMI.ExecQuery("select * from win32_process where ProcessId = " & $Process)
        Else
            $colProcs = $oWMI.ExecQuery("select * from win32_process where Name = '" & $Process & "'")
        EndIf
        If IsObj($colProcs) Then
            If $colProcs.count = 0 Then Return $avProcs
            ReDim $avProcs[$colProcs.count + 1][10]
            $avProcs[0][0] = UBound($avProcs) - 1
            For $oProc In $colProcs
                $avProcs[$n][0] = $oProc.name
                $avProcs[$n][1] = $oProc.ProcessId
                $avProcs[$n][2] = $oProc.ParentProcessId
                If $oProc.GetOwner($sUserName, $sUserDomain) = 0 Then $avProcs[$n][3] = $sUserDomain & "\" & $sUserName
                $avProcs[$n][4] = $oProc.Priority
                $avProcs[$n][5] = $oProc.ExecutablePath
                $dtmDate = $oProc.CreationDate
                If $dtmDate <> "" Then
                    Local $sRegExpPatt = "\A(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(?:.*)"
                    $dtmDate = StringRegExpReplace($dtmDate, $sRegExpPatt, "$2/$3/$1 $4:$5:$6")
                EndIf
                $avProcs[$n][8] = $dtmDate
                $avProcs[$n][9] = $oProc.CommandLine
                $n += 1
            Next
        Else
            SetError(2)
        EndIf
        $colProcs = 0
        Local $oRefresher = ObjCreate("WbemScripting.SWbemRefresher")
        $colProcs = $oRefresher.AddEnum($oWMI, "Win32_PerfFormattedData_PerfProc_Process" ).objectSet
        $oRefresher.Refresh
        Local $iTime = TimerInit()
        Do
            Sleep(20)
        Until TimerDiff($iTime) >= 100
        $oRefresher.Refresh
        For $oProc In $colProcs
            For $n = 1 To $avProcs[0][0]
                If $avProcs[$n][1] = $oProc.IDProcess Then
                    $avProcs[$n][6] = $oProc.PercentProcessorTime
                    $avProcs[$n][7] = $oProc.WorkingSet
                    ExitLoop
                EndIf
            Next
        Next
    Else
        SetError(1)
    EndIf
    Return $avProcs
EndFunc


