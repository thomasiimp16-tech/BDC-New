#requires -Version 5.1
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$__early = Join-Path $env:TEMP "SyncProject_early.log"
try { Add-Content -Path $__early -Value ("[{0}] START pid={1} IsAdmin={2} PSCommandPath=[{3}] MyInvPath=[{4}]" -f (Get-Date -Format o), $PID, $IsAdmin, $PSCommandPath, $MyInvocation.MyCommand.Path) -Encoding UTF8 } catch {}
if (-not $IsAdmin) {
    try {
        $scriptPath = $PSCommandPath; if (-not $scriptPath) { $scriptPath = $MyInvocation.MyCommand.Path }
        if (-not $scriptPath) {
            try { Add-Content -Path $__early -Value "  -> NO scriptPath, cannot self-elevate; continuing NON-admin" -Encoding UTF8 } catch {}
            Write-Warning "Could not determine script path; run this .ps1 file directly (not via -Command/iex) so it can elevate itself."
        } else {
            try { Add-Content -Path $__early -Value ("  -> relaunching elevated with -File [{0}]" -f $scriptPath) -Encoding UTF8 } catch {}
            Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$scriptPath`"") -Verb RunAs
            try { Add-Content -Path $__early -Value "  -> Start-Process RunAs returned WITHOUT throwing; exiting original" -Encoding UTF8 } catch {}
            exit
        }
    } catch {
        try { Add-Content -Path $__early -Value ("  -> ELEVATION THREW: {0}; continuing NON-admin" -f $_.Exception.Message) -Encoding UTF8 } catch {}
        Write-Warning "Could not elevate."
    }
}
try { Add-Content -Path $__early -Value ("[{0}] passed elevation gate, IsAdmin={1}, loading WPF..." -f (Get-Date -Format o), $IsAdmin) -Encoding UTF8 } catch {}
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$Global:Orig = @{}; $Global:AppliedKeys = @{}; $Global:OrigServices = @{}; $Global:OrigMisc = @{}; $Global:ActiveNetPreset = $null; $Global:ActiveGpuPreset = $null; $Global:SelectAllActive = $false
$Global:StateDir = Join-Path $env:LOCALAPPDATA "SyncProject"; $Global:StateFile = Join-Path $Global:StateDir "state.json"
function Save-TweakState { try { if(-not(Test-Path $Global:StateDir)){New-Item -Path $Global:StateDir -ItemType Directory -Force|Out-Null}; @{Orig=$Global:Orig;AppliedKeys=$Global:AppliedKeys;TweakToggles=$Global:TweakToggles;OrigServices=$Global:OrigServices;OrigMisc=$Global:OrigMisc;ActiveNetPreset=$Global:ActiveNetPreset;ActiveGpuPreset=$Global:ActiveGpuPreset;SelectAllActive=$Global:SelectAllActive}|ConvertTo-Json -Depth 10|Set-Content -Path $Global:StateFile -Encoding UTF8 -EA Stop } catch {} }
function ConvertTo-HashtableDeep($obj) { if($null -eq $obj){return $null}; if($obj -is [System.Collections.IDictionary]){$h=@{};foreach($k in $obj.Keys){$h[$k]=ConvertTo-HashtableDeep $obj[$k]};return $h}; if($obj -is [PSCustomObject]){$h=@{};foreach($p in $obj.PSObject.Properties){$h[$p.Name]=ConvertTo-HashtableDeep $p.Value};return $h}; if(($obj -is [System.Collections.IEnumerable]) -and ($obj -isnot [string])){return @($obj|ForEach-Object{ConvertTo-HashtableDeep $_})}; return $obj }
function Load-TweakState { try { if(Test-Path $Global:StateFile){$raw=Get-Content -Path $Global:StateFile -Raw -EA Stop|ConvertFrom-Json -EA Stop; if($raw.Orig){$Global:Orig=ConvertTo-HashtableDeep $raw.Orig}; if($raw.AppliedKeys){$Global:AppliedKeys=ConvertTo-HashtableDeep $raw.AppliedKeys}; if($raw.TweakToggles){$Global:SavedTweakToggles=ConvertTo-HashtableDeep $raw.TweakToggles}; if($raw.OrigServices){$Global:OrigServices=ConvertTo-HashtableDeep $raw.OrigServices}; if($raw.OrigMisc){$Global:OrigMisc=ConvertTo-HashtableDeep $raw.OrigMisc}; if($raw.ActiveNetPreset){$Global:ActiveNetPreset=$raw.ActiveNetPreset}; if($raw.ActiveGpuPreset){$Global:ActiveGpuPreset=$raw.ActiveGpuPreset}; if($null -ne $raw.SelectAllActive){$Global:SelectAllActive=[bool]$raw.SelectAllActive}} } catch {} }
Load-TweakState
$Global:TweakToggles = @{ NetThrottle=$true;BcdTimer=$true;TcpGlobal=$true;KbQueue=$true;NduDisable=$true;GamingMemory=$true;FiveMBooster=$true;GM_FiveMPerfOptions=$true;NET_KillerFix=$true;NET_FiveMQos=$true;NET_FiveMFirewall=$true;GM_FiveMCoreAffinity=$true;DriverHealth=$true;LanOptimize=$true;WifiOptimize=$true;PWR_Throttling=$true;GM_FSOptim=$true;GM_MouseAccel=$true;UX_MenuInstant=$true;UX_Notifications=$true;ADV_HPET=$true;GM_SmoothMotion=$true;CLEAN_SmoothOptim=$true;NET_NoNagle=$true;PWR_UltimatePlan=$true;SYS_NoCoreParking=$true;GM_HAGS=$true;NET_PowerSaving=$true;NET_USBSelSuspend=$true;SYS_TimerRes=$true;SYS_PauseUpdates=$true;GM_GameMode=$true;GM_NoGameDVR=$true;GM_GameBarOff=$true;GM_StandbyClean=$true;CLEAN_NoSearchIndex=$true;CLEAN_NoTelemetry=$true;CLEAN_NoStorageSense=$true;SYS_Win32Priority=$true;GM_MMCSS=$true;NET_TcpTimedWait=$true;NET_PortRange=$true;NET_QoSReserve=$true;GM_MouseQueue=$true;GM_NoStickyKeys=$true;SYS_NoBackgroundApps=$true;CLEAN_NoWER=$true;CLEAN_NoPrintSpooler=$true;CLEAN_RemoveBloat=$true;GPU_TdrDelay_Nvidia=$true;GPU_TdrDelay_Amd=$true;GPU_NvidiaPowerMode=$true;GPU_NvidiaTelemetryOff=$true;GPU_AmdUlps=$true;GPU_AmdEventsUtil=$true;GPU_NvidiaMSIMode=$true;GPU_NvidiaOverlayOff=$true;GPU_AmdMSIMode=$true;GPU_AmdCrashDefenderOff=$true;NetThrottle_WiFi=$true;TcpGlobal_WiFi=$true;NduDisable_WiFi=$true;NET_NoNagle_WiFi=$true;NET_PowerSaving_WiFi=$true;NET_TcpTimedWait_WiFi=$true;NET_PortRange_WiFi=$true;NET_QoSReserve_WiFi=$true;NET_LanJumboFrame=$true;NET_LanInterruptModeration=$true;NET_WifiPowerSaveMode=$true;NET_WifiRoamingAggressiveness=$true;NET_DnsFast=$true;NET_DnsFast_WiFi=$true;NET_DeliveryOptOff=$true;NET_DnsCacheAggressive=$true;GPU_ClearShaderCache=$true;CLEAN_ClearTempJunk=$true;CLEAN_ClearFiveMCache=$true;SYS_BottleneckCheck=$true;NET_Ipv6Disable=$false;NET_RssEnable=$true;NET_FlowControlOff=$true;NET_Ipv6Disable_WiFi=$false;DEF_GameExclusion=$true;SYS_PageFileAuto=$true;NET_Ipv6Transition=$true;NET_DnsClientPolicy=$true;NET_LltdDisable=$true;NET_BitsNoLimit=$true;NET_NetbiosDisable=$true;NET_NcsiNoActiveProbe=$true;NET_NoAutoRootCertUpdate=$true;SYS_NoBkgndGPRefresh=$true;SYS_NoSmartScreenCheck=$true;NET_RemoteAssistanceOff=$true;SYS_OneDriveSyncOff=$true;SYS_WidgetsOff=$true;SYS_ConsumerFeaturesOff=$true;CLEAN_KillBackgroundProcs=$true;CLEAN_DisableLauncherStartup=$true }
# --- Shared lists used by BOTH the Run-* tweak functions and the pre-run confirmation dialog,
# so the dialog can never show a different list than what actually gets removed/killed. ---
$Global:BloatList = @(
    "Microsoft.XboxApp","Microsoft.Xbox.TCUI","Microsoft.XboxGamingOverlay","Microsoft.XboxSpeechToTextOverlay","Microsoft.XboxIdentityProvider","Microsoft.XboxGameOverlay",
    "Microsoft.3DBuilder","Microsoft.Microsoft3DViewer","Microsoft.MixedRealityPortal","Microsoft.SkypeApp","Microsoft.YourPhone",
    "Microsoft.MicrosoftSolitaireCollection","Microsoft.BingWeather","Microsoft.BingNews","Microsoft.BingFinance","Microsoft.ZuneMusic","Microsoft.ZuneVideo",
    "Microsoft.GetHelp","Microsoft.Getstarted","Microsoft.Messaging","Microsoft.MicrosoftOfficeHub","Microsoft.People","Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps","Microsoft.MixedReality.Portal","Microsoft.Wallet","Microsoft.WindowsAlarms","Microsoft.WindowsCommunicationsApps",
    "Microsoft.OneConnect","Microsoft.Print3D","Microsoft.Todos","Clipchamp.Clipchamp"
)
$Global:KillProcList = @(
    "OneDrive","Spotify","SpotifyWebHelper","Discord","DiscordCanary","DiscordPTB","Skype","Teams",
    "SteamWebHelper","EpicGamesLauncher","EpicWebHelper","OriginWebHelperService","UbisoftConnectWebHelper",
    "GoogleCrashHandler","GoogleCrashHandler64","GoogleUpdate","AdobeUpdateService","AdobeIPCBroker",
    "OneDriveStandaloneUpdater","YourPhone","GameBar","GameBarFTServer","XboxAppServices","Nvidia Share",
    "NVIDIA GeForce Experience","AMDRSSrcExt","RtkAudUService64","iCloudServices","CCleaner64","CCleaner",
    "Dropbox","Cortana","SearchApp","WidgetService","Widgets"
    # msedgewebview2 / TeamViewer / AnyDesk intentionally excluded - see review notes.
)
$Global:StartupDisableTargets = @("Steam","Discord","Epic","Battle.net","Origin","Ubisoft","Uplay","Riot","GOG","Spotify")
# --- SYNC PROJECT (customized): only Network + Input Lag tweaks are enabled by default. ---
# --- GPU tweaks are auto-detected. If only one vendor is found, only that vendor's category/tweaks are shown/enabled. ---
# --- If BOTH an NVIDIA and an AMD GPU are detected (hybrid/multi-GPU systems), both categories stay visible so the user can pick. ---
$Global:DetectedGpuVendor = $null
try {
    $__gpuNames = @(Get-CimInstance -ClassName Win32_VideoController -EA SilentlyContinue | Select-Object -ExpandProperty Name)
    $__hasNvidia = [bool]($__gpuNames -match "NVIDIA")
    $__hasAmd = [bool]($__gpuNames -match "AMD|ATI|Radeon")
    if ($__hasNvidia -and $__hasAmd) { $Global:DetectedGpuVendor = "BOTH" }
    elseif ($__hasNvidia) { $Global:DetectedGpuVendor = "NVIDIA" }
    elseif ($__hasAmd) { $Global:DetectedGpuVendor = "AMD" }
} catch {}
$Global:NvidiaOnlyKeys = @("GPU_NvidiaPowerMode","GPU_NvidiaTelemetryOff","GPU_NvidiaMSIMode","GPU_NvidiaOverlayOff")
$Global:AmdOnlyKeys    = @("GPU_AmdUlps","GPU_AmdEventsUtil","GPU_AmdMSIMode","GPU_AmdCrashDefenderOff")
if (-not $Global:SavedTweakToggles) {
    # Auto-select AND auto-deselect based on detected vendor, so a single-vendor
    # system never has the other vendor's (unsupported) tweaks left enabled.
    if ($Global:DetectedGpuVendor -eq "NVIDIA") {
        foreach ($k in $Global:NvidiaOnlyKeys) { $Global:TweakToggles[$k] = $true }
        foreach ($k in $Global:AmdOnlyKeys)    { $Global:TweakToggles[$k] = $false }
    }
    elseif ($Global:DetectedGpuVendor -eq "AMD") {
        foreach ($k in $Global:AmdOnlyKeys)    { $Global:TweakToggles[$k] = $true }
        foreach ($k in $Global:NvidiaOnlyKeys) { $Global:TweakToggles[$k] = $false }
    }
    elseif ($Global:DetectedGpuVendor -eq "BOTH") {
        foreach ($k in $Global:NvidiaOnlyKeys) { $Global:TweakToggles[$k] = $true }
        foreach ($k in $Global:AmdOnlyKeys)    { $Global:TweakToggles[$k] = $true }
    }
    else {
        # No GPU vendor detected at all (e.g. Get-CimInstance failed) - disable both
        # vendor-specific sets rather than silently trying both and logging warnings.
        foreach ($k in $Global:NvidiaOnlyKeys) { $Global:TweakToggles[$k] = $false }
        foreach ($k in $Global:AmdOnlyKeys)    { $Global:TweakToggles[$k] = $false }
    }
    # GPU_TdrDelay_Nvidia / GPU_TdrDelay_Amd both map to the same vendor-agnostic
    # TdrDelay tweak (see Run-GpuTdrDelay), so keep whichever one matches what was detected.
    if ($Global:DetectedGpuVendor -eq "AMD") { $Global:TweakToggles["GPU_TdrDelay_Nvidia"] = $false; $Global:TweakToggles["GPU_TdrDelay_Amd"] = $true }
    elseif ($Global:DetectedGpuVendor -eq "NVIDIA") { $Global:TweakToggles["GPU_TdrDelay_Amd"] = $false; $Global:TweakToggles["GPU_TdrDelay_Nvidia"] = $true }
}
if($Global:SavedTweakToggles){ foreach($k in $Global:SavedTweakToggles.Keys){ if($Global:TweakToggles.ContainsKey($k)){ $Global:TweakToggles[$k]=[bool]$Global:SavedTweakToggles[$k] } } }
# Safety net: even if an OLD state.json (saved before this fix) has the wrong vendor's
# tweaks set to $true, force them off every run - they can never apply on this hardware.
if ($Global:DetectedGpuVendor -ne "AMD" -and $Global:DetectedGpuVendor -ne "BOTH") {
    foreach ($k in $Global:AmdOnlyKeys) { $Global:TweakToggles[$k] = $false }
    if ($Global:DetectedGpuVendor -ne "NVIDIA") { $Global:TweakToggles["GPU_TdrDelay_Amd"] = $false }
}
if ($Global:DetectedGpuVendor -ne "NVIDIA" -and $Global:DetectedGpuVendor -ne "BOTH") {
    foreach ($k in $Global:NvidiaOnlyKeys) { $Global:TweakToggles[$k] = $false }
    if ($Global:DetectedGpuVendor -ne "AMD") { $Global:TweakToggles["GPU_TdrDelay_Nvidia"] = $false }
}
$Global:TweakInfo = @(
    @{Key="NetThrottle"; Title="Network Throttling -> Absolute Max"; Category="Network"; Group="LAN NETWORK"; Tag="REG"; Desc="Removes Windows' built-in network throttling limit so traffic isn't capped."}
    @{Key="TcpGlobal";   Title="TCP Global Stack Overhaul";           Category="Network"; Group="LAN NETWORK"; Tag="TCP"; Desc="Tunes the TCP stack (auto-tuning, RSS, fast open) for lower latency."}
    @{Key="NduDisable";  Title="Ndu Driver -> Disabled";              Category="Network"; Group="LAN NETWORK"; Tag="REG"; Desc="Disables the Network Data Usage driver, which some report adds overhead."}
    @{Key="LanOptimize"; Title="LAN Optimization";                    Category="Network"; Group="LAN NETWORK"; Tag="TCP"; Desc="Applies auto-tuning settings tailored for wired connections."}
    @{Key="NET_NoNagle";      Title="Nagle's Algorithm -> Disabled";  Category="Network"; Group="LAN NETWORK"; Tag="TCP"; Desc="Disables TCP ACK delay/coalescing per adapter so small packets (shots, positions) send immediately instead of waiting to batch."}
    @{Key="NET_PowerSaving";  Title="Adapter Power Saving -> Off";    Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Stops Windows from powering down network adapters and disables Energy-Efficient Ethernet, which can cause mid-match latency spikes."}
    @{Key="NET_TcpTimedWait"; Title="TCP TIME_WAIT Delay -> 30s";     Category="Network"; Group="LAN NETWORK"; Tag="TCP"; Desc="Shrinks the TIME_WAIT hold from 240s to 30s so ports free up fast during frequent connect/disconnect (voice chat, reconnects) - more stable under bursty traffic."}
    @{Key="NET_PortRange";    Title="Dynamic Port Range -> Widened";  Category="Network"; Group="LAN NETWORK"; Tag="TCP"; Desc="Expands the TCP/UDP ephemeral port range (10000-65535, IPv4 & IPv6) so a game with many simultaneous connections never runs out of ports."}
    @{Key="NET_QoSReserve";   Title="QoS Reserved Bandwidth -> 0% (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > QoS Packet Scheduler > Limit reservable bandwidth. Windows reserves 20% of bandwidth by default; this returns all of it to your traffic."}
    @{Key="NET_LanJumboFrame";Title="Jumbo Frame -> 9014 Bytes";      Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Wired only. Raises the wired adapter's max frame size so large TCP transfers move in fewer, bigger frames instead of many small ones, cutting per-packet CPU/interrupt overhead. Skipped if the adapter/switch doesn't support it."}
    @{Key="NET_LanInterruptModeration";Title="Interrupt Moderation -> Disabled"; Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Wired only. Stops the wired NIC from batching interrupts before notifying the CPU, trading a little CPU load for lower per-packet latency."}
    @{Key="NET_DnsFast";      Title="DNS -> Google (8.8.4.4 / 8.8.8.8)"; Category="Network"; Group="LAN NETWORK"; Tag="DNS"; Desc="Wired only. Points the wired adapter at fast, widely stable public resolvers (Google primary and secondary) instead of the ISP's default DNS, which can cut name-lookup delay."}
    @{Key="NET_DeliveryOptOff";Title="Delivery Optimization (P2P Updates) -> Off"; Category="Network"; Group="LAN NETWORK"; Tag="REG"; Desc="System-wide. Stops Windows Update from uploading update chunks to other PCs on the internet/LAN in the background, which can silently eat upload bandwidth and cause mid-match latency spikes."}
    @{Key="NET_DnsCacheAggressive";Title="DNS Client Cache -> Aggressive"; Category="Network"; Group="LAN NETWORK"; Tag="REG"; Desc="System-wide. Lengthens how long the local DNS resolver cache holds entries, so repeat lookups (game servers, CDNs) are served from cache instead of re-querying."}
    @{Key="NET_Ipv6Disable";  Title="IPv6 -> Disabled";              Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Wired only. Unbinds IPv6 on the wired adapter. Some ISPs/routers resolve and route IPv6 poorly, adding lookup/connect delay when a game or DNS falls back to it."}
    @{Key="NET_RssEnable";    Title="Receive Side Scaling -> Enabled"; Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Wired only. Spreads incoming network interrupts across multiple CPU cores instead of one, preventing a single core from bottlenecking throughput/latency under heavy traffic."}
    @{Key="NET_FlowControlOff";Title="Flow Control -> Disabled";     Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Wired only. Disables 802.3x flow control pause frames on the NIC, which some switches/routers mishandle in a way that causes brief stalls."}
    @{Key="NET_Ipv6Transition"; Title="IPv6 Transition Tech -> Disabled (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > TCPIP Settings > IPv6 Transition Technologies. Disables Teredo/6to4/ISATAP/IP-HTTPS tunneling attempts so nothing wastes time falling back to a dead IPv6 tunnel before using IPv4."}
    @{Key="NET_DnsClientPolicy"; Title="DNS Client Multicast/Smart Resolution -> Off (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > DNS Client > 'Turn off multicast name resolution' + 'Turn off smart multi-homed name resolution'. Stops the DNS client from firing extra parallel LLMNR/multi-homed lookups in the background."}
    @{Key="NET_LltdDisable"; Title="Link-Layer Topology Discovery -> Disabled (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > Link-Layer Topology Discovery (Mapper I/O + Responder). Stops periodic LLTD broadcast traffic used only for Windows' network map feature."}
    @{Key="NET_BitsNoLimit"; Title="BITS Bandwidth Limit -> Removed (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > Background Intelligent Transfer Service (BITS). Removes any background-transfer bandwidth cap so Windows Update/BITS jobs don't quietly reserve bandwidth during play."}
    @{Key="NET_NcsiNoActiveProbe"; Title="Network Connectivity Active Probing -> Off (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > Network Connectivity Status Indicator settings. Stops Windows from periodically pinging Microsoft's connectivity-check endpoint in the background, removing a small recurring source of background traffic and CPU wakeups."}
    @{Key="NET_NoAutoRootCertUpdate"; Title="Automatic Root Certificate Update -> Disabled (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > System > Internet Communication Management > Internet Communication settings > 'Turn off Automatic Root Certificates Update'. Stops Windows from silently reaching out to Microsoft to fetch new trusted root certificates in the background."}
    @{Key="NET_NetbiosDisable"; Title="NetBIOS over TCP/IP -> Disabled"; Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Disables legacy NetBIOS over TCP/IP on every adapter, cutting local broadcast/name-resolution chatter that isn't used by modern games or apps."}
    @{Key="NET_RemoteAssistanceOff"; Title="Solicited Remote Assistance -> Disabled (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Computer Configuration > System > Remote Assistance > 'Configure Solicited Remote Assistance', set to Disabled. Stops the PC from being reachable for incoming Remote Assistance sessions, removing an always-listening background feature."}

    @{Key="WifiOptimize";Title="Wi-Fi Optimization";                  Category="Network"; Group="WI-FI NETWORK"; Tag="ADAPTER"; Desc="Prefers the 5GHz band for a more stable, lower-latency Wi-Fi link."}
    @{Key="NetThrottle_WiFi"; Title="Network Throttling -> Absolute Max"; Category="Network"; Group="WI-FI NETWORK"; Tag="REG"; Desc="Removes Windows' built-in network throttling limit so traffic isn't capped."}
    @{Key="TcpGlobal_WiFi";   Title="TCP Global Stack Overhaul";           Category="Network"; Group="WI-FI NETWORK"; Tag="TCP"; Desc="Tunes the TCP stack (auto-tuning, RSS, fast open) for lower latency."}
    @{Key="NduDisable_WiFi";  Title="Ndu Driver -> Disabled";              Category="Network"; Group="WI-FI NETWORK"; Tag="REG"; Desc="Disables the Network Data Usage driver, which some report adds overhead."}
    @{Key="NET_NoNagle_WiFi";      Title="Nagle's Algorithm -> Disabled";  Category="Network"; Group="WI-FI NETWORK"; Tag="TCP"; Desc="Disables TCP ACK delay/coalescing per adapter so small packets (shots, positions) send immediately instead of waiting to batch."}
    @{Key="NET_PowerSaving_WiFi";  Title="Adapter Power Saving -> Off";    Category="Network"; Group="WI-FI NETWORK"; Tag="ADAPTER"; Desc="Stops Windows from powering down network adapters and disables Energy-Efficient Ethernet, which can cause mid-match latency spikes."}
    @{Key="NET_TcpTimedWait_WiFi"; Title="TCP TIME_WAIT Delay -> 30s";     Category="Network"; Group="WI-FI NETWORK"; Tag="TCP"; Desc="Shrinks the TIME_WAIT hold from 240s to 30s so ports free up fast during frequent connect/disconnect (voice chat, reconnects) - more stable under bursty traffic."}
    @{Key="NET_PortRange_WiFi";    Title="Dynamic Port Range -> Widened";  Category="Network"; Group="WI-FI NETWORK"; Tag="TCP"; Desc="Expands the TCP/UDP ephemeral port range (10000-65535, IPv4 & IPv6) so a game with many simultaneous connections never runs out of ports."}
    @{Key="NET_QoSReserve_WiFi";   Title="QoS Reserved Bandwidth -> 0% (gpedit)"; Category="Network"; Group="WI-FI NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > QoS Packet Scheduler > Limit reservable bandwidth. Windows reserves 20% of bandwidth by default; this returns all of it to your traffic."}
    @{Key="NET_WifiPowerSaveMode";Title="802.11 Power Saving -> Disabled"; Category="Network"; Group="WI-FI NETWORK"; Tag="ADAPTER"; Desc="Wi-Fi only. Forces the Wi-Fi adapter's driver-level power save mode off so the radio stays fully awake between packets instead of dozing and adding latency."}
    @{Key="NET_WifiRoamingAggressiveness";Title="Roaming Aggressiveness -> Lowest"; Category="Network"; Group="WI-FI NETWORK"; Tag="ADAPTER"; Desc="Wi-Fi only. Makes the adapter stick to the current access point instead of hunting for a 'better' one mid-match, avoiding the brief drop when it roams."}
    @{Key="NET_DnsFast_WiFi"; Title="DNS -> Google (8.8.4.4 / 8.8.8.8)"; Category="Network"; Group="WI-FI NETWORK"; Tag="DNS"; Desc="Wi-Fi only. Points the Wi-Fi adapter at fast, widely stable public resolvers (Google primary and secondary) instead of the ISP's default DNS, which can cut name-lookup delay."}
    @{Key="NET_Ipv6Disable_WiFi";Title="IPv6 -> Disabled";           Category="Network"; Group="WI-FI NETWORK"; Tag="ADAPTER"; Desc="Wi-Fi only. Unbinds IPv6 on the Wi-Fi adapter. Some ISPs/routers resolve and route IPv6 poorly, adding lookup/connect delay when a game or DNS falls back to it."}

    @{Key="KbQueue";     Title="Keyboard Queue Size -> 10";           Category="Input"  ; Group="INPUT LAG"; Tag="REG"; Desc="Shrinks the keyboard input buffer so keystrokes register with less delay."}
    @{Key="GM_MouseAccel";    Title="Mouse Acceleration -> Disabled"; Category="Input"  ; Group="INPUT LAG"; Tag="REG"; Desc="Turns off pointer acceleration for 1:1 raw mouse movement."}
    @{Key="NET_USBSelSuspend";Title="USB Selective Suspend -> Off";   Category="Input"  ; Group="INPUT LAG"; Tag="REG"; Desc="Stops USB mice/keyboards from being suspended when idle, removing the wake-up delay."}
    @{Key="GM_MouseQueue";    Title="Mouse Data Queue Size -> 100 (safe default)"; Category="Input"  ; Group="INPUT LAG"; Tag="REG"; Desc="Keeps the mouse input buffer at Windows' own default (100). Shrinking this below default can cause dropped input on high polling-rate mice, which shows up as cursor ghosting/skipping."}
    @{Key="GM_NoStickyKeys";  Title="Sticky/Toggle/Filter Keys -> Disabled"; Category="Input"; Group="INPUT LAG"; Tag="REG"; Desc="Turns off the accessibility hotkeys so holding Shift/Ctrl while spamming WASD never triggers the Sticky Keys popup mid-fight."}

    @{Key="BcdTimer";    Title="BCD Timer Tweaks";                   Category="System"; Group="SYSTEM & TIMING"; Tag="BCD"; Desc="Adjusts boot timer settings for more precise system clock ticks (needs reboot)."}
    @{Key="ADV_HPET";         Title="Dynamic Tick and HPET -> Disabled";    Category="System"; Group="SYSTEM & TIMING"; Tag="BCD"; Desc="Disables dynamic tick and HPET, which can reduce micro-stutter (needs reboot)."}
    @{Key="PWR_Throttling";   Title="Power Throttling -> Off";              Category="Power" ; Group="SYSTEM & TIMING"; Tag="REG"; Desc="Stops Windows from throttling background process power to keep performance steady."}
    @{Key="PWR_UltimatePlan"; Title="Ultimate Performance Power Plan";      Category="Power" ; Group="SYSTEM & TIMING"; Tag="POWERCFG"; Desc="Enables and activates the Ultimate Performance plan so the CPU never idles down during a match."}
    @{Key="SYS_NoCoreParking";Title="CPU Core Parking -> Disabled";        Category="System"; Group="SYSTEM & TIMING"; Tag="POWERCFG"; Desc="Keeps all CPU cores active instead of parking them, cutting the delay when a core has to spin back up."}
    @{Key="SYS_TimerRes";     Title="System Timer Resolution -> 0.5ms";    Category="System"; Group="SYSTEM & TIMING"; Tag="API"; Desc="Requests the finest Windows timer resolution for smoother frame pacing. Only holds while this app stays open."}
    @{Key="SYS_PauseUpdates"; Title="No Auto-Restart for Windows Update";  Category="System"; Group="SYSTEM & TIMING"; Tag="GPEDIT"; Desc="Stops Windows Update from silently rebooting the PC while you're logged in and mid-session."}
    @{Key="SYS_Win32Priority";Title="Win32PrioritySeparation -> Lowest Input Lag (0xFA322A)"; Category="System"; Group="SYSTEM & TIMING"; Tag="REG"; Desc="Sets Win32PrioritySeparation to 0xFA322A. Windows only reads the low 6 bits of this value, so it effectively behaves as 0x2A / 42 decimal (Short quantum / Variable length / No foreground boost) - CPU time is split equally and quickly between all processes with no single app hogging a turn, which competitive players cite as giving the best raw response time for mouse/keyboard input."}
    @{Key="SYS_NoBackgroundApps";Title="UWP Background Apps -> Blocked (gpedit)"; Category="System"; Group="SYSTEM & TIMING"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Administrative Templates > App Privacy > Let Windows apps run in the background, set to Force Deny. Stops Store apps from using CPU/network while minimized."}
    @{Key="SYS_NoBkgndGPRefresh";Title="Background Group Policy Refresh -> Disabled (gpedit)"; Category="System"; Group="SYSTEM & TIMING"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Administrative Templates > System > Group Policy > 'Turn off background refresh of Group Policy'. Stops Windows from silently re-applying policy every ~90 minutes, which can cause a brief hitch if it lands mid-session."}
    @{Key="SYS_NoSmartScreenCheck";Title="SmartScreen App Reputation Check -> Off (gpedit)"; Category="System"; Group="SYSTEM & TIMING"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Administrative Templates > Windows Components > File Explorer > 'Configure Windows Defender SmartScreen', set to Off. Skips the online reputation lookup Windows normally does when launching a new .exe, cutting the small delay/stutter on first launch of a game or tool."}
    @{Key="DriverHealth";Title="Driver Health Check";                 Category="System"; Group="SYSTEM & TIMING"; Tag="WMI"; Desc="Scans installed drivers and flags any reporting an error."}
    @{Key="SYS_PageFileAuto"; Title="Page File -> System Managed";    Category="System"; Group="SYSTEM & TIMING"; Tag="WMI"; Desc="Sets the page file back to Windows' automatically-managed size. Fixes cases where a manual pagefile was left too small/misplaced, which can cause stutter when RAM gets tight."}
    @{Key="SYS_BottleneckCheck"; Title="CPU/GPU Bottleneck Check"; Category="System"; Group="SYSTEM & TIMING"; Tag="WMI"; Desc="Samples CPU and GPU load for a few seconds and reports which is more taxed right now. This is an idle-desktop snapshot, not a per-game reading — use an in-game overlay (RTSS/Afterburner) for real numbers while actually playing."}

    @{Key="GamingMemory";Title="Gaming Memory Mode";                  Category="Memory"; Group="GAMING & MEMORY"; Tag="SVC"; Desc="Disables Superfetch so memory prioritization favors active games."}
    @{Key="FiveMBooster";Title="FiveM Booster";                       Category="Gaming"; Group="GAMING & MEMORY"; Tag="PROC"; Desc="Raises the FiveM process priority to High while it's running."}
    @{Key="GM_FiveMPerfOptions";Title="FiveM_GTAProcess.exe -> CpuPriorityClass 3 (IFEO)"; Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Adds an Image File Execution Options entry for FiveM_GTAProcess.exe with PerfOptions\\CpuPriorityClass set to 3 (Normal). This is applied by Windows automatically every time the process starts, unlike the FiveM Booster tweak above which only boosts an already-running process."}
    @{Key="GM_FiveMCoreAffinity"; Title="FiveM Core Affinity -> Auto-Optimized"; Category="Gaming"; Group="GAMING & MEMORY"; Tag="PROC"; Desc="Pins FiveM_GTAProcess.exe / FiveM.exe to cores 1 through (logical cores - 1, capped at 6), leaving core 0 free for system/interrupt work. If FiveM isn't running yet, watches for it in the background for up to 10 minutes and applies the affinity as soon as it starts. Skipped on 2-core-or-fewer systems."}
    @{Key="NET_KillerFix";    Title="Killer NIC Traffic Analysis -> Disabled";  Category="Network"; Group="GAMING & MEMORY"; Tag="SVC"; Desc="If a Killer-branded network adapter is detected, stops only its user-mode 'smart traffic' analytics service (not the adapter driver itself), which is a well-known cause of random ping spikes and packet loss in games. The adapter keeps working normally through the standard Windows driver. Skipped entirely if no Killer adapter is found."}
    @{Key="NET_FiveMQos";     Title="FiveM Traffic -> QoS Priority Tag";        Category="Network"; Group="GAMING & MEMORY"; Tag="QOS"; Desc="Tags outbound traffic from FiveM.exe / FiveM_GTAProcess.exe with a DSCP priority marker (Expedited Forwarding) so routers/ISPs that respect QoS tagging queue it ahead of other traffic. Also enables Windows to apply DSCP tagging on home (non-domain) networks, which is off by default. Purely additive - it does not throttle or block any other traffic, so it cannot slow down or drop your connection."}
    @{Key="NET_FiveMFirewall";Title="FiveM -> Explicit Firewall Allow Rule";     Category="Network"; Group="GAMING & MEMORY"; Tag="FW"; Desc="Adds an explicit Windows Firewall allow rule for the running FiveM.exe / FiveM_GTAProcess.exe so their traffic is never silently dropped by a delayed firewall prompt or a conflicting security app. Only adds allow rules - never removes or restricts existing ones, so it cannot cause disconnects. Skipped if FiveM isn't running when you click Run."}
    @{Key="GM_FSOptim";       Title="Fullscreen Optimizations -> Disabled"; Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Disables Windows' fullscreen optimizations layer, which can add input delay."}
    @{Key="GM_SmoothMotion";  Title="Smooth Motion -> MPO Disabled";        Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Disables Multi-Plane Overlay, which some GPUs mishandle causing stutter."}
    @{Key="GM_HAGS";          Title="Hardware-Accelerated GPU Scheduling -> On"; Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Lets the GPU manage its own scheduling queue, which can lower render latency on supported GPUs (needs reboot)."}
    @{Key="GM_GameMode";      Title="Windows Game Mode -> Forced On";       Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Forces Windows Game Mode on so the foreground game reliably gets CPU/GPU scheduling priority."}
    @{Key="GM_NoGameDVR";     Title="Game Bar / Game DVR -> Disabled";      Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Turns off Xbox Game Bar's background recording, which quietly eats CPU/GPU while you play."}
    @{Key="GM_GameBarOff";    Title="Xbox Game Bar Overlay -> Disabled";    Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Goes further than the DVR toggle above: stops the Xbox Game Bar overlay itself (Win+G panel) from loading in the background, freeing up the memory/CPU it reserves and removing another source of input-hook overhead."}
    @{Key="GM_StandbyClean";  Title="Clear Standby Memory List";            Category="Memory"; Group="GAMING & MEMORY"; Tag="API"; Desc="Purges the standby (cached) memory list so the game gets clean free RAM instead of waiting on the cache."}
    @{Key="GM_MMCSS";         Title="MMCSS Games Profile -> Smooth Max";     Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Sets the Multimedia Class Scheduler's Games task profile to the best-known values (max GPU/CPU priority, High scheduling category) for the smoothest frame delivery."}
    @{Key="DEF_GameExclusion";Title="Defender Exclusions -> Game Folders";   Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Adds Windows Defender real-time scan exclusions for common launcher/game folders (Steam, Epic, Riot, FiveM) that are found on this PC, so on-access scanning doesn't add disk I/O stutter while loading. Only paths that exist are added."}

    @{Key="UX_MenuInstant";   Title="Instant Menus and Animations Off";     Category="UX"  ; Group="INTERFACE & CLEANUP"; Tag="REG"; Desc="Sets menu show delay to 0ms and trims UI animations."}
    @{Key="UX_Notifications"; Title="Toast Notifications -> Disabled";      Category="UX"  ; Group="INTERFACE & CLEANUP"; Tag="REG"; Desc="Silences Windows toast pop-ups so they don't interrupt gameplay."}
    @{Key="CLEAN_SmoothOptim";Title="Smooth Background Maintenance";        Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="TASK"; Desc="Disables scheduled background maintenance so it can't kick in mid-session."}
    @{Key="CLEAN_NoWER";      Title="Windows Error Reporting -> Disabled";  Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="SVC"; Desc="Stops the WerSvc service so a crashed app can't trigger a dump-write/popup that stutters the system."}
    @{Key="CLEAN_NoPrintSpooler";Title="Print Spooler -> Disabled (OFF by default)"; Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="SVC"; Desc="Disables the Print Spooler service. Off by default - only enable this if you don't use a printer, since it will stop printing from working."}
    @{Key="CLEAN_NoSearchIndex";Title="Windows Search Indexing -> Disabled";Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="SVC"; Desc="Stops the Windows Search service so it can't chew disk I/O in the background."}
    @{Key="CLEAN_NoTelemetry"; Title="Telemetry Service -> Disabled";       Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="SVC"; Desc="Stops the Connected User Experiences and Telemetry (DiagTrack) service."}
    @{Key="CLEAN_NoStorageSense";Title="Storage Sense -> Disabled";         Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="REG"; Desc="Stops Windows from automatically scanning and cleaning storage in the background."}
    @{Key="CLEAN_KillBackgroundProcs";Title="Non-Essential Background Processes -> Closed"; Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="PROC"; Desc="Closes a curated list of common non-essential background apps that are currently running (updaters, chat/overlay clients, cloud-sync helpers, etc.) to immediately lower the process count in Task Manager. Never touches Windows system processes, drivers, security software, or the foreground game - only known safe-to-close third-party helper apps."}
    @{Key="CLEAN_DisableLauncherStartup";Title="Game Launchers & Chat Apps -> Startup Disabled"; Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="REG"; Desc="Removes Steam, Discord, Epic Games, Battle.net, Origin, Ubisoft Connect, Riot Client, GOG Galaxy and Spotify from Windows startup (HKCU/HKLM Run keys) so they no longer auto-launch when you turn on the PC. You can still open them manually anytime - this only stops the automatic launch. Fully reversible via Restore."}
    @{Key="SYS_OneDriveSyncOff"; Title="OneDrive Background Sync -> Off (gpedit)"; Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Administrative Templates > OneDrive > 'Prevent the usage of OneDrive for file storage'. Stops OneDrive from syncing in the background and also ends any currently-running OneDrive process."}
    @{Key="SYS_WidgetsOff"; Title="Windows Widgets -> Disabled (gpedit)"; Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Administrative Templates > Windows Components > Widgets > 'Allow widgets', set to Disabled. Stops the Widgets/News-and-interests board from loading content in the background."}
    @{Key="SYS_ConsumerFeaturesOff"; Title="Consumer Features / Suggested Apps -> Blocked (gpedit)"; Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Administrative Templates > Windows Components > Cloud Content > 'Turn off Microsoft consumer experiences'. Stops Windows from silently re-installing bundled/suggested apps in the background."}

    @{Key="GPU_TdrDelay_Nvidia"; Title="GPU Timeout Detection (TDR) -> Extended"; Category="GPU"; Group="NVIDIA GPU"; Tag="REG"; Desc="Extends the driver timeout from 2s to 8s (works for any GPU vendor) so heavy frames don't trigger a driver reset/crash."}
    @{Key="GPU_NvidiaPowerMode";Title="NVIDIA Power Mode -> Prefer Max Performance"; Category="GPU"; Group="NVIDIA GPU"; Tag="REG"; Desc="NVIDIA (green) only. Sets PowerMizer to Prefer Maximum Performance so the GPU doesn't downclock between frames. Skipped automatically if no NVIDIA GPU is detected."}
    @{Key="GPU_NvidiaTelemetryOff";Title="NVIDIA Telemetry Service -> Disabled"; Category="GPU"; Group="NVIDIA GPU"; Tag="SVC"; Desc="NVIDIA (green) only. Disables the NvTelemetryContainer service. Skipped automatically if no NVIDIA GPU is detected."}
    @{Key="GPU_NvidiaMSIMode";  Title="NVIDIA MSI Mode -> Enabled";       Category="GPU"; Group="NVIDIA GPU"; Tag="REG"; Desc="NVIDIA (green) only. Switches the GPU from line-based to Message-Signaled Interrupts, cutting interrupt/DPC latency for smoother frame delivery. Skipped automatically if no NVIDIA GPU is detected."}
    @{Key="GPU_NvidiaOverlayOff";Title="NVIDIA In-Game Overlay -> Disabled"; Category="GPU"; Group="NVIDIA GPU"; Tag="REG"; Desc="NVIDIA (green) only. Disables the ShadowPlay/GeForce Experience in-game overlay so its input hook and capture pipeline stop eating frame time in the background. Skipped automatically if no NVIDIA GPU is detected."}

    @{Key="GPU_TdrDelay_Amd";    Title="GPU Timeout Detection (TDR) -> Extended"; Category="GPU"; Group="AMD GPU"; Tag="REG"; Desc="Extends the driver timeout from 2s to 8s (works for any GPU vendor) so heavy frames don't trigger a driver reset/crash."}
    @{Key="GPU_AmdUlps";       Title="AMD ULPS -> Disabled";              Category="GPU"; Group="AMD GPU"; Tag="REG"; Desc="AMD (red) only. Disables Ultra Low Power State, a known cause of micro-stutter/black screens on some Radeon cards. Skipped automatically if no AMD GPU is detected."}
    @{Key="GPU_AmdEventsUtil"; Title="AMD External Events Utility -> Disabled"; Category="GPU"; Group="AMD GPU"; Tag="SVC"; Desc="AMD (red) only. Disables the AMD External Events Utility service, commonly cited as a source of periodic stutter. Skipped automatically if no AMD GPU is detected."}
    @{Key="GPU_AmdMSIMode";    Title="AMD MSI Mode -> Enabled";           Category="GPU"; Group="AMD GPU"; Tag="REG"; Desc="AMD (red) only. Switches the GPU from line-based to Message-Signaled Interrupts, cutting interrupt/DPC latency for smoother frame delivery. Skipped automatically if no AMD GPU is detected."}
    @{Key="GPU_AmdCrashDefenderOff";Title="AMD Crash Defender -> Disabled"; Category="GPU"; Group="AMD GPU"; Tag="SVC"; Desc="AMD (red) only. Disables the background driver-crash monitoring service so it stops polling in the background during a match. Skipped automatically if no AMD GPU is detected."}

    @{Key="GPU_ClearShaderCache"; Title="Clear Shader Cache (NVIDIA/AMD, Auto-Detect)"; Category="GPU"; Group="GPU & CACHE"; Tag="WMI"; Desc="Deletes cached compiled shaders for whichever GPU vendor's folders are found, forcing a fresh compile on next launch. Can fix stutter or corrupted shader artifacts, but the first load after clearing will be slower while shaders recompile."}
    @{Key="CLEAN_ClearTempJunk";  Title="Clear Temp & Junk Files";           Category="Cleanup"; Group="GPU & CACHE"; Tag="WMI"; Desc="Empties the Windows and user Temp folders of leftover files to free disk space. Skips anything currently locked/in use."}
    @{Key="CLEAN_ClearFiveMCache";Title="Clear FiveM Cache";                 Category="Cleanup"; Group="GPU & CACHE"; Tag="WMI"; Desc="Deletes FiveM's local cache folder so the client re-downloads fresh server assets on next connect. Useful if streamed textures/models got corrupted. Skipped if FiveM isn't installed."}
    @{Key="CLEAN_RemoveBloat";    Title="Remove Unnecessary Pre-Installed Apps"; Category="Cleanup"; Group="GPU & CACHE"; Tag="APPX"; Desc="Uninstalls a curated list of non-essential pre-installed Windows apps (Xbox extras, 3D Viewer, Mixed Reality Portal, Skype, etc.) for the current user to free up RAM/disk. Core system apps and anything not found are left alone/skipped."}
)
function Get-SystemInfo {
    $info = @{}
    try {
        $os=Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue
        if($os){
            $cap=$os.Caption -replace "Microsoft\s*","" -replace "\s+"," "
            $cap=$cap.Trim()
            # Keep it short: e.g. "Windows 10 IoT Enterprise LTSC 2021" -> "Windows 10 IoT Enterprise"
            if($cap -match "^(Windows\s+\S+(\s+IoT)?(\s+Enterprise|\s+Pro|\s+Home)?)"){ $info.OS=$Matches[1].Trim() } else { $info.OS=$cap }
        } else { $info.OS="Windows" }
    } catch { $info.OS="Windows" }
    try { $cpu=Get-CimInstance Win32_Processor -EA SilentlyContinue|Select -First 1; $info.CPU=if($cpu){($cpu.Name -replace "\(R\)|\(TM\)|CPU|Processor","").Trim()}else{"Unknown CPU"} } catch { $info.CPU="Unknown CPU" }
    try { $gpu=Get-CimInstance Win32_VideoController -EA SilentlyContinue|Select -First 1; $info.GPU=if($gpu){$gpu.Name}else{"Unknown GPU"} } catch { $info.GPU="Unknown GPU" }
    try { $ram=Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue; $info.RAM=if($ram){[math]::Round($ram.TotalPhysicalMemory/1GB)}else{16}; $info.RAMType="DDR4" } catch { $info.RAM=16; $info.RAMType="DDR4" }
    try { $net=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up"}|Select -First 1; if($net){$info.Adapter=$net.InterfaceDescription; $info.NetType=if($net.InterfaceDescription -match "Wi-Fi|Wireless"){"Wi-Fi"}else{"Ethernet"}}else{$info.Adapter="No Adapter";$info.NetType="None"} } catch { $info.Adapter="Ethernet";$info.NetType="Ethernet" }
    try { $freeRam=(Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue).FreePhysicalMemory; $totalRam=(Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue).TotalPhysicalMemory/1KB; if($freeRam -and $totalRam){$info.RAMUsedPct=[math]::Round((($totalRam-$freeRam)/$totalRam)*100)}else{$info.RAMUsedPct=45} } catch { $info.RAMUsedPct=45 }
    return $info
}
$Global:SysInfo = Get-SystemInfo
$mainXamlStr = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SYNC PROJECT" Height="700" Width="1080" MinHeight="560" MinWidth="900"
        WindowStartupLocation="CenterScreen" Background="Transparent" FontFamily="Segoe UI"
        UseLayoutRounding="True" SnapsToDevicePixels="True"
        WindowStyle="None" AllowsTransparency="True" ResizeMode="CanResize">
  <Window.Resources>
    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="6"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Grid Background="Transparent">
              <Track x:Name="PART_Track" IsDirectionReversed="True">
                <Track.DecreaseRepeatButton><RepeatButton Command="ScrollBar.PageUpCommand" Opacity="0" Focusable="False"/></Track.DecreaseRepeatButton>
                <Track.IncreaseRepeatButton><RepeatButton Command="ScrollBar.PageDownCommand" Opacity="0" Focusable="False"/></Track.IncreaseRepeatButton>
                <Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType="Thumb"><Border Background="#5B21B6" CornerRadius="3" Margin="2,0"/></ControlTemplate></Thumb.Template></Thumb></Track.Thumb>
              </Track>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="ToggleStyle" TargetType="CheckBox">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border x:Name="Track" Width="38" Height="20" CornerRadius="10" Background="#1E1630" BorderBrush="#3A2854" BorderThickness="1">
              <Border x:Name="Thumb" Width="14" Height="14" CornerRadius="7" Background="#3D2D5C" HorizontalAlignment="Left" Margin="2,0,0,0"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Track" Property="Background" Value="#5B21B6"/>
                <Setter TargetName="Track" Property="BorderBrush" Value="#7C3AED"/>
                <Setter TargetName="Thumb" Property="Background" Value="#FFFFFF"/>
                <Setter TargetName="Thumb" Property="HorizontalAlignment" Value="Right"/>
                <Setter TargetName="Thumb" Property="Margin" Value="0,0,2,0"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>
  <Border BorderThickness="1" CornerRadius="16" BorderBrush="#2A1F42">
    <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#0E0B1A" Offset="0"/><GradientStop Color="#080612" Offset="1"/></LinearGradientBrush></Border.Background>
    <Grid x:Name="RootGrid">
      <Grid.Clip><RectangleGeometry x:Name="RootClipGeom" Rect="0,0,1078,698" RadiusX="15" RadiusY="15"/></Grid.Clip>
      <Image x:Name="MainLogoWatermark" Width="560" Height="560" Stretch="Uniform" Opacity="0.05" HorizontalAlignment="Center" VerticalAlignment="Center" IsHitTestVisible="False" SnapsToDevicePixels="True"/>
      <Canvas x:Name="MainBgCanvas" IsHitTestVisible="False" CacheMode="BitmapCache">
        <Ellipse Width="500" Height="380" Canvas.Left="-100" Canvas.Top="320"><Ellipse.Fill><RadialGradientBrush><GradientStop Color="#221A0040" Offset="0"/><GradientStop Color="#00000000" Offset="1"/></RadialGradientBrush></Ellipse.Fill></Ellipse>
        <Ellipse Width="450" Height="340" Canvas.Left="680" Canvas.Top="360"><Ellipse.Fill><RadialGradientBrush><GradientStop Color="#333B0060" Offset="0"/><GradientStop Color="#00000000" Offset="1"/></RadialGradientBrush></Ellipse.Fill></Ellipse>
      </Canvas>
      <Grid>
        <Grid.RowDefinitions><RowDefinition Height="52"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
        <!-- TOP BAR -->
        <Grid Grid.Row="0" Margin="16,0,12,0" Background="Transparent" x:Name="TopBar">
          <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
          <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
            <Border Width="28" Height="28" CornerRadius="8" Margin="0,0,9,0" Background="#1E1430" BorderBrush="#3D2D5C" BorderThickness="1">
              <TextBlock Text="S" Foreground="#9B5DE5" FontSize="14" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <TextBlock Text="SYNC" FontSize="14" FontWeight="Bold" Foreground="#FFFFFF" VerticalAlignment="Center"/>
            <TextBlock Text=" PROJECT" FontSize="14" Foreground="#6B7280" VerticalAlignment="Center"/>
          </StackPanel>
          <Border Grid.Column="1" Background="#0F0C1A" CornerRadius="20" BorderBrush="#2A1F42" BorderThickness="1" Height="32" Width="240" HorizontalAlignment="Center" VerticalAlignment="Center">
            <Grid Margin="12,0">
              <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <TextBlock Grid.Column="0" Text="&#x2315;" Foreground="#4B5563" FontSize="14" VerticalAlignment="Center" Margin="0,0,8,0"/>
              <Grid Grid.Column="1">
                <TextBlock x:Name="SearchPlaceholder" Text="Search tweaks..." Foreground="#3D3450" FontSize="11" VerticalAlignment="Center" IsHitTestVisible="False"/>
                <TextBox x:Name="SearchBox" Background="Transparent" Foreground="#D1D5DB" FontSize="11" BorderThickness="0" VerticalContentAlignment="Center" CaretBrush="#9B5DE5"/>
              </Grid>
            </Grid>
          </Border>
          <StackPanel Grid.Column="2" Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
            <Border Background="#130F20" CornerRadius="16" Padding="12,5" Margin="0,0,12,0" BorderBrush="#2A1F42" BorderThickness="1">
              <StackPanel Orientation="Horizontal">
                <Ellipse x:Name="StatusDotEllipse" Width="7" Height="7" Fill="#9B5DE5" VerticalAlignment="Center" Margin="0,0,7,0"/>
                <TextBlock x:Name="StatusText" Text="READY" Foreground="#D1D5DB" FontSize="10" FontWeight="SemiBold" VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
            <Button x:Name="BtnMin" Content="&#8212;" Width="26" Height="26" Background="Transparent" Foreground="#6B7280" BorderThickness="0" Margin="0,0,2,0" Cursor="Hand"/>
            <Button x:Name="BtnMax" Content="&#9633;" Width="26" Height="26" Background="Transparent" Foreground="#6B7280" FontSize="10" BorderThickness="0" Margin="0,0,2,0" Cursor="Hand"/>
            <Button x:Name="BtnClose" Content="&#10005;" Width="26" Height="26" Background="Transparent" Foreground="#6B7280" BorderThickness="0" Cursor="Hand"/>
          </StackPanel>
        </Grid>
        <!-- HEADER -->
        <Grid Grid.Row="1" Margin="20,8,20,8">
          <StackPanel HorizontalAlignment="Left">
            <TextBlock FontSize="8.5" FontWeight="SemiBold" Margin="0,0,0,3">
              <Run Text="SYSTEM" Foreground="#374151"/>
            </TextBlock>
            <TextBlock Text="AVAILABLE TWEAKS" FontSize="20" FontWeight="Bold" Foreground="#FFFFFF"/>
          </StackPanel>
        </Grid>
        <!-- BODY -->
        <Grid Grid.Row="2" Margin="16,0,16,16">
          <Grid.ColumnDefinitions><ColumnDefinition Width="270"/><ColumnDefinition Width="12"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <!-- LEFT PANEL -->
          <Border Grid.Column="0" CornerRadius="14" BorderBrush="#2A1F42" BorderThickness="1" Padding="14">
            <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#120E1E" Offset="0"/><GradientStop Color="#0C0A16" Offset="1"/></LinearGradientBrush></Border.Background>
            <DockPanel>
              <TextBlock DockPanel.Dock="Top" Text="STAGES" Foreground="#9CA3AF" FontSize="9" FontWeight="SemiBold" Margin="2,0,0,10"/>
              <StackPanel DockPanel.Dock="Bottom">
                <Border Height="1" Background="#1F1633" Margin="0,6,0,8"/>
                <TextBlock Text="PROGRESS" Foreground="#4B5563" FontSize="8" FontWeight="SemiBold" Margin="0,0,0,4"/>
                <Grid Margin="0,0,0,2">
                  <Border Background="#0A0814" CornerRadius="4" Height="5">
                    <Border x:Name="ProgressFill" CornerRadius="4" HorizontalAlignment="Left" Width="0">
                      <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,0"><GradientStop Color="#5B21B6" Offset="0"/><GradientStop Color="#9B5DE5" Offset="1"/></LinearGradientBrush></Border.Background>
                    </Border>
                  </Border>
                </Grid>
                <TextBlock x:Name="ProgressPercent" Text="0%" Foreground="#4B5563" FontSize="8" Margin="0,2,0,10"/>
                <TextBlock Text="NET" Foreground="#4B5563" FontSize="7.5" FontWeight="SemiBold" Margin="0,0,0,4"/>
                <Grid Margin="0,0,0,8">
                  <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="7"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <Button x:Name="NetPresetLan" Grid.Column="0" Height="30" Cursor="Hand" BorderThickness="0" ToolTip="Enable all wired LAN network tweaks and disable all Wi-Fi tweaks"><Button.Template><ControlTemplate TargetType="Button"><Border x:Name="Bd" CornerRadius="7" Background="#0F0C1A" BorderBrush="#2A1F42" BorderThickness="1"><StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center"><TextBlock Text="&#9889; " FontSize="10" Foreground="#38BDF8"/><TextBlock Text="LAN" Foreground="#D1D5DB" FontSize="10" FontWeight="SemiBold"/></StackPanel></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#38BDF8"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Button.Template></Button>
                  <Button x:Name="NetPresetWifi" Grid.Column="2" Height="30" Cursor="Hand" BorderThickness="0" ToolTip="Enable all Wi-Fi network tweaks and disable all wired LAN tweaks"><Button.Template><ControlTemplate TargetType="Button"><Border x:Name="Bd" CornerRadius="7" Background="#0F0C1A" BorderBrush="#2A1F42" BorderThickness="1"><StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center"><TextBlock Text="&#9889; " FontSize="10" Foreground="#2DD4BF"/><TextBlock Text="WI-FI" Foreground="#D1D5DB" FontSize="10" FontWeight="SemiBold"/></StackPanel></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#2DD4BF"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Button.Template></Button>
                </Grid>
                <TextBlock Text="GPU" Foreground="#4B5563" FontSize="7.5" FontWeight="SemiBold" Margin="0,0,0,4"/>
                <Grid Margin="0,0,0,8">
                  <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="7"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <Button x:Name="GpuPresetAmd" Grid.Column="0" Height="30" Cursor="Hand" BorderThickness="0" ToolTip="Enable all AMD GPU tweaks and disable all NVIDIA GPU tweaks"><Button.Template><ControlTemplate TargetType="Button"><Border x:Name="Bd" CornerRadius="7" Background="#0F0C1A" BorderBrush="#2A1F42" BorderThickness="1"><StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center"><TextBlock Text="&#9670; " FontSize="10" Foreground="#ED1C24"/><TextBlock Text="AMD" Foreground="#D1D5DB" FontSize="10" FontWeight="SemiBold"/></StackPanel></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#ED1C24"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Button.Template></Button>
                  <Button x:Name="GpuPresetNvidia" Grid.Column="2" Height="30" Cursor="Hand" BorderThickness="0" ToolTip="Enable all NVIDIA GPU tweaks and disable all AMD GPU tweaks"><Button.Template><ControlTemplate TargetType="Button"><Border x:Name="Bd" CornerRadius="7" Background="#0F0C1A" BorderBrush="#2A1F42" BorderThickness="1"><StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center"><TextBlock Text="&#9670; " FontSize="10" Foreground="#76B900"/><TextBlock Text="NVIDIA" Foreground="#D1D5DB" FontSize="10" FontWeight="SemiBold"/></StackPanel></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#76B900"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Button.Template></Button>
                </Grid>
                <TextBlock Text="PRESET" Foreground="#4B5563" FontSize="7.5" FontWeight="SemiBold" Margin="0,0,0,4"/>
                <Button x:Name="BtnPresetAllExceptGpuLan" Height="30" Cursor="Hand" BorderThickness="0" Margin="0,0,0,8" ToolTip="Enable every tweak except GPU (incl. shader cache) and network (LAN/Wi-Fi) tweaks, which get turned off">
                  <Button.Template><ControlTemplate TargetType="Button"><Border x:Name="Bd" CornerRadius="7" Background="#0F0C1A" BorderBrush="#2A1F42" BorderThickness="1"><StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center"><TextBlock Text="&#9733; " FontSize="12" Foreground="#FBBF24" VerticalAlignment="Center"/><TextBlock Text="Select All (No GPU / Net)" Foreground="#D1D5DB" FontSize="12" FontWeight="SemiBold" VerticalAlignment="Center"/></StackPanel></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#FBBF24"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Button.Template>
                </Button>
                <Button x:Name="BtnRun" Height="44" FontSize="11.5" FontWeight="Bold" Foreground="#FFFFFF" Cursor="Hand" BorderThickness="0" Margin="0,0,0,7">
                  <Button.Template>
                    <ControlTemplate TargetType="Button">
                      <Border x:Name="RunBorder" CornerRadius="10">
                        <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,0"><GradientStop Color="#4C1D95" Offset="0"/><GradientStop Color="#7C3AED" Offset="0.5"/><GradientStop Color="#9B5DE5" Offset="1"/></LinearGradientBrush></Border.Background>
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                          <TextBlock Text="&#x25B6;  " Foreground="#E9D5FF" FontSize="9" VerticalAlignment="Center"/>
                          <TextBlock Text="RUN SYNC PROJECT" Foreground="#FFFFFF" FontSize="11.5" FontWeight="Bold" VerticalAlignment="Center"/>
                        </StackPanel>
                      </Border>
                      <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="RunBorder" Property="Opacity" Value="0.85"/></Trigger>
                        <Trigger Property="IsPressed" Value="True"><Setter TargetName="RunBorder" Property="Opacity" Value="0.72"/></Trigger>
                      </ControlTemplate.Triggers>
                    </ControlTemplate>
                  </Button.Template>
                </Button>
                <Grid Margin="0,0,0,6">
                  <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="7"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <Button x:Name="BtnRestore" Grid.Column="0" Height="30" Cursor="Hand" BorderThickness="0">
                    <Button.Template><ControlTemplate TargetType="Button"><Border x:Name="Bd" CornerRadius="7" Background="#0F0C1A" BorderBrush="#2A1F42" BorderThickness="1"><StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center"><TextBlock Text="&#8635; " Foreground="#9CA3AF" FontSize="13" VerticalAlignment="Center"/><TextBlock Text="Restore" Foreground="#D1D5DB" FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center"/></StackPanel></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#5B21B6"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Button.Template>
                  </Button>
                  <Button x:Name="BtnClear" Grid.Column="2" Height="30" Cursor="Hand" BorderThickness="0">
                    <Button.Template><ControlTemplate TargetType="Button"><Border x:Name="Bd" CornerRadius="7" Background="#0F0C1A" BorderBrush="#2A1F42" BorderThickness="1"><StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center"><TextBlock Text="&#x2715; " Foreground="#9CA3AF" FontSize="13" VerticalAlignment="Center"/><TextBlock Text="Clear" Foreground="#D1D5DB" FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center"/></StackPanel></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#5B21B6"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Button.Template>
                  </Button>
                </Grid>
                <Grid>
                  <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="7"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <Button x:Name="BtnDiscord" Grid.Column="0" Height="30" Cursor="Hand" BorderThickness="0">
                    <Button.Template><ControlTemplate TargetType="Button"><Border x:Name="Bd" CornerRadius="8" Background="#0F0C1A" BorderBrush="#2A1F42" BorderThickness="1"><TextBlock Text="Join Discord" Foreground="#9CA3AF" FontSize="13" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#5B21B6"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Button.Template>
                  </Button>
                  <Button x:Name="BtnExit" Grid.Column="2" Height="30" Width="60" Cursor="Hand" BorderThickness="0">
                    <Button.Template><ControlTemplate TargetType="Button"><Border x:Name="Bd" CornerRadius="8" Background="#1A0F0F" BorderBrush="#3D1515" BorderThickness="1"><TextBlock Text="EXIT" Foreground="#EF4444" FontSize="13" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#EF4444"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Button.Template>
                  </Button>
                </Grid>
              </StackPanel>
              <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,0,0,4" Padding="0,0,3,0">
                <StackPanel x:Name="StagesPanel" Margin="0,0,0,8"/>
              </ScrollViewer>
            </DockPanel>
          </Border>
          <!-- RIGHT PANEL -->
          <Grid Grid.Column="2">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <!-- STATUS OVERLAY -->
            <Border Grid.Row="0" CornerRadius="14" BorderBrush="#2A1F42" BorderThickness="1" Padding="18,14" Margin="0,0,0,10">
              <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#120E1E" Offset="0"/><GradientStop Color="#0C0A16" Offset="1"/></LinearGradientBrush></Border.Background>
              <StackPanel>
                <TextBlock Text="SYSTEM INFO" Foreground="#9CA3AF" FontSize="8.5" FontWeight="SemiBold" Margin="0,0,0,12"/>
                <Grid Margin="0,0,0,10">
                  <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <StackPanel Grid.Column="0" Margin="0,0,6,0"><TextBlock Text="OS" Foreground="#374151" FontSize="7.5" FontWeight="SemiBold" Margin="0,0,0,3"/><TextBlock x:Name="InfoOS" Text="Windows" Foreground="#E5E7EB" FontSize="11.5" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/></StackPanel>
                  <StackPanel Grid.Column="1"><TextBlock Text="CPU" Foreground="#374151" FontSize="7.5" FontWeight="SemiBold" Margin="0,0,0,3"/><TextBlock x:Name="InfoCPU" Text="CPU" Foreground="#E5E7EB" FontSize="11.5" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/></StackPanel>
                  <StackPanel Grid.Column="2"><TextBlock Text="GPU" Foreground="#374151" FontSize="7.5" FontWeight="SemiBold" Margin="0,0,0,3"/><TextBlock x:Name="InfoGPU" Text="GPU" Foreground="#E5E7EB" FontSize="11.5" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/></StackPanel>
                  <StackPanel Grid.Column="3"><TextBlock Text="NET" Foreground="#374151" FontSize="7.5" FontWeight="SemiBold" Margin="0,0,0,3"/><TextBlock x:Name="InfoNET" Text="Ethernet" Foreground="#E5E7EB" FontSize="11.5" FontWeight="SemiBold"/></StackPanel>
                </Grid>
                <Grid Margin="0,0,0,14">
                  <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <StackPanel Grid.Column="0"><TextBlock Text="RAM" Foreground="#374151" FontSize="7.5" FontWeight="SemiBold" Margin="0,0,0,3"/><TextBlock x:Name="InfoRAM" Text="16 GB" Foreground="#E5E7EB" FontSize="11.5" FontWeight="SemiBold"/></StackPanel>
                  <StackPanel Grid.Column="1"><TextBlock Text="ADAPTER" Foreground="#374151" FontSize="7.5" FontWeight="SemiBold" Margin="0,0,0,3"/><TextBlock x:Name="InfoAdapter" Text="Ethernet" Foreground="#E5E7EB" FontSize="11.5" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/></StackPanel>
                </Grid>
                <Grid>
                  <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <TextBlock Grid.Column="0" Text="RAM USAGE" Foreground="#374151" FontSize="7.5" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,10,0"/>
                  <Border Grid.Column="1" Background="#0A0814" CornerRadius="3" Height="5" VerticalAlignment="Center">
                    <Border x:Name="RamUsageFill" CornerRadius="3" HorizontalAlignment="Left" Width="0">
                      <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,0"><GradientStop Color="#5B21B6" Offset="0"/><GradientStop Color="#9B5DE5" Offset="1"/></LinearGradientBrush></Border.Background>
                    </Border>
                  </Border>
                  <TextBlock x:Name="RamUsageText" Grid.Column="2" Text="0%" Foreground="#6B7280" FontSize="8.5" VerticalAlignment="Center" Margin="8,0,0,0"/>
                </Grid>
              </StackPanel>
            </Border>
            <!-- QUICK TOOLS -->
            <Border Grid.Row="1" CornerRadius="14" BorderBrush="#2A1F42" BorderThickness="1" Padding="18,12" Margin="0,0,0,10">
              <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#120E1E" Offset="0"/><GradientStop Color="#0C0A16" Offset="1"/></LinearGradientBrush></Border.Background>
              <StackPanel>
                <TextBlock Text="QUICK TOOLS" Foreground="#9CA3AF" FontSize="8.5" FontWeight="SemiBold" Margin="0,0,0,10"/>
                <StackPanel Orientation="Horizontal">
                  <Button x:Name="BtnTaskMgr" Height="32" Cursor="Hand" BorderThickness="0" Margin="0,0,8,0"><Button.Template><ControlTemplate TargetType="Button"><Border x:Name="Bd" CornerRadius="7" Background="#0F0C1A" BorderBrush="#2A1F42" BorderThickness="1" Padding="14,0"><TextBlock Text="Task Manager" Foreground="#D1D5DB" FontSize="11.5" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#5B21B6"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Button.Template></Button>
                  <Button x:Name="BtnGpedit" Height="32" Cursor="Hand" BorderThickness="0" Margin="0,0,8,0"><Button.Template><ControlTemplate TargetType="Button"><Border x:Name="Bd" CornerRadius="7" Background="#0F0C1A" BorderBrush="#2A1F42" BorderThickness="1" Padding="14,0"><TextBlock Text="Group Policy Editor" Foreground="#D1D5DB" FontSize="11.5" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#5B21B6"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Button.Template></Button>
                  <Button x:Name="BtnClean" Height="32" Cursor="Hand" BorderThickness="0"><Button.Template><ControlTemplate TargetType="Button"><Border x:Name="Bd" CornerRadius="7" Background="#0F0C1A" BorderBrush="#2A1F42" BorderThickness="1" Padding="14,0"><TextBlock Text="Clean" Foreground="#D1D5DB" FontSize="11.5" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#5B21B6"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Button.Template></Button>
                </StackPanel>
              </StackPanel>
            </Border>
            <!-- OUTPUT LOG -->
            <Border Grid.Row="2" CornerRadius="14" BorderBrush="#2A1F42" BorderThickness="1" Padding="18,14" Margin="0,0,0,10">
              <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#120E1E" Offset="0"/><GradientStop Color="#0C0A16" Offset="1"/></LinearGradientBrush></Border.Background>
              <DockPanel>
                <TextBlock DockPanel.Dock="Top" Text="OUTPUT LOG" Foreground="#9CA3AF" FontSize="8.5" FontWeight="SemiBold" Margin="0,0,0,10"/>
                <ScrollViewer x:Name="LogScrollViewer" VerticalScrollBarVisibility="Auto">
                  <TextBlock x:Name="LogBox" Foreground="#4B5563" FontSize="11" FontFamily="Consolas" TextWrapping="Wrap" LineHeight="19"/>
                </ScrollViewer>
              </DockPanel>
            </Border>
            <!-- CURRENT TASK -->
            <Border Grid.Row="3" CornerRadius="12" BorderBrush="#2A1F42" BorderThickness="1" Padding="18,10">
              <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#120E1E" Offset="0"/><GradientStop Color="#0C0A16" Offset="1"/></LinearGradientBrush></Border.Background>
              <StackPanel>
                <TextBlock Text="CURRENT TASK" Foreground="#374151" FontSize="8" FontWeight="SemiBold"/>
                <TextBlock x:Name="CurrentTaskText" Text="Waiting to start..." Foreground="#9CA3AF" FontSize="11.5" Margin="0,3,0,0"/>
              </StackPanel>
            </Border>
            <!-- CATEGORY DETAIL OVERLAY -->
            <Border x:Name="CategoryOverlay" Grid.Row="0" Grid.RowSpan="4" CornerRadius="14" BorderBrush="#2A1F42" BorderThickness="1" Padding="22,18" Visibility="Collapsed">
              <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#0E0B1A" Offset="0"/><GradientStop Color="#080612" Offset="1"/></LinearGradientBrush></Border.Background>
              <Grid>
              <Grid.Clip><RectangleGeometry x:Name="CatOverlayClipGeom" Rect="0,0,600,600" RadiusX="13" RadiusY="13"/></Grid.Clip>
              <Canvas x:Name="CatOverlayBgCanvas" IsHitTestVisible="False" CacheMode="BitmapCache">
                <Ellipse Width="260" Height="220" Canvas.Left="-60" Canvas.Top="10"><Ellipse.Fill><RadialGradientBrush><GradientStop Color="#221A0040" Offset="0"/><GradientStop Color="#00000000" Offset="1"/></RadialGradientBrush></Ellipse.Fill></Ellipse>
                <Ellipse Width="240" Height="200" Canvas.Left="260" Canvas.Top="360"><Ellipse.Fill><RadialGradientBrush><GradientStop Color="#333B0060" Offset="0"/><GradientStop Color="#00000000" Offset="1"/></RadialGradientBrush></Ellipse.Fill></Ellipse>
              </Canvas>
              <Grid>
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                <Grid Grid.Row="0">
                  <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <TextBlock Grid.Column="0" x:Name="CatOverlayTitle" Text="CATEGORY" FontSize="15" FontWeight="Bold" Foreground="#FFFFFF" VerticalAlignment="Center"/>
                  <Button Grid.Column="1" x:Name="CatOverlayCloseX" Content="&#10005;" Width="26" Height="26" Background="Transparent" Foreground="#6B7280" FontSize="12" BorderThickness="0" Cursor="Hand"/>
                </Grid>
                <TextBlock Grid.Row="1" x:Name="CatOverlayDesc" Text="" Foreground="#9CA3AF" FontSize="11" TextWrapping="Wrap" Margin="0,8,0,16"/>
                <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto">
                  <StackPanel x:Name="CatOverlayItems"/>
                </ScrollViewer>
                <Button Grid.Row="3" x:Name="CatOverlayCloseBtn" Height="42" Margin="0,16,0,0" Background="#FFFFFF" Foreground="#0C0A16" FontWeight="Bold" FontSize="11.5" BorderThickness="0" Cursor="Hand" Content="CLOSE"/>
              </Grid>
              </Grid>
            </Border>
          </Grid>
        </Grid>
      </Grid>
    </Grid>
  </Border>
</Window>
"@

# =========================================================
# SPLASH HELPER FUNCTIONS (chime sounds, click FX, background aura)
# =========================================================
# [console]::Beep() blocks the calling thread for the full note duration. Called directly
# on the UI thread it froze the window for ~0.4-1s (the reported "START hangs for 1-3s" bug).
# Running the beep sequence on a background thread keeps the UI fully responsive.
function Invoke-BeepSequenceAsync([scriptblock]$Beeps) {
    try {
        $ps = [PowerShell]::Create()
        [void]$ps.AddScript($Beeps.ToString())
        # BeginInvoke() runs on a threadpool thread and returns immediately -
        # the UI thread never blocks waiting for the beeps to finish.
        [void]$ps.BeginInvoke()
    } catch {}
}

function Play-CompletionChime {
    try {
        [System.Media.SystemSounds]::Asterisk.Play()
    } catch {}
    Invoke-BeepSequenceAsync {
        [console]::Beep(1046,110)
        [console]::Beep(1318,110)
        [console]::Beep(1568,160)
    }
}

function Play-StartupChime {
    # Distinct "power-on" chime for the splash START button - a soft rising sweep,
    # separate from the completion chime so the two moments feel different.
    try {
        [System.Media.SystemSounds]::Beep.Play()
    } catch {}
    Invoke-BeepSequenceAsync {
        [console]::Beep(523,90)
        [console]::Beep(659,90)
        [console]::Beep(784,90)
        [console]::Beep(1046,200)
    }
}

# ---------- Lightweight "premium" aura for the splash card: a soft breathing glow behind the ----------
# ---------- title + a handful of slow, faint drifting particles. No lightning, no busy grid   ----------
# ---------- - just enough motion/light to give the flat card some dimension.                  ----------
function New-SplashAura {
    param(
        $Canvas,
        [double]$Width = 360,
        [double]$Height = 330,
        [double]$CenterX = 180,
        [double]$CenterY = 110,
        [int]$ParticleCount = 9
    )
    try {
        $rnd = New-Object System.Random

        # ---- One very soft, faint ambient glow behind everything (keeps things clean, not busy) ----
        $ambientBrush = New-Object System.Windows.Media.RadialGradientBrush
        [void]$ambientBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(35,140,90,230)), 0))
        [void]$ambientBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,140,90,230)), 1))
        $ambient = New-Object System.Windows.Shapes.Ellipse
        $ambient.Width = $Width * 0.85
        $ambient.Height = $Width * 0.85
        $ambient.Fill = $ambientBrush
        [System.Windows.Controls.Canvas]::SetLeft($ambient, $CenterX - ($ambient.Width / 2))
        [System.Windows.Controls.Canvas]::SetTop($ambient, $CenterY - ($ambient.Height / 2))
        [void]$Canvas.Children.Add($ambient)

        # ---- Clean constellation network: sparse nodes linked by thin, faint lines ----
        $nodeCount = [Math]::Max($ParticleCount + 5, 14)
        $nodes = @()
        for ($n = 0; $n -lt $nodeCount; $n++) {
            $nodes += [PSCustomObject]@{
                X = $rnd.Next(6, [int]($Width - 6))
                Y = $rnd.Next(6, [int]($Height - 6))
            }
        }

        $linkDist = $Width * 0.30
        for ($a = 0; $a -lt $nodes.Count; $a++) {
            for ($b = $a + 1; $b -lt $nodes.Count; $b++) {
                $dx = $nodes[$a].X - $nodes[$b].X
                $dy = $nodes[$a].Y - $nodes[$b].Y
                $dist = [Math]::Sqrt(($dx * $dx) + ($dy * $dy))
                if ($dist -le $linkDist) {
                    $line = New-Object System.Windows.Shapes.Line
                    $line.X1 = $nodes[$a].X; $line.Y1 = $nodes[$a].Y
                    $line.X2 = $nodes[$b].X; $line.Y2 = $nodes[$b].Y
                    $lineAlpha = 18 + ((1 - ($dist / $linkDist)) * 34)
                    $line.Stroke = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb([byte]$lineAlpha,140,110,220))
                    $line.StrokeThickness = 0.7
                    [void]$Canvas.Children.Add($line)
                }
            }
        }

        foreach ($node in $nodes) {
            $dotSize = 2 + ($rnd.NextDouble() * 1.6)
            $isBright = ($rnd.NextDouble() -gt 0.72)
            $dot = New-Object System.Windows.Shapes.Ellipse
            $dot.Width = $dotSize
            $dot.Height = $dotSize
            if ($isBright) {
                $dot.Fill = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(235,210,185,255))
            } else {
                $dot.Fill = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(170,150,120,220))
            }
            [System.Windows.Controls.Canvas]::SetLeft($dot, $node.X - ($dotSize / 2))
            [System.Windows.Controls.Canvas]::SetTop($dot, $node.Y - ($dotSize / 2))
            [void]$Canvas.Children.Add($dot)

            $twinkle = New-Object System.Windows.Media.Animation.DoubleAnimation
            $twinkle.From = 0.35 + ($rnd.NextDouble() * 0.2)
            $twinkle.To = 0.8 + ($rnd.NextDouble() * 0.2)
            $twinkle.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(2 + $rnd.NextDouble() * 3))
            $twinkle.AutoReverse = $true
            $twinkle.BeginTime = [TimeSpan]::FromSeconds($rnd.NextDouble() * 2)
            $twinkle.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $dot.BeginAnimation([System.Windows.Shapes.Ellipse]::OpacityProperty, $twinkle)
        }
    } catch { }
}

# ---------- Click feedback FX (scale bounce) for main action buttons ----------
function Add-ClickFX($btn) {
    if (-not $btn) { return }
    $btn.RenderTransformOrigin = New-Object -TypeName System.Windows.Point -ArgumentList 0.5,0.5
    $scaleT = New-Object System.Windows.Media.ScaleTransform
    $scaleT.ScaleX = 1; $scaleT.ScaleY = 1
    $btn.RenderTransform = $scaleT

    $btn.Add_PreviewMouseLeftButtonDown({
        $sender = $args[0]
        $down = New-Object System.Windows.Media.Animation.DoubleAnimation
        $down.To = 0.92
        $down.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds(70))
        $sender.RenderTransform.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $down)
        $sender.RenderTransform.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $down)
    })
    $btn.Add_PreviewMouseLeftButtonUp({
        $sender = $args[0]
        $up = New-Object System.Windows.Media.Animation.DoubleAnimation
        $up.To = 1.0
        $up.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds(150))
        $bounce = New-Object System.Windows.Media.Animation.BackEase
        $bounce.Amplitude = 0.5
        $up.EasingFunction = $bounce
        $sender.RenderTransform.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $up)
        $sender.RenderTransform.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $up)
    })
}

# ---------- Shared background drift (continuous, automatic - no mouse movement needed) so the ----------
# ---------- Splash screen and the Main Console background move the exact same way.              ----------
function Add-BackgroundParallax {
    param(
        $TargetWindow,
        $Canvas,
        [double]$MaxOffset = 20,
        [double]$DurationX = 9,
        [double]$DurationY = 7
    )
    if (-not $Canvas) { return }
    $translate = New-Object System.Windows.Media.TranslateTransform
    $Canvas.RenderTransform = $translate

    $animX = New-Object System.Windows.Media.Animation.DoubleAnimation
    $animX.From = -$MaxOffset
    $animX.To = $MaxOffset
    $animX.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($DurationX))
    $animX.AutoReverse = $true
    $animX.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
    $animX.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $translate.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $animX)

    $animY = New-Object System.Windows.Media.Animation.DoubleAnimation
    $animY.From = -($MaxOffset * 0.6)
    $animY.To = ($MaxOffset * 0.6)
    $animY.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($DurationY))
    $animY.AutoReverse = $true
    $animY.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
    $animY.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $translate.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $animY)
}

# SPLASH / START SCREEN
# =========================================================
$Global:SplashLogoBase64 = "iVBORw0KGgoAAAANSUhEUgAAAP8AAAEsCAYAAAAM1WX/AAB9r0lEQVR42u29d5wkV3Uv/j3n3KrqnrC7WkkgISRyDsbPYAwGA362AWOTZ8EmSGCSTE5GEmF2AJGjiSYHY8yMwcb2Mzy/IPF+Du/ZgDFGJJOjkISk3Z2Z7q6695zfH/dWd/WEjbO7M7N19SnNdq6uvt+Tz/cQ2nXKLDPjhYUF2rNnT1j52NLS0o0nJiZuCuAsVb0jgJsB2BVC6BBRAUDSUykda/0bAKCqYGYDYOs9RhTvCiEwgPr5x3ORqtJ6l4aZ0TjfsdfV573W61a8R/M21d/RbM2v1rwmzfMiMxu+Nr2+vsFmxs3XNs7BABgRKRGpxTcBM1O6zs57nzGzN7OJEMIHqIXEtgc8AWAASkTDXdjv929XFMXtvff3MrPbENFtvfdnMPNknudcb3gzGx6rdi8RiAhmNgaOBKRNvZrnW3+PQ1xHmNm6zzvU69d6v2N5/cr3aQqa5nvX9xMRFhcXsWvXLlRV9d4rr7zyohb82xz0RBQagL+9c+6BRPQAAHcBcEYN1BrA6e9QUDQ3z8E23GoskB3N5j2B1+eIwNd8vpmtEnArX7+Otl/38eb7Heq1h/vdmkJZVUO3282rqnpvnudPAQDXwmRbgp6ISAEEMysA3Md7f76q/paInFFrvrIs1Tmn6flERBCRoYnMzLWZflRmdvtrnFzLxnsPZoaZhW63m/d6vff/6Ec/eqaZ0d69e6n9gbbRmp+fl9qfP3DgwA273e5MVVW/T0R3L4qCB4MBAARmNhHh2h9cx5/dUmZ8C/ZxIe29h6oaEWmWZa7f77/+b/7mby7es2dPSDEFa8G/PbQ9p2CPmdlpIYTzReRpAG4DAL1ez7IsC8xMIQSuN0kKCB3UH27BvzVWCGHl72ne++Ccy1T1NSJycR04HLp07WXb8sCX2q83s98FMAfgF5O/F9LfoVnf9FGPF/jXsiROtgDZ7AJtI675OsB/s4g8r6kg6ie1Pv/W9u1BRMHMbgrgFd77xzrnAMCHEIiZuQZ5MzhHrbe37VYdnwFgqqrOuazX671vYmLi+WsBvwX/9tD2Twgh7BWR87z3CsCcc5KEwCF9w+Ph429GN+FYrZcT/Z3qzz/cz1VVqKoBUOecW1paesf3vve956XIv62VfWnBv0WBb2ZneO/foap7iAj9ft/neV4XgbTrBAuLk+0uqKqFELQoCtfr9d46NTX1HCKCqnLK/Kz+ju3PvHXM/Abw7xFC+F/OuT29Xi+YWRARqfP07To1VqMIy1RVi6Jwg8Hg3RMTE88xMzoY8FvwbyHgp5LY0Ov1nhBC+G8icueyLKtut8sAWERArTN/yi0isqqqLM9z1+v13vXqV7/66Y140EFzuO1m2QLATyk87vf7ewG8pNPpkKp6ZpbN6K9ud2270df0SLIjdczGe48QgmVZpszslpeXXzc5OXkREVnK7hzSBJT259zUwOcE/Mx7/+48z58bQlBmtvWAn163Uju0F3PjfpMNv6br9U2so+mHUf0QQsiyLCvL8k3dbveFyTXk+93vfofl+7UqYRMDP/6xrNfr/Ylz7km9Xq9yztHJ/t1SZHl4tOvEb48QgnY6nUxV314UxfPNjPfu3Utzc3OH/YO0KmGTmvoAcPnll8uv/dqvvYOZn9Lr9SoREeccHcrkPN5m/6nsVmwCs9/MTEXEVVX1nizLntb0/4/kc1vNv0mB/4UvfMHd6173ehszP6UsS59y94clrJl57NjodbzffzOv4/GdV17PgwE/hGAi4gaDwbsvvfTSC48W+K3m35zAp4WFBXrYwx72NufchWVZeolrLODTrlNrhRCsqirtdDrOe//HWZY9O/n/dDTAB9oin00HfCLSwWDweufchf1+36uq5Hl+SprY7RrX+An4b86y7HkrWreParWafxOZ+kRkg8HglXmev7gsS5/a74Y+fgv8Uw70dbeeOuek3++/pdvtPndld14L/i2u8REbMl7LzC/03nuOq/19NgBAW01wNrIoVlWVdbtdSXn8F22Exh9ake322Bymvqq+oQa+c64F/im+mNnMTLvdriwuLr46AV+Sxt+Q/GoL/pMLfE4+/iuY+XmDwcCrKrcWWQv8EIJmWeZU9XXT09OXJODrsZr6rdm/iTT+4uLiyyYnJ+dCCCHV5tNW9e83U8FP3d++XkXeZry+jfMNKZ33tk6n86z1+vFb8G9N8Dsi8v1+//lZlr0hRG4tEhFqAX/ihMOJvEaH+rwQAqqqgoholmVSluUbiqJ44fECPtCm+k4q8IuieIP3Pqzi2GoBv93M+MPZFwZAsyxzAF5bFMVFyUI8LsBvff6TBPylpaWnZFn2hl6vF1SV6sq9zQ6q7VDLf6KqEo/wOpmZ1QU8byaiizYqndeCfxMB38weY2bvCiEoEW0JU3+7NPCcLCqu9R4LISCEYKk11/V6vbc5515wIoDf+vwnGPje+/PN7L1EJGaGw63VP5GNNCv90+1i4m+2AF/Nq29mmog4XjMxMXHJEJjHGfit5j+xwP8DIvoAAEkMunQkG/dENtK07brH99qGEOCcMwBaFIVbXl7eOzk5eXGtjE8E8FvNf+KA/zgAH6rHJ4kIbeZU03Yi/6iv82ZpQ65ZdolIRcSp6qtE5MXHI4/fav6TDPzBYPBYVX1/Y0gGtTX6p+YKIdT02iYirt/vv/lkAb8F/3EG/vLy8u8B+AAzOzNDnudUt+ZuRq2fTM7D+X4brj2b04I3ioG4eX4nm4MghAAzsxCCMbMsLy+/qtvtPm92dpZPBvCBNs9/3IC/tLT0cOfch4jIIeZqaTODfrutTWhdGTOrc87t37//lTt37nzp/Py8zMzMnBTgt+A/TsDv9XoPcM59lIhyVdWNNvU3yn/djsDfLKBvZk1U1bz3WhSF895funPnzpeeLFO/NfuPD/CFiHxVVfd1zv0ZgAlVDZvVx28j+SfG1A8hGAArisItLS29Kcuyl2wG4ANttH9DNX5VVQ8E8HFm3pnq9Xkz+vibEfgbQTd+Iiv3DqdW33tvzjkTEen3+6/odrsvO561+i34Tx7wfwfAx81siohCLN4Ta4F/6pn7aV+YmalzzoUQXuSce91mAn4L/o0D/v1VdcE5N50GKWxKd2ozA38leA/3XE8U6A+nM685O8/MNMsyF0K4yDn32s1i6rc+/wb6+GVZ3svM/oyZVwF/M4Gt9fFPzDVM3XmWZZkbDAYv3qzAB9po/7EAP5jZr1ZVtZBl2e4QQnDO8eFos2PVVkca7d8KwD+ac9xMgdSqqlCb9M456fV6F09MTLxmswK/NfuPAfhlWd6TiD4lIjdsAv9g5uHJIJNsffwTs7z3ZmaWZZkMBoMXdTqd121m4Lea/yiBPxgM7iIif05ENyzL0hdFsSnL9to8/vG9rvW51Om8LMukqqotAfzW5z+Cddlll7lk6t/BzD5lZueWZelTBd+m00itj3/cFcGYm++ck8FgcFGe51sC+K3Zf+Q+/i8OBoO/KIri5lVVeRGR7VjAc7SR91NB64cQmn8NADnnqKqqP+p0Oq/fbOm8FvwbA/y7VVX1SefcuSEET0SSuvRaU/8UMvdrjZ8KeMDMrKpPd869c6to/Bb8R+bj39E59zcAbuq993mey5EA8ETmojfYpI2b5CT2JG0m4doAvyXtLmVZPqPb7b5jqwG/9fkPT+OfKyILzHzTelT2Zjzf1sc/MYLIzExETEQkhPDMBHy31YAPtNH+QwH/HFX9KxG5bVVVvtPpyOFukq0M/M3QfXyyr+HKz/few3tv9WMhhAvzPH930vhhqwG/Bf9BgL+4uHiWqv4VM/+XOrhXb5LNZoq2vv2JudSJcFW9908piuKD9V7Zqte69fnX1vhnhhD+SkTuWZv6bVvu9gb9WteymcdXVYiImdlTnHMfqPs6tvQ1byG/CvinA/iEiNxzeXnZE5HUc99a4J9S+2F4qUWk9vefloAvWx34reYf/dBMRLp///4zJicnP8HMv+69r5xzm9It2o5c+sfLnTrSkur6PMqyhJlpcvdKInqqc+5DW93Ub33+NYBvZmcA+CSAX6uqqkoz0zadj79dTfzNco0bpr6msu2lqqou6HQ6f7GdgH/Ka/4G8E8DsADgv/b7fZ9lmWxWlt2tqvmPBNwbKXCPppkqjVJjAEuq+tgsyz69HXz8VvOvBv40gD8F8F97vV7lnHObGfibSUtuR8GWCFfFzErv/ROLotiWwD9lwT87O1sDfzKE8GER+e2yLH23221Tn9tAsDUth/Um9jQ/rx5Nlmi3RFWXATyhKIqF7Qr8UxL8ZkZEpD/96U8ny7L8cJ7nD9vMlXvtOjGr9vFV9YD3/gmdTueT2yWq34I/AR8AvvnNbxann376+7Ise8RgMPBZlkkb1Ds1V9L6mmWZhBD2m9njOp3OX29njT+0ek4xH98A0I1vfON3Z1n26H6/7wFsyjx+u04Y+INzTsxsyXv/uCzLTgngA6dItL/W+ABkMBi8vSiKp1ZV5c1MUlvmKaftNtrP3mrfv9/vwzkX8jx3IYSfJ1P/b7ZbOu+UNvsbwHdVVf1JURRP8JFwTTZpDU+7TowAUGZ2IYSrReRRzrnLTiXgb3uzvwF8rqrq7VmWPWEwGHgALfBP4eW914mJCWHma6qq2kNEpxzwtzX4E/CJiExVX5Nl2VMGg4F3zolzbjgKug30nXrAz/NczOy6siwf1e12L6/5GU+1a+G2MfCZiMKBAwdeTkQv8N77WL8TM3oiMszvHm8BcKr72Cd7hRBQVRWcc3Ue/xoze3S32/3f2z2ddyr6/ExEod/vv6Qoipd67z0RsZm1tfqnjk+/8nZwzjnv/TVm9vA8z/+/pPH9qXqNth34a9/Ne/88EXlFr9fzWZYxEdFKbroTJok2mbA5FYRf/Vunyj0/MTGRqeqVZvbIPM//8VRJ5x1syTYF/lOI6G1lWQbnHNdav970NU1VvUE2A21Vu46L9jcz0zzPsxDCV0MIDy2K4vOnYnBvrUXbDfhlWT6Vmd9ZVRWYGc45atZ3tyb/xpnTG9l5Z2Y4FBX6es+rzymEACKqhXowM5fnOVT148z8bCK6ugV+wwLcJsCvp+k8UUTe6b2nLMtiEf9x2Kzt2mSbOLLsgIigqlpVlWZZ5pj5mn6//2QR+f0EfG6Bv418/jpaa2aPVdV3hxDIOaeqyi3gjw/QNmMptJmpmVme57W2/5Rz7mVZll1R13sQUVvDvV3A3/DxZ0II74vZPGdmxiKCkxXg266m/kYK0o0QILVPH0KgepCK9/7zRPQ659xCc4+0v+I28vnrH7Wqqgcz88dCCJNEpETEdS7/ZIzEPhnAPNRsvc002fZIrIvalF/xeqsPZnYN2q0rRORdP/nJTz54zjnnLDeKvFptv500fwP4v01EHwUwRUSBT0Eb/3C+8vEQBkfynmsB/2CZFu89VBXOOQNgqopUqUlEJCICIkIIYZ+q/l8z+8T+/fs/tXv37n31/kCcoNMCfztp/gbF9r0B/FUIYTeAgBS8bFJwbXfN3/h+1tCIw/u3qNtDqRiL6t80z/Ph91XV67z3X2fm/wHgr/I8/1I9LWcrzstrwX/kwL87gL8EcHYIIaQo7rBWfyV10zYEv9aDJNJIaK4Bsl2WmSGEMDCzn5nZ95xz/+a9/xKAz+d5/k0iKpv7ogX9Njb75+fn64m5v6iqnyCis733XuJa0/89Eq724+kjH6mJXDcdEdEwby0iOhgMTFW52+2KiEBE0O/3zcyuLsvyu0R0jYhcy8wHVLWvqoGZKzMbpLRnxsyUQNVlZmHmXkjD5kWEVLXbuI7EzNT4DkPrAoACGDBzp6lMVLWsgZmm3EhDyWTpfmZmUlVj5mBmA1UtsywbhBAGIYQegCUi+lmWZVcA2EdE1QrhUF9EawN621jzNzT+f0Hk1r9pVVWBiLip6U8EOE/E+ycs1g0pWhSFAXDOufqxb4vIl0II/2JmXw4hfKcoih8DWN6u2i+BnTAaj91q+e0O/hr4/X7/Ns65z4jIzaqq8oleGdutL7/uNIyKWuGcEyJCWZY/Zua/BfA3S0tL/7xr165r17letOJ3pQZomvfVWnz4/Msvvxz3ve999Qj2DiULYK37h6e0zr/X2oe0xvMNAFqwn2Lgb47KDiF8RkTu5L2viMilDVGbxFse8M2vrTGs7VLb8X+EED6QZdnHiehnK0DOLUjatR3NPEl/b1BV1ZfMzAaDQRVC0FTNpc1/b6bjSM+rLEsty1IHg0FiGDOrquqbZvZUM5tsxj3MTMyMGixF7WrX9gn4NTT+blVdcM79gve+ahZ1HA/f/GR+5bIsdXJy0nnvry3L8k/KsnzL9PT0VQ1BqG1gq13b2uxvjNHahZjOu2/Nrb+dQF+b+qlElbIso6qqPpNl2QuJ6IoVoG9N+XZt+OJNCvxpAJ9IwK/SQIUtV7RSB+/WvPBRgAXnHDNzCeDF//iP//hgIrqiNu2JKLTAb9e2N/sbwJ9U1Y8x82/Vo7JXzl3bMpJ1jZ7zWoBVVRU6nY5T1R+a2TOJ6NON69Ca9+06Ncz+BvCLRLzwMO995bZRHq8u3lkB/C9WVfV7nU7nm62J365TDvzJvDUz64QQPiIiM957z8yS8tzb5mKHEKCqIcsyp6r/j5kfSUQ/avnk2nXK+fx1usrMcu/9B0VkpqqqiojqNN+2mqFHRD7LMue9/w9m3pOALy3w23VKgX/FUI23OecenYDv6qKdLMtOqJ9/sADdsb5vVVWBmTPv/ddCCI8koh+0RBPtOiXN/kYu/xkA3laWZYVUv34yA3vHg+Sz3+9rp9MRAN8A8DAi+loL/HadkuBvBPh+M4TwaVXNKbI60EY06myiZamzLgshfDuE8JCiKK5ogd+uU9LsT+a+mdmZIYS3i0g3mdrk/clxfY9XXCFNgs289z8KITyyBX67TlnwN/187/3rReTW3ntfFAUTEfI8Py4UU4e8CBvQEtw8vA8IQQMzO+/9D8qyfFhRFF9qgd+uU1nzUzL3f5eIHpdSekP6rZMB/A2/oMwIwQcRdqr6HVV96OTkZDslpl2nrs/f6DPfUVXVPzDzHczMO+e2xciwRgVfEBGnqt9h5ocR0Zdb4LfrVNf8REQaQnhilmV3SNRRcjw19dGm7laa8Yer8c0QRMSF4K9k5ke1wG/XKa/5EwWTATirLMt/EZFzRCTFw8br37dipD+V7tYa/6oQBg/P84l/bIHfrlbzpyAfgAvzPL+x934V8LeyqR9CCIld6KchhIe1wG9Xq/nHtf65qvqvqnqmmZmI0FqTZraKQGgAX0VEmPnHVVU9Ms/z/9sCv12t5m9ofVV9GjPfQFUDRdrdLX/xVFWdc2Jm11RVNZOA71rgt+uU1/yNSr7dqvrvIYRziMgorjW1/KYftJHif159EBFHpNf1euXDJiYmPtd257Wr1fwrhEsI4RHMfOPESktrzWfbMqY+A1Wogog4M7vG++oRCfhtd167WvAnrU8A1MycmZ0PwETEmsDfSu26qgFmiqoaqAg7M7syhPCQLOte1pr67WrBv+K9U4T/tkR0t2TKc9Ok31r9+gYzDVmWCzNd3e+Hh+V5/k+tqd+urbqOO01OCOE3RCSvp+zUvfr1DPaVvv1m8/VVAdUKZhayLHMh2HWqg5nJyYn/2wK/Xa3mX9fyNyKi+281E3+F+IKqqYhzqnSVKD84z9vgXrta8K+HeiYiBXBuCOHuIQQ453hrmfmagK+BmQXgK/v96iGU0z+0wb12tWb/+osAwHt/xyzLTquqSusQ//GegLvBnxGYxZnaz0PAwyYn89bUb1cL/sNZ3vt7O+dARFpP1d1okG58jMCj8hUIXXUODqj2G+iReU4t8NvVmv2HY/kDQJZlt6sBysybZJquAvAAQvp3fdTBPYIqVBgSQri2LAcPzbLs8tbUb1er+Q/t7xMR6U9/+tPJEMJtkmbeZFU9tIb74GFQmEHzrCshhOvN9OHd7nQb3GtXq/mPBFlnnXXW2SGEsxMvH22uryzxUE5HPEUzKBGxr/yy71d78jxvgd+uVvMfhVo9K8uyHd57O17BvqM3+zWdZnRD1Bix9NixBvNW4snd6e7/aIHfrhb8R7d2O+cohBBSW+8mWwZwAGCoBpU5l0sIoeovlU/cuXv6zzaTjz87a3yHO0ShesUVl9Md7nDfrTvPb2EBV9x+xvbuhUWV0M4m3DzO77H7/PUwjicBeG9Zlp6Z5WTy8Y+lAw1gcNT+AlRlacwZa5ByUPWeOD098bG2H//EC7YrroDNzcFaYbANwF+W5cVZlr3Ke++JSIgIZob1WnmPH/ABszD8ujQMdDBgMDAAxjLgH0uUfXqTmfoEwN7/pm/8BrHe4MABkAV2k9nuQMG8y3N1BBLpgiiQMYwZ5r1YiYFqCGpVbgE5TBaZLBAwzRn32BCYfE7IAEdQo2BmYmxdI102QBBCDpEAoESAAEGAEAApYewIoQuigUkeIMhhVhiTt4AeghNQlRMEIClVDAGal4PS9wmDA8v97/3wD+fuctXKLzw/My9X3H7G5uZIW3huUbOfiLrp7xDwtQZuauINFwT1W7OHooKxAJrDzAPkAWMEI4B6EOfQv67gv/z4D/x3vz5xo1SZ6Gcxy3OYO+mbrxaWQuFM5/i9092dE36Qw1WTIFKEfh+SE4wHMDhQlaNSQbAK6gneE8w8DAGgOsZRQUXA4sAQUOCobI0BI/hQAsbxs+ERvIIoPmaWLokKojD3IAJMJb7cSjADwRxsYND0eHxJOheFBrOyk5191Ydffd03yrL8nuPs3xd7B/7fM1916b/vWdhTjQSByZ4FaGsNbD2z/+UAXuq9H6PnXlmRdzzAr6ZgqQAEBGQwzQB4mAWQOWjlIVkFv+zw7td+3f75MqNzzjmb+v4n73niAz//jLs+9al+FrO0GQTA7Owsz83N6Xte86X7O97154vXu51cTngyFckM4jzIBYByqC/gqxxmPRh8rLaof2Gjkd9DBiSBzDTeYWmw9NzD2RrxA5gYxFQLfQAGUxsKC1WDwihzDuIciVCqBBGYBRg8Kr/UywpcoaH3mQrh758xd9t/aFoDexb2tG7YFgL/JQAu9d5Xzjl3QsEPD2YDkEEBWEic+gpA+2AAoT+Bd73+i/iH/znAaTvPRdB+mOxMOjP9szuec84FT30PfNzaJ1/rzM+b7NlD4Y9f+u8P7Ba7PmFld8rUqXMFAwHMhKAVfABCRTBSoLYahGvvYfiTq4YGUFdbG/H51LTihlCP72Dj24dqh2oEfsCgZoDVfwEnYswCi7+KmZKFEOCDJ4JKljl0Og4VDUoV/p+O+O1/cNHpn6ljAzFI2FoBWwH8FwJ4ZwjBE5HUID9W8B/69ZFr3zjm8IUDoAQNjKAlGH1ov4t3vfrruPzvKuw+7RxAFsFC0GqXn+zuzKzzgw/e+/c//+Q9e2Z0swmAt734yzO7dp710XKAnGlCq5KYKYP3Hqp9gALMZAhEZl4F8gh+O8S2WA3+w3D1ME7WEoWAWTziuQiYK6iVMHMgK6DBwZRMTY1MzRxJsbNLwn0QDvz3Shff/JSLbv7fR65AG4zd7OD/fQAf894HjusEgb+KegUZCAGAj5W8IQM0gEOGt1/6BfyPT/exe8dt4G0RrlCQCRg7Ufl+6O7c74ToPVdPfekPFxY2nwB4++wVT9wxvfs9pjnKZUehmiAoEHQJoCUQd5J/b2OArP82wb+y3yI+j1dtjcMRACufU4N+5G5QtBBIAVMw5VAVmEq0JyyWXLODIRcldTw5DVZdhA/67uXevrlnzN3syuQG6CEkWLtOIvjvD+Czg8EgOOf4RNX1B/QAEEQ7ACtCKKGhD9ICXHXx3jd9GX/78euwc/I8GAU4l4HQBbsKRhUMgFYWOtlZjrL9H77ujBv+wcICNp0AePcrvvr0icldb+8viVZLk1DviNkjz/soA0DkQDQOyFoQ1OAfB+fBwX8wkK8nGNZ7f4BB4CgMCDDzUKtAFGDmwS6AJQfpTgAukAwozzuitPTVMlz9zKdcfMv/bWaU3I1WABzlOp45t59576v0GXbi+vh5pA6UQSogLeBCgY++/av4209cg6nOTaEmYGKoF5gimaEVtASo2s29A84Plvn8yZ995V0GYC9AjajZSVt79lCYnzd52ktv/4591//8OcSBvR0AaGCAIVQ5mN2GKsVaaKx3HPkbGkABoAqgEqAIfJCBGIDliIb9EmBBggf3+77yJW4Pn3/m3S/76YuIyAhks7Oz3MJ482h+IiJbXl4+z8y+kGXZGWamIkInIseviBFrUYGqj+Ylcvz5O6/AX37wAAo5Fx4VGJPwvkSnSzCUYGGYZuDQAQXCQK9HieUwMT3pLPvJOz/yv3/16bN4Gc9h76YoRKktgDdf8vXnTBRTb+4vmWbYAbEueV4GOYvaFRim245W868E+Vrm/ZFo/vh+AlgA2FIaESAwzFyUsaRgV0Hh4/fggLKvSiGnvKvcw5Xvv+Knt7vwPe+hqs6ItHDeJOD/wQ9+0D3zzDP/pSiKO1ZVFWqnvxH4P2p4QxlghY6S+vG++hyiSwkyDxHG/Lu/gU9/ZB8m+GYYVMuAMCxkMRLOJYgUhAKELFoLFlDhWigEZcVhakfpRKp3vPeyOz8DMNpsLsBbL/rqcyandrx5edkFqnaQOE8kAQQFEVuUVhKj8pFTOcb/zQ4K3nqLUDLPDwf8dW1C9OHXAT84CZhkBaAJfh7FCLiCoQczji6M5vBlgWBLIZ9Up8F/8qoffv2xcx/+9f7srHJbGHSSwd/0+0MIn2bmB4cQvKUQ9DGDXzWmjsRiMA8AkMc0HhusElgoEYJHx01g4X3fwKc/ug+TfCtU/gCUBrCQDZU3EYPZgVBvcIbBoh8aag2loTsZXD7Re8+uz3z8wjnMqcFoUwmA2f94TpHvfvPisgtdy0nEKIQKWZ6ZGSikbkaFITMa++FXgjQG3qwBfDrc3z2Bnw9ja8XnDdOIZmOuihk13i9ZLCHWDmhwqMoQTr+hc0F//hffrw48Zm7uTuXs7MtaC2CT+PxQ1a80tcHGmPzc+JcDIwODQawgVGD2COrR6TDmP/RVfPLD+1HQLWHUhzgB6QSIKW28evNpQxbGohURhWQGgoBpSkK5w5Oe8ZRrH/Co98/MfCUnALM4+f5mHQN49tyd3rK4fN3zpycHorwMHyrL8kl4LwRItAJMgTACafNYrROOwac/ar2TUozG8RjWJ2g8RwJA0QXoTIhcv29f1e2e9sibTe74+N+99RvF3r17bXbW2hjAZgA/gMvqz9ko8OvQia0BKwBKsALQAPUDdGQC8+/7NuY/8BNMuFsilBk0FKiqpEXAa2zsRkrKYgcAUYA4A1MOYEJ6i1YV2ZkXnFnK+2fvc7nM4eW6mQTACy6945sqf+0LJiaFXYfMa2V5UcCMACWYKijU1Xd2CJ/8eIP/cAVEdAlitaCCyCCiAPWRyaTbf31VdfMbPvzqcMaH9u69Itu7F60AOMngNwAoy/LrIYSfiwiHECwRe2zYxtDAMYcPHyfqhBzOdfCpD34LC+/djyLcEWW1DyZXw4dBzCubAbzSZ8VQw8TbMfhHRDAaQLJBFDAsbml5qcow/djrdtzqQw+45X8r5jBnm0QA6Py8yTNedpc39qvFV+3c2ZW8U5li2ZgJMJe06cELfA43mHdigG+NbUqjgwzEAUQZTKfd9df6ymHq0Tfp7v7AU5/6HhcFQJsFOCk+fx34A4AQwv8SkftVVeUBiIigWfBz5EU+SBuYImpJATVoCTiX47/96Q/xobd/G7ndCoxJwF0DdgdAloP0dAAOxP0V/qU1gloCQh4DTFwCPIjuAQrAGORKcGE+p7OyoPs/8Z/fPv38z34L5Sz2boZeAJqdNZqbI/3wG390abeYvOS66w94+CnWKicLBhGfRNzq6H2t6c3CGOiPVCAcns9/iG1plGIva1xSMhApoBmALgBBhev9jh3IvC591H/3yj946p/8kp/dC2qDgCfH7K/Hdf11vYE2ptBHwZx68imA2UMrgeMc/3b5dfj4u3+ISbkNnCthtgS2Lhg5SEoY+whuwjr5akqg93FzwYGQgchA3AfXpcIVu8EyV0I7HnXTW3713TMzYMwCdvLrAGxuLg5LOf/5N35xoGp2amrSBe0roTLmaOZs/jGpSaivZ6Eow4KDkcJoALUShUy4A9cPPPmpx2Xn3fTDn38P3NwcaesCnBzwx74tkc8AWBIRp6p27H5/TcMVEHvOCc55XH9liQ+/80vI6AyY9WPQzgEwAcLpQDgzpo+lP+bzN9NYRBzNSV6OKUA4kE6DbBJ1uSxTB1R1YVhy+5evq0CdC3YuXvG2ubm9tnd2L518AUAWjSKj33v6DV5OCG+YnOg6tYEKq/HYT5586i1jpNYNRgY1ij0MVIF4ET4sAdqRxeulQpj4ve/ITz761mdasXeO2hjAyQB/Mv2/DeBfiMhUTQ9u0uvwONgZKwBlTeA3gA0f/9C38NPv7oITBxaPWMeiIA6AOZBOQohBVDZk0+ggslEuOwkEotRKbgKyDMQMUwLgALkezD23fIB9ZtMXPuOB33lTnWY62QKAagEwa/yY59zghUzhHbtOy51hWQmZqQoZYqqU4EGmMdVZK9z1f9DDjAHYYRxHoUuGzYSa+gMo1nMQhl2MTOyu23eg8oP8Uff83cGH987Mt0HAEw3+ZPIzEfkQ8IF019jnNa2AGvT1BltPALASEGJAzgePPM/xL/9nP/7x7/uY6pwHVRerxDiAxIYmO8kiGDF1F2tH19qIGq0C64AgIK5A3ANoMPRDwQqlCmYKBtDlSbZB4TMpnvPch37zj/diLxFocwiAOZjB6PEXnfkMlt6bujvYlVqqEce2/dRII8nBESWQ6qrqhWZmoPkbNYVBM18fDz3IYYejOZJQrisUR64AgSEEEFWAARocmHMQG8z1kDlxP/jWgWpQDh71onfO/MmePQvcCoATq/lrG51E8Omq8t/KMkcheD1UpPlgaUHltAksdqcNlgyf/NOvYemAgNgPe9WH0WKyQ8Y210/7EVa1twLJSuBUQ1+Q4DQOftLnvPuZvYc97l02axTBdfIFQEqT0aOfd87zDYO3diZ7zocDIU5RLQB0YJBI4sGx824zugGr3DQa1SKgERgkRGKRTjHp/uPff1YR44I//8jDPviFL3zB7Z0bWqPtOt7gJyJL1FgHssx9EGAKYdysb5r5dVDwoHEBDTAL0BDQKQr8n8/+DF/71wxTnXNQ+n7cxGOAPXQp/spo98HgZLBYUEQElgCXe5iBrJqUQV88yeRTnvUf//aO+m1OugVAtQAwevwfnfccr/veVeTkvJWBkq9jBARK5dKbFBrr1R6sLFGO2QogyzKUfXJf+uLVFXfc4+54uzt/+IqvIEvPbS2AE6D5m77/+1TD9/PcsapqCEfHx6AWUFUeFjzKpQE+93c/Ag9uCkERuepSTvhwClRW9rqv7Htf+zV12auLMQFeBLtFqHn4kmXxQFV1stOe9uyHfvutRGybwgUYst8Y/Vhv+wyj6gMTHc6MlgNJCXYCmIORDF2arbLGyUPieYvEQDDrLnz/O4uuXNKqmMh+75a33PcnCwtgZm6zACcC/ESkWAAT0VVm8scAk/feQgioqmoosQ+H2ls10kUxO+TdAlf8ywH855cDprrTUCyDmKGWUnl8cAGwXgXb4VW2MWAdQDvRBXFLIHcA4B4IIlVvp5/unvXMFzz8p2+dmTFOTTQnXQDMzu6lvXNkf/659z2Vs3Jhcpoydj0ftARI4gGFIaxbAnyw3v2R5j1U+fD6wcSV9fyH+i3W7yhkiOT4+TUlfvKjRQevVVFMXfDABy6/71//9V+zvXvplHcBToz0m4GaGYvgA77y/5ZlmVM1rX/UI8r+UeTaRgn8v8t+DuvvQrczAPMyYg4/VrLRivr0g22kQ22wcasgVZdBAHRB1klZhT6I+xCpiALJYDn3u3ae8axzw0/eMT8D3rsXdLI329zcnO6dNbr88r3hB9//4gVE/c9O7pjIxAVvqKAaoEpjTTVHU+G3IT3/x2QFGJgGIFYMlrr4yQ88fIAblAM/NTVxwZ3v/AvvxeWx0exUFgB8gn4Ui3/oepe5S0SkBAyqarG//AjM/sDIhXHdT3r42hcX0XGTAP8coCWAHIgkbYLUBko2NNXXc2iJ1m9kGW5gpDoAMhAvAdxP75sDWkQCChRgdJFxAJHJdft/7jtT8tR/lv983dwc6d69OOl1APV5zL3nwcvX/Oja3wta/s/J6W4WbODVfGypNayhuW3Tgn/8s+JvxGyATkEwhat+UsaUIEiqquezzJ3f/2X/vssvv/yUFgAnzO9J1F5MRJ9V1Y92Oh3xIWhickWi3T0Y7EcHeXzr64orfwRkGcdWT2QJoIkRppm3R1MIYDyIn9JIRLFrzOr/KAYKrT647iojgDhyAHBIAiZLJcFdmBWxBEkPABp4cd/AZ+g+7wWP+P4r5uZI985uDgFgs8bPfesvXv/jwQ8fWfql/7ljh8uCDrxZBkIk1Bgy8oJA5kDGqC/D5vH5V99mYgjnMA0QIlz382X0en0Qe4BUgteqM+HOv/td7/G2RoqSWvAf/+gfMfNLQ9DvZ1nmDKrMmrjdMSYARpmAKCCYMSzS+d43+vAVgTMD7DSwnR5poXg5ReNtBYdds5hn/DBoopOOf5VCLB1lSyWkmgRASF38kyngF2vMSQBiS4JHocYAKlgwcqHL/eskOCpectGe78zOzZHGepWTHAOYIzUzvuiiu+5b/nlvT6lX/n2347Kq8l5VYiszCwQObBlYBaICp5Qyghur1Q9lKaxliYx+35jqG9UEEMgIItfDOUN/iTBYNAgTmAwgdoNB6btTxdP6y9XbFvYs8KkoAPjESmnSZP7/1Ht9HsyC49xCEDMjMGssolmzyi+6B8w54IHvf/+HEHGR/QUB4z35R7nx1gj4rb0hw1AgxaITGxaijJ5mABiqBcF20tIBDrns3PuiPf/5choW2Zz0IKDarPEfvuYm1139nXxPWS5f1p0ss0r3ewgByEDcBYhhFAAO0MOwW44m4LdRgqO5B0wdyDJUJXBgfwnmHEEpTSEiKcvSF1339Id9bOZdl1+OU84F4JOy4cxcp5N9SkheCcCpqsbhEqMKstWnGQ9mh0Ev4Lpre+gW0zClYzZDaVTcP2YtrC0I1jc9xwQEKUBl5ASQghzvpH37gne886UvevxXX0tE2AwxAEouwEXvucW+fdfaI4z3Xb5791RGHDzHMroo4ghQBBiHQ8rXEw3+5rVfWQSk6lAOCEsHAoAcqnWQmUEkPCgH3mV48r3u5d8LnFoC4GTlOoOZMTt++aA3+ECWORdC6avKp0jz2imcmH8W7Lsu4MC+Ciw5atqto4sKrxXRX7vgZ/x2WHFoNP/TYUrJZzaQLEOyZRB7YhTcW7aQue4fXfT4r71mGAOwzeECXPyum1xX9vwjzar/s3NHJws44JWWI7EOBEoMY40JlyOqmDxhimWo+WMpcmz+CUFQlTQ0DmNKWcFMJCSi6r1z7oLBYPAnCws4ZVyAkwL+FP03ItKvfLV4mveDj4rkmQYLWs92QvOHGmkUAOgtMvrLBBHXML+b5vt4nflKNX0km3N15BqJenqdo2bFDbF0lhkw2g/OFuHykkSEetdPhw6f/kezF1z98jr6DmwCF8CMn/ma2/98aXD9jEn//05NS+bD9cFQoW5vjhoTK7j3DmWGb3xM4GAZBavHhAWL3I5GqDzS3JA4cJQTlVss0WapqtIXRfHEBz+4fMfevXvpVBAAfBI3m5kZ3/WuVDlXPFG9frDodBwTaRPAa61Bz1CVMcgTNKzoz+eDbI5DbKDD2rh08GpAshhVRhYDg5aDxUBcgqQH4j6Jdmj5APtcpl46e/5Vr4p955tDAMzPz8sfzt3yquXedQ819D8/MVk4H5a9kU+mdGyP2tzDcixaZKkRyEwRQixdFiGwMJgp8kJQ5IYgkhgDKPKnXnLJS95Rp6e3swDgk73ZEtW3/6TjJ/tK3y9OnJn5+AOtPL1IBlJVhsHAIwRtsO7SQTVE7ZuvT+Sx0ipYRwjQoXoBAsgtp0KgVAaMHIxOPMjBySI5dHlxfwhFN7v4lc/43uzcHOnMzAKfbAGwZ8+eMD9v8uQX3+Jn/bD8MBZ8ecf0VAauPLNFijNbcUE2I/gpCgCjOLQ1zyXtdhsyNkUEeIBD+r2Zvfc+z93Ter3BG+oA9XYVACe9vjmWnc7yDEj//cv/dmG/3/+4cy7zPoQRL7/GQqC6c4uB4AENAIvEoo6U3z20H3qwcl9gZUpw2PbbMOvXBr5hSIyf2IDAVZpgm+oAMAmybnwte2J21OtRcDKx9/XPuu75Cwt7wuwmqAOoCUGfctGtf2RV+J0sty+esXsyEwo+40kSK0DGifwwoJ4J2Mi1HaZ2PpbjYO8bqb8BhqlCnGJyqummBIzyyjV3o0KEiYjYh4HvdLLnDwa9S7ezANg0X6hxcV018B/OCvd7/cHAZ5kIMRAqIHhFp+vwrX8/gNmnfxlucFsUWQVQBdNJgCOrKxo9G6s1fMzlrx3QQ8z51zUCvL4Pe/B0ICWfEuNlwTW3HRNYBtEEpdyyIre8CKK2/OIXvfMGr5qdNZ6bw0mfDFTPBJh/+3fPcjb916GcvtuB69QjZBKshHIPSh5GsazaQDAysBnidMODB1mPZdvSGoJ+FOOpU30cC66yH+MRj7shzrn5LnjrgwVgdNZ8Z1WFBjUfgnU6hSwvlq+enC4uqffndhoRvmk6mxolwFX2FXd+NfDznaJwaupDiAM3gyqCB3bsdJiYMrB4gBIBB6do+wqKrsPx2ZuBwkPl+Q/n9gj4aAAfQ4uifhxUweCpGngqe6Kw4tJXX/iDl22WGEBtAex5xs2u3Ne78sFw138h6/bcIOwLipg6E55M1OYBIB8zHDh59N910Q8RwCxgAbqdHBNTBWJWBmDIusCPliURpakzE1P5xb1e9YYUBNxWFsCmamskioSLdFeqvvcD9/jBQD+RSZ75MgRA4VysLZ3a4bDrDECxBOekMZHW0r8PsvEOkscf8/np2ATBiMFWhxkCYgVxPaeeY/kwPGAZDXodLO13ijA99/ILYynwZhIAT/ijO165dOD6hygvfjXrqgsYhHhmLrIekYCNQBZWxVVOvBWZ2sVNoDrAztMKdCeyaPWZArGtf03g17+jcy6K56r0nY57/ksuedlrkgvALfiP04qbfpZvfWsa/OAH3z5/sKyf6Ha7zsAh8s8DeYdxzrkTsYWWOHL01eRzxgfxy7Gm2T7u84/8ofXz/DikGzDml9KKGIJxbEKCgFihGADwpCHH4gENGtxLXn7hTy/dTALAzPiCl9zmx1W19HBQ9c2iy86wHIL14ze1PAoCrn3ok6sgmQnOCUADnHGDDjpTLg79JDuMRrJ6wGmcLVv5gXc5v9AP/J7UoyIt+I+bAJhTM+Nb3/rWg59exRdUPf3LbmfCARJCULgiw01veVpk2TUXjxVhjPXTeYci+Dh2kzVql1T3P9ZnYMN5gDVYAA/IAUD2Q9yAmITCoAi5TFzy2guXXr7Z0oBPetntvrHcO7CHZPkHRVed2mKAKSwkklOrvycN6diipbOxbsB6XAMjiniNFOxuGTe8Eaed7iEsYB4ni621fn2uzICkbJNzQsJCg0HfjPEWM7tF3aTWgv84bjYz45vdjPrZNfyYsqd/lWWZM2UPALe49W5I3kMI9VBHv24Mc708/2rTfSN8/kYHIRnGg+CUtL+P2tFiyTLxAJTtB9x+SF6Row6qvoQ8l5e++bnXvyymAbFJ0oDz8qzX3ubffbX0EFD5PSfqysFiCKGCqSEyKaym2Toevv16hyXNbxhgctpw45t00rQXAyAHZ4de+9MYMHVOzg5B3/75z38+WxGkbsF/vAQAnUe9a6678jHLB6q/LbqcIQR/3s0ddu3O0O9XkXmGBhi1/WLNSHNTq68H3CEp5LH4/KxjbcXN2n8iAqQHUC8KqjAFhB0ACjBlYCqQOzBKR/2eDz70517/3O+/aGGBwvwmqgN4ytxtviSGGWb+fpblzqxShoKVQWmkdgQIsNH4X69WY2htRKyi8j3c+Ma7MX1aHrMPXJ/I4YC/OQuSIJLx8vKyF+EH3PnOd35WnQJswX8CBMA555yzvH8pe3R/Sf8auWTTu9jf/FY3QG95MbXlZ9HcJr/CcT98nx00YoM9uM+/glJ61e3xCP9ow6bbVMXouCVf2SbBOgXCBMg6UFsGZyVV/YyWlnzwnl7z2mdd9ew9C3s2iQCIQcDzX3KTz5PxI7M8/LjbJQGqwMjjsBPYKisIY6y7G7I70BzkUf8HYigJKBvgprfKwRnijMZ65h8f7uyBEUxUDSJCIQQV4eeZ2blR+W9d839LnHgtAM4+m5a+cYB/f7l34G95cjL7xbvf0OcT1yNUBirPiCOoeTHl6CObC9dcfhzvAwPGNHZoHGILo/jv4VCINYtLEolH4wD5xrHOIMzmnEnNQRojziwlmKr0UABxH8aAkgESCNVOCks7NKfiTe+46Lrn7UmFQCdb69QC4ElzN/o86Icz3cnBVROT4sxccJSDLMA0RHeMKhj5yBBMAuPE0HwEEmClexaZVyRG9AF4lPAYwFOAh2CxAnac7XHObbJYysNx1oNqAAdZI0C4djVpfAxwjlEUBauqMsuNADx/q+f8t4zUqgXAXc6mpf/85vSjtYe/vedv7MjOvkU/lLoMZMuJqr+TpvAmKi+Mcu6UfO6ahGPUjde8bcec518ZQzicTT2WggSDSUHk4TIiFoIPChH3xvfN/vwFc3Ok8zPzm8YCeNLsL/2zr5b2uNx+mE96V/qloEoISrEcGIkcxChyL2iIfvdR+wMWXT1EGncbmugMswwAQe0a3Pb2p6HT6UBVa0bHo97yzFEYSN17DjzOzG5V78sW/Cck4mxyl7vQ0je/eM3vg3HZgx91RzfATwK5JVgayxUBzWMFP0OtS5SAPkq9NW9TXap6zMDHwQlDOVUQDgODafBEHHQEYoO4AJYAcY7UE/q9gZrJ698zFy2AGATcHBbA+S+++eeQ2SM42/djzvvOoCH+DhkYBQhF/E3MQ81D9Vj6/AmmMchr8GmqsMA0g6lDWfVw5o0q3OYOO1H5AGJK19VFwXD0V8yYmbz3AcBuAE9pNf8J32zzcrt7nXngB9/GI259u4l/vcs9pt3Pr+15Qwal5VR0kib7kEWKraG7aaP70tG8fcgYwRHEENZvDLSx3D81g4OgyKEHA3gAlhgfIM4pVDkW96sOBuH1b7v4Z89cWKAwP2+bwgKYnb3MPfo5u/51qew9KivoZy4Pjp1XkXoEGoGUYwX2YY7sWlfrG8FCFjU+DeL11DzOHkAFuP34lV87A50phkIhEhmicAwKOqUE61ZfNjOEEPYcOHDghltV+29Jc2XPnj3B5k1ucme67tre/ofe7JZnfH33md2sDKVnp2CKbZt1rpaTjxmtgYP7kwcj+jicOgEczvtbHQzU4by8yEGXeARTDQlLHV8gEDIEn1M1yLF8gKDevfWtL7jmmVEYnnwLYG7ufj52A97yHwfV4qPZDQ7kHRPiUg0l1Oreek7Cee3OyvWYf8Y4/Y1BcGAykERQhyAAArxehdvfaQI3u9VugEsw03CjMwHMrpHP58OaF1HHBOrnZVlGIYRAROd2u937N6I6LfhPiAuQzM3b/dKZPzmwzz/ktDOy/+h0fUbsPTHAw+KaZrCuZvY9Nh/+WJ6P2vqoo+GsowDjMH6U/qoAEJhSpDcDAeRIBzl6+52x0Vve8rxrnp1M703jAjz5pbe6vNTl87MCPXKVeF1W0woaIlDJ1m7KOZirtCoOTwY1jZ2dJCAK8HYddp25jHvc5zRkuYeaIctqP583dLczs6X6/8dedtllLhX+bCkBsOWbFOZn5mXPwp7wrN/99g2J+3+jg4m7USgqYjhOI7VHmiT6fsZ6CFPdDgJ0pIj++qZ/HQSu/x3dBRtyBAKx/p0ldRKmTrRasxBTylYQiDKY1ru2AkkABgQjNhKgMx2oQu85z3/dOX+cuvAUJ5lpo+4G/OCrvzMDdR/r98j5qlBBxo4EJnEu4LAoJw4THbvOB3cLKJVI1wQjOQZ+CfnE1XjI75+Hs29ewPsSzF3EfH2ttX3y+4/O7G9aASEES+b/vizLfpWIrkjU9Ftm1tmWL1GMga95+eO/ucXPPNED2cnni2IiY4aPGymOdB796Cspv2rgcsOs5+HttQXDSkrwNXoDhoKiIXcapCPrd+tS6k5M7LmWxzn0VsFoAMMyODeAlYLlVpa5ZZm85c0X/fhZIwtgE8QA7nOZe8LFN18A+T+QLASiilRNOU1UwhjLsTYCsty4v9baI6spjmsDSCqICIQ7UHhk3WU84ME3w9nndRH8IpxjMCJVD8d63pH1d4xLVRFCIDMLWZbtDCHccyviaVt0KC0kAfCOv7r9z38+uPZB6vb9k2QuE2SelcEQMDkoK4wDHDglnwjRA+V0yPC5w2PoDzby+clXNwtpJPhotkD9b2oGEet2Y/YgruJUIWQJ1DGNVE8nZpI0NIPBMAADAH0QeZAJSCegrgQKA+fGZg5W7rROvvMtb3vZTxsxgJM8GORz9/Ozs5e5J1xy84/Crn389I5eyArPXjM1ZGDKQCTR/WFNMxmiwAMAkQpMGaBxJFpMtaWuSGII5QDy2KxT/Az/9SHTuOmdHTwGIDoNQDdZ+jVjD6f3PrqenHXiBJZcll+r5UJr9p+kFUkwSC980JdP29Hd9WldPu3e1YAryq5xJvtg4UwQuuC6GxBY0YlHII4jq5slv9EkHUXoV1rVzNIoDW6Un0qztFeH8YbYhYi08W1IitmsC2CK56IwmIWxijlzFRQOTAUIDpKpOldSZwIs0n/2H1xydnIBoCedEGTGZM8Chfe96puPyTD5gf7SZK6aB5BybR3VzU+Wch0GBUFh5qCBQBRAHElYOLVsOxfBvFxdiXv/1g7c8Vd2wocSLAJTgbjj+72S9jeOUuC7IvILRHQg0dJtieKfbTWmODbAzMu7/tudrytp/0ODu/qfs45lZrm3kEMowNFaeXwMgd4cvDEi9bRVtfrjR5P6CwcnDwWNfc7aHIOAUZwjNCo8inUBRHF0Vhw+V4KlggVlImdVGRTq3vL2l171rM2SBdizQMHmTZ50ya0/VpV4Ymdif2V8NYdgWjfakHUA5NFMR0gnnKMuhTZK1LsmYMog4mDs0fM/wq/cbxp3vNs0QhjEgS5GiUD1OAMnWYQhBJjZjaqqumO0Qhe2DKa23YzyyINn/OaFO15blf4hFV/5/8R1M1Rne9IMzL0xoDVr79GY5zcE9VBj4zA4AA/GZY9GncA4TdhKS8IQa9HNGlZkc0ieZQkYJYL1YFD4Urgqc1QDZ0VevOXtL/7RhY0swEnPzMze5zL3pL3nfKyUa56cd9SAHhkGShRijMWiST4KBUhytUpEDkcBIYcpIM5hqbwGv3jPDn7xV6egVILYpZyOHWbt/rEt72NISVWDc65g5tsDwMzMDLXgP8kWwOys8ds+e+ur91U/+V3l6//Z5SErB8HDOiBRiCOI40ZgTgE0S0XroaD1jMBGcGrFakamm0xA9fCINT2shmVoQ6CnvL+FJIRiPIElZQCGE4VcHFXGIZnEAJDBtEvVoANfeZucmvzjP3nJj59UF+Cc9N8kxQCefNF/+bCT7EkT0x5ZXhFxpSw+DtkIQLBIthFCrASMBVoOQl2YAZIFLPV/hDv+4iTu9ms3QKADUPgUxUlW03Ey85uHc66O01j63W+2piRvwX/yXIAPfvbXribrP5iLa/916rRuNgg9zxTAnMx0rodspgmvaHTkDafwoFECvJbZv3pU1FgsYYzUltLnNduIkzBI+f644XXILR93nwGqjc9gwDIQuRQ4tPRXKJSM3j5mg3vXm5/33SfOzUXgnfzfJJ7HBZfc+IOuU104OcVstEiKZVMMoKYwZZhRigMEmBqADN4DLB77l76P825huMevnxmvmWUxfiOapizLUQf1jjYImITDzbda0G/bgr+ZBXjT3972mn5fH+Sz6/7H5E7JKM7OMqZR5199gMddgBHAeVQlyLTisEbX4OqCH058fk1yz5GrsZL+e1SDUPcn2cqmePLx/VDERia41OjSh9EyfLVI5bJg+UDOWTH9zkv/8JuPnJu7n79s1jaNAHj8C27yHkX/mTt2djiEngY/sBAqqNZU6R5GCiJBqAARh8Wla3Cj8xj3e9B5yKcCFASiLogcFBrrN07Qjh6SfaYfm5lvmPL8tlWKfbY1+JsxgLd99tZXf8+WHw6EP52YmM4kMzbSQDWgCUPaqaGmXjHee2TR0YqDG39XPqVR2Tf2GjTqDMbfu8kBGGONo1oCMwMopNdmYCtiABAGowHU+iDNYBZYQ2GDQZ5PTE189LXP+88H32+ONo0AmJ83eczzz3u7oZqbmppwIQzUTNPYRUtlzwRA4FyOXn8fbnijCdz/d2+N7jTgKw/nNApISOPan9gap0ac54wUpdwy65QZRzwL4zmQAkaXPOYbz867upftjJ3Li5lndUQamBFgxiiJYl6dAxiawMYjam+TVWl0qnnqGFAJ65KF1DXmUVukisME7liHnur5V86fQ0z/AQA7HmcZHsYN6spDhanCrIBXp50OycROv7i/d+VjnvvKW/31ZbPm7jdH/mT+HmZGC3vAexZIP/Cab77W/OQLD1xPIcMkcUYkxQCwDkwFih4md/fxoEeehd03MgStIK5zQs93JfVXox9AAYiqfo+Z77yV0n2nDPiTPqkNcnv+nn+549SOyTd1sh2/WS5OoFx2XqRiHypSVtTd32QU8/iIhTlECsjSikuXgF1viATeGphjf2uaL1hjA1nD1cCQiXhMeKQaBAAg4UbZcP0zJiFisbDFKMCMYvqLVYsJL8Uk9fYfuOaxz5q7zac2hQCAURqeae+79FuvorDz4rLnvBAz5aA866IMS3CT1+MBDzkHZ52bIaiHdGIcYDOsSO7Boqo/YOY7EdH+rQJ+PpXAT8mInp8xeeP8L39l7n3zvx0G5R+wu/5rO08/4CjrM4kLjErZCKQ5oF1Y6AKaR3HABHAH4GJ4GDKAsvQ3h6ADQQGxAoICrDnYCojl4JriGnlM2Vms6IvzBtJYL5sGYxqE+JdpB5imwdgBxg5QmAKF6Xj4HSBf/90B+GmoTsCsiJWERBDXYe/z4Ku8MzVx1p++4xXfedT95sjPnmQXgEAGisVZT3rxLS8hN3hd3h04c94y17HK9kMmrsH9HnA6zrqJwGuA5AQN2Zrsu+1qNf/huQGpGhAALn7CN8/soHqCWXiq490318Eu9HsDCyELjIzAgSTrk2T9WAFoO2Jk3uq5cGlgKHNqGy3HGXoaYX0CIbBvZAlsGP0fhQfyYZCxWflX/5vNhpbASqZcNUUwBrgEuSqWxVIBEiaXWchzZXO9arC89Pin773JJ2ZnL3Nzc/fbNBbAR974rUu1nL5kMOiAu1fq/R54Jt3iDqchhBKQAEKRKi55PTP8hLoCZqYiIiGE74lIa/ZvJeE3P2O8ZyG26V3ymK+ePTm566FQe7j39Gvmu3lVAj5UUHjNctE4yMUgmZCFkKb7KUwtRegpjeQa8dXDYhwr+vYGIz8MLtYEItxsdEkDPmMeWQwARfaoOFue1IadcEhEGdYIchlJrHKTAcwMLFNmKCACkmwQiu5OFqLywPXXzjzrVWf/t6YgPIkigCwJgPl3Xffyfdfve+7d7jU18Qv3PB1VtURSZIAymA0BGWh9HxyqeszC4CA+/ppmfwjhiyJyTyIatODfYrGAPTMLvLCwJ7V8zfIrn/SkX+4vlw/Mi+zXvOntzOSGwkWk1pYdYAaCVlCNfePQMPS/XSaNLsG0SepUnUVhQTxq6R2W+SYAs/PDoh6uB1+IpGi/Qr0ieI9Qp5vqzEHddFLzBLBHMEUIDmSTyDqMLFeY88iKEqZLS2b933riC276T5thw6YUGRNR+P7Xlv7mvNtM/E41CJ6zSkjqLImL3urmAX9gZhdC+Dvn3IPq79GCf8sLAWB2dpYH33n8LZn4Ft1ix50yl92GiW5AxLsA7CDSCVUVVc+AKQsM0eyvo4sQyZKJmCbDSGYEI2aK1isDZEq1eS8uks1azCJHNU/EzAy1mrnGQ30K8tVpSmKAQRkcwI6I1UA+BJNgWgR2FMRVqrJs5AZU5IMA2DcHy9WTn/Si2x2IAdGTt2nNTIgoLO1fekRnovM+U9thsb2ZyHkYIk8fGOBNAn7vfXDOOQAfJqILtlJjj2shvyIAtYAAgGZnYy4vmsNz3wTwTQCfGYsb/OHPprKKpk1K55Ui3Y7voQdgh5hVrmNZ1TXQMgNA5cyyygzoY2JiAgeMGQeA7gRQ+T4BQLcLDNQMS/Ezctc1AFjq9xldoItIUFE/v9frIXMdcxlRL53XtCcCusicmYqG4AZBbL+XckrLYlABV4M709lH//ojB55+3xn+Fu7gRwHRkwv8/dcu36fTxQeYezt8yNVMiXOgTqEb+8RxeNKj/CuFxA/TX0FkDWnXNrAHaHZ2lmdmTGZm5sXMttWY5k1xhRNp4eLi4BfLsvyJarDgK29mGo+go38fnyOEcMjHm8+pb4cQKjMz7/1T0nfZMgq13cTHEqBK8TkA2Lt3L+3du/eEac40Lx71Z9a313ierfmL21i/wcnU+ExEuv+a/u0mdmZ/S2w3996HPC9OaPj+UK7CysdDCCAiq6qKnHOVqv5mnuf/ZytRebXgbxdONvAXF+2sIg9/7zLcqT/o+TwrBMhwIrN3RxInqGsLmNlUlYnoqpTm+1lL5tGudh0m8O1a21kUOu8yuVPlyyrLconUZpv63EFEqKrKYqwPX1tYWLhm68W42tWuEw+eet91Q6Ufl4wf7EOvcpJngFitXce01CaTBt57EJEXkQzAHBHtrYOWW+V3aDV/u04G8HlhYYG992+VjB9cln3PlDlADBpLJjbzSpV9CCE4730J4HNb8bdoU33tOuEKJ866CHuZ+Ull2a+cy6QehBnt0c0dL0tWiKqqAPg2gC/WcmFL/RDtXmzXCdT6QkSh1+s9UVVfNhgMAmJenIbYYQ/mzY2hpPnNOQdV/Z9EtK8m8mg1f7vatQ7w+/3+w4XdO0MgYybKMqGoMGvyDpe066Y3/YWISmb+29pe2XImWLst23WigF9V9htZlr2/8j6HwYSFtuj3UeccmdlXnHOXb0WTvwV/u477mp+PwB8M7L8Q4aMaaBeTUyJmszpnDoxTcW3+lYhW/pyIyq1o8rdmf7tOiMZfXFw8i0j/jEBnVd57ZpGanFTVQFtL/5uIsPf+Ku/9p7by79OCv13HC/icxlafpqqfYubbDPrei4jUHrIpgDSlN5XLbrp8fl35l4Z0IISgRVE4VV3odrvfThV9W5JKqDX723U8gE9EpGY2UVXho8x8D+9DRUxST0AePXloSG/q71TP5gMgIYQrVfXNW+LEW/C360QCHwCbmVPFu7JMHlRV3puRW3twMK84NhlAmBFCADPDzLQoCgLwxqT1eatq/Rb87TouwCei4L2+khmPr6qqii273Hje1vlOmqYkmZl2Oh1XVdV/iMj7zIyxhUZztT5/u47nGgJ/0PN/QMCLekv9ICJCHGm3mHjIND5CjR6WPjretf4r379u3qn9fTODqvosyy4iouu3aoS/1fztOh5aP2r8gT1ahN5d9iuFMYUwpCaEmY7NJtrUkiylIFI1n8/zXFT1T4jo7+bn52Urm/ut5m/XRgI/FvH07XeI8YHBQEWVlQgsQjAdDSU1S6PJN3mYjJmhqijLUvM8z0IIX+/1enPJtdkWgwJazd+uDQH+0r7y7kT6wXIQuhqgBmYRhgZLRTyMBoHxllghBHPOkfd+UJblU3bs2HF1NAq2trnfav52bZipf801dg6LfrQs6YzBwHsnIsyCEBRmDOe4JiAe87EjvTkD0OG8wvWm7xzv/P/K9w8hmIgoM7vBYPDiiYmJ/2+r9eu34G/X8QS+Xn+97S4En4LyrXq9ygMQcCzcgTGIk6lfm/zY/CZ/yulrnufOe/+6TqfzxlrQbaffsDX723U0wE+Dga071cXHOh388oHF0jNYmDhNJ0rP1XSk2zqcNLSpwR8S8N+ZZdmLtkNarwV/uzYE+AsLC8zMhgrvMIQHXLevXwk7IRKI0NB0H/fxa8CPTPyN1tYHG9x5uIM9VdU751xVVR9xzj2zBv528fObq+Xwa9eRgt8RkV+8xl6WZZg7sLhYseTC5KgeM85CUBsNHyWKEf7RaLLGkXzt+jYoaiQlXTWFZ6NiADUNV7OXYDAYgJl9lmXZYDD470VR/A4ze1Wl7Qj81udv15EB/7II/OuvtKd5b3OLBwaB2AlDyLgGuMCGcwsPw/C0kQqK044ZepxVUp3Gq4GfBEtIwP+noigeT0R+q5fvtuBv10ZpfCEif+Ba+30/CO8sy6AGEBOTmsWJ5QDYFCR0xHNA4tjt2rNWGGxDZu4dTAAk4FsIIRRFkQH4YghhDxFdtd2B34K/XYe1akKOfT/t/46V+oFBL0ARQMSkamA2mMVJf2oA85H36Fs9/og0jTQ/eOpvA2MFmmVZpqrfLMvyUZOTkz9OFXxhu/+uLfjbdXBQzpvQHgrf/9rSXcuBfLCqtPBBgzhm5zKADMEbSAxkNOTeq33q2MKra4B9XKMPx5QTw6A4VHD9aKyCWpDUnXohBHXOOe/9z5aWln5/165d39puufwW/O06WlOfiSj84AfXnINl+1i/F86oBqXPurmoEoIamONY8cTMAQIDCCPs0sitH2p3UMr7awJ+bOcdZgWOg8/fBH59FxGJqu6rquqRu3bt+sKpBHwgEqe1q13rAV+/8k+2m1U+TZb9Qn8JPhcn3gLEcQQ91e18MeDHxDA2gGzYHFP7//GmNbR9KvKnqOljUN2GhUDRElhfEtBh+hZ1dL8mESrL0lSVRKQH4BGdTufylMUIp9Jv3Ob527Vqzc4ag2A//vznJyYm9KNixa8sL/qKIBJUQWRQDTADTA1jIfuk4s0Mw2qflNe3sb+WNH8EpjUf3+hNzjwEfmLjMRGhqqqekWXZ/7jsssscEflT7Xduzf52rdT4BMD2AnRB/gvvFObfPrCvVxnEsUR2fQcHU4IGgAVQpUR4kbCeEvaGuqyXYaopHsCjUt+61t801gAlS6Kh2+uzSgePAfpIVgghfpKq5XkuIYTnd7vdD9ZZjFPxt241f7vGgL+wACYiu+AR/k0An79v34GKRZxzDswAc92eT02lXr/BqHTXCDBCkiWNf9fbjtfZhvVjtEIIHFkgoJklSGw85r3XLMukLMuXO+fedKr5+KvcpnbLtyvqViMYiIj0in+sXpUXcnG/XPKAMFNGIg4iAZJVICYQM5gJIgALJcEQq/sifmMwkLluf6eYAmQCkySfHsOUIJGOKv4IQH2b1jflDwX+ZhFPVVW+KIqsLMu3FUXxrO1ctttq/nYdmcafBxOR/st/77+QSC7ev3/JVyWJBSHAxZp4U2jQVT65JR/fxm5Tw+Wn0X1GR9DPf/Skniuq93xRFFlVVR/K8/y5LfBb8LcLoJmZecFe0J49FC77xPUv7RbZ6w4cWAwhEMMyAA7qNWbyIj/nGia5wVJEfQRyg4VGvC+BPnb46dixyv60+r00vZ6H793U7Idq1KkpuJg56/V6l2VZdmFt5p/qwG/Bfwqv2dmo/RYW9gTsBf76vVe9ZsfUjpf3Fn0IngjmCCYwjd2sNgy45elvHbG32m4fRfmbPr/W9fsjv92G1sHQ52jcryssiFpIHJnfX5YlvPdBRLKyLP9fCOH3iKh/KpTtHu5q8/ynmKafhfHnsBef+xyZmcn3/+mX7/ftL1VvudUtb/rEKpQqYJKMyMTAyfeO/remPL4DsY58dELMzxMhBg0SRoc5+rqoh0Fk8W+DxnPk09sQ2smWGObxR3/XjwE0c/6JjCMUReH6/f5/qOrDp6amftwCv9X8p6JXH817wOYimu383/qzBzzojh/7jAb+7K1veavfLQchWOgRzMcifQQYPMxKGJUA+aTZa1PeGv36BtPQ0Ni1qY8Vvfs8BHoz5z86sOo+HFGMYPh6LYrChRC+UZblIycmJr6/XRh3N1QTtJdgO/6mhlnspa/O3IEWFma0LrEzAz3yV/7ql7m88bOWy5/sybvePXzmV+2cG+9QtcAu88iyDFQALLEiTpylY1Qsw07BEqPpwgQSpGg/IEJAauxhIiAO6Irtvhzvo6EnQKD03OYxrBei2CLc1Pr1gM+VaiuEABFBCEFjCg9XhaD3L4riS6d6Sm+91Rb5HActCwCzAGE23vPVry4cZyE7g6uuupzu+7n76hzIALI5wLAQH330L/79jSjfdf+H/UL5CCD8RlVpoSp40O/8arjh2RM08H12jgDKUketQZkgtY9uHCv52ACkrjslGEVmXhl288TIPsNApgAYZDTs1IOlxh1r2u+0whogEGjcUjjMq+e9V+89Z1m2qFruKYqJL52q1Xut5j8BQK81LDCDhQXoETeyH4d1/n2+2yG77tzF3s9/mRDub1rcV/1p5/r+JMoeoaLv+t95+B3lVre7ATjrQcRDnMA5gjiA0pE5gThKVkB8TCTeJo7VfbW2j/82MHPK51uEsSSSDyTNzwxiSjGBWO0HDnWYIPr+KV4wfJwOrvlDCFBVU1VzzmlZlhdMTEz8WavxW/AfB8CDvjoDWlhYvbF+6Zf+JLvx1K0nd9iOsx13drCVXZhlCnEmJZkFIhULXgA3ALwD4KE+I6bKAmABHgIgOKTHo+nLEkhNmdSYrMMeyy70pWuiExSmp4z6NxK2sy1M3QLKN4fxGeYdgipK3w8iZv3ektzz18/D3e55YyiWQK6HbrcAs6SCHQXlBJZIuS2OIJLMfjGIcAJ/LOgRiVV/sdAnPh6DgzG4x3FsZ+r+SwCWKDlGATxNjUBN8//wwQ/AlpeXrdvtivf+6Xmev7MFfgv+DQ6aLfDCwp7mhqILH/Tlmw0W5c5B9Vbi3B1U6Wahym8E411MoUMSnIEEygwjGHmY9qAWACMoMlggAD6luQiVlYBOABRgPABbbmaOYmW9JwpMZEyqBLI88uVZJxXiVBACzAsIkyqYVO+XmfPr6ED/u7jr3W+Cu93rDvDooej2keWKPM/BnCWAe0AI7GgIfucwrOQTIZBo0vQ0rvWFVoGfiMAUXQZiQIiAeCkimJnXAP8I+E0OQCCx/RDDhzLGJESs3+9bURSiqi9zzr0iDgaFtrn81uffINBTWFhAABiPvte/3nm6M3G/oNUDyr7dGexuxGEa1bIghKglgwe8GYxKAxjQLIE7wHwRhYAFmKXJ1aYwVAAUph1AuwBXIHSgkMRuA5gFCLwpVWbBwdQshADCATN1MHWAHCChgggFmfUlywMO9K/D7e9wHn757ndAv+wj6/ikdRmqnHzxmkSjUYdfF+cMdUWzpn9F7j0V9xDSX0rvBY4xAIufN3o/GzX4jBX7rJ+EMgNUfT0y2waDgXY6Haeqr2yB34L/uID+wbf5h+ldZ1z3MJdP/55Z9+7md5+GICh9HyFAtWKFMQl7BN0PI40psxQEi9nwFOwCgzSLwFEAvAzTPEXMBE6zeApqyeSPoLRQpJBCRgSBmUdMXcf3NQrRr9YcBhdfx8tYKq/BLW93Gu7167dCSdeCXY4hNizO0lMYROIpDCP1CcyqAGnTF7dhmW78q+O3YSCl2N1HNurRNSBegxA1vwlGNULjZJ5jv8TwfykmgDg0oKoqm5iYcKp4pYi8NJXttsBvwX/0a3bWeG6OdGEB4TG//H93uE55AdQ9ycJ5d4Iv4C3Ah76HMVnoElNJJMsClBFUSmljU9J4PASFDU3XQbQCjGEgKELSkgQTD1KJ0XUTmAoMFYwCjAxOGWw51AYADFoLlWRBELsYNacKfb8fZ964wN3vfWsgU4RAcMmWjlqURmOzkrau6beG+nlYu2+xYo9rjb6idj9ZB0PkaYrbp+fH5r4QMwUwGMdrE9PvByk5MTSovQwgWFmWNjk5Kd77V2RZ9rK2Xr8F/wZoe/DcHAVglh9/r986v3CTz6/KnXcIgRAq9qESkDATKiFCArBHjC0ZzDhqXhXAIqWVWQQC4FNUO0v3J6BZBwKNvjsApQBQFdNrpgBJSn+FKEgIUIQoKKiKU3AlFeAww1kOooC+vxY7zyD8yr3vgKwb0Cv7kDxZEmawJKBqX9oAmGZgM5B5kFEsCULU/AixY49q1GtNuEnDVB7qiTwyuh1jEinqr5zu1iGtV8zwJUovcKoq5JQ0HQ37SHEBC8Hr5OSk896/pgV+C/5j1/aY5TlEbX/+r/79r2SdqZeTTf1m2c/gBx1vykTSF+ISZJ0IFjUAPmkm14ihEkABQIW6WJWk4QJQqpOve91Rl8fGslY2jUBHEhgU/62GJAQYRmnWvQmMFEA0oZVivAEcQDLA3e7xX9CdJAx8H5KHRLElSRPX1XMBQ7IMc4D5BP6Yp6f0xsPgG3g4g8vUknmfZArFtl1TA5FCjZN8MEABZdTSI1pG9bVo9goao1nrG0KIGQaQVb7Uie6kU/VvzbLs4hb4LfiPac3MmMwtUHjALf+uuNktbnKxL8sXmM8nF5eq4LgAs4haiFqPKGm88Ur0Mcd2REA/8lFrg7hWsSNvNrHg1FYAGgPsqRFoa+YYfOMjBWTpZySDwKCyiMov4t6/fhdMTXfQL5dQSAAFwEmWPqPZIWfQoWlf02oRNGlutrrhRkbUXRzdlfq2puAeUnqPKLowZHXZUy1cbFgkRMObGqUWUwo6cjR4CABzjEVAEXzQiYlJ571/c5Zlz2+B34L/mIG/sEDhcb/6+fOmpvP3s+74Dd9jBFWfM4vBYORB4pNpejjZURsTCMS13xrhXFeyNcEPNAQARm0ua5NU1ufBgEkSHgpCgEJBbhF3v8etcNoZBbz2wFRFv1wZ5lMMca3A2pB3r7a2o7CyRiTfhgFMi22+UscO0llT8naaci619JJEoVK/v9XWjg1lV7KO4nsw4gQf7z1YLHQnCqeKNyXgUwv8FvzHDPyn/caX7m/WfVe1nN3MB6uEJkUxEEMFUAWgShq/GwFHZSNKTSPgNIJjq4HbYK1NYbqRgWDjVNZMICPUbeorB1vWDS+RDy+mzpgBIw82jzv/0q1wzrmno18uQbKQ4oDRdLeAaPqn82NKDDvpXFU1IpkwLLOluvlTkbRzNOFNaiOChi6NqUHDUHSBGxY8UkkwOLoKrARlg6TUoiWTP7oxmmb+VXAZ+zx3maq+R0Rajd+C/9jW/IzJngUKT3/g154A797e73cmykHXiyud8TUp+h1gVnPQZ0nT8ppaszbdD2uxRj+aGsA2W0VtveozEk+2WVOKRN8aXEF1Gbe7w01x45vtxGCwBMpShDyBkjQV1Qy/E0VB0/g+agoEi6k+XknckUCvyWyv63Z5ZNXUMcCYNbA0nIOS/x8He9RCr3YLNMb3oGrDYh6zCmVJyHLxee4yAO9l5qe1wN+4xacy8J/z4K89DZa/rz/odL0Xn2VOYqS6TBo/2Z91pJ2XAVleddmafeeHwyW/smR1eJuxrmCpK98ikGTYK2/mQVxhUO3DjW96Om5ys9PRK5dgoqMKOkNMr9mIMENNV7XS6pCNh4bpuzEPxmLQsU5CRCGQyhHS4zGtOXo8vmdyFQxjtQCWgn6mI4sh+ADvQxz/wRQ6nSxTj3cBeOowJdMCv9X8R2vq71mg8Mz7f/3p1aDztn6pBnSVBWL8c7AoEDoYpZVr2zYAKAEO8b41wF9Xtx0a/CMXgWqnl0a3VxoQNS328LMs1QOYgVjRG+zHDc6axq1ve2MMqkVQXmORGucWU3KkNh5wTG6HKlJgDQ33BWlgZjIzmGIGzyhRbTGCWbovTdypefs1ZiAYOhRcdXS/pvWqh3OYARaipRDIYGamUN19+oSD4o8lo2cnH7+l32rBf1SL5meM9yxQePKvf/7ZVaC3VKVpCABRn5mLtBEVZkXU9Bix1ERzP28AFWO+/Zivz+MugNWvGRa1Up0CHxceWqtgXiOLABAnamzLk6VQogrL2HFaB7e63U2x3F+Cc4ocWSwuUouBM+ahad+k2VKtq/dSwwxGZbd1KlADIA6oW24NnNJ7cTpPDOBbdBcUYMhwfI/VFgdzKuONxiY1rsRQAKasg8EbKNjpp0079XizZPS81tRvwX9Ma/Y+l8meBfJP+80vPwvovKXfG6iwIHM5mRrMejDLYp57WFiSxk5hPLU35KLH2gE5rADakNe23uRNtormO62obacVQqa+j8TBENAb9DA5neFWtz0PRj6m60gQvCLLGYSwKgcxnKhno+9S9+qrUmy8SWdc++hDgi01GI+m8cSXETRYKkas8/ujfnwzg4YUr5BUIwCA4OsIIlRTwBJmhkrPPHOnI+ANlNELW+C34N8Ije+f9ptfe5bw1Ft7y/sCU0ZETMO0GwExD7ZWKOTENj+O5f3XEC7sPKqqh6npAje52VnIcob3PeRCUPVQlQgoqe1watTl0xgdV4o1Qs3AVlsgo6g8UjGTIrbtjqh2ohUSQj2Sm1MsgcGSKgJ5OGg7FvsEgFhj6tQCzDIIOxAUat5E1Hbt3umqyr+q6GYvboHfBvyOCUezs0Z7FihceP+vPE8w9dbesiqQESMjS1VrSKklHMZo6BMDfqwir2zE4+HDIlyuOPcmN8DUdI4QenAZYPBQrUYCo0GsSw0B0OzMG7kBHLW9oqG168DdaL5ezaVvSrBgCMl1qF2IyOdXN/BEq0G1LuzB8LnBtGGReMtz2M7dHSn7/tIW+CdmbWP2XqOZmTvwO995R336A77xAsGuN/T7g2Aoyckk1eyysR12SCiPJlPE+tH7g0f3Dx3xX/vxYcxgWLgziimEoHFUlik4K3HeeWdh12mTCNqHOIVaGfvps5gNiH31iYGn8W9OffXEHNN5KctQE2VElp1awcd6g3g5LF0ZjvHOxlw9rnN3jbRh3RxUT+KtfXsiASeLItXxW14E27mrEF/apZ0p95IW+K3Zf0xrfga8Z2FPePaDv/cSZ2e8Ymn/ILDrkaCgUHEkyrCQqtDq/2gM2CuBaY0Ee/PxNYtwDioEGgU1awoNG35G/V4ihBA8iIHTz9iBiakMg8EiJIvgFJZUUBP97tEk3FG8oW7PZbZRX07Nx8cYff9hCS+gKbdfR+tVFaQEuGFgY5Tl0BgQTP+EUIN9l0duRvAEJgfOzAwlpndMSoC+qpiUFvit2X9sq07nPedhP3pBJqe9Ynm5CuY8sRMyy4bVZ02gxUshm+KSjGtPGg6v8KHCaaftxK5d06h8bOcdpgqNU1pyde3uyGRP4cehcEhFS9ag29ZRYFPrWv+G6V+X8lqw1F0bewDi46mCsK4f0GblYwo4akguQrCq6tvu0yfZB+zNMmlN/dbsP3bgLyxQeOYDfvxMxvSbvZWK/GpSWibvi9Rjnop2qObbrMvUXErpHWrvHWsAcO1A3kgiEyIHLoZDLb332H3aLpx22mkIWBrSZsXel3pwpqS03sjEZxkNzGCum2VSxD/V3lLqxKun8NaDOKhp4aShHUQ0quijRMaZCoZGCZEwIvmx5EJxKuwxgMRMUdrpZ0xKVfqXTe5wL2+B34J/Q4B/4W98+WmAvN1XZgYP4pLMd8A2AfUhFdlYQ+uvYISkFXOkaPzmocB/SJ/fRm9IjTOImjR6Y1prdY68fBOTOU7bvRMGD4iHc9GOFuEE/kSkSZxAP34/SEfARk3aATBZ5OCDpOfxkH5rGCRkSjwE8T4bTuSp/X0MEybEBDaOV5QUwgHMhhAUkqi3QN5OP3NSzOwlO3Znr2yB34J/Q4D/1Ad+5ckE967BoCQig6OCUE2DzIEsgIf19JT60kcFNUQ1YUSd6x7vulsZ5FvLt18rCLjy+Zyq22jlf8P8OYFFUnttiaLjsPO0SbBTgEMk0SSKAzQ4aloiDO9nocilXwOU43AMrgN3adRWDNbVjLuxaKem6UroTYE8HmYMkDR/5B/gNK67ESdhgE0gIBDVwPdwTqAKIzLbdVpH4OglO3fLpS3w24DfMQJ/XhYWKPzhb37jqaTuHUvLPRLJjCinGFOrRqmthl89qjqrwUlNEqqT4OyPzonIUHmPbjfHzl1TcBJZgYQl0V6N6vJplW+/auzt2OissRx/SsVRGsBBJEPPpybpNFVYatKxYLBamKSUIcbOIXIJmhGgOXwVi3u8D2ZU2s5d08KMl+zaTS3wW/BvjMZ/3kO+e4GWnXcsLXkWgjIcm3IimRgPpq0VyW8OlTQ7OXtxKIyYUFUDOEeYnJrAkC5MNWn3ZgRfh4QYMa9e8+GNvg/MUjVeLMZJgfzGPL0oAJgiKQfV7GEc+wOgluKAkVIMamBlaMMQqFt9SWPLsDFDVVKZbzCXK3adNikEXLLrLHp1C/yTv7Z0tH8+Af+iR319hjl7dzXIGJqpcx0WzuFcNhY9r4t41jPLV5ruh/LdD7eL75AKf0VXoPcVxDGmpychwgghwKApiDcWfMCI9qNO7a0MLKbyXI3luzrOMzJGwx05/CxG42uyjvQ+8bU8ilkoDdl/VDVlEEZ9DKX3UAOCBQNXNjVVMJm9+IybtMBvNf8GaPw9CxRmz//uo6vKv897LZRYs8LVXLFQDckntpqzEitz9IenkccnyB4K9CtjASstiYMVBpkZxBE6nQLOSSzq4VF9gUHRbDWgmiZozNRPxUCIXNwxZ98w0ZkTC0+yEIYsPZHCm+qGHBrx91PKB0Zs85DEQzVO49FE8CHCqKoKReGgCCYSbOdpHREOL77BzdyrWuC34N8QU//i3/vpo8vSf3DQt47kpWbaIy2n0/CLOGZ6RHlFOJoUXbPwJprlhHUJ5o/a3B+v4+90uyiKDCEEOKbGR9ka34PGtHytzdUA1uifxxbcBtuOWazdHwo0HRbwcBIMVvPraarGk3G2HuaU20+GAINTNy/BSQ5yMEaFXbu7ohZedtYtWuBvtiVbFfjP3/OtR4dKPlgOOh2iieCV2ChAOJnB5FMPvjZ8Xxy9EGg0yIyD7mh8rTW8raSRiyKHy/KUl69HW1uK4td5+FGajevHmdJjo/ZdYh6NwRqOwrbGSCwatvI2iUcple4y17cbrhCSYKAGtWhKnRJZzT9qIgG7TitYoS+98S1dm85rwb8xwH/OQ7+zhzx/cHlJu+qzYHBsoRNnwqGPSGOtGAXyaZRbp7XAvzLvv5b2p8YkWUKTgHP8PQ5HkPAK1ANqAS4TFJ08RdYDxEmaezc+wJJTHT4PC3Nizz7XOfmxmfejcHxduDMqCqLhe8NoJFgYo4Ke9HXr2gAmThN4o1tBkEhwQgZfMZyYKS1jx2mTTGQvPvfWro3qt+DfGOA/9yHffoSvwkf6vdAVZMFJxmQGQpn4pTjl5+s6dWmw69iwUKUG64g3z4ZR9OhHrwzGofHacaKNER3W2gJkZR3AGDMWFEYBkglcFqfhEGzIrUepCAcNjS2sSeunop6hQKgFgI2+KyEKEBuNxWaOVoOIJB6+WjhIaraJr2eMtD2S9UFMEDII6bBWQc3DQGAUFrSPHbtzloIuuults9e0wN+8a0tE++uo/ksf+/3fLfLswxasyywhlqNhVJFHYVikQ2N+8qH9+hE/3vHv3W9mE2qB4tiBWZL1TY0y21EDzWo/vw7u2Yqg5Mr7R9w59RXRlfx6te/fCHBqTReG1Pwz5PYD1DhaKPCAFgiezNv1mNrRZVTdF978tvlr5+dNWuC3Ab+jB/68yZ49FF75xOseUQ76H+n1lieE82AKZhYwURx3zRpZaVO/eTOldzh5+/EuveMP/iZ4ncsAWksQcaMUuekp0IoAHw2T9jYcfmGNOXqNQJ/FVB4YkWKbNF6tJmtQmuHHFIXE8Ezr0V1s0dwPkgKBYsYVdu2aYEj1/Nv9Svam+LtBD6NRol0t+Nc29ffsoXDp+Vc/dND3H+j33YRgIiADx8AVI/gq0T3XAb6RaX64xTpHRLu9we+3slw4zqtfHSUYxS3qfzepfptDMw2kqT2ZG7GOJDQsce8DK4ZsGsaFiVIs4gkERSLe1DQqzGKhkHM5CLCAAXbuLAhsz73zPfK3tMBvff4N8fHnLvjPmcqHj/R7Mq1GgYW43viqOt6kMwzu8brDM2iNaP9qU//gtfmH8umbMYPm68aZdGxo3teBNua1io1s6MrUAbpY4hsHbgxdg0ZMoI7Y1ZF/go27GZzq8mv/v+4OTOeeeHKHlF9A+iwWMAsUCnEEo4FJ7jE1nVGncM+906+6t7bAb33+DQH+xY/9+kP7vfyDBxZ5UuGDUWDTON8dUIwryWY//ubfd+Nc/FjDrMc6FsDIL6lptup+/lWjssdM/tq3H48RqEaCTUsTglRrDV9P0eH0GEMDEIJBjeBVDTxA0TGWzP3RHX6VWuC3Zv+xrdn7XObmFsi/5DFXPnhQho8uLbpJRha8LLG4MrLDDMNW9VSYxtiYLbCaGYQjWzY0y61BwGHJ5h/9u8G7P3bUQzIiQw9zauZhHREWg9MEYsAS/TbSHE2iECcECRksoNuZZBb80V3uTW9ogd+C/9iCe7Fk11/06B89eDAIH+33OlOmPpBTJuwAbD+C9sEohmauaT0n4nD2XB1VW1Hg3hAma5n1B32vwwC5rRGpb+btx/x6HMwFGZHrr/q6w9MfleqOERGk4RxD/74hEFRXCCJN6VL2UcByDAASZbEn1y/b9I6ukBYvvOv9WuC34N8Ajb9ngfxLHvOdPT6E9w36YZphoXAFmwFMfUCzRh4/wYGRKnhrHz91tdka9NvW6NtfF/y8aurOkN7bDhYTWDFgY0UcYPz5K/sDVgTxWMcFgTXq92se/RWafWgRpHJcI2tofxtL09UlzyPgU92rE3U/M0gJphWMS3hTCE3CBzGDt+40C2fVC37ltztvnJ+fb4Hfgv/YNf6rn/nt3y2X8g8N9oWuEwlqwnGwYxorQ36VTxyZZUadbcO9vQnN/MM27ushQY3cffN23VTTjNSPBnyMaLXqsVhNARC5+SIlf92UU6f/YrCPYFbCrAPVDhAcoAJPalIs2sTEhDibfPF9H+Te2Gr8FvwbAfzw+gt/8nCt6MP95bJrRgFELKmGRzVWwcVGHV7DhG4MubCNdv0bMQaygwTjDh/8dcBtXaGQGmpi7r0ekNHw9esBlzYK+hk1CDhS8G/Y4ls/t2bprYOEaNTyo8HgQxWMDWw5EBzEiZH00emKsFQv+a3HFK9qgd+Cf0NM/Zc/4WuPHFT2kbLnuhry4ByzhmiCB/Ugif24MXsdzfqRRuQV5vlGrxXlukcpAA4mENYSDsDB7qNVcQSzla4CrRAKkQHYNJb0WpyvNRQ02uQ5EA8yBVsXRmxV6GFqMmOy6qIHPGbqta2p34L/mIE/97n7+dknfH+P1/JDfrnokklgBseqMoLqarJNaqTzmrn8g9XWH9rMHue5pxVNO6Pq1LUti0P1768F/KbPv5IfYHQ7au661HdoytcCrxnXaBb9rJXiGzL2xLZdQj1Mox7FraNpPcYQ7iAYmVBpnS5L2ffPf/CTd7xpdtZ4pgV+C/5jBf5LL7j6d6vB4MP9vnQEGkSyOPYVPk2S0UZUm1MN6tG15B6OFh72668J3vVq6zfAtlgx7XdEIUDDYRtJv498fqJhv72lmoGh8q9jIWMuAa9I9yUbSupS3kaln05DSS0rlqzokJjRCx/5zJ1vGjbpzLXAb8F/DMG92Sd873e08n866EkH6AQlYtVFiNAwul133EWlLMNo/fFI6I8aaA5G4WkbCvj1pv6sDAXUAsFsFNQcRfpXBP7MGqQdNNZxGJ/PqV7fhvGTkecUsyUWnIlTE0eiHC6aedrpb5ifNyFqNf52WnwSgB9e+rgf31+r6k+rMuwgSMhkgk0NxBZNfayg2h0DHq0+jBsHra+Y6fACcsd71VTdaBTk1NNvVsmYBn1Ys21vlNZMgG1aK7UpP3wxNWr3aVWdAEFj1aQJSDPzumzMEK0mLpl52umvbYN7rebfEOC/+LFff0CoBn8Wqs5OVfGOncAUuRAsuDQx1xobfDjZDkAJUA4kbrqxoRqNIhfSRp3/GIpsbdU6hkwDrSD3GANW3d++op9/XJjwWCxipXAZMvnYSBjEj67FgoGUEvlGmpRN8XE2RPKM4YRNHQUiqXkxaBgYrYWLKQ9n6VEjNmIWuQ6DD2YgzSaD6+niCy/4o/PeMDPTBvda8G8A8F/z9G/+Zrlc/HnfY2cVBiF3TmAhEVykrryD+vS0KS/ieo1B66XzDofQc/z5iGPGZBTEiz6+DVtxCU2fPboJMbhHjccbLoQSjARqDCIHYGDkljXvdByUX3Thi897w/z8vMzMzGjbj9+C/5iA/7bn/fz+Vek/3vODnUGDz7NCYDDiuq5MQeRh6jYklXYywT8i+lwb7IeVkiQdemXDnL1GbW+kq+v2te7Jt0RhxmBoasflBPa6PiDAEAB1YORgHpjm+23ndNdB3dz5L51+3fzMvOzZM9Nq/Bb8xwb8Nz3zmt+qyvIT/cWdOxm5z11PTAUhxBxUHPZoh8O5s2WEwcbXHNTzBJtcBeMCZhgArCf3KgNMqYRXU9CUYeaTNeBgpKZU6mQx4bzvz/3B7Bl74+/Wmvot+I8R+HNP/fJveq0+pqHY6YN5QIQ5R7C6xn48mEcrfPVm7tzS5JlxzjyMPT58jR3MjF79+tHrVkf7xzR7I9W2UruP3m91DQJWxC4Joxl3zfcYvmcasEEcZ+k1LYoRTdeokAdQaEDqunMAEdQUrJGsU7WuG4h8fiIdEJXmdRG5OLd/f/nyF7zlnL0zM/My0wK/Bf+xAv/1z77q1wi9P696U7t7fe9ZeqI+bX6K3WIjYDTz+KtNZLO1MgDbY63k7Y8RuXqgfRyeUQf2zCz6/9zs108NSUOzPo7NYibESklrilMIckBK83St5RMkRNlFL3jjua+1WWPsRevjnyKLjxfw3/Scq+4t5ObLfnd3WapXCxKwDFCJephGnBarGHXirA72jeWoG5NztzzgYetaI3U+Hmg25dg4IWcq1BnW7BvFQZpmaXSWRmIOM2hQqOqQtLPqk3m/rJ2skCzLXvzs15/72vmZecFcS7bZav5jBP7rnvKje/hq8Be9JbuBD7kHggAG7yUW59bpPLIoB8b8eVsfLtZ8znqlvLT1BMFKurE6oj+s2LV1X9N0JeKSKFisTvUpiAgaIt03lM1gWuQ7nOngZc949Rmvmp8xmVmAUmvqt+A/Jh//yV+/Wz/4+aonN/De+0xE6rx3zGfLiA7aGuNik8aK6b6Yj27W8hmiZovmbzkKfA1JJaP2o2GRz1qVgImfHrRuHOAwonnr9PsfPAC41u21egKoaeInpiK10Wc2+xdqEz8SbcT6AmIGpRnbhjhc04JBJAcMxgiq3cpdP6gufcU7zn7F7KzxnrnWx2/N/mME/muf/v27knU/6b3ceFB6L+xkJZnlBtvOqzjwj13x11H19Y6NtyxWBQq1UUbUYNwZCamGwFJa1dwUu3qXYXINzAYwKwDkCKoqE31nuu+1r3jf2S+xWeO9e2sTrF0t+I8S+K/6wx/e3Sz/pIXi3H7Pe+FciFyc3konYH/VtFhb0Oxvgnr4V1PmQRPd9pq+/1o1/oBZHFcGdQAymDqrvIbJqdzB3Ktn33+Li1Jwr/XxW/AfG/Bf/+xr7l7kE58a9KfPK0v2RT4pwjlM7TjlvJuYpxVjtLYq8Mc5BGsSjvHBHNyo9W9IPWvm/SO7sYVpWNiN4LtGXNnUdOXYhZdd/J4bXGKzxm1wr11HDf7Z2cvcngUKb3vh9++aCT416MmNDN47yYQ5g7Akau1Rn3xdWrpeP/toyiyte6wRBmxoQj3sbED8PI697StGZ53oVX9207yvh2PEDkce9uKrYtjHX0fva85CDXEKj/cV1GeoBrkJq0m+X6pw1cV/9M4dr5ipo/qtqd8G/I5a48+Rf/MLfnYXhf6F+s6NLAQv5MSjAqBxsKMhMcxoQ9ZQe9UPaQmg0cLLsVZ/yG1go1p/bg4naQoQRtDS2GVKUjmW6qK5D9/6tXXlXgv8dh0V+Gdm5mXPAoVXP+M7v8ASFlDtuEmvpx7cd1qZsbiRBkuVZ+Osty34Dwn+9L+RACBAOQkAHWZOrNG7P3QFalYP7ltRVM5Q7X35R27y2pm2ZLddxwL+UR7/+7dwOf6i7E3e0leVJxecWt+YuogMXDpknalposfz+K0AOOjSBi1Bo7KPhpybkWWXEBrlDnHymikZQSyf2C8KvPi187d4VZyA1AK/XUcJ/mFU/0nfvnVw9Jd+yd1SddEz5wLA1OeJWluG7aNDbWSafNvVI6PG9Z0NueXqInpK+WxCzUU/mkozfN2wpW3kQx9+kG1lrf/6BTVNduB1ewOGFs7q1698nuo6HOM0SN+Mx96vvnaVMsgEzjzY9cDMcK4D09wy11HrLLsB9OVvWbhVC/x2HRv4RyW737/5YIC/9iVuU/nSOylknOhide39ykYdsyMn16yFyCggtg0sB1tfOMAk9uNbXbtAjduAuWsBFEA4E4QdAC8jSGXOqUpWuqoKr37Lp28123bntetgiw8X+K94xpduprC/JBS3GZTeQ1k0UGwLtfVn2g9TccPjCM6Omloa2JZdPVgjfw+CWWQpHuXv66g/g1RAZlAcQOkZZbnT/GDS8q65XvjZG9/w6RtcMjtr3HbnteuowT9k4HnWt8+b6pz5aT+YunO/X3nHuYjrABB4v7Lm/vipyuNZL7DZrII6sLdCSkSZqDsACBQ9BDtgg0EfLjdZXCxf85a/vvULZmeN59p0XruO1uyvo/pvedaPz8t3FH/ZO9C906A84J3LRRXDMc5jre62Um3biC9v6CPziteMaz0MI9gWXfkVZv64G7GSzHMdA4KOoBZ/Db4AokaMomHlHAlP/6oYA2xVbf8wBmCrZ/5Zyv/FWwNoVSB40sCL3J2+nipMXPzOz5z7mhr4rcZv11GBPwaJKLzvFdfepCoHf1328jsvLV/vs6yQ4H2cksOjQN6QRda4AcSN2XsROCvdhSN774MSaxzh64/me419fnNSLkY5/ZVxkigH6hl6sTd/tALMzAtPZFl3f9/IP++dnz33XS3w23VM4I8biMIbn3vNOaGUv/D90++8eGCfF3KiFVJhSQQ70Qoyjqam2sCTrPPdR1sqfCzAbyrioUWgB7csDvZ61HX7WFGiO3bRGEjDM5kxbNEV4TSct6PdzmRm/PPvVZpf+P7LbvlZmzWmOdJ2S7frqHz+BHx97Qu/dqNut/PJqszueuDAojcEMe6BXJyZx5JYo3lcyRyPDr6DlfaustcPNm5jHequI4k32GFPAV09/nto6td032iO1yaMz+ETAA5EghBqIk+xEMgL59zt7HImi3+3FMJ93v8P5312ZsakBX67jlrz18C/9FlX3nAiKz5R+vLuy/3lSsU5U4aGHIY+hLpDzTU0+RNnvMFGcyRQxwRouOnVFGScBlbYGkfkkB/6+bXWG2PST3UC9X+mw882MkAFkTNgNOFmXHCkHgBbPSYrvotinCwEw8lBMFuTWHi8zLZm4RnhmVhHaCdDMA+YizMITBCUYo0EEYijZREGDGZANZhWpllRuU6RcdDB1SUtvu6Ln7vqrV/AXasZzMvCAoV2K7friBVrE/hvfO71u8WyT/kS9xn4xcpJ1zHnCN4QtIRauTp4ptrQZJYGUtBYAE+pDvgpSGXs8ebz6nqgOqtnGHH6rd3XPoq+mVESPg6wbCygNv78ONJq5HePAmqqOhwHuh5B6HjzDVYIj3T+5lZdo1GmMsDzvniOmgGWxcImikQmRAFEA0MorOoXhjDp8twBxff2E/f+rNfb9ZaF/7jdNwBgFsZzaDV+u44S/DXwX/+0b90gn9j9Ma2y31hc3FcZsSvyCYhk8D5AtYSiBEKB1ey6NuSL4xTrCwkfOka6aZFpZzgZtu74G0XASSXx09mYSdzsdW9G5MdrAWw4tqs20Yd/G/yfhtUgVlWoaWyYIT4IOzBFrd20fWw0YSgKMFs1LGiUwzcolVEopuCBSD6Sk8YQIycsIBlgUC5/G5j4NPveR/70ijv9+0hYt4G9dm2A5r/0md88c2c+9Umy6Xtfv//60iBigYhdbhYSrz5VIA4pHTXac9wweWPLKTU0eW1y02iU1hgbb9MUr++TISV1ZJ5tUndjbJR2czhGk8U2voc1PoOGwmloJVhj8OXw/JNlQFK7KbQa/LYqq6ghtRI3uPNho5BKdDPqomdG8Lvi+WiAqZIIOM8dRByYFRqu75nhX2Hhz3uD/Z/686/c42dR088ysBettm/XhoD/fbNLN+ot7v+zTrbrPr3eAF5zqDKq0uB9iD3vYmBSEAMKXTPSrRp540NiiTVVqFnql+ea7B6kDeyYRa3ZDKSRDHvXLSRzGTx8/8j4aWNad6ShEwWXMUwVQVNdAeLnqAYAAoYM2W1VtVFLQI1YwXiwsD5fA9L7jD8e30dX9wcYD88xligwyDKYeSgGMAwA88uO5Seq+Dqb+1+q2T/+6Es//bfP4X6+Nu8BtKBv18YG/ELY/4CiQ2f2l3pf4FyzXAYcAgXKVTkEBO9NKRBxmjIRJqKPajSM8Bs0DpcgIClBo0DGRmYMkzpwNmTzSGycBiIYmVrk0TBA4evhcnEypQFGagiR6x8U6vAeKA72RYoqoG58MzVADGx1KYJGdaxmZkBIPfJGBrDBgsaRmHXjjg6tdWqC36LPAnODsckewSw1HQUyBQPEsbpOop1BFKCmalAYSpGwnxQ/Dd5/W5W+xkw/XDyw/xt/+fX7/LT548zMzMvCwoy2oG/X8Vj/P7+lOGPbqJy2AAAAAElFTkSuQmCC"

[xml]$splashXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SYNC PROJECT" Height="360" Width="360"
        WindowStartupLocation="CenterScreen"
        Background="Transparent" FontFamily="Segoe UI"
        WindowStyle="None" AllowsTransparency="True" ResizeMode="NoResize" Topmost="True">
  <Window.Resources>
    <DrawingBrush x:Key="SplashStripeBrush" TileMode="Tile" Viewport="0,0,14,16" ViewportUnits="Absolute">
      <DrawingBrush.Drawing>
        <DrawingGroup>
          <GeometryDrawing>
            <GeometryDrawing.Brush>
              <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                <GradientStop Color="#FFFFFF" Offset="0"/>
                <GradientStop Color="#8A4FFF" Offset="1"/>
              </LinearGradientBrush>
            </GeometryDrawing.Brush>
            <GeometryDrawing.Geometry>
              <RectangleGeometry Rect="0,0,9,16" RadiusX="4" RadiusY="4"/>
            </GeometryDrawing.Geometry>
          </GeometryDrawing>
        </DrawingGroup>
      </DrawingBrush.Drawing>
    </DrawingBrush>
  </Window.Resources>
  <Border x:Name="SplashOuterBorder" BorderThickness="1.2" CornerRadius="22" BorderBrush="#3A2C56">
    <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#0E0B1A" Offset="0"/><GradientStop Color="#080612" Offset="1"/></LinearGradientBrush></Border.Background>
    <Grid>
      <Grid.Clip>
        <RectangleGeometry Rect="0,0,358,358" RadiusX="21" RadiusY="21"/>
      </Grid.Clip>
      <Canvas x:Name="SplashBgCanvas" ClipToBounds="True" IsHitTestVisible="False"/>


      <Grid x:Name="SplashRoot">
        <Grid.RowDefinitions>
          <RowDefinition Height="40"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- ================= MINI TOP BAR (minimize + close buttons, top-right) ================= -->
        <Grid Grid.Row="0" x:Name="SplashTopBar" Background="Transparent">
          <Button x:Name="BtnSplashMinimize" Content="—" Width="20" Height="20" FontSize="9" Foreground="#B79BDD" BorderThickness="0" Cursor="Hand" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,10,34,0">
            <Button.Template>
              <ControlTemplate TargetType="Button">
                <Border x:Name="MinBg" CornerRadius="5" Background="Transparent">
                  <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                  <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="MinBg" Property="Background" Value="#221A33"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                  </Trigger>
                </ControlTemplate.Triggers>
              </ControlTemplate>
            </Button.Template>
          </Button>
          <Button x:Name="BtnSplashClose" Content="✕" Width="20" Height="20" FontSize="9" Foreground="#B79BDD" BorderThickness="0" Cursor="Hand" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,10,10,0">
            <Button.Template>
              <ControlTemplate TargetType="Button">
                <Border x:Name="CloseBg" CornerRadius="5" Background="Transparent">
                  <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                  <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="CloseBg" Property="Background" Value="#3A1F30"/>
                    <Setter Property="Foreground" Value="#FF7A93"/>
                  </Trigger>
                </ControlTemplate.Triggers>
              </ControlTemplate>
            </Button.Template>
          </Button>
        </Grid>

        <!-- ================= STATE HOST: START-group (logo/title/subtitle/button) and LOADING-group occupy the SAME centered cell, so whichever is visible sits dead-center with no leftover space from the other ================= -->
        <Grid Grid.Row="1" HorizontalAlignment="Center" VerticalAlignment="Center">

          <!-- ==== START / branding state (visible by default) ==== -->
          <StackPanel x:Name="SplashStartGroup" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,-26,0,0">
            <Image x:Name="SplashLogoImage" Width="64" Height="64" HorizontalAlignment="Center" Margin="0,0,0,8" Stretch="Uniform" RenderTransformOrigin="0.5,0.5">
              <Image.RenderTransform>
                <TranslateTransform x:Name="SplashLogoFloat" Y="0"/>
              </Image.RenderTransform>
            </Image>

            <TextBlock Text="SYNC PROJECT" FontSize="27" FontFamily="Segoe UI Black" FontStyle="Italic" FontWeight="ExtraBold" HorizontalAlignment="Center">
              <TextBlock.Foreground>
                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                  <GradientStop Color="#FFFFFF" Offset="0"/>
                  <GradientStop Color="#C79BFF" Offset="0.18"/>
                  <GradientStop Color="#8A4FFF" Offset="1"/>
                </LinearGradientBrush>
              </TextBlock.Foreground>
            </TextBlock>

            <TextBlock Text="PREMIUM SETTING &amp; OPTIMIZED NETWORK" FontFamily="Consolas" Foreground="#FFFFFF" FontSize="12.5" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,9,0,0"/>

            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,4,0,0">
              <TextBlock Text="BY SOFT STORE" FontFamily="Segoe UI" FontSize="13" FontWeight="Bold" Foreground="#C79BFF" VerticalAlignment="Center"/>
            </StackPanel>

            <Button x:Name="BtnSplashStart" Content="START" Width="175" Height="50" FontSize="20" FontFamily="Segoe UI Semibold" FontWeight="Bold" Foreground="#FFFFFF" BorderThickness="0" Cursor="Hand" HorizontalAlignment="Center" Margin="0,24,0,0">
              <Button.Template>
                <ControlTemplate TargetType="Button">
                  <Border x:Name="StartBorder" CornerRadius="12">
                    <Border.Background>
                      <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                        <GradientStop Color="#9B6FE0" Offset="0"/>
                        <GradientStop Color="#7A3FE0" Offset="0.55"/>
                        <GradientStop Color="#5F2FC7" Offset="1"/>
                      </LinearGradientBrush>
                    </Border.Background>
                    <Border.Effect>
                      <DropShadowEffect Color="#8A4FFF" BlurRadius="22" ShadowDepth="0" Opacity="0.6"/>
                    </Border.Effect>
                    <Grid>
                      <Border CornerRadius="12,12,0,0" VerticalAlignment="Top" Height="24" Opacity="0.18">
                        <Border.Background>
                          <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                            <GradientStop Color="#FFFFFF" Offset="0"/>
                            <GradientStop Color="#00FFFFFF" Offset="1"/>
                          </LinearGradientBrush>
                        </Border.Background>
                      </Border>
                      <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Grid>
                  </Border>
                  <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True">
                      <Setter TargetName="StartBorder" Property="Effect">
                        <Setter.Value>
                          <DropShadowEffect Color="#C9A6FF" BlurRadius="26" ShadowDepth="0" Opacity="0.85"/>
                        </Setter.Value>
                      </Setter>
                    </Trigger>
                  </ControlTemplate.Triggers>
                </ControlTemplate>
              </Button.Template>
            </Button>
          </StackPanel>

          <!-- ==== LOADING state (fades in on START, replaces the group above, dead-centered on its own) ==== -->
          <StackPanel x:Name="SplashLoadingGroup" Opacity="0" IsHitTestVisible="False" HorizontalAlignment="Center" VerticalAlignment="Center">

            <!-- ============ CIRCULAR PROGRESS RING WITH LOGO (same purple tone as START screen) ============ -->
            <Grid x:Name="SplashRingWrap" Width="136" Height="136" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,0,16">

              <!-- decorative rotating dashed ring, always spinning, purely for depth/motion -->
              <Ellipse x:Name="SplashRingAmbient" Width="136" Height="136" Stroke="#4B3A73" StrokeThickness="1.4" StrokeDashArray="2,9" Opacity="0.55">
                <Ellipse.RenderTransform>
                  <RotateTransform x:Name="SplashRingAmbientRotate" Angle="0" CenterX="68" CenterY="68"/>
                </Ellipse.RenderTransform>
              </Ellipse>

              <!-- static track -->
              <Ellipse Width="112" Height="112" Stroke="#241B38" StrokeThickness="6"/>

              <!-- real progress arc -->
              <Ellipse x:Name="SplashRingProgress" Width="112" Height="112" Stroke="#8A4FFF" StrokeThickness="6" StrokeStartLineCap="Round" StrokeEndLineCap="Round">
                <Ellipse.RenderTransform>
                  <RotateTransform Angle="-90" CenterX="56" CenterY="56"/>
                </Ellipse.RenderTransform>
                <Ellipse.Effect>
                  <DropShadowEffect Color="#8A4FFF" BlurRadius="16" ShadowDepth="0" Opacity="0.8"/>
                </Ellipse.Effect>
              </Ellipse>

              <!-- center logo, gently breathing for a touch of life/depth -->
              <Image x:Name="SplashLoadingLogoImage" Width="52" Height="52" HorizontalAlignment="Center" VerticalAlignment="Center" Stretch="Uniform" RenderTransformOrigin="0.5,0.5">
                <Image.RenderTransform>
                  <ScaleTransform x:Name="SplashLogoBreathe" ScaleX="1" ScaleY="1"/>
                </Image.RenderTransform>
              </Image>
            </Grid>

            <StackPanel x:Name="SplashLoadingWrap" HorizontalAlignment="Center">
              <TextBlock Text="LOADING" FontFamily="Segoe UI Black" FontStyle="Italic" FontSize="34" FontWeight="Bold" HorizontalAlignment="Center">
                <TextBlock.Foreground>
                  <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                    <GradientStop Color="#FFFFFF" Offset="0"/>
                    <GradientStop Color="#C79BFF" Offset="0.18"/>
                    <GradientStop Color="#8A4FFF" Offset="1"/>
                  </LinearGradientBrush>
                </TextBlock.Foreground>
              </TextBlock>
              <TextBlock FontFamily="Consolas" Foreground="#B79BDD" FontSize="11" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,4,0,0">
                <Run Text="CONNECTING TO SYNC SETTING"/><Run x:Name="SplashConnectingDots" Text="..."/>
              </TextBlock>
            </StackPanel>

            <!-- ============ LONG PILL-SHAPED LOADING TUBE ============ -->
            <StackPanel x:Name="SplashStripeWrap" Width="300" HorizontalAlignment="Center" Margin="0,24,0,0">
              <Border Height="20" CornerRadius="10" Background="#1D1628" BorderBrush="#6C4FBF" BorderThickness="1.2" HorizontalAlignment="Stretch">
                <Grid Margin="2" ClipToBounds="True">
                  <Border x:Name="SplashLoadingFill" CornerRadius="8" HorizontalAlignment="Left" Width="0">
                    <Border.Background>
                      <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                        <GradientStop Color="#C79BFF" Offset="0"/>
                        <GradientStop Color="#8A4FFF" Offset="1"/>
                      </LinearGradientBrush>
                    </Border.Background>
                  </Border>
                </Grid>
              </Border>
              <TextBlock x:Name="SplashRingPercentText" Text="0%" FontFamily="Consolas" Foreground="#D9C2FF" FontSize="14" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,8,0,0"/>
            </StackPanel>
          </StackPanel>
        </Grid>
      </Grid>
    </Grid>
  </Border>
</Window>
"@
$splashReader = New-Object System.Xml.XmlNodeReader $splashXaml
$splashWindow = [Windows.Markup.XamlReader]::Load($splashReader)

# --- DEBUG logger, attached to the UI-thread dispatcher BEFORE the splash shows, so a crash/loop
# during the splash loading is captured too (same dispatcher is reused by the main window). ---
$Global:DebugLog = Join-Path $env:TEMP "SyncProject_error.log"
function Trace-Dbg($m){ try { Add-Content -Path $Global:DebugLog -Value ("[{0}] {1}" -f (Get-Date -Format o), $m) -Encoding UTF8 } catch {} }
Remove-Item $Global:DebugLog -EA SilentlyContinue
Trace-Dbg "=== splash window loaded ==="
$splashWindow.Dispatcher.Add_UnhandledException({
    param($src,$ev)
    try { Add-Content -Path $Global:DebugLog -Value ("[{0}] UNHANDLED: {1}`r`n{2}" -f (Get-Date -Format o), $ev.Exception.Message, $ev.Exception.StackTrace) -Encoding UTF8 } catch {}
    $ev.Handled = $true
})

$SplashRoot           = $splashWindow.FindName("SplashRoot")
$SplashBgCanvas       = $splashWindow.FindName("SplashBgCanvas")
$SplashTopBar         = $splashWindow.FindName("SplashTopBar")
$BtnSplashMinimize    = $splashWindow.FindName("BtnSplashMinimize")
$BtnSplashClose       = $splashWindow.FindName("BtnSplashClose")
$BtnSplashStart       = $splashWindow.FindName("BtnSplashStart")
$SplashLogoImage      = $splashWindow.FindName("SplashLogoImage")
$SplashStartGroup     = $splashWindow.FindName("SplashStartGroup")
$SplashLoadingGroup   = $splashWindow.FindName("SplashLoadingGroup")
$SplashLoadingWrap    = $splashWindow.FindName("SplashLoadingWrap")
$SplashLoadingFill    = $splashWindow.FindName("SplashLoadingFill")
$SplashStripeWrap     = $splashWindow.FindName("SplashStripeWrap")
$SplashRingPercentText = $splashWindow.FindName("SplashRingPercentText")
$SplashRingProgress   = $splashWindow.FindName("SplashRingProgress")
$SplashLoadingLogoImage = $splashWindow.FindName("SplashLoadingLogoImage")
$SplashRingAmbientRotate = $splashWindow.FindName("SplashRingAmbientRotate")
$SplashLogoBreathe       = $splashWindow.FindName("SplashLogoBreathe")
$SplashLogoFloat         = $splashWindow.FindName("SplashLogoFloat")
$SplashConnectingDots    = $splashWindow.FindName("SplashConnectingDots")

try {
    $splashLogoBytes = [Convert]::FromBase64String($Global:SplashLogoBase64)
    $splashLogoStream = New-Object -TypeName System.IO.MemoryStream -ArgumentList @(,$splashLogoBytes)
    $splashLogoBitmap = New-Object System.Windows.Media.Imaging.BitmapImage
    $splashLogoBitmap.BeginInit()
    $splashLogoBitmap.StreamSource = $splashLogoStream
    $splashLogoBitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $splashLogoBitmap.EndInit()
    $SplashLogoImage.Source = $splashLogoBitmap
    $SplashLoadingLogoImage.Source = $splashLogoBitmap
} catch { }

# Gentle continuous float/bob for the logo on the START screen, so it feels alive even before loading starts.
$logoFloat = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
$logoFloat.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
$lf0 = [System.Windows.Media.Animation.EasingDoubleKeyFrame]::new([double]0,  [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds(0)))
$lf1 = [System.Windows.Media.Animation.EasingDoubleKeyFrame]::new([double]-8, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds(1.4)))
$lf2 = [System.Windows.Media.Animation.EasingDoubleKeyFrame]::new([double]0,  [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds(2.8)))
foreach ($kf in @($lf0,$lf1,$lf2)) {
    $ease = New-Object System.Windows.Media.Animation.SineEase
    $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseInOut
    $kf.EasingFunction = $ease
    $logoFloat.KeyFrames.Add($kf) | Out-Null
}
$SplashLogoFloat.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $logoFloat)

# Soft premium glow + faint drifting particles behind the title, for depth (no lightning/busy grid).
New-SplashAura -Canvas $SplashBgCanvas -Width 360 -Height 360 -CenterX 180 -CenterY 130 -ParticleCount 9
Add-BackgroundParallax -TargetWindow $splashWindow -Canvas $SplashBgCanvas -MaxOffset 12 -DurationX 8 -DurationY 6.5

# Simple fade-in for the whole card
$SplashRoot.Opacity = 0
$fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
$fadeIn.From = 0
$fadeIn.To = 1
$fadeIn.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(0.5))
$SplashRoot.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeIn)

# Tracks whether the user closed the splash with the X button (full program exit)
# rather than pressing START (proceed into the main console).
$Global:SplashClosedByX = $false

# Animates the loading bar from 0 -> 100% and then hands off to the main console.
# Runs on a DispatcherTimer so the UI stays responsive while it fills.
# NOTE: the timer and its width constant are stored in Global scope (not local to this
# function) because the Tick event fires later, after this function has already returned -
# a local variable would fall out of scope and read back as $null.
function Start-SplashLoading {
    Trace-Dbg "Start-SplashLoading ENTER"
    $BtnSplashStart.IsEnabled = $false
    $BtnSplashStart.Content = "LOADING"
    $SplashLoadingFill.Width = 0
    $SplashRingPercentText.Text = "0%"

    # Circular ring math: dash-array units in WPF are multiples of StrokeThickness,
    # so total "distance" around the ring = circumference / thickness.
    $Global:SplashRingThickness = 6.0
    $Global:SplashRingCircumference = [math]::PI * (112 - $Global:SplashRingThickness)
    $Global:SplashRingDashUnits = $Global:SplashRingCircumference / $Global:SplashRingThickness
    $initialDashArray = New-Object System.Windows.Media.DoubleCollection
    $initialDashArray.Add(0)
    $initialDashArray.Add([double]($Global:SplashRingDashUnits * 3))
    $SplashRingProgress.StrokeDashArray = $initialDashArray

    # Continuous ambient ring spin - decorative only, unrelated to actual % progress, just for depth/motion.
    $ambientSpin = New-Object System.Windows.Media.Animation.DoubleAnimation
    $ambientSpin.From = 0; $ambientSpin.To = 360
    $ambientSpin.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(6))
    $ambientSpin.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $SplashRingAmbientRotate.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $ambientSpin)

    # Gentle breathing pulse on the center logo for a touch of depth/life.
    $breatheX = New-Object System.Windows.Media.Animation.DoubleAnimation
    $breatheX.From = 1.0; $breatheX.To = 1.08
    $breatheX.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(1.1))
    $breatheX.AutoReverse = $true
    $breatheX.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $breatheX.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
    $breatheY = $breatheX.Clone()
    $SplashLogoBreathe.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $breatheX)
    $SplashLogoBreathe.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $breatheY)

    # Animated "..." after CONNECTING TO SYNC SETTING - cycles "." / ".." / "..." on its own timer.
    $Global:SplashDotsFrames = @(".", "..", "...")
    $Global:SplashDotsIndex = 2
    $Global:SplashDotsTimer = New-Object System.Windows.Threading.DispatcherTimer
    $Global:SplashDotsTimer.Interval = [TimeSpan]::FromMilliseconds(450)
    $Global:SplashDotsTimer.Add_Tick({
        $Global:SplashDotsIndex = ($Global:SplashDotsIndex + 1) % $Global:SplashDotsFrames.Count
        $SplashConnectingDots.Text = $Global:SplashDotsFrames[$Global:SplashDotsIndex]
    })
    $Global:SplashDotsTimer.Start()

    $splashFadeOut = New-Object System.Windows.Media.Animation.DoubleAnimation
    $splashFadeOut.From = 1
    $splashFadeOut.To = 0
    $splashFadeOut.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(0.2))
    $SplashStartGroup.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $splashFadeOut)
    $SplashStartGroup.IsHitTestVisible = $false

    $splashFadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
    $splashFadeIn.From = 0
    $splashFadeIn.To = 1
    $splashFadeIn.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(0.25))
    $SplashLoadingGroup.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $splashFadeIn)

    # Inner width of the thin progress bar: 260 fixed bar width - 2/2 inner grid margin
    $Global:SplashLoadFullWidth = 300 - 4
    $Global:SplashLoadPct = 0

    $Global:SplashLoadTimer = New-Object System.Windows.Threading.DispatcherTimer
    $Global:SplashLoadTimer.Interval = [TimeSpan]::FromMilliseconds(50)
    $Global:SplashLoadTimer.Add_Tick({
        $Global:SplashLoadPct += 1
        if ($Global:SplashLoadPct -ge 100) {
            $Global:SplashLoadPct = 100
        }
        $fillWidthNow = [double]$Global:SplashLoadFullWidth * ($Global:SplashLoadPct / 100.0)
        $SplashLoadingFill.Width = $fillWidthNow
        $SplashRingPercentText.Text = "$($Global:SplashLoadPct)%"

        $ringDash = $Global:SplashRingDashUnits * ($Global:SplashLoadPct / 100.0)
        $ringGap  = $Global:SplashRingDashUnits * 3
        $ringDashArray = New-Object System.Windows.Media.DoubleCollection
        $ringDashArray.Add([double]$ringDash)
        $ringDashArray.Add([double]$ringGap)
        $SplashRingProgress.StrokeDashArray = $ringDashArray

        if ($Global:SplashLoadPct -ge 100) {
            $Global:SplashLoadTimer.Stop()
            $Global:SplashDotsTimer.Stop()
            Trace-Dbg "splash reached 100% -> closing splash"
            $splashWindow.Close()
        }
    })
    $Global:SplashLoadTimer.Start()
}

Add-ClickFX $BtnSplashStart
Add-ClickFX $BtnSplashMinimize
Add-ClickFX $BtnSplashClose
$BtnSplashStart.Add_Click({ Start-SplashLoading })
$BtnSplashClose.Add_Click({ $Global:SplashClosedByX = $true; $splashWindow.Close() })
$BtnSplashMinimize.Add_Click({ $splashWindow.WindowState = 'Minimized' })
$SplashTopBar.Add_MouseLeftButtonDown({ $splashWindow.DragMove() })

Trace-Dbg "about to call splash ShowDialog"
$splashWindow.ShowDialog() | Out-Null
Trace-Dbg "splash ShowDialog RETURNED (SplashClosedByX=$($Global:SplashClosedByX))"

if ($Global:SplashClosedByX) {
    # User closed the splash screen with the X button - exit before the main console ever opens.
    Trace-Dbg "exiting because splash closed by X"
    exit
}


[xml]$xaml = $mainXamlStr
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

Trace-Dbg "=== main window loaded ==="

$MainBgCanvas = $window.FindName("MainBgCanvas")
$RootClipGeom = $window.FindName("RootClipGeom")
$MainLogoWatermark = $window.FindName("MainLogoWatermark")
try { if ($splashLogoBitmap) { $MainLogoWatermark.Source = $splashLogoBitmap } } catch {}
Add-BackgroundParallax -TargetWindow $window -Canvas $MainBgCanvas -MaxOffset 22 -DurationX 11 -DurationY 8.5

$TopBar=$window.FindName("TopBar"); $SearchBox=$window.FindName("SearchBox"); $SearchPH=$window.FindName("SearchPlaceholder")
$StatusText=$window.FindName("StatusText"); $StatusDotE=$window.FindName("StatusDotEllipse")
$BtnMin=$window.FindName("BtnMin"); $BtnMax=$window.FindName("BtnMax"); $BtnClose=$window.FindName("BtnClose")
$StagesPanel=$window.FindName("StagesPanel")
$ProgressFill=$window.FindName("ProgressFill"); $ProgressPct=$window.FindName("ProgressPercent")
$BtnRun=$window.FindName("BtnRun"); $BtnRestore=$window.FindName("BtnRestore")
$NetPresetLan=$window.FindName("NetPresetLan"); $NetPresetWifi=$window.FindName("NetPresetWifi")
$GpuPresetAmd=$window.FindName("GpuPresetAmd"); $GpuPresetNvidia=$window.FindName("GpuPresetNvidia")
$BtnPresetAllExceptGpuLan=$window.FindName("BtnPresetAllExceptGpuLan")
$BtnClear=$window.FindName("BtnClear"); $BtnDiscord=$window.FindName("BtnDiscord"); $BtnExit=$window.FindName("BtnExit")
$InfoOS=$window.FindName("InfoOS"); $InfoCPU=$window.FindName("InfoCPU"); $InfoGPU=$window.FindName("InfoGPU")
$InfoNET=$window.FindName("InfoNET"); $InfoRAM=$window.FindName("InfoRAM"); $InfoAdapter=$window.FindName("InfoAdapter")
$RamUsageFill=$window.FindName("RamUsageFill"); $RamUsageText=$window.FindName("RamUsageText")
$BtnTaskMgr=$window.FindName("BtnTaskMgr"); $BtnGpedit=$window.FindName("BtnGpedit"); $BtnClean=$window.FindName("BtnClean")
$LogScrollV=$window.FindName("LogScrollViewer"); $LogBox=$window.FindName("LogBox"); $CurrentTask=$window.FindName("CurrentTaskText")
$CategoryOverlay=$window.FindName("CategoryOverlay"); $CatOverlayTitle=$window.FindName("CatOverlayTitle")
$CatOverlayClipGeom=$window.FindName("CatOverlayClipGeom")
$CatOverlayBgCanvas=$window.FindName("CatOverlayBgCanvas")
Add-BackgroundParallax -TargetWindow $window -Canvas $CatOverlayBgCanvas -MaxOffset 14 -DurationX 9.5 -DurationY 7.5
$CatOverlayDesc=$window.FindName("CatOverlayDesc"); $CatOverlayItems=$window.FindName("CatOverlayItems")
$CatOverlayCloseX=$window.FindName("CatOverlayCloseX"); $CatOverlayCloseBtn=$window.FindName("CatOverlayCloseBtn")

$InfoOS.Text=$Global:SysInfo.OS; $InfoCPU.Text=$Global:SysInfo.CPU; $InfoGPU.Text=$Global:SysInfo.GPU
$InfoNET.Text=$Global:SysInfo.NetType; $InfoRAM.Text="$($Global:SysInfo.RAM) GB"
$InfoAdapter.Text=$Global:SysInfo.Adapter

$window.Add_Loaded({
    $maxW=$RamUsageFill.Parent.ActualWidth; if($maxW -le 0){$maxW=400}
    $pct=$Global:SysInfo.RAMUsedPct; $RamUsageFill.Width=[math]::Max(0,($pct/100.0)*$maxW); $RamUsageText.Text="$pct%"
    Play-StartupChime
})
$TopBar.Add_MouseLeftButtonDown({ $window.DragMove() })
$BtnClose.Add_Click({ $window.Close() })
$BtnMin.Add_Click({ $window.WindowState="Minimized" })
$BtnMax.Add_Click({
    if($window.Tag -eq "Maximized"){
        $window.Width=$Global:NormalW; $window.Height=$Global:NormalH
        $window.Left=$Global:NormalL; $window.Top=$Global:NormalT
        $window.Tag=$null
    } else {
        $Global:NormalW=$window.Width; $Global:NormalH=$window.Height
        $Global:NormalL=$window.Left; $Global:NormalT=$window.Top
        $wa=[System.Windows.SystemParameters]::WorkArea
        $window.Left=$wa.Left; $window.Top=$wa.Top
        $window.Width=$wa.Width; $window.Height=$wa.Height
        $window.Tag="Maximized"
    }
})
# Keep the rounded-corner clip matched to the actual window size so resizing/maximizing
# never leaves stray hairlines at the edges or a stuck/oversized render surface.
$window.Add_SizeChanged({
    if($window.ActualWidth -gt 2 -and $window.ActualHeight -gt 2){
        $RootClipGeom.Rect=[System.Windows.Rect]::new(0,0,$window.ActualWidth-2,$window.ActualHeight-2)
    }
})
# The category overlay's clip geometry was hardcoded to 600x600 in XAML, but the overlay
# itself stretches to fill the whole right-hand panel (which is wider than 600px on most
# window sizes). That mismatch pushed each row's toggle switch (right-aligned "Auto" column)
# past the clipped/visible area, so the switches rendered off-screen and couldn't be clicked.
# Keep the clip synced to the overlay's actual size, the same way RootClipGeom tracks the window.
$CategoryOverlay.Add_SizeChanged({
    if($CategoryOverlay.ActualWidth -gt 2 -and $CategoryOverlay.ActualHeight -gt 2){
        $CatOverlayClipGeom.Rect=[System.Windows.Rect]::new(0,0,$CategoryOverlay.ActualWidth,$CategoryOverlay.ActualHeight)
    }
})

$Global:LogLines=[System.Collections.Generic.List[string]]::new()
function Add-Log {
    param([string]$msg,[string]$color="#6B7280")
    $Global:LogLines.Add($msg)
    $window.Dispatcher.Invoke([Action]{
        $run=New-Object System.Windows.Documents.Run; $run.Text="> $msg`n"
        try{$run.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString($color)}catch{}
        $LogBox.Inlines.Add($run); $LogScrollV.ScrollToEnd()
    })
}
$Global:StageCBs=@{}
$Global:CategoryInfo = @(
    @{Group="LAN NETWORK";           Icon="⚡"; Desc="TCP/network stack tuning and adapter-level tweaks for wired Ethernet connections."; Accent=@(0x38,0xBD,0xF8)}
    @{Group="WI-FI NETWORK";         Icon="⚡"; Desc="TCP/network stack tuning and adapter-level tweaks for Wi-Fi connections."; Accent=@(0x2D,0xD4,0xBF)}
    @{Group="INPUT LAG";             Icon="⌨"; Desc="Keyboard, mouse, and USB tweaks aimed at reducing input delay."; Accent=@(0x9B,0x5D,0xE5)}
    @{Group="SYSTEM & TIMING";      Icon="■"; Desc="Timer resolution, power throttling, and driver health checks for a steadier system."; Accent=@(0x9B,0x5D,0xE5)}
    @{Group="GAMING & MEMORY";      Icon="▶"; Desc="Memory prioritization and fullscreen/overlay tweaks aimed at smoother gaming."; Accent=@(0x9B,0x5D,0xE5)}
    @{Group="INTERFACE & CLEANUP";  Icon="✓"; Desc="Instant menus, disabled notifications, and background maintenance kept out of the way."; Accent=@(0x9B,0x5D,0xE5)}
    @{Group="NVIDIA GPU";           Icon="◆"; Desc="NVD - Driver-level tweaks for NVIDIA (green) cards, plus the universal GPU timeout fix."; Accent=@(0x76,0xB9,0x00)}
    @{Group="AMD GPU";              Icon="◆"; Desc="Driver-level tweaks for AMD (red) cards, plus the universal GPU timeout fix."; Accent=@(0xED,0x1C,0x24)}
    @{Group="GPU & CACHE";           Icon="🗑"; Desc="Shader cache, temp files, and game-cache cleanup, plus a quick CPU/GPU load check."; Accent=@(0xF5,0x9E,0x0B)}
)
# What each tweak actually touches under the hood, shown as a small badge in the detail view.
$Global:TagMeta = @{
    REG      = @{ Label="REGISTRY"; Bg=@(0x1E,0x2A,0x45); Fg=@(0x60,0xA5,0xFA) }
    TCP      = @{ Label="TCP/NETSH"; Bg=@(0x27,0x1E,0x45); Fg=@(0xA7,0x8B,0xFA) }
    GPEDIT   = @{ Label="GPEDIT"; Bg=@(0x40,0x2A,0x1A); Fg=@(0xF5,0x9E,0x0B) }
    SVC      = @{ Label="SERVICE"; Bg=@(0x40,0x1A,0x1A); Fg=@(0xEF,0x44,0x44) }
    POWERCFG = @{ Label="POWERCFG"; Bg=@(0x1A,0x33,0x28); Fg=@(0x10,0xB9,0x81) }
    BCD      = @{ Label="BCD/BOOT"; Bg=@(0x14,0x33,0x38); Fg=@(0x2D,0xD4,0xBF) }
    ADAPTER  = @{ Label="ADAPTER"; Bg=@(0x14,0x2E,0x3D); Fg=@(0x38,0xBD,0xF8) }
    WMI      = @{ Label="WMI"; Bg=@(0x28,0x28,0x28); Fg=@(0x9C,0xA3,0xAF) }
    PROC     = @{ Label="PROCESS"; Bg=@(0x40,0x38,0x14); Fg=@(0xEA,0xB3,0x08) }
    API      = @{ Label="WIN API"; Bg=@(0x38,0x1A,0x38); Fg=@(0xE8,0x79,0xF9) }
    TASK     = @{ Label="SCHED. TASK"; Bg=@(0x33,0x24,0x14); Fg=@(0xF9,0x9B,0x5D) }
}
function Get-LighterRgb($rgb, [double]$amt=0.55) {
    $r=[math]::Round($rgb[0] + (255-$rgb[0])*$amt); $g=[math]::Round($rgb[1] + (255-$rgb[1])*$amt); $b=[math]::Round($rgb[2] + (255-$rgb[2])*$amt)
    return @([byte]$r,[byte]$g,[byte]$b)
}
function New-IconBrush($rgb) {
    $light=Get-LighterRgb $rgb 0.55
    $brush=New-Object System.Windows.Media.LinearGradientBrush
    $brush.StartPoint=New-Object System.Windows.Point(0,0); $brush.EndPoint=New-Object System.Windows.Point(1,1)
    $brush.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromRgb($light[0],$light[1],$light[2]),0)))
    $brush.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromRgb($rgb[0],$rgb[1],$rgb[2]),1)))
    return $brush
}
function New-CategoryIconVisual([string]$GroupName, $AccentRgb, [bool]$IsActive) {
    $fgRgb= if($IsActive){$AccentRgb} else {@(0x9C,0xA3,0xAF)}
    $brush=New-IconBrush $fgRgb
    $canvas=New-Object System.Windows.Controls.Canvas; $canvas.Width=24; $canvas.Height=24
    switch($GroupName){
        "LAN NETWORK" {
            foreach($pt in @(@(12,7,6,16),@(12,7,18,16))){
                $l=New-Object System.Windows.Shapes.Line; $l.X1=$pt[0];$l.Y1=$pt[1];$l.X2=$pt[2];$l.Y2=$pt[3]
                $l.Stroke=$brush; $l.StrokeThickness=1.6; $l.StrokeStartLineCap="Round"; $l.StrokeEndLineCap="Round"
                $canvas.Children.Add($l)|Out-Null
            }
            foreach($n in @(@(9.8,2.8),@(3.8,15.8),@(15.8,15.8))){
                $e=New-Object System.Windows.Shapes.Ellipse; $e.Width=4.4; $e.Height=4.4; $e.Fill=$brush
                [System.Windows.Controls.Canvas]::SetLeft($e,$n[0]); [System.Windows.Controls.Canvas]::SetTop($e,$n[1])
                $canvas.Children.Add($e)|Out-Null
            }
        }
        "WI-FI NETWORK" {
            foreach($bar in @(@(3,14,6),@(10,9,11),@(17,4,16))){
                $r=New-Object System.Windows.Shapes.Rectangle; $r.Width=4; $r.Height=$bar[2]; $r.RadiusX=1; $r.RadiusY=1; $r.Fill=$brush
                [System.Windows.Controls.Canvas]::SetLeft($r,$bar[0]); [System.Windows.Controls.Canvas]::SetTop($r,$bar[1])
                $canvas.Children.Add($r)|Out-Null
            }
        }
        "INPUT LAG" {
            $body=New-Object System.Windows.Shapes.Rectangle; $body.Width=20; $body.Height=13; $body.RadiusX=3; $body.RadiusY=3; $body.Fill=$brush; $body.Opacity=0.28
            [System.Windows.Controls.Canvas]::SetLeft($body,2); [System.Windows.Controls.Canvas]::SetTop($body,6)
            $canvas.Children.Add($body)|Out-Null
            $keys=@(@(4.5,8.5),@(7.7,8.5),@(10.9,8.5),@(14.1,8.5),@(17.3,8.5),@(4.5,11.7),@(7.7,11.7),@(10.9,11.7),@(14.1,11.7),@(17.3,11.7),@(6,14.9),@(9.5,14.9),@(14.5,14.9),@(18,14.9))
            foreach($p in $keys){
                $k=New-Object System.Windows.Shapes.Rectangle; $k.Width=2.2; $k.Height=2.2; $k.RadiusX=0.5; $k.RadiusY=0.5; $k.Fill=$brush
                [System.Windows.Controls.Canvas]::SetLeft($k,$p[0]); [System.Windows.Controls.Canvas]::SetTop($k,$p[1])
                $canvas.Children.Add($k)|Out-Null
            }
        }
        "SYSTEM & TIMING" {
            $arc=New-Object System.Windows.Shapes.Path; $arc.Data=[System.Windows.Media.Geometry]::Parse("M4,17 A8,8 0 1 1 20,17")
            $arc.Stroke=$brush; $arc.StrokeThickness=2; $arc.StrokeStartLineCap="Round"; $arc.StrokeEndLineCap="Round"
            $canvas.Children.Add($arc)|Out-Null
            $needle=New-Object System.Windows.Shapes.Line; $needle.X1=12; $needle.Y1=17; $needle.X2=16; $needle.Y2=10
            $needle.Stroke=$brush; $needle.StrokeThickness=1.8; $needle.StrokeStartLineCap="Round"; $needle.StrokeEndLineCap="Round"
            $canvas.Children.Add($needle)|Out-Null
            $hub=New-Object System.Windows.Shapes.Ellipse; $hub.Width=3; $hub.Height=3; $hub.Fill=$brush
            [System.Windows.Controls.Canvas]::SetLeft($hub,10.5); [System.Windows.Controls.Canvas]::SetTop($hub,15.5)
            $canvas.Children.Add($hub)|Out-Null
        }
        "GAMING & MEMORY" {
            $bodyGeom=[System.Windows.Media.Geometry]::Parse("M6,9 L18,9 A4,4 0 0 1 22,13 L22,15 A3,3 0 0 1 17,17.5 L15,15 L9,15 L7,17.5 A3,3 0 0 1 2,15 L2,13 A4,4 0 0 1 6,9 Z")
            $bodyPath=New-Object System.Windows.Shapes.Path; $bodyPath.Data=$bodyGeom; $bodyPath.Fill=$brush
            $canvas.Children.Add($bodyPath)|Out-Null
            $dpadV=New-Object System.Windows.Shapes.Rectangle; $dpadV.Width=1.6; $dpadV.Height=5; $dpadV.Fill="#0F0C1A"
            [System.Windows.Controls.Canvas]::SetLeft($dpadV,7.2); [System.Windows.Controls.Canvas]::SetTop($dpadV,10.5)
            $dpadH=New-Object System.Windows.Shapes.Rectangle; $dpadH.Width=5; $dpadH.Height=1.6; $dpadH.Fill="#0F0C1A"
            [System.Windows.Controls.Canvas]::SetLeft($dpadH,5.5); [System.Windows.Controls.Canvas]::SetTop($dpadH,12.2)
            $canvas.Children.Add($dpadV)|Out-Null; $canvas.Children.Add($dpadH)|Out-Null
            foreach($b in @(@(16.5,10.5),@(18.5,12.5))){
                $btn=New-Object System.Windows.Shapes.Ellipse; $btn.Width=2; $btn.Height=2; $btn.Fill="#0F0C1A"
                [System.Windows.Controls.Canvas]::SetLeft($btn,$b[0]); [System.Windows.Controls.Canvas]::SetTop($btn,$b[1])
                $canvas.Children.Add($btn)|Out-Null
            }
        }
        "INTERFACE & CLEANUP" {
            $star=New-Object System.Windows.Shapes.Path; $star.Data=[System.Windows.Media.Geometry]::Parse("M12,2 L14,9 L21,11 L14,13 L12,20 L10,13 L3,11 L10,9 Z")
            $star.Fill=$brush
            $canvas.Children.Add($star)|Out-Null
        }
        {$_ -eq "NVIDIA GPU" -or $_ -eq "AMD GPU"} {
            $chip=New-Object System.Windows.Shapes.Rectangle; $chip.Width=16; $chip.Height=12; $chip.RadiusX=2; $chip.RadiusY=2; $chip.Fill=$brush
            [System.Windows.Controls.Canvas]::SetLeft($chip,4); [System.Windows.Controls.Canvas]::SetTop($chip,6)
            $canvas.Children.Add($chip)|Out-Null
            $fan=New-Object System.Windows.Shapes.Ellipse; $fan.Width=6; $fan.Height=6; $fan.Fill="#0F0C1A"; $fan.Opacity=0.55
            [System.Windows.Controls.Canvas]::SetLeft($fan,9); [System.Windows.Controls.Canvas]::SetTop($fan,9)
            $canvas.Children.Add($fan)|Out-Null
            foreach($p in @(@(6,3,6,6),@(10,3,10,6),@(14,3,14,6),@(6,18,6,15),@(10,18,10,15),@(14,18,14,15))){
                $pin=New-Object System.Windows.Shapes.Line; $pin.X1=$p[0]; $pin.Y1=$p[1]; $pin.X2=$p[2]; $pin.Y2=$p[3]
                $pin.Stroke=$brush; $pin.StrokeThickness=1.4
                $canvas.Children.Add($pin)|Out-Null
            }
        }
        "GPU & CACHE" {
            $lid=New-Object System.Windows.Shapes.Rectangle; $lid.Width=14; $lid.Height=2; $lid.RadiusX=1; $lid.RadiusY=1; $lid.Fill=$brush
            [System.Windows.Controls.Canvas]::SetLeft($lid,5); [System.Windows.Controls.Canvas]::SetTop($lid,6)
            $canvas.Children.Add($lid)|Out-Null
            $handle=New-Object System.Windows.Shapes.Rectangle; $handle.Width=5; $handle.Height=2.5; $handle.RadiusX=1; $handle.RadiusY=1; $handle.Fill=$brush
            [System.Windows.Controls.Canvas]::SetLeft($handle,9.5); [System.Windows.Controls.Canvas]::SetTop($handle,3.2)
            $canvas.Children.Add($handle)|Out-Null
            $bin=New-Object System.Windows.Shapes.Path; $bin.Data=[System.Windows.Media.Geometry]::Parse("M6.5,9 L17.5,9 L16.5,20 A2,2 0 0 1 14.5,22 L9.5,22 A2,2 0 0 1 7.5,20 Z")
            $bin.Fill=$brush
            $canvas.Children.Add($bin)|Out-Null
        }
        default {
            $dot=New-Object System.Windows.Shapes.Ellipse; $dot.Width=10; $dot.Height=10; $dot.Fill=$brush
            [System.Windows.Controls.Canvas]::SetLeft($dot,7); [System.Windows.Controls.Canvas]::SetTop($dot,7)
            $canvas.Children.Add($dot)|Out-Null
        }
    }
    $vb=New-Object System.Windows.Controls.Viewbox; $vb.Width=16; $vb.Height=16; $vb.Stretch="Uniform"; $vb.Child=$canvas
    $shadow=New-Object System.Windows.Media.Effects.DropShadowEffect
    $shadow.Color=[System.Windows.Media.Color]::FromRgb($fgRgb[0],$fgRgb[1],$fgRgb[2]); $shadow.BlurRadius=6; $shadow.ShadowDepth=0; $shadow.Opacity=0.55
    $vb.Effect=$shadow
    return $vb
}
function Build-StageCards {
    param([string]$filter="")
    $StagesPanel.Children.Clear()
    $groupOrder=@("LAN NETWORK","WI-FI NETWORK","INPUT LAG","SYSTEM & TIMING","GAMING & MEMORY","INTERFACE & CLEANUP","NVIDIA GPU","AMD GPU","GPU & CACHE")
    if ($Global:DetectedGpuVendor -eq "NVIDIA") { $groupOrder = $groupOrder | Where-Object { $_ -ne "AMD GPU" } }
    elseif ($Global:DetectedGpuVendor -eq "AMD") { $groupOrder = $groupOrder | Where-Object { $_ -ne "NVIDIA GPU" } }
    # If $Global:DetectedGpuVendor -eq "BOTH" (hybrid system), keep both GPU categories visible.
    foreach ($groupName in $groupOrder) {
        $catMeta=$Global:CategoryInfo | Where-Object { $_.Group -eq $groupName }
        $itemsInGroup=$Global:TweakInfo | Where-Object { $_.Group -eq $groupName }
        $matches= -not $filter -or $groupName -like "*$filter*" -or ($itemsInGroup | Where-Object { $_.Title -like "*$filter*" -or $_.Category -like "*$filter*" })
        if(-not $matches){continue}
        $isActive = ($Global:ActiveCategory -eq $groupName)
        $accentColor= if($catMeta.Accent){$catMeta.Accent}else{0x9B,0x5D,0xE5}
        $card=New-Object System.Windows.Controls.Border
        $card.CornerRadius="10"; $card.BorderThickness="1"; $card.Margin="0,0,0,7"; $card.Padding="12,11"; $card.Cursor="Hand"
        $bgColor= if($isActive){0x1E,0x16,0x30}else{0x13,0x0F,0x20}
        $borderColor= if($isActive){$accentColor}else{0x2A,0x1F,0x42}
        $card.Background=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($bgColor[0],$bgColor[1],$bgColor[2]))
        $card.BorderBrush=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($borderColor[0],$borderColor[1],$borderColor[2]))
        $grid=New-Object System.Windows.Controls.Grid
        $c1=New-Object System.Windows.Controls.ColumnDefinition; $c1.Width="Auto"
        $c2=New-Object System.Windows.Controls.ColumnDefinition; $c2.Width="*"
        $c3=New-Object System.Windows.Controls.ColumnDefinition; $c3.Width="Auto"
        $grid.ColumnDefinitions.Add($c1)|Out-Null; $grid.ColumnDefinitions.Add($c2)|Out-Null; $grid.ColumnDefinitions.Add($c3)|Out-Null
        # icon circle
        $iconBd=New-Object System.Windows.Controls.Border
        $iconBd.Width=30; $iconBd.Height=30; $iconBd.CornerRadius=15; $iconBd.Margin="0,0,10,0"
        $iconBg= if($isActive){0x3D,0x2D,0x5C}else{0x1E,0x14,0x30}
        $iconBgLight=Get-LighterRgb $iconBg 0.25
        $iconBgBrush=New-Object System.Windows.Media.RadialGradientBrush
        $iconBgBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromRgb($iconBgLight[0],$iconBgLight[1],$iconBgLight[2]),0)))
        $iconBgBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromRgb($iconBg[0],$iconBg[1],$iconBg[2]),1)))
        $iconBd.Background=$iconBgBrush
        $iconVisual=New-CategoryIconVisual -GroupName $groupName -AccentRgb $accentColor -IsActive $isActive
        $iconBd.Child=$iconVisual
        [System.Windows.Controls.Grid]::SetColumn($iconBd,0)
        # title + desc
        $sp=New-Object System.Windows.Controls.StackPanel; [System.Windows.Controls.Grid]::SetColumn($sp,1)
        $title=New-Object System.Windows.Controls.TextBlock
        $title.Text=$groupName; $title.FontSize=10.5; $title.FontWeight="SemiBold"
        $title.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0xE5,0xE7,0xEB))
        $desc=New-Object System.Windows.Controls.TextBlock
        $desc.Text=$catMeta.Desc; $desc.FontSize=8.5; $desc.TextWrapping="Wrap"; $desc.Margin="0,3,0,0"
        $desc.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x6B,0x72,0x80))
        $sp.Children.Add($title)|Out-Null; $sp.Children.Add($desc)|Out-Null
        # active accent bar
        if($isActive){
            $accent=New-Object System.Windows.Controls.Border
            $accent.Width=3; $accent.CornerRadius=2; $accent.Margin="8,0,0,0"; $accent.VerticalAlignment="Stretch"
            $accent.Background=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($accentColor[0],$accentColor[1],$accentColor[2]))
            [System.Windows.Controls.Grid]::SetColumn($accent,2)
            $grid.Children.Add($accent)|Out-Null
        }
        $grid.Children.Add($iconBd)|Out-Null; $grid.Children.Add($sp)|Out-Null; $card.Child=$grid
        $capturedGroup=$groupName
        $card.Add_MouseLeftButtonUp({ Show-CategoryDetail $capturedGroup }.GetNewClosure())
        $StagesPanel.Children.Add($card)|Out-Null
    }
}
function Show-CategoryDetail {
    param([string]$groupName)
    $Global:ActiveCategory=$groupName
    $CatOverlayTitle.Text=$groupName
    $catMeta=$Global:CategoryInfo | Where-Object { $_.Group -eq $groupName }
    $CatOverlayDesc.Text=$catMeta.Desc
    $CatOverlayItems.Children.Clear()
    $itemsInGroup=$Global:TweakInfo | Where-Object { $_.Group -eq $groupName }
    if($itemsInGroup){
        $summaryWrap=New-Object System.Windows.Controls.WrapPanel
        $summaryWrap.Margin="0,0,0,14"
        $tagGroups=$itemsInGroup | Group-Object Tag | Sort-Object Count -Descending
        foreach($tg in $tagGroups){
            if(-not $tg.Name -or -not $Global:TagMeta.ContainsKey($tg.Name)){continue}
            $tm=$Global:TagMeta[$tg.Name]
            $chip=New-Object System.Windows.Controls.Border
            $chip.CornerRadius="6"; $chip.Padding="7,3"; $chip.Margin="0,0,6,6"
            $chip.Background=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($tm.Bg[0],$tm.Bg[1],$tm.Bg[2]))
            $chipTxt=New-Object System.Windows.Controls.TextBlock
            $chipTxt.Text="$($tg.Count) $($tm.Label)"; $chipTxt.FontSize=8.5; $chipTxt.FontWeight="Bold"
            $chipTxt.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($tm.Fg[0],$tm.Fg[1],$tm.Fg[2]))
            $chip.Child=$chipTxt
            $summaryWrap.Children.Add($chip)|Out-Null
        }
        $CatOverlayItems.Children.Add($summaryWrap)|Out-Null
    }
    foreach ($t in $itemsInGroup) {
        $key=$t.Key; $isOn=$Global:TweakToggles[$key]
        $row=New-Object System.Windows.Controls.Border
        $row.CornerRadius="10"; $row.BorderThickness="1"; $row.Margin="0,0,0,8"; $row.Padding="14,12"
        $row.Background=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x13,0x0F,0x20))
        $row.BorderBrush=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x2A,0x1F,0x42))
        $grid=New-Object System.Windows.Controls.Grid
        $c1=New-Object System.Windows.Controls.ColumnDefinition; $c1.Width="*"
        $c2=New-Object System.Windows.Controls.ColumnDefinition; $c2.Width="Auto"
        $grid.ColumnDefinitions.Add($c1)|Out-Null; $grid.ColumnDefinitions.Add($c2)|Out-Null
        $sp=New-Object System.Windows.Controls.StackPanel; [System.Windows.Controls.Grid]::SetColumn($sp,0)
        $sp.Margin="0,0,14,0"
        $headerRow=New-Object System.Windows.Controls.StackPanel; $headerRow.Orientation="Horizontal"; $headerRow.VerticalAlignment="Center"
        $title=New-Object System.Windows.Controls.TextBlock
        $title.Text=$t.Title; $title.FontSize=11; $title.FontWeight="SemiBold"; $title.TextWrapping="Wrap"; $title.VerticalAlignment="Center"
        $title.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0xE5,0xE7,0xEB))
        $headerRow.Children.Add($title)|Out-Null
        if($t.Tag -and $Global:TagMeta.ContainsKey($t.Tag)){
            $tm=$Global:TagMeta[$t.Tag]
            $badge=New-Object System.Windows.Controls.Border
            $badge.CornerRadius="6"; $badge.Padding="6,1"; $badge.Margin="8,0,0,0"; $badge.VerticalAlignment="Center"
            $badge.Background=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($tm.Bg[0],$tm.Bg[1],$tm.Bg[2]))
            $badgeTxt=New-Object System.Windows.Controls.TextBlock
            $badgeTxt.Text=$tm.Label; $badgeTxt.FontSize=7.5; $badgeTxt.FontWeight="Bold"
            $badgeTxt.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($tm.Fg[0],$tm.Fg[1],$tm.Fg[2]))
            $badge.Child=$badgeTxt
            $headerRow.Children.Add($badge)|Out-Null
        }
        $desc=New-Object System.Windows.Controls.TextBlock
        $desc.Text=$t.Desc; $desc.FontSize=9; $desc.TextWrapping="Wrap"; $desc.Margin="0,3,0,0"
        $desc.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x6B,0x72,0x80))
        $sp.Children.Add($headerRow)|Out-Null; $sp.Children.Add($desc)|Out-Null
        $cb=New-Object System.Windows.Controls.CheckBox
        $cb.Style=$window.Resources["ToggleStyle"]; $cb.IsChecked=$isOn; $cb.VerticalAlignment="Center"
        [System.Windows.Controls.Grid]::SetColumn($cb,1)
        $capturedKey=$key
        $cb.Add_Checked({$Global:TweakToggles[$capturedKey]=$true; Update-EnabledBadge; Update-PresetGlowConsistency; Save-TweakState}.GetNewClosure())
        $cb.Add_Unchecked({$Global:TweakToggles[$capturedKey]=$false; Update-EnabledBadge; Update-PresetGlowConsistency; Save-TweakState}.GetNewClosure())
        $Global:StageCBs[$key]=$cb
        $grid.Children.Add($sp)|Out-Null; $grid.Children.Add($cb)|Out-Null; $row.Child=$grid
        $CatOverlayItems.Children.Add($row)|Out-Null
    }
    $CategoryOverlay.Visibility="Visible"
    Build-StageCards
}
function Close-CategoryDetail {
    $CategoryOverlay.Visibility="Collapsed"
}
function Set-PresetGlow {
    param($Border,[bool]$Selected,[string]$AccentColor,[string]$DefaultColor="#2A1F42")
    if(-not $Border){ return }
    $bc = New-Object System.Windows.Media.BrushConverter
    if($Selected){
        $accent = $bc.ConvertFromString($AccentColor)
        $Border.BorderBrush = $accent
        $Border.BorderThickness = [System.Windows.Thickness]::new(1.6)
        if(-not ($Border.Effect -is [System.Windows.Media.Effects.DropShadowEffect])){
            $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $glow.Color = $accent.Color; $glow.BlurRadius = 16; $glow.ShadowDepth = 0; $glow.Opacity = 0
            $Border.Effect = $glow
        }
        $Border.Effect.Color = $accent.Color
        $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
        $anim.To = 0.85; $anim.Duration = [TimeSpan]::FromMilliseconds(200)
        $Border.Effect.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty,$anim)
    } else {
        $Border.BorderBrush = $bc.ConvertFromString($DefaultColor)
        $Border.BorderThickness = [System.Windows.Thickness]::new(1)
        if($Border.Effect -is [System.Windows.Media.Effects.DropShadowEffect]){
            $glowEffect = $Border.Effect
            $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
            $anim.To = 0; $anim.Duration = [TimeSpan]::FromMilliseconds(160)
            $capturedBorder = $Border
            $anim.Add_Completed({ $capturedBorder.Effect = $null }.GetNewClosure())
            $glowEffect.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty,$anim)
        }
    }
}
function Set-NetPresetGlow {
    param([string]$Selected)
    if(-not $NetPresetLan -or -not $NetPresetWifi){ return }
    $lanBd = $NetPresetLan.Template.FindName("Bd",$NetPresetLan)
    $wifiBd = $NetPresetWifi.Template.FindName("Bd",$NetPresetWifi)
    Set-PresetGlow -Border $lanBd  -Selected ($Selected -eq "LAN NETWORK")   -AccentColor "#38BDF8"
    Set-PresetGlow -Border $wifiBd -Selected ($Selected -eq "WI-FI NETWORK") -AccentColor "#2DD4BF"
}
function Set-GpuPresetGlow {
    param([string]$Selected)
    if(-not $GpuPresetAmd -or -not $GpuPresetNvidia){ return }
    $amdBd = $GpuPresetAmd.Template.FindName("Bd",$GpuPresetAmd)
    $nvBd  = $GpuPresetNvidia.Template.FindName("Bd",$GpuPresetNvidia)
    Set-PresetGlow -Border $amdBd -Selected ($Selected -eq "AMD")    -AccentColor "#ED1C24"
    Set-PresetGlow -Border $nvBd  -Selected ($Selected -eq "NVIDIA") -AccentColor "#76B900"
}
function Set-SelectAllGlow {
    param([bool]$Active)
    if(-not $BtnPresetAllExceptGpuLan){ return }
    $bd = $BtnPresetAllExceptGpuLan.Template.FindName("Bd",$BtnPresetAllExceptGpuLan)
    Set-PresetGlow -Border $bd -Selected $Active -AccentColor "#FBBF24"
}
function Update-PresetGlowConsistency {
    # Re-checks whether the actual tweak toggle state still matches each preset, and dims
    # the glow on any preset button whose selection no longer reflects reality (e.g. the
    # user manually flipped a checkbox that the preset had set).
    if($Global:ActiveNetPreset){
        $type=$Global:ActiveNetPreset
        $other="WI-FI NETWORK"; if($type -eq "WI-FI NETWORK"){ $other="LAN NETWORK" }
        $match=$true
        foreach($t in $Global:TweakInfo){
            if($t.Group -eq $type -and -not $Global:TweakToggles[$t.Key]){ $match=$false }
            elseif($t.Group -eq $other -and $Global:TweakToggles[$t.Key]){ $match=$false }
        }
        if($match){ Set-NetPresetGlow -Selected $type } else { Set-NetPresetGlow -Selected $null }
    } else { Set-NetPresetGlow -Selected $null }
    if($Global:ActiveGpuPreset){
        $vendor=$Global:ActiveGpuPreset
        $mine="AMD GPU"; $other="NVIDIA GPU"; if($vendor -eq "NVIDIA"){ $mine="NVIDIA GPU"; $other="AMD GPU" }
        $match=$true
        foreach($t in $Global:TweakInfo){
            if($t.Group -eq $mine -and -not $Global:TweakToggles[$t.Key]){ $match=$false }
            elseif($t.Group -eq $other -and $Global:TweakToggles[$t.Key]){ $match=$false }
        }
        if($match){ Set-GpuPresetGlow -Selected $vendor } else { Set-GpuPresetGlow -Selected $null }
    } else { Set-GpuPresetGlow -Selected $null }
    if($Global:SelectAllActive){
        $match=$true
        foreach($t in $Global:TweakInfo){
            # GPU and Network tweaks are controlled by their own presets and are meant to be
            # combined with Select-All (pick your NIC type + your GPU vendor on top of it),
            # so they're excluded from this check - only the "everything else" part matters.
            if($t.Category -eq "GPU" -or $t.Key -eq "GPU_ClearShaderCache" -or $t.Group -eq "LAN NETWORK" -or $t.Group -eq "WI-FI NETWORK"){ continue }
            if(-not $Global:TweakToggles[$t.Key]){ $match=$false }
        }
        Set-SelectAllGlow -Active $match
    } else { Set-SelectAllGlow -Active $false }
}
function Set-NetPreset {
    param([ValidateSet("LAN NETWORK","WI-FI NETWORK")][string]$Type)
    $other= if($Type -eq "LAN NETWORK"){"WI-FI NETWORK"}else{"LAN NETWORK"}
    foreach($t in $Global:TweakInfo){
        if($t.Group -eq $Type){ $Global:TweakToggles[$t.Key]=$true }
        elseif($t.Group -eq $other){ $Global:TweakToggles[$t.Key]=$false }
    }
    $Global:ActiveNetPreset = $Type
    Update-PresetGlowConsistency
    Build-StageCards
    if($Global:ActiveCategory -eq "LAN NETWORK" -or $Global:ActiveCategory -eq "WI-FI NETWORK"){ Show-CategoryDetail $Global:ActiveCategory }
    Save-TweakState
    $label= if($Type -eq "LAN NETWORK"){"LAN (wired)"}else{"Wi-Fi"}
    Add-Log "Network preset: $label tweaks enabled, the other connection type's tweaks disabled" "#9B5DE5"
}
function Set-GpuPreset {
    param([ValidateSet("AMD","NVIDIA")][string]$Vendor)
    $Global:DetectedGpuVendor=$Vendor
    $mine= if($Vendor -eq "AMD"){"AMD GPU"}else{"NVIDIA GPU"}
    $other= if($Vendor -eq "AMD"){"NVIDIA GPU"}else{"AMD GPU"}
    foreach($t in $Global:TweakInfo){
        if($t.Group -eq $mine){ $Global:TweakToggles[$t.Key]=$true }
        elseif($t.Group -eq $other){ $Global:TweakToggles[$t.Key]=$false }
    }
    $Global:ActiveGpuPreset = $Vendor
    Update-PresetGlowConsistency
    Build-StageCards
    if($Global:ActiveCategory -eq "NVIDIA GPU" -or $Global:ActiveCategory -eq "AMD GPU"){ Show-CategoryDetail $Global:ActiveCategory }
    Save-TweakState
    Add-Log "GPU preset: $Vendor tweaks enabled, the other vendor's tweaks disabled" "#9B5DE5"
}
$GpuPresetAmd.Add_Click({ Set-GpuPreset -Vendor "AMD" })
$GpuPresetNvidia.Add_Click({ Set-GpuPreset -Vendor "NVIDIA" })
function Set-PresetAllExceptGpuLan {
    foreach($t in $Global:TweakInfo){
        if($t.Category -eq "GPU" -or $t.Key -eq "GPU_ClearShaderCache" -or $t.Group -eq "LAN NETWORK" -or $t.Group -eq "WI-FI NETWORK"){ $Global:TweakToggles[$t.Key]=$false }
        else { $Global:TweakToggles[$t.Key]=$true }
    }
    $Global:ActiveGpuPreset = $null
    $Global:ActiveNetPreset = $null
    $Global:SelectAllActive = $true
    Update-PresetGlowConsistency
    Build-StageCards
    if($Global:ActiveCategory){ Show-CategoryDetail $Global:ActiveCategory }
    Save-TweakState
    Add-Log "Preset applied: all tweaks enabled except GPU (incl. shader cache) and all network (LAN/Wi-Fi) tweaks" "#9B5DE5"
}
$BtnPresetAllExceptGpuLan.Add_Click({ Set-PresetAllExceptGpuLan })
function Update-EnabledBadge {
    # Badge UI removed - counts are no longer displayed, but toggle state tracking still works.
}
Build-StageCards; Update-EnabledBadge
$CatOverlayCloseX.Add_Click({ Close-CategoryDetail })
$CatOverlayCloseBtn.Add_Click({ Close-CategoryDetail })
$SearchBox.Add_TextChanged({
    $txt=$SearchBox.Text.Trim()
    $SearchPH.Visibility=if($txt -eq ""){"Visible"}else{"Collapsed"}
    Build-StageCards -filter $txt
})
$BtnTaskMgr.Add_Click({Start-Process "taskmgr.exe" -EA SilentlyContinue})
$NetPresetLan.Add_Click({ Set-NetPreset -Type "LAN NETWORK" })
$NetPresetWifi.Add_Click({ Set-NetPreset -Type "WI-FI NETWORK" })
$BtnGpedit.Add_Click({Start-Process "gpedit.msc" -EA SilentlyContinue})
$BtnClean.Add_Click({Start-Process "explorer.exe" -ArgumentList "`"$env:APPDATA\Microsoft\Windows\PowerShell`"" -EA SilentlyContinue})
$BtnDiscord.Add_Click({Start-Process "https://discord.gg/syncproject" -EA SilentlyContinue})
$BtnExit.Add_Click({$window.Close()})
$BtnClear.Add_Click({$LogBox.Inlines.Clear();$Global:LogLines.Clear();$CurrentTask.Text="Waiting to start..";$ProgressFill.Width=0;$ProgressPct.Text="0%"})
function Set-RegValue{param($Path,$Name,$Value,$Type="DWord");try{if(-not(Test-Path $Path)){New-Item -Path $Path -Force|Out-Null};Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -EA Stop;return $true}catch{return $false}}
function Get-RegValue{param($Path,$Name);try{return(Get-ItemProperty -Path $Path -Name $Name -EA Stop).$Name}catch{return $null}}
function Save-Orig{param($key,$path,$name);if(-not $Global:Orig.ContainsKey($key)){$Global:Orig[$key]=@{Path=$path;Name=$name;Value=(Get-RegValue $path $name)}}}
# Several tweaks are exposed as two separate UI toggles (e.g. a LAN and a Wi-Fi checkbox, or an
# NVIDIA and an AMD checkbox) but actually change one machine-wide, non-adapter-specific setting.
# If both toggles are active at once this helper makes sure the underlying change/log only happens
# once, while still marking whichever toggle key triggered the call as applied (so restore/undo
# and the on-screen "OK" status stay consistent no matter which of the two checkboxes was used).
function Invoke-DedupedGlobalTweak{
    param([string]$BaseKey, $ToggleKey, [scriptblock]$Action)
    if(-not $Global:AppliedKeys[$BaseKey]){
        & $Action
        $Global:AppliedKeys[$BaseKey]=$true
    } else {
        Add-Log "Already applied via the other toggle sharing this setting - skipped duplicate write" "#6B7280"
    }
    if($ToggleKey -and $ToggleKey -ne $BaseKey){ $Global:AppliedKeys[$ToggleKey]=$true }
}
function Save-OrigService{
    param($key,[string]$serviceName)
    if($Global:OrigServices.ContainsKey($key)){return}
    try{
        $svc=Get-Service -Name $serviceName -EA Stop
        $startType=(Get-CimInstance Win32_Service -Filter "Name='$serviceName'" -EA SilentlyContinue).StartMode
        $Global:OrigServices[$key]=@{ServiceName=$serviceName;Status=$svc.Status.ToString();StartType=$startType}
    } catch { $Global:OrigServices[$key]=@{ServiceName=$serviceName;Status=$null;StartType=$null} }
}
function Restore-OrigService{
    param($info)
    try{
        $name=$info.ServiceName
        if(-not $name){return}
        $st=$info.StartType
        $wasRunning=($info.Status -eq "Running")
        if($st){
            $mapped = switch($st){"Auto"{"Automatic"};"Manual"{"Manual"};"Disabled"{"Disabled"};default{"Manual"}}
            Set-Service -Name $name -StartupType $mapped -EA SilentlyContinue
        }
        if($wasRunning){ Start-Service -Name $name -EA SilentlyContinue }
    } catch {}
}
$Global:IsCancelled=$false
function Update-Progress{param([int]$done,[int]$total);$window.Dispatcher.Invoke([Action]{if($total -gt 0){$pct=[math]::Round(($done/$total)*100);$ProgressPct.Text="$pct%";$maxW=$ProgressFill.Parent.ActualWidth;if($maxW -le 0){$maxW=242};$ProgressFill.Width=[math]::Max(0,($pct/100.0)*$maxW)}})}
function Set-StatusRunning{$window.Dispatcher.Invoke([Action]{$StatusText.Text="RUNNING";$StatusDotE.Fill=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0xF5,0x9E,0x0B));$BtnRun.IsEnabled=$false})}
function Set-StatusDone{$window.Dispatcher.Invoke([Action]{$StatusText.Text="DONE";$StatusDotE.Fill=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x10,0xB9,0x81));$BtnRun.IsEnabled=$true})}
function Set-CurrentTask{param([string]$msg);$window.Dispatcher.Invoke([Action]{$CurrentTask.Text=$msg})}

function Run-NetThrottle{param($ToggleKey);Set-CurrentTask "Network Throttling -> Absolute Max";Invoke-DedupedGlobalTweak "NetThrottle" $ToggleKey {$p="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile";Save-Orig "NetThrottle" $p "NetworkThrottlingIndex";Set-RegValue $p "NetworkThrottlingIndex" 0xFFFFFFFF|Out-Null;Set-RegValue $p "SystemResponsiveness" 0|Out-Null;Add-Log "Network throttling disabled" "#9B5DE5"}}
function Run-BcdTimer{Set-CurrentTask "BCD Timer Tweaks";try{bcdedit /set useplatformtick yes 2>&1|Out-Null;bcdedit /set disabledynamictick yes 2>&1|Out-Null;Add-Log "BCD timer tweaks applied (reboot)" "#9B5DE5";$Global:AppliedKeys["BcdTimer"]=$true}catch{Add-Log "BCD tweaks skipped" "#EF4444"}}
function Run-TcpGlobal{param($ToggleKey);Set-CurrentTask "TCP Global Stack Overhaul";try{Invoke-DedupedGlobalTweak "TcpGlobal" $ToggleKey {netsh int tcp set global autotuninglevel=normal rss=enabled ecncapability=enabled fastopen=enabled congestionprovider=ctcp 2>&1|Out-Null;Add-Log "TCP global stack optimized" "#9B5DE5"}}catch{Add-Log "TCP global failed" "#EF4444"}}
function Run-KbQueue{Set-CurrentTask "Keyboard Queue Size -> 10";$p="HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters";Save-Orig "KbQueue" $p "KeyboardDataQueueSize";Set-RegValue $p "KeyboardDataQueueSize" 10|Out-Null;Add-Log "Keyboard queue -> 10" "#9B5DE5";$Global:AppliedKeys["KbQueue"]=$true}
function Run-NduDisable{param($ToggleKey);Set-CurrentTask "Ndu Driver -> Disabled";Invoke-DedupedGlobalTweak "NduDisable" $ToggleKey {$p="HKLM:\SYSTEM\ControlSet001\Services\Ndu";Save-Orig "NduDisable" $p "Start";Set-RegValue $p "Start" 4|Out-Null;Add-Log "Ndu driver disabled" "#9B5DE5"}}
function Run-GamingMemory{Set-CurrentTask "Gaming Memory Mode";try{Save-OrigService "GamingMemory" "SysMain";Stop-Service SysMain -Force -EA SilentlyContinue;Set-Service SysMain -StartupType Disabled -EA SilentlyContinue;Add-Log "Gaming memory mode enabled" "#9B5DE5";$Global:AppliedKeys["GamingMemory"]=$true}catch{Add-Log "Gaming memory partial" "#F59E0B"}}
function Run-FiveMBooster{Set-CurrentTask "FiveM Booster";$p=Get-Process -Name "FiveM*" -EA Ignore|Select -First 1;if($p){$p.PriorityClass="High";Add-Log "FiveM boosted to High priority" "#9B5DE5"}else{Add-Log "FiveM not running - skipped" "#F59E0B"};$Global:AppliedKeys["FiveMBooster"]=$true}
function Run-FiveMPerfOptions{
    Set-CurrentTask "FiveM_GTAProcess.exe -> CpuPriorityClass 3 (IFEO)"
    $p="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\FiveM_GTAProcess.exe\PerfOptions"
    Save-Orig "GM_FiveMPerfOptions" $p "CpuPriorityClass"
    Set-RegValue $p "CpuPriorityClass" 3|Out-Null
    Add-Log "FiveM_GTAProcess.exe CpuPriorityClass set to 3 (Normal) via IFEO" "#9B5DE5"
    $Global:AppliedKeys["GM_FiveMPerfOptions"]=$true
}
function Run-FiveMCoreAffinity{
    Set-CurrentTask "FiveM Core Affinity -> Auto-Optimized"
    try{
        $logical=[Environment]::ProcessorCount
        if($logical -le 2){
            Add-Log "Only $logical logical cores detected - skipping affinity change (not enough cores to spare)" "#F59E0B"
            $Global:AppliedKeys["GM_FiveMCoreAffinity"]=$true
            return
        }
        # Leave core 0 free for system/interrupt work, cap usable cores around 5-6 to avoid cross-core migration overhead
        $maxCores=[Math]::Min($logical-1,6)
        $mask=0
        for($i=1;$i -le $maxCores;$i++){ $mask=$mask -bor (1 -shl $i) }
        $procs=Get-Process -Name "FiveM_GTAProcess","FiveM" -EA Ignore
        if($procs){
            foreach($proc in $procs){
                try{ $proc.ProcessorAffinity=[IntPtr]$mask; Add-Log "$($proc.ProcessName) affinity set to cores 1-$maxCores (mask 0x$($mask.ToString('X')))" "#9B5DE5" }catch{ Add-Log "Could not set affinity for $($proc.ProcessName): $_" "#EF4444" }
            }
        } else {
            Add-Log "FiveM not running yet - will auto-apply as soon as it starts (watching for 10 min)" "#F59E0B"
            $affinityJob = Start-Job -ScriptBlock {
                param($mask)
                $deadline=(Get-Date).AddMinutes(10)
                while((Get-Date) -lt $deadline){
                    $proc=Get-Process -Name "FiveM_GTAProcess","FiveM" -EA Ignore|Select -First 1
                    if($proc){ try{ $proc.ProcessorAffinity=[IntPtr]$mask }catch{}; break }
                    Start-Sleep -Seconds 5
                }
            } -ArgumentList $mask
            # Track it so we can stop/reap it on app exit instead of leaving an orphaned job running.
            if(-not $Global:BackgroundJobs){ $Global:BackgroundJobs=@() }
            $Global:BackgroundJobs += $affinityJob
        }
        $Global:AppliedKeys["GM_FiveMCoreAffinity"]=$true
    } catch { Add-Log "FiveM core affinity error: $_" "#EF4444" }
}
function Run-KillerFix{
    Set-CurrentTask "Killer NIC Traffic Analysis -> Disabled"
    try{
        # Only ever touch user-mode "smart traffic" services (Win32OwnProcess/Win32ShareProcess),
        # never a Kernel/FileSystem driver - that keeps the actual NIC driver completely untouched
        # so the adapter itself can never be broken by this tweak.
        $killerSvcs=Get-CimInstance Win32_Service -Filter "Name LIKE '%Killer%'" -EA SilentlyContinue | Where-Object { $_.ServiceType -notmatch "Kernel|FileSystem" }
        if($killerSvcs){
            foreach($svc in $killerSvcs){
                Save-OrigService "NET_KillerFix_$($svc.Name)" $svc.Name
                Stop-Service -Name $svc.Name -Force -EA SilentlyContinue
                Set-Service -Name $svc.Name -StartupType Disabled -EA SilentlyContinue
                Add-Log "Killer service disabled: $($svc.DisplayName)" "#9B5DE5"
            }
        } else {
            Add-Log "No Killer NIC detected - skipped" "#6B7280"
        }
        $Global:AppliedKeys["NET_KillerFix"]=$true
    } catch { Add-Log "Killer NIC check failed: $_" "#EF4444" }
}
function Run-FiveMQos{
    Set-CurrentTask "FiveM Traffic -> QoS Priority Tag"
    try{
        # Windows only applies DSCP tagging on domain networks by default - this flips that on
        # for home/private networks too. It only permits tagging, it never blocks or throttles.
        $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS"
        Save-Orig "NET_FiveMQos_NLA" $p "DoNotUseNLA"
        Set-RegValue $p "DoNotUseNLA" 1|Out-Null

        $created=@()
        foreach($procName in @("FiveM.exe","FiveM_GTAProcess.exe")){
            $polName="SyncProject FiveM Priority - $procName"
            try{
                Get-NetQosPolicy -Name $polName -EA SilentlyContinue | Remove-NetQosPolicy -Confirm:$false -EA SilentlyContinue
                New-NetQosPolicy -Name $polName -AppPathNameMatchCondition $procName -DSCPAction 46 -NetworkProfile All -EA Stop | Out-Null
                $created+=$polName
                Add-Log "QoS priority tag applied: $procName" "#9B5DE5"
            } catch { Add-Log "QoS policy for $procName skipped: $_" "#F59E0B" }
        }
        if($created.Count -gt 0){ $Global:OrigMisc["NET_FiveMQos_Policies"]=$created }
        $Global:AppliedKeys["NET_FiveMQos"]=$true
    } catch { Add-Log "FiveM QoS setup failed: $_" "#EF4444" }
}
function Run-FiveMFirewall{
    Set-CurrentTask "FiveM -> Explicit Firewall Allow Rule"
    try{
        $procs=Get-Process -Name "FiveM","FiveM_GTAProcess" -EA Ignore | Where-Object { $_.Path }
        if(-not $procs){
            Add-Log "FiveM not running - firewall rule skipped" "#F59E0B"
            $Global:AppliedKeys["NET_FiveMFirewall"]=$true
            return
        }
        $created=@()
        $seenPaths=@{}
        foreach($proc in $procs){
            $path=$proc.Path
            if(-not $path -or $seenPaths.ContainsKey($path)){ continue }
            $seenPaths[$path]=$true
            $ruleName="SyncProject - FiveM Allow ($($proc.ProcessName))"
            if(-not (Get-NetFirewallRule -DisplayName $ruleName -EA SilentlyContinue)){
                try{
                    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Program $path -Profile Any -EA Stop | Out-Null
                    New-NetFirewallRule -DisplayName "$ruleName (Out)" -Direction Outbound -Action Allow -Program $path -Profile Any -EA Stop | Out-Null
                    $created+=$ruleName; $created+="$ruleName (Out)"
                    Add-Log "Firewall allow rule added: $($proc.ProcessName)" "#9B5DE5"
                } catch { Add-Log "Firewall rule for $($proc.ProcessName) skipped: $_" "#F59E0B" }
            }
        }
        if($created.Count -gt 0){ $Global:OrigMisc["NET_FiveMFirewall_Rules"]=$created }
        $Global:AppliedKeys["NET_FiveMFirewall"]=$true
    } catch { Add-Log "FiveM firewall rule failed: $_" "#EF4444" }
}
function Run-DriverHealth{Set-CurrentTask "Driver Health Check";try{$bad=Get-WmiObject Win32_PnPEntity -EA SilentlyContinue|Where-Object{$_.ConfigManagerErrorCode -ne 0};if($bad){foreach($d in $bad){Add-Log "Problem: $($d.Name)" "#EF4444"}}else{Add-Log "All drivers OK" "#10B981"};$Global:AppliedKeys["DriverHealth"]=$true}catch{Add-Log "Driver check skipped" "#F59E0B"}}
function Run-LanOptimize{Set-CurrentTask "LAN Optimization";try{netsh int tcp set global autotuninglevel=normal 2>&1|Out-Null;Add-Log "LAN optimized" "#9B5DE5";$Global:AppliedKeys["LanOptimize"]=$true}catch{Add-Log "LAN optimize failed" "#EF4444"}}
function Run-WifiOptimize{Set-CurrentTask "Wi-Fi Optimization";try{$wa=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.InterfaceDescription -match "Wi-Fi|Wireless"}|Select -First 1;if($wa){Set-NetAdapterAdvancedProperty -Name $wa.Name -DisplayName "Preferred Band" -DisplayValue "Prefer 5GHz band" -EA SilentlyContinue};Add-Log "Wi-Fi optimized" "#9B5DE5";$Global:AppliedKeys["WifiOptimize"]=$true}catch{Add-Log "Wi-Fi optimize skipped" "#F59E0B"}}
function Run-LanJumboFrame{
    Set-CurrentTask "Jumbo Frame -> 9014 Bytes"
    try{
        $la=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Wi-Fi|Wireless"}
        $count=0
        foreach($a in $la){
            Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "Jumbo Packet" -DisplayValue "9014 Bytes" -EA SilentlyContinue
            $count++
        }
        Add-Log "Jumbo frame requested on $count wired adapter(s) (skipped if unsupported)" "#9B5DE5"
        $Global:AppliedKeys["NET_LanJumboFrame"]=$true
    } catch { Add-Log "Jumbo frame tweak skipped" "#F59E0B" }
}
function Run-LanInterruptModeration{
    Set-CurrentTask "Interrupt Moderation -> Disabled"
    try{
        $la=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Wi-Fi|Wireless"}
        $count=0
        foreach($a in $la){
            Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -EA SilentlyContinue
            $count++
        }
        Add-Log "Interrupt moderation disabled on $count wired adapter(s)" "#9B5DE5"
        $Global:AppliedKeys["NET_LanInterruptModeration"]=$true
    } catch { Add-Log "Interrupt moderation tweak skipped" "#F59E0B" }
}
function Run-WifiPowerSaveMode{
    Set-CurrentTask "802.11 Power Saving -> Disabled"
    try{
        $wa=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.InterfaceDescription -match "Wi-Fi|Wireless"}|Select -First 1
        if($wa){
            Set-NetAdapterAdvancedProperty -Name $wa.Name -DisplayName "Power Saving Mode" -DisplayValue "Disabled" -EA SilentlyContinue
            Set-NetAdapterAdvancedProperty -Name $wa.Name -DisplayName "802.11n/ac Power Save Mode" -DisplayValue "Off" -EA SilentlyContinue
            Add-Log "Wi-Fi power saving disabled" "#9B5DE5"
        } else { Add-Log "No Wi-Fi adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_WifiPowerSaveMode"]=$true
    } catch { Add-Log "Wi-Fi power save tweak skipped" "#F59E0B" }
}
function Run-WifiRoamingAggressiveness{
    Set-CurrentTask "Roaming Aggressiveness -> Lowest"
    try{
        $wa=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.InterfaceDescription -match "Wi-Fi|Wireless"}|Select -First 1
        if($wa){
            Set-NetAdapterAdvancedProperty -Name $wa.Name -DisplayName "Roaming Aggressiveness" -DisplayValue "Lowest" -EA SilentlyContinue
            Add-Log "Wi-Fi roaming aggressiveness set to lowest" "#9B5DE5"
        } else { Add-Log "No Wi-Fi adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_WifiRoamingAggressiveness"]=$true
    } catch { Add-Log "Wi-Fi roaming tweak skipped" "#F59E0B" }
}
function Run-DnsFastLan{
    Set-CurrentTask "DNS -> Google"
    try{
        $la=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Wi-Fi|Wireless"}
        $count=0
        foreach($a in $la){
            Set-DnsClientServerAddress -InterfaceIndex $a.IfIndex -ServerAddresses ("8.8.4.4","8.8.8.8") -EA SilentlyContinue
            $count++
        }
        if($count -gt 0){ Add-Log "DNS set to 8.8.4.4 / 8.8.8.8 on $count wired adapter(s)" "#9B5DE5" } else { Add-Log "No wired adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_DnsFast"]=$true
    } catch { Add-Log "DNS tweak (LAN) skipped" "#F59E0B" }
}
function Run-DeliveryOptOff{
    Set-CurrentTask "Delivery Optimization (P2P Updates) -> Off"
    try{
        $p="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"
        Save-Orig "NET_DeliveryOptOff" $p "DODownloadMode"
        Set-RegValue $p "DODownloadMode" 0|Out-Null
        try{ Set-Service dosvc -StartupType Manual -EA SilentlyContinue }catch{}
        Add-Log "Delivery Optimization P2P sharing disabled" "#9B5DE5"
        $Global:AppliedKeys["NET_DeliveryOptOff"]=$true
    } catch { Add-Log "Delivery Optimization tweak failed" "#EF4444" }
}
function Run-DnsCacheAggressive{
    Set-CurrentTask "DNS Client Cache -> Aggressive"
    try{
        $p="HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
        Save-Orig "NET_DnsCacheAggressive_MaxTtl" $p "MaxCacheTtl"
        Save-Orig "NET_DnsCacheAggressive_NegTtl" $p "MaxNegativeCacheTtl"
        Set-RegValue $p "MaxCacheTtl" 86400|Out-Null
        Set-RegValue $p "MaxNegativeCacheTtl" 5|Out-Null
        try{ Restart-Service dnscache -Force -EA SilentlyContinue }catch{}
        Add-Log "DNS client cache set to hold entries longer" "#9B5DE5"
        $Global:AppliedKeys["NET_DnsCacheAggressive"]=$true
    } catch { Add-Log "DNS cache tweak failed" "#EF4444" }
}
function Run-BottleneckCheck{
    Set-CurrentTask "CPU/GPU Bottleneck Check"
    try{
        # NOTE: previously used -SampleInterval 1 -MaxSamples 3 on BOTH counters, which
        # blocks this single-threaded UI for ~6 real seconds every run (2 x 3s), long enough
        # for Windows to flag the window as "Not Responding" and paint the ghost/frozen
        # overlay - no clicks register during that window. A single instantaneous sample
        # keeps this fast/non-blocking; it's already labeled as a rough snapshot, not a
        # precise reading, so losing the 3-sample average doesn't change its usefulness.
        $cpuSamples=(Get-Counter '\Processor(_Total)\% Processor Time' -MaxSamples 1 -EA SilentlyContinue).CounterSamples
        $gpuSamples=(Get-Counter '\GPU Engine(*engtype_3D)\Utilization Percentage' -MaxSamples 1 -EA SilentlyContinue).CounterSamples
        $cpuAvg= if($cpuSamples){[math]::Round(($cpuSamples|Measure-Object CookedValue -Average).Average,1)}else{$null}
        $gpuAvg= if($gpuSamples){[math]::Round(($gpuSamples|Measure-Object CookedValue -Average).Average,1)}else{$null}
        if($null -ne $cpuAvg -and $null -ne $gpuAvg){
            $verdict= if($cpuAvg -gt ($gpuAvg+15)){"CPU is more loaded right now"} elseif($gpuAvg -gt ($cpuAvg+15)){"GPU is more loaded right now"} else {"CPU and GPU load are close"}
            Add-Log "CPU: $cpuAvg% | GPU: $gpuAvg% - $verdict" "#9B5DE5"
            Add-Log "This is a single instant snapshot, not in-game data - use RTSS/Afterburner while playing for a real reading" "#6B7280"
        } else { Add-Log "Bottleneck check: counters unavailable on this system - skipped" "#6B7280" }
        $Global:AppliedKeys["SYS_BottleneckCheck"]=$true
    } catch { Add-Log "Bottleneck check skipped (counters unavailable)" "#F59E0B" }
}
function Run-ClearShaderCache{
    Set-CurrentTask "Clear Shader Cache (NVIDIA/AMD)"
    try{
        $found=0
        $paths=@(
            "$env:LOCALAPPDATA\NVIDIA\DXCache","$env:LOCALAPPDATA\NVIDIA\GLCache","$env:LOCALAPPDATA\NVIDIA Corporation\NV_Cache",
            "$env:LOCALAPPDATA\AMD\DxCache","$env:LOCALAPPDATA\AMD\DxcCache","$env:LOCALAPPDATA\AMD\GLCache","$env:LOCALAPPDATA\AMD\VkCache"
        )
        foreach($p in $paths){
            if(Test-Path $p){
                # Remove-Item with a wildcard handles its own recursion internally instead of
                # building a full Get-ChildItem object list and piping it item-by-item, which is
                # much faster on large caches and keeps this from blocking the UI thread as long.
                Remove-Item -Path "$p\*" -Force -Recurse -EA SilentlyContinue
                $found++
            }
        }
        if($found -gt 0){ Add-Log "Shader cache cleared ($found folder(s) found)" "#9B5DE5" } else { Add-Log "No NVIDIA/AMD shader cache folders found - skipped" "#6B7280" }
        $Global:AppliedKeys["GPU_ClearShaderCache"]=$true
    } catch { Add-Log "Shader cache clear skipped (files in use)" "#F59E0B" }
}
function Run-ClearTempJunk{
    Set-CurrentTask "Clear Temp & Junk Files"
    try{
        $paths=@($env:TEMP,"$env:WINDIR\Temp")
        $touched=0
        foreach($p in $paths){
            if(Test-Path $p){
                # See Run-ClearShaderCache note: wildcard Remove-Item avoids the slow
                # Get-ChildItem + per-item pipeline pattern, which matters a lot here since
                # TEMP folders can accumulate tens of thousands of files over time.
                Remove-Item -Path "$p\*" -Force -Recurse -EA SilentlyContinue
                $touched++
            }
        }
        Add-Log "Temp/junk files cleared from $touched location(s) (locked files skipped)" "#9B5DE5"
        $Global:AppliedKeys["CLEAN_ClearTempJunk"]=$true
    } catch { Add-Log "Temp cleanup partial - some files in use" "#F59E0B" }
}
function Run-ClearFiveMCache{
    Set-CurrentTask "Clear FiveM Cache"
    try{
        $p="$env:LOCALAPPDATA\FiveM\FiveM.app\data\cache"
        if(Test-Path $p){
            Remove-Item -Path "$p\*" -Force -Recurse -EA SilentlyContinue
            Add-Log "FiveM cache cleared" "#9B5DE5"
        } else { Add-Log "FiveM cache folder not found - skipped" "#6B7280" }
        $Global:AppliedKeys["CLEAN_ClearFiveMCache"]=$true
    } catch { Add-Log "FiveM cache clear skipped (files in use)" "#F59E0B" }
}
function Run-RemoveBloat{
    Set-CurrentTask "Remove Unnecessary Pre-Installed Apps"
    $bloatList=$Global:BloatList
    $removed=0; $skipped=0; $removedNames=@()
    # One enumeration of all installed packages instead of calling Get-AppxPackage once per
    # name in $bloatList (~30 separate full-repository queries) - much faster, same result.
    $allPkgs = @(Get-AppxPackage -EA SilentlyContinue)
    foreach($name in $bloatList){
        try{
            $pkgs=$allPkgs | Where-Object { $_.Name -eq $name }
            if($pkgs){
                $pkgs | Remove-AppxPackage -EA SilentlyContinue
                $removed++; $removedNames+=$name
            } else { $skipped++ }
        } catch { $skipped++ }
    }
    if($removedNames.Count -gt 0){ $Global:OrigMisc["CLEAN_RemoveBloat"]=$removedNames }
    Add-Log "Pre-installed app cleanup: $removed app(s) removed, $skipped not found/skipped" "#9B5DE5"
    $Global:AppliedKeys["CLEAN_RemoveBloat"]=$true
}
function Run-KillBackgroundProcesses{
    Set-CurrentTask "Non-Essential Background Processes -> Closed"
    # Curated, deliberately conservative list of common third-party helper/updater/overlay processes.
    # Never includes Windows system processes, drivers, security software, shell (explorer.exe), or FiveM/game processes.
    $procList=$Global:KillProcList
    $closed=0; $notRunning=0
    foreach($name in $procList){
        try{
            $p=Get-Process -Name $name -EA Ignore
            if($p){ $p | Stop-Process -Force -EA SilentlyContinue; $closed += ($p|Measure-Object).Count }
            else { $notRunning++ }
        } catch { }
    }
    Add-Log "Background process cleanup: $closed process(es) closed, $notRunning not running" "#9B5DE5"
    $Global:AppliedKeys["CLEAN_KillBackgroundProcs"]=$true
}
function Run-DisableLauncherStartup{
    Set-CurrentTask "Game Launchers & Chat Apps -> Startup Disabled"
    # Matches by substring against the value NAME (usually the app's own registered name) so it catches
    # "Steam", "Discord", "EpicGamesLauncher", "Battle.net", "Origin", "Ubisoft Connect", "RiotClientServices", "GOG Galaxy", "Spotify".
    $targets=$Global:StartupDisableTargets
    $runPaths=@(
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )
    $backup=@(); $removed=0
    foreach($rp in $runPaths){
        try{
            if(-not (Test-Path $rp)){ continue }
            $props=Get-ItemProperty -Path $rp -EA SilentlyContinue
            if(-not $props){ continue }
            foreach($name in $props.PSObject.Properties.Name){
                if($name -in @("PSPath","PSParentPath","PSChildName","PSDrive","PSProvider")){ continue }
                foreach($t in $targets){
                    if($name -match [regex]::Escape($t)){
                        $val=$props.$name
                        $backup += @{Path=$rp;Name=$name;Value=$val}
                        try{
                            Remove-ItemProperty -Path $rp -Name $name -EA Stop
                            $removed++
                            Add-Log "Startup entry disabled: $name" "#9B5DE5"
                        } catch { Add-Log "Could not remove startup entry $name (may need admin on HKLM): $_" "#F59E0B" }
                        break
                    }
                }
            }
        } catch {}
    }
    if($backup.Count -gt 0){ $Global:OrigMisc["CLEAN_DisableLauncherStartup"]=$backup }
    if($removed -gt 0){ Add-Log "Startup cleanup: $removed launcher/chat app(s) will no longer auto-start" "#9B5DE5" }
    else { Add-Log "No matching startup entries found (nothing to disable)" "#6B7280" }
    $Global:AppliedKeys["CLEAN_DisableLauncherStartup"]=$true
}
function Run-DnsFastWifi{
    Set-CurrentTask "DNS -> Google"
    try{
        $wa=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.InterfaceDescription -match "Wi-Fi|Wireless"}|Select -First 1
        if($wa){
            Set-DnsClientServerAddress -InterfaceIndex $wa.IfIndex -ServerAddresses ("8.8.4.4","8.8.8.8") -EA SilentlyContinue
            Add-Log "DNS set to 8.8.4.4 / 8.8.8.8 on Wi-Fi adapter" "#9B5DE5"
        } else { Add-Log "No Wi-Fi adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_DnsFast_WiFi"]=$true
    } catch { Add-Log "DNS tweak (Wi-Fi) skipped" "#F59E0B" }
}
function Run-Ipv6DisableLan{
    Set-CurrentTask "IPv6 -> Disabled"
    try{
        $la=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Wi-Fi|Wireless"}
        $count=0
        foreach($a in $la){ Disable-NetAdapterBinding -Name $a.Name -ComponentID ms_tcpip6 -EA SilentlyContinue; $count++ }
        if($count -gt 0){ Add-Log "IPv6 disabled on $count wired adapter(s)" "#9B5DE5" } else { Add-Log "No wired adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_Ipv6Disable"]=$true
    } catch { Add-Log "IPv6 disable (LAN) skipped" "#F59E0B" }
}
function Run-Ipv6DisableWifi{
    Set-CurrentTask "IPv6 -> Disabled"
    try{
        $wa=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.InterfaceDescription -match "Wi-Fi|Wireless"}|Select -First 1
        if($wa){
            Disable-NetAdapterBinding -Name $wa.Name -ComponentID ms_tcpip6 -EA SilentlyContinue
            Add-Log "IPv6 disabled on Wi-Fi adapter" "#9B5DE5"
        } else { Add-Log "No Wi-Fi adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_Ipv6Disable_WiFi"]=$true
    } catch { Add-Log "IPv6 disable (Wi-Fi) skipped" "#F59E0B" }
}
function Run-RssEnable{
    Set-CurrentTask "Receive Side Scaling -> Enabled"
    try{
        $la=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Wi-Fi|Wireless"}
        $count=0
        foreach($a in $la){ Enable-NetAdapterRss -Name $a.Name -EA SilentlyContinue; $count++ }
        if($count -gt 0){ Add-Log "RSS enabled on $count wired adapter(s)" "#9B5DE5" } else { Add-Log "No wired adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_RssEnable"]=$true
    } catch { Add-Log "RSS enable skipped" "#F59E0B" }
}
function Run-FlowControlOff{
    Set-CurrentTask "Flow Control -> Disabled"
    try{
        $la=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Wi-Fi|Wireless"}
        $count=0
        foreach($a in $la){
            Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "Flow Control" -DisplayValue "Disabled" -EA SilentlyContinue
            $count++
        }
        Add-Log "Flow control disable requested on $count wired adapter(s) (skipped if unsupported)" "#9B5DE5"
        $Global:AppliedKeys["NET_FlowControlOff"]=$true
    } catch { Add-Log "Flow control tweak skipped" "#F59E0B" }
}
function Run-Ipv6TransitionDisable{
    Set-CurrentTask "IPv6 Transition Tech -> Disabled"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\TCPIP6\Teredo"
    foreach($n in @("Teredo_State","6to4_State","IPHTTPS_State","ISATAP_State")){
        Save-Orig "NET_Ipv6Transition_$n" $p $n
        Set-RegValue $p $n "Disabled" "String"|Out-Null
    }
    Add-Log "IPv6 transition technologies (Teredo/6to4/ISATAP/IP-HTTPS) disabled" "#9B5DE5"
    $Global:AppliedKeys["NET_Ipv6Transition"]=$true
}
function Run-DnsClientPolicy{
    Set-CurrentTask "DNS Client Multicast/Smart Resolution -> Off"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
    Save-Orig "NET_DnsClientPolicy_Multicast" $p "EnableMulticast"
    Set-RegValue $p "EnableMulticast" 0|Out-Null
    Save-Orig "NET_DnsClientPolicy_SmartMultiHomed" $p "DisableSmartNameResolution"
    Set-RegValue $p "DisableSmartNameResolution" 1|Out-Null
    Add-Log "LLMNR multicast + smart multi-homed name resolution turned off" "#9B5DE5"
    $Global:AppliedKeys["NET_DnsClientPolicy"]=$true
}
function Run-LltdDisable{
    Set-CurrentTask "Link-Layer Topology Discovery -> Disabled"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    Save-Orig "NET_LltdDisable_IO" $p "EnableLLTDIO"
    Set-RegValue $p "EnableLLTDIO" 0|Out-Null
    Save-Orig "NET_LltdDisable_Rspndr" $p "EnableRspndr"
    Set-RegValue $p "EnableRspndr" 0|Out-Null
    Add-Log "LLTD mapper/responder disabled" "#9B5DE5"
    $Global:AppliedKeys["NET_LltdDisable"]=$true
}
function Run-BitsNoLimit{
    Set-CurrentTask "BITS Bandwidth Limit -> Removed"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\BITS"
    Save-Orig "NET_BitsNoLimit" $p "EnableBITSMaxBandwidth"
    Set-RegValue $p "EnableBITSMaxBandwidth" 0|Out-Null
    Add-Log "BITS background transfer bandwidth cap removed" "#9B5DE5"
    $Global:AppliedKeys["NET_BitsNoLimit"]=$true
}
function Run-NcsiNoActiveProbe{
    Set-CurrentTask "Network Connectivity Active Probing -> Off"
    $p="HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet"
    Save-Orig "NET_NcsiNoActiveProbe" $p "EnableActiveProbing"
    Set-RegValue $p "EnableActiveProbing" 0|Out-Null
    Add-Log "Network connectivity status active probing disabled" "#9B5DE5"
    $Global:AppliedKeys["NET_NcsiNoActiveProbe"]=$true
}
function Run-NoAutoRootCertUpdate{
    Set-CurrentTask "Automatic Root Certificate Update -> Disabled"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\SystemCertificates\AuthRoot"
    Save-Orig "NET_NoAutoRootCertUpdate" $p "DisableRootAutoUpdate"
    Set-RegValue $p "DisableRootAutoUpdate" 1|Out-Null
    Add-Log "Automatic root certificate update disabled" "#9B5DE5"
    $Global:AppliedKeys["NET_NoAutoRootCertUpdate"]=$true
}
function Run-NetbiosDisable{
    Set-CurrentTask "NetBIOS over TCP/IP -> Disabled"
    try{
        $base="HKLM:\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
        $ifaces=Get-ChildItem -Path $base -EA SilentlyContinue
        $count=0
        foreach($i in $ifaces){
            $p=$i.PSPath
            Save-Orig "NET_NetbiosDisable_$($i.PSChildName)" $p "NetbiosOptions"
            Set-RegValue $p "NetbiosOptions" 2|Out-Null
            $count++
        }
        if($count -gt 0){ Add-Log "NetBIOS over TCP/IP disabled on $count adapter(s)" "#9B5DE5" } else { Add-Log "No adapters found for NetBIOS tweak - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_NetbiosDisable"]=$true
    } catch { Add-Log "NetBIOS disable skipped" "#F59E0B" }
}
function Run-RemoteAssistanceOff{
    Set-CurrentTask "Solicited Remote Assistance -> Disabled"
    $p="HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance"
    Save-Orig "NET_RemoteAssistanceOff" $p "fAllowToGetHelp"
    Set-RegValue $p "fAllowToGetHelp" 0|Out-Null
    Add-Log "Solicited Remote Assistance disabled" "#9B5DE5"
    $Global:AppliedKeys["NET_RemoteAssistanceOff"]=$true
}
function Run-GameExclusion{
    Set-CurrentTask "Defender Exclusions -> Game Folders"
    try{
        $candidates=@(
            "$env:ProgramFiles(x86)\Steam","$env:ProgramFiles\Steam","C:\Program Files (x86)\Steam",
            "$env:ProgramFiles(x86)\Epic Games","C:\Program Files\Epic Games",
            "$env:ProgramFiles(x86)\Riot Games","C:\Program Files\Riot Games",
            "$env:LOCALAPPDATA\FiveM","$env:LOCALAPPDATA\FiveM Application Data"
        )
        $added=0; $addedPaths=@()
        foreach($p in $candidates){
            if($p -and (Test-Path $p)){
                try{ Add-MpPreference -ExclusionPath $p -EA Stop; $added++; $addedPaths+=$p }catch{}
            }
        }
        if($added -gt 0){
            Add-Log "Defender exclusions added for $added game folder(s)" "#9B5DE5"
            if(-not $Global:OrigMisc.ContainsKey("DEF_GameExclusion")){ $Global:OrigMisc["DEF_GameExclusion"]=@() }
            $Global:OrigMisc["DEF_GameExclusion"]=@($Global:OrigMisc["DEF_GameExclusion"])+$addedPaths
        } else { Add-Log "No known game folders found / Defender module unavailable - skipped" "#6B7280" }
        $Global:AppliedKeys["DEF_GameExclusion"]=$true
    } catch { Add-Log "Defender exclusion tweak skipped" "#F59E0B" }
}
function Run-PageFileAuto{
    Set-CurrentTask "Page File -> System Managed"
    try{
        $cs=Get-WmiObject Win32_ComputerSystem -EA Stop
        if(-not $cs.AutomaticManagedPagefile){
            $cs.AutomaticManagedPagefile=$true
            $cs.Put()|Out-Null
        }
        Add-Log "Page file set to system-managed" "#9B5DE5"
        $Global:AppliedKeys["SYS_PageFileAuto"]=$true
    } catch { Add-Log "Page file tweak skipped" "#F59E0B" }
}
function Run-PwrThrottling{Set-CurrentTask "Power Throttling -> Off";Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1|Out-Null;Add-Log "Power throttling disabled" "#9B5DE5";$Global:AppliedKeys["PWR_Throttling"]=$true}
function Run-FSOptim{Set-CurrentTask "Fullscreen Optimizations -> Disabled";Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2|Out-Null;Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1|Out-Null;Add-Log "Fullscreen optimizations disabled" "#9B5DE5";$Global:AppliedKeys["GM_FSOptim"]=$true}
function Run-MouseAccel{Set-CurrentTask "Mouse Acceleration -> Disabled";Set-RegValue "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" "String"|Out-Null;Set-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" "String"|Out-Null;Set-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" "String"|Out-Null;Add-Log "Mouse acceleration disabled" "#9B5DE5";$Global:AppliedKeys["GM_MouseAccel"]=$true}
function Run-MenuInstant{Set-CurrentTask "Instant Menus and Animations Off";Set-RegValue "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String"|Out-Null;Add-Log "Menu delay 0ms, animations off" "#9B5DE5";$Global:AppliedKeys["UX_MenuInstant"]=$true}
function Run-Notifications{Set-CurrentTask "Toast Notifications -> Disabled";Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled" 0|Out-Null;Add-Log "Toast notifications disabled" "#9B5DE5";$Global:AppliedKeys["UX_Notifications"]=$true}
function Run-HPET{Set-CurrentTask "Dynamic Tick and HPET -> Disabled";try{bcdedit /set useplatformclock false 2>&1|Out-Null;bcdedit /set disabledynamictick yes 2>&1|Out-Null;Add-Log "HPET disabled (reboot)" "#9B5DE5";$Global:AppliedKeys["ADV_HPET"]=$true}catch{Add-Log "HPET tweak failed" "#EF4444"}}
function Run-MPODisable{Set-CurrentTask "Smooth Motion -> MPO Disabled";Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode" 5|Out-Null;Add-Log "MPO disabled" "#9B5DE5";$Global:AppliedKeys["GM_SmoothMotion"]=$true}
function Run-SmoothOptim{Set-CurrentTask "Smooth Background Maintenance";try{Disable-ScheduledTask -TaskName "\Microsoft\Windows\TaskScheduler\Regular Maintenance" -EA SilentlyContinue|Out-Null;Add-Log "Auto maintenance disabled" "#9B5DE5";$Global:AppliedKeys["CLEAN_SmoothOptim"]=$true}catch{Add-Log "Maintenance disable skipped" "#F59E0B"}}
function Run-NoNagle{
    param($ToggleKey)
    Set-CurrentTask "Nagle's Algorithm -> Disabled"
    try{
        Invoke-DedupedGlobalTweak "NET_NoNagle" $ToggleKey {
            $ifRoot="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
            $ifaces=Get-ChildItem -Path $ifRoot -EA SilentlyContinue
            $count=0
            foreach($i in $ifaces){
                Save-Orig "NET_NoNagle_$($i.PSChildName)_Ack" $i.PSPath "TcpAckFrequency"
                Save-Orig "NET_NoNagle_$($i.PSChildName)_Delay" $i.PSPath "TCPNoDelay"
                Set-RegValue $i.PSPath "TcpAckFrequency" 1|Out-Null
                Set-RegValue $i.PSPath "TCPNoDelay" 1|Out-Null
                $count++
            }
            Add-Log "Nagle's algorithm disabled on $count adapter(s)" "#9B5DE5"
        }
    } catch { Add-Log "Nagle disable failed" "#EF4444" }
}
function Run-UltimatePlan{
    Set-CurrentTask "Ultimate Performance Power Plan"
    try{
        $srcGuid="e9a42b02-d5df-448d-aa00-03f14749eb61"
        $guid=$null
        # Reuse the scheme this app created on a previous run (if it's still present) instead of
        # matching the literal English label "Ultimate Performance" - that text is localized on
        # non-English Windows installs, which made the old check silently fail and duplicate a
        # brand-new power scheme every single time this tweak ran.
        if($Global:OrigMisc.ContainsKey("PWR_UltimatePlanGuid")){
            $savedGuid=$Global:OrigMisc["PWR_UltimatePlanGuid"]
            if((powercfg /list) -match [regex]::Escape($savedGuid)){ $guid=$savedGuid }
        }
        if(-not $guid){
            $dup=powercfg /duplicatescheme $srcGuid 2>&1
            $guid=[regex]::Match($dup,"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}").Value
            if($guid){ $Global:OrigMisc["PWR_UltimatePlanGuid"]=$guid }
        }
        if($guid){ powercfg /setactive $guid 2>&1|Out-Null; Add-Log "Ultimate Performance plan active" "#9B5DE5" }
        else { Add-Log "Ultimate Performance plan not supported on this system" "#F59E0B" }
        $Global:AppliedKeys["PWR_UltimatePlan"]=$true
    } catch { Add-Log "Ultimate Performance plan failed" "#EF4444" }
}
function Run-NoCoreParking{
    Set-CurrentTask "CPU Core Parking -> Disabled"
    try{
        powercfg /setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 100 2>&1|Out-Null
        powercfg /setdcvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 100 2>&1|Out-Null
        powercfg /setactive scheme_current 2>&1|Out-Null
        Add-Log "Core parking disabled (all cores active)" "#9B5DE5"
        $Global:AppliedKeys["SYS_NoCoreParking"]=$true
    } catch { Add-Log "Core parking tweak failed" "#EF4444" }
}
function Run-HAGS{
    Set-CurrentTask "Hardware-Accelerated GPU Scheduling -> On"
    $p="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    Save-Orig "GM_HAGS" $p "HwSchMode"
    Set-RegValue $p "HwSchMode" 2|Out-Null
    Add-Log "HAGS enabled (reboot)" "#9B5DE5"
    $Global:AppliedKeys["GM_HAGS"]=$true
}
function Get-GpuVendors{
    if($null -ne $Global:GpuVendors){return $Global:GpuVendors}
    $names=@()
    try{ $names=@(Get-CimInstance Win32_VideoController -EA SilentlyContinue|Select-Object -ExpandProperty Name) }catch{}
    $Global:GpuVendors=@{
        Nvidia=($names|Where-Object{$_ -match "NVIDIA"}).Count -gt 0
        Amd=($names|Where-Object{$_ -match "AMD|Radeon|ATI"}).Count -gt 0
    }
    return $Global:GpuVendors
}
function Get-GpuClassSubKeys{
    $classPath="HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    if(-not(Test-Path $classPath)){return @()}
    return Get-ChildItem -Path $classPath -EA SilentlyContinue|Where-Object{$_.PSChildName -match '^\d{4}$'}
}
function Run-GpuTdrDelay{
    # NOTE: GPU_TdrDelay_Nvidia and GPU_TdrDelay_Amd both map to this function because TdrDelay
    # is a single system-wide registry value, not per-vendor. On hybrid (NVIDIA+AMD) systems both
    # toggles can be active at once, so we only touch the registry once and just record the extra
    # toggle key as applied - this avoids duplicate writes/log lines and keeps AppliedKeys in sync
    # with whichever toggle(s) the user actually had checked.
    param($ToggleKey)
    Set-CurrentTask "GPU Timeout Detection (TDR) -> Extended"
    if(-not $Global:AppliedKeys["GPU_TdrDelay"]){
        $p="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        Save-Orig "GPU_TdrDelay" $p "TdrDelay"
        Set-RegValue $p "TdrDelay" 8|Out-Null
        Add-Log "TDR delay extended to 8s" "#9B5DE5"
        $Global:AppliedKeys["GPU_TdrDelay"]=$true
    } else {
        Add-Log "TDR delay already extended by the other GPU toggle - shared setting, skipped duplicate write" "#6B7280"
    }
    if($ToggleKey -and $ToggleKey -ne "GPU_TdrDelay"){ $Global:AppliedKeys[$ToggleKey]=$true }
}
function Run-NvidiaPowerMode{
    Set-CurrentTask "NVIDIA Power Mode -> Prefer Max Performance"
    if(-not (Get-GpuVendors).Nvidia){ Add-Log "No NVIDIA GPU detected - skipped" "#6B7280"; return }
    try{
        $keys=Get-GpuClassSubKeys|Where-Object{ (Get-ItemProperty -Path $_.PSPath -Name "DriverDesc" -EA SilentlyContinue).DriverDesc -match "NVIDIA" }
        foreach($k in $keys){
            $path="HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\$($k.PSChildName)"
            Save-Orig "GPU_NvidiaPowerMode_$($k.PSChildName)" $path "PowerMizerEnable"
            Set-RegValue $path "PowerMizerEnable" 1|Out-Null
            Set-RegValue $path "PowerMizerLevel" 1|Out-Null
            Set-RegValue $path "PowerMizerLevelAC" 1|Out-Null
            Set-RegValue $path "PerfLevelSrc" 0x2222|Out-Null
        }
        Add-Log "NVIDIA power mode set to Prefer Max Performance" "#9B5DE5"
        $Global:AppliedKeys["GPU_NvidiaPowerMode"]=$true
    } catch { Add-Log "NVIDIA power mode tweak skipped" "#F59E0B" }
}
function Run-NvidiaTelemetryOff{
    Set-CurrentTask "NVIDIA Telemetry Service -> Disabled"
    if(-not (Get-GpuVendors).Nvidia){ Add-Log "No NVIDIA GPU detected - skipped" "#6B7280"; return }
    try{
        Stop-Service NvTelemetryContainer -Force -EA SilentlyContinue
        Set-Service NvTelemetryContainer -StartupType Disabled -EA SilentlyContinue
        Add-Log "NVIDIA telemetry service disabled" "#9B5DE5"
        $Global:AppliedKeys["GPU_NvidiaTelemetryOff"]=$true
    } catch { Add-Log "NVIDIA telemetry disable skipped" "#F59E0B" }
}
function Get-GpuInstancePaths{
    param([string]$vendorMatch)
    try{
        $ctrls=Get-CimInstance -ClassName Win32_VideoController -EA SilentlyContinue|Where-Object{$_.Name -match $vendorMatch -or $_.PNPDeviceID -match $vendorMatch}
        return $ctrls|ForEach-Object{ "HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.PNPDeviceID)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" }
    } catch { return @() }
}
function Run-NvidiaMSIMode{
    Set-CurrentTask "NVIDIA MSI Mode -> Enabled"
    if(-not (Get-GpuVendors).Nvidia){ Add-Log "No NVIDIA GPU detected - skipped" "#6B7280"; return }
    try{
        $paths=Get-GpuInstancePaths "NVIDIA"
        foreach($path in $paths){
            Save-Orig "GPU_NvidiaMSIMode_$([math]::Abs($path.GetHashCode()))" $path "MSISupported"
            Set-RegValue $path "MSISupported" 1|Out-Null
        }
        Add-Log "NVIDIA MSI mode enabled (interrupt latency reduced)" "#9B5DE5"
        $Global:AppliedKeys["GPU_NvidiaMSIMode"]=$true
    } catch { Add-Log "NVIDIA MSI mode tweak skipped" "#F59E0B" }
}
function Run-NvidiaOverlayOff{
    Set-CurrentTask "NVIDIA In-Game Overlay -> Disabled"
    if(-not (Get-GpuVendors).Nvidia){ Add-Log "No NVIDIA GPU detected - skipped" "#6B7280"; return }
    try{
        $path="HKCU:\SOFTWARE\NVIDIA Corporation\Global\ShadowPlay\NVSPCAPS"
        Save-Orig "GPU_NvidiaOverlayOff" $path "value"
        Set-RegValue $path "value" 0|Out-Null
        Add-Log "NVIDIA in-game overlay disabled" "#9B5DE5"
        $Global:AppliedKeys["GPU_NvidiaOverlayOff"]=$true
    } catch { Add-Log "NVIDIA overlay disable skipped" "#F59E0B" }
}
function Run-AmdUlps{
    Set-CurrentTask "AMD ULPS -> Disabled"
    if(-not (Get-GpuVendors).Amd){ Add-Log "No AMD GPU detected - skipped" "#6B7280"; return }
    try{
        $keys=Get-GpuClassSubKeys|Where-Object{ (Get-ItemProperty -Path $_.PSPath -Name "DriverDesc" -EA SilentlyContinue).DriverDesc -match "AMD|Radeon|ATI" }
        foreach($k in $keys){
            $path="HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\$($k.PSChildName)"
            Save-Orig "GPU_AmdUlps_$($k.PSChildName)" $path "EnableUlps"
            Set-RegValue $path "EnableUlps" 0|Out-Null
            Set-RegValue $path "EnableUlps_NA" 0|Out-Null
        }
        Add-Log "AMD ULPS disabled" "#9B5DE5"
        $Global:AppliedKeys["GPU_AmdUlps"]=$true
    } catch { Add-Log "AMD ULPS tweak skipped" "#F59E0B" }
}
function Run-AmdEventsUtil{
    Set-CurrentTask "AMD External Events Utility -> Disabled"
    if(-not (Get-GpuVendors).Amd){ Add-Log "No AMD GPU detected - skipped" "#6B7280"; return }
    try{
        Stop-Service "AMD External Events Utility Service" -Force -EA SilentlyContinue
        Set-Service "AMD External Events Utility Service" -StartupType Disabled -EA SilentlyContinue
        Add-Log "AMD External Events Utility disabled" "#9B5DE5"
        $Global:AppliedKeys["GPU_AmdEventsUtil"]=$true
    } catch { Add-Log "AMD External Events Utility disable skipped" "#F59E0B" }
}
function Run-AmdMSIMode{
    Set-CurrentTask "AMD MSI Mode -> Enabled"
    if(-not (Get-GpuVendors).Amd){ Add-Log "No AMD GPU detected - skipped" "#6B7280"; return }
    try{
        $paths=Get-GpuInstancePaths "AMD|Radeon|ATI"
        foreach($path in $paths){
            Save-Orig "GPU_AmdMSIMode_$([math]::Abs($path.GetHashCode()))" $path "MSISupported"
            Set-RegValue $path "MSISupported" 1|Out-Null
        }
        Add-Log "AMD MSI mode enabled (interrupt latency reduced)" "#9B5DE5"
        $Global:AppliedKeys["GPU_AmdMSIMode"]=$true
    } catch { Add-Log "AMD MSI mode tweak skipped" "#F59E0B" }
}
function Run-AmdCrashDefenderOff{
    Set-CurrentTask "AMD Crash Defender -> Disabled"
    if(-not (Get-GpuVendors).Amd){ Add-Log "No AMD GPU detected - skipped" "#6B7280"; return }
    try{
        Stop-Service "AMD Crash Defender Service" -Force -EA SilentlyContinue
        Set-Service "AMD Crash Defender Service" -StartupType Disabled -EA SilentlyContinue
        Add-Log "AMD Crash Defender service disabled" "#9B5DE5"
        $Global:AppliedKeys["GPU_AmdCrashDefenderOff"]=$true
    } catch { Add-Log "AMD Crash Defender disable skipped" "#F59E0B" }
}
function Run-NetPowerSaving{
    param($ToggleKey)
    Set-CurrentTask "Adapter Power Saving -> Off"
    try{
        Invoke-DedupedGlobalTweak "NET_PowerSaving" $ToggleKey {
            $ups=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up"}
            foreach($a in $ups){
                Disable-NetAdapterPowerManagement -Name $a.Name -EA SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "Energy-Efficient Ethernet" -DisplayValue "Disabled" -EA SilentlyContinue
            }
            Add-Log "Adapter power saving disabled" "#9B5DE5"
        }
    } catch { Add-Log "Adapter power saving skipped" "#F59E0B" }
}
function Run-UsbSelSuspend{
    Set-CurrentTask "USB Selective Suspend -> Off"
    $p="HKLM:\SYSTEM\CurrentControlSet\Services\USB"
    Save-Orig "NET_USBSelSuspend" $p "DisableSelectiveSuspend"
    Set-RegValue $p "DisableSelectiveSuspend" 1|Out-Null
    Add-Log "USB selective suspend disabled" "#9B5DE5"
    $Global:AppliedKeys["NET_USBSelSuspend"]=$true
}
function Run-TimerRes{
    Set-CurrentTask "System Timer Resolution -> 0.5ms"
    try{
        if(-not ("Win32TimerRes" -as [type])){
            Add-Type -Namespace Win32TimerResNS -Name Win32TimerRes -MemberDefinition @"
[DllImport("ntdll.dll")] public static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, ref uint CurrentResolution);
"@
        }
        [uint32]$cur=0
        [Win32TimerResNS.Win32TimerRes]::NtSetTimerResolution(5000,$true,[ref]$cur)|Out-Null
        Add-Log "Timer resolution set to ~0.5ms (holds while app is open)" "#9B5DE5"
        $Global:AppliedKeys["SYS_TimerRes"]=$true
    } catch { Add-Log "Timer resolution tweak failed" "#EF4444" }
}
function Run-PauseUpdates{
    Set-CurrentTask "No Auto-Restart for Windows Update"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    Save-Orig "SYS_PauseUpdates" $p "NoAutoRebootWithLoggedOnUsers"
    Set-RegValue $p "NoAutoRebootWithLoggedOnUsers" 1|Out-Null
    Add-Log "Windows Update auto-restart disabled" "#9B5DE5"
    $Global:AppliedKeys["SYS_PauseUpdates"]=$true
}
function Run-GameMode{
    Set-CurrentTask "Windows Game Mode -> Forced On"
    $p="HKCU:\SOFTWARE\Microsoft\GameBar"
    Save-Orig "GM_GameMode" $p "AutoGameModeEnabled"
    Set-RegValue $p "AutoGameModeEnabled" 1|Out-Null
    Add-Log "Game Mode forced on" "#9B5DE5"
    $Global:AppliedKeys["GM_GameMode"]=$true
}
function Run-NoGameDVR{
    Set-CurrentTask "Game Bar / Game DVR -> Disabled"
    $p1="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
    Save-Orig "GM_NoGameDVR_App" $p1 "AppCaptureEnabled"
    Set-RegValue $p1 "AppCaptureEnabled" 0|Out-Null
    $p2="HKCU:\System\GameConfigStore"
    Save-Orig "GM_NoGameDVR_Cfg" $p2 "GameDVR_Enabled"
    Set-RegValue $p2 "GameDVR_Enabled" 0|Out-Null
    Add-Log "Game Bar / Game DVR disabled" "#9B5DE5"
    $Global:AppliedKeys["GM_NoGameDVR"]=$true
}
function Run-GameBarOff{
    Set-CurrentTask "Xbox Game Bar Overlay -> Disabled"
    $p="HKCU:\SOFTWARE\Microsoft\GameBar"
    Save-Orig "GM_GameBarOff_Nexus" $p "UseNexusForGameBarEnabled"
    Set-RegValue $p "UseNexusForGameBarEnabled" 0|Out-Null
    Save-Orig "GM_GameBarOff_Startup" $p "ShowStartupPanel"
    Set-RegValue $p "ShowStartupPanel" 0|Out-Null
    Add-Log "Xbox Game Bar overlay disabled" "#9B5DE5"
    $Global:AppliedKeys["GM_GameBarOff"]=$true
}
function Run-StandbyClean{
    Set-CurrentTask "Clear Standby Memory List"
    try{
        if(-not ("Win32MemPurge" -as [type])){
            Add-Type -Namespace Win32MemPurgeNS -Name Win32MemPurge -MemberDefinition @"
[DllImport("ntdll.dll")] public static extern int NtSetSystemInformation(int InfoClass, IntPtr Info, int Length);
"@
        }
        $cmd=4 # MemoryPurgeStandbyList
        $ptr=[System.Runtime.InteropServices.Marshal]::AllocHGlobal(4)
        [System.Runtime.InteropServices.Marshal]::WriteInt32($ptr,$cmd)
        [Win32MemPurgeNS.Win32MemPurge]::NtSetSystemInformation(80,$ptr,4)|Out-Null
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
        Add-Log "Standby memory list cleared" "#9B5DE5"
        $Global:AppliedKeys["GM_StandbyClean"]=$true
    } catch { Add-Log "Standby list clear failed (needs admin)" "#EF4444" }
}
function Run-NoSearchIndex{
    Set-CurrentTask "Windows Search Indexing -> Disabled"
    try{
        Save-OrigService "CLEAN_NoSearchIndex" "WSearch"
        Stop-Service WSearch -Force -EA SilentlyContinue
        Set-Service WSearch -StartupType Disabled -EA SilentlyContinue
        Add-Log "Windows Search indexing disabled" "#9B5DE5"
        $Global:AppliedKeys["CLEAN_NoSearchIndex"]=$true
    } catch { Add-Log "Search indexing disable skipped" "#F59E0B" }
}
function Run-NoTelemetry{
    Set-CurrentTask "Telemetry Service -> Disabled"
    try{
        Save-OrigService "CLEAN_NoTelemetry" "DiagTrack"
        Stop-Service DiagTrack -Force -EA SilentlyContinue
        Set-Service DiagTrack -StartupType Disabled -EA SilentlyContinue
        Add-Log "Telemetry (DiagTrack) service disabled" "#9B5DE5"
        $Global:AppliedKeys["CLEAN_NoTelemetry"]=$true
    } catch { Add-Log "Telemetry disable skipped" "#F59E0B" }
}
function Run-NoStorageSense{
    Set-CurrentTask "Storage Sense -> Disabled"
    $p="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
    Save-Orig "CLEAN_NoStorageSense" $p "01"
    Set-RegValue $p "01" 0|Out-Null
    Add-Log "Storage Sense disabled" "#9B5DE5"
    $Global:AppliedKeys["CLEAN_NoStorageSense"]=$true
}
function Run-OneDriveSyncOff{
    Set-CurrentTask "OneDrive Background Sync -> Off"
    try{
        $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
        Save-Orig "SYS_OneDriveSyncOff" $p "DisableFileSyncNGSC"
        Set-RegValue $p "DisableFileSyncNGSC" 1|Out-Null
        Get-Process -Name OneDrive -EA Ignore|Stop-Process -Force -EA SilentlyContinue
        Add-Log "OneDrive file sync policy disabled and process stopped" "#9B5DE5"
        $Global:AppliedKeys["SYS_OneDriveSyncOff"]=$true
    } catch { Add-Log "OneDrive sync tweak skipped" "#F59E0B" }
}
function Run-WidgetsOff{
    Set-CurrentTask "Windows Widgets -> Disabled"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
    Save-Orig "SYS_WidgetsOff" $p "AllowNewsAndInterests"
    Set-RegValue $p "AllowNewsAndInterests" 0|Out-Null
    Add-Log "Windows Widgets / News and Interests disabled" "#9B5DE5"
    $Global:AppliedKeys["SYS_WidgetsOff"]=$true
}
function Run-ConsumerFeaturesOff{
    Set-CurrentTask "Consumer Features / Suggested Apps -> Blocked"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    Save-Orig "SYS_ConsumerFeaturesOff" $p "DisableWindowsConsumerFeatures"
    Set-RegValue $p "DisableWindowsConsumerFeatures" 1|Out-Null
    Add-Log "Microsoft consumer experiences / suggested apps blocked" "#9B5DE5"
    $Global:AppliedKeys["SYS_ConsumerFeaturesOff"]=$true
}
function Run-Win32Priority{
    Set-CurrentTask "Win32PrioritySeparation -> Lowest Input Lag (40)"
    $p="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
    Save-Orig "SYS_Win32Priority" $p "Win32PrioritySeparation"
    Set-RegValue $p "Win32PrioritySeparation" 0xFA322A|Out-Null
    Add-Log "Win32PrioritySeparation set to 0xFA322A (Windows only reads the low 6 bits -> effectively 0x2A / 42)" "#9B5DE5"
    $Global:AppliedKeys["SYS_Win32Priority"]=$true
}
function Run-MMCSS{
    Set-CurrentTask "MMCSS Games Profile -> Smooth Max"
    $p="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    foreach($n in @("GPU Priority","Priority","Scheduling Category","SFIO Priority","Background Only","Clock Rate")){
        Save-Orig "GM_MMCSS_$($n -replace ' ','')" $p $n
    }
    Set-RegValue $p "GPU Priority" 8|Out-Null
    Set-RegValue $p "Priority" 6|Out-Null
    Set-RegValue $p "Scheduling Category" "High" "String"|Out-Null
    Set-RegValue $p "SFIO Priority" "High" "String"|Out-Null
    Set-RegValue $p "Background Only" "False" "String"|Out-Null
    Set-RegValue $p "Clock Rate" 10000|Out-Null
    Add-Log "MMCSS Games profile tuned for smoothest scheduling" "#9B5DE5"
    $Global:AppliedKeys["GM_MMCSS"]=$true
}
function Run-TcpTimedWait{
    param($ToggleKey)
    Set-CurrentTask "TCP TIME_WAIT Delay -> 30s"
    Invoke-DedupedGlobalTweak "NET_TcpTimedWait" $ToggleKey {
        $p="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        Save-Orig "NET_TcpTimedWait" $p "TcpTimedWaitDelay"
        Set-RegValue $p "TcpTimedWaitDelay" 30|Out-Null
        Add-Log "TCP TIME_WAIT delay set to 30s" "#9B5DE5"
    }
}
function Run-PortRange{
    param($ToggleKey)
    Set-CurrentTask "Dynamic Port Range -> Widened"
    try{
        Invoke-DedupedGlobalTweak "NET_PortRange" $ToggleKey {
            netsh int ipv4 set dynamicport tcp start=10000 num=55536 2>&1|Out-Null
            netsh int ipv4 set dynamicport udp start=10000 num=55536 2>&1|Out-Null
            netsh int ipv6 set dynamicport tcp start=10000 num=55536 2>&1|Out-Null
            netsh int ipv6 set dynamicport udp start=10000 num=55536 2>&1|Out-Null
            Add-Log "Dynamic port range widened (10000-65535)" "#9B5DE5"
        }
    } catch { Add-Log "Port range widen failed" "#EF4444" }
}
function Run-QoSReserve{
    param($ToggleKey)
    Set-CurrentTask "QoS Reserved Bandwidth -> 0% (gpedit)"
    Invoke-DedupedGlobalTweak "NET_QoSReserve" $ToggleKey {
        $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
        Save-Orig "NET_QoSReserve" $p "NonBestEffortLimit"
        Set-RegValue $p "NonBestEffortLimit" 0|Out-Null
        Add-Log "QoS reserved bandwidth returned to 0%" "#9B5DE5"
    }
}
function Run-MouseQueue{
    Set-CurrentTask "Mouse Data Queue Size -> 100 (Windows default)"
    $p="HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters"
    Save-Orig "GM_MouseQueue" $p "MouseDataQueueSize"
    # NOTE: 100 is Windows' own default. A high polling-rate mouse (500Hz-8000Hz)
    # can send far more reports than a queue of 10 can hold; when it overflows,
    # reports get dropped, which is exactly what causes cursor "ghosting"/skipping/
    # stutter. Keeping this at the OS default removes that risk while still
    # applying the tweak (in case it was previously shrunk by this or another tool).
    Set-RegValue $p "MouseDataQueueSize" 100|Out-Null
    Add-Log "Mouse data queue restored to safe default (100)" "#9B5DE5"
    $Global:AppliedKeys["GM_MouseQueue"]=$true
}
function Run-NoStickyKeys{
    Set-CurrentTask "Sticky/Toggle/Filter Keys -> Disabled"
    $pSK="HKCU:\Control Panel\Accessibility\StickyKeys"
    $pTK="HKCU:\Control Panel\Accessibility\ToggleKeys"
    $pFK="HKCU:\Control Panel\Accessibility\Keyboard Response"
    Save-Orig "GM_NoStickyKeys_SK" $pSK "Flags"
    Save-Orig "GM_NoStickyKeys_TK" $pTK "Flags"
    Save-Orig "GM_NoStickyKeys_FK" $pFK "Flags"
    Set-RegValue $pSK "Flags" "58" "String"|Out-Null
    Set-RegValue $pTK "Flags" "58" "String"|Out-Null
    Set-RegValue $pFK "Flags" "58" "String"|Out-Null
    Add-Log "Accessibility keyboard hotkeys disabled" "#9B5DE5"
    $Global:AppliedKeys["GM_NoStickyKeys"]=$true
}
function Run-NoBackgroundApps{
    Set-CurrentTask "UWP Background Apps -> Blocked (gpedit)"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
    Save-Orig "SYS_NoBackgroundApps" $p "LetAppsRunInBackground"
    Set-RegValue $p "LetAppsRunInBackground" 2|Out-Null
    Add-Log "UWP background apps force-denied" "#9B5DE5"
    $Global:AppliedKeys["SYS_NoBackgroundApps"]=$true
}
function Run-NoBkgndGPRefresh{
    Set-CurrentTask "Background Group Policy Refresh -> Disabled"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    Save-Orig "SYS_NoBkgndGPRefresh" $p "DisableBkGndGroupPolicy"
    Set-RegValue $p "DisableBkGndGroupPolicy" 1|Out-Null
    Add-Log "Background Group Policy refresh disabled" "#9B5DE5"
    $Global:AppliedKeys["SYS_NoBkgndGPRefresh"]=$true
}
function Run-NoSmartScreenCheck{
    Set-CurrentTask "SmartScreen App Reputation Check -> Off"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    Save-Orig "SYS_NoSmartScreenCheck" $p "EnableSmartScreen"
    Set-RegValue $p "EnableSmartScreen" 0|Out-Null
    Add-Log "SmartScreen app reputation check turned off" "#9B5DE5"
    $Global:AppliedKeys["SYS_NoSmartScreenCheck"]=$true
}
function Run-NoWER{
    Set-CurrentTask "Windows Error Reporting -> Disabled"
    try{
        Save-OrigService "CLEAN_NoWER" "WerSvc"
        Stop-Service WerSvc -Force -EA SilentlyContinue
        Set-Service WerSvc -StartupType Disabled -EA SilentlyContinue
        Add-Log "Windows Error Reporting service disabled" "#9B5DE5"
        $Global:AppliedKeys["CLEAN_NoWER"]=$true
    } catch { Add-Log "WER disable skipped" "#F59E0B" }
}
function Run-NoPrintSpooler{
    Set-CurrentTask "Print Spooler -> Disabled"
    try{
        Save-OrigService "CLEAN_NoPrintSpooler" "Spooler"
        Stop-Service Spooler -Force -EA SilentlyContinue
        Set-Service Spooler -StartupType Disabled -EA SilentlyContinue
        Add-Log "Print Spooler disabled (printing will not work)" "#9B5DE5"
        $Global:AppliedKeys["CLEAN_NoPrintSpooler"]=$true
    } catch { Add-Log "Print Spooler disable skipped" "#F59E0B" }
}
$BtnRestore.Add_Click({
    $confirm=[System.Windows.MessageBox]::Show("This will revert every tweak this app has changed (registry values, services, Defender exclusions) back to what they were before.`n`nContinue?","Sync Project - Restore",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
    if($confirm -ne [System.Windows.MessageBoxResult]::Yes){ return }
    Add-Log "--- RESTORING ORIGINAL SETTINGS ---" "#F59E0B"

    # 1) Registry values: restore if a previous value existed, otherwise DELETE the value/key we created
    foreach($k in $Global:Orig.Keys){
        $o=$Global:Orig[$k]
        try{
            if($null -ne $o.Value){
                Set-RegValue $o.Path $o.Name $o.Value|Out-Null
                Add-Log "Restored: $k" "#6B7280"
            } else {
                if(Test-Path $o.Path){ Remove-ItemProperty -Path $o.Path -Name $o.Name -EA SilentlyContinue }
                Add-Log "Removed (was not set before): $k" "#6B7280"
            }
        } catch { Add-Log "Could not restore $k`: $_" "#EF4444" }
    }

    # 2) Services: restore original StartupType and running state
    foreach($k in $Global:OrigServices.Keys){
        Restore-OrigService $Global:OrigServices[$k]
        Add-Log "Restored service: $($Global:OrigServices[$k].ServiceName)" "#6B7280"
    }

    # 3) Defender exclusions we added
    if($Global:OrigMisc.ContainsKey("DEF_GameExclusion")){
        foreach($p in $Global:OrigMisc["DEF_GameExclusion"]){
            try{ Remove-MpPreference -ExclusionPath $p -EA SilentlyContinue }catch{}
        }
        Add-Log "Removed Defender exclusions added by this app" "#6B7280"
    }

    # 3b) FiveM QoS policies we created
    if($Global:OrigMisc.ContainsKey("NET_FiveMQos_Policies")){
        foreach($polName in $Global:OrigMisc["NET_FiveMQos_Policies"]){
            try{ Get-NetQosPolicy -Name $polName -EA SilentlyContinue | Remove-NetQosPolicy -Confirm:$false -EA SilentlyContinue }catch{}
        }
        Add-Log "Removed FiveM QoS priority tags" "#6B7280"
    }

    # 3c) FiveM firewall rules we created
    if($Global:OrigMisc.ContainsKey("NET_FiveMFirewall_Rules")){
        foreach($ruleName in $Global:OrigMisc["NET_FiveMFirewall_Rules"]){
            try{ Remove-NetFirewallRule -DisplayName $ruleName -EA SilentlyContinue }catch{}
        }
        Add-Log "Removed FiveM firewall allow rules" "#6B7280"
    }

    # 3d) Launcher/chat app startup entries we removed - re-add them
    if($Global:OrigMisc.ContainsKey("CLEAN_DisableLauncherStartup")){
        foreach($entry in $Global:OrigMisc["CLEAN_DisableLauncherStartup"]){
            try{
                if(-not (Test-Path $entry.Path)){ New-Item -Path $entry.Path -Force|Out-Null }
                Set-ItemProperty -Path $entry.Path -Name $entry.Name -Value $entry.Value -EA SilentlyContinue
            } catch {}
        }
        Add-Log "Restored startup entries (Steam/Discord/Epic/etc.)" "#6B7280"
    }

    # 4) Things this app cannot fully auto-revert (netsh/bcdedit/powercfg) - tell the user explicitly
    $manual=@()
    if($Global:AppliedKeys["TcpGlobal"] -or $Global:AppliedKeys["LanOptimize"]){
        $reverted=$false
        try{
            netsh int tcp set global autotuninglevel=normal rss=enabled ecncapability=default fastopen=disabled congestionprovider=default 2>&1|Out-Null
            Add-Log "TCP global stack settings reverted to Windows defaults" "#6B7280"
            $reverted=$true
        } catch {}
        if(-not $reverted){ $manual+="TCP global settings (netsh int tcp) - run: netsh int tcp set global autotuninglevel=normal rss=enabled ecncapability=default fastopen=disabled congestionprovider=default" }
    }
    if($Global:AppliedKeys["BcdTimer"] -or $Global:AppliedKeys["ADV_HPET"]){
        $reverted=$false
        try{
            bcdedit /deletevalue useplatformtick 2>&1|Out-Null
            bcdedit /deletevalue disabledynamictick 2>&1|Out-Null
            bcdedit /deletevalue useplatformclock 2>&1|Out-Null
            Add-Log "Boot timer/HPET BCD overrides cleared (reboot for it to take effect)" "#6B7280"
            $reverted=$true
        } catch {}
        if(-not $reverted){ $manual+="Boot timer/HPET (bcdedit) - run: bcdedit /deletevalue useplatformtick; bcdedit /deletevalue disabledynamictick; bcdedit /deletevalue useplatformclock" }
    }
    if($Global:AppliedKeys["PWR_UltimatePlan"]){
        $reverted=$false
        try{
            powercfg /setactive SCHEME_BALANCED 2>&1|Out-Null
            if($Global:OrigMisc.ContainsKey("PWR_UltimatePlanGuid")){
                powercfg /delete $Global:OrigMisc["PWR_UltimatePlanGuid"] 2>&1|Out-Null
            }
            Add-Log "Switched back to Balanced power plan and removed the duplicated Ultimate Performance scheme" "#6B7280"
            $reverted=$true
        } catch {}
        if(-not $reverted){ $manual+="Ultimate Performance power plan - switch back to Balanced in Power Options" }
    }
    if($Global:AppliedKeys["SYS_NoCoreParking"]){ $manual+="CPU core parking - re-enable via powercfg or reset the power plan" }
    if($Global:AppliedKeys["CLEAN_SmoothOptim"]){
        $reverted=$false
        try{
            Enable-ScheduledTask -TaskName "\Microsoft\Windows\TaskScheduler\Regular Maintenance" -EA Stop|Out-Null
            Add-Log "Re-enabled the 'Regular Maintenance' scheduled task" "#6B7280"
            $reverted=$true
        } catch {}
        if(-not $reverted){ $manual+="Scheduled Task 'Regular Maintenance' - re-enable it in Task Scheduler" }
    }
    if($Global:OrigMisc.ContainsKey("CLEAN_RemoveBloat") -and $Global:OrigMisc["CLEAN_RemoveBloat"].Count -gt 0){
        $manual+="Removed apps CANNOT be auto-reinstalled. If you want any of these back, reinstall from the Microsoft Store: " + ($Global:OrigMisc["CLEAN_RemoveBloat"] -join ", ")
    }
    if($manual.Count -gt 0){
        Add-Log "NOTE: some changes need a manual step to fully undo:" "#F59E0B"
        foreach($m in $manual){ Add-Log " - $m" "#F59E0B" }
    }

    $Global:Orig.Clear();$Global:AppliedKeys.Clear();$Global:OrigServices.Clear();$Global:OrigMisc.Clear();Save-TweakState
    Add-Log "Restore complete." "#10B981";$CurrentTask.Text="Settings restored."
})

$BtnRun.Add_Click({
    Trace-Dbg "BtnRun click ENTER (IsRunning=$($Global:IsRunning))"
    if($Global:IsRunning){ Trace-Dbg "BtnRun click BLOCKED (already running)"; return }  # guard: a run is already in progress - ignore re-entrant clicks / Enter-key re-triggers
    $activeKeys=$Global:TweakToggles.Keys|Where-Object{$Global:TweakToggles[$_] -eq $true}
    $total=($activeKeys|Measure-Object).Count
    if($total -eq 0){Add-Log "No tweaks selected." "#EF4444";return}

    # --- Safety check #1: warn about the selected tweaks that change system behavior in ways the user should know about ---
    $riskyMap = [ordered]@{
        "SYS_PauseUpdates"        = "Windows Update will be paused"
        "CLEAN_NoTelemetry"       = "Telemetry / diagnostic data collection will be disabled"
        "CLEAN_NoWER"             = "Windows Error Reporting will be disabled"
        "CLEAN_NoPrintSpooler"    = "Print Spooler service will be disabled (printing will stop working)"
        "SYS_NoBackgroundApps"    = "Background apps will be restricted"
        "CLEAN_RemoveBloat"       = "Pre-installed 'bloatware' apps will be removed"
        "CLEAN_KillBackgroundProcs" = "Common background apps (OneDrive, Discord, Spotify, browser updaters, etc.) will be force-closed if running"
        "CLEAN_DisableLauncherStartup" = "Steam/Discord/Epic/Battle.net/Origin/Ubisoft/Riot/GOG/Spotify will no longer auto-start with Windows (still openable manually)"
        "SYS_ConsumerFeaturesOff" = "Windows 'suggested content' / consumer features will be disabled"
        "SYS_WidgetsOff"         = "Windows Widgets will be disabled"
        "SYS_OneDriveSyncOff"    = "OneDrive sync will be turned off"
        "NET_RemoteAssistanceOff"= "Remote Assistance will be disabled"
        "NET_NoAutoRootCertUpdate" = "Automatic root certificate updates will be disabled"
        "NduDisable"             = "Network Data Usage (Ndu) driver will be disabled"
        "NduDisable_WiFi"        = "Network Data Usage (Ndu) driver will be disabled"
        "NET_Ipv6Disable"        = "IPv6 will be unbound on the wired adapter"
        "NET_Ipv6Disable_WiFi"   = "IPv6 will be unbound on the Wi-Fi adapter"
    }
    $activeRisky=@()
    foreach($k in $riskyMap.Keys){ if($Global:TweakToggles[$k] -and ($activeRisky -notcontains $riskyMap[$k])){ $activeRisky += $riskyMap[$k] } }
    if($activeRisky.Count -gt 0){
        $riskMsg = "The tweaks you selected include changes you should know about:`n`n- " + ($activeRisky -join "`n- ") + "`n`nContinue?"
        $riskConfirm=[System.Windows.MessageBox]::Show($riskMsg,"Sync Project - Please Review",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
        if($riskConfirm -ne [System.Windows.MessageBoxResult]::Yes){ Add-Log "Run cancelled by user at the review step." "#F59E0B"; return }
    }

    # --- Safety check #1b: for the three tweaks that remove/kill/disable actual apps, show the
    # SPECIFIC list of what's actually installed/running on THIS machine (not a generic description)
    # and let the user opt each one out individually without cancelling the whole run. ---
    $skipKeys=@()
    if($Global:TweakToggles["CLEAN_RemoveBloat"]){
        $__installedPkgs = @(Get-AppxPackage -EA SilentlyContinue | Select-Object -ExpandProperty Name)
        $foundBloat=@($Global:BloatList | Where-Object { $__installedPkgs -contains $_ })
        if($foundBloat.Count -gt 0){
            $msg="These pre-installed apps will be REMOVED from this PC:`n`n- "+($foundBloat -join "`n- ")+"`n`nNOTE: this cannot be undone by the Restore Defaults button - to get an app back you'd need to reinstall it from the Microsoft Store.`n`nRemove them?"
            $r=[System.Windows.MessageBox]::Show($msg,"Sync Project - Confirm App Removal",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
            if($r -ne [System.Windows.MessageBoxResult]::Yes){ $skipKeys+="CLEAN_RemoveBloat"; Add-Log "Skipped: app removal (declined by user)." "#F59E0B" }
        }
    }
    if($Global:TweakToggles["CLEAN_KillBackgroundProcs"]){
        $foundProcs=@($Global:KillProcList | Where-Object { Get-Process -Name $_ -EA Ignore } | Select-Object -Unique)
        if($foundProcs.Count -gt 0){
            $msg="These currently-running apps will be FORCE-CLOSED:`n`n- "+($foundProcs -join "`n- ")+"`n`nClose them now? (You can reopen them manually afterward.)"
            $r=[System.Windows.MessageBox]::Show($msg,"Sync Project - Confirm Force-Close",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
            if($r -ne [System.Windows.MessageBoxResult]::Yes){ $skipKeys+="CLEAN_KillBackgroundProcs"; Add-Log "Skipped: force-close background apps (declined by user)." "#F59E0B" }
        }
    }
    if($Global:TweakToggles["CLEAN_DisableLauncherStartup"]){
        $msg="Auto-start on Windows login will be DISABLED for any installed launcher/chat app matching:`n`n- "+($Global:StartupDisableTargets -join "`n- ")+"`n`n(They'll still open fine manually - this only stops them launching automatically.) Continue?"
        $r=[System.Windows.MessageBox]::Show($msg,"Sync Project - Confirm Startup Change",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
        if($r -ne [System.Windows.MessageBoxResult]::Yes){ $skipKeys+="CLEAN_DisableLauncherStartup"; Add-Log "Skipped: disable launcher startup (declined by user)." "#F59E0B" }
    }
    if($skipKeys.Count -gt 0){
        $activeKeys=@($activeKeys | Where-Object { $skipKeys -notcontains $_ })
        $total=($activeKeys|Measure-Object).Count
        if($total -eq 0){ Add-Log "No tweaks left to run after declining the app changes above." "#EF4444"; return }
    }

    # --- Safety check #2: offer to create a System Restore Point first ---
    $rpChoice=[System.Windows.MessageBox]::Show("Create a Windows System Restore Point before applying tweaks? (Recommended, lets you undo everything from Control Panel if something goes wrong)`n`nYes = create restore point, then continue`nNo = continue without one`nCancel = don't run anything","Sync Project - Safety Check",[System.Windows.MessageBoxButton]::YesNoCancel,[System.Windows.MessageBoxImage]::Question)
    if($rpChoice -eq [System.Windows.MessageBoxResult]::Cancel){ Add-Log "Run cancelled by user." "#F59E0B"; return }
    if($rpChoice -eq [System.Windows.MessageBoxResult]::Yes){
        Add-Log "Creating System Restore Point..." "#6B7280"
        try{
            Enable-ComputerRestore -Drive "$env:SystemDrive\" -EA SilentlyContinue
            Checkpoint-Computer -Description "Sync Project - before tweaks" -RestorePointType "MODIFY_SETTINGS" -EA Stop
            Add-Log "Restore point created." "#10B981"
        } catch {
            Add-Log "Could not create a restore point: $_" "#F59E0B"
            $cont=[System.Windows.MessageBox]::Show("Failed to create a restore point.`n`n$_`n`nContinue anyway without one?","Sync Project",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
            if($cont -ne [System.Windows.MessageBoxResult]::Yes){ Add-Log "Run cancelled by user." "#F59E0B"; return }
        }
    }

    $Global:IsRunning=$true; Set-StatusRunning; Add-Log "--- SYNC PROJECT STARTED ---" "#9B5DE5"
    $Global:IsCancelled=$false; $script:done=0; Update-Progress 0 $total
    $runMap=@{
        "NetThrottle"="Run-NetThrottle";"BcdTimer"="Run-BcdTimer";"TcpGlobal"="Run-TcpGlobal"
        "KbQueue"="Run-KbQueue";"NduDisable"="Run-NduDisable";"GamingMemory"="Run-GamingMemory"
        "FiveMBooster"="Run-FiveMBooster";"GM_FiveMPerfOptions"="Run-FiveMPerfOptions";"GM_FiveMCoreAffinity"="Run-FiveMCoreAffinity";"NET_KillerFix"="Run-KillerFix";"NET_FiveMQos"="Run-FiveMQos";"NET_FiveMFirewall"="Run-FiveMFirewall";"DriverHealth"="Run-DriverHealth"
        "LanOptimize"="Run-LanOptimize";"WifiOptimize"="Run-WifiOptimize"
        "PWR_Throttling"="Run-PwrThrottling";"GM_FSOptim"="Run-FSOptim";"GM_MouseAccel"="Run-MouseAccel"
        "UX_MenuInstant"="Run-MenuInstant";"UX_Notifications"="Run-Notifications"
        "ADV_HPET"="Run-HPET";"GM_SmoothMotion"="Run-MPODisable";"CLEAN_SmoothOptim"="Run-SmoothOptim"
        "NET_NoNagle"="Run-NoNagle";"PWR_UltimatePlan"="Run-UltimatePlan";"SYS_NoCoreParking"="Run-NoCoreParking";"GM_HAGS"="Run-HAGS"
        "NET_PowerSaving"="Run-NetPowerSaving";"NET_USBSelSuspend"="Run-UsbSelSuspend"
        "SYS_TimerRes"="Run-TimerRes";"SYS_PauseUpdates"="Run-PauseUpdates"
        "GM_GameMode"="Run-GameMode";"GM_NoGameDVR"="Run-NoGameDVR";"GM_GameBarOff"="Run-GameBarOff";"GM_StandbyClean"="Run-StandbyClean"
        "CLEAN_NoSearchIndex"="Run-NoSearchIndex";"CLEAN_NoTelemetry"="Run-NoTelemetry";"CLEAN_NoStorageSense"="Run-NoStorageSense"
        "SYS_Win32Priority"="Run-Win32Priority";"GM_MMCSS"="Run-MMCSS"
        "NET_TcpTimedWait"="Run-TcpTimedWait";"NET_PortRange"="Run-PortRange";"NET_QoSReserve"="Run-QoSReserve"
        "GM_MouseQueue"="Run-MouseQueue";"GM_NoStickyKeys"="Run-NoStickyKeys"
        "SYS_NoBackgroundApps"="Run-NoBackgroundApps";"CLEAN_NoWER"="Run-NoWER";"CLEAN_NoPrintSpooler"="Run-NoPrintSpooler"
        "GPU_TdrDelay_Nvidia"="Run-GpuTdrDelay";"GPU_TdrDelay_Amd"="Run-GpuTdrDelay";"GPU_NvidiaPowerMode"="Run-NvidiaPowerMode";"GPU_NvidiaTelemetryOff"="Run-NvidiaTelemetryOff"
        "GPU_NvidiaMSIMode"="Run-NvidiaMSIMode";"GPU_NvidiaOverlayOff"="Run-NvidiaOverlayOff"
        "GPU_AmdUlps"="Run-AmdUlps";"GPU_AmdEventsUtil"="Run-AmdEventsUtil"
        "GPU_AmdMSIMode"="Run-AmdMSIMode";"GPU_AmdCrashDefenderOff"="Run-AmdCrashDefenderOff"
        "NetThrottle_WiFi"="Run-NetThrottle";"TcpGlobal_WiFi"="Run-TcpGlobal";"NduDisable_WiFi"="Run-NduDisable"
        "NET_NoNagle_WiFi"="Run-NoNagle";"NET_PowerSaving_WiFi"="Run-NetPowerSaving"
        "NET_TcpTimedWait_WiFi"="Run-TcpTimedWait";"NET_PortRange_WiFi"="Run-PortRange";"NET_QoSReserve_WiFi"="Run-QoSReserve"
        "NET_LanJumboFrame"="Run-LanJumboFrame";"NET_LanInterruptModeration"="Run-LanInterruptModeration"
        "NET_WifiPowerSaveMode"="Run-WifiPowerSaveMode";"NET_WifiRoamingAggressiveness"="Run-WifiRoamingAggressiveness"
        "NET_DnsFast"="Run-DnsFastLan";"NET_DnsFast_WiFi"="Run-DnsFastWifi"
        "NET_DeliveryOptOff"="Run-DeliveryOptOff";"NET_DnsCacheAggressive"="Run-DnsCacheAggressive"
        "SYS_BottleneckCheck"="Run-BottleneckCheck";"GPU_ClearShaderCache"="Run-ClearShaderCache"
        "CLEAN_ClearTempJunk"="Run-ClearTempJunk";"CLEAN_ClearFiveMCache"="Run-ClearFiveMCache"
        "CLEAN_RemoveBloat"="Run-RemoveBloat";"CLEAN_KillBackgroundProcs"="Run-KillBackgroundProcesses";"CLEAN_DisableLauncherStartup"="Run-DisableLauncherStartup"
        "NET_Ipv6Disable"="Run-Ipv6DisableLan";"NET_Ipv6Disable_WiFi"="Run-Ipv6DisableWifi"
        "NET_RssEnable"="Run-RssEnable";"NET_FlowControlOff"="Run-FlowControlOff"
        "DEF_GameExclusion"="Run-GameExclusion";"SYS_PageFileAuto"="Run-PageFileAuto"
        "NET_Ipv6Transition"="Run-Ipv6TransitionDisable";"NET_DnsClientPolicy"="Run-DnsClientPolicy"
        "NET_LltdDisable"="Run-LltdDisable";"NET_BitsNoLimit"="Run-BitsNoLimit";"NET_NetbiosDisable"="Run-NetbiosDisable"
        "NET_NcsiNoActiveProbe"="Run-NcsiNoActiveProbe";"NET_NoAutoRootCertUpdate"="Run-NoAutoRootCertUpdate"
        "SYS_NoBkgndGPRefresh"="Run-NoBkgndGPRefresh";"SYS_NoSmartScreenCheck"="Run-NoSmartScreenCheck"
        "NET_RemoteAssistanceOff"="Run-RemoteAssistanceOff"
        "SYS_OneDriveSyncOff"="Run-OneDriveSyncOff";"SYS_WidgetsOff"="Run-WidgetsOff";"SYS_ConsumerFeaturesOff"="Run-ConsumerFeaturesOff"
    }
    $timer=New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval=[TimeSpan]::FromMilliseconds(110)
    $keyQueue=[System.Collections.Queue]::new($activeKeys)
    $script:_total = $total; $script:_done = 0
    $timer.Add_Tick({
        if($keyQueue.Count -eq 0 -or $Global:IsCancelled){
            $timer.Stop();Save-TweakState
            Trace-Dbg "RUN complete branch (cancelled=$($Global:IsCancelled))"
            Add-Log "--- SYNC PROJECT COMPLETE ---" "#10B981"
            if(-not $Global:IsCancelled){
                Add-Log "Some tweaks require a restart to fully take effect. Please restart your PC now." "#F59E0B"
                [System.Windows.MessageBox]::Show("All tweaks have been applied.`n`nSome changes require a restart to fully take effect. Please restart your PC now.","Sync Project - Complete",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information)|Out-Null
            }
            Set-CurrentTask "All done! Please restart your PC.";Set-StatusDone;Update-Progress $script:_total $script:_total;$Global:IsRunning=$false;return
        }
        $k=$keyQueue.Dequeue();$script:_done++;Update-Progress $script:_done $script:_total
        if($runMap.ContainsKey($k)){
            $fnName=$runMap[$k]
            $Error.Clear()
            try{
                & (Get-Command $fnName -CommandType Function).ScriptBlock $k
                if($Error.Count -gt 0){
                    # -EA SilentlyContinue suppresses throwing but still records to $Error, so a tweak
                    # can "succeed" (no exception) while individual sub-steps quietly failed. Surface that
                    # instead of always claiming [OK].
                    Add-Log "[OK w/ $($Error.Count) warning(s)] $k - some sub-steps may not have applied (e.g. unsupported hardware, missing key, no permission): $($Error[0].ToString())" "#F59E0B"
                } else {
                    Add-Log "[OK] $k" "#10B981"
                }
            } catch {
                Add-Log "[FAIL] $k`: $_" "#EF4444"
            }
        } else { Set-CurrentTask $k; Add-Log "[OK] $k applied" "#10B981" }
    }.GetNewClosure())
    $timer.Start()
})

Add-Log "> SYNC PROJECT console initialised." "#9B5DE5"
Add-Log "> System profile detected. Ready to tune." "#6B7280"

$window.Add_KeyDown({
    param($s,$e)
    if($e.Key -eq [System.Windows.Input.Key]::Escape){
        if($CategoryOverlay.Visibility -eq "Visible"){ Close-CategoryDetail; $e.Handled=$true }
    } elseif(($e.Key -eq [System.Windows.Input.Key]::Return -or $e.Key -eq [System.Windows.Input.Key]::Enter)){
        if($CategoryOverlay.Visibility -ne "Visible" -and (-not $SearchBox.IsFocused) -and (-not $Global:IsRunning)){
            $BtnRun.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
            $e.Handled=$true
        }
    }
})

$window.Add_Closing({
    Trace-Dbg "main window CLOSING event fired"
    if($Global:BackgroundJobs){
        foreach($j in $Global:BackgroundJobs){
            try{ Stop-Job -Job $j -EA SilentlyContinue; Remove-Job -Job $j -Force -EA SilentlyContinue }catch{}
        }
    }
})
$window.Add_Loaded({ Trace-Dbg "main window Loaded event fired" })

Update-PresetGlowConsistency
Trace-Dbg "about to call main ShowDialog"
$window.ShowDialog()|Out-Null
Trace-Dbg "main ShowDialog RETURNED (window closed)"