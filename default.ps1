Task Package {
    Compress-Archive -Path MacroManager,MacroManagerData -DestinationPath package.zip
}

Task PublishToLocalWoW {
    $macroManagerFolderPath = 'C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns\MacroManager';
    if (Test-Path $macroManagerFolderPath) {
        Remove-Item $macroManagerFolderPath -Recurse -Force
    }

    $macroManagerDataFolderPath = 'C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns\MacroManagerData';
    if (Test-Path $macroManagerDataFolderPath) {
        Remove-Item $macroManagerDataFolderPath -Recurse -Force
    }

    Copy-Item '.\MacroManager' 'C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns' -Recurse
    Copy-Item '.\MacroManagerData' 'C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns' -Recurse
}