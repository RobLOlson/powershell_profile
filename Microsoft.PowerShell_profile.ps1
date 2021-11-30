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

  $exit_code = $?
  # Ran as Administrator?
  $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

  $bgcolor = "White"
  $nl = [Environment]::NewLine

  If ($IsAdmin) { $bgcolor = "Yellow" }

  If ($exit_code) {$dummy=0} Else { $bgcolor = "Red" }

  $terminal_height = (Get-Host).UI.RawUI.MaxWindowSize.Height
  $terminal_width = (Get-Host).UI.RawUI.MaxWindowSize.Width

  # Get path as an array of strings
  $path = (Split-Path -path (Get-Location)).Split('\')
  $leaf = Split-Path -leaf -path (Get-Location)

  $folders = Get-ChildItem -Path (Get-Location) -Directory -ErrorAction SilentlyContinue | Select-Object Name

  $folders = $folders.name


  if($folders)
  {
    # Hide hidden folders
    $folders = $folders | Where {$_[0] -ne '.'}

    $folders = $folders -join ", "

    # IF folder list requires multiple lines
    if( $($folders.length) -gt $terminal_width) {
      $folders = $folders | word-wrap

      # indent list
      $folders[0] = "  " + $folders[0]

      # Pad the end of each line so that the background color changes appropriately
      $i = 0
      foreach ($line in $folders){
        if($i -eq 0){
          $folders[0] = $line + " " * ($terminal_width - $line.length)
        }
        else {
          $folders[$i] = $line + " " * ($terminal_width - $line.length - 2)
        }
        $i = $i + 1
      }

      # Lines must be manually joined with new-line characters to print properly
      $folders = $folders -join "`n  "

      $fake_prompt = "> cd ..." + " " * ($terminal_width -8) + "`n"
      $folders = $fake_prompt + $folders
    }

    # ELSE folders fit on one line
    else {
      $folders = "cd> " + $folders + " " * ($terminal_width - $folders.length - 4)
    }
  } else {
    $folders = "cd> " + $folders + " " * ($terminal_width - $folders.length - 4)
  }

  # use list of path lengths walk up to the terminal width
  $path_lengths = foreach ($folder in $path){($folder).Length}
  $cur_length = 0
  $root_count = 0

  # walk down the path in reverse, accumulating string length; stop when terminal width is exceeded
  foreach ($length in $path_lengths[$path_lengths.length..1]){
    if ($cur_length+$length -lt ($terminal_width-"C:\..X..\".length-$leaf.length)) {
        $cur_length = $cur_length + $length + 1
        $root_count += 1
    } else {
      break
    }
  }

  $MAX = -1 * $root_count

  $finish_line_later = 0

  $finish_folders = " " * ($terminal_width - 1 - (($folders.length + 4) % $terminal_width))

  if( $folders.length + $path_width + 4 -gt $terminal_width) {
    $folder_sep = [Environment]::NewLine
  } else {
    $folder_sep = ""
  }

  $full_depth = $path.Count

  # Move the Root to $drive (Unless we're in Root)
  $drive = If ($path[0] -ne '') {$path[0]+'\'} Else {""}

  # a is driveless path, e.g., "/Users/bob/desktop"
  $a = $path[1..$path.Count]

  # Slice Array and Remove Null Elements
  #$b = ($a[$MAX..-1] | Where {$_ -ne ""})
  $b = ($a[$MAX..-1] | Where {$_ -ne ""})

  # MAX has to be compared with depth in a sensible way
  $MAX = $MAX * -1
  $MAX += 1
  $new_depth = $b.Count
  $skip = ($full_depth - $MAX)

  if($path[1].length -gt 5)
  {
    $path[1] = "..$skip.."
  }

  # Join String Array Elements with '\' Unless Empty Array
  If ($new_depth) {$c = ($b -join '\')+'\'} Else {$c = ""}

  # Remove first $skip folders (unless they are longer than the abbreviation would be)
  If ($skip -gt 0) {$d = If($skip -lt 2) {"$drive$($path[1])\"} Else {"$drive..$skip..\"}} Else {$d = "$drive"}

  #Changes Window Title to CWD
  If ($isadmin) {
    $Host.ui.rawui.windowtitle = "$d$c$leaf [ADMIN]"
  } Else {
    $Host.ui.rawui.windowtitle = "$d$c$leaf"
  }

  $promptString = "$folders"
  Write-Host $promptString -NoNewline -BackgroundColor $bgcolor -ForegroundColor Black
  $promptString = "$nl$d$c$leaf"
  Write-Host $promptString -NoNewLine

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

