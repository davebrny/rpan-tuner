/*
[script_info]
version     = 2.1
description = keep up to date with your favourite rpan broadcasters
author      = davebrny
source      = https://github.com/davebrny/rpan-tuner
*/

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

goSub, load_gui

return ; end of auto-execute ---------------------------------------------------




load_gui:
gui font, s10, fixedSys
gui add, listView, x10 y45 w480 h175 vList_view gLv_click
                 , broadcaster|title|channel|rank|time|url
lv_modifyCol(1, "125")        ; broadcaster
lv_modifyCol(2, "285")        ; title
lv_modifyCol(3, "130")        ; channel
lv_modifyCol(4, "42 integer") ; rank
lv_modifyCol(5, "170")        ; time
lv_modifyCol(6, "0")          ; url (hidden)

gui font, s9, fixedSys
gui add, button, x10 y10 w25 h25 gShow_menu, >
gui add, statusBar, gSb_click, ? live
sb_setParts("62")
gui +resize +lastFound
gui show, w530 h260, rpan tuner

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
    setBatchLines, -1  ; run at full speed

    sb_setText("tuning...", 1)
    live := JSON.Load(  download("https://strapi.reddit.com/broadcasts")  )
    live_total := (live.data[1].total_streams - 1)
    live_following := check_live_following()
    update_listView(selected_view)
    sb_setText(live_total " live", 1)
    sb_setText(live_following, 2)

    setBatchLines, 10
    last_update := a_now
    updating := false
    }
return


show_menu:
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


select_view:
selected_view := a_thisMenuItem
update_listView(selected_view)
return


follow_new_broadcaster:
inputBox, input, follow new broadcaster, add names separated by a comma, , 230, 105
if (errorLevel != 1)  ; only if there was input
    {
    loop, parse, input, % "," , % a_space
        {
        if (in_obj(a.following, a_loopField) = false)  ; if not already added
            a.following[a_loopField] := {}
        }
    save_json(a, "settings.json")  ; update json
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
menu, live_menu, add, live broadcasts:, open_broadcast
menu, live_menu, disable, live broadcasts:
menu, live_menu, add,

channel_list := ""
loop, % live_total
    {
    broadcaster := live.data[a_index].post.authorInfo.name
    channel     := live.data[a_index].post.subreddit.name
    if (broadcaster = "") or (channel = "")
        continue
    menu, all_menu, add, % broadcaster, open_broadcast
    menu, % channel, add, % broadcaster, open_broadcast
    if !inStr(channel_list, channel)  ; if not already in list
        channel_list .= (channel_list ? "|" : "") . channel
    }

if (live_following)
    {
    try menu, following_menu, deleteAll
    loop, parse, live_following, % "`," , a_space
        menu, following_menu, add, % trim(a_loopField), open_broadcast
    }

menu, live_menu, add, &all, :all_menu
try menu, live_menu, add, &following, :following_menu
menu, live_menu, add, ; separator
loop, parse, % channel_list, |
    menu, live_menu, add, % a_loopfield, :%a_loopfield%

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
guicontrol, move, list_view, % "w" (a_guiWidth - 20) " h" (a_guiHeight - 65)
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
    comObjError(false)
    request := comObjCreate("WinHttp.WinHttpRequest.5.1")
    request.open("GET", url)
    request.send()
    while (request.responseText = "") and (a_index <= 5)
        sleep 200
    return request.responseText
}


check_live_following() {
    global a, live, live_total, selected_view
    static previous_broadcasts

    loop, % live_total
        {
        this_broadcaster := live.data[a_index].post.authorInfo.name
        if (in_obj(a.following, this_broadcaster)) ; if following this broadcaster
            live_following .= (live_following ? ", " : "") . this_broadcaster
        else continue ; if not following

        this_url := live.data[a_index].post.outboundLink.url
        broadcasts .= this_url "`n"
        if !inStr(previous_broadcasts, this_url) ; if not in previous list
            new_broadcast .= (new_broadcast ? ", " : "") . this_broadcaster
        }
    previous_broadcasts := broadcasts

    if (new_broadcast) and (a.show_notifications = true)
        trayTip, new rpan broadcast!, % new_broadcast, 8

    return live_following
}


in_obj(haystack, needle) {
    for index in haystack
        if (index = needle)
            return index
    return 0
}


update_listView(selected_view) {
    global a, live, live_total
    guiControl, -redraw, list_view
    lv_delete()

    loop, % live_total
        {
        broadcaster := live.data[a_index].post.authorInfo.name
        if (selected_view = "&following") and (in_obj(a.following, broadcaster) = false)
            continue ; if not following

        title       := live.data[a_index].post.title
        channel     := live.data[a_index].post.subreddit.name
        global_rank := live.data[a_index].global_rank
        sub_rank    := live.data[a_index].rank_in_subreddit
        url         := live.data[a_index].post.outboundLink.url
        start_time  := subStr(live.data[a_index].post.createdAt, 1, 19) ; remove +00:00 from timestamp
        if (broadcaster)
            lv_add("", broadcaster, title, channel, global_rank, start_time, url)
        }

    lv_modifyCol(4, "sort")  ; sort by rank
    guiControl, +redraw, list_view
}