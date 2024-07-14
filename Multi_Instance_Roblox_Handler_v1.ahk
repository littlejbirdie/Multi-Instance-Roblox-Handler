#Requires AutoHotkey v2.0
#SingleInstance Force
CoordMode("Pixel", "Client") ; Use client coordinates for window-specific operations
CoordMode("Mouse", "Client")
SetMouseDelay(-1)
SetControlDelay(1)
SetWinDelay(0)
SetKeyDelay(-1)

global specialInstances := Map()
global instanceIDs := []
global cycleCount := 0
global minKeyPressInterval := 100
global timeInterval := 10000
global iniFilePath := A_ScriptDir "\keystrokes.ini"
global sequencesMap := Map()
global instanceSequenceNames := []
global instanceInputComplete := false
global timeInputComplete := false
global idList
global defaultSequence := "{Space down},{Space up}"
global gui3
global guiStatus
global logoFilePath := A_ScriptDir "\LittleJBirdieLogo.png" ; Define the path to the logo

; Ensure INI file exists
if !FileExist(iniFilePath) {
    FileAppend("[Keystrokes]`nDefault={Space down},{Space up}`n", iniFilePath)
}

; Load all sequences from INI file
LoadSequences()

; Initial Instruction Screen
gui1 := Gui()
gui1.Opt("+AlwaysOnTop")
gui1.Add("Text",,"Instructions for use with AutoHotKey v2          ").SetFont("bold","s15 w200") 
gui1.Add("Picture","w100 h-1", logoFilePath) ; Use the full path to the image
gui1.Add("Text",,"By Little J Birdie").SetFont("s8 w50")
gui1.Add("Button",,"Donate").OnEvent("Click", Donate)
gui1.Add("Link",,'Visit my <a href="https://www.youtube.com/@littlejbirdie">YouTube Channel</a>`nor Join my <a href="https://discord.gg/te6JSdRF7C">Discord Server</a>')
gui1.Add("Text",,"Instructions:  ").SetFont("Bold")
gui1.Add("Link",,'1. Open all <a href="https://github.com/ic3w0lf22/Roblox-Account-Manager">instances of Roblox</a> and position characters as needed.`n2. Press the START button to start the script.`n3. Follow the prompts to assign key sequences to each instance')
gui1.Add("Text",,"Hotkeys:  ").SetFont("Bold")
gui1.Add("Text",,"-F8: Exit script`n-F12: Pause/Resume script")
gui1.AddButton("Default w80","Start").OnEvent("Click", StartScript)
gui1.Title := "Multi Instance Roblox Handler v1"
gui1.Show("w410 h400")

Donate(*) {
    Run("https://www.paypal.com/ncp/payment/8QW9PKMS4PNTQ")
}

StartScript(*) {
    global idList, instanceSequenceNames, specialInstances, instanceIDs, cycleCount, minKeyPressInterval, timeInterval, iniFilePath, defaultSequence, gui1, timeInputComplete
    gui1.Destroy()
    
    idList := WinGetList("ahk_exe RobloxPlayerBeta.exe")
    if (idList.Length < 1) {
        MsgBox("Error: No instances of Roblox are running.")
        ExitApp()
    }
    MsgBox("Number of instances detected: " idList.Length)

    ; Prompt user for key sequences
    Loop idList.Length {
        instanceNum := A_Index
        ; Activate instance
        thisID := idList[instanceNum]
        WinActivate(thisID)
        Sleep(200)
        
        ; Sequentially prompt for user input
        PromptForKeySequences(instanceNum)
    }

    ; Ensure the sequences are set after user input
    Loop idList.Length {
        instanceNum := A_Index
        ChosenSequence := instanceSequenceNames[instanceNum]
        KeyPresses := (ChosenSequence = "Default") ? defaultSequence : sequencesMap[ChosenSequence]
        MsgBox("Key presses for instance " instanceNum ": " KeyPresses)
        specialInstances[instanceNum] := StrSplit(KeyPresses, ",")
    }

    ; Prompt for time interval
    PromptForTimeInterval()

    ; Wait for user input to complete before proceeding
    timeInputComplete := false
    while (!timeInputComplete) {
        Sleep(100)
    }

    ; Show the running status GUI at a specified position
    ShowStatusGUI(100, 100) ; Change the coordinates as needed

    ; Start the main loop for executing key presses
    MainLoop()
}

PromptForKeySequences(instanceNum) {
    global sequencesMap, instanceSequenceNames, instanceInputComplete, defaultSequence
    gui2 := Gui()
    gui2.Add("Text", , "Instance " instanceNum ": Choose a saved sequence or create a new one.")
    existingSequences := "New Sequence||Default"
    
    ; Populate with existing sequences from the sequencesMap
    for key in sequencesMap {
        if (key != "Default") {
            existingSequences .= "|" key
        }
    }
    
    sequencesArray := StrSplit(existingSequences, "|")
    gui2.Add("ComboBox", "vChosenSequence", sequencesArray)
    gui2.Add("Button", , "Choose").OnEvent("Click", ChooseSequence.Bind(gui2, instanceNum))
    gui2.Add("Button", , "Show Sequences").OnEvent("Click", ShowSequences)
    gui2.Title := "Choose Key Sequence"
    gui2.Show("w300 h200")
    
    ; Wait for user input to complete before proceeding
    instanceInputComplete := false
    while (!instanceInputComplete) {
        Sleep(100)
    }
}

ShowSequences(*) {
    global sequencesMap
    sequenceList := "Loaded sequences in map:`n"
    for section, keyPresses in sequencesMap {
        sequenceList .= section ": " keyPresses "`n"
    }
    MsgBox(sequenceList)
}

KeySyntax(*) {
    Run("https://www.autohotkey.com/docs/v2/lib/Send.htm")
}    

ChooseSequence(gui2, instanceNum, *) {
    global sequencesMap, specialInstances, instanceSequenceNames, instanceInputComplete, defaultSequence
    gui2.Submit()
    ChosenSequence := gui2["ChosenSequence"].Text
    
    if (ChosenSequence == "") {
        MsgBox("Error: No sequence selected.")
        gui2.Show("w400 h200")  ; Re-show the GUI
        return
    }

    if (ChosenSequence == "New Sequence") {
        ; Prompt for new key sequence
        gui3 := Gui()
        gui3.Opt("+AlwaysOnTop")
        gui3.Add("Text", , "Enter key presses for Instance " instanceNum " `n(comma-separated):").SetFont("Bold")
        gui3.Add("Text",,"Modifiers: Ctrl=^, Alt=!, Shift=+`n Enclose Key Names in {} `n Examples:`n  -{Space down},{Space up}`n  -{Left down},^h,{Left up}`n  -h,e,l,l,o")
        gui3.Add("Button",,"Syntax Help").OnEvent("Click", KeySyntax)
        gui3.Add("Text","x+m","opens in new window")
        gui3.Add("Text", , "Enter key presses for Instance " instanceNum ":")
        gui3.Add("Edit", "vKeyPresses w200 h40") ; Increased size for better visibility
        gui3.Add("Text", , "Enter a nickname for this key sequence:")
        gui3.Add("Edit", "vSequenceNickname w200 h20") ; Increased size for better visibility
        gui3.Add("Button", , "Save").OnEvent("Click", SaveNewSequence.Bind(gui3, instanceNum))
        gui3.Title := "New Key Sequence"
        gui3.Show("w400 h300")
    } else {
        ; Load the chosen sequence
        KeyPresses := (ChosenSequence = "Default") ? defaultSequence : sequencesMap[ChosenSequence]
        instanceSequenceNames.InsertAt(instanceNum, ChosenSequence)
        specialInstances[instanceNum] := StrSplit(KeyPresses, ",")
        gui2.Destroy()
        instanceInputComplete := true
    }
}

SaveNewSequence(gui3, instanceNum, *) {
    global sequencesMap, specialInstances, iniFilePath, instanceSequenceNames, instanceInputComplete
    gui3.Submit()
    KeyPresses := gui3["KeyPresses"].Text
    SequenceNickname := gui3["SequenceNickname"].Text
    
    if (KeyPresses == "" || SequenceNickname == "") {
        MsgBox("Error: Key presses or sequence nickname cannot be empty.")
        gui3.Show("w400 h300")  ; Re-show the GUI
        return
    }
    
    IniWrite(KeyPresses, iniFilePath, "Keystrokes", SequenceNickname)
    sequencesMap[SequenceNickname] := KeyPresses
    instanceSequenceNames.InsertAt(instanceNum, SequenceNickname)
    specialInstances[instanceNum] := StrSplit(KeyPresses, ",")
    gui3.Destroy()
    instanceInputComplete := true
}

LoadSequences() {
    global iniFilePath, sequencesMap, defaultSequence
    iniContents := FileRead(iniFilePath)

    ; Iterate through each line in the INI file
    for line in StrSplit(iniContents, "`n") {
        if (InStr(line, "=")) {
            ; Extract the key (sequence name) and the value (key presses)
            key := RegExReplace(line, "^(.*)=.*$", "$1")
            keyPresses := RegExReplace(line, "^.*=(.*)$", "$1")
            sequencesMap[key] := keyPresses
        }
    }
}

PromptForTimeInterval() {
    global timeInterval
    guiTime := Gui()
    guiTime.Opt("+AlwaysOnTop")
    guiTime.Add("Text", , "Enter time between instances (in ms):")
    guiTime.Add("Edit", "vTimeInterval", timeInterval)  ; Pre-populated with the default value
    guiTime.Add("Button",,"OK").OnEvent("Click", SetTimeInterval.Bind(guiTime))
    guiTime.Title := "Time Between Instances"
    guiTime.Show("w300 h150")
}

SetTimeInterval(guiTime, *) {
    global timeInterval, timeInputComplete
    guiTime.Submit()
    userInput := guiTime["TimeInterval"].Text
    if (userInput != "") {
        timeInterval := userInput
    }
    guiTime.Destroy()
    timeInputComplete := true
}

ShowStatusGUI(x, y) {
    global guiStatus, cycleCount
    guiStatus := Gui()
    guiStatus.Opt("+AlwaysOnTop")
    guiStatus.Add("Text",,"Hotkeys: `n-F8: Exit script`n-F12: Pause/Resume script")
    guiStatus.Add("Text", "vCycleCount", "Cycles Completed: 0000000").Opt("Wrap") ; Ensure text wraps if too long - Idea from JSLover https://www.autohotkey.com/board/topic/86024-fixed-gui-doesnt-show-double-digits/
    guiStatus.Add("Link",,'Visit Little J Birdie <a href="https://www.youtube.com/@littlejbirdie">on Youtube</a> `nor Join my <a href="https://discord.gg/te6JSdRF7C">Discord Server</a>')
    guiStatus.Title := "Cycle Count"
    guiStatus.Show("w250 h120 x" x " y" y) ; Increased size for better visibility
}

MainLoop() {
    global idList, specialInstances, minKeyPressInterval, timeInterval, cycleCount, guiStatus
    ; Main loop for executing key presses
    Loop {
        if A_IsPaused {
            guiStatus["CycleCount"].Text := "Cycles Completed: " TruncateLeadingZeros(Format("{:07}", cycleCount))
            Sleep(100)
            continue
        }
        
        Loop idList.Length {
            instanceNum := A_Index
            thisID := idList[instanceNum]
            
            ; Error handling for missing instances
            if !WinExist("ahk_id " thisID) {
                MsgBox("Instance " instanceNum " not found. Exiting.")
                ExitApp()
            }
            
            WinActivate(thisID)
            Sleep(200)
            
            ; Perform special key presses for this instance
            for key in specialInstances[instanceNum] {
                key := StrLower(key)
                if (InStr(key, "down") || InStr(key, "up")) {
                    Send(key)
                } else {
                    SendInput(key)
                }
                Sleep(minKeyPressInterval)
            }
            
            requiredTime := minKeyPressInterval * (specialInstances[instanceNum].Length + 1)
            if (timeInterval < requiredTime) {
                timeInterval := requiredTime
            }
            
            Sleep(timeInterval)
        }
        cycleCount++
        guiStatus["CycleCount"].Text := "Cycles Completed: " TruncateLeadingZeros(Format("{:07}", cycleCount))
        Sleep(1000)
    }
    return
}

ArrayToString(array) {
    str := ""
    for index, element in array {
        str .= element ", "
    }
    return SubStr(str, 1, -2) ; Remove the trailing comma and space
}

TruncateLeadingZeros(number) {
    return RegExReplace(number, "^0+", "")  ; Remove leading zeros
}

F8::ExitApp()
F12::Pause -1
