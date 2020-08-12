win32_header_parser() { ; total header files: 3,505
    root := Settings.Has("ApiPath") ? Settings["ApiPath"] : ""
    If (!root) {
        Msgbox "Specify the path for the Win32 headers first."
        return
    }
    
    Loop Files root "\*", "R"
        fCount := A_Index
    
    IncludesList := Map(), const_list := Map()
    
    prog := progress2.New(0,fCount,"title:Scanning files...,mainText:0 of " fCount)
    Static q := Chr(34)
    rg1 := "i)^\#include[ `t]+(<|\" q ")([^>" q "]+)(>|\" q ")"
    rg2 := "i)^#define[ `t]+(\w+)[ `t]+(.+)"
    
    Loop Files root "\*.h", "R"
    {
        fullPath := A_LoopFileFullPath, file := A_LoopFileName
        prog.Update(A_Index,A_Index " of " fCount,file)
        fText := FileRead(fullPath)
        fArr := StrSplit(fText,"`n","`r")
        
        c := 1
        For i, curLine in fArr {
            constValue := "" ; init value
            c := 1 ; counter for more lines
            If (RegExMatch(curLine,rg1,m)) { ; include line
                If (!IncludesList.Has(file))
                    IncludesList[file] := [m.Value(2)]
                Else
                    IncludesList[file].Push(m.Value(2))
            } Else If (RegExMatch(curLine,rg2,m)) {
                constName := m.Value(1), constExp := m.Value(2)
                
                comment := ""
                If (RegExMatch(constExp,"([ `t]*//.*|[ `t]*/\*.*)",m2)) {
                    comment := Trim(m2.Value(0)," `t")
                    constExp := RegExReplace(constExp,"([ `t]*//.*|[ `t]*/\*.*?\*/)","")
                    constExp := RegExReplace(constExp,"[ `t]*/\*.*","")
                }
                
                nextLine := fArr[i+c]
                While (SubStr(constExp,-1) = "\") {
                    nextLine := RegExReplace(nextLine,"([ `t]*//.*|[ `t]*/\*.*?\*/)","")
                    nextLine := RegExReplace(nextLine,"[ `t]*/\*.*","")
                    
                    constExp := SubStr(constExp,1,-1) . nextLine
                    c++, nextLine := fArr[i+c]
                }
                
                constExp := RegExReplace(Trim(constExp," `t"),"[ ]{2,}"," ")
                If (InStr(constExp,"//") = 1) ; this is a comment, not a value/expression!
                    constExp := ""
                
                If (SubStr(constExp,1,-1) = constName And (SubStr(constExp,-1) = "w" Or SubStr(constExp,-1) = "a"))
                    vConst := {value:constExp, type:"macro"}
                ; Else If (!InStr(constExp," ") And RegExMatch(constExp,"i)[a-z0-9_]+") AND (RegExMatch(constExp,"i)(a|w|wide)$")))
                    ; vConst := {value:constExp, type:"macro"}
                Else If (SubStr(constExp,2) = constName And SubStr(constExp,1,1) = "_")
                    vConst := {value:constExp, type:"struct"}
                Else
                    vConst := value_cleanup(constExp)
                
                item := Map("exp",constExp,"comment",comment,"file",file,"line",i,"value",vConst.value,"type",vConst.type)
                
                If (!const_list.Has(constName))
                    const_list[constName] := item
                Else If (!const_list[constName].Has("dupe")
                  And (const_list[constName]["exp"] != constExp)
                  And SubStr(const_list[constName]["exp"],1,-1) != SubStr(constExp,1,-1)
                  And const_list[constName]["value"] != vConst.value)
                    const_list[constName]["dupe"] := [item]
                Else If (const_list[constName].Has("dupe") And (const_list[constName]["dupe"][1]["exp"] != constExp))
                    const_list[constName]["dupe"].Push(item)
            }

        }
    }
    
    prog.Close()
    
    ; prevList := ""
    ; Loop {
        ; curList := reparse1a(A_Index)
        ; If (curList = prevList or curList = "")
            ; Break
        ; prevList := curList
    ; }
    
    ; prevList := ""
    ; Loop { ; re-use until no replacements
        ; curList := reparse2(A_Index)
        ; If (curList = prevList or curList = "")
            ; Break
        ; prevList := curList
    ; }
    
    ; prevList := ""
    ; Loop { ; re-use until no replacements
        ; curList := reparse3(A_Index)
        ; If (curList = prevList or curList = "")
            ; Break
        ; prevList := curList
    ; }
    
    ; prevList := ""
    ; Loop {
        ; curList := reparse4(A_Index)
        ; If (curList = prevList or curList = "")
            ; Break
        ; prevList := curList
    ; }
    
    ; prevList := ""
    ; Loop {
        ; curList := reparse5(A_Index)
        ; If (curList = prevList or curList = "")
            ; Break
        ; prevList := curList
    ; }
    
    ; reparse6()
    
    g["Total"].Value := "Scan complete: " const_list.Count " constants recorded."
}

reparse1a(pass) { ; constants that point to a single constant / any type
    t := 0, list := ""
    prog := progress2.New(0,const_list.Count,"title:Reparse 1")
    prog.Update(A_Index,"Reparse 1 - Pass #" pass)
    
    For const, obj in const_list {
        prog.Update(A_Index)
        
        cValue := obj["value"], cType := obj["type"], cExp := obj["exp"]
        
        If (cType = "unknown") {
            nObj := const_list[cValue]
            nType := nObj["type"], nValue := nObj["value"]
            
            obj["type"] := nType, obj["value"] := nValue 
            const_list[const] := obj
            
            t++, list .= const "`r`n"
        }
    }
    
    prog.Close() ; msgbox "reparse1: " t
    return list
}

; reparse6() {
    ; t := 0
    ; prog := progress2.New(0,const_list.Count,"title:Reparse 6")
    ; prog.Update(A_Index,"Reparse 6 - removing duplicates with same value")
    
    ; For const, obj in const_list {
        ; prog.Update(A_Index)
        
        ; dupe := obj.Has("dupe") ? obj["dupe"] : ""
        ; If (dupe) {
            ; cValue := obj["value"], newDupes := []
            ; For i, obj2 in dupe {
                ; If (cValue != obj2["value"])
                    ; newDupes.push(obj2)
            ; }
            
            ; If (newDupes.Length)
                ; const_list[const]["dupe"] := newDupes, t++
            ; Else
                ; const_list[const].Delete("dupe")
        ; }
    ; }
    
    ; prog.Close() ; msgbox "saved dupes: " t
; }


; reparse5(pass) {
    ; t := 0, list := "", opers := "+-*/^|&<<>>~()"
    ; prog := progress2.New(0,const_list.Count,"title:Reparse 5")
    ; prog.Update(A_Index,"Reparse 5 - Pass #" pass)
    
    ; For const, obj in const_list {
        ; prog.Update(A_Index)
        
        ; cValue := obj["value"], cValue := StrReplace(cValue,"~"," ~ ")
        ; cType := obj["type"], cExp := obj["exp"]
        ; newVal := 0, finalVal := "", success := true
        
        ; If (cType = "unknown" And InStr(cValue," ")) {
            ; arr := StrSplit(cValue," ")
            
            ; For i, v in arr {
                ; v := Trim(v)
                ; If (v = "")
                    ; Continue
                
                ; If (RegExMatch(v,"i)(0x)?[\da-f]+[ul]+$"))
                    ; v := RegExReplace(v,"i)(u|l|ul|ull|ll)$","")
                
                ; If (const_list.Has(v) And const_list[v]["type"] = "integer") {
                    ; newVal := Integer(const_list[v]["value"])
                ; } Else If (IsInteger(v)) {
                    ; newVal := Integer(v)
                ; } Else If (InStr(opers,v)) { ; Or v = "<<" Or v = ">>") {
                    ; newVal := v
                ; } Else {
                    ; newVal := 0, finalVal := "", success := false
                    ; Break ; MUST break / cancel changes to obj
                ; }
                
                ; finalVal .= newVal " "
            ; }
            ; finalVal := Trim(finalVal)
            
            ; If (success) {
                ; Try {
                    ; old := finalVal
                    ; finalVal := eval(finalVal)
                    
                    ; If (!IsInteger(finalVal)) {
                        ; Continue
                    ; }
                ; } Catch e
                    ; Continue
                
                ; obj["value"] := finalVal, obj["type"] := "integer"
                ; const_list[const] := obj
                ; t++, list .= const "`r`n"
            ; }
        ; }
        ; c := A_Index
    ; }
    
    ; prog.Close() ; msgbox "reparse5: " t
    ; return list
; }

; reparse4(pass) {
    ; t := 0, list := ""
    ; prog := progress2.New(0,const_list.Count,"title:Reparse 4")
    ; prog.Update(A_Index,"Reparse 4 - Pass #" pass)
    
    ; For const, obj in const_list {
        ; prog.Update(A_Index)
        
        ; cValue := obj["value"], cType := obj["type"], cExp := obj["exp"]
        ; newVal := 0, finalVal := 0, success := true
        
        ; If (cType = "unknown" And InStr(cValue,"-")) {
            ; arr := StrSplit(cValue,"-")
            
            ; If (arr.Length != 2 Or arr[1] = "") 
                ; Continue
            
            ; For i, v in arr {
                ; v := Trim(v)
                ; If (const_list.Has(v) And const_list[v]["type"] = "integer") {
                    ; newVal := Integer(const_list[v]["value"])
                ; } Else If (IsInteger(v)) {
                    ; newVal := Integer(v)
                ; } Else {
                    ; newVal := 0, finalVal := 0, success := false
                    ; Break ; MUST break / cancel changes to obj
                ; }
                
                ; finalVal -= newVal
            ; }
            
            ; If (success) {
                ; obj["value"] := finalVal, obj["type"] := "integer"
                ; const_list[const] := obj
                ; t++, list .= const "`r`n"
            ; }
        ; }
        ; c := A_Index
    ; }
    
    ; prog.Close() ; msgbox "reparse4: " t
    ; return list
; }

; reparse3(pass) { ; const integer with bitwise OR "|"
    ; t := 0, list := ""
    ; prog := progress2.New(0,const_list.Count,"title:Reparse 3")
    ; prog.Update(A_Index,"Reparse 3 - Pass #" pass)
     
    ; For const, obj in const_list {
        ; prog.Update(A_Index)
        
        ; cValue := obj["value"], cType := obj["type"], cExp := obj["exp"]
        ; newVal := 0, finalVal := 0, success := true
        
        ; If (cType = "unknown" And InStr(cValue,"|")) {
            ; arr := StrSplit(cValue,"|")
            
            ; For i, v in arr {
                ; v := Trim(v)
                ; If (IsInteger(v))
                    ; newVal := Integer(v)
                ; Else If (const_list.Has(v) And const_list[v]["type"] = "integer") {
                    ; newVal := const_list[v]["value"]
                ; } Else {
                    ; success := false
                    ; Break
                ; }
                
                ; finalVal := finalVal | newVal
            ; }
            
            ; If (success) {
                ; obj["value"] := finalVal, obj["type"] := "integer"
                ; const_list[const] := obj
                ; t++, list .= const "`r`n"
            ; }
        ; }
        ; c := A_Index
    ; }
    
    ; prog.Close() ; msgbox "reparses3: " t
    ; return list
; }

; reparse2(pass) { ; only trying to calc [ const + number ] or similar
    ; t := 0, list := ""
    ; prog := progress2.New(0,const_list.Count,"title:Reparse 2")
    ; prog.Update(A_Index,"Reparse 2 - Pass #" pass)
    
    ; For const, obj in const_list {
        ; prog.Update(A_Index)
        
        ; cValue := obj["value"], cType := obj["type"], cExp := obj["exp"]
        ; newVal := 0, finalVal := 0, success := true
        
        ; If (cType = "unknown" And InStr(cValue,"+")) {
            ; arr := StrSplit(cValue,"+")
            
            ; If (arr.Length != 2 Or arr[1] = "") 
                ; Continue
            
            ; For i, v in arr {
                ; v := Trim(v)
                ; If (const_list.Has(v) And const_list[v]["type"] = "integer") {
                    ; newVal := Integer(const_list[v]["value"])
                ; } Else If (IsInteger(v)) {
                    ; newVal := Integer(v)
                ; } Else {
                    ; newVal := 0, finalVal := 0, success := false
                    ; Break ; MUST break / cancel changes to obj
                ; }
                
                ; finalVal += newVal
            ; }
            
            ; If (success) {
                ; obj["value"] := finalVal, obj["type"] := "integer"
                ; const_list[const] := obj
                ; t++, list .= const "`r`n"
            ; }
        ; }
        ; c := A_Index
    ; } ; end FOR loop
    
    ; prog.Close() ; msgbox "reparse2: " t ; " / " c
    ; return list
; }

; reparse1(pass) { ; constants that point to a single constant / any type
    ; t := 0, list := ""
    ; prog := progress2.New(0,const_list.Count,"title:Reparse 1")
    ; prog.Update(A_Index,"Reparse 1 - Pass #" pass)
    
    ; For const, obj in const_list {
        ; prog.Update(A_Index)
        
        ; cValue := obj["value"], cType := obj["type"], cExp := obj["exp"]
        
        ; If (cType = "unknown" And const_list.Has(cValue)) {
            ; nObj := const_list[cValue]
            ; nType := nObj["type"], nValue := nObj["value"]
            
            ; obj["type"] := nType, obj["value"] := nValue 
            ; const_list[const] := obj
            
            ; t++, list .= const "`r`n"
        ; }
    ; }
    
    ; prog.Close() ; msgbox "reparse1: " t
    ; return list
; }

; 32-bit LONG max value = 2147483647
; 32-bit ULONG max value = 4294967296
; 32-bit convert LONG to ULONG >>> add 2147483648

; 64-bit LONG LONG max value = 9223372036854775807
; 64-bit ULONG LONG max vlue = 18446744073709551616
; 64-bit convert LONGLONG to ULONGLONG >>> add 9223372036854775808

value_cleanup(inValue) {
    Static q := Chr(34)
    cType := "unknown"
    
    If (RegExMatch(inValue,"^\w+\x28")) {       ; Macros likely won't be resolved, so identify them as such
        cType := "macro", cValue := inValue     ; so we don't continually recurse them.
        Goto Finish
    }
    
    ; If (SubStr(inValue,1,1) = "(" And SubStr(inValue,-1) = ")" And !InStr(inValue,")(")) ; prune external parenthesis
        ; inValue := SubStr(inValue,2,-1)
    ; Else If (SubStr(inValue,1,2) = "((" And SubStr(inValue,-2) = "))")
        ; inValue := SubStr(inValue,2,-1)
    
    ; inValue := StrReplace(StrReplace(inValue,"<<"," << "),">>"," >> ")
    
    inValue := RegExReplace(inValue,";$","")
    
    ; If (inValue != Chr(34) "+" Chr(34) And inValue != "'+'")
        ; inValue := StrReplace(inValue,"+"," + ")
    ; inValue := StrReplace(StrReplace(inValue,"< <","<<"),"> >",">>")
    ; If (!RegExMatch(inValue,"(\~)?\x28\w+\x29[ ]*(\-)?\d") And !InStr(inValue,")(") And !InStr(inValue,"TEXT(",true) And !RegExMatch(inValue,"i)^[a-z]+\x28"))
        ; inValue := StrReplace(StrReplace(inValue,"("," ( "),")"," ) ")
    ; If (RegExMatch(inValue,"\~\x28[ ]*\w+[ ]*\|"))
        ; inValue := StrReplace(StrReplace(inValue,"("," ( "),")"," ) ")
    
    inValue := RegExReplace(inValue,"[ ]{2,}"," ")
    inValue := Trim(inValue," `t")
    
    cValue := inValue ; save cValue without outside (parenthesis)
    
    If (IsInteger(inValue)) { ; type = integer / no conversion needed
        cType := "integer", cValue := Integer(inValue)
        Goto Finish
    }
    
    ; newValue := eval(inValue)
    ; If (IsInteger(newValue)) {
        ; cType := "integer", cValue := newValue
        ; Goto Finish
    ; }
    
    ; If (RegExMatch(inValue,"i)\d+U\-\d+U")) {
        ; newValue := StrReplace(inValue,"U","")
        ; newValue := eval(newValue)
        ; If (IsInteger(newValue)) {
            ; cType := "integer", cValue := newValue
            ; Goto Finish
        ; }
    ; }
    
    If (RegExMatch(inValue,"i)^\x28ULONG\x29([ ]*)?(0x[\dA-F]+)L?$",m)) {
        If (IsInteger(m.Value(2))) {
            inValue := Integer(m.Value(2)) + 2147483648 ; convert to unsigned long
            cType := "integer", cValue := inValue
            Goto Finish
        }
    }
    
    If (RegExMatch(inValue,"^\x28LONG\x29((0x)?[\dA-Fa-f]+)$",m)) { ; convert to signed long
        If (IsInteger(m.Value(1))) {
            inValue := Integer(m.Value(1)) - 2147483648 ; convert to unsigned long
            cType := "integer", cValue := inValue
            Goto Finish
        }
    }
    
    newValue := RegExReplace(inValue,"^(\x28?(0x)?[a-fA-F0-9]+)(U|L|UL|ULL|LL|ui|UI)(8|16|32|64)?\x29?$","$1")
    If (newValue != inValue And IsInteger(newValue)) { ; type = numeric literal
        cType := "integer", cValue := Integer(newValue)
        Goto Finish
    }
    
    If (SubStr(inValue,1,1) = q And SubStr(inValue,-1) = q And !InStr(inValue," + ")) { ; char string
        cType := "string", cValue := inValue
        Goto Finish
    }
    
    If (SubStr(inValue,1,2) = "L" q And SubStr(inValue,-1) = q And !InStr(inValue," + ")) { ; wchar_t string
        cType := "string", cValue := inValue
        Goto Finish
    }
    
    Finish:
    inValue := RegExReplace(inValue,"[ ]{2,}"," ") ; attempt to remove consecutive spaces, hopefully won't break anything
    inValue := Trim(inValue," `t")
    return {value:cValue, type:cType}
}

isExpr(sInput) {
    If mathStr = "" Or InStr(mathStr,Chr(34))
        return false
    Loop Parse mathStr
    {
        c := Ord(A_LoopField)
        If (c >= 65 And c <= 90) Or (c >= 97 And c <= 122)
            return false ; actual string evaluated MUST be purely numerical with operators
    }
    return true
}

get_full_path(inFile) {
    fullPath := ""
    root := Settings.Has("ApiPath") ? Settings["ApiPath"] : ""
    If (!root)
        return ""
    
    Loop Files root "\*", "R"
    {
        If (!fullPath And InStr(A_LoopFileFullPath,"\" inFile))
            fullPath := A_LoopFileFullPath
        Else If (fullPath And InStr(A_LoopFileFullPath,"\" inFile))
            Msgbox "Dupe file found:`r`n`r`n" fullPath "`r`n`r`n" A_LoopFileFullPath
    }
    
    return fullPath
}