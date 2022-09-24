local AddonName, Private = ...

local AceGUI = LibStub("AceGUI-3.0");

local AddonObject = LibStub("AceAddon-3.0"):NewAddon("MacroMicro", "AceConsole-3.0");
function AddonObject:OnInitialize()
    -- Code that you want to run when the addon is first loaded goes here.
  end

function AddonObject:OnEnable()
    -- Called when the addon is enabled
end

function AddonObject:OnDisable()
    -- Called when the addon is disabled
end


local Predictor = {}
function Predictor:Initialize()
end
function Predictor:GetValues(text, values, max)
end
function Predictor:GetValue(text, key)
end
function Predictor:GetHyperlink(key)
end
LibStub("AceGUI-3.0-Search-EditBox"):Register("MacroPredictor", Predictor)

local frame = nil;

local sharedMacroLabel = nil;

local scrollStatusTable = {
    scrollvalue = 0,
    offset = 0
};

local fameStatusTable = {};

local macroTree = nil;
local macroTreeStatusTable = {};

local selectedMacroId = nil;
local selectedMacroLabel = nil;
local selectedMacroTexture = nil;

local macroIcon = nil;
local macroBodyEditBox = nil;
local macroNameEditBox = nil;
local macroIsAccountTypeRadioButton = nil;

local macroTypeRadioButtons = {};
macroTypeRadioButtons.characterMacroRadioButton = nil;
macroTypeRadioButtons.accountMacroRadioButton = nil;

function SetMacroTypeRadioButtons(macroIndex)
    if macroIndex == nil or macroIndex == -1 then
        macroTypeRadioButtons.accountMacroRadioButton:SetValue(false)
        macroTypeRadioButtons.characterMacroRadioButton:SetValue(true)
    else
        macroTypeRadioButtons.accountMacroRadioButton:SetValue(macroIndex < 121)
        macroTypeRadioButtons.characterMacroRadioButton:SetValue(macroIndex >= 121)
    end
end

function GetMacroTypeSelected()
    if macroTypeRadioButtons.accountMacroRadioButton:GetValue() then
        return "account";
    else
        return "character";
    end
end

function MacroTypeBasedOnIndex(macroIndex)
    if macroIndex < 121 then
        return "account"
    else
        return "character"
    end
end

StaticPopupDialogs["DELETE_MACRO"] = {
    text = "Do you want to delete the macro '%s'?",
    button1 = "Delete Macro",
    button2 = "Cancel",
    OnAccept = function(self, macroId)
        DeleteMacro(self.macroId);
        frame:Release();
        frame = nil;
        Show_Options();
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 5
  }

function CreateMacroHeaderLabel(text)
    local label = AceGUI:Create("Label");
    label:SetFullWidth(true);
    label:SetText(text);
    local background = label.frame:CreateTexture(nil, "BACKGROUND");
    background:SetBlendMode("BLEND");
    background:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight");
    background:SetAllPoints(label.frame);
    label:SetFontObject(GameFontHighlight);
    return label;
end

function Private.OpenSharedMacroWithData(data)
    ShowMacroMicro()
    Private.OpenSharedMacro(sharedMacroLabel, data);
end

function ResetSelectedMacro()
    -- Reset selected macro
    if selectedMacroLabel ~= nil then
        selectedMacroLabel:SetHighlight("Interface\\Buttons\\UI-Listbox-Highlight2");
        selectedMacroTexture:SetTexture(nil);
    end
    selectedMacroLabel = nil;
    selectedMacroId = nil;
end

function Private.OpenSharedMacro(label, data)
    ResetSelectedMacro();

    local macroName, macroTexture, macroBody = "", "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK", ""
    if data then
        macroName = data.macroName
        macroTexture = data.macroTexture
        macroBody = data.macroBody   
    end
    macroIcon:SetImage(macroTexture);
    if macroBody then
        macroBodyEditBox:SetText(macroBody);
    end
    macroNameEditBox:SetText(macroName);
    macroNameEditBox:SetFocus();
    SetMacroTypeRadioButtons();
end

function Print_Macros(macroIcon, macroNameEditBox, macroBodyEditBox)
    local scrollContainer = AceGUI:Create("InlineGroup") -- "InlineGroup" is also good
    scrollContainer:SetTitle("Macros");
    scrollContainer:SetWidth(200);
    scrollContainer:SetFullHeight(true); -- probably?
    scrollContainer:SetLayout("Fill") -- important!
        
    -- ... add your widgets to "scroll"
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List") -- probably?
    scroll:SetStatusTable(scrollStatusTable);
    scrollContainer:AddChild(scroll)
    
    local newButton = AceGUI:Create("Button");
    newButton:SetText("New Macro");
    --newButton:SetWidth(100);
    newButton:SetRelativeWidth(1);
    newButton:SetCallback("OnClick", function()
        Private.OpenSharedMacro(self, nil);
    end);
    
    local accountMacroList = AceGUI:Create("SimpleGroup");
    accountMacroList:AddChild(CreateMacroHeaderLabel("Account Macros"));

    local characterMacroList = AceGUI:Create("SimpleGroup");
    characterMacroList:AddChild(CreateMacroHeaderLabel("Character Macros"));

    if selectedMacroTexture == nil then 
        selectedMacroTexture = accountMacroList.frame:CreateTexture(nil, "BACKGROUND");
        selectedMacroTexture:SetBlendMode("ADD");
        selectedMacroTexture:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight2");
    end

    local accountMacroCount, characterMacroCount = GetNumMacros();

    if accountMacroCount == 0 then
        local noneAccountLabel = AceGUI:Create("Label");
        noneAccountLabel:SetFullWidth(true);
        noneAccountLabel:SetText("   None");
        noneAccountLabel:SetFontObject(GameFontHighlight);
        accountMacroList:AddChild(noneAccountLabel);
    end

    if characterMacroCount == 0 then
        local noneCharacterLabel = AceGUI:Create("Label");
        noneCharacterLabel:SetFullWidth(true);
        noneCharacterLabel:SetText("  None");
        noneCharacterLabel:SetFontObject(GameFontHighlight);
        characterMacroList:AddChild(noneCharacterLabel);
    end

    local maxMacroButtons = 138;
    for i=1, maxMacroButtons do
        name, texture, body = GetMacroInfo(i);
        
        if name ~= nil then
            local label = AceGUI:Create("InteractiveLabel");
            label:SetImage(texture);
            label:SetFullWidth(true);
            label:SetText(name);
            label:SetHighlight("Interface\\Buttons\\UI-Listbox-Highlight2");
            label:SetUserData("macroId", i);

            if selectedMacroId == i then
                selectedMacroLabel = label;
                selectedMacroTexture:SetAllPoints(label.frame);
            end

            label:SetCallback("OnClick", function(self)
                selectedMacroTexture:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight2");
                if (IsShiftKeyDown()) then
                    local name, texture, body = GetMacroInfo(self.userdata["macroId"]);
                
                    local editbox = GetCurrentKeyBoardFocus();
                    local fullName;
                    if(editbox) then
                        if (not fullName) then
                        local name, realm = UnitFullName("player")
                        if realm then
                            fullName = name.."-".. realm
                        else
                            fullName = name
                        end
                        end
                        
                        editbox:Insert("[MacroMicro: "..fullName.." - "..name.."]");
                        Private.linked = Private.linked or {}
                        Private.linked[name] = GetTime()
                    end
                else
                    -- Allow highlighting of the previously selected label
                    if selectedMacroLabel ~= nil then
                        selectedMacroLabel:SetHighlight("Interface\\Buttons\\UI-Listbox-Highlight2");
                    end
                    selectedMacroLabel = self;
                    local macroName, icon, body = GetMacroInfo(i);
                    macroIcon:SetImage(icon);
                    macroBodyEditBox:SetText(body);
                    macroBodyEditBox:Fire("OnTextChanged");
                    macroNameEditBox:SetText(macroName);
                    macroNameEditBox:Fire("OnTextChanged");
                    selectedMacroId = i;

                    SetMacroTypeRadioButtons(i)
                    
                    selectedMacroLabel:SetHighlight("");
                    selectedMacroTexture:SetAllPoints(self.frame);
                end
            end);
            
            -- Macro slot index to query. Slots 1 through 120 are general macros; 121 through 138 are per-character macros.
            if i < 121 then
                accountMacroList:AddChild(label);
            else
                characterMacroList:AddChild(label);
            end
        end
    end

    local separator = AceGUI:Create("Label");
    separator:SetText(" ");
    local separatorTexture = separator.frame:CreateTexture(nil, "BACKGROUND");
    
    separatorTexture:SetBlendMode("BLEND");
    separatorTexture:SetTexture("Interface/BUTTONS/WHITE8X8");

    scroll:AddChild(newButton);
    scroll:AddChild(CreateSeparatorLabel());
    scroll:AddChild(characterMacroList);
    scroll:AddChild(CreateSeparatorLabel());
    scroll:AddChild(accountMacroList);
    scroll:AddChild(CreateSeparatorLabel());
    return scrollContainer;
end

local tree = { 
    {
        value = "new",
        text = "New Macro"
    },
    {
      value = "character",
      text = "Character Macros",
      disabled = true,
      children = {}
    },
    { 
      value = "account", 
      text = "Account Macros",
      disabled = true,
      children = {}
    },
  };

function CreateSeparatorLabel()
    local label = AceGUI:Create("Label");
    label:SetText(" ");
    return label
end

function GenerateMacroTree()
    local characterMacros = {};
    local accountMacros = {};
    local maxMacroButtons = 138;
    for i=1, maxMacroButtons do
        name, texture, body = GetMacroInfo(i);
        
        if name ~= nil then
            local data = {
                value = i,
                text = name,
                icon = texture
            };
            if i < 121 then
                table.insert(accountMacros, data);
            else
                table.insert(characterMacros, data);
            end
        end
    end
    return characterMacros, accountMacros;
end

function Show_Options()
    if selectedMacroId == nil then
        selectedMacroId = 1;
    end
    frame = AceGUI:Create("Window");
    frame:SetStatusTable(fameStatusTable);
    -- Setting the frame to high as it was above the delete macro dialog box
    frame.frame:SetFrameStrata("HIGH");
    frame:SetTitle("MacroMicro");
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end);
    frame:SetLayout("Flow");

    -- local treeGroup = AceGUI:Create("TreeGroup");
    -- treeGroup:SetTree(tree);
    -- local treeGroupStatusTable = {};
    -- treeGroupStatusTable.scrollvalue = 0;
    -- treeGroup:SetStatusTable(treeGroupStatusTable);
    -- frame:AddChild(treeGroup);
    -- DevTools_Dump(treeGroup);

    local macroTreeContainer = AceGUI:Create("SimpleGroup");
    macroTreeContainer:SetLayout("Fill")
    macroTreeContainer:SetFullHeight(true); -- probably?
    frame:AddChild(macroTreeContainer)

    macroTree = AceGUI:Create("TreeGroup");
    macroTree:SetLayout("Flow");

    -- Expand groups by default
    macroTreeStatusTable.groups = macroTreeStatusTable.groups or {};
    macroTreeStatusTable.groups["character"] = true;
    macroTreeStatusTable.groups["account"] = true;
    macroTree:SetStatusTable(macroTreeStatusTable);
    
    local characterMacros, accountMacros = GenerateMacroTree();
    tree[2].children = characterMacros;
    tree[3].children = accountMacros;
    macroTree:SetTree(tree);
    macroTree:SetFullWidth(true);
    macroTree:SelectByValue(selectedMacroId);
    macroTree:SetCallback("OnGroupSelected", function(self)
        print("OnGroupSelected");
        -- Couldn't figure out how to get the actual value selected.
        -- Looked into the source code of TreeGroup and it delimits paths
        -- with "\001", so we can split on that and get the last value to
        -- get the macro index.
        local macroType, macroIndexString = ("\001"):split(macroTreeStatusTable.selected);
        if macroType == "new" then
            Private.OpenSharedMacro(self, nil);
            return
        end
        
        print(macroType);
        print(macroIndexString);
        local macroIndex = tonumber(macroIndexString);
        
        local macroName, icon, macroBody = GetMacroInfo(macroIndex);
        if (IsShiftKeyDown()) then
            local editbox = GetCurrentKeyBoardFocus();
            local fullName;
            if(editbox) then
                if (not fullName) then
                local name, realm = UnitFullName("player")
                if realm then
                    fullName = name.."-".. realm
                else
                    fullName = name
                end
                end
                
                editbox:Insert("[MacroMicro: "..fullName.." - "..macroName.."]");
                Private.linked = Private.linked or {}
                Private.linked[macroName] = GetTime()
            end
        else
            macroIcon:SetImage(icon);
            if macroBody then
                macroBodyEditBox:SetText(macroBody);
                macroBodyEditBox:Fire("OnTextChanged");
            end
            macroNameEditBox:SetText(macroName);
            macroNameEditBox:Fire("OnTextChanged");
            selectedMacroId = macroIndex;

            SetMacroTypeRadioButtons(macroIndex);
        end
    end);

    local newButton = AceGUI:Create("Button");
    newButton:SetText("New Macro");
    newButton:SetCallback("OnClick", function()
        Private.OpenSharedMacro(self, nil);
    end);

    --macroTreeContainer:AddChild(newButton);
    macroTreeContainer:SetFullWidth(true);
    macroTreeContainer:AddChild(macroTree);
    
    
    -- If we got a nil value for index, that means the macro doesn't exist.
    -- This might happen if you delete the bottom most macro.
    local macroName, macroTexture, macroBody = GetMacroInfo(selectedMacroId);
    if macroName == nil then
        selectedMacroId = 1;
    end
    local macroName, macroTexture, macroBody = GetMacroInfo(selectedMacroId);


    local macroTypeGroup = AceGUI:Create("SimpleGroup");
    macroTypeGroup:SetLayout("Flow");

    macroTypeRadioButtons.characterMacroRadioButton = AceGUI:Create("CheckBox");
    macroTypeRadioButtons.characterMacroRadioButton:SetLabel("Character Macro");
    macroTypeRadioButtons.characterMacroRadioButton:SetType("radio");
    macroTypeRadioButtons.characterMacroRadioButton:SetCallback("OnValueChanged", function(self)
        macroTypeRadioButtons.accountMacroRadioButton:SetValue(not self:GetValue())
    end)

    macroTypeRadioButtons.accountMacroRadioButton = AceGUI:Create("CheckBox");
    macroTypeRadioButtons.accountMacroRadioButton:SetLabel("Account Macro");
    macroTypeRadioButtons.accountMacroRadioButton:SetType("radio");
    macroTypeRadioButtons.accountMacroRadioButton:SetCallback("OnValueChanged", function(self)
        macroTypeRadioButtons.characterMacroRadioButton:SetValue(not self:GetValue())
    end)

    SetMacroTypeRadioButtons(selectedMacroId)

    macroTypeGroup:AddChild(macroTypeRadioButtons.characterMacroRadioButton);
    macroTypeGroup:AddChild(macroTypeRadioButtons.accountMacroRadioButton);

    macroNameEditBox = AceGUI:Create("EditBox");
    macroNameEditBox:SetLabel("Macro Name (0/16)");
    macroNameEditBox:SetWidth(200);
    macroNameEditBox:DisableButton(true);
    macroNameEditBox:SetMaxLetters(16);
    macroNameEditBox:SetCallback("OnTextChanged", function(self)
        self:SetLabel("Macro Name ("..string.len(macroNameEditBox:GetText()).."/16)");
    end);
    if macroName ~= nil then
        macroNameEditBox:SetText(macroName);
        macroNameEditBox:SetLabel("Macro Name ("..string.len(macroNameEditBox:GetText()).."/16)");
    end

    macroBodyEditBox = AceGUI:Create("MultiLineEditBox");
    macroBodyEditBox:SetLabel("Macro Body (0/255)");
    macroBodyEditBox:SetRelativeWidth(1);
    macroBodyEditBox:DisableButton(true);
    macroBodyEditBox:SetMaxLetters(255);
    macroBodyEditBox:SetNumLines(10);
    macroBodyEditBox:SetCallback("OnTextChanged", function(self)
        self:SetLabel("Macro Body ("..string.len(macroBodyEditBox:GetText()).."/255)");
    end);
    if macroName ~= nil then
        macroBodyEditBox:SetText(macroBody);
        macroBodyEditBox:Fire("OnTextChanged");
    end

    macroIcon = AceGUI:Create("Icon");
    macroIcon:SetImage("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK");
    macroIcon:SetImageSize(24, 24);
    macroIcon:SetCallback("OnClick", function(self)
        PickupMacro(selectedMacroId);
    end);
    if macroTexture ~= nil then
        macroIcon:SetImage(macroTexture);
    end

    local saveButton = AceGUI:Create("Button");
    saveButton:SetText("Save");
    saveButton:SetWidth(100);
    saveButton:SetCallback("OnClick", function()
        local newName = macroNameEditBox:GetText();
        local newBody = macroBodyEditBox:GetText();
        local macroType = GetMacroTypeSelected()
        if selectedMacroId then
            local _, currentIcon, _ = GetMacroInfo(selectedMacroId);
            -- Was the macro type changed from account to character or vice versa?
            if macroType == MacroTypeBasedOnIndex(selectedMacroId) then
                -- Macro type hasn't changed, just do an edit macro
                EditMacro(selectedMacroId, newName, currentIcon, newBody);
                ShowMacroMicro();
            else
                -- Macro type changed, delete and add new macro
                DeleteMacro(selectedMacroId);
                local isCharacterMacro = macroType == "character";
                selectedMacroId = CreateMacro(newName, currentIcon, newBody, isCharacterMacro);
                ShowMacroMicro();

                local path = macroType .. "\001" .. selectedMacroId;
                macroTree:SelectByPath(path);
            end
        else
            local isCharacterMacro = macroType == "character";
            -- 134400 is the question mark icon
            selectedMacroId = CreateMacro(newName, 134400, newBody, isCharacterMacro);
            ShowMacroMicro();
            
            local path = macroType .. "\001" .. selectedMacroId;
            macroTree:SelectByValue(path);
        end
    end);

    local deleteButton = AceGUI:Create("Button");
    deleteButton:SetText("Delete");
    deleteButton:SetWidth(100);
    deleteButton:SetCallback("OnClick", function()
        local currentMacroName, _, _ = GetMacroInfo(selectedMacroId);
        local dialog = StaticPopup_Show("DELETE_MACRO", currentMacroName);
        if (dialog) then
            dialog.macroId = selectedMacroId;
        end
    end)

    local shareButton = AceGUI:Create("Button");
    shareButton:SetText("Share");
    shareButton:SetWidth(100);
    shareButton:SetCallback("OnClick", function()
        local name, texture, body = GetMacroInfo(selectedMacroId);
        local message = "|Hitem:myAddonName:value1:value2|h[Click here!]|h";
    
        local editbox = GetCurrentKeyBoardFocus();
        local fullName;
        if(editbox) then
          if (not fullName) then
            local name, realm = UnitFullName("player")
            if realm then
              fullName = name.."-".. realm
            else
              fullName = name
            end
          end
          
          editbox:Insert("[MacroMicro: "..fullName.." - "..name.."]");
          Private.linked = Private.linked or {}
          Private.linked[name] = GetTime()
        end
    end)

    macroTree:AddChild(macroTypeGroup);
    macroTree:AddChild(macroNameEditBox);
    macroTree:AddChild(macroIcon);
    macroTree:AddChild(macroBodyEditBox);
    macroTree:AddChild(saveButton);
    macroTree:AddChild(deleteButton);
end 


SlashCmdList["MACROMICRO"] = function()
    ShowMacroMicro()
end
SLASH_MACROMICRO1 = "/macromicro";
SLASH_MACROMICRO2 = "/mm";


function ShowMacroMicro() 
    if frame and frame:IsVisible() then
        frame.frame:Hide()
    end
    Show_Options();
end
