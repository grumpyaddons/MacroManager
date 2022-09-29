local AddonName, Private = ...

MacroMicro = {}
local AddonObject = LibStub("AceAddon-3.0"):NewAddon("MacroMicro", "AceConsole-3.0");
function MacroMicro.IsRetail()
    return true;
end

function AddonObject:OnInitialize()
    -- Code that you want to run when the addon is first loaded goes here.
  end

function AddonObject:OnEnable()
    MacroMicroSaved = MacroMicroSaved or {};
end

function AddonObject:OnDisable()
    -- Called when the addon is disabled
end
