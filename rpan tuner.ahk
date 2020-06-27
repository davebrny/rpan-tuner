/*
[script_info]
version     = 1.1.4
description = keep up to date with your favourite rpan broadcasters
author      = davebrny
source      = https://github.com/davebrny/rpan-tuner
*/

#persistent
#singleInstance, force
sendMode, input
setWorkingDir, % a_scriptDir
onExit, gui_exit

hotkey, ^r, update_broadcasts  ; set hotkeys
hotkey, ifWinActive, rpan tuner
hotkey, m, show_menu
hotkey, l, show_live_menu

#include, <JSON>  ; load json
fileRead, contents, settings.json
a := JSON.Load(contents)

if (a.update_frequency >= 1)
    setTimer, time_check, 30000  ; check every 30 seconds

broadcasters := []  ; convert to array
for index in a.broadcaster
    broadcasters.push(index)

loop, % a.channels.maxIndex()  ; convert to string
    channels .= a.channels[a_index] ", "

goSub, load_gui

return ; end of auto-execute ---------------------------------------------------




load_gui:
gui font, s10, fixedSys
gui add, listView, x10 y45 w480 h175 sortDesc noSortHdr vList_view gLv_click
                 , date|title|broadcaster|live|time|url
lv_modifyCol(1, "0")    ; date column (hidden, for sorting)
lv_modifyCol(2, "275")  ; title
lv_modifyCol(3, "115")  ; broadcaster
lv_modifyCol(4, "42")   ; live status
lv_modifyCol(5, "170")  ; time
lv_modifyCol(6, "0")    ; url (hidden)

gui font, s9, fixedSys
gui add, button, x10 y10 w25 h25 gShow_menu, >
gui add, statusBar, gSb_click, 0 live:
gui +resize +lastFound
gui show, w510 h260, rpan tuner

gui_id := winExist()
if (a.gui_size.maxIndex())  ; set x, y, width and heigth
    winMove, % "ahk_id " gui_id, , % a.gui_size.1, % a.gui_size.2, % a.gui_size.3, % a.gui_size.4

selected_broadcaster := "&all"
goSub, update_broadcasts
return



update_broadcasts:
if (broadcasters.maxIndex() = "") and (first_run = "")
    {
    first_run := 1
    goSub, add_new_broadcaster
    return
    }

if (updating != true)
    {
    updating := true
    setBatchLines, -1  ; run at full speed
    rpan := []  ; initialise array
    recent_broadcasts := ""
    max_broadcast := a_now
    max_broadcast += -2, h  ; the time 2 hours ago

    loop, % broadcasters.maxIndex()
        {
        broadcaster := broadcasters[a_index]
        rpan[broadcaster] := [] ; initialise array
        sb_setText("`t`tdownloading " broadcaster, 2)
        xml := download("https://www.reddit.com/user/" broadcaster "/submitted.rss")
        parse_xml(xml)
        }

    update_listView(selected_broadcaster)

    new_live := ""
    rpan.live := []
    sb_setText("", 2)
    sb_setText("searching for live broadcasts...", 1)
    live_list := live_broadcasters(recent_broadcasts)
    update_live_status()
    sb_setText(rpan.live.maxIndex() " live: " trim(live_list, ", "), 1)
    if (new_live) and (a.show_notifications = true)
        trayTip, new rpan broadcast!, % trim(new_live, ", "), 8

    formatTime, time_now, % a_now, HH:mm
    sb_setText("`t`tlast updated: " time_now, 2)
    setBatchLines, 10
    last_update := a_now
    updating := false
    }
return


show_menu:
if (broadcasters.maxIndex())
    {
    menu, broadcaster_menu, add, &all, select_broadcaster
    menu, broadcaster_menu, add, ; separator
    loop, % broadcasters.maxIndex()
        menu, broadcaster_menu, add, % broadcasters[a_index], select_broadcaster
    menu, broadcaster_menu, add
    }
menu, broadcaster_menu, add, add new, add_new_broadcaster

ahk_script := a_scriptDir "\" subStr(a_scriptName, 1, strLen(a_scriptName) - 4) ".ahk"
if fileExist(ahk_script)
    {
    iniRead, version, % ahk_script, script_info, version
    menu, about_menu, add, % t := "rpan tuner: version " version, github_page
    menu, about_menu, disable, % t
    menu, about_menu, add,
    }
menu, about_menu, add, github page, github_page

menu, main_menu, add, &select broadcaster, :broadcaster_menu
menu, main_menu, add, &check for new broadcasts, update_broadcasts
menu, main_menu, add, &reload rpan tuner, reload_tuner
menu, main_menu, add,
menu, main_menu, add, about, :about_menu

menu, main_menu, show
loop, parse, % "main|broadcaster|about", |
    menu, % a_loopField "_menu", deleteAll
return


select_broadcaster:
selected_broadcaster := a_thisMenuItem
update_listView(selected_broadcaster)
update_live_status()
return


add_new_broadcaster:
inputBox, new_broadcaster, add new broadcaster, , , 210, 105
if (errorLevel != 1)
    {
    for index in a.broadcaster  ; check if already added
        {
        if (index = new_broadcaster)
            already_added := true
        }
    if (already_added != true)
        {
        a.broadcaster[new_broadcaster] := {}  ; update json
        save_json(a, "settings.json")
        broadcasters := []  ; recreate array so its alphabetical
        for index in a.broadcaster
            broadcasters.push(index)
        }
    }
return


reload_tuner:
reload
return


github_page:
run, https://github.com/davebrny/rpan-tuner
return


lv_click:  ; listView
if (a_guiEvent = "DoubleClick")
    {
    lv_getText(listview_url, a_eventInfo, 6)
    run, % listview_url
    }
return


sb_click:  ; statusBar
goSub, show_live_menu
return


show_live_menu:
if (rpan.live.maxIndex())
    {
    loop, % rpan.live.maxIndex()
        menu, live_menu, add, % rpan.live[a_index].1, open_broadcast
    }
else
    {
    menu, live_menu, add, % t := "no broadcasts :(", open_broadcast
    menu, live_menu, disable, % t
    }
menu, live_menu, show
menu, live_menu, deleteAll 
return


open_broadcast:
loop, % rpan.live.maxIndex() 
    {
    this_index := a_index
    for index, value in rpan.live[this_index]
        {
        if (value = a_thisMenuItem)
            {
            run, % rpan.live[this_index].2  ; open url
            break
            }
        }
    }
Return


GUISize:
guicontrol, move, list_view, % "w" (a_guiWidth - 20) " h" (a_guiHeight - 65)
if (a_guiWidth < 340)
     sb_setParts("346", "155")
else sb_setParts((a_guiWidth - 155), "155")
return


gui_exit:
winGetPos, x, y, w, h, % "ahk_id " gui_id
a.gui_size.1 := x
a.gui_size.2 := y
a.gui_size.3 := w
a.gui_size.4 := h
save_json(a, "settings.json")
exitApp


guiClose:
exitApp


time_check:
next_update := last_update
next_update += % a.update_frequency, m  ; add minutes
if (a_now > next_update)
    goSub, update_broadcasts  
return


save_json(object, path) {
    file := fileOpen(path, "w `n")
    file.write(JSON.Dump(object, , 4))
    file.close()
}


download(url) {
    comObjError(false)
    request := comObjCreate("WinHttp.WinHttpRequest.5.1")
    request.open("GET", url)
    request.send()
    while (request.responseText = "") and (a_index <= 5)
        sleep 200
    return request.responseText
}


parse_xml(xml) {
    global
    strReplace(xml, "<entry>", "", post_count)
    loop, % post_count
        {
        entry := xml_element(xml, "<entry>", "</entry>", a_index)
        channel := xml_element(entry, "<category term=""", """")
        if inStr(channels, channel)   ; if post is a broadcast
            {
            title := xml_element(entry, "<title>", "</title>")
            link  := xml_element(entry, "<link href=""", """")
            time  := xml_element(entry, "<updated>", "</updated>")
            timestamp := format_time(time)
            formatTime, time_date, % timestamp, (HH:mm) dd-MM-yyyy  ; for displaying
            formatTime, time_sort, % timestamp, yyyy-MM-dd HH:mm:ss ; for sorting listview

            rpan[broadcaster].push([ title , link , time_date , time_sort ])
            if (timestamp > max_broadcast)    ; if within last 2 hours
                recent_broadcasts .= time_sort "|" broadcaster "|" link "`n"
            }
        }
}
xml_element(xml, start, end, index="1") {
    stringGetPos, pos, xml, % start, L%index%
    stringMid, str_right, xml, pos + 1 + strLen(start)
    stringGetPos, pos, str_right, % end
    stringMid, value, str_right, pos, , L
    return value
}


format_time(str) {  ; convert time 2020-12-31T12:34:56+00:00
    str := regExReplace(str, "[^0-9]")  ; leave numbers only
    timestamp := subStr(str, 1, 14)     ; remove +00:00
    tz_difference := round( (a_now - a_nowUTC) / 10000 )
    timestamp += % tz_difference, h
    return timestamp
}


update_listView(selected_broadcaster) {
    global
    guiControl, -redraw, list_view
    lv_delete()

    if (selected_broadcaster = "&all")
        {
        loop, % broadcasters.maxIndex()
            update_rows(broadcasters[a_index])   
        }
    else update_rows(selected_broadcaster)

    lv_modifyCol(1, sort)  ; sort by recent decending
    guiControl, +redraw, list_view
}


update_rows(name) {
    global
    loop, % rpan[name].maxIndex()
        {
        title     := rpan[name][a_index].1
        url       := rpan[name][a_index].2
        time_date := rpan[name][a_index].3
        time_sort := rpan[name][a_index].4
        lv_add("", time_sort, title, name, , time_date, url)
        }
}


update_live_status() {
    global
    loop,
        {
        this_index := a_index
        lv_getText(row_url, this_index, 6)
        for index, value in rpan.live[this_index] {
            if (value = row_url)  ; if url is in live list
                lv_modify(this_index, "col4", "live")
            }
        }
    until (row_url = "")
}


live_broadcasters(recent_broadcasts) {
    global rpan, new_live
    static off_air_list, previous_live
    sort, recent_broadcasts, r    ; sort most recent to the top
    loop, parse, recent_broadcasts, `n
        {
        split := strSplit(a_loopField, "|")
        this_broadcaster := split[2]
        this_url         := split[3]

        if inStr(checked_list, this_broadcaster) ; only check each name or url once
        or inStr(off_air_list, this_url)
            continue

        html := download(this_url)      ; check page for live status
        stringGetPos, pos, html, </div><h1 class=, L1
        stringMid, str_left, html, pos, , L
        stringGetPos, pos, str_left, % """", R1
        stringMid, string, str_left, pos + 2
        if inStr(string, "Live") and !inStr(string, "Recorded live")
            {
            if !inStr(previous_live, this_broadcaster)
                new_live .= this_broadcaster ", "
            rpan.live.push([ this_broadcaster , this_url ])
            live_list .= this_broadcaster ", "
            }
        else off_air_list .= this_url "`n"
        checked_list .= this_broadcaster "`n"
        }

    previous_live := live_list
    return live_list
}