local AddonName, Private = ...

MacroMicro = {}
local AddonObject = LibStub("AceAddon-3.0"):NewAddon("MacroMicro", "AceConsole-3.0");
function MacroMicro.IsRetail()
    -- Hard coded for now. Used by SpellCache
    return false;
end

function AddonObject:OnInitialize()
    -- Code that you want to run when the addon is first loaded goes here.
  end

function AddonObject:OnEnable()
    MacroMicroSaved = MacroMicroSaved or {};
    MacroMicroSaved.spellCache = MacroMicroSaved.spellCache or {};
    MacroMicroSaved.dynamicIconCache = MacroMicroSaved.dynamicIconCache or {};

    MacroMicro.spellCache.Load(MacroMicroSaved);
end

function AddonObject:OnDisable()
    -- Called when the addon is disabled
end

-- Handle coroutines
local dynFrame = {};
Private.dynFrame = dynFrame;

function Private.ValueToPath(data, path, value)
    if not data then
      return
    end
    if(#path == 1) then
      data[path[1]] = value;
    else
      local reducedPath = {};
      for i=2,#path do
        reducedPath[i-1] = path[i];
      end
      Private.ValueToPath(data[path[1]], reducedPath, value);
    end
  end


do
  -- Internal data
  dynFrame.frame = CreateFrame("Frame");
  dynFrame.update = {};
  dynFrame.size = 0;

  -- Add an action to be resumed via OnUpdate
  function dynFrame.AddAction(self, name, func)
    if not name then
      name = string.format("NIL", dynFrame.size+1);
    end

    if not dynFrame.update[name] then
      dynFrame.update[name] = func;
      dynFrame.size = dynFrame.size + 1
      dynFrame.frame:Show();
    end
  end

  -- Remove an action from OnUpdate
  function dynFrame.RemoveAction(self, name)
    if dynFrame.update[name] then
      dynFrame.update[name] = nil;
      dynFrame.size = dynFrame.size - 1
      if dynFrame.size == 0 then
        dynFrame.frame:Hide();
      end
    end
  end

  -- Setup frame
  dynFrame.frame:Hide();
  dynFrame.frame:SetScript("OnUpdate", function(self, elapsed)
    -- Start timing
    local start = debugprofilestop();
    local hasData = true;

    -- Resume as often as possible (Limit to 16ms per frame -> 60 FPS)
    while (debugprofilestop() - start < 16 and hasData) do
      -- Stop loop without data
      hasData = false;

      -- Resume all coroutines
      for name, func in pairs(dynFrame.update) do
        -- Loop has data
        hasData = true;

        -- Resume or remove
        if coroutine.status(func) ~= "dead" then
          local ok, msg = coroutine.resume(func)
          if not ok then
            geterrorhandler()(msg .. '\n' .. debugstack(func))
          end
        else
          dynFrame:RemoveAction(name);
        end
      end
    end
  end);
end