local AddonName, Private = ...;

MacroManager = {}

local AddonObject = LibStub("AceAddon-3.0"):NewAddon("MacroManager", "AceConsole-3.0");

function MacroManager.IsRetail()
    return true;
end

function AddonObject:OnInitialize()
    -- Code that you want to run when the addon is first loaded goes here.
  end

function AddonObject:OnEnable()
    MacroManagerSaved = MacroManagerSaved or {};
end

function AddonObject:OnDisable()
    -- Called when the addon is disabled
end
