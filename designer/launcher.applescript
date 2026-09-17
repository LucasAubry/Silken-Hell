on run
    set bundlePath to POSIX path of (path to me)
    if bundlePath ends with "/" then set bundlePath to text 1 thru -2 of bundlePath
    set projectPath to do shell script "/usr/bin/dirname " & quoted form of bundlePath
    set launcherPath to projectPath & "/Lancer le concepteur.command"
    set logPath to (POSIX path of (path to library folder from user domain)) & "Logs/Silken-Hell-Concepteur.log"
    do shell script "/bin/zsh " & quoted form of launcherPath & " > " & quoted form of logPath & " 2>&1 &"
end run
