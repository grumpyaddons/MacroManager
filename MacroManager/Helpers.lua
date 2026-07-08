local _, Private = ...;

local MAX_ACCOUNT_MACROS = MAX_ACCOUNT_MACROS;

local Helpers = {}

function Helpers.MacroTypeBasedOnIndex(macroId)
    if macroId <= MAX_ACCOUNT_MACROS then
        return "account"
    else
        return "character"
    end
end

Private.Helpers = Helpers;