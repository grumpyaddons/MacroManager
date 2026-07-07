local _, Private = ...;

-- Contain accessing undefined variables to one place to remove linter warnings.
local hooksecurefunc, GetItemInfo, GetItemSpell, GetSpellInfo, CreateFrame, C_Spell = hooksecurefunc, GetItemInfo, GetItemSpell, GetSpellInfo, CreateFrame, C_Spell;
local strfind, strsub, strmatch = strfind, strsub, strmatch;

-- GetSpellInfo (multi-return) was removed on Retail as part of the 11.0
-- SpellBook API rewrite, replaced by C_Spell.GetSpellInfo (single table
-- return). Classic-family clients still have the old global. Prefer the
-- modern table API when present, fall back to the old global otherwise.
local function GetSpellName(spellId)
    if ( C_Spell and C_Spell.GetSpellInfo ) then
        local info = C_Spell.GetSpellInfo(spellId);
        return info and info.name;
    end
    if ( GetSpellInfo ) then
        return GetSpellInfo(spellId);
    end
end

-- Returns true once the paste has been handled (inserted, or nothing to do).
-- Returns false when the item/spell data isn't cached client-side yet, so the
-- caller can retry once the server has sent it back instead of erroring out
-- on a nil name (this happens a lot right after new items are added, e.g. a
-- fresh TBC/Anniversary content patch, when nobody has looked at them yet).
local function TryInsertLink(text)
    local macroBodyWidget = Private.Layout.MacroEditor.macroBodyWidget;
    if not ( macroBodyWidget and macroBodyWidget.editBox:HasFocus() ) then
        return true;
    end

    local cursorPosition = macroBodyWidget.editBox:GetCursorPosition();
    local isTheStartOfAnEmptyLine = cursorPosition == 0 or
        strsub(macroBodyWidget.editBox:GetText(), cursorPosition, cursorPosition) == "\n";

    local isItem = strfind(text, "item:", 1, true);
    local isSpell = strfind(text, "spell:", 1, true);

    local valueToInsert = text;

    if isItem then
        local item = GetItemInfo(text);
        if not item then
            return false;
        end

        if isTheStartOfAnEmptyLine then
            if ( GetItemSpell(item) ) then
                valueToInsert = "/use "..item.."\n";
            else
                valueToInsert = "/equip "..item.."\n";
            end
        else
            valueToInsert = item
        end
    elseif isSpell then
        local spellId = strmatch(text, "spell:(%d+):");
        local spellName = GetSpellName(tonumber(spellId));

        -- Spell names are essentially always cached (spellbook, auras, etc.),
        -- unlike brand new items, so just fall back to the raw link rather
        -- than wiring up a retry (GET_ITEM_INFO_RECEIVED wouldn't fire for it).
        if spellName then
            if isTheStartOfAnEmptyLine then
                valueToInsert = "/cast "..spellName.."\n";
            else
                valueToInsert = spellName;
            end
        end
    end

    macroBodyWidget.editBox:Insert(valueToInsert);
    return true;
end

local function OnLinkInserted(text)
    -- Code taken and modified from
    -- https://github.com/Gethe/wow-ui-source/blob/f43c2b83f700177e6a2a215f5d7d0c0825abd636/Interface/FrameXML/ChatFrame.lua#L4549
    if ( not text ) then
        return
    end

    if TryInsertLink(text) then
        return;
    end

    local retryFrame = CreateFrame("Frame");
    retryFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED");
    retryFrame:SetScript("OnEvent", function(self, _, _, success)
        if ( success and TryInsertLink(text) ) then
            self:UnregisterEvent("GET_ITEM_INFO_RECEIVED");
            self:SetScript("OnEvent", nil);
        end
    end);
end

-- The client's actual shift-click-to-insert codepath goes through
-- ChatFrameUtil.InsertLink on newer clients (including current Classic/TBC/
-- Wrath/Cata builds). The legacy global ChatEdit_InsertLink still exists there,
-- but only as `ChatEdit_InsertLink = ChatFrameUtil.InsertLink` (a one-time
-- variable alias in Blizzard_DeprecatedChatInfo, not a wrapper), so nothing
-- actually calls through the global anymore and hooking it alone never fires.
-- Hook whichever entry point is present.
local originalChatFrameUtilInsertLink = ChatFrameUtil and ChatFrameUtil.InsertLink;
if ( originalChatFrameUtilInsertLink ) then
    hooksecurefunc(ChatFrameUtil, "InsertLink", OnLinkInserted);
end
if ( _G.ChatEdit_InsertLink and _G.ChatEdit_InsertLink ~= originalChatFrameUtilInsertLink ) then
    hooksecurefunc("ChatEdit_InsertLink", OnLinkInserted);
end