$ErrorActionPreference = "Continue"
$root = "c:\Users\stoic\Documents\antigravity\clever-maxwell"

$bundleObj = @{
    SlimeData      = [System.IO.File]::ReadAllText("$root\src\shared\SlimeData.luau", [System.Text.Encoding]::UTF8)
    UIBuilder      = [System.IO.File]::ReadAllText("$root\src\shared\UIBuilder.luau", [System.Text.Encoding]::UTF8)
    SquishyBuilder = [System.IO.File]::ReadAllText("$root\src\shared\SquishyBuilder.luau", [System.Text.Encoding]::UTF8)
    PrebuiltLoader           = [System.IO.File]::ReadAllText("$root\src\shared\PrebuiltLoader.luau", [System.Text.Encoding]::UTF8)
    CreatorStoreGameplayKits = [System.IO.File]::ReadAllText("$root\src\shared\CreatorStoreGameplayKits.luau", [System.Text.Encoding]::UTF8)
    WorldBuilder             = [System.IO.File]::ReadAllText("$root\src\server\WorldBuilder.luau", [System.Text.Encoding]::UTF8)
    GameServer               = [System.IO.File]::ReadAllText("$root\src\server\GameServer.server.luau", [System.Text.Encoding]::UTF8)
    GameClient               = [System.IO.File]::ReadAllText("$root\src\client\GameClient.client.luau", [System.Text.Encoding]::UTF8)
}
$bundleJson = $bundleObj | ConvertTo-Json -Depth 4 -Compress
$bundleBytes = [System.Text.Encoding]::UTF8.GetBytes($bundleJson)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:18765/")
$listener.Start()
Write-Output "Started local bundle server on http://127.0.0.1:18765/ ($($bundleBytes.Length) bytes)"

Stop-Process -Name "RobloxStudioBeta" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Remove-Item -Path "$root\Find My Squishy.rbxl.lock" -Force -ErrorAction SilentlyContinue

$studioExe = Get-ChildItem "$env:LOCALAPPDATA\Roblox\Versions\*\RobloxStudioBeta.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
$studioProc = Start-Process -FilePath $studioExe -ArgumentList "-task EditPlace -universeId 10771618269 -placeId 99542192127764" -PassThru
Write-Output "Launched interactive Cloud EditPlace Studio PID: $($studioProc.Id)"

$asyncTask = $listener.GetContextAsync()
$deadline = (Get-Date).AddSeconds(45)
while ((Get-Date) -lt $deadline) {
    if ($asyncTask.IsCompleted) {
        $ctx = $asyncTask.Result
        $ctx.Response.ContentType = "application/json; charset=utf-8"
        $ctx.Response.ContentLength64 = $bundleBytes.Length
        $ctx.Response.OutputStream.Write($bundleBytes, 0, $bundleBytes.Length)
        $ctx.Response.OutputStream.Close()
        Write-Output "Served /bundle.json to Roblox Studio Cloud EditPlace!"
        break
    }
    Start-Sleep -Milliseconds 200
}
$listener.Stop()

Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class StudioWinHelper2 {
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr hWndParent, EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, int dwExtraInfo);
    [DllImport("user32.dll")] public static extern IntPtr WindowFromPoint(POINT Point);
    [DllImport("user32.dll")] public static extern bool ScreenToClient(IntPtr hWnd, ref POINT lpPoint);

    public static string ClickPoint(int sx, int sy) {
        POINT pt = new POINT { X = sx, Y = sy };
        IntPtr hwnd = WindowFromPoint(pt);
        if (hwnd == IntPtr.Zero) return "NoWindow";
        ScreenToClient(hwnd, ref pt);
        int lParamVal = (pt.Y << 16) | (pt.X & 0xFFFF);
        IntPtr lParam = new IntPtr(lParamVal);
        SendMessage(hwnd, 0x0200, IntPtr.Zero, lParam);
        System.Threading.Thread.Sleep(60);
        SendMessage(hwnd, 0x0201, new IntPtr(1), lParam);
        System.Threading.Thread.Sleep(80);
        SendMessage(hwnd, 0x0202, IntPtr.Zero, lParam);
        return string.Format("Clicked HWND={0} client=({1},{2})", hwnd, pt.X, pt.Y);
    }
}
"@

$targetHwnd = [IntPtr]::Zero
$targetTitle = ""
$winDeadline = (Get-Date).AddSeconds(20)
while ((Get-Date) -lt $winDeadline) {
    $script:foundHwnd = [IntPtr]::Zero
    $script:foundTitle = ""
    [StudioWinHelper2]::EnumWindows({
        param($hWnd, $lParam)
        $pidOut = [uint32]0
        [StudioWinHelper2]::GetWindowThreadProcessId($hWnd, [ref]$pidOut) | Out-Null
        if ($pidOut -eq $studioProc.Id -and [StudioWinHelper2]::IsWindowVisible($hWnd)) {
            $sb = New-Object System.Text.StringBuilder 256
            [StudioWinHelper2]::GetWindowText($hWnd, $sb, 256) | Out-Null
            $t = $sb.ToString()
            if ($t.Length -gt 0 -and $t -notmatch "Splash") {
                $script:foundHwnd = $hWnd
                $script:foundTitle = $t
                return $false
            }
        }
        return $true
    }, [IntPtr]::Zero) | Out-Null

    if ($script:foundHwnd -ne [IntPtr]::Zero) {
        $targetHwnd = $script:foundHwnd
        $targetTitle = $script:foundTitle
        break
    }
    Start-Sleep -Milliseconds 400
}

# Wait until EditModeBuilder finishes SetWaypoint in the Studio log
$logDeadline = (Get-Date).AddSeconds(60)
while ((Get-Date) -lt $logDeadline) {
    $l = Get-ChildItem "$env:LOCALAPPDATA\Roblox\logs\*.log" | Where-Object { $_.Name -like "*Studio*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($l) {
        $txt = Get-Content $l.FullName -Raw -ErrorAction SilentlyContinue
        if ($txt -match "Marked DataModel dirty via ChangeHistoryService:SetWaypoint") {
            Write-Output "Confirmed ChangeHistoryService:SetWaypoint in Studio log!"
            break
        }
    }
    Start-Sleep -Milliseconds 400
}

[StudioWinHelper2]::EnumWindows({
    param($hWnd, $lParam)
    $pidOut = [uint32]0
    [StudioWinHelper2]::GetWindowThreadProcessId($hWnd, [ref]$pidOut) | Out-Null
    if ($pidOut -eq $studioProc.Id -and [StudioWinHelper2]::IsWindowVisible($hWnd)) {
        $sb = New-Object System.Text.StringBuilder 256
        [StudioWinHelper2]::GetWindowText($hWnd, $sb, 256) | Out-Null
        $t = $sb.ToString()
        if ($t.Length -gt 0 -and $t -notmatch "Splash") {
            $script:targetHwnd = $hWnd
            $script:targetTitle = $t
            return $false
        }
    }
    return $true
}, [IntPtr]::Zero) | Out-Null

Write-Output "Active Studio Window HWND=$targetHwnd Title='$targetTitle'"
[StudioWinHelper2]::ShowWindow($targetHwnd, 9) | Out-Null
[StudioWinHelper2]::MoveWindow($targetHwnd, 0, 0, 1920, 1040, $true) | Out-Null
[StudioWinHelper2]::SetForegroundWindow($targetHwnd) | Out-Null

$ctrlListener = New-Object System.Net.HttpListener
$ctrlListener.Prefixes.Add("http://127.0.0.1:18766/")
$ctrlListener.Start()
Write-Output "Studio Control Server listening on http://127.0.0.1:18766/"

Add-Type -AssemblyName System.Drawing
while ($true) {
    $ctx = $ctrlListener.GetContext()
    $q = $ctx.Request.QueryString
    $cmd = $q["cmd"]
    $resText = "OK"
    if ($cmd -eq "click") {
        $x = [int]$q["x"]
        $y = [int]$q["y"]
        $resText = [StudioWinHelper2]::ClickPoint($x, $y)
    } elseif ($cmd -eq "key") {
        $vk = [int]$q["vk"]
        $alt = $q["alt"] -eq "1"
        [StudioWinHelper2]::SetForegroundWindow($targetHwnd) | Out-Null
        if ($alt) {
            [StudioWinHelper2]::PostMessage($targetHwnd, 0x0104, (New-Object IntPtr($vk)), (New-Object IntPtr(0x20000001))) | Out-Null
            Start-Sleep -Milliseconds 80
            [StudioWinHelper2]::PostMessage($targetHwnd, 0x0105, (New-Object IntPtr($vk)), (New-Object IntPtr(-1073741823))) | Out-Null
        } else {
            [StudioWinHelper2]::PostMessage($targetHwnd, 0x0100, (New-Object IntPtr($vk)), (New-Object IntPtr(1))) | Out-Null
            Start-Sleep -Milliseconds 80
            [StudioWinHelper2]::PostMessage($targetHwnd, 0x0101, (New-Object IntPtr($vk)), (New-Object IntPtr(-1073741823))) | Out-Null
        }
        $resText = "SentKey vk=$vk alt=$alt"
    } elseif ($cmd -eq "windows") {
        $winList = New-Object System.Collections.Generic.List[string]
        [StudioWinHelper2]::EnumWindows({
            param($hWnd, $lParam)
            $pidOut = [uint32]0
            [StudioWinHelper2]::GetWindowThreadProcessId($hWnd, [ref]$pidOut) | Out-Null
            if ($pidOut -eq $studioProc.Id -and [StudioWinHelper2]::IsWindowVisible($hWnd)) {
                $sb = New-Object System.Text.StringBuilder 256
                [StudioWinHelper2]::GetWindowText($hWnd, $sb, 256) | Out-Null
                $winList.Add("HWND=$hWnd Title='$($sb.ToString())'")
            }
            return $true
        }, [IntPtr]::Zero) | Out-Null
        $resText = ($winList -join "`n")
    } elseif ($cmd -eq "snap") {
        $hwndToCap = if ($q["hwnd"]) { New-Object IntPtr([long]$q["hwnd"]) } else { $targetHwnd }
        $bmp = New-Object System.Drawing.Bitmap(1920, 1040)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $hdc = $g.GetHdc()
        [StudioWinHelper2]::PrintWindow($hwndToCap, $hdc, 2) | Out-Null
        $g.ReleaseHdc($hdc)
        $g.Dispose()
        $outPath = "C:\Users\stoic\.gemini\antigravity\brain\090adf17-918c-4074-b898-42768880514f\studio_cloud_synced_verified.png"
        $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        $resText = "Snapped HWND=$hwndToCap to $outPath"
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($resText)
    $ctx.Response.ContentType = "text/plain; charset=utf-8"
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.OutputStream.Close()
}
