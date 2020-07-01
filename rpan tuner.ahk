/*
[script_info]
version     = 2.5
description = keep up to date with your favourite rpan broadcasters
author      = davebrny
source      = https://github.com/davebrny/rpan-tuner
*/

#singleInstance, force
sendMode, input
setWorkingDir, % a_scriptDir
onExit, gui_exit

hotkey, ^r, update_broadcasts  ; set hotkeys
hotkey, enter, menu_broadcaster_open
hotkey, ifWinActive, rpan tuner
hotkey, m, show_main_menu
hotkey, l, show_live_menu

#include, <JSON>  ; load json
fileRead, contents, settings.json
a := JSON.Load(contents)

if (a.update_frequency >= 1)
    setTimer, time_check, 15000  ; check every 15 seconds

goSub, load_gui

return ; end of auto-execute ---------------------------------------------------




load_gui:
gui font, s10, fixedSys
gui add, listView, x10 y10 w480 h260 checked altSubmit -multi vlistView gListView_click
                 , broadcaster|title|channel|rank|time|url
lv_modifyCol(1, "135")        ; broadcaster
lv_modifyCol(2, "300")        ; title
lv_modifyCol(3, "130")        ; channel
lv_modifyCol(4, "42 integer") ; rank
lv_modifyCol(5, "170")        ; time
lv_modifyCol(6, "0")          ; url (hidden)

gui font, s9, fixedSys
gui add, statusBar, gStatusBar_click, ? live
sb_setParts("62")
gui +resize +lastFound
gui show, w550 h255, rpan tuner

gui_id := winExist()
if (a.gui_size.maxIndex())  ; set x, y, width and heigth
    winMove, % "ahk_id " gui_id, , % a.gui_size.1, % a.gui_size.2, % a.gui_size.3, % a.gui_size.4

selected_view := "&all"
goSub, update_broadcasts
return



update_broadcasts:
if (updating != true)
    {
    updating := true
    sb_setText("tuning...", 1)
    
    json_data := download("https://strapi.reddit.com/broadcasts")
    if (json_data)
        live := JSON.Load(json_data)
    live_total := (live.data[1].total_streams - 1)
    check_live_following()
    update_listView(selected_view)
    
    if (json_data)
         sb_setText(live_total " live", 1)
    else sb_setText("off-air", 1)
    sb_setText(" " live_following_string(), 2)
    last_update := a_now
    updating := false
    }
return


show_main_menu:
menu, view_menu, add, &all, select_view
menu, view_menu, add, &following, select_view

ahk_script := a_scriptDir "\" subStr(a_scriptName, 1, strLen(a_scriptName) - 4) ".ahk"
if fileExist(ahk_script)
    {
    iniRead, version, % ahk_script, script_info, version
    menu, about_menu, add, % t := "rpan tuner: version " version, github_page
    menu, about_menu, disable, % t
    menu, about_menu, add,
    }
menu, about_menu, add, github page, github_page

if (lv_getNext(0))  ; if a row is selected
    {
    lv_getText(row_broadcaster, lv_getNext(0), 1)  ; get name
    menu, main_menu, add, % "open " row_broadcaster, menu_broadcaster_open
    if (a.following.hasKey(row_broadcaster))
         menu, main_menu, add, % "unfollow " row_broadcaster, menu_broadcaster_follow
    else menu, main_menu, add, % "follow "   row_broadcaster, menu_broadcaster_follow 
    menu, main_menu, add,  
    }

menu, main_menu, add, follow new broadcaster, follow_new_broadcaster
menu, main_menu, add, &check for new broadcasts, update_broadcasts
menu, main_menu, add, &view, :view_menu
menu, main_menu, add, ; separator
menu, main_menu, add, &reload rpan tuner, reload_tuner
menu, main_menu, add, about, :about_menu

menu, main_menu, show
loop, parse, % "main|view|about", |
    menu, % a_loopField "_menu", deleteAll
return


menu_broadcaster_open:  ; (right-click menu or enter)
if (lv_getNext(0))  ; if a row is selected
    {
    lv_getText(listview_url, lv_getNext(0), 6)  ; get url
    run, % listview_url
    }
return


menu_broadcaster_follow:
split := strSplit(a_thisMenuItem, a_space)
if inStr(split[1], "unfollow")
    {
    lv_modify(lv_getNext(0), "-check")
    a.following.delete( trim(split[2]) )  ; remove key
    if (selected_view = "&following")
        update_listView(selected_view)    ; refresh listView
    }
else
    {
    lv_modify(lv_getNext(1), "check")
    a.following[ trim(split[2]) ] := {}    ; add key
    lv_getText(listview_url, lv_getNext(0), 6)
    if !inStr(previous_broadcasts, listview_url)
        previous_broadcasts .= listview_url "`n"
    }
sb_setText(" " live_following_string(), 2)
save_json(a, "settings.json")
return


follow_new_broadcaster:
inputBox, input, follow new broadcaster, add names separated by a comma, , 230, 105
if (errorLevel != 1)  ; only if there was input
    {
    loop, parse, input, % "," , % a_space
        {
        if (a.following.hasKey(a_loopField) = false)  ; if not already added
            a.following[a_loopField] := {}
        }
    save_json(a, "settings.json")
    }
return


select_view:
selected_view := a_thisMenuItem
update_listView(selected_view)
return


reload_tuner:
reload
return


github_page:
run, https://github.com/davebrny/rpan-tuner
return


listView_click:
if (a_guiEvent = "DoubleClick")  ;;;; open row url
    {
    lv_getText(listview_url, a_eventInfo, 6)
    run, % listview_url
    }

if (a_guiEvent == "I") and (errorLevel = "c")  ;;;; checkbox clicked
    {
    lv_getText(broadcaster, a_eventInfo, 1)
    if (errorLevel == "C") and (a.following.hasKey(broadcaster) = false)  ; if checked
        {
        a.following[broadcaster] := {}    ; add key
        lv_getText(listview_url, a_eventInfo, 6)
        if !inStr(previous_broadcasts, listview_url)
            previous_broadcasts .= listview_url "`n"
        }
    else if (errorLevel == "c") and (a.following.hasKey(broadcaster))     ; if unchecked
        {
        a.following.delete(broadcaster)    ; remove key
        if (selected_view = "&following")
            update_listView(selected_view) ; refresh listView
        }
    sb_setText(" " live_following_string(), 2)
    save_json(a, "settings.json")
    }
return


guiContextMenu:
if (a_guiControl = "listView")
    goSub, show_main_menu
return


statusBar_click:
if (a_guiEvent = "RightClick")
    {
    lv_modify(lv_getNext(0), "-select")  ; deselect row
    goSub, show_main_menu
    }
else goSub, show_live_menu
return


show_live_menu:
menu, live_menu, add, live broadcasts:, open_broadcast
menu, live_menu, disable, live broadcasts:
menu, live_menu, add, ; separator

loop, % live_total
    {
    this_broadcaster := live.data[a_index].post.authorInfo.name
    if (a.following.hasKey(this_broadcaster))  ; if following
        menu, live_menu, add, % this_broadcaster, open_broadcast
    }

channel_list := ""
loop, % live_total
    {
    this_broadcaster := live.data[a_index].post.authorInfo.name
    this_channel     := live.data[a_index].post.subreddit.name
    if (this_broadcaster = "") or (this_channel = "")
        continue
    menu, all_menu, add, % this_broadcaster, open_broadcast
    menu, % this_channel, add, % this_broadcaster, open_broadcast
    ++%this_channel%_count
    if !inStr(channel_list, this_channel)  ; if not already in list
        channel_list .= (channel_list ? "|" : "") . this_channel
    }

if (live_following_string())
    menu, live_menu, add, ; separator

menu, live_menu, add, % "&all " a_tab "(" live_total ")", :all_menu
menu, live_menu, add,
loop, parse, % channel_list, |
    {
    var_name := a_loopfield "_count"
    channel_count := %var_name%  ; get value stored in variable name
    %a_loopfield%_count := "" ; reset
    menu, live_menu, add, % a_loopfield . a_tab "(" channel_count ")", :%a_loopfield%
    }

menu, live_menu, show
loop, parse, % "live_menu|all_menu|" . channel_list, |
    menu, % a_loopField, deleteAll
return


open_broadcast:
loop, % live_total
    {
    if (live.data[a_index].post.authorInfo.name = a_thisMenuItem)
        {
        run, % live.data[a_index].post.outboundLink.url  ; open url
        break
        }
    }
return


GUISize:  ; when gui is resized
guicontrol, move, listView, % "w" (a_guiWidth - 20) " h" (a_guiHeight - 36)
return


gui_exit:
winGetPos, x, y, w, h, % "ahk_id " gui_id  ; save window position
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
    setBatchLines, -1  ; run at full speed
    comObjError(false)
    request := comObjCreate("WinHttp.WinHttpRequest.5.1")
    request.open("GET", url)
    request.send()
    while (request.responseText = "") and (a_index <= 5)
        sleep 200
    setBatchLines, 10ms
    return request.responseText
}


check_live_following() {
    local this_broadcaster, this_url, new_broadcast

    loop, % live_total
        {
        this_broadcaster := live.data[a_index].post.authorInfo.name
        if (a.following.hasKey(this_broadcaster) = false)
            continue ; if not following

        this_url := live.data[a_index].post.outboundLink.url
        if !inStr(previous_broadcasts, this_url) ; if not in previous list
            {
            new_broadcast .= (new_broadcast ? ", " : "") . this_broadcaster
            previous_broadcasts .= this_url "`n"
            }
        }

    if (new_broadcast) and (a.show_notifications = true)
        trayTip, new rpan broadcast!, % new_broadcast, 8
}


update_listView(selected_view) {
    global a, live, live_total
    setBatchLines, -1  ; run at full speed
    guiControl, -redraw, listView
    lv_delete()

    loop, % live_total
        {
        options := ""
        this_broadcaster := live.data[a_index].post.authorInfo.name
        if (a.following.hasKey(this_broadcaster))   ; if following
            options := "check"
        else if (selected_view = "&following") ; and not following
            continue

        title       := live.data[a_index].post.title
        channel     := live.data[a_index].post.subreddit.name
        global_rank := live.data[a_index].global_rank
        sub_rank    := live.data[a_index].rank_in_subreddit
        url         := live.data[a_index].post.outboundLink.url
        start_time  := subStr(live.data[a_index].post.createdAt, 1, 19) ; remove +00:00 from timestamp
        if (this_broadcaster)
            lv_add(options, this_broadcaster, title, channel, global_rank, start_time, url)
        }

    lv_modifyCol(4, "sort")  ; sort by rank
    guiControl, +redraw, listView
    setBatchLines, 10ms
}


live_following_string() {  ; convert key list to string
    local this_broadcaster, string
    loop, % live_total
        {
        this_broadcaster := live.data[a_index].post.authorInfo.name
        if (a.following.hasKey(this_broadcaster))  ; if following
            string .= (string ? ", " : "") . this_broadcaster
        }
    return string
}