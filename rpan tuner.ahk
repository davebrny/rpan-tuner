/*
[script_info]
version     = 2.7.1
description = keep up to date with your favourite rpan broadcasters
author      = davebrny
source      = https://github.com/davebrny/rpan-tuner
*/

#singleInstance, force
sendMode, input
setWorkingDir, % a_scriptDir
onExit, gui_exit

hotkey, ifWinActive, rpan tuner  ; set hotkeys
hotkey, ^r, update_broadcasts
hotkey, enter, menu_broadcaster_open
hotkey, m, show_main_menu
hotkey, l, show_live_menu
hotkey, t, toggle_on_top

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
if (a.gui_size.maxIndex())    ; set x, y, width and heigth
    winMove, % "ahk_id " gui_id, , % a.gui_size.1, % a.gui_size.2, % a.gui_size.3, % a.gui_size.4
if (a.always_on_top = true)
    winSet, alwaysOnTop, on, % "ahk_id " gui_id

selected_view := "&live"
goSub, update_broadcasts
return



update_broadcasts:
if (updating != true)
    {
    updating := true
    sb_setText("tuning...", 1)

    json_data := download_json()
    if (json_data)
        {
        live := JSON.Load(json_data)
        live_total := (live.data[1].total_streams - 1)
        check_live_following()
        update_listView(selected_view)
        sb_setText(live_total " live", 1)
        sb_setText(" " live_following_string(), 2)
        }
    else
        {
        sb_setText("off-air", 1)
        sb_setText("the snoos are sleeping. try again later", 2)
        }

    json_data := ""
    last_update := a_now
    updating := false
    }
return



show_main_menu:
loop, % live_total
    live_string .= "|" live.data[a_index].post.authorInfo.name "|"

menu, following_menu, add, follow new broadcaster, follow_new_broadcaster
menu, following_menu, add
for broadcaster in a.following
    {
    menu, following_menu, add, % broadcaster, follow_new_broadcaster
    broadcaster_submenu(broadcaster)
    if (a.following[broadcaster].show_notifications = true)  ; add checkbox
        menu, following_menu, check, % broadcaster
    menu, following_menu, add, % broadcaster, % ":" broadcaster "_menu"
    }

menu, view_menu, add, &live, select_view
menu, view_menu, % (selected_view = "&live" ? "check" : "unCheck"), &live
menu, view_menu, add, &following (live), select_view
menu, view_menu, % (selected_view = "&following (live)" ? "check" : "unCheck"), &following (live)

menu, window_menu, add, &always-on-top, toggle_on_top
menu, window_menu, % (a.always_on_top = true ? "check" : "unCheck"), &always-on-top
menu, window_menu, add ; separator
menu, window_menu, add, resize to:, resize_window
menu, window_menu, disable, resize to:
menu, window_menu, add
menu, window_menu, add, default, resize_window
menu, window_menu, add, mini   , resize_window

menu, settings_menu, add, show notifications, toggle_settings
menu, settings_menu, % (a.show_notifications = true ? "check" : "unCheck"), show notifications
menu, settings_menu, add, &always-on-top, toggle_on_top
menu, settings_menu, % (a.always_on_top = true ? "check" : "unCheck"), &always-on-top
menu, settings_menu, add, run at startup, run_at_startup
menu, settings_menu, % (fileExist(a_startup "\" a_scriptName ".lnk") ? "check" : "unCheck"), run at startup
menu, settings_menu, add, &reload rpan tuner, reload_tuner

ahk_script := a_scriptDir "\" subStr(a_scriptName, 1, strLen(a_scriptName) - 4) ".ahk"
if fileExist(ahk_script)
    {
    iniRead, version, % ahk_script, script_info, version
    menu, help_menu, add, % t := "rpan tuner: version " version, github_page
    menu, help_menu, disable, % t
    menu, help_menu, add
    }
menu, help_menu, add, github page, github_page

if (lv_getNext(0))  ; if a row is selected
    {
    lv_getText(row_broadcaster, lv_getNext(0), 1)  ; get name
    broadcaster_submenu(row_broadcaster)
    menu, main_menu, add, % row_broadcaster, % ":" row_broadcaster "_menu"
    menu, main_menu, add,  
    }

sec := a_now
sec -= last_update, seconds  ; get seconds elapsed since last update
time_elapsed := (floor(sec/60) < 1 ? "" : floor(sec/60) "m ") . mod(sec, 60) "s"  ; format to 1m 23s
menu, main_menu, add, &update broadcasts (updated %time_elapsed% ago), update_broadcasts
menu, main_menu, add  ; separator
menu, main_menu, add, &following, :following_menu
menu, main_menu, add, &view, :view_menu
menu, main_menu, add, &window, :window_menu
menu, main_menu, add, &settings, :settings_menu
menu, main_menu, add
menu, main_menu, add, help, :help_menu

menu, main_menu, show
loop, parse, % "main|following|view|window|settings|help", |
    menu, % a_loopField "_menu", deleteAll
return



broadcaster_submenu(broadcaster) {
    global a, live_string
    menu_name := broadcaster "_menu"
    try menu, % menu_name, deleteAll

    if inStr(live_string, "|" broadcaster "|")  ; if live
        menu, % menu_name, add, % "open broadcast", open_live_broadcast
    menu, % menu_name, add, % "open profile", open_profile
    
    if (a.following.hasKey(broadcaster))
        menu, % menu_name, add, notifcations, toggle_notifications

    if (a.following[broadcaster].show_notifications = "")
        a.following[broadcaster].show_notifications := true  ; initialise if key hasnt been created
    if (a.following[broadcaster].show_notifications = true)  ; if following
    and (a.following.hasKey(broadcaster))                    ; and already added
        menu, % menu_name, check, notifcations

    menu, % menu_name, add
    if (a.following.hasKey(broadcaster))
         menu, % menu_name, add, % "unfollow", menu_broadcaster_follow
    else menu, % menu_name, add, % "follow"  , menu_broadcaster_follow
}


menu_broadcaster_open:  ; (enter key)
if (lv_getNext(0))  ; if a row is selected
    {
    lv_getText(listview_url, lv_getNext(0), 6)  ; get url
    run, % listview_url
    }
return


menu_broadcaster_follow:
broadcaster := strReplace(a_thisMenu, "_menu", "")
if (a_thisMenuItem = "unfollow")
    {
    a.following.delete(broadcaster)  ; remove key
    update_listView(selected_view)   ; refresh listView
    }
else
    {
    lv_modify(lv_getNext(1), "check")
    a.following[broadcaster] := {}    ; add key
    lv_getText(listview_url, lv_getNext(0), 6)
    if !inStr(previous_broadcasts, listview_url)
        previous_broadcasts .= listview_url "`n"
    }
sb_setText(" " live_following_string(), 2)
save_json(a, "settings.json")
return



follow_new_broadcaster:
inputBox, input, follow new broadcaster, add names separated by a comma, , 240, 122
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


toggle_on_top:
winSet, alwaysOnTop, toggle, % "ahk_id " gui_id
winGet, ex_style, exStyle, % "ahk_id " gui_id
if (ex_style & 0x8)    ; 0x8 is WS_EX_TOPMOST
     a.always_on_top := true
else a.always_on_top := false
return


resize_window:
if (a_thisMenuItem = "default")
    winMove, % "ahk_id " gui_id, , , , 700, 350
else if (a_thisMenuItem = "mini")
    winMove, % "ahk_id " gui_id, , , , 480, 71
return


toggle_settings:
menu_item := strReplace(a_thisMenuItem, " ", "_")
a[menu_item] := (a[menu_item] = 1 ? 0 : 1)
return


toggle_notifications:
menu_item := strReplace(a_thisMenu, "_menu", "")
a.following[menu_item].show_notifications := (a.following[menu_item].show_notifications = 1 ? 0 : 1)
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
        if (selected_view = "&following (live)")
            update_listView(selected_view) ; refresh listView
        }
    sb_setText(" " live_following_string(), 2)
    save_json(a, "settings.json")
    }
return


guiContextMenu:
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
if (live_total = "")
    return

menu, live_menu, add, live broadcasts:, open_live_broadcast
menu, live_menu, disable, live broadcasts:
menu, live_menu, add ; separator

loop, % live_total
    {
    this_broadcaster := live.data[a_index].post.authorInfo.name
    if (a.following.hasKey(this_broadcaster))  ; if following
        menu, live_menu, add, % this_broadcaster, open_live_broadcast
    }

channel_list := ""
loop, % live_total
    {
    this_broadcaster := live.data[a_index].post.authorInfo.name
    this_channel     := live.data[a_index].post.subreddit.name
    if (this_broadcaster = "") or (this_channel = "")
        continue
    menu, all_menu, add, % this_broadcaster, open_live_broadcast
    menu, % this_channel, add, % this_broadcaster, open_live_broadcast
    ++%this_channel%_count
    if !inStr(channel_list, this_channel)  ; if not already in list
        channel_list .= (channel_list ? "|" : "") . this_channel
    }

if (live_following_string())
    menu, live_menu, add, ; separator

menu, live_menu, add, % "&all " a_tab "(" live_total ")", :all_menu
menu, live_menu, add
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



open_live_broadcast:
loop, % live_total
    {
    if (live.data[a_index].post.authorInfo.name = a_thisMenuItem)
        {
        run, % live.data[a_index].post.outboundLink.url  ; open url
        break
        }
    }
return


open_profile:
run, % "https://www.reddit.com/user/" . strReplace(a_thisMenu, "_menu", "")
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


download_json() {
    loop,
        {
        response := download("https://strapi.reddit.com/broadcasts")
        if (inStr(response, "success"))
            return response
        sleep 200
        }
    until (a_index >= 20)
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

        if (a.following[this_broadcaster].show_notifications = "")
            a.following[this_broadcaster].show_notifications := true   ; initialise if key hasnt been created

        this_url := live.data[a_index].post.outboundLink.url
        if !inStr(previous_broadcasts, this_url)                       ; if not in previous list
        and (a.following[this_broadcaster].show_notifications = true)  ; if notifications enabled for broadcaster
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
        else if (selected_view = "&following (live)") ; and not following
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


run_at_startup:
if fileExist(a_startup "\" a_scriptName ".lnk")
     fileDelete, % a_startup "\" a_scriptName ".lnk"
else fileCreateShortcut, % a_scriptFullPath, % a_startup "\" a_scriptName ".lnk"
return