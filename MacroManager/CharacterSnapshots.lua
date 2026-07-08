local _, Private = ...;

-- Contain accessing undefined variables to one place to remove linter warnings.
local GetMacroInfo, GetNumMacros, UnitFullName, UnitClass = GetMacroInfo, GetNumMacros, UnitFullName, UnitClass;
local MAX_ACCOUNT_MACROS = MAX_ACCOUNT_MACROS;

local CharacterSnapshots = {};

function CharacterSnapshots.GetFullCharacterName()
    local name, realm = UnitFullName("player");
    if realm and realm ~= "" then
        return name.."-"..realm;
    end
    return name;
end

-- Captures the current character's character-specific macros (the slots after all
-- account macros) into the account-wide saved variables, keyed by full character
-- name. Since MacroManagerSaved is shared across every character on the account,
-- this is what lets other characters browse a read-only copy of it later.
function CharacterSnapshots.CaptureCurrentCharacter()
    MacroManagerSaved.CharacterMacroSnapshots = MacroManagerSaved.CharacterMacroSnapshots or {};

    local _, characterMacroCount = GetNumMacros();

    local macros = {};
    for i = MAX_ACCOUNT_MACROS + 1, characterMacroCount + MAX_ACCOUNT_MACROS do
        local macroName, icon, macroBody = GetMacroInfo(i);
        table.insert(macros, { name = macroName, icon = icon, body = macroBody });
    end

    local _, classToken = UnitClass("player");

    MacroManagerSaved.CharacterMacroSnapshots[CharacterSnapshots.GetFullCharacterName()] = {
        class = classToken,
        macros = macros
    };
end

function CharacterSnapshots.GetAll()
    return MacroManagerSaved.CharacterMacroSnapshots or {};
end

-- Snapshots captured before the addon tracked class info are stored as a bare
-- macros array rather than { class = ..., macros = ... }. Handle both so old
-- saved data doesn't break until that character logs in and gets recaptured.
function CharacterSnapshots.GetMacros(characterName)
    local entry = CharacterSnapshots.GetAll()[characterName];
    if not entry then
        return nil;
    end
    return entry.macros or entry;
end

function CharacterSnapshots.GetClass(characterName)
    local entry = CharacterSnapshots.GetAll()[characterName];
    return entry and entry.class;
end

function CharacterSnapshots.GetMacro(characterName, index)
    local macros = CharacterSnapshots.GetMacros(characterName);
    return macros and macros[index];
end

Private.CharacterSnapshots = CharacterSnapshots;
