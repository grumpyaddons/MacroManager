# Usage: psake default.ps1 Package
$classicAddonsPath = "F:\World of Warcraft\_classic_\Interface\AddOns"
$classicMacroManagerPath = "$classicAddonsPath\MacroManager"
$classicMacroManagerDataPath = "$classicAddonsPath\MacroManagerData"

$retailAddonsPath = "F:\wow-retail\World of Warcraft\_retail_\Interface\AddOns"
$retailMacroManagerPath = "$retailAddonsPath\MacroManager"
$retailMacroManagerDataPath = "$retailAddonsPath\MacroManagerData"


Task Package {
    Compress-Archive -Path MacroManager,MacroManagerData -DestinationPath package.zip -Force
}

Task SymlinkForDev {
    # Classic
    if (Test-Path $classicMacroManagerPath) {
        Remove-Item $classicMacroManagerPath -Recurse -Force
    }
    if (Test-Path $classicMacroManagerDataPath) {
        Remove-Item $classicMacroManagerDataPath -Recurse -Force
    }
    New-Item -ItemType SymbolicLink -Path $classicMacroManagerPath -Target "$pwd\MacroManager"
    New-Item -ItemType SymbolicLink -Path $classicMacroManagerDataPath -Target "$pwd\MacroManagerData"

    # Retail
    if (Test-Path $retailMacroManagerPath) {
        Remove-Item $retailMacroManagerPath -Recurse -Force
    }
    if (Test-Path $retailMacroManagerDataPath) {
        Remove-Item $retailMacroManagerDataPath -Recurse -Force
    }
    New-Item -ItemType SymbolicLink -Path $retailMacroManagerPath -Target "$pwd\MacroManager"
    New-Item -ItemType SymbolicLink -Path $retailMacroManagerDataPath -Target "$pwd\MacroManagerData"
}
