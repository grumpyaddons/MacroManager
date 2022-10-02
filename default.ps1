# Usage: psake default.ps1 Package
$macroManagerFolderPath = 'C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns\MacroManager';
$macroManagerDataFolderPath = 'C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns\MacroManagerData';

Task Package {
    Compress-Archive -Path MacroManager,MacroManagerData -DestinationPath package.zip
}

Task PublishToLocalWoW {
    
    if (Test-Path $macroManagerFolderPath) {
        Remove-Item $macroManagerFolderPath -Recurse -Force
    }

    if (Test-Path $macroManagerDataFolderPath) {
        Remove-Item $macroManagerDataFolderPath -Recurse -Force
    }

    Copy-Item '.\MacroManager' 'C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns' -Recurse
    Copy-Item '.\MacroManagerData' 'C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns' -Recurse
}

# Dev symlink to local WoW install
# cmd /c mklink /d $macroManagerFolderPath "./MacroManager"