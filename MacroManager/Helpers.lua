local _, Private = ...;

-- Patch 12.1 moved these off the global namespace and into Constants.MacroConsts
-- (also raising MAX_CHARACTER_MACROS from 18 to 30 in the process). Fall back to the
-- old globals for Classic clients, which haven't picked up that migration.
local MacroConsts = Constants and Constants.MacroConsts;
local MAX_ACCOUNT_MACROS = (MacroConsts and MacroConsts.MAX_ACCOUNT_MACROS) or MAX_ACCOUNT_MACROS;
local MAX_CHARACTER_MACROS = (MacroConsts and MacroConsts.MAX_CHARACTER_MACROS) or MAX_CHARACTER_MACROS;

local Helpers = {
    MAX_ACCOUNT_MACROS = MAX_ACCOUNT_MACROS,
    MAX_CHARACTER_MACROS = MAX_CHARACTER_MACROS
}

function Helpers.MacroTypeBasedOnIndex(macroId)
    if macroId <= MAX_ACCOUNT_MACROS then
        return "account"
    else
        return "character"
    end
end

Private.Helpers = Helpers;