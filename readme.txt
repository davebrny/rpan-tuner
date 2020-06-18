autohotkey script to keep up to date with your favourite rpan broadcasters

- click the > menu button at the top to add new broadasters, then select "check for new broadcasts"  
- use ctrl + r to manually check for new broadcasts (it checks every 4 minutes by default)  
- double click on a broadcast in the list to open it in your browser  

the following settings have to be changed in the ini file for now. just remember to reload the script after making any changes there.

- set "update_every" to 0 turn off checking for new broadcasts  
- set "show_notifications" to "no" to turn off the tray notifications  

.ahk or .exe? 
if you already have autohotkey installed then run "rpan tuner.ahk".
(autohotkey can be downloaded here: https://www.autohotkey.com)  
the .exe is the compiled/self-contained version of the .ahk script that will run without having to install autohotkey first.  


TODO:  
- colour the posts that are live instead of using the status bar  
- add a settings window  
- choose which broadcasters you want notifications for  
- resize window and remember position  