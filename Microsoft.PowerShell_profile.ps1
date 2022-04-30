#Robert Olson

#automatically manages virtual environments upon entering/exiting a folder

# $PSDefaultParameterValues = @{ '*:Encoding' = 'utf8' }

Set-PSReadLineOption -PredictionSource History

if (Get-Module -ListAvailable -Name ps-autoenv) {
  import-module ps-autoenv
}
else {
  Install-Module ps-autoenv
}

# Updated version of PSReadLine gives line completion
if (Get-Module -ListAvailable -Name PSReadLine) {
  import-module PSReadLine
}
else {
  Install-Module PSReadLine -RequiredVersion 2.2.2
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
$appdata = $home +  "\AppData\Local"

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

  $tasks = Get-Content -Path ($appdata+'\robolson\tick\tasks.txt') -ErrorAction SilentlyContinue

  # Get path as an array of strings
  $leaf = Split-Path -leaf -path (Get-Location)
  $path = @(Split-Path -path (Get-Location)).Split('\') + $leaf
  $path = @($path | where {$_})

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

  # Adjust environment folder display if exists
  if($env:VIRTUAL_ENV){
    if($folders.contains((Split-path -path $env:VIRTUAL_ENV -leaf))){
      $folders = $folders.replace((Split-Path -path $env:VIRTUAL_ENV -leaf), ("[*"+(Split-Path -path $env:VIRTUAL_ENV -leaf)+"]"))
      $skip_env_line = $true
    }
    if((Split-path -path (Get-Location))-eq(Split-path -path $env:VIRTUAL_ENV)){
      $skip_env_line = $true
    }
  }

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


  # If CWD is too long, try using '~'
  if(($path -join '\').length -gt $terminal_width -and "users" -in $path){
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

  If ($isadmin) {
    $Host.ui.rawui.windowtitle = "$leaf [ADMIN]"
  } Else {
    $Host.ui.rawui.windowtitle = "$leaf"
  }

  if($tasks){
    $tasks = $tasks -join ", "
    if($tasks.length -gt $terminal_width){
      $tasks = $tasks[0..($terminal_width - 4)] -join ""
      $tasks = $tasks + "..."
    }
    $tasks = $tasks + " " * ($terminal_width - $tasks.length)
    Write-Host $tasks -NoNewline -BackgroundColor Red -ForegroundColor Black
  }

  Write-Host $folders -NoNewline -BackgroundColor $bgcolor -ForegroundColor Black

  # print venv path, if exists (and desired)
  # !! setx VIRTUAL_ENV_DISABLE_PROMPT $true to disable pre-packaged prompt modifiers !!
  $vdirs = @($env:VIRTUAL_ENV -split "\\")
  $vdirs = @('~')+$vdirs[3..256]
  if ($env:VIRTUAL_ENV -and !$skip_env_line)
  {
    # If virtual env path is too long, try collapsing '~'
    if($env:VIRTUAL_ENV.length -gt $terminal_width){
      # $vdirs = $vdirs -join '\'
      Write-Host ($vdirs -join '\') -ForegroundColor Green
    } else {
      Write-Host $env:VIRTUAL_ENV -ForegroundColor Green
    }
  }

  # if($env:VIRTUAL_ENV){
  #   [System.Collections.ArrayList]$env2 = ($env:VIRTUAL_ENV -split '\\')
  #   $env2.removeat($($env2).length-1)
  #   if($env2 -eq $path) {
  #     Write-Host DLFKJDLSKFJ
  #   }
  # }

  # Arrays are normally immutable, so create a mutable 'ArrayList'
  [System.Collections.ArrayList]$path2=@($path)
  $path2.remove($leaf)
  if($path2.length -gt 1){
    Write-host ($path2 -join '\') -NoNewLine
    Write-host \ -NoNewLine
    Write-Host $leaf -BackgroundColor Black -ForegroundColor Yellow
  }
  else{
    Write-host $path
  }

  If ($isadmin) {
    Write-Host "(ADMIN)" -ForegroundColor Yellow -NoNewLine
  }

  # invoke posh-git to finalize prompt
  & $GitPromptScriptBlock
  return "> "
}

# Adds tab completion for git commands and git-integrated prompt
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




# powertoys keyboard remap, copy as 'default.json' to %appdata%../local/Microsoft/Powertoys/Keyboard... etc.
# {"remapKeys":{"inProcess":[{"originalKeys":"20","newRemapKeys":"13"},{"originalKeys":"36","newRemapKeys":"20"}]},"remapShortcuts":{"global":[{"originalKeys":"164;49","newRemapKeys":"48"},{"originalKeys":"164;50","newRemapKeys":"57"},{"originalKeys":"164;51","newRemapKeys":"56"},{"originalKeys":"164;52","newRemapKeys":"55"},{"originalKeys":"164;53","newRemapKeys":"109"},{"originalKeys":"164;54","newRemapKeys":"187"},{"originalKeys":"164;65","newRemapKeys":"37"},{"originalKeys":"164;66","newRemapKeys":"78"},{"originalKeys":"164;67","newRemapKeys":"188"},{"originalKeys":"164;68","newRemapKeys":"39"},{"originalKeys":"164;69","newRemapKeys":"73"},{"originalKeys":"164;70","newRemapKeys":"74"},{"originalKeys":"164;72","newRemapKeys":"37"},{"originalKeys":"164;74","newRemapKeys":"40"},{"originalKeys":"164;75","newRemapKeys":"38"},{"originalKeys":"164;76","newRemapKeys":"39"},{"originalKeys":"164;81","newRemapKeys":"80"},{"originalKeys":"164;82","newRemapKeys":"85"},{"originalKeys":"164;83","newRemapKeys":"40"},{"originalKeys":"164;86","newRemapKeys":"77"},{"originalKeys":"164;87","newRemapKeys":"38"},{"originalKeys":"164;88","newRemapKeys":"190"},{"originalKeys":"164;90","newRemapKeys":"191"},{"originalKeys":"164;112","newRemapKeys":"79"},{"originalKeys":"164;113","newRemapKeys":"76"},{"originalKeys":"164;114","newRemapKeys":"75"},{"originalKeys":"164;192","newRemapKeys":"8"},{"originalKeys":"164;160;53","newRemapKeys":"160;189"},{"originalKeys":"164;160;54","newRemapKeys":"107"},{"originalKeys":"164;160;65","newRemapKeys":"160;186"},{"originalKeys":"164;160;112","newRemapKeys":"160;219"},{"originalKeys":"164;160;113","newRemapKeys":"160;221"},{"originalKeys":"164;160;192","newRemapKeys":"46"},{"originalKeys":"162;164;65","newRemapKeys":"162;37"},{"originalKeys":"162;164;68","newRemapKeys":"162;39"},{"originalKeys":"162;164;72","newRemapKeys":"162;37"},{"originalKeys":"162;164;74","newRemapKeys":"162;40"},{"originalKeys":"162;164;75","newRemapKeys":"162;38"},{"originalKeys":"162;164;76","newRemapKeys":"162;39"},{"originalKeys":"162;164;83","newRemapKeys":"162;40"},{"originalKeys":"162;164;87","newRemapKeys":"162;38"},{"originalKeys":"162;164;112","newRemapKeys":"219"},{"originalKeys":"162;164;113","newRemapKeys":"221"},{"originalKeys":"91;187","newRemapKeys":"91;13"}],"appSpecific":[]}}
