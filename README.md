# Folder Size Search

## Overview

This project contains:
1. `DiskUsage.ps1` for interactive disk usage exploration and logging.
2. `copy-files-before-delete.cmd` with example `robocopy` commands (commented out) for backing up folders.
3. `archived-logs` with previous log outputs.

## DiskUsage.ps1

`DiskUsage.ps1` scans the immediate subfolders of a target path, calculates their total sizes (recursive), sorts by size, and shows the top results. It is interactive: you can drill down into a folder, go back to the parent, or quit. All results and user choices are logged to a file.

### Parameters

1. `-Path` (required): Root path to scan.
2. `-Top` (optional, default `20`): Number of top folders to show.
3. `-LogFile` (optional, default `log.txt`): Output log file path.

### Usage

```powershell
.\DiskUsage.ps1 -Path C:\Users\rsese -Top 20 -LogFile "disk_audit.txt"
```

### Interaction

After each scan:
1. Enter a number to drill into that folder.
2. Type `back` (or `b`) to move up one level.
3. Type `q` / `quit` / `exit` to stop.

## copy-files-before-delete.cmd

`copy-files-before-delete.cmd` contains example `robocopy` commands for backing up folders. All commands are commented out; edit and uncomment the lines you need before running.
