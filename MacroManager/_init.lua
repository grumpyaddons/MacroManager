local _, Private = ...;

MacroManager = {}

local AddonObject = LibStub("AceAddon-3.0"):NewAddon("MacroManager", "AceConsole-3.0");

function MacroManager.IsRetail()
    return true;
end

function AddonObject:OnInitialize()
    MacroManagerSaved = MacroManagerSaved or { };
    MacroManagerSaved.MacroManagerWindow = MacroManagerSaved.MacroManagerWindow or { }
    MacroManagerSaved.MacroManagerWindow.statusTable = MacroManagerSaved.MacroManagerWindow.statusTable or { }
    MacroManagerSaved.MacroManagerWindow.macroTreeStatusTable = MacroManagerSaved.MacroManagerWindow.macroTreeStatusTable or { }
end

function AddonObject:OnEnable()
    Private.CharacterSnapshots.CaptureCurrentCharacter();
end

function AddonObject:OnDisable()
    -- Called when the addon is disabled
end

Private.Addon = MacroManager;
