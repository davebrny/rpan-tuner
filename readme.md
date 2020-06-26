> autohotkey script to keep up to date with your favourite rpan broadcasters   

<a href="url"><img src="https://i.imgur.com/Dtimf7V.png"></a><br></br>  

## installation  
- install [AutoHotkey](https://www.autohotkey.com)  
- download and extract the [zip](https://github.com/davebrny/rpan-tuner/archive/master.zip) file  
- run "rpan tuner.ahk"  

**rpan tuner.exe?**   
if you already have autohotkey installed then run "rpan tuner.ahk".  
the .exe is the compiled/self-contained version of the .ahk script that will run without having to install autohotkey first.   
&nbsp;

## usage  

- click the > menu button at the top to add new broadcasters, then select "check for new broadcasts"  
- use ctrl + r to manually check for new broadcasts (it checks every 4 minutes by default)  
- double click on a broadcast in the list to open it in your browser  
    + or click on the status bar at the bottom to show a menu of live broadcasts  

> both menus can be shown by pressing the M or L key  

&nbsp;

## settings  

> the following settings have to be changed in the .json file for now. just remember to reload the script after making any changes there.  

- set "update_frequency" to 0 turn off checking for new broadcasts  
- set "show_notifications" to "no" to turn off the tray notifications  

&nbsp;  

TODO:   
- add a settings window  
- choose which broadcasters you want notifications for  