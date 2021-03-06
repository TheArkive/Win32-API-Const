Global filter_gui

load_filters() {
    Global Settings, filter_gui
    filter_gui := Gui("-MinimizeBox -MaximizeBox +Owner" Settings["gui"].hwnd,"More Filter Options")
    filter_gui.OnEvent("escape",filter_escape)
    filter_gui.OnEvent("close",filter_close)
    
    filter_gui.Add("Text","xm y+5 Right w35","File:")
    filter_gui.Add("ComboBox","yp-4 x+2 w410 vFileFilter Sort").OnEvent("change",gui_events)
    
    fileList := listFiles()
    filter_gui["FileFilter"].Delete()
    filter_gui["FileFilter"].Add(fileList)
    filter_gui["FileFilter"].Opt("+Sort")
    filter_gui["FileFilter"].Text := Settings["FileFilter"]
    
    filter_gui.Add("Button","x+0 hp vFileFilterClear","X").OnEvent("click",gui_events)
    
    filter_gui.Add("Text","xm y+10","Types:")
    ctl := filter_gui.Add("Checkbox","y+5 vInteger Section","Integer"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckInteger"]
    ctl := filter_gui.Add("Checkbox","y+5 vFloat","Float"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckFloat"]
    ctl := filter_gui.Add("Checkbox","y+5 vString","String"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckString"]
    
    ctl := filter_gui.Add("Checkbox","xs+100 ys vStruct Section","Struct"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckStruct"]
    ctl := filter_gui.Add("Checkbox","xs y+5 vEnum","Enum"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckEnum"]
    ctl := filter_gui.Add("Checkbox","xs y+5 vExpr","Expr"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckExpr"]
    
    ctl := filter_gui.Add("Checkbox","xs+100 ys vUnknown Section","Unknown"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckUnknown"]
    ctl := filter_gui.Add("Checkbox","xs y+5 vOther","Other"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckOther"]
    ctl := filter_gui.Add("Checkbox","xs y+5 vDupe","Dupe"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckDupe"]
    ctl := filter_gui.Add("Checkbox","xs y+5 vCrit","Critical"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckCrit"]
    
    
    filter_gui.Show()
    
    WinSetEnabled False, Settings["gui"].hwnd
}

filter_close(_gui) {
    Global Settings
    WinActivate "ahk_id " Settings["gui"].hwnd
    WinSetEnabled True, Settings["gui"].hwnd
    Settings["gui"]["NameFilter"].Focus()
}

filter_escape(_gui) {
    Global filter_gui
    filter_close(_gui)
    filter_gui.Destroy()
}