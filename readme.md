> autohotkey script to keep up to date with your favourite rpan broadcasters   

<a href="url"><img src="https://i.imgur.com/CTYsnhv.png"></a><br></br>  

## installation  
- install [AutoHotkey](https://www.autohotkey.com)  
- download and extract the [zip](https://github.com/davebrny/rpan-tuner/archive/master.zip) file  
- run "rpan tuner.ahk"  

**.ahk or .exe?**   
if you already have autohotkey installed then run "rpan tuner.ahk".  
the .exe is the compiled/self-contained version of the .ahk script that will run without having to install autohotkey first.   
&nbsp;

## usage  

- click the > menu button at the top to add new broadcasters, then select "check for new broadcasts"  
- use ctrl + r to manually check for new broadcasts (it checks every 4 minutes by default)  
- double click on a broadcast in the list to open it in your browser  
&nbsp;

## settings  

> the following settings have to be changed in the .ini file for now. just remember to reload the script after making any changes there.  

- set "update_every" to 0 turn off checking for new broadcasts  
- set "show_notifications" to "no" to turn off the tray notifications  

&nbsp;  

TODO:  
- colour the posts that are live instead of using the status bar  
- add a settings window  
- choose which broadcasters you want notifications for  
- resize window and remember position  