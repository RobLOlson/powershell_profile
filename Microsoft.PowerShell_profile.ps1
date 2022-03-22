#Robert Olson

#automatically manages virtual environments upon entering/exiting a folder

if (Get-Module -ListAvailable -Name ps-autoenv) {
  import-module ps-autoenv
}
else {
  Install-Module ps-autoenv
}

. 'C:\Users\sterl\OneDrive\Documents\WindowsPowerShell\autoenv.ps1'


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


function word-wrap {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=1,ValueFromPipeline=1,ValueFromPipelineByPropertyName=1)]
        [Object[]]$chunk
    )
    PROCESS {
        $Lines = @()
        foreach ($line in $chunk) {
            $str = ''
            $counter = 0
            $line -split '\s+' | %{
                $counter += $_.Length + 1
                if ($counter -gt $Host.UI.RawUI.BufferSize.Width-2) {
                    $Lines += ,$str.trim()
                    $str = ''
                    $counter = $_.Length + 1
                }
                $str = "$str$_ "
            }
            $Lines += ,$str.trim()
        }
        $Lines
    }
}

#open new terminals at project
$project = $env:project
$desktop = $env:desktop
$downloads = $env:downloads
$programming = $env:programming

#Changes Powershell Prompt to display CWD at limited depth
#And automatically supply list of folders
function prompt {
  $origLastExitCode = $LASTEXITCODE
  $exit_code = $?
  # Write-Host $global:gitpromptvalues.DollarQuestion -NoNewline

  # Ran as Administrator?
  $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

  $bgcolor = "White"

  If ($IsAdmin) { $bgcolor = "Yellow" }

  If ($exit_code) {} Else { $bgcolor = "Red" }

  if($env:VIRTUAL_ENV) {$bgcolor = "Green"}



  # Get path as an array of strings
  $leaf = Split-Path -leaf -path (Get-Location)
  $path = @(Split-Path -path (Get-Location)).Split('\') + $leaf
  $drive = $path[0]

  $terminal_height = (Get-Host).UI.RawUI.MaxWindowSize.Height
  $terminal_width = (Get-Host).UI.RawUI.MaxWindowSize.Width

  $folders = Get-ChildItem -Path (Get-Location) -Directory -ErrorAction SilentlyContinue | Select-Object Name

  $folders = $folders.name

  if(!$folders) { $folders = "" }

  # Hide hidden folders
  $folders = $folders | Where {$_[0] -ne '.'}

  $folders_list = @($folders)
  $folders = $folders -join ", "

  # IF folder list requires multiple lines
  if( ($folders.length) -gt ($terminal_width)) {
    $folders = $folders | word-wrap

    $MAX_FOLDER_LINES = 3

    $folders = $folders[0..$MAX_FOLDER_LINES]
    if($folders[$MAX_FOLDER_LINES])
    {
      # omit excess folders with '...'
      $folders[$MAX_FOLDER_LINES] = " " * (($terminal_width-3)/2-1) + "..."
    }

    # Pad the end of each line so that the background color changes appropriately
    $i = 0
    foreach ($line in $folders){
      $folders[$i] = $line + " " * ($terminal_width - $line.length)
      $i = $i + 1
    }

    # Lines must be manually joined with new-line characters to print properly
    $folders = $folders -join "`n"

  }
  else{
    $folders = $folders + " " * ($terminal_width - $folders.length)
  }


  # If CWD is too long, try using '~''
  if(($path -join '\').length -gt $terminal_width){
    $shortpath = @('~')+@($path[3..256])
    if(($shortpath -join '\').length -lt $terminal_width){
      $path = $shortpath
    }
  }

  # If CWD is STILL too long, use C:\..N..\
  $cut_count = 1
  while(($path -join '\').length -gt $terminal_width){
    $cut_count += 1
    $cut_string = '..'+$cut_count+'..'
    $path = @($drive, $cut_string)+$path[3..256]
  }

  #Changes Window Title to CWD
  If ($isadmin) {
    $Host.ui.rawui.windowtitle = "$leaf [ADMIN]"
  } Else {
    $Host.ui.rawui.windowtitle = "$leaf"
  }

  Write-Host $folders -NoNewline -BackgroundColor $bgcolor -ForegroundColor Black

  # print venv path, if exists
  # !! setx VIRTUAL_ENV_DISABLE_PROMPT $true to disable pre-packaged prompt modifiers !!
  if ($env:VIRTUAL_ENV){
    # If virtual env path is too long, try collapsing '~'
    if($env:VIRTUAL_ENV.length -gt $terminal_width){
      $subs = @($env:VIRTUAL_ENV -split "\\")
      $subs = $subs[3..256] -join '\'
      Write-Host ~\$subs -ForegroundColor Green
    } else {
      Write-Host $env:VIRTUAL_ENV -ForegroundColor Green
    }
  }

  # Arrays are normally immutable, so create a mutable 'ArrayList'
  [System.Collections.ArrayList]$path2=$path
  $path2.remove($leaf)
  Write-host ($path2 -join '\') -NoNewLine
  Write-host \ -NoNewLine
  Write-Host $leaf -BackgroundColor Black -ForegroundColor Yellow

  If ($isadmin) {
    Write-Host "(ADMIN)" -ForegroundColor Yellow -NoNewLine
  }

  # invoke posh-git to finalize prompt
  & $GitPromptScriptBlock
  return "> "
}

function global:PromptWriteErrorInfo() {
    if ($global:GitPromptValues.DollarQuestion) { return }

    if ($global:GitPromptValues.LastExitCode) {
        "`e[31m(" + $global:GitPromptValues.LastExitCode + ") `e[0m"
    }
    else {
        "`e[31m! `e[0m"
    }
}

# $global:GitPromptSettings.DefaultPromptBeforeSuffix.Text = '`n$(PromptWriteErrorInfo)$([DateTime]::now.ToString("MM-dd HH:mm:ss"))'

# Adds tab completion for git commands
# Import-Module 'C:\tools\poshgit\dahlbyk-posh-git-9bda399\src\posh-git.psd1'
# Import-Module posh-git

if (Get-Module -ListAvailable -Name posh-git) {
  import-module posh-git
  $GitPromptSettings.DefaultPromptPath = ""
  $GitPromptSettings.PathStatusSeparator = ""
}
else {
  Install-Module posh-git
}

# Use python+sympy as a symbolic calculator
Function calc {
  py -ic "from sympy import init_session; init_session(use_unicode=False)"
}


# ZLocation (alias 'z') is an alternative to cd that learns important folders
# NOTE: Import MUST be made after other prompt modifiers
# NOTE: Commented out import because it was interfering with exit code stuff
if (Get-Module -ListAvailable -Name ZLocation) {
  import-module ZLocation
  New-Alias -Name a -Value z
}
else {
  Install-Module ZLocation
}
