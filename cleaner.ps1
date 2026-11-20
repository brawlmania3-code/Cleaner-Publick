# ============================================================
#  CLEANER 2.0 (Public Edition)
#  Автор: ты :)
#
#  ⚠️ ДИСКЛЕЙМЕР (для читающих код):
#  Этот скрипт перемещает файлы в корзину (%TEMP%\CleanerTrash).
#  Не используйте на рабочих компьютерах без согласования с ИТ-отделом.
#  Тестируйте на тестовых файлах.
#  Ответственность за использование лежит на пользователе.
# ============================================================

# --- Экранное предупреждение при запуске (видно пользователю) ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Red
Write-Host "  CLEANER 2.0 — PUBLIC EDITION" -ForegroundColor Cyan
Write-Host "  ⚠️ ОПАСНО: Скрипт перемещает файлы!" -ForegroundColor Red
Write-Host "  Используйте только на личных данных." -ForegroundColor Yellow
Write-Host "  Тестируйте сначала на тестовой папке!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Red
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$codeFile = Join-Path -Path $scriptPath -ChildPath "cleaner_code.txt"
$trashFolder = Join-Path -Path $env:TEMP -ChildPath "CleanerTrash"

# Создаём корзину в TEMP (не будет мешать синхронизации OneDrive)
if (-not (Test-Path $trashFolder)) {
    try { New-Item -ItemType Directory -Force -Path $trashFolder | Out-Null } catch { }
}

# Утилиты
function Write-Color([string]$Text, [string]$Color) {
    Write-Host $Text -ForegroundColor $Color
}

function FSize([long]$b) {
    if ($b -ge 1GB) { return "$([math]::Round($b/1GB,2)) GB" }
    if ($b -ge 1MB) { return "$([math]::Round($b/1MB,1)) MB" }
    return "$([math]::Round($b/1KB,0)) KB"
}

function MoveToTrash([string]$SourcePath) {
    $name = Split-Path $SourcePath -Leaf
    $dest = Join-Path -Path $trashFolder -ChildPath $name
    
    # Если файл с таким именем уже есть в корзине — добавим случайное число, чтобы не перезаписать
    if (Test-Path $dest) {
        $ext = [System.IO.Path]::GetExtension($name)
        $base = [System.IO.Path]::GetFileNameWithoutExtension($name)
        $dest = Join-Path -Path $trashFolder -ChildPath "$base_$(Get-Random)$ext"
    }
    
    try {
        Move-Item -LiteralPath $SourcePath -Destination $dest -Force
        return $true
    } catch {
        Write-Color "Ошибка перемещения: $SourcePath" "Red"
        return $false
    }
}

# Настройка пароля (запрашивается только при первом запуске)
if (Test-Path $codeFile) {
    $adminCode = (Get-Content -LiteralPath $codeFile -Raw).Trim()
} else {
    Clear-Host
    Write-Color "ПЕРВЫЙ ЗАПУСК: Настройка доступа" "Cyan"
    Write-Color "Файл cleaner_code.txt будет создан рядом со скриптом." "Gray"
    Write-Color "Не загружайте этот файл в интернет!" "Red"
    $adminCode = Read-Host " Придумайте и введите код доступа (цифры, например 1234)"
    if ([string]::IsNullOrWhiteSpace($adminCode)) { $adminCode = "0000" }
    Set-Content -LiteralPath $codeFile -Value $adminCode -Encoding UTF8
    Write-Color "Код сохранён." "Green"
    Start-Sleep -Seconds 2
}

# Проверка пароля перед входом в меню
$ok = $false
for ($i = 3; $i -gt 0; $i--) {
    Clear-Host
    $c = Read-Host " Введите код доступа ($i попыток)"
    if ($c -eq $adminCode) { $ok = $true; break }
    Write-Color " Неверный код." "Red"
    Start-Sleep -Seconds 1
}
if (-not $ok) { 
    Write-Color " Слишком много ошибок. Выход." "Yellow"
    Start-Sleep -Seconds 2 
    exit 
}

# Главное меню (10 пунктов + корзина)
while ($true) {
    Clear-Host
    Write-Color "================= ГЛАВНОЕ МЕНЮ CLEANER =================" "Cyan"
    Write-Color " Корзина: $trashFolder" "DarkGray"
    Write-Host ""
    
    Write-Host "    [1] Очистить Temp (переместить в корзину с подтверждением)" -ForegroundColor White
    Write-Host "    [2] Старые большие файлы в Загрузках (фильтр по размеру/типу)" -ForegroundColor White
    Write-Host "    [3] Топ-50 самых больших файлов (предпросмотр, без удаления)" -ForegroundColor White
    Write-Host "    [4] Поиск дубликатов в Загрузках (по хешу)" -ForegroundColor White
    Write-Host "    [5] Файлы старше 90 дней в Загрузках" -ForegroundColor White
    Write-Host "    [6] Пути кэша браузеров (только показать, не чистить)" -ForegroundColor White
    Write-Host "    [7] Отчёт по типам файлов в Загрузках" -ForegroundColor White
    Write-Host "    [8] Монитор системы (CPU, RAM)" -ForegroundColor White
    Write-Host "    [9] Свободное место на дисках" -ForegroundColor White
    Write-Host "    [A] Показать содержимое корзины" -ForegroundColor Cyan
    Write-Host "    [B] Восстановить файл из корзины" -ForegroundColor Cyan
    Write-Host "    [C] Удалить ВСЁ из корзины НАВСЕГДА" -ForegroundColor Red
    Write-Host "    [0] Выход" -ForegroundColor White
    Write-Host ""

    $ch = Read-Host " Выберите пункт (0-9, A, B, C)"

    switch ($ch) {
        '1' {
            Clear-Host; Write-Color "Очистка Temp — в корзину." "Cyan"
            $confirm = Read-Host " Подтвердить перемещение файлов из TEMP? Y/N"
            if (-not ($confirm -match '^[Yy]')) { Write-Color "Отменено." "Yellow"; pause; continue }
            
            $count = 0
            Get-ChildItem -LiteralPath $env:TEMP -Force -ErrorAction SilentlyContinue | ForEach-Object {
                if (MoveToTrash $_.FullName) { $count++ }
            }
            Write-Color "Перемещено в корзину: $count файлов." "Green"
            pause
        }

        '2' {
            Clear-Host; Write-Color "Поиск старых больших файлов в Загрузках." "Cyan"
            $dl = Join-Path -Path $env:USERPROFILE -ChildPath "Downloads"
            if (-not (Test-Path $dl)) { Write-Color "Папка Загрузки не найдена." "Red"; pause; continue }
            
            $sizeMin = Read-Host " Минимальный размер в МБ (например 50, можно пусто):"
            $extFilter = Read-Host " Фильтр по расширению (например .mp4, можно пусто):"
            $cutoff = (Get-Date).AddDays(-30)
            $minBytes = 0
            if ($sizeMin -match '^\d+$') { $minBytes = [int]$sizeMin * 1MB }

            $files = Get-ChildItem -LiteralPath $dl -File -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Length -ge $minBytes -and $_.LastWriteTime -lt $cutoff }
            if ($extFilter) { $files = $files | Where-Object { $_.Extension -eq $extFilter } }

            if (-not $files -or $files.Count -eq 0) {
                Write-Color "Файлы по этим критериям не найдены." "Gray"
            } else {
                Write-Color "Найдено файлов: $($files.Count)" "Yellow"
                $confirm = Read-Host " Переместить их в корзину? Y/N"
                if ($confirm -match '^[Yy]') {
                    $count = 0
                    foreach ($f in $files) { if (MoveToTrash $f.FullName) { $count++ } }
                    Write-Color "Перемещено: $count" "Green"
                }
            }
            pause
        }

        '3' {
            Clear-Host; Write-Color "Топ-50 самых больших файлов (только предпросмотр)." "Cyan"
            $path = Read-Host " Путь к папке (пусто = Загрузки):"
            if ([string]::IsNullOrWhiteSpace($path)) { $path = Join-Path -Path $env:USERPROFILE -ChildPath "Downloads" }
            if (-not (Test-Path $path)) { Write-Color "Путь не найден." "Red"; pause; continue }
            $extFilter = Read-Host " Фильтр по расширению (например .jpg, можно пусто):"

            $files = Get-ChildItem -LiteralPath $path -File -Force -ErrorAction SilentlyContinue
            if ($extFilter) { $files = $files | Where-Object { $_.Extension -eq $extFilter } }
            $top = $files | Sort-Object Length -Descending | Select-Object -First 50

            Write-Color "Топ-50 файлов:" "White"
            foreach ($f in $top) {
                Write-Host "  $($f.Name) — $(FSize $f.Length) — $($f.LastWriteTime.ToString('yyyy-MM-dd'))"
            }
            Write-Color "Это только предпросмотр — файлы не удаляются." "Gray"
            pause
        }

        '4' {
            Clear-Host; Write-Color "Дубликаты в Загрузках — по хешу." "Cyan"
            $dl = Join-Path -Path $env:USERPROFILE -ChildPath "Downloads"
            if (-not (Test-Path $dl)) { Write-Color "Папка не найдена." "Red"; pause; continue }
            Write-Color "Считаем хеши (может занять время)..." "Gray"
            
            $files = Get-ChildItem -LiteralPath $dl -File -Force -ErrorAction SilentlyContinue
            $hashes = @{}
            $duplicates = @()
            
            foreach ($f in $files) {
                $h = Get-FileHash -LiteralPath $f.FullName -Algorithm MD5 -ErrorAction SilentlyContinue
                if ($null -eq $h) { continue }
                $hash = $h.Hash
                if ($hashes.ContainsKey($hash)) {
                    $duplicates += $f
                } else {
                    $hashes[$hash] = $f
                }
            }
            
            if ($duplicates.Count -eq 0) {
                Write-Color "Дубликатов не найдено." "Gray"
            } else {
                Write-Color "Найдено дубликатов: $($duplicates.Count)" "Yellow"
                foreach ($d in $duplicates) { Write-Host "  - $($d.Name) — $(FSize $d.Length)" }
                $confirm = Read-Host " Переместить дубликаты в корзину? Y/N"
                if ($confirm -match '^[Yy]') {
                    $count = 0
                    foreach ($d in $duplicates) { if (MoveToTrash $d.FullName) { $count++ } }
                    Write-Color "Перемещено дубликатов: $count" "Green"
                }
            }
            pause
        }

        '5' {
            Clear-Host; Write-Color "Старые файлы в Загрузках (90+ дней)." "Cyan"
            $dl = Join-Path -Path $env:USERPROFILE -ChildPath "Downloads"
            if (-not (Test-Path $dl)) { Write-Color "Папка не найдена." "Red"; pause; continue }
            $confirm = Read-Host " Подтвердить? Y/N"
            if (-not ($confirm -match '^[Yy]')) { Write-Color "Отменено." "Yellow"; pause; continue }
            
            $cutoff = (Get-Date).AddDays(-90)
            $count = 0
            Get-ChildItem -LiteralPath $dl -File -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -lt $cutoff } |
                ForEach-Object { if (MoveToTrash $_.FullName) { $count++ } }
            Write-Color "Перемещено старых файлов: $count" "Green"
            pause
        }

        '6' {
            Clear-Host; Write-Color "Пути кэша браузеров (только показ)." "Cyan"
            $paths = @(
                (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Cache"),
                (Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Default\Cache"),
                (Join-Path $env:LOCALAPPDATA "Mozilla\Firefox\Profiles")
            )
            foreach ($p in $paths) {
                if (Test-Path $p) { Write-Host "  НАЙДЕНО: $p" -ForegroundColor Green }
                else { Write-Host "  не найдено: $p" -ForegroundColor Gray }
            }
            Write-Color "Автоочистка кэша браузеров отключена — очищайте кэш в настройках браузера." "Yellow"
            pause
        }

        '7' {
            Clear-Host; Write-Color "Отчёт по типам файлов (в Загрузках)." "Cyan"
            $dl = Join-Path -Path $env:USERPROFILE -ChildPath "Downloads"
            if (-not (Test-Path $dl)) { Write-Color "Папка не найдена." "Red"; pause; continue }
            
            $report = Get-ChildItem -LiteralPath $dl -File -Force -ErrorAction SilentlyContinue |
                Group-Object -Property Extension | Sort-Object Count -Descending
            
            foreach ($r in $report) {
                $sum = ($r.Group | Measure-Object -Property Length -Sum).Sum
                Write-Host "  $($r.Name) : $($r.Count) файлов — $(FSize $sum)"
            }
            pause
        }

        '8' {
            Clear-Host; Write-Color "Монитор системы (CPU/RAM)." "Cyan"
            try {
                $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
                $mem = Get-CimInstance Win32_OperatingSystem
                $usedMem = ($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / 1MB
                $totalMem = $mem.TotalVisibleMemorySize / 1MB
                
                Write-Host "  CPU загрузка: $([math]::Round($cpu,1))%" -ForegroundColor Yellow
                Write-Host "  RAM: $([math]::Round($usedMem,1)) ГБ из $([math]::Round($totalMem,1)) ГБ" -ForegroundColor Yellow
            } catch {
                Write-Color "Не удалось получить данные мониторинга." "Red"
            }
            pause
        }

        '9' {
            Clear-Host; Write-Color "Место на дисках." "Cyan"
            Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
                $free = [math]::Round($_.FreeSpace / 1GB, 2)
                $total = [math]::Round($_.Size / 1GB, 2)
                Write-Host "  $($_.DeviceId) : $free ГБ свободно из $total ГБ" -ForegroundColor Green
            }
            pause
        }

        'A' {
            Clear-Host; Write-Color "Содержимое корзины:" "Cyan"
            $items = Get-ChildItem -LiteralPath $trashFolder -Force -ErrorAction SilentlyContinue
            if ($items) {
                foreach ($it in $items) { Write-Host "  - $($it.Name) — $(FSize $it.Length)" }
            } else {
                Write-Color "Корзина пуста." "Gray"
            }
            pause
        }
        'B' {
            Clear-Host; Write-Color "Восстановление файла из корзины." "Cyan"
            $fname = Read-Host " Имя файла (точно как в корзине, включая расширение):"
            if ([string]::IsNullOrWhiteSpace($fname)) { Write-Color "Имя не введено." "Yellow"; pause; continue }
            $src = Join-Path -Path $trashFolder -ChildPath $fname
            if (Test-Path $src) {
                # Пытаемся вернуть в папку со скриптом
                try {
                    Move-Item -LiteralPath $src -Destination $scriptPath -Force
                    Write-Color "Файл восстановлен в папку Cleaner." "Green"
                } catch {
                    Write-Color "Не удалось восстановить: $($_.Exception.Message)" "Red"
                }
            } else {
                Write-Color "Файл не найден в корзине." "Red"
            }
            pause
        }

        'C' {
            Clear-Host; Write-Color "ВНИМАНИЕ: удаление корзины без восстановления!" "Red"
            Write-Color "Все файлы в корзине будут удалены навсегда!" "Yellow"
            $conf = Read-Host " Подтвердить (Y/N)?"
            if ($conf -match '^[Yy]') {
                Remove-Item -LiteralPath $trashFolder -Force -Recurse -ErrorAction SilentlyContinue
                New-Item -ItemType Directory -Force -Path $trashFolder | Out-Null
                Write-Color "Корзина очищена." "Green"
            } else {
                Write-Color "Отменено." "Yellow"
            }
            pause
        }

        '0' { exit }

        default {
            Write-Color "Неверный выбор." "Yellow"
            Start-Sleep -Seconds 1
        }
    }
}

    
