# trigger_publish.ps1
# Automates Studio File -> Publish to Roblox (Alt+P) via local HTTP helper on port 18766

for ($i = 0; $i -lt 30; $i++) {
    try {
        $w = Invoke-RestMethod -Uri "http://127.0.0.1:18766/?cmd=windows" -TimeoutSec 2 -ErrorAction Stop
        if ($w) {
            Write-Output "Studio helper ready: $w"
            break
        }
    } catch {}
    Start-Sleep -Seconds 1
}

Start-Sleep -Seconds 4

# Click File menu at (X=14, Y=40)
Write-Output "Clicking File menu..."
Invoke-RestMethod -Uri "http://127.0.0.1:18766/?cmd=click&x=14&y=40" | Out-Null
Start-Sleep -Milliseconds 350

# Navigate to Publish to Roblox (13 down arrows)
1..13 | ForEach-Object {
    Invoke-RestMethod -Uri "http://127.0.0.1:18766/?cmd=key&vk=40" | Out-Null
    Start-Sleep -Milliseconds 120
}

# Press Enter to publish
Write-Output "Pressing Enter on Publish to Roblox..."
Invoke-RestMethod -Uri "http://127.0.0.1:18766/?cmd=key&vk=13" | Out-Null
Start-Sleep -Seconds 8

$latestLog = Get-ChildItem "$env:LOCALAPPDATA\Roblox\logs\*Studio*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Write-Output "Latest Studio Log: $($latestLog.FullName)"
$matches = Select-String -Path $latestLog.FullName -Pattern "AUDIT|CloudPlaceSynced|Publish succeeded|publish notes"
foreach ($m in $matches) {
    Write-Output $m.Line
}
