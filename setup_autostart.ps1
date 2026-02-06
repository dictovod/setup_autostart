# setup_autostart.ps1 - установщик системы автозапуска

Write-Host "=== Установка системы автозапуска приложений ===" -ForegroundColor Cyan

# 1. Создание папки
$scriptDir = "C:\Scripts"
if (-not (Test-Path $scriptDir)) {
    New-Item -ItemType Directory -Path $scriptDir -Force
    Write-Host "Создана папка: $scriptDir" -ForegroundColor Green
}

# 2. Копирование основного скрипта (предполагается, что startup_check.ps1 в той же папке)
$sourceScript = Join-Path $PSScriptRoot "startup_check.ps1"
$destScript = Join-Path $scriptDir "startup_check.ps1"

if (Test-Path $sourceScript) {
    Copy-Item -Path $sourceScript -Destination $destScript -Force
    Write-Host "Скопирован скрипт автозапуска" -ForegroundColor Green
} else {
    Write-Host "ВНИМАНИЕ: startup_check.ps1 не найден рядом с установщиком!" -ForegroundColor Red
}

# 3. Создание задачи в планировщике
Write-Host "`nСоздание задачи в планировщике..." -ForegroundColor Yellow
$taskName = "StartupAppsLauncher"

# Удаляем старую задачу, если есть
schtasks /delete /tn $taskName /f 2>$null

# Создаем новую задачу
$createTask = @"
schtasks /create /tn $taskName /tr 'powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "$destScript"' /sc onlogon /delay 0000:30 /ru "%USERDOMAIN%\%USERNAME%" /rl highest /f
"@

cmd /c $createTask

if ($LASTEXITCODE -eq 0) {
    Write-Host "Задача успешно создана!" -ForegroundColor Green
} else {
    Write-Host "Ошибка при создании задачи" -ForegroundColor Red
}

# 4. Проверка
Write-Host "`n=== ПРОВЕРКА ===" -ForegroundColor Cyan
Write-Host "1. Скрипт: $destScript" -ForegroundColor White
Write-Host "2. Задача: $taskName" -ForegroundColor White
Write-Host "3. Логи: C:\Scripts\startup_user_log.txt" -ForegroundColor White
Write-Host "`nДобавьте ярлыки приложений в папку автозагрузки:" -ForegroundColor Yellow
Write-Host "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" -ForegroundColor White

Write-Host "`nНастройка завершена!" -ForegroundColor Green
pause
