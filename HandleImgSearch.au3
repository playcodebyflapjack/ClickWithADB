; Author: Lâm Thành Nhân
; Version: 1.0.4
; Email: ltnhanst94@gmail.com
; Base on
; - ImageSearchDLL (Author: kangkeng 2008)


#include-once
#include <GDIPlus.au3>
#include <WinAPI.au3>
#include <WinAPIGdi.au3>
#include <Color.au3>
#include <ScreenCapture.au3>

OnAutoItExitRegister("__HandleImgSearch_Shutdown")
Opt("WinTitleMatchMode", 1)

Global Const $__BMPSEARCHSRCCOPY 		= 0x00CC0020

Global $_HandleImgSearch_BitmapHandle	= 0

Global $_HandleImgSearch_HWnd 			= ""
Global $_HandleImgSearch_X				= 0
Global $_HandleImgSearch_Y				= 0
Global $_HandleImgSearch_Width 			= -1
Global $_HandleImgSearch_Height 		= -1
Global $_HandleImgSearch_IsDebug 		= False
Global $_HandleImgSearch_IsUser32 		= False
Global $_HandleImgSearch_Tolerance		= 15
Global $_HandleImgSearch_MaxImg			= 1000

Global $__BinaryCall_Kernel32dll
Global $__BinaryCall_Msvcrtdll

; ===============================================================================================================================
; Ảnh để tìm kiếm nên lưu dạng "24-bit Bitmap".
; ===============================================================================================================================

; #Global Functions# ============================================================================================================
; _GlobalImgInit($Hwnd, $X = 0, $Y = 0, $Width = -1, $Height = -1, $IsUser32 = False, $IsDebug = False, $Tolerance = 15, $MaxImg = 1000)
; _GlobalImgCapture($Hwnd = 0)
; _GlobalGetBitmap()
; _GlobalImgSearchRandom($BmpLocal, $IsReCapture = False, $BmpSource = 0, $IsRandom = True, $Tolerance = $_HandleImgSearch_Tolerance, $MaxImg = $_HandleImgSearch_MaxImg)
; _GlobalImgSearch($BmpLocal, $IsReCapture = False, $BmpSource = 0, $Tolerance = $_HandleImgSearch_Tolerance, $MaxImg = $_HandleImgSearch_MaxImg)
; _GlobalImgWaitExist($BmpLocal, $TimeOutSecs = 5, $Tolerance = $_HandleImgSearch_Tolerance, $MaxImg = $_HandleImgSearch_MaxImg)
; _GlobalGetPixel($X, $Y, $IsReCapture = False, $BmpSource = 0)
; _GlobalPixelCompare($X, $Y, $PixelColor, $Tolerance = $_HandleImgSearch_Tolerance, $IsReCapture = False, $BmpSource = 0)

; #Local Functions# =============================================================================================================
; _HandleImgSearch($hwnd, $bmpLocal, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $Tolerance = 15, $MaxImg = 1000)
; _HandleImgWaitExist($hwnd, $bmpLocal, $timeOutSecs = 5, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $Tolerance = 15, $MaxImg = 1000)
; _BmpImgSearch($SourceBmp, $FindBmp, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $Tolerance = 15, $MaxImg = 1000)
; _HandleGetPixel($hwnd, $getX, $getY, $x = 0, $y = 0, $Width = -1, $Height = -1)
; _HandlePixelCompare($hwnd, $getX, $getY, $pixelColor, $tolerance = 15, $x = 0, $y = 0, $Width = -1, $Height = -1)
; _HandleCapture($hwnd, $x = 0, $y = 0, $Width = -1, $Height = -1, $IsBMP = False, $SavePath = "", $IsUser32 = False)
; ===============================================================================================================================


; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalImgInit
; Description ...:	Khởi tạo cho global
; Syntax ........: _GlobalImgInit
; Parameters ....: $Hwnd                	- [optional] Handle của cửa sổ.
;                  $X, $Y, $Width, $Height 	- Vùng ảnh trong handle cần chụp. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $IsUser32            	- [optional] Sử dụng DllCall User32.dll thay vì _WinAPI_BitBlt (Thử để tìm cái phù hợp).. Default is False.
;                  $IsDebug             	- [optional] Cho phép Debug. Default is False.
;                  $Tolerance           	- [optional] Giá trị sai số màu. Default is 15.
;                  $MaxImg	           		- [optional] Số ảnh tối đa để tìm kiếm. Default is 15.
; ===============================================================================================================================
Func _GlobalImgInit($Hwnd = $_HandleImgSearch_HWnd, $X = $_HandleImgSearch_X, $Y = $_HandleImgSearch_Y, _
		$Width = $_HandleImgSearch_Width, $Height = $_HandleImgSearch_Height, $IsUser32 = $_HandleImgSearch_IsUser32, _
		$IsDebug = $_HandleImgSearch_IsDebug, $Tolerance = $_HandleImgSearch_Tolerance, $MaxImg = $_HandleImgSearch_MaxImg)
	$_HandleImgSearch_HWnd 		= $Hwnd
	$_HandleImgSearch_X 		= $X
	$_HandleImgSearch_Y 		= $Y
	$_HandleImgSearch_Width 	= $Width
	$_HandleImgSearch_Height 	= $Height
	$_HandleImgSearch_IsUser32 	= $IsUser32
	$_HandleImgSearch_IsDebug 	= $IsDebug
	$_HandleImgSearch_Tolerance = $Tolerance
	$_HandleImgSearch_MaxImg	= $MaxImg
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalImgCapture
; Description ...: Chụp ảnh Global.
; Syntax ........: _GlobalImgCapture([$Hwnd = 0])
; Parameters ....: $Hwnd                - Handle của cửa sổ nếu không dùng _GlobalImgInit để khai báo.
; Return values .: @error khác 0 nếu có lỗi. Trả về Handle của Bitmap đã chụp.
; ===============================================================================================================================
Func _GlobalImgCapture($Hwnd = 0)
	Local $Handle = $_HandleImgSearch_HWnd

	If $Hwnd <> 0 Then $Handle = $Hwnd
	If not IsHWnd($Handle) and $Handle <> "" Then
		Return SetError(1, 0, 0)
	EndIf

	If $_HandleImgSearch_BitmapHandle <> 0 Then
		_GDIPlus_ImageDispose($_HandleImgSearch_BitmapHandle)
		$_HandleImgSearch_BitmapHandle = 0
	EndIf

	$_HandleImgSearch_BitmapHandle = _HandleCapture($Handle, _
		$_HandleImgSearch_X, _
		$_HandleImgSearch_Y, _
		$_HandleImgSearch_Width, _
		$_HandleImgSearch_Height, _
		True, _
		"", _
		$_HandleImgSearch_IsUser32)
	If @error Then Return SetError(2, 0, 0)

	If $_HandleImgSearch_IsDebug Then
		_GDIPlus_ImageSaveToFile($_HandleImgSearch_BitmapHandle, @ScriptDir & "\GlobalImgCapture.bmp")
	EndIf

	Return SetError(0, 0, $_HandleImgSearch_BitmapHandle)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalGetBitmap
; Description ...: Trả về Handle của Bitmap của Global.
; Syntax ........: _GlobalGetBitmap()
; Parameters ....:
; Return values .: Handle của Bitmap đã khai báo
; ===============================================================================================================================
Func _GlobalGetBitmap()
	Return SetError(0, 0, $_HandleImgSearch_BitmapHandle)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalImgSearchRandom
; Description ...: Trả về toạ độ ngẫu nhiên của ảnh đã tìm được (Chỉ trả về vị trí ảnh đầu tiên tìm được)
; Syntax ........: _GlobalImgSearchRandom($BmpLocal[, $IsReCapture = False[, $BmpSource = 0[, $IsRandom = True[, $Tolerance = $_HandleImgSearch_Tolerance]]]])
; Parameters ....: $BmpLocal            - Đường dẫn của ảnh BMP cần tìm.
;                  $IsReCapture         - [optional] Chụp lại ảnh. Default is False.
;                  $Tolerance           - [optional] an unknown value. Default is 15.
;                  $BmpSource           - [optional] Handle của Bitmap nếu không sử dụng Global. Default is 0.
;                  $IsRandom            - [optional] True sẽ trả về toạ độ ngẫu nhiên của ảnh đã tìm được, False sẽ là $X, $Y. Default is True.
; Return values .: @error = 1 nếu có lỗi xảy ra. Trả về toạ độ ngẫu nhiên của ảnh đã tìm được($P[0] = $X, $P[1] = $Y).
; ===============================================================================================================================
Func _GlobalImgSearchRandom($BmpLocal, $IsReCapture = False, $BmpSource = 0, $IsRandom = True, $Tolerance = $_HandleImgSearch_Tolerance, $MaxImg = $_HandleImgSearch_MaxImg)
	Local $Pos = _GlobalImgSearch($BmpLocal, $IsReCapture, $BmpSource, $Tolerance, $MaxImg)
	If @error Then
		Local $Results[2] = [-1, -1]
		Return SetError(1, 0, $Results)
	EndIf

	If not $IsRandom Then
		Local $Results[2] = [$Pos[1][0], $Pos[1][1]]
	Else
		Local $Results[2] = [Random($Pos[1][0], $Pos[1][0] + $Pos[1][2], 1), Random($Pos[1][1], $Pos[1][1] + $Pos[1][3], 1)]
	EndIf

	Return SetError(0, 0, $Results)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalImgSearch
; Description ...: Tìm ảnh trong Handle đã khai báo
; Syntax ........: _GlobalImgSearch
; Parameters ....: $BmpLocal            - Đường dẫn của ảnh BMP cần tìm.
;                  $IsReCapture         - [optional] Chụp lại ảnh. Default is False.
;                  $BmpSource           - [optional] Handle của Bitmap nếu không sử dụng Global.
;                  $Tolerance           - [optional] Độ lệch màu sắc của ảnh.
;                  $MaxImg          	- [optional] Số kết quả trả về tối đa.
; Return values .: Thành công: Returns a 2d array with the following format:
;							$aCords[0][0]  		= Tổng số vị trí tìm được
;							$aCords[$i][0]		= Toạ độ X
;							$aCords[$i][1] 		= Toạ độ Y
;							$aCords[$i][2] 		= Width của bitmap
;							$aCords[$i][3] 		= Height của bitmap
;					Lỗi: @error khác 0
; ===============================================================================================================================
Func _GlobalImgSearch($BmpLocal, $IsReCapture = False, $BmpSource = 0, $Tolerance = $_HandleImgSearch_Tolerance, $MaxImg = $_HandleImgSearch_MaxImg)
	Local $BMP = $_HandleImgSearch_BitmapHandle

	If $BmpSource <> 0 Then $BMP = $BmpSource
	If $BMP = 0 or $IsReCapture Then
		_GlobalImgCapture()
		If @error Then Return SetError(1, 0, 0)

		$BMP = $_HandleImgSearch_BitmapHandle
	EndIf

	; Clone Bitmap để tìm kiếm vì sau khi tìm toàn bộ Bitmap đều bị giải phóng.
	Local $Width = _GDIPlus_ImageGetWidth($BMP)
	Local $Height = _GDIPlus_ImageGetHeight($BMP)
	Local $BmpClone = _GDIPlus_BitmapCloneArea($BMP, 0, 0, $Width, $Height, $GDIP_PXF24RGB)
	If @error Then Return SetError(2, 0, 0)

	Local $Results = _HandleImgSearch("*" & $BmpClone, $BmpLocal, 0, 0, -1, -1, $Tolerance, $MaxImg)
	Return SetError(@error, 0, $Results)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalImgWaitExist
; Description ...: Tìm ảnh trong Handle đã khai báo
; Syntax ........: _GlobalImgWaitExist
; Parameters ....: $BmpLocal            - Đường dẫn của ảnh BMP cần tìm.
;                  $TimeOutSecs         - [optional] Thời gian tìm ảnh tối đa (giây). Default is False.
;                  $Tolerance           - [optional] Độ lệch màu sắc của ảnh.
;                  $MaxImg          	- [optional] Số kết quả trả về tối đa.
; Return values .: Thành công: Returns a 2d array with the following format:
;							$aCords[0][0]  		= Tổng số vị trí tìm được
;							$aCords[$i][0]		= Toạ độ X
;							$aCords[$i][1] 		= Toạ độ Y
;							$aCords[$i][2] 		= Width của bitmap
;							$aCords[$i][3] 		= Height của bitmap
;					Lỗi: @error khác 0
; ===============================================================================================================================
Func _GlobalImgWaitExist($BmpLocal, $TimeOutSecs = 5, $Tolerance = $_HandleImgSearch_Tolerance, $MaxImg = $_HandleImgSearch_MaxImg)
	Local $Handle = $_HandleImgSearch_HWnd

	If not IsHWnd($Handle) and $Handle <> "" Then
		Return SetError(1, 0, 0)
	EndIf

	Local $Results = _HandleImgWaitExist($Handle, $BmpLocal, _
		$_HandleImgSearch_X, _
		$_HandleImgSearch_Y, _
		$_HandleImgSearch_Width, _
		$_HandleImgSearch_Height, _
		$Tolerance, _
		$MaxImg)
	Return SetError(@error, 0, $Results)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalGetPixel
; Description ...:
; Syntax ........: _GlobalGetPixel($X, $Y[, $IsReCapture = False[, $BmpSource = 0]])
; Parameters ....: $X, $Y               - Toạ độ cần lấy màu.
;                  $IsReCapture         - [optional] Chụp lại ảnh. Default is False.
;                  $BmpSource           - [optional] Handle của Bitmap nếu không sử dụng Global. Default is 0.
; Return values .: @error = 1 nếu xảy ra lỗi. Trả về mã màu dạng 0xRRGGBB
; ===============================================================================================================================
Func _GlobalGetPixel($X, $Y, $IsReCapture = False, $BmpSource = 0)
	Local $BMP = $_HandleImgSearch_BitmapHandle
	If $BmpSource <> 0 Then $BMP = $BmpSource

	If $BMP = 0 Or $IsReCapture Then
		_GlobalImgCapture()
		If @error Then Return SetError(1, 0, 0)

		$BMP = $_HandleImgSearch_BitmapHandle
	EndIf

	Local $Result = _GDIPlus_BitmapGetPixel($BMP, $X, $Y)
	If @error Then Return SetError(1, 0, 0)

	Return SetError(0, 0, "0x" & Hex($Result, 6))
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GlobalPixelCompare
; Description ...: So sánh mã màu tại vị trí $X, $Y với tolerance
; Syntax ........: _GlobalPixelCompare($X, $Y, $PixelColor[, $Tolerance = $_HandleImgSearch_Tolerance[, $IsReCapture = False[, $BmpSource = 0]]])
; Parameters ....: $X, $Y               - Toạ độ cần so sánh.
;                  $PixelColor          - Màu cần so sánh.
;                  $Tolerance           - [optional] Giá trị tolerance. Default is 20.
;                  $IsReCapture         - [optional] Chụp lại ảnh. Default is False.
;                  $BmpSource           - [optional] Handle của Bitmap nếu không sử dụng Global. Default is 0.
; Return values .: @error = 1 nếu xảy ra lỗi. Trả về True nếu tìm thấy, False nếu không tìm thấy.
; ===============================================================================================================================
Func _GlobalPixelCompare($X, $Y, $PixelColor, $Tolerance = $_HandleImgSearch_Tolerance, $IsReCapture = False, $BmpSource = 0)
	Local $PixelColorSource = _GlobalGetPixel($X, $Y, $IsReCapture, $BmpSource)
	If @error Then Return SetError(1, 0, False)

	Return _ColorInBounds($PixelColorSource, $PixelColor, $Tolerance)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _HandleImgSearch
; Description ...: Tìm ảnh trong Handle. Nếu $hwnd = "" sẽ tìm trong toàn màn hình hiện tại.
; Syntax ........: _HandleImgSearch
; Parameters ....: $hwnd                		- Handle của cửa sổ cần chụp. Nếu để trống "" sẽ tự chụp ảnh desktop.
;                  $bmpLocal            		- Đường dẫn đến ảnh BMP cần tìm.
;                  $x, $y, $iWidth, $iHeight 	- Vùng tìm kiếm. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $Tolerance              		- Độ lệch màu sắc của ảnh.
;                  $MaxImg              		- Số ảnh tối đa trả về.
; Return values .: Success: Returns a 2d array with the following format:
;							$aCords[0][0]  		= Tổng số vị trí tìm được
;							$aCords[$i][0]		= Toạ độ X
;							$aCords[$i][1] 		= Toạ độ Y
;							$aCords[$i][2] 		= Width của bitmap
;							$aCords[$i][3] 		= Height của bitmap
;
;					Failure: Returns 0 and sets @error to 1
; ===============================================================================================================================
Func _HandleImgSearch($hwnd, $bmpLocal, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $Tolerance = 15, $MaxImg = 1000)
	If StringInStr($hwnd, "*") Then
		Local $BMP = Ptr(StringReplace($hwnd, "*", ""))
		If @error Then
			Local $result[1][4] = [[0, 0, 0, 0]]
			Return SetError(1, 0, $result)
		EndIf
	Else
		Local $BMP = _HandleCapture($hwnd, $x, $y, $iWidth, $iHeight, true)
		If @error Then
			Local $result[1][4] = [[0, 0, 0, 0]]
			Return SetError(1, 0, $result)
		EndIf
	EndIf

	If StringLeft($bmpLocal, 1) = "*" Then
		Local $Bitmap = Ptr(StringTrimLeft($bmpLocal, 1))
		If @error Then
			Local $result[1][4] = [[0, 0, 0, 0]]
			Return SetError(1, 0, $result)
		EndIf
	Else
		Local $Bitmap = _GDIPlus_BitmapCreateFromFile($bmpLocal)
		If @error Then
			Local $result[1][4] = [[0, 0, 0, 0]]
			Return SetError(1, 0, $result)
		EndIf
	EndIf

	Local $pos = __ImgSearch(0, 0, _GDIPlus_ImageGetWidth($BMP), _GDIPlus_ImageGetHeight($BMP), $Bitmap, $BMP, $Tolerance, $MaxImg)
	Return SetError(@error, 0, $pos)
EndFunc   ;==>_HandleImgSearch

; #FUNCTION# ====================================================================================================================
; Name ..........: _HandleImgWaitExist
; Description ...: Tìm ảnh trong Handle. Nếu $hwnd = "" sẽ tìm trong toàn màn hình hiện tại.
; Syntax ........: _HandleImgWaitExist
; Parameters ....: $hwnd                		- Handle của cửa sổ cần chụp. Nếu để trống "" sẽ tự chụp ảnh desktop.
;                  $bmpLocal            		- Đường dẫn đến ảnh BMP cần tìm.
;                  $timeOutSecs            		- Thời gian tìm tối đa (tính bằng giây).
;                  $x, $y, $iWidth, $iHeight 	- Vùng tìm kiếm. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $Tolerance              		- Độ lệch màu sắc của ảnh.
;                  $MaxImg              		- Số ảnh tối đa trả về.
; Return values .: Success: Returns a 2d array with the following format:
;							$aCords[0][0]  		= Tổng số vị trí tìm được
;							$aCords[$i][0]		= Toạ độ X
;							$aCords[$i][1] 		= Toạ độ Y
;							$aCords[$i][2] 		= Width của bitmap
;							$aCords[$i][3] 		= Height của bitmap
;
;					Failure: Returns 0 and sets @error to 1
; ===============================================================================================================================
Func _HandleImgWaitExist($hwnd, $bmpLocal, $timeOutSecs = 5, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $Tolerance = 15, $MaxImg = 1000)
	$timeOutSecs = $timeOutSecs*1000
	Local $timeStart = TimerInit()

	Local $Results
	While TimerDiff($timeStart) < $timeOutSecs
		$Results = _HandleImgSearch($hwnd, $bmpLocal, $x, $y, $iWidth, $iHeight, $Tolerance, $MaxImg)
		If Not @error Then Return SetError(0, 0, $Results)

		Sleep(100)
	WEnd
	Return SetError(1, 0, $Results)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _BmpImgSearch
; Description ...: Tìm ảnh Bmp trong Bmp
; Syntax ........: _BmpImgSearch
; Parameters ....: $SourceBmp                	- Đường dẫn đến ảnh BMP gốc.
;                  $FindBmp            			- Đường dẫn đến ảnh BMP cần tìm.
;                  $x, $y, $iWidth, $iHeight 	- Vùng tìm kiếm. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $Tolerance              		- Độ lệch màu sắc của ảnh.
;                  $MaxImg              		- Số ảnh trả về tối đa.
; Return values .: Success: Returns a 2d array with the following format:
;							$aCords[0][0]  		= Tổng số vị trí tìm được
;							$aCords[$i][0]		= Toạ độ X
;							$aCords[$i][1] 		= Toạ độ Y
;							$aCords[$i][2] 		= Width của bitmap
;							$aCords[$i][3] 		= Height của bitmap
;
;					Failure: Returns 0 and sets @error to 1
; ===============================================================================================================================
Func _BmpImgSearch($SourceBmp, $FindBmp, $x = 0, $y = 0, $iWidth = -1, $iHeight = -1, $Tolerance = 15, $MaxImg = 1000)
	Local $SourceBitmap = _GDIPlus_BitmapCreateFromFile($SourceBmp)
	If @error Then Return SetError(1, 0, 0)
	Local $FindBitmap = _GDIPlus_BitmapCreateFromFile($FindBmp)
	If @error Then Return SetError(1, 0, 0)

	Local $pos = __ImgSearch(0, 0, _GDIPlus_ImageGetWidth($SourceBitmap), _GDIPlus_ImageGetHeight($SourceBitmap), $FindBitmap, $SourceBitmap, $Tolerance, $MaxImg)
	Return SetError(@error, 0, $pos)
EndFunc   ;==>_BmpImgSearch

; #FUNCTION# ====================================================================================================================
; Name ..........: _HandleGetPixel
; Description ...: Lấy mã màu tại toạ độ nhất định của ảnh
; Syntax ........: _HandleGetPixel($hwnd, $getX, $getY[, $x = 0[, $y = 0[, $Width = -1[, $Height = -1]]]])
; Parameters ....: $hwnd                		- a handle value.
;                  $getX, $getY               	- Toạ độ cần lấy màu.
;                  $x, $y, $iWidth, $iHeight 	- Vùng ảnh trong handle cần chụp. Mặc định là toàn ảnh chụp từ $hwnd.
; Return values .: @error = 1 nếu có lỗi xảy ra.
; Author ........: Lâm Thành Nhân
; ===============================================================================================================================
Func _HandleGetPixel($hwnd, $getX, $getY, $x = 0, $y = 0, $Width = -1, $Height = -1)
	Local $BMP = _HandleCapture($hwnd, $x, $y, $Width, $Height, True, "")
	If @error Then Return SetError(1, 0, 0)

	Local $result = _GDIPlus_BitmapGetPixel($BMP, $getX, $getY)
	If @error Then Return SetError(1, 0, 0)
	_GDIPlus_ImageDispose($BMP)

	Return SetError(0, 0, "0x" & Hex($result, 6))
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _HandlePixelCompare
; Description ...: So sánh màu điểm ảnh với tolerance
; Syntax ........: _HandlePixelCompare
; Parameters ....: $hwnd                		- a handle value.
;                  $getX, $getY               	- Toạ độ cần lấy màu.
;                  $pixelColor          		- Mã màu cần so sánh.
;                  $Tolerance          			- Độ lệch màu sắc.
;                  $x, $y, $iWidth, $iHeight 	- Vùng ảnh trong handle cần chụp. Mặc định là toàn ảnh chụp từ $hwnd.
; Return values .: None
; ===============================================================================================================================
Func _HandlePixelCompare($hwnd, $getX, $getY, $pixelColor, $tolerance = 15, $x = 0, $y = 0, $Width = -1, $Height = -1)
	Local $BMP = _HandleCapture($hwnd, $x, $y, $Width, $Height, True, "")
	If @error Then Return SetError(1, 0, False)

	Local $result = _GDIPlus_BitmapGetPixel($BMP, $getX, $getY)
	If @error Then Return SetError(1, 0, False)
	_GDIPlus_ImageDispose($BMP)

	Return SetError(0, 0, _ColorInBounds($pixelColor, "0x" & Hex($result, 6), $tolerance))
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _HandleCapture
; Description ...: Chụp ảnh theo Handle. Nếu Handle = "" sẽ chụp ảnh màn hình hiện tại.
; Syntax ........: _HandleCapture
; Parameters ....: $hwnd                		- Handle của cửa sổ cần chụp. Nếu bỏ trống ("") sẽ chụp ảnh màn hình.
;                  $x, $y, $iWidth, $iHeight 	- Vùng ảnh trong handle cần chụp. Mặc định là toàn ảnh chụp từ $hwnd.
;                  $SavePath            		- Đường dẫn lưu ảnh.
;                  $IsBMP               		- True: Kết quả trả về là Bitmap.
;												- False: Kết quả trả về là HBitmap.[Mặc định]
;				   $IsUser32					- Sử dụng User32.dll thay vì _WinAPI_BitBlt (Thử để tìm tuỳ chọn phù hợp)
; ===============================================================================================================================
Func _HandleCapture($hwnd = "", $x = 0, $y = 0, $Width = -1, $Height = -1, $IsBMP = False, $SavePath = "", $IsUser32 = False)
	If $hwnd = "" Then
		Local $Right = $Width = -1 ? -1 : $x + $Width - 1
		Local $Bottom = $Height = -1 ? -1 : $y + $Height - 1

		Local $hBMP = _ScreenCapture_Capture("", $x, $y, $Right, $Bottom, False)
		If @error Then Return SetError(1, 0, 0)

		If $_HandleImgSearch_IsDebug Then
			Local $BMP = _GDIPlus_BitmapCreateFromHBITMAP($hBMP)
			_GDIPlus_ImageSaveToFile($BMP, $SavePath <> "" ? $SavePath : @ScriptDir & "\HandleCapture0.bmp")
			_GDIPlus_BitmapDispose($BMP)
		EndIf

		If not $IsBMP Then Return SetError(0, 0, $hBMP)

		Local $BMP = _GDIPlus_BitmapCreateFromHBITMAP($hBMP)
		If @error Then Return SetError(1, 0, 0)
		_WinAPI_DeleteObject($hBMP)
		Return SetError(0, 0, $BMP)
	EndIf

	Local $Handle = $Hwnd
	If Not IsHWnd($Handle) Then $Handle = HWnd($Hwnd)
	If @error Then
		$Handle = WinGetHandle($Hwnd)
		If @error Then
			ConsoleWrite("! _HandleCapture error: Handle error!")
			Return SetError(1, 0, 0)
		EndIf
	EndIf

	Local $hDC = _WinAPI_GetDC($Handle)
	Local $hCDC = _WinAPI_CreateCompatibleDC($hDC)
	If $Width = -1 Then $Width = _WinAPI_GetWindowWidth($Handle)
	If $Height = -1 Then $Height = _WinAPI_GetWindowHeight($Handle)

	If $IsUser32 Then
		Local $hBMP = _WinAPI_CreateCompatibleBitmap($hDC, _WinAPI_GetWindowWidth($Handle), _WinAPI_GetWindowHeight($Handle))
		_WinAPI_SelectObject($hCDC, $hBMP)

		DllCall("User32.dll", "int", "PrintWindow", "hwnd", $Handle, "hwnd", $hCDC, "int", 0)

		Local $tempBMP = _GDIPlus_BitmapCreateFromHBITMAP($hBMP)
		_WinAPI_DeleteObject($hBMP)

		Local $BMP = _GDIPlus_BitmapCloneArea($tempBMP, $x, $y, $Width, $Height, $GDIP_PXF24RGB)
		_GDIPlus_BitmapDispose($tempBMP)
	Else
		Local $hBMP = _WinAPI_CreateCompatibleBitmap($hDC, $Width, $Height)
		_WinAPI_SelectObject($hCDC, $hBMP)

		_WinAPI_BitBlt($hCDC, 0, 0, $Width, $Height, $hDC, $x, $y, $__BMPSEARCHSRCCOPY)

		Local $BMP = _GDIPlus_BitmapCreateFromHBITMAP($hBMP)
		_WinAPI_DeleteObject($hBMP)
	EndIf

	If $_HandleImgSearch_IsDebug Then
		_GDIPlus_ImageSaveToFile($BMP, $SavePath = "" ? @ScriptDir & "\HandleCapture1.bmp" : $SavePath)
	EndIf

	_WinAPI_ReleaseDC($Handle, $hDC)
	_WinAPI_DeleteDC($hCDC)

	If $IsBMP Then Return SetError(0, 0, $BMP)

	; Nên tạo lại $hBMP này vì có thể có lỗi nếu sử dụng $hBMP ở trên
	Local $hBMP = _GDIPlus_BitmapCreateHBITMAPFromBitmap($BMP)
	_GDIPlus_BitmapDispose($BMP)

	Return SetError(0, 0, $hBMP)
EndFunc   ;==>_HandleCapture

#Region Internal Functions
; Author: Lâm Thành Nhân
Func __ImgSearch($x, $y, $right, $bottom, $BitmapFind, $BitmapSource, $tolerance = 15, $MaxImg = 1000)
	If $_HandleImgSearch_IsDebug Then
		_GDIPlus_ImageSaveToFile($BitmapSource, @ScriptDir & "\HandleImgSearchSource.bmp")
		_GDIPlus_ImageSaveToFile($BitmapFind, @ScriptDir & "\HandleImgSearchFind.bmp")
	EndIf

	Local $hBitmapFind = _GDIPlus_BitmapCreateHBITMAPFromBitmap($BitmapFind)
	Local $hBitmapSource = _GDIPlus_BitmapCreateHBITMAPFromBitmap($BitmapSource)
	Local $Pos, $Error = 0
	Dim $PosAr[1][4] = [[0,0,0,0]]

	; Tính trước giá trị màu sắc pixel cần thay đổi khi tìm được kết quả
	Local $LocalPixel = _GDIPlus_BitmapGetPixel($BitmapFind, 0, 0)
	$LocalPixel = _ColorGetBlue($LocalPixel)
	$LocalPixel = "0xFF0000" & Hex($LocalPixel > $Tolerance + 1 ? $LocalPixel - $Tolerance - 1 : $LocalPixel + $Tolerance + 1, 2)

	For $i = 1 to $MaxImg

		$Pos = DllCall("ImageSearchDLL.dll","str","ImageSearchExt", _
			"int", $x, _
			"int", $y, _
			"int", $right, _
			"int", $bottom, _
			"int", $Tolerance, _
			"ptr", $hBitmapFind, _
			"ptr", $hBitmapSource)

		If @error Then
			ConsoleWrite("Call ImageSearchDLL " & @error & " Extend " & @extended & " Result " & $Pos & @CRLF)
			$Error = $i = 1 ? 1 : 0
			ExitLoop
		EndIf

		If $Pos[0] = 0 Then
			$Error = $i = 1 ? 1 : 0
			ExitLoop
		EndIf
		Local $PosSplit = StringSplit($Pos[0], "|", 2)
		Redim $PosAr[$i + 1][4]
		$PosAr[0][0] = $i
		$PosAr[$i][0] = $PosSplit[1]
		$PosAr[$i][1] = $PosSplit[2]
		$PosAr[$i][2] = $PosSplit[3]
		$PosAr[$i][3] = $PosSplit[4]

		; Set lại màu sắc của vị trí ảnh vừa tìm được
		_GDIPlus_BitmapSetPixel($BitmapSource, $PosSplit[1], $PosSplit[2], $LocalPixel)
		_WinAPI_DeleteObject($hBitmapSource)

		; Xác định lại toạ độ $y để không phải tìm từ đầu nếu tìm nhiều ảnh
		$y = $PosSplit[2]

		; Thao tác với ImageSearchExt đã xoá ảnh $hBitmapFind
		$hBitmapFind = _GDIPlus_BitmapCreateHBITMAPFromBitmap($BitmapFind)
		$hBitmapSource = _GDIPlus_BitmapCreateHBITMAPFromBitmap($BitmapSource)
	Next

	If $_HandleImgSearch_IsDebug Then
		_GDIPlus_ImageSaveToFile($BitmapSource, @ScriptDir & "\HandleImgSearchSourceFilter.bmp")
		_GDIPlus_ImageSaveToFile($BitmapFind, @ScriptDir & "\HandleImgSearchFindFilter.bmp")
	EndIf

	_GDIPlus_BitmapDispose($BitmapSource)
	_WinAPI_DeleteObject($hBitmapSource)
	_GDIPlus_BitmapDispose($BitmapFind)
	_WinAPI_DeleteObject($hBitmapFind)

	Return SetError($Error, 0, $PosAr)
EndFunc

Func __HandleImgSearch_StartUp()
	_GDIPlus_Startup()
	$__BinaryCall_Kernel32dll = DllOpen('kernel32.dll')
	$__BinaryCall_Msvcrtdll = DllOpen('msvcrt.dll')
EndFunc

Func __HandleImgSearch_Shutdown()
	_GDIPlus_ImageDispose($_HandleImgSearch_BitmapHandle)
	_GDIPlus_Shutdown()
EndFunc

;Author: jvanegmond
Func _ColorInBounds($pMColor, $pTColor, $pVariation)
    Local $lMCBlue = _ColorGetBlue($pMColor)
    Local $lMCGreen = _ColorGetGreen($pMColor)
    Local $lMCRed = _ColorGetRed($pMColor)

    Local $lTCBlue = _ColorGetBlue($pTColor)
    Local $lTCGreen = _ColorGetGreen($pTColor)
    Local $lTCRed = _ColorGetRed($pTColor)

    Local $a = Abs($lMCBlue - $lTCBlue)
    Local $b = Abs($lMCGreen - $lTCGreen)
	Local $c = Abs($lMCRed - $lTCRed)

    If ( ( $a < $pVariation ) AND ( $b < $pVariation ) AND ( $c < $pVariation ) ) Then
        Return True
    Else
        Return False
    EndIf
EndFunc

__HandleImgSearch_StartUp()
#EndRegion Internal Functions
