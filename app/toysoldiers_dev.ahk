#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

vigemDll := A_ScriptDir "\ViGEmClient.dll"
if !FileExist(vigemDll) {
    MsgBox, 48, Error, ViGEmClient.dll not found in script directory.`nPlease place it next to this script.
    ExitApp
}

DllCall("LoadLibrary", "Str", vigemDll)

global client := 0
global x360_target := 0
global controllerActive := false
global gravePressCount := 0
global Msg
VarSetCapacity(XUSB_REPORT, 20, 0)

global key_Up := false
global key_Down := false
global key_Left := false
global key_Right := false
global key_Grave := false
global key_Backspace := false

SetTimer, UpdateController, 10
SetTimer, CheckGameProcess, 1000
CreateJoystick()
return

CreateJoystick() {
    global client, x360_target, controllerActive, vigemDll
    if (controllerActive)
        return

    client := DllCall(vigemDll "\vigem_alloc", "Ptr")
    result := DllCall(vigemDll "\vigem_connect", "Ptr", client, "UInt")
    if (result != 0x20000000) {
        MsgBox, 48, Error, Failed to connect to ViGEmBus.
        ExitApp
    }

    x360_target := DllCall(vigemDll "\vigem_target_x360_alloc", "Ptr")
    add_result := DllCall(vigemDll "\vigem_target_add", "Ptr", client, "Ptr", x360_target, "UInt")
    if (add_result != 0x20000000) {
        MsgBox, 48, Error, Failed to add X360 target.
        ExitApp
    }

    controllerActive := true
}

RemoveJoystick() {
    global client, x360_target, controllerActive, vigemDll
    if (!controllerActive)
        return

    DllCall(vigemDll "\vigem_target_remove", "Ptr", client, "Ptr", x360_target)
    DllCall(vigemDll "\vigem_target_free", "Ptr", x360_target)
    DllCall(vigemDll "\vigem_disconnect", "Ptr", client)
    DllCall(vigemDll "\vigem_free", "Ptr", client)
    controllerActive := false
}

CheckGameProcess:
if !ProcessExist("GameP.exe") {
    RemoveJoystick()
    ExitApp
}
return

ProcessExist(name) {
    Process, Exist, %name%
    return ErrorLevel
}

UpdateController:
if (!controllerActive)
    return

buttons := 0
pov := 0xFFFF

if (key_Up && key_Right)
    pov := 4500
else if (key_Down && key_Right)
    pov := 13500
else if (key_Down && key_Left)
    pov := 22500
else if (key_Up && key_Left)
    pov := 31500
else if (key_Up)
    pov := 0
else if (key_Right)
    pov := 9000
else if (key_Down)
    pov := 18000
else if (key_Left)
    pov := 27000

if (key_Grave || key_Backspace)
    buttons |= 0x0040 | 0x0080

if (key_Grave && !graveWasDown) {
    gravePressCount++
    if (Mod(gravePressCount, 2) = 0) {
        ShowOSD("☢ Dev Console Initialized ☢")
    }
    if (Mod(gravePressCount, 3) = 0) {
        ShowOSD("☢ Dev Console Removed ☢")
    }
}
graveWasDown := key_Grave

if (GetKeyState("Escape", "P")) {
    if (!escStart)
        escStart := A_TickCount
    else if (A_TickCount - escStart >= 10000) {
        RemoveJoystick()
        ExitApp
    }
} else {
    escStart := 0
}

NumPut(buttons, XUSB_REPORT, 0, "UShort")
NumPut(0, XUSB_REPORT, 2, "UChar")
NumPut(0, XUSB_REPORT, 3, "UChar")
NumPut(0, XUSB_REPORT, 4, "Short")
NumPut(0, XUSB_REPORT, 6, "Short")
NumPut(0, XUSB_REPORT, 8, "Short")
NumPut(0, XUSB_REPORT, 10, "Short")
NumPut(pov, XUSB_REPORT, 12, "UShort")

DllCall(vigemDll "\vigem_target_x360_update", "Ptr", client, "Ptr", x360_target, "Ptr", &XUSB_REPORT)
return

ShowOSD(message) {
    global Msg
    Gui, Destroy
    Gui, +AlwaysOnTop -Caption +ToolWindow
    Gui, Font, s14 cYellow, Segoe UI
    Gui, Color, 000000
    Gui, Add, Text, vMsg Center, %message%

    screenWidth := A_ScreenWidth
    Gui, Show, x0 y0 NoActivate AutoSize
    WinGetPos, , , winW, winH, ahk_class AutoHotkeyGUI

    x := (screenWidth - winW) // 2
    y := 20
    Gui, Show, x%x% y%y% NoActivate

    SetTimer, HideOSD, -3000
}

HideOSD:
Gui, Destroy
return

~Up:: key_Up := true
return
~Up Up:: key_Up := false
return

~Down:: key_Down := true
return
~Down Up:: key_Down := false
return

~Left:: key_Left := true
return
~Left Up:: key_Left := false
return

~Right:: key_Right := true
return
~Right Up:: key_Right := false
return

~`:: key_Grave := true
return
~` Up:: key_Grave := false
return

~Backspace:: key_Backspace := true
return
~Backspace Up:: key_Backspace := false
return
