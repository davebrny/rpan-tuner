> autohotkey script to keep up to date with your favourite rpan broadcasters   

<a href="url"><img src="https://i.imgur.com/2B9Fw5g.png"></a><br></br>  

## installation  
- install [AutoHotkey](https://www.autohotkey.com)  
- download and extract the [zip](https://github.com/davebrny/rpan-tuner/archive/master.zip) file  
- run "rpan tuner.ahk"  

**rpan tuner.exe?**   
if you already have autohotkey installed then run "rpan tuner.ahk".  
the .exe is the compiled/self-contained version of the .ahk script that will run without having to install autohotkey first.   
&nbsp;


## usage  

- double click on a broadcast in the list to open it in your browser  
- click the checkbox beside a broadcasters name to get desktop notifications for them  
    + to follow a broadcaster that isnt currently live, select "following/follow new" in the main menu 
- use  <kbd>ctrl</kbd> + <kbd>r</kbd> to manually update broadcasts. (it updates every 2 minutes by default)  
&nbsp;


**menus**  
- right click (anywhere) to access the main menu  
- left click (on the status bar) to access the live menu  

both menus can be shown by pressing the M or L key.  
the first or underlined letter in each item can be used to select it. (e.g. press M then W then A to toggle the always-on-top option)  
&nbsp;


**views**  
you can choose between "live", "following" and "following (live only)". 
"following" shows live broadcasts for the people you are following but also off-air broadcasts if you choose to download them.  

> it takes a second to download each broadcaster's post history so its turned off by default. to enable it, open the "following" sub-menu and select "download off-air broadcasts" for each broadcaster you want  
&nbsp;


**mini mode**  
\- resize the window by selecting "window / mini" in the main menu  
\- turn on always-on-top  
\- left click on the status bar to view live broadcasts  

<a href="url"><img src="https://i.imgur.com/LOtyYYr.png"></a>
&nbsp;


## settings  

**notifications**  
when you follow a broadcaster, notifications are enabled for them by default. if you only want to follow someone without getting notifications then untick the option in the "following" sub-menu.  
to turn off notifications completely, select the option in the "settings" sub-menu  


**update_frequency**  
this needs to be changed in the settings.json file for now, just remember to reload the script after making any changes there.   
set to 0 to turn off checking for new broadcasts. the lowest it can be set to is 1 second  