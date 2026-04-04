@echo off
setlocal
set "JAVA_HOME=C:\Program Files\Microsoft\jdk-21.0.10.7-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"
firebase emulators:start --only firestore,functions --config firebase.phase4.json > emulator.phase4.log 2> emulator.phase4.err
