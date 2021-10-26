#Robert Olson

#automatically manages virtual environments upon entering/exiting a folder

if (Get-Module -ListAvailable -Name ps-autoenv) {
  import-module ps-autoenv
}
else {
  Install-Module ps-autoenv
}

# Ran as Administrator?
$IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)


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

  $exit_code = $?

  $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

  $bgcolor = "White"

  If ($IsAdmin) { $bgcolor = "Yellow" }

  If ($exit_code) {$dummy=0} Else { $bgcolor = "Red" }

  $terminal_height = (Get-Host).UI.RawUI.MaxWindowSize.Height
  $terminal_width = (Get-Host).UI.RawUI.MaxWindowSize.Width

  #Desired Depth (if path is sider than terminal window)
  $path_width = ((pwd)[0].toString().Length)
  if($path_width -gt $terminal_width) {
    $MAX = 1
    $MAX = $MAX * -1
  }
  else {
    $MAX = 10
    $MAX = $MAX*-1
  }

  $folders = Get-ChildItem -Path (Get-Location) -Directory -ErrorAction SilentlyContinue | Select-Object Name

  $folders = $folders.name

  if($folders)
  {
    $folders = $folders | Where {$_[0] -ne '.'}

    #Alternate implmentation of above
    #$folders = $folders | % { If ($_[0] -ne '.') {$_}}

    $folders = $folders -join ", "
  }

  $finish_line_later = 0

  if( $folders.length + $path_width + 4 -gt $terminal_width) {
    $folder_sep = [Environment]::NewLine
    if( $MAX -eq -10) {
      $finish_line = " " * ($terminal_width - $path_width -1) # pad end of line with spaces
    } else {
      $finish_line_later = 1
    }
    $finish_folders = " " * ($terminal_width - 1 - (($folders.length + 4) % $terminal_width))
  } else {
    $folder_sep = ""
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
  If ($isadmin) {
    $Host.ui.rawui.windowtitle = "$d$c$p [ADMIN]"
  } Else {
    $Host.ui.rawui.windowtitle = "$d$c$p"
  }

  if($finish_line_later){
    $finish_line = " " * ($terminal_width - "$d$c$p".length - 1)
  }

  $promptString = "[ $folders ] $finish_folders$d$c$p $finish_line"
  Write-Host $promptString -NoNewline -BackgroundColor $bgcolor -ForegroundColor Black
  If ($isadmin) {
    return $nl+"ADMIN> "
  } Else {
    return "$nl> "
  }
  return "$nl> "
}

# Adds tab completion for git commands
Import-Module 'C:\tools\poshgit\dahlbyk-posh-git-9bda399\src\posh-git.psd1'

# Use python+sympy as a symbolic calculator
Function calc {
  py -ic "from sympy import init_session; init_session(use_unicode=False)"
}

