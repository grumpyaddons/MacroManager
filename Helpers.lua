local _, Private = ...;

local Helpers = {}

function Helpers.MacroTypeBasedOnIndex(macroId)
    if macroId < 121 then
        return "account"
    else
        return "character"
    end
end

Private.Helpers = Helpers;