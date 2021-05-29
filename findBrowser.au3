#RequireAdmin
#include "AdbMemu.au3"
#include <Array.au3>
#include <MsgBoxConstants.au3>
#include "HandleImgSearch.au3"
#include <Date.au3>


Global Const $PATH_FILE_ADB = "C:\Program Files (x86)\Nox\bin\"
Global $HANDLEWINDOWS , $IP_ADDRESS_DEVICE ,$PORT_ADDRESS_DEVICE


if CheckProcessEmulator() Then

Const $imagieBrowser 		= @ScriptDir&"\"&"image-browser.png"
Const $snapShortImage   = findImage($imagieBrowser)

	if (Not @error and $snapShortImage[0][0] = 1 ) Then
		clickByPositionImageMap($snapShortImage)
	Else
		MsgBox($MB_SYSTEMMODAL, "","Value of @error is: " & @error & @CRLF & _
        "Value of @extended is: " & @extended)
	EndIf

EndIf


Func findImage($findImageName)

    Const $formatdate       = StringReplace(StringReplace(_NowDate(),"/","_"),":","_")
    Const $fullfileName     = @ScriptDir & "\tmp\" & $formatdate & ".png"

    adb_screencap($PATH_FILE_ADB,$fullfileName,$PORT_ADDRESS_DEVICE)

    ConsoleWrite("Find Image "&$findImageName&@CRLF)
    ConsoleWrite("Current Image "&$fullfileName&@CRLF)

    return _BmpImgSearch($fullfileName,$findImageName)

EndFunc


Func clickByPositionImageMap($positionIconGame)
    Const $size = $positionIconGame[0][0]

    For $i = 1 To $size Step +1

        $positionX = $positionIconGame[$i][0]
        $positionY = $positionIconGame[$i][1]

        adb_tap($PATH_FILE_ADB, $PORT_ADDRESS_DEVICE,$positionX,$positionY)

    Next

EndFunc


Func CheckProcessEmulator()

    Const $WORD_LIST_OF_DEVICE = "List of devices attached"
    Local $command   = "adb.exe devices"
    Local $iPID = Run($PATH_FILE_ADB&$command,"", @SW_HIDE, $STDOUT_CHILD)

	ProcessWaitClose($iPID)

	Local $sOutput = StdoutRead($iPID)

    ConsoleWrite($sOutput&@CRLF)

    $sOutput      = StringReplace($sOutput,$WORD_LIST_OF_DEVICE,"")
    $listOfDevice = removeArrayBlankToArray(StringSplit($sOutput, @CRLF,2))

    if (UBound($listOfDevice) = 0) Then
        MsgBox(0,"Error","Please Open LD Player")
        SetError(1)
        Return
    Else
        $IP_ADDRESS_DEVICE  = $listOfDevice[0][0]
        $PORT_ADDRESS_DEVICE  = $listOfDevice[0][1]
    EndIf

		Return true
EndFunc



Func removeArrayBlankToArray($arrayWord)
    Dim $arrayWordNew[0][2]
    For $word In $arrayWord
        if ( "" <> $word) Then
                Local $wordArray = StringSplit($word,":",2)
                if (UBound($wordArray) = 2 ) Then
                    Dim $item[1][2]
                    $item[0][0] = $wordArray[0]
                    $item[0][1] = StringReplace($wordArray[1],"device","")
                _ArrayAdd($arrayWordNew,$item)
                endif
        endif
    Next
    Return $arrayWordNew
EndFunc
