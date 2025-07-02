//This is a config file for Nilesoft Shell found at nilesoft.org
//This file should be located at `C:\Program Files\Nilesoft Shell`

settings
{
	priority=1
	exclude.where = !process.is_explorer
	showdelay = 10
	// Options to allow modification of system items
	modify.remove.duplicate=1
	tip.enabled=true
}

remove(find="Sort")
remove(find="Manage access")
remove(find="Free up space")
remove(find="Scan with")
remove(find="Add to favorites")
remove(find="Move to OneDrive")
remove(find="Edit in Note")
remove(find="Give access to")
remove(find="Copy Link")
remove(find="Version History")

item(type="file" title="Clean" cmd="py.exe" arg='-m robo.rob.clean --target="@sel.path\." --yes-all')

item(where=package.exists("WindowsTerminal") title=title.Windows_Terminal tip=tip_run_admin admin=has_admin image='@package.path("WindowsTerminal")\WindowsTerminal.exe' cmd='wt.exe' arg='-d "@sel.path\."')

remove(type="file" find="Windows Terminal")

import 'imports/theme.nss'
import 'imports/images.nss'

import 'imports/modify.nss'

menu(mode="multiple" title="Pin/Unpin" image=icon.pin)
{
}

menu(mode="multiple" title=title.more_options image=icon.more_options)
{
}

import 'imports/taskbar.nss'
