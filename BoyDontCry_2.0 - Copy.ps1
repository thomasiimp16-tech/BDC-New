# ===================== BDC 2.0 =====================
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ===================== BLACK / WHITE HUD COLORS =====================
$TEXT     = [System.Drawing.Color]::FromArgb(245,245,245)
# ===================== KEY SYSTEM =====================

try {
    $UserKey = Read-Host "Enter Key"

# ===================== BDC LOGIN GUI =====================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$LoginForm = New-Object System.Windows.Forms.Form
$LoginForm.Text = "BDC Authentication"
$LoginForm.Size = New-Object System.Drawing.Size(420,260)
$LoginForm.StartPosition = "CenterScreen"
$LoginForm.FormBorderStyle = "FixedSingle"
$LoginForm.MaximizeBox = $false
$LoginForm.BackColor = [System.Drawing.Color]::FromArgb(15,15,15)

$Logo = New-Object System.Windows.Forms.Label
$Logo.Text = "BDC"
$Logo.Font = New-Object System.Drawing.Font("Segoe UI",28,[System.Drawing.FontStyle]::Bold)
$Logo.ForeColor = [System.Drawing.Color]::White
$Logo.AutoSize = $true
$Logo.Location = New-Object System.Drawing.Point(150,20)
$LoginForm.Controls.Add($Logo)

$Sub = New-Object System.Windows.Forms.Label
$Sub.Text = "BOYDONTCRY AUTHENTICATION"
$Sub.ForeColor = [System.Drawing.Color]::Silver
$Sub.AutoSize = $true
$Sub.Location = New-Object System.Drawing.Point(95,75)
$LoginForm.Controls.Add($Sub)

$KeyBox = New-Object System.Windows.Forms.TextBox
$KeyBox.Size = New-Object System.Drawing.Size(260,30)
$KeyBox.Location = New-Object System.Drawing.Point(70,110)
$KeyBox.BackColor = [System.Drawing.Color]::FromArgb(25,25,25)
$KeyBox.ForeColor = [System.Drawing.Color]::White
$KeyBox.BorderStyle = "FixedSingle"
$LoginForm.Controls.Add($KeyBox)

$LoginBtn = New-Object System.Windows.Forms.Button
$LoginBtn.Text = "LOGIN"
$LoginBtn.Size = New-Object System.Drawing.Size(260,35)
$LoginBtn.Location = New-Object System.Drawing.Point(70,155)
$LoginBtn.BackColor = [System.Drawing.Color]::White
$LoginBtn.ForeColor = [System.Drawing.Color]::Black
$LoginBtn.FlatStyle = "Flat"
$LoginForm.Controls.Add($LoginBtn)

$script:AuthSuccess = $false

$LoginBtn.Add_Click({

    try {

        $GitHubKey = (Invoke-RestMethod "https://raw.githubusercontent.com/thomasiimp16-tech/BDC-V1/main/key.txt").Trim()

        if ($KeyBox.Text.Trim() -eq $GitHubKey) {

            $script:AuthSuccess = $true
            $LoginForm.Close()

        } else {

            [System.Windows.Forms.MessageBox]::Show(
                "Invalid Key",
                "BDC",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )

        }

    } catch {

        [System.Windows.Forms.MessageBox]::Show(
            "Cannot connect to GitHub",
            "BDC",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )

    }

})

[void]$LoginForm.ShowDialog()

if (-not $script:AuthSuccess) {
    exit
}
            "Invalid Key!",
            "BDC Authentication",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        exit
    }
}
catch {
    [System.Windows.Forms.MessageBox]::Show(
        "Unable to verify key.",
        "BDC Authentication",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit
}
$WARN     = [System.Drawing.Color]::FromArgb(175,175,175)
$DARKRED  = [System.Drawing.Color]::FromArgb(105,105,105)
$GLOW     = [System.Drawing.Color]::FromArgb(70,255,255,255)
$GRAY2    = [System.Drawing.Color]::FromArgb(105,105,105)
$WHITE    = [System.Drawing.Color]::White
$WHITE2   = [System.Drawing.Color]::FromArgb(215,215,215)
$BLACK    = [System.Drawing.Color]::Black

$FontTitle = New-Object System.Drawing.Font("Segoe UI Semibold",18,[System.Drawing.FontStyle]::Bold)
$FontSub   = New-Object System.Drawing.Font("Consolas",7,[System.Drawing.FontStyle]::Bold)
$FontLog   = New-Object System.Drawing.Font("Consolas",7.4)
$FontMono  = New-Object System.Drawing.Font("Consolas",8.2,[System.Drawing.FontStyle]::Bold)
$FontBig   = New-Object System.Drawing.Font("Consolas",20,[System.Drawing.FontStyle]::Bold)

# ===================== STATE =====================
$script:progressValue = 0
$script:statusText = "READY BoyDontCry 2.0"
$script:isRunning = $false
$script:_drag = $false
$script:_dragStart = [System.Drawing.Point]::Empty

# ===================== STEP DEFINITIONS =====================
$stepDefs = @(
    @{ id=1; label="REG EDIT"  },
    @{ id=2; label="NETWORK"   },
    @{ id=3; label="OPTIMIZE"  },
    @{ id=4; label="BRYCE PRF" },
    @{ id=5; label="GPU"       },
    @{ id=6; label="CPU"       }
)
$stepState = @{}
foreach ($s in $stepDefs) { $stepState[$s.id] = "idle" }

# ===================== DRAW HELPERS =====================
function New-RoundedPath {
    param([int]$X,[int]$Y,[int]$W,[int]$H,[int]$R)
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $R * 2
    $p.AddArc($X,$Y,$d,$d,180,90)
    $p.AddArc(($X+$W-$d),$Y,$d,$d,270,90)
    $p.AddArc(($X+$W-$d),($Y+$H-$d),$d,$d,0,90)
    $p.AddArc($X,($Y+$H-$d),$d,$d,90,90)
    $p.CloseFigure()
    return $p
}
function Update-FormRegion {
    if (-not $form) { return }
    $p = New-RoundedPath 0 0 $form.ClientSize.Width $form.ClientSize.Height 18
    $form.Region = New-Object System.Drawing.Region($p)
    $p.Dispose()
}
function Update-Rail { $railPanel.Invalidate() }
function Set-StepActive {
    param([int]$active)
    foreach ($s in $stepDefs) {
        $sid = [int]$s.id
        if ($sid -eq [int]$active) { $stepState[$sid] = "active" }
        elseif ($sid -lt [int]$active) { $stepState[$sid] = "done" }
        else { $stepState[$s.id] = "idle" }
    }
    Update-Rail
    [System.Windows.Forms.Application]::DoEvents()
}

# ===================== MAIN FORM =====================
$form = New-Object System.Windows.Forms.Form
$form.Text = "BoyDontCry 2.0"
$form.Size = New-Object System.Drawing.Size(980,660)
$form.StartPosition = "CenterScreen"
$form.BackColor = $BG
$form.ForeColor = $TEXT
$form.FormBorderStyle = "None"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.ShowInTaskbar = $true
$form.Add_Load({ Update-FormRegion })
$form.Add_Resize({ Update-FormRegion })
$form.Add_MouseDown({ param($s,$e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:_drag=$true
        $script:_dragStart=$e.Location
    }
})
$form.Add_MouseMove({ param($s,$e)
    if ($script:_drag) {
        $form.Left += $e.X - $script:_dragStart.X
        $form.Top  += $e.Y - $script:_dragStart.Y
    }
})
$form.Add_MouseUp({ $script:_drag=$false })

$form.Add_Paint({
    $g=$_.Graphics
    $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $fw=[int]$form.ClientSize.Width
    $fh=[int]$form.ClientSize.Height

    # Outer futuristic frame
    for($i=0;$i -lt 3;$i++){
        $alpha=230-($i*65)
        $pen=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($alpha,245,245,245),(1+$i))
        $path=New-RoundedPath ($i+1) ($i+1) ($fw-2-($i*2)) ($fh-2-($i*2)) 18
        $g.DrawPath($pen,$path)
        $path.Dispose();$pen.Dispose()
    }

    # Header fill + angled right side
    $b=New-Object System.Drawing.SolidBrush($BG2)
    $g.FillRectangle($b,14,10,$fw-28,84);$b.Dispose()
    $hp=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(175,175,175),1)
    $g.DrawLine($hp,$fw-70,10,$fw-108,94)
    $g.DrawLine($hp,$fw-88,10,$fw-126,94)
    $g.DrawLine($hp,$fw-106,10,$fw-144,94)
    $hp.Dispose()

    # Bottom hatch
    $hpen=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(45,150,150,150),1)
    for($x=52;$x -lt $fw-52;$x+=14){
        $g.DrawLine($hpen,$x,$fh-27,$x+9,$fh-18)
    }
    $hpen.Dispose()

    # Bottom center bracket
    $poly=[System.Drawing.Point[]]@(
        (New-Object System.Drawing.Point([int]($fw/2-72),[int]($fh-18))),
        (New-Object System.Drawing.Point([int]($fw/2+72),[int]($fh-18))),
        (New-Object System.Drawing.Point([int]($fw/2+86),[int]($fh-2))),
        (New-Object System.Drawing.Point([int]($fw/2-86),[int]($fh-2)))
    )
    $bp=New-Object System.Drawing.Pen($ACCENT2,1)
    $g.DrawPolygon($bp,$poly);$bp.Dispose()
})

# ===================== HEADER =====================
$lblTitle=New-Object System.Windows.Forms.Label
$lblTitle.Text="BoyDontCry 2.0"
$lblTitle.Font=$FontTitle
$lblTitle.ForeColor=$ACCENT
$lblTitle.Location=New-Object System.Drawing.Point(28,14)
$lblTitle.AutoSize=$true
$form.Controls.Add($lblTitle)

$lblSub=New-Object System.Windows.Forms.Label
$lblSub.Text=">> PC OPTIMIZATION BoyDontCry 2.0"
$lblSub.Font=$FontSub
$lblSub.ForeColor=$ACCENT3
$lblSub.Location=New-Object System.Drawing.Point(30,54)
$lblSub.AutoSize=$true
$form.Controls.Add($lblSub)

$statusPanel=New-Object System.Windows.Forms.Panel
$statusPanel.Location=New-Object System.Drawing.Point(360,25)
$statusPanel.Size=New-Object System.Drawing.Size(82,28)
$statusPanel.BackColor=$BG2
$form.Controls.Add($statusPanel)
$statusPanel.Add_Paint({
    $g=$_.Graphics
    $p=[System.Drawing.Point[]]@(
        (New-Object System.Drawing.Point(8,0)),
        (New-Object System.Drawing.Point(82,0)),
        (New-Object System.Drawing.Point(74,28)),
        (New-Object System.Drawing.Point(0,28))
    )
    $pen=New-Object System.Drawing.Pen($ACCENT2,1)
    $g.DrawPolygon($pen,$p);$pen.Dispose()
})
$lblStatus=New-Object System.Windows.Forms.Label
$lblStatus.Text="● READY  BDC"
$lblStatus.Font=New-Object System.Drawing.Font("Consolas",6.8,[System.Drawing.FontStyle]::Bold)
$lblStatus.ForeColor=$ACCENT
$lblStatus.Location=New-Object System.Drawing.Point(13,8)
$lblStatus.AutoSize=$true
$statusPanel.Controls.Add($lblStatus)

$btnWinClose=New-Object System.Windows.Forms.Button
$btnWinClose.Text="X"
$btnWinClose.Location=New-Object System.Drawing.Point(944,13)
$btnWinClose.Size=New-Object System.Drawing.Size(22,20)
$btnWinClose.FlatStyle="Flat"
$btnWinClose.FlatAppearance.BorderSize=0
$btnWinClose.BackColor=[System.Drawing.Color]::Transparent
$btnWinClose.ForeColor=$TEXTDIM
$btnWinClose.Font=New-Object System.Drawing.Font("Segoe UI",8)
$btnWinClose.Cursor=[System.Windows.Forms.Cursors]::Hand
$btnWinClose.Add_Click({$form.Close()})
$form.Controls.Add($btnWinClose)

# ===================== STEP RAIL =====================
$railPanel=New-Object System.Windows.Forms.Panel
$railPanel.Location=New-Object System.Drawing.Point(14,92)
$railPanel.Size=New-Object System.Drawing.Size(65,418)
$railPanel.BackColor=$BG
$railPanel.BorderStyle=[System.Windows.Forms.BorderStyle]::None
$form.Controls.Add($railPanel)

$railPanel.Add_Paint({
    $g=$_.Graphics
    $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $cx=32

    # CLEAN RAIL: no rectangle/trapezoid/X overlay
    $line=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(175,175,175),1)
    $g.DrawLine($line,$cx,18,$cx,396)
    $line.Dispose()

    for($i=0;$i -lt 6;$i++){
        $id=$i+1
        $cy = [int](29 + ([int]$i * 67))
        $state=$stepState[$id]

        $fill=switch($state){
            "active" {[System.Drawing.Color]::FromArgb(28,28,28)}
            "done"   {[System.Drawing.Color]::FromArgb(58,58,58)}
            default  {[System.Drawing.Color]::FromArgb(2,2,2)}
        }
        $ring=switch($state){
            "active" {$WHITE}
            "done"   {$WHITE2}
            default  {[System.Drawing.Color]::FromArgb(205,205,205)}
        }

        $r=16
        $rx = [int]($cx - $r)
        $ry = [int]($cy - $r)
        $rw = [int]($r * 2)
        $rh = [int]($r * 2)
        $rect = New-Object System.Drawing.Rectangle($rx,$ry,$rw,$rh)
        $fb=New-Object System.Drawing.SolidBrush($fill)
        $g.FillEllipse($fb,$rect)
        $fb.Dispose()

        $rp=New-Object System.Drawing.Pen($ring,1.6)
        $g.DrawEllipse($rp,$rect)
        $rp.Dispose()

        $fmt=New-Object System.Drawing.StringFormat
        $fmt.Alignment="Center"
        $fmt.LineAlignment="Center"
        $tb=New-Object System.Drawing.SolidBrush($WHITE)
        $g.DrawString("$id",$FontMono,$tb,[System.Drawing.RectangleF]$rect,$fmt)
        $tb.Dispose()
        $fmt.Dispose()
    }
})

# ===================== STATS =====================
$statsPanel=New-Object System.Windows.Forms.Panel
$statsPanel.Location=New-Object System.Drawing.Point(74,91)
$statsPanel.Size=New-Object System.Drawing.Size(502,46)
$statsPanel.BackColor=$BG2
$form.Controls.Add($statsPanel)
$statsPanel.Add_Paint({
    $g=$_.Graphics
    $p=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(125,125,125),1)
    $g.DrawRectangle($p,0,0,$statsPanel.Width-1,$statsPanel.Height-1);$p.Dispose()
})
try{
    $osInfo=(Get-CimInstance Win32_OperatingSystem).Caption
    $cpuInfo=(Get-CimInstance Win32_Processor).Name
    $ramGB=[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1)
}catch{
    $osInfo="Windows";$cpuInfo="Unknown CPU";$ramGB="?"
}
$sInfoItems=@(@{key="OS";val=$osInfo},@{key="CPU";val=$cpuInfo},@{key="RAM";val="${ramGB} GB"})
$sX=12;$colWidths=@(170,220,72);$ci=0
foreach($si in $sInfoItems){
    $lk=New-Object System.Windows.Forms.Label
    $lk.Text=$si.key;$lk.Font=New-Object System.Drawing.Font("Consolas",6,[System.Drawing.FontStyle]::Bold);$lk.ForeColor=$ACCENT
    $lk.Location=New-Object System.Drawing.Point($sX,4);$lk.Size=New-Object System.Drawing.Size($colWidths[$ci],12)
    $statsPanel.Controls.Add($lk)
    $lv=New-Object System.Windows.Forms.Label
    $lv.Text=$si.val;$lv.Font=New-Object System.Drawing.Font("Consolas",6.1);$lv.ForeColor=$TEXTDIM
    $lv.Location=New-Object System.Drawing.Point($sX,18);$lv.Size=New-Object System.Drawing.Size($colWidths[$ci],20)
    $statsPanel.Controls.Add($lv)
    $sX += $colWidths[$ci]+4;$ci++
}

# ===================== LOG =====================
$logBg=New-Object System.Windows.Forms.Panel
$logBg.Location=New-Object System.Drawing.Point(74,145)
$logBg.Size=New-Object System.Drawing.Size(545,318)
$logBg.BackColor=$BG2
$form.Controls.Add($logBg)
$logBg.Add_Paint({
    $g=$_.Graphics
    $p=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(135,135,135),1)
    $g.DrawRectangle($p,0,0,$logBg.Width-1,$logBg.Height-1);$g.DrawLine($p,0,24,$logBg.Width,24);$p.Dispose()
})
$lblLogTitle=New-Object System.Windows.Forms.Label
$lblLogTitle.Text=">> BDC.exe"
$lblLogTitle.Font=New-Object System.Drawing.Font("Consolas",7,[System.Drawing.FontStyle]::Bold)
$lblLogTitle.ForeColor=$ACCENT
$lblLogTitle.Location=New-Object System.Drawing.Point(5,5);$lblLogTitle.AutoSize=$true
$logBg.Controls.Add($lblLogTitle)
$logBox=New-Object System.Windows.Forms.RichTextBox
$logBox.Location=New-Object System.Drawing.Point(6,28)
$logBox.Size=New-Object System.Drawing.Size(533,282)
$logBox.BackColor=$BLACK;$logBox.ForeColor=$ACCENT2;$logBox.Font=$FontLog;$logBox.ReadOnly=$true;$logBox.BorderStyle="None";$logBox.ScrollBars="Vertical"
$logBg.Controls.Add($logBox)
function Write-Log {
    param([string]$msg,[string]$type="info")
    try{
        $col=switch($type){
            "ok" {$ACCENT2};"warn" {$WARN};"err" {$WHITE};"dim" {[System.Drawing.Color]::FromArgb(100,100,100)};"hi" {$WHITE};"step" {[System.Drawing.Color]::FromArgb(225,225,225)};default {$ACCENT2}
        }
        $ts=(Get-Date).ToString("HH:mm:ss")
        $logBox.SelectionStart=$logBox.TextLength
        $logBox.SelectionColor=[System.Drawing.Color]::FromArgb(90,90,90)
        $logBox.AppendText("[$ts] ")
        $logBox.SelectionColor=$col
        $logBox.AppendText("$msg`n")
        $logBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }catch{}
}

# ===================== RIGHT CONTROL BAY =====================
$ringPanel=New-Object System.Windows.Forms.Panel
$ringPanel.Location=New-Object System.Drawing.Point(630,91)
$ringPanel.Size=New-Object System.Drawing.Size(338,272)
$ringPanel.BackColor=$BG2
$form.Controls.Add($ringPanel)
$ringPanel.Add_Paint({
    $g=$_.Graphics
    $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $w=$ringPanel.Width
    $h=$ringPanel.Height

    # Panel frame
    $p=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(125,125,125),1)
    $drawW = [int]($w - 1)
    $drawH = [int]($h - 1)
    $g.DrawRectangle($p,0,0,$drawW,$drawH)
    $p.Dispose()

    # Progress ring sized/positioned like the supplied reference image
    $ringSize=174
    $ringW = [int]$w
    $ringSizeInt = [int]$ringSize
    $ringX = [int](($ringW - $ringSizeInt) / 2)
    $ringY=16
    $rect = New-Object System.Drawing.Rectangle([int]$ringX,[int]$ringY,[int]$ringSizeInt,[int]$ringSizeInt)

    $bgPen=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(58,58,58),11)
    $g.DrawEllipse($bgPen,$rect)
    $bgPen.Dispose()

    $sweep=360*($script:progressValue/100)
    if($sweep -gt 0){
        $fg=New-Object System.Drawing.Pen($ACCENT2,11)
        $fg.StartCap=[System.Drawing.Drawing2D.LineCap]::Round
        $fg.EndCap=[System.Drawing.Drawing2D.LineCap]::Round
        $g.DrawArc($fg,$rect,-90,$sweep)
        $fg.Dispose()
    }

    $txt="$($script:progressValue)%"
    $tb=New-Object System.Drawing.SolidBrush($WHITE)
    $fmt=New-Object System.Drawing.StringFormat
    $fmt.Alignment="Center"
    $fmt.LineAlignment="Center"
    $g.DrawString($txt,$FontBig,$tb,[System.Drawing.RectangleF]$rect,$fmt)
    $tb.Dispose()
    $fmt.Dispose()

    $fmt2=New-Object System.Drawing.StringFormat
    $fmt2.Alignment="Center"
    $b2=New-Object System.Drawing.SolidBrush($ACCENT2)
    $progressX = [single]($w / 2)
    $progressY = [single]($h - 22)
    $g.DrawString("PROGRESS",$FontMono,$b2,$progressX,$progressY,$fmt2)
    $b2.Dispose()
    $fmt2.Dispose()
})
$lblTask=New-Object System.Windows.Forms.Label
$lblTask.Text="Waiting to start...";$lblTask.Font=New-Object System.Drawing.Font("Consolas",6.4);$lblTask.ForeColor=$TEXTDIM
$lblTask.Location=New-Object System.Drawing.Point(632,368);$lblTask.Size=New-Object System.Drawing.Size(334,16);$lblTask.TextAlign="MiddleCenter"
$form.Controls.Add($lblTask)
function Set-Progress { param([int]$val,[string]$task="")
    $script:progressValue=[Math]::Max(0,[Math]::Min($val,100));$ringPanel.Invalidate();if($task){$lblTask.Text=$task};[System.Windows.Forms.Application]::DoEvents()
}

# ===================== RUN =====================
$btnRunPanel=New-Object System.Windows.Forms.Panel
$btnRunPanel.Location=New-Object System.Drawing.Point(630,392);$btnRunPanel.Size=New-Object System.Drawing.Size(338,62);$btnRunPanel.BackColor=[System.Drawing.Color]::Transparent;$btnRunPanel.Cursor=[System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnRunPanel)
$btnRunPanel.Add_Paint({
    $g=$_.Graphics;$g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias;$w=$btnRunPanel.Width;$h=$btnRunPanel.Height
    $runRight = [int]$w
    $runRightInset = [int]($w - 16)
    $runPts=[System.Drawing.Point[]]@(
        (New-Object System.Drawing.Point(16,0)),
        (New-Object System.Drawing.Point($runRight,0)),
        (New-Object System.Drawing.Point($runRightInset,[int]$h)),
        (New-Object System.Drawing.Point(0,[int]$h))
    )
    $pts = $runPts
    $fill=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(7,7,7));$g.FillPolygon($fill,$pts);$fill.Dispose()
    $pen=New-Object System.Drawing.Pen($WHITE2,1.2);$g.DrawPolygon($pen,$pts);$pen.Dispose()
})
$lblRun=New-Object System.Windows.Forms.Label
$lblRun.Text="▶ RUN BoyDontCry 2.0";$lblRun.Font=New-Object System.Drawing.Font("Segoe UI Semibold",9.5,[System.Drawing.FontStyle]::Bold);$lblRun.ForeColor=$WHITE
$lblRun.Location=New-Object System.Drawing.Point(0,20);$lblRun.Size=New-Object System.Drawing.Size(338,24);$lblRun.TextAlign="MiddleCenter";$lblRun.Cursor=[System.Windows.Forms.Cursors]::Hand
$btnRunPanel.Controls.Add($lblRun)

# ===================== CLEAR / EXIT =====================
function New-MiniButton {
    param($txt,$x,$y,$w,$h)
    $b=New-Object System.Windows.Forms.Button;$b.Text=$txt;$b.Location=New-Object System.Drawing.Point($x,$y);$b.Size=New-Object System.Drawing.Size($w,$h)
    $b.FlatStyle="Flat";$b.FlatAppearance.BorderColor=$WHITE2;$b.FlatAppearance.BorderSize=1;$b.BackColor=$BLACK;$b.ForeColor=$WHITE2
    $b.Font=New-Object System.Drawing.Font("Consolas",6.8,[System.Drawing.FontStyle]::Bold);$b.Cursor=[System.Windows.Forms.Cursors]::Hand
    return $b
}
$btnClear=New-MiniButton "CLEAR" 630 464 164 29
$btnExit=New-MiniButton "EXIT" 804 464 164 29
$form.Controls.Add($btnClear);$form.Controls.Add($btnExit)

# ===================== FOOTER EDIT / SHARE =====================
$lblEdit=New-Object System.Windows.Forms.Label
$lblEdit.Text="Edit";$lblEdit.Font=New-Object System.Drawing.Font("Segoe UI Semibold",10,[System.Drawing.FontStyle]::Bold);$lblEdit.ForeColor=$ACCENT
$lblEdit.Location=New-Object System.Drawing.Point(40,586);$lblEdit.AutoSize=$true
$form.Controls.Add($lblEdit)
$share=New-Object System.Windows.Forms.Button
$share.Text="↥";$share.Font=New-Object System.Drawing.Font("Segoe UI Symbol",12);$share.FlatStyle="Flat";$share.FlatAppearance.BorderSize=0;$share.BackColor=[System.Drawing.Color]::Transparent;$share.ForeColor=$ACCENT2
$share.Location=New-Object System.Drawing.Point(935,584);$share.Size=New-Object System.Drawing.Size(30,26)
$form.Controls.Add($share)

$btnExit.Add_Click({$form.Close()})
$btnWinClose.Add_Click({$form.Close()})
$btnClear.Add_Click({
    $logBox.Clear();Set-Progress 0 "Waiting to start...";$lblStatus.Text="● READY  BDC";$lblStatus.ForeColor=$ACCENT;$script:isRunning=$false
    foreach($s in $stepDefs){$stepState[$s.id]="idle"};Update-Rail
})

# The optimization backend begins below.  It keeps the original stage logic.

# ===================== STAGE DESCRIPTIONS =====================
$stageInfo = @{
    1 = @{
        title = "Registry Editor"
        logs  = @(
            "Scanning registry hives...",
            "Applying performance keys to HKLM\\SYSTEM...",
            "Disabling unnecessary startup entries...",
            "Setting priority separation for foreground apps...",
            "Patching visual effects registry values...",
            "Disabling telemetry registry keys...",
            "Registry Editor complete."
        )
    }
    2 = @{
        title = "Network Optimization"
        logs  = @(
            "Detecting active network adapters...",
            "Applying TCP global settings (27 commands)...",
            "Disabling Nagle algorithm — ACK immediate...",
            "Setting NetworkThrottlingIndex = disabled...",
            "Configuring interface registry parameters...",
            "Setting MTU to 1500, MaxUserPort to 65534...",
            "Network optimization complete."
        )
    }
    3 = @{
        title = "Computer Optimizer"
        logs  = @(
            "Clearing temporary files and cache...",
            "Disabling SysMain (Superfetch) service...",
            "Disabling Windows Search indexing...",
            "Setting power plan to High Performance...",
            "Flushing DNS cache...",
            "Disabling background app refresh...",
            "Computer optimizer complete."
        )
    }
    4 = @{
        title = "Bryce Profile Setup"
        logs  = @(
            "Loading Bryce performance profile...",
            "Applying multimedia game scheduling profile...",
            "Setting GPU priority = 8, CPU priority = 6...",
            "Patching clock rate to 10000 for low latency...",
            "Configuring SFIO priority to High...",
            "Setting scheduling category to High...",
            "Bryce Profile Setup complete."
        )
    }
    5 = @{
        title = "GPU Optimization"
        logs  = @(
            "Detecting GPU hardware...",
            "Disabling Game DVR and Game Bar...",
            "Enabling hardware-accelerated GPU scheduling...",
            "Setting NVIDIA/AMD power mode to Maximum Performance...",
            "Disabling shader cache precompilation delay...",
            "Applying PCIe registry performance flags...",
            "GPU optimization complete."
        )
    }
    6 = @{
        title = "CPU Optimization"
        logs  = @(
            "Detecting CPU cores and topology...",
            "Disabling dynamic tick (bcdedit)...",
            "Setting IRQ affinity hints...",
            "Unlocking CPU responsiveness attributes...",
            "Setting process priority for 25 game titles...",
            "Applying Win32PrioritySeparation = 42...",
            "CPU optimization complete."
        )
    }
}

# ===================== RUN =====================
$script:isRunning = $false

$script:isRunning = $false

$runClick = {
    if ($script:isRunning) { return }
    $script:isRunning = $true
    try {

    $lblStatus.Text      = "RUNNING"
    $lblStatus.ForeColor = $WARN
    foreach ($s in $stepDefs) { $stepState[$s.id] = "idle" }
    Update-Rail

    Write-Log "============================================" "dim"
    Write-Log "  BoyDontCry 2.0  -  PC Optimizer" "step"
    Write-Log "============================================" "dim"
    Write-Log "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "hi"
    Write-Log "OS:  $osInfo" "dim"
    Write-Log "CPU: $cpuInfo" "dim"
    Write-Log "RAM: $ramGB GB" "dim"
    Write-Log "" "dim"

    # ---- STAGE 1: Registry ----
    Set-StepActive 1
    Write-Log "--------------------------------------------" "dim"
    Write-Log "STAGE 1  >  Registry Editor" "step"
    $regEntries = @(
        @{ Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name="SystemResponsiveness";        Val=0x00000000 },
        @{ Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name="NetworkThrottlingIndex";       Val=4294967295 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="TcpNoDelay";      Val=0x00000001 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="TCPAckFrequency"; Val=0x00000001 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="TCPDelAckTicks";  Val=0x00000000 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="DefaultTTL";      Val=0x00000040 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="ConvertibleSlateMode";        Val=0x00000000 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="Win32PrioritySeparation";     Val=0x00000042 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="IRQ8Priority";                Val=0x00000001 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="AVX2PriorityBoost";           Val=0x00000001 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="GameScheduling";              Val=0x00000001 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="IsClientAlwaysFirstResponse"; Val=0x00000001 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="KernelChannelThreadPriority"; Val=0x00000002 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="KernelResponseTime";          Val=0x00000001 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="MouseResponse";               Val=0x00000001 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="SchedulerDisable";            Val=0x00000000 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="SystemLatency";               Val=0x00000000 },
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="Win32TimeSlice";              Val=0x00000001 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\USB"; Name="DisableSelectiveSuspend";              Val=0x00000001 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="ContextSwitchDeadband";              Val=0x00000001 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"; Name="DisableSmartNameResolution";              Val=0x00000001 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\NDIS\Parameters"; Name="DefaultPnPCapabilities";              Val=0x00000024 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="LatencySensitivityHint";              Val=0x00000001 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel"; Name="GlobalTimerResolutionRequests";              Val=0x00000001 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"; Name="PowerThrottlingOff";              Val=0x00000001 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\USB"; Name="DisableSelectiveSuspend";              Val=0x00000001 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name="IgnorePushBitOnReceives";              Val=0x00000001 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name="DoNotHoldOutstandingRequests";              Val=0x00000001 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name="MaximumSendsPerTransmit";              Val=0x00000016 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name="DisableChainedReceive";              Val=0x00000001 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name="PriorityBoost";              Val=0x00000002 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name="TransmitWorker";              Val=0x00000032 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name="DynamicSendBufferDisable";              Val=0x00000001 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name="DefaultSendWindow";              Val=0x00065535 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name="DefaultReceiveWindow";              Val=0x00065535 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name="FastCopyReceiveThreshold";              Val=0x00016384 }
        @{ Path="HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"; Name="FastSendDatagramThreshold";              Val=0x00016384 }
    )
    $li = 0; $tot = $regEntries.Count
    foreach ($r in $regEntries) {
        $li++
        try {
            if (-not (Test-Path $r.Path)) { New-Item -Path $r.Path -Force | Out-Null }
            Set-ItemProperty -Path $r.Path -Name $r.Name -Value $r.Val -Type DWord -Force -EA SilentlyContinue
            Write-Log "  SET $($r.Name) = $($r.Val)" "ok"
        } catch { Write-Log "  SKIP $($r.Name)" "warn" }
        Set-Progress ([int](($li / $tot) / 6 * 100)) "Registry: $($r.Name)"
        Start-Sleep -Milliseconds 80
    }
    Write-Log "STAGE 1 DONE" "hi"; Write-Log "" "dim"

    # ---- STAGE 2: Network ----
    Set-StepActive 2
    Write-Log "--------------------------------------------" "dim"
    Write-Log "STAGE 2  >  Network Optimization" "step"

    # Backup
    $BK = "$env:SystemDrive\NIC_CORE_ONLY_BACKUP"
    New-Item -ItemType Directory -Path $BK -Force | Out-Null
    reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "$BK\Tcpip_Parameters.reg" /y 2>&1 | Out-Null
    reg export "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" "$BK\NIC_Class.reg" /y 2>&1 | Out-Null
    Write-Log "  Backup saved to $BK" "dim"
    Set-Progress 18 "Network: Backup done"

    # Tcpip Parameters
    function RegAdd($p,$n,$v){ reg add "$p" /v "$n" /t REG_DWORD /d "$v" /f 2>&1 | Out-Null }
    RegAdd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpAckFrequency" 1
    RegAdd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TCPNoDelay" 1
    RegAdd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpDelAckTicks" 0
    RegAdd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "DefaultTTL" 64
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "EnablePMTUDiscovery" 1
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "EnableTCPA" 0
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "EnableRSS" 1
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "DisableTaskOffload" 0
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "Tcp1323Opts" 0
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpTimedWaitDelay" 30
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "MaxUserPort" 65534
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpMaxDataRetransmissions" 3
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" "TcpAckFrequency" 1
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" "TCPNoDelay" 1
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "LocalPriority" 1
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "HostsPriority" 1
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "NetbtPriority" 1
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" "DnsPriority" 1
    Regadd "HKLM\SYSTEM\CurrentControlSet\services\NDIS\Parameters" "TrackNblOwner" 0
    Regadd "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" "EnableLMHOSTS" 0
    Write-Log "  Tcpip\Parameters keys set" "ok"
    Set-Progress 20 "Network: Tcpip Parameters"

    # Per-interface TCP values
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -EA SilentlyContinue | ForEach-Object {
        New-ItemProperty -Path $_.PSPath -Name TcpAckFrequency -PropertyType DWord -Value 1 -Force -EA SilentlyContinue | Out-Null
        New-ItemProperty -Path $_.PSPath -Name TCPNoDelay      -PropertyType DWord -Value 1 -Force -EA SilentlyContinue | Out-Null
        New-ItemProperty -Path $_.PSPath -Name TcpDelAckTicks  -PropertyType DWord -Value 0 -Force -EA SilentlyContinue | Out-Null
    }
    Write-Log "  Per-interface TCP values set" "ok"
    Set-Progress 22 "Network: Interface TCP values"

    # netsh
    $netCmds = @(
        "netsh int tcp set heuristics disabled",
        "netsh int tcp set global rss=enabled",
        "netsh int tcp set global rsc=disabled",
        "netsh int tcp set global chimney=disabled",
        "netsh int tcp set global ecncapability=disabled",
        "netsh int tcp set global timestamps=disabled",
        "netsh int tcp set global autotuninglevel=normal",
        "netsh int tcp set global nonsackrttresiliency=disabled",
        "netsh int tcp set global initialRto=2000",
        "netsh int tcp set global maxsynretransmissions=2",
        "netsh int ip set global taskoffload=enabled",
        "netsh int ipv4 set global defaultcurhoplimit=64",
        "netsh int ipv6 set global defaultcurhoplimit=64",
        "netsh int tcp set supplemental template=internet congestionprovider=ctcp"
        "netsh int isatap set state disable"
        "netsh interface teredo set state servername=default"
        "netsh int ip set global sourceroutingbehavior=drop"
        "netsh int ip set global neighborcachelimit=4096"
        "netsh int tcp set security mpp=disabled"
        "netsh int tcp set security profiles=disabled"
    )
    $li = 0; $tot = $netCmds.Count
    foreach ($cmd in $netCmds) {
        $li++
        try { Invoke-Expression "$cmd 2>&1" | Out-Null } catch {}
        Write-Log "  $cmd" "ok"
        Set-Progress ([int](22 + ($li/$tot) * 8)) "Network: $cmd"
        Start-Sleep -Milliseconds 60
    }
    ipconfig /flushdns 2>&1 | Out-Null
    Write-Log "  DNS flushed" "ok"

    # Global offload settings
    try {
        Set-NetOffloadGlobalSetting -ReceiveSideScaling Enabled -ReceiveSegmentCoalescing Disabled -Chimney Disabled -TaskOffload Enabled -NetworkDirect Disabled -PacketCoalescingFilter Disabled -EA SilentlyContinue | Out-Null
        Write-Log "  NetOffloadGlobalSetting applied" "ok"
    } catch {}
    Set-Progress 31 "Network: Offload settings"

    # NIC helper function
    function Set-NICProp {
        param($Name,[string[]]$Patterns,[string[]]$RegVals=@(),[string[]]$DispVals=@())
        $props = Get-NetAdapterAdvancedProperty -Name $Name -EA SilentlyContinue | Where-Object {
            $hit=$false
            foreach($x in $Patterns){ if($_.DisplayName -like $x -or $_.RegistryKeyword -like $x){$hit=$true} }
            $hit
        }
        foreach($p in $props){
            $done=$false
            foreach($v in $DispVals){
                try{ Set-NetAdapterAdvancedProperty -Name $Name -RegistryKeyword $p.RegistryKeyword -DisplayValue $v -NoRestart -EA Stop | Out-Null; $done=$true; break }catch{}
            }
            if(!$done){ foreach($v in $RegVals){ try{ Set-NetAdapterAdvancedProperty -Name $Name -RegistryKeyword $p.RegistryKeyword -RegistryValue $v -NoRestart -EA Stop | Out-Null; break }catch{} } }
        }
    }

    # Find adapters
    $adapters = Get-NetAdapter -Physical -EA SilentlyContinue | Where-Object { $_.Status -ne "Disabled" -and ($_.InterfaceDescription -match "Realtek|2\.5|GbE|Ethernet") }
    if (!$adapters) { $adapters = Get-NetAdapter -Physical -EA SilentlyContinue | Where-Object { $_.Status -eq "Up" } }
    Write-Log "  Found $(@($adapters).Count) adapter(s)" "ok"

    $ai = 0
    foreach ($a in $adapters) {
        $ai++
        $n = $a.Name
        Write-Log "  Configuring: $n" "step"
        Set-Progress ([int](31 + ($ai / [Math]::Max(1,@($adapters).Count)) * 16)) "NIC: $n"

        try { Enable-NetAdapterRss -Name $n -EA SilentlyContinue | Out-Null } catch {}
        try { Set-NetAdapterRss -Name $n -Enabled $true -NumberOfReceiveQueues 4 -Profile NUMA -BaseProcessorNumber 2 -MaxProcessorNumber 5 -MaxProcessors 4 -EA SilentlyContinue | Out-Null } catch {}
        try { Disable-NetAdapterRsc -Name $n -EA SilentlyContinue | Out-Null } catch {}
        try { Disable-NetAdapterPowerManagement -Name $n -EA SilentlyContinue | Out-Null } catch {}
        try { Set-NetIPInterface -InterfaceAlias $n -NlMtuBytes 1500 -EA SilentlyContinue | Out-Null } catch {}
        try { Set-NetIPInterface -InterfaceAlias $n -AutomaticMetric Disabled -InterfaceMetric 1 -EA SilentlyContinue | Out-Null } catch {}

        Set-NICProp $n @("*Receive Side Scaling*","*RSS*") @("1") @("Enabled")
        Set-NICProp $n @("*Maximum Number of RSS Queues*","*RSS Queues*","NumRssQueues","NumberOfReceiveQueues") @("4") @("4 Queues","4 Queue","4")
        Set-NICProp $n @("*Receive Buffers*","ReceiveBuffers") @("1024")
        Set-NICProp $n @("*Transmit Buffers*","TransmitBuffers") @("1024")
        Set-NICProp $n @("*Flow Control*","FlowControl") @("0") @("Disabled")
        Set-NICProp $n @("*Interrupt Moderation*","InterruptModeration") @("0") @("Disabled")
        Set-NICProp $n @("*Interrupt Moderation Rate*","InterruptModerationRate","ITR") @("0") @("Off","Disabled")
        Set-NICProp $n @("TxIntDelay") @("0")
        Set-NICProp $n @("DMACoalescing") @("0")
        Set-NICProp $n @("*Packet Coalescing*","PacketCoalescing","Coalesce") @("0") @("Disabled")
        Set-NICProp $n @("CoalesceBufferSize") @("0")
        Set-NICProp $n @("UdpTxScaling") @("0") @("Disabled")
        Set-NICProp $n @("*IPv4 Checksum Offload*","IPChecksumOffloadIPv4") @("3") @("Rx & Tx Enabled")
        Set-NICProp $n @("*TCP Checksum Offload*IPv4*","TCPChecksumOffloadIPv4") @("3") @("Rx & Tx Enabled")
        Set-NICProp $n @("*UDP Checksum Offload*IPv4*","UDPChecksumOffloadIPv4") @("3") @("Rx & Tx Enabled")
        Set-NICProp $n @("*TCP Checksum Offload*IPv6*","TCPChecksumOffloadIPv6") @("3") @("Rx & Tx Enabled")
        Set-NICProp $n @("*UDP Checksum Offload*IPv6*","UDPChecksumOffloadIPv6") @("3") @("Rx & Tx Enabled")
        Set-NICProp $n @("*Large Send Offload*IPv4*","LsoV1IPv4","LsoV2IPv4") @("0") @("Disabled")
        Set-NICProp $n @("*Large Send Offload*IPv6*","LsoV2IPv6") @("0") @("Disabled")
        Set-NICProp $n @("*ARP Offload*","PMARPOffload") @("0") @("Disabled")
        Set-NICProp $n @("*NS Offload*","PMNSOffload") @("0") @("Disabled")
        Set-NICProp $n @("*Energy Efficient Ethernet*","EEE","AdvancedEEE","EeePhyEnable") @("0") @("Disabled")
        Set-NICProp $n @("*Green Ethernet*","EnableGreenEthernet") @("0") @("Disabled")
        Set-NICProp $n @("*Gigabit Lite*","GigabitLite") @("0") @("Disabled")
        Set-NICProp $n @("*Power Saving*","AutoPowerSaveModeEnabled","ReduceSpeedOnPowerDown","PowerDownPll") @("0") @("Disabled")
        Set-NICProp $n @("*Wake On Magic Packet*","WakeOnMagicPacket") @("0") @("Disabled")
        Set-NICProp $n @("*Wake On Pattern*","WakeOnPattern") @("0") @("Disabled")
        Set-NICProp $n @("*Jumbo Frame*","*Jumbo Packet*","JumboPacket") @("1514","0") @("Disabled")
        Set-NICProp $n @("*Priority*VLAN*","PriorityVLANTag") @("0") @("Disabled")

        Write-Log "  $n configured" "ok"
    }
    Write-Log "STAGE 2 DONE" "hi"; Write-Log "" "dim"

    # ---- STAGE 3: GPU + CPU Priority ----
    Set-StepActive 3
    Write-Log "--------------------------------------------" "dim"
    Write-Log "STAGE 3  >  GPU & CPU Priority" "step"

    $gamePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    if (-not (Test-Path $gamePath)) { New-Item -Path $gamePath -Force | Out-Null }

    $gameVals = [ordered]@{
        "GPU Priority"          = @{ Val=8;       Type="DWord"  }
        "Priority"              = @{ Val=6;       Type="DWord"  }
        "Affinity"              = @{ Val=0;       Type="DWord"  }
        "Clock Rate"            = @{ Val=10000;   Type="DWord"  }
        "Background Only"       = @{ Val="False"; Type="String" }
        "Scheduling Category"   = @{ Val="High";  Type="String" }
        "SFIO Priority"         = @{ Val="High";  Type="String" }
    }

    $li = 0; $tot = $gameVals.Count
    foreach ($kv in $gameVals.GetEnumerator()) {
        $li++
        try {
            Set-ItemProperty -Path $gamePath -Name $kv.Key -Value $kv.Value.Val -Type $kv.Value.Type -Force -EA SilentlyContinue
            Write-Log "  SET `"$($kv.Key)`" = $($kv.Value.Val)" "ok"
        } catch { Write-Log "  SKIP $($kv.Key)" "warn" }
        Set-Progress ([int](50 + ($li/$tot) * 8)) "Priority: $($kv.Key)"
        Start-Sleep -Milliseconds 80
    }
    Write-Log "STAGE 3 DONE" "hi"; Write-Log "" "dim"

    # ---- STAGE 4: Mouse / Keyboard / Input Delay ----
    Set-StepActive 4
    Write-Log "--------------------------------------------" "dim"
    Write-Log "STAGE 4  >  Mouse / Keyboard / Input Delay" "step"

    # ปิด Mouse Acceleration
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed"      -Value "0"  -Type String -Force -EA SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0"  -Type String -Force -EA SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0"  -Type String -Force -EA SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSensitivity" -Value "10"  -Type String -Force -EA SilentlyContinue
    Write-Log "  Mouse Acceleration disabled" "ok"
    Set-Progress 62 "Input: Mouse acceleration off"

    # Keyboard ตอบสนองเร็วสุด
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31" -Type String -Force -EA SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "0"  -Type String -Force -EA SilentlyContinue
    Write-Log "  Keyboard speed max, delay min" "ok"
    Set-Progress 64 "Input: Keyboard response tuned"

    # Mouse/Keyboard Queue Size (ลด input buffer lag)
    $mousePath = "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters"
    $kbdPath   = "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters"
    if (-not (Test-Path $mousePath)) { New-Item -Path $mousePath -Force | Out-Null }
    if (-not (Test-Path $kbdPath))   { New-Item -Path $kbdPath   -Force | Out-Null }
    Set-ItemProperty -Path $mousePath -Name "MouseDataQueueSize"    -Value 0x64 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty -Path $kbdPath   -Name "KeyboardDataQueueSize" -Value 0x64 -Type DWord -Force -EA SilentlyContinue
    Write-Log "  Mouse/Keyboard queue size = 100" "ok"
    Set-Progress 66 "Input: Queue size set"

    # ปิด Dynamic Tick (ลด timer latency / input lag จริง)
    try { bcdedit /set disabledynamictick yes 2>&1 | Out-Null;   Write-Log "  DynamicTick disabled" "ok" } catch {}
    try { bcdedit /set useplatformclock false 2>&1 | Out-Null;   Write-Log "  PlatformClock disabled" "ok" } catch {}
    try { bcdedit /deletevalue useplatformhpet 2>&1 | Out-Null;  Write-Log "  HPET cleared" "ok" } catch {}
    Set-Progress 68 "Input: Timer latency reduced"

    # MMCSS service (Multimedia Class Scheduler - ช่วย input thread priority)
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\MMCSS" -Name "Start" -Value 2 -Type DWord -Force -EA SilentlyContinue
    Write-Log "  MMCSS set to Auto start" "ok"
    Write-Log "STAGE 4 DONE" "hi"; Write-Log "" "dim"

    # ---- STAGE 5: ลด Background Load ----
    Set-StepActive 5
    Write-Log "--------------------------------------------" "dim"
    Write-Log "STAGE 5  >  Background Load Reduction" "step"
    Set-Progress 70 "Background: Disabling services..."

    $svcs = @(
        @{ name="SysMain";         reason="Superfetch - wastes RAM/IO" },
        @{ name="DiagTrack";       reason="Telemetry" },
        @{ name="WSearch";         reason="Search Indexing - high disk IO" },
        @{ name="XboxGipSvc";      reason="Xbox Game Input - unneeded" },
        @{ name="XblAuthManager";  reason="Xbox Live Auth" },
        @{ name="XblGameSave";     reason="Xbox Game Save" },
        @{ name="XboxNetApiSvc";   reason="Xbox Network" },
        @{ name="WMPNetworkSvc";   reason="Windows Media Player Network" },
        @{ name="RemoteRegistry";  reason="Remote Registry" },
        @{ name="Fax";             reason="Fax service" }
    )
    $li = 0; $tot = $svcs.Count
    foreach ($svc in $svcs) {
        $li++
        Stop-Service  -Name $svc.name -Force -EA SilentlyContinue
        Set-Service   -Name $svc.name -StartupType Disabled -EA SilentlyContinue
        Write-Log "  DISABLED $($svc.name) — $($svc.reason)" "ok"
        Set-Progress ([int](70 + ($li/$tot) * 10)) "Service: $($svc.name)"
        Start-Sleep -Milliseconds 100
    }

    # ปิด background apps (UWP)
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force -EA SilentlyContinue
    Write-Log "  Background UWP apps disabled" "ok"

    # ปิด Game Bar / DVR
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore"                               -Name "GameDVR_Enabled"     -Value 0 -Type DWord -Force -EA SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled"   -Value 0 -Type DWord -Force -EA SilentlyContinue
    if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR")) { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Force | Out-Null }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"       -Name "AllowGameDVR"        -Value 0 -Type DWord -Force -EA SilentlyContinue
    Write-Log "  Game Bar / DVR disabled" "ok"
    Set-Progress 82 "Background: Game DVR off"

    Write-Log "STAGE 5 DONE" "hi"; Write-Log "" "dim"

    # ---- STAGE 6: Process Priority ----
    Set-StepActive 6
    Write-Log "--------------------------------------------" "dim"
    Write-Log "STAGE 6  >  Process & Priority" "step"
    Set-Progress 84 "Priority: Setting process rules..."

    # High Performance power plan
    try { powercfg -setactive SCHEME_MIN 2>&1 | Out-Null; Write-Log "  Power plan: High Performance" "ok" } catch {}

    # Win32PrioritySeparation — foreground boost สูงสุด (ค่านี้ซ้ำ stage 1 แต่ยืนยันอีกรอบ)
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 0x2a -Type DWord -Force -EA SilentlyContinue
    Write-Log "  Win32PrioritySeparation = 0x2a confirmed" "ok"

    # ตั้ง Image File Execution Options — CPU+IO priority สูงสำหรับเกมหลัก
    $gameExes = @(
        "FiveM_GTAProcess.exe","FiveM_b2944_GTAProcess.exe","FiveM_b3095_GTAProcess.exe",
        "VALORANT-Win64-Shipping.exe","cs2.exe","csgo.exe",
        "RainbowSix.exe","r5apex.exe","EscapeFromTarkov.exe",
        "Rust.exe","FortniteClient-Win64-Shipping.exe",
        "GenshinImpact.exe","ZZZ.exe","Overwatch.exe"
    )
    $li = 0; $tot = $gameExes.Count
    foreach ($exe in $gameExes) {
        $li++
        $ifoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exe\PerfOptions"
        if (-not (Test-Path $ifoPath)) { New-Item -Path $ifoPath -Force -EA SilentlyContinue | Out-Null }
        Set-ItemProperty -Path $ifoPath -Name "CpuPriorityClass" -Value 3 -Type DWord -Force -EA SilentlyContinue  # High
        Set-ItemProperty -Path $ifoPath -Name "IoPriority"       -Value 3 -Type DWord -Force -EA SilentlyContinue  # High
        Set-ItemProperty -Path $ifoPath -Name "PagePriority"     -Value 5 -Type DWord -Force -EA SilentlyContinue  # Normal
        Write-Log "  [$li/$tot] $exe — CPU/IO High" "ok"
        Set-Progress ([int](84 + ($li/$tot) * 14)) "Priority: $exe"
        Start-Sleep -Milliseconds 60
    }
    Write-Log "STAGE 6 DONE" "hi"; Write-Log "" "dim"

    # ---- DONE ----
    foreach ($s in $stepDefs) { $stepState[$s.id] = "done" }
    Update-Rail
    Set-Progress 100 "All stages complete."
    Write-Log "============================================" "dim"
    Write-Log "          ALL STAGES COMPLETE" "ok"
    Write-Log "  Registry / Network / Optimizer" "dim"
    Write-Log "  Bryce Profile / GPU / CPU" "dim"
    Write-Log "============================================" "dim"
    Write-Log "Restart recommended for all changes to take effect." "warn"
    $lblStatus.Text      = "COMPLETE"
    $lblStatus.ForeColor = $ACCENT
    $script:isRunning    = $false

# เปิด Discord หลังรันเสร็จ
Start-Sleep -Seconds 2
try {
    Start-Process "https://discord.gg/JVTgXNR2SG"
    Write-Log "Opening Discord invite..." "hi"
}
catch {
    Write-Log "Failed to open Discord invite." "err"
}
    }
    catch {
        Write-Log ("FATAL: " + $_.Exception.Message) "err"
        $lblStatus.Text = "ERROR"
        $lblStatus.ForeColor = $ACCENT
        $script:isRunning = $false
    }
}

$btnRunPanel.Add_Click($runClick)
$lblRun.Add_Click($runClick)


$btnClear.Add_Click({
    $logBox.Clear()
    Set-Progress 0 "Waiting to start..."
    $lblStatus.Text      = "● READY"
    $lblStatus.ForeColor = $ACCENT
    $script:isRunning    = $false
    foreach ($s in $stepDefs) { $stepState[$s.id] = "idle" }
    Update-Rail
})

$btnExit.Add_Click({ $form.Close() })
$btnWinClose.Add_Click({ $form.Close() })

# ===================== INIT LOG =====================
Write-Log "BoyDontCry 2.0 " "hi"
Write-Log "OS:  $osInfo" "dim"
Write-Log "CPU: $cpuInfo" "dim"
Write-Log "RAM: $ramGB GB" "dim"
Write-Log "" "dim"
Write-Log "Stages loaded:" "step"
Write-Log "  [1] Registry Editor        — performance registry keys" "ok"
Write-Log "  [2] Network Optimization   — TCP/IP, Nagle, ACK" "ok"
Write-Log "  [3] Computer Optimizer     — temp, services, power" "ok"
Write-Log "  [4] Bryce Profile Setup    — multimedia game profile" "ok"
Write-Log "  [5] GPU Optimization       — HAGS, DVR, PCIe flags" "ok"
Write-Log "  [6] CPU Optimization       — IRQ, affinity, priority" "ok"
Write-Log "" "dim"
Write-Log "Press [ RUN BoyDontCry 2.0 ] to begin." "hi"

[void][System.Windows.Forms.Application]::Run($form)