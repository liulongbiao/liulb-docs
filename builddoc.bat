@echo off

multimarkdown --version >NUL 2>&1 || ( echo multimarkdown not found. Please install multimarkdown or check PATH variable! & pause & exit )

echo do translating ...
for /f "delims=" %%i in ('dir /b /a-d /s "*.md"') do multimarkdown -b %%i
echo translate multimarkdown file to html has finished 