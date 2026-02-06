# startup_check.ps1 - Проверка автозагрузки только для реальных пользователей

# Пропускаем системные и служебные учетные записи
if ($env:USERNAME -like "*$" -or $env:USERNAME -eq "SYSTEM" -or $env:USERNAME -eq "LOCAL SERVICE" -or $env:USERNAME -eq "NETWORK SERVICE") {
    Write-Host "Пропускаем системный запуск (пользователь: $env:USERNAME)" -ForegroundColor Yellow
    exit 0
}

Write-Host "=== Проверка автозагрузки пользователя: $env:USERNAME ===" -ForegroundColor Cyan
Write-Host "Время запуска: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor White

# Лог-файл
$logFile = "C:\Scripts\startup_user_log.txt"
"=== $(Get-Date) - Проверка для пользователя: $env:USERNAME ===" | Out-File -FilePath $logFile -Append

# Путь к автозагрузке текущего пользователя
$userStartupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
Write-Host "`nПроверяем папку автозагрузки:" -ForegroundColor Yellow
Write-Host "Путь: $userStartupPath" -ForegroundColor Gray

if (Test-Path $userStartupPath) {
    $files = Get-ChildItem -Path $userStartupPath -File
    Write-Host "Найдено файлов: $($files.Count)" -ForegroundColor White
    "Найдено файлов: $($files.Count)" | Out-File -FilePath $logFile -Append
    
    if ($files.Count -gt 0) {
        foreach ($file in $files) {
            Write-Host "`n $($file.Name)" -ForegroundColor Cyan
            
            # Обработка ярлыков
            if ($file.Extension -eq '.lnk') {
                try {
                    $shell = New-Object -ComObject WScript.Shell
                    $shortcut = $shell.CreateShortcut($file.FullName)
                    $targetPath = $shortcut.TargetPath
                    
                    if ($targetPath) {
                        Write-Host "  Путь: $targetPath" -ForegroundColor Gray
                        
                        if (Test-Path $targetPath) {
                            $processName = [System.IO.Path]::GetFileNameWithoutExtension($targetPath)
                            
                            # Проверяем, запущен ли процесс
                            $isRunning = Get-Process -Name $processName -ErrorAction SilentlyContinue
                            
                            if ($isRunning) {
                                Write-Host "  Статус:  Уже запущено" -ForegroundColor Green
                                "$($file.Name) - Уже запущено" | Out-File -FilePath $logFile -Append
                            } else {
                                Write-Host "  Статус:  Не запущено" -ForegroundColor Red
                                "$($file.Name) - Не запущено. Пытаюсь запустить..." | Out-File -FilePath $logFile -Append
                                
                                # Пытаемся запустить с правами администратора
                                try {
                                    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                                    $processInfo.FileName = $targetPath
                                    $processInfo.Verb = "runas"
                                    $processInfo.UseShellExecute = $true
                                    $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
                                    
                                    $process = New-Object System.Diagnostics.Process
                                    $process.StartInfo = $processInfo
                                    
                                    if ($process.Start()) {
                                        Write-Host "  Результат:  Запущено от администратора" -ForegroundColor Green
                                        "$($file.Name) - Успешно запущено" | Out-File -FilePath $logFile -Append
                                        Start-Sleep -Seconds 2  # Даем время запуститься
                                    }
                                }
                                catch {
                                    # Пробуем обычный запуск
                                    try {
                                        Write-Host "  Пробуем обычный запуск..." -ForegroundColor Yellow
                                        Start-Process -FilePath $targetPath -WindowStyle Normal -ErrorAction Stop
                                        Write-Host "  Результат:  Запущено обычным способом" -ForegroundColor Green
                                        "$($file.Name) - Запущено обычным способом" | Out-File -FilePath $logFile -Append
                                        Start-Sleep -Seconds 2
                                    }
                                    catch {
                                        Write-Host "  Результат:  Не удалось запустить" -ForegroundColor Red
                                        "$($file.Name) - Ошибка запуска: $_" | Out-File -FilePath $logFile -Append
                                    }
                                }
                            }
                        } else {
                            Write-Host "  Ошибка: Файл не найден" -ForegroundColor Red
                            "$($file.Name) - Целевой файл не найден" | Out-File -FilePath $logFile -Append
                        }
                    }
                }
                catch {
                    Write-Host "  Ошибка: Не удалось прочитать ярлык" -ForegroundColor Red
                    "$($file.Name) - Ошибка чтения ярлыка" | Out-File -FilePath $logFile -Append
                }
            }
        }
    } else {
        Write-Host "В папке автозагрузки нет файлов" -ForegroundColor Yellow
        "Нет файлов в автозагрузке" | Out-File -FilePath $logFile -Append
    }
} else {
    Write-Host "Папка автозагрузки не найдена!" -ForegroundColor Red
    "Папка автозагрузки не найдена: $userStartupPath" | Out-File -FilePath $logFile -Append
}

Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "Проверка завершена!" -ForegroundColor Green
Write-Host "Логи сохранены в: $logFile" -ForegroundColor White
"=== Проверка завершена: $(Get-Date) ===" | Out-File -FilePath $logFile -Append

# Закрываем окно через 15 секунд
Write-Host "`nОкно закроется через 15 секунд..." -ForegroundColor Gray
Start-Sleep -Seconds 15
