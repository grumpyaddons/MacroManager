# Usage: psake default.ps1 Package
$classicAddonsPath = "C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns"
$classicMacroManagerPath = "$classicAddonsPath\MacroManager"
$classicMacroManagerDataPath = "$classicAddonsPath\MacroManagerData"

$retailAddonsPath = "D:\wow-retail\World of Warcraft\_retail_\Interface\AddOns"
$retailMacroManagerPath = "$retailAddonsPath\MacroManager"
$retailMacroManagerDataPath = "$retailAddonsPath\MacroManagerData"


Task Package {
    Compress-Archive -Path MacroManager,MacroManagerData -DestinationPath package.zip
}

Task SymlinkForDev {
    # Classic
    if (Test-Path $classicMacroManagerPath) {
        (Get-Item $classicMacroManagerPath).Delete()
    }
    if (Test-Path $classicMacroManagerDataPath) {
        (Get-Item $classicMacroManagerDataPath).Delete()
    }
    New-Item -ItemType SymbolicLink -Path $classicMacroManagerPath -Target "$pwd\MacroManager"
    New-Item -ItemType SymbolicLink -Path $classicMacroManagerDataPath -Target "$pwd\MacroManagerData"

    # Retail
    if (Test-Path $retailMacroManagerPath) {
        (Get-Item $retailMacroManagerPath).Delete()
    }
    if (Test-Path $retailMacroManagerDataPath) {
        (Get-Item $retailMacroManagerDataPath).Delete()
    }
    New-Item -ItemType SymbolicLink -Path $retailMacroManagerPath -Target "$pwd\MacroManager"
    New-Item -ItemType SymbolicLink -Path $retailMacroManagerDataPath -Target "$pwd\MacroManagerData"
}
