/*
[script_info]
version     = 1.0.2
description = keep up to date with your favourite rpan broadcasters
author      = davebrny
source      = https://github.com/davebrny/rpan-tuner
*/

#persistent
#singleInstance, force
sendMode, input
setWorkingDir, % a_scriptDir
onExit, gui_exit
hotkey, ^r, update_broadcasts

#include, <JSON>
fileRead, contents, settings.json
o := JSON.Load(contents)

if (o.update_frequency >= 1)
    setTimer, time_check, 30000  ; check every 30 seconds

for index in o.broadcaster  ; convert object to string
    broadcasters .= (broadcasters ? "|" : "") . index
loop, % o.channels.maxIndex()
    channels .= o.channels[a_index] ", "

goSub, load_gui

return ; end of auto-execute ---------------------------------------------------




load_gui:
gui font, s10, fixedSys
columns := "date|title|broadcaster|live|time|url"
gui add, listView, x10 y45 w480 h175 sortDesc noSortHdr vList_view gLv_click, % columns
lv_modifyCol(1, "0")    ; date column (hidden, for sorting)
lv_modifyCol(2, "275")  ; title
lv_modifyCol(3, "115")  ; broadcaster
lv_modifyCol(4, "42")   ; live status
lv_modifyCol(5, "170")  ; time
lv_modifyCol(6, "0")    ; url (hidden)

gui font, s9, fixedSys
gui add, button, x10 y10 w25 h25 gShow_menu, >
gui add, statusBar, gSb_click, live:
gui +resize +lastFound
gui show, w510 h260, rpan tuner

gui_id := winExist()
if (o.gui_size.maxIndex())  ; set x, y, width and heigth
    winMove, % "ahk_id " gui_id, , % o.gui_size.1, % o.gui_size.2, % o.gui_size.3, % o.gui_size.4

selected := broadcasters  ; select all
goSub, update_broadcasts
return



update_broadcasts:
if (broadcasters = "") and (first_run = "")
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
    new_live := ""
    recent_broadcasts := ""
    max_broadcast := a_now
    max_broadcast += -2, h  ; the time 2 hours ago

    loop, parse, broadcasters, |
        {
        broadcaster := a_loopField
        rpan[broadcaster] := [] ; initialise array
        sb_setText("`t`tdownloading " broadcaster, 2)
        xml := download("https://www.reddit.com/user/" broadcaster "/submitted.rss")
        parse_xml(xml)
        }

    update_listView(selected)

    sb_setText("", 2)
    sb_setText("searching for live broadcasts...", 1)
    live_list := live_broadcasters(recent_broadcasts)
    strReplace(live_list, ",", "", live_count)
    sb_setText(live_count " live: " trim(live_list, ", "), 1)
    if (new_live) and (o.show_notifications = true)
        trayTip, new rpan broadcast!, % trim(new_live, ", "), 8

    formatTime, time_now, % a_now, HH:mm
    sb_setText("`t`tlast updated: " time_now, 2)
    setBatchLines, 10
    last_update := a_now
    updating := false
    }
return


show_menu:
menu, broadcaster_menu, add, &all, select_broadcaster
menu, broadcaster_menu, add, ; separator
loop, parse, broadcasters, |
    menu, broadcaster_menu, add, % a_loopField, select_broadcaster
menu, broadcaster_menu, add
menu, broadcaster_menu, add, add new, add_new_broadcaster

iniRead, version, % a_lineFile, script_info, version
menu, about_menu, add, % t := "rpan tuner: version " version, github_page
menu, about_menu, disable, % t
menu, about_menu, add,
menu, about_menu, add, github page, github_page

menu, main_menu, add, select broadcaster, :broadcaster_menu
menu, main_menu, add, check for new broadcasts, update_broadcasts
menu, main_menu, add, reload rpan tuner, reload_tuner
menu, main_menu, add,
menu, main_menu, add, about, :about_menu

menu, main_menu, show
loop, parse, % "main|broadcaster|about", |
    menu, % a_loopField "_menu", deleteAll
return


select_broadcaster:
if (a_thisMenuItem = "&all")
     selected := broadcasters
else selected := a_thisMenuItem
update_listView(selected)
return


add_new_broadcaster:
inputBox, input, add new broadcaster, , , 210, 105
if (errorLevel != 1)
    {
    if !inStr(broadcasters, input)  ; if not already added
        {
        broadcasters .= "|" input
        if inStr(broadcasters, "|") ; if "all" is selected then update it
            selected := broadcasters
        sort, broadcasters, D|      ; sort alphabetically
        
        o.broadcaster[input] := {}  ; update json
        save_json(o, "settings.json")
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


sb_click:  ; StatusBar
if (live_list)
    {
    loop, parse, % trim(live_list, ", "), `,
        menu, live_menu, add, % trim(a_loopField), open_broadcast
    menu, live_menu, show
    menu, live_menu, deleteAll  
    }
return


open_broadcast:
loop, 100
    {
    lv_getText(row_name, a_index, 3)
    lv_getText(live_status, a_index, 4)
    if (row_name = a_thisMenuItem) and (live_status = "live")
        {
        lv_getText(broadcast_url, a_index, 6)
        break
        }
    }
run, % broadcast_url
Return


GUISize:
guicontrol, move, list_view, % "w" (a_guiWidth - 20) " h" (a_guiHeight - 65)
if (a_guiWidth < 340)
     sb_setParts("346", "155")
else sb_setParts((a_guiWidth - 155), "155")
return


gui_exit:
winGetPos, x, y, w, h, % "ahk_id " gui_id
o.gui_size.1 := x
o.gui_size.2 := y
o.gui_size.3 := w
o.gui_size.4 := h
save_json(o, "settings.json")
exitApp


guiClose:
exitApp


time_check:
next_update := last_update
next_update += % o.update_frequency, m  ; add minutes
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

            rpan[broadcaster].push([ title , link , time_date, time_sort ])
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


update_listView(selected) {
    global
    guiControl, -redraw, list_view
    lv_delete()

    loop, parse, selected, |
        {
        name := a_loopField
        loop, % rpan[name].maxIndex()
            {
            title     := rpan[name][a_index].1
            url       := rpan[name][a_index].2
            time_date := rpan[name][a_index].3
            time_sort := rpan[name][a_index].4
            lv_add("", time_sort, title, name, , time_date, url)
            }
        }

    lv_modifyCol(1, sort)  ; sort by recent decending
    guiControl, +redraw, list_view
}


live_broadcasters(recent_broadcasts) {
    global new_live
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
            live_list .= this_broadcaster ", "
            loop, 100
                {
                lv_getText(row_url, a_index, 6)
                if (row_url = this_url)  ; update listview
                    {
                    lv_modify(a_index, "col4", "live")
                    break
                    }
                }
            }
        else off_air_list .= this_url "`n"
        checked_list .= this_broadcaster "`n"
        }

    previous_live := live_list
    return live_list
}