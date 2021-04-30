#Robert Olson

#automatically manages virtual environments upon entering/exiting a folder

if (Get-Module -ListAvailable -Name ps-autoenv) {
  import-module ps-autoenv
}
else {
  Install-Module ps-autoenv
}


# powershell equivalent of touch
function touch {
  Param(
    [Parameter(Mandatory=$true)]
    [string]$Path
  )

  if (Test-Path -LiteralPath $Path) {
    (Get-Item -Path $Path).LastWriteTime = Get-Date
  } else {
    New-Item -Type File -Path $Path
  }
}

# Allows you to use Bash commands without wsl
# Import-WslCommand "apt", "awk", "emacs", "grep", "head", "less", "ls", "man", "sed", "seq", "ssh", "sudo", "tail", "vim", "touch"

# make a bash-like alias for environment variables
# (use yellow text to indicate it's not builtin)
# Function env { Get-Item Env: }
Function env {
  $my_env = Get-Item Env:
  $my_env = $my_env | Out-String
  Write-Host "$my_env" -BackgroundColor Black -ForegroundColor Yellow
}

#open new terminals at project
$project = $env:project
$desktop = $env:desktop
$downloads = $env:downloads
$programming = $env:programming

#Changes Powershell Prompt to display CWD at limited depth
#And automatically supply list of folders
function prompt {

  # Check Exit Code of Last Cmdlet (White=success/Red=fail)
  If ($?) { $bgcolor = "White" } Else { $bgcolor = "Red" }

  #Desired Depth
  $MAX = 1
  $MAX = $MAX * -1

  $folders = Get-ChildItem -Path (Get-Location) -Directory -ErrorAction SilentlyContinue | Select-Object Name

  $folders = $folders.name

  if($folders)
  {
    $folders = $folders | Where {$_[0] -ne '.'}

    #Alternate implmentation of above
    #$folders = $folders | % { If ($_[0] -ne '.') {$_}}

    $folders = $folders -join ", "
  }

  # Get path as an array of strings
  $t = (Split-Path -path (Get-Location)).Split('\')
  $full_depth = $t.Count


  # Move the Root to $drive (Unless we're in Root)
  $drive = If ($t[0] -ne '') {$t[0]+'\'} Else {""}
  $a = $t[1..$t.Count]

  # Slice Array and Remove Null Elements
  $b = ($a[$MAX..-1] | Where {$_ -ne ""})

  # MAX has to be compared with depth in a sensible way
  $MAX = $MAX * -1
  $MAX += 1
  $new_depth = $b.Count
  $skip = ($full_depth - $MAX)

  if($t[1].length -gt 5)
  {
    $t[1] = "..$skip.."
  }

  # Join String Array Elements with '\' Unless Empty Array
  If ($new_depth) {$c = ($b -join '\')+'\'} Else {$c = ""}

  # Remove first $skip folders (unless they are longer than the abbreviation would be)
  If ($skip -gt 0) {$d = If($skip -lt 2) {"$drive$($t[1])\"} Else {"$drive..$skip..\"}} Else {$d = "$drive"}
  $nl = [Environment]::NewLine
  $p = Split-Path -leaf -path (Get-Location)

  #Changes Window Title to CWD
  $Host.ui.rawui.windowtitle = "$d$c$p"

  $promptString = "$d$c$p [ $folders ]"
  Write-Host $promptString -NoNewline -BackgroundColor $bgcolor -ForegroundColor Black
  return "$nl> "
}
