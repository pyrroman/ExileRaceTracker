#include <Array.au3>
;#include <Date.au3>
#include "include/WinHttp.au3"
#include "include/JSON.au3"
#include "include/JSON_Translate.au3" ; examples of translator functions, includes JSON_pack and JSON_unpack
#include "include/JSON_Get.au3"

if FileExists(@MyDocumentsDir & "/ExileRaceTracker.ini") = 0 then
  SetAccount()
  IniWrite(@MyDocumentsDir & "/ExileRaceTracker.ini", "Config", "DisplayLocationX", "0")
  IniWrite(@MyDocumentsDir & "/ExileRaceTracker.ini", "Config", "DisplayLocationY", "0")
EndIf

HotKeySet("+!p", "SetPos")
HotKeySet("+!x", "ExitScript")
HotKeySet("+!a", "SetAccount")

$dispX = IniRead("ExileRaceTracker.ini", "Config", "DisplayLocationX", "0")
$dispY = IniRead("ExileRaceTracker.ini", "Config", "DisplayLocationY", "0")
$Account = IniRead("ExileRaceTracker.ini", "Config", "Account", "")

$races = _JSONDecode(HttpGet("http://api.pathofexile.com/leagues","type=event"))
$raceID = _JSONGet($races[0],"id")
;$endAt = _JSONGet($races[0],"endAt")

$deadString = ""
$myClass = ""
$deadCounts = false
$tooltip = ""

If StringInStr($raceID,"descent",2) Or StringInStr($raceID,"endless ledge",2) Or StringInStr($raceID,"EL",2) Then
    $deadCounts = true
Endif

While 1
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
                
                If $dead And $deadCounts = false Then
                    $tooltip = "REEEEEEEEEEEEP"
                Else
                    If $deadCounts = false Then
                        $rank = $rank-$deads
                    Endif
                    
                    If $myClass = "" Then
                        $myClass = $class
                    Else
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
            
            If $dead = false Or $deadCounts = true Then
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

Func SetPos()
    $MousePos = MouseGetPos()
    $dispX = $MousePos[0]
    $dispY = $MousePos[1]
    ToolTip(@HOUR & ":" & @MIN & ":" & @SEC & " " & $tooltip, $dispX, $dispY)
    IniWrite("ExileRaceTracker.ini", "Config", "DisplayLocationX", $dispX)
    IniWrite("ExileRaceTracker.ini", "Config", "DisplayLocationY", $dispY)
EndFunc

Func ExitScript()
    Exit
EndFunc

Func SetAccount()
    $account = InputBox("Account","Wich account do you want to follow?")
    IniWrite(@MyDocumentsDir & "/ExileRaceTracker.ini", "Config", "Account", $account)
EndFunc