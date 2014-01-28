#include <Array.au3>
#include <Date.au3>
#include "include/WinHttp.au3"
#include "include/JSON.au3"
#include "include/JSON_Translate.au3" ; examples of translator functions, includes JSON_pack and JSON_unpack
#include "include/JSON_Get.au3"

$ini = @MyDocumentsDir & "/ExileRaceTracker.ini"

if FileExists($ini) = 0 then
  IniWrite($ini, "Config", "DisplayLocationX", "0")
  IniWrite($ini, "Config", "DisplayLocationY", "0")
  SetAccount()
  IniWrite($ini, "Config", "Week", False)
EndIf

HotKeySet("+!p", "SetPos")
HotKeySet("+!x", "ExitScript")
HotKeySet("+!a", "SetAccount")
HotKeySet("+!w", "SetWeek")

$dispX = IniRead($ini, "Config", "DisplayLocationX", "0")
$dispY = IniRead($ini, "Config", "DisplayLocationY", "0")
$Account = IniRead($ini, "Config", "Account", "")
$Week = IniRead($ini, "Config", "Week", "False")
If $Week = "" Then
    IniWrite($ini, "Config", "Week", False)
Endif
If $Account = "" Then
    SetAccount()
Endif
While 1
    $changeWeekMode = False
    $races = _JSONDecode(HttpGet("http://api.pathofexile.com/leagues","type=event"))
    $i=0
    $raceID = _JSONGet($races[$i],"id")
    $endAt = _JSONGet($races[$i],"endAt")
    $mylocaltime = _Date_Time_SystemTimeToDateTimeStr(_Date_Time_GetSystemTime())
    
    If (StringInStr($raceID,"week",2) And $Week = "False") then
        $i=$i+1
        $raceID = _JSONGet($races[$i],"id")
        $endAt = _JSONGet($races[$i],"endAt")
    endif
    
    While _DateDiff('s', StringTrimRight ( $endAt, 1 ), _NowCalc()) > 0
        $i=$i+1
        $raceID = _JSONGet($races[$i],"id")
        $endAt = _JSONGet($races[$i],"endAt")
    Wend

    $deadString = ""
    $myClass = ""
    $deadCounts = False
    $tooltip = ""
    $changeWeekMode = False

    If StringInStr($raceID,"descent",2) Or StringInStr($raceID,"endless ledge",2) Or StringInStr($raceID,"EL",2) Then
        $deadCounts = True
    Endif

    While not $changeWeekMode
        $deads = 0
        $offset = 0
        $found = 0
        $xpprev = 0
        $cptClass = 1
        $classPos = ""
        
        While $found = 0
            $Ladder = _JSONDecode(HttpGet("http://api.pathofexile.com/ladders/" & $raceID,"limit=200&offset=" & $offset))
       
            $total = _JSONGet($Ladder,"total")
            $array = _JSONGet($Ladder,"entries")
            
            If UBound($array) = 0 Then
                ExitLoop
            EndIf
            
            For $i = 0 To UBound($array)-1
                $dead = _JSONGet($array[$i],"dead")
                $xp = _JSONGet($array[$i],"character.experience")
                $class = _JSONGet($array[$i],"character.class")
               
                If _JSONGet($array[$i],"account.name") = $Account Then
                    $online = _JSONGet($array[$i],"online")
                    $rank = _JSONGet($array[$i],"rank")
                    $level = _JSONGet($array[$i],"character.level")
                    
                    If $dead And $deadCounts = False Then
                        $tooltip = "REEEEEEEEEEEEP"
                    Else
                        If $deadCounts = False Then
                            $rank = $rank-$deads
                        Endif
                        
                        If $myClass <> $class Then
                            $myClass = $class
                        else
                            $classPos = " " & $myClass & " n°" & $cptClass
                        EndIf
                        
                        $tooltip = "Rank: " & $rank & "/" & $total
                        
                        If $rank <> 1 Then
                             $tooltip = $tooltip & " next: " & $xpprev-$xp & "xp"
                        EndIf
                        
                        $tooltip = $tooltip & $classPos 
                        
                        If $dead Then
                            $tooltip = $tooltip & " - REEEEEEEEEEEEP"
                        EndIf
                        
                        If Not $online Then
                            $tooltip = $tooltip & " - Offline"
                        EndIf
                    EndIf
                    
                    $found = 1
                    ExitLoop
                EndIf
                
                If $dead = False Or $deadCounts = True Then
                    If $class = $myClass Then
                        $cptClass += 1
                    EndIf
                    $xpprev = $xp
                Else
                    $deads += 1
                EndIf
            Next
            $offset+=200
        WEnd
        For $i = 1 To 30 Step 1
            ToolTip(@HOUR & ":" & @MIN & ":" & @SEC & " " & $tooltip, $dispX, $dispY)
            Sleep(1000)
        Next
       
    WEnd
Wend

Func SetPos()
    $MousePos = MouseGetPos()
    $dispX = $MousePos[0]
    $dispY = $MousePos[1]
    ToolTip(@HOUR & ":" & @MIN & ":" & @SEC & " " & $tooltip, $dispX, $dispY)
    IniWrite($ini, "Config", "DisplayLocationX", $dispX)
    IniWrite($ini, "Config", "DisplayLocationY", $dispY)
EndFunc

Func ExitScript()
    Exit
EndFunc

Func SetAccount()
    $account = InputBox("Account","Wich account do you want to follow?")
    IniWrite($ini, "Config", "Account", $account)
EndFunc

Func SetWeek()
    $week = not $week
    $changeWeekMode = True
EndFunc