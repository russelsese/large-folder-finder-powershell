param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [int]$Top = 20,

    [string]$LogFile = "log.txt"
)

# Initialize log file
"===== Disk Usage Scan Started: $(Get-Date) =====" | Out-File -FilePath $LogFile -Encoding utf8
"Root Path: $Path" | Out-File -FilePath $LogFile -Append
"Top Results: $Top" | Out-File -FilePath $LogFile -Append

function Log-Line {
    param([string]$Text)
    $Text | Out-File -FilePath $LogFile -Append
}

function Get-FolderSizes {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    Log-Line "
Scanning: $TargetPath"

    # Get immediate child directories for progress tracking
    $folders = Get-ChildItem -LiteralPath $TargetPath -Directory -Force -ErrorAction SilentlyContinue
    $total = $folders.Count

    if ($total -eq 0) {
        Write-Host "No subfolders found under: $TargetPath" -ForegroundColor Yellow
        Log-Line "No subfolders found under: $TargetPath"
        return @()
    }

    $counter = 0
    $results = foreach ($folder in $folders) {
        $counter++
        $percent = [math]::Round(($counter / $total) * 100, 1)

        Write-Progress -Activity "Scanning folders in $TargetPath" `
                       -Status "Processing: $($folder.FullName) ($counter of $total)" `
                       -PercentComplete $percent

        $size = (Get-ChildItem -LiteralPath $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue |
                 Measure-Object Length -Sum).Sum

        [PSCustomObject]@{
            Folder = $folder.FullName
            SizeGB  = [math]::Round(($size / 1GB), 2)
        }
    }

    Write-Progress -Activity "Scanning folders in $TargetPath" -Completed

    return $results | Sort-Object SizeGB -Descending
}

$CurrentPath = $Path

while ($true) {

    Write-Host "
=== Top $Top folders under: $CurrentPath ===" -ForegroundColor Cyan
    Log-Line "
=== Top $Top folders under: $CurrentPath ==="

    $sorted = Get-FolderSizes -TargetPath $CurrentPath

    if (-not $sorted -or $sorted.Count -eq 0) {
        break
    }

    $topList = $sorted | Select-Object -First $Top

    # Print numbered list and log it
    $i = 0
    foreach ($item in $topList) {
        $i++
        $line = "[{0}] {1}  ({2} GB)" -f $i, $item.Folder, $item.SizeGB
        Write-Host $line
        Log-Line $line
    }

    Write-Host "
Enter a number to drill into that folder, type 'back' to go up one level, or 'q' to quit." -ForegroundColor Green
    $choice = Read-Host "Selection"

    Log-Line "User selection: $choice"

    if ($choice -match '^(q|quit|exit)$') {
        break
    }

    if ($choice -match '^(back|b)$') {
        $parent = Split-Path $CurrentPath -Parent

        if ($parent -and (Test-Path -LiteralPath $parent)) {
            Log-Line "Moving up to: $parent"
            $CurrentPath = $parent
            continue
        }
        else {
            Write-Host "Already at the root level." -ForegroundColor Yellow
            continue
        }
    }

    if (-not [int]::TryParse($choice, [ref]$null)) {
        Write-Host "Invalid input. Please enter a number (1-$($topList.Count)) or 'q'." -ForegroundColor Yellow
        continue
    }

    $idx = [int]$choice
    if ($idx -lt 1 -or $idx -gt $topList.Count) {
        Write-Host "Out of range. Please enter a number (1-$($topList.Count)) or 'q'." -ForegroundColor Yellow
        continue
    }

    $selected = $topList[$idx - 1].Folder

    Log-Line "Drilling into: $selected"

    if (-not (Test-Path -LiteralPath $selected)) {
        Write-Host "Selected path no longer exists: $selected" -ForegroundColor Yellow
        Log-Line "Path no longer exists: $selected"
        break
    }

    $CurrentPath = $selected
}

Log-Line "===== Scan Finished: $(Get-Date) ====="

Write-Host "Done. Results saved to $LogFile" -ForegroundColor Cyan
