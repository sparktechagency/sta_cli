# STA CLI Windows Installer
Write-Host "Installing STA CLI..." -ForegroundColor Cyan

dart pub get
dart compile exe bin/main.dart -o sta.exe

$installDir = "$env:USERPROFILE\.pub-cache\bin"
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Move-Item -Force .\sta.exe "$installDir\sta.exe"

Write-Host "Installed to $installDir\sta.exe" -ForegroundColor Green
Write-Host "Make sure $installDir is in your PATH" -ForegroundColor Yellow
Write-Host ""
Write-Host "Done! Try: sta --help" -ForegroundColor Cyan
