local _, Private = ...;

-- Contain accessing undefined variables to one place to remove linter warnings.
local hooksecurefunc, GetItemInfo, GetItemSpell, GetSpellInfo = hooksecurefunc, GetItemInfo, GetItemSpell, GetSpellInfo;
local strfind, strsub = strfind, strsub;

hooksecurefunc("ChatEdit_InsertLink", function(text)
    -- Code taken and modified from
    -- https://github.com/Gethe/wow-ui-source/blob/f43c2b83f700177e6a2a215f5d7d0c0825abd636/Interface/FrameXML/ChatFrame.lua#L4549
	if ( not text ) then
		return
	end
    local macroBodyWidget = Private.Layout.MacroEditor.macroBodyWidget;
    if ( macroBodyWidget and macroBodyWidget.editBox:HasFocus() ) then
        local valueToInsert = text;

        local cursorPosition = macroBodyWidget.editBox:GetCursorPosition();
        local isTheStartOfAnEmptyLine = cursorPosition == 0 or
            strsub(macroBodyWidget.editBox:GetText(), cursorPosition, cursorPosition) == "\n";

        local isItem = strfind(text, "item:", 1, true);
        local isSpell = strfind(text, "spell:", 1, true);

        if isItem then
            local item = GetItemInfo(text);
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
            local _, _, spellId = string.find(text, "spell:(%d+):");
            local spellName = GetSpellInfo(tonumber(spellId));

            if isTheStartOfAnEmptyLine then
                valueToInsert = "/cast "..spellName.."\n";
            else
                valueToInsert = spellName;
            end
        end

        macroBodyWidget.editBox:Insert(valueToInsert);
    end
end);