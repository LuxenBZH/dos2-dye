---@diagnostic disable: param-type-mismatch
local currentItem
local contextCharacter

--- Update the drop down menu colors and name
--- @param name string Name of the dye
--- @param colors integer[] Colors of the dye in integer format
local function ChangeDyerMcColors(name, colors)
    local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
    root.dyer_mc.colorSelector_mc.cSet_mc.visible = true
    root.dyer_mc.colorSelector_mc.cSet_mc.changePartColor(0, tonumber("0x"..colors[1]))
    root.dyer_mc.colorSelector_mc.cSet_mc.changePartColor(1, tonumber("0x"..colors[2]))
    root.dyer_mc.colorSelector_mc.cSet_mc.changePartColor(2, tonumber("0x"..colors[3]))
    root.dyer_mc.colorSelector_mc.currentColor_txt.htmlText = name
    if name == "Default" then
        root.dyer_mc.colorSelector_mc.cSet_mc.visible = false
    end
end

--- Call this to dye an item if the dye already exists
--- @param item EclItem
--- @param dye string
--- @param fromPeer boolean | nil Won't call the server for a refresh if true
function DyeItem(item, dye, fromPeer)
    if item.Stats.WeaponType or item.Stats.Slot then
        item.ItemColorOverride = dye
    end
    item.Stats.DynamicStats[1].ItemColor = dye
    item.Stats.StatsEntry.ItemGroup = ""
    if dye == "Default" then
        item.ItemColorOverride = "" 
        for i=1, #item.Stats.DynamicStats, 1 do
            item.Stats.DynamicStats[i].ItemColor = ""
        end
        item.Stats.DynamicStats[1].ItemColor = ""
        item.Stats.StatsEntry.ItemGroup = Ext.GetStat(item.StatsId).ItemGroup
    end
    if not fromPeer then
        -- Force refresh on the character sheet (doesn't work on possessed NPCs)
        local ui = Ext.UI.GetByPath("Public/Game/GUI/characterSheet.swf")
        local root = ui:GetRoot()
        local helmet = root.stats_mc.equip_mc.helmet_mc.stateID
        if helmet == 0 then
            ui:ExternalInterfaceCall("setHelmetOption", 1)
            ui:ExternalInterfaceCall("setHelmetOption", 0)
        else
            ui:ExternalInterfaceCall("setHelmetOption", 0)
            ui:ExternalInterfaceCall("setHelmetOption", 1)
        end
        Ext.Net.PostMessageToServer("DyeItem", Ext.Json.Stringify({
            Item = item.NetID,
            Dye = dye,
            InInventory = Ext.UI.HandleToDouble(item.InventoryParentHandle) ~= 0
        }))
    end
end

--- Call this to dye an item from a custom input
--- @param item EclItem
--- @param primary integer
--- @param secondary integer
--- @param tertiary integer
--- @param fromPeer boolean | nil
local function DyeItemCustom(item, primary, secondary, tertiary, fromPeer)
    for dye, colors in pairs(customDyes) do
        if colors[1] == primary and colors[2] == secondary and colors[3] == tertiary then
            DyeItem(item, dye, false)
            return
        end
    end
    --- Would a 72 bits (24*3) number as the index be better ?
    local dye = "CUSTOM_"..tostring(primary).."-"..tostring(secondary).."-"..tostring(tertiary)
    customDyes[dye] = {primary, secondary, tertiary}
    Ext.Stats.ItemColor.Update({Name=dye, Color1=primary, Color2=secondary, Color3=tertiary})
    if item.Stats.WeaponType or item.Stats.Slot then
        item.ItemColorOverride = dye
    end
    item.Stats.DynamicStats[1].ItemColor = dye
    item.Stats.StatsEntry.ItemGroup = ""
    if not fromPeer then
        -- Force refresh on the character sheet (doesn't work on possessed NPCs)
        local ui = Ext.UI.GetByPath("Public/Game/GUI/characterSheet.swf")
        local root = ui:GetRoot()
        local helmet = root.stats_mc.equip_mc.helmet_mc.stateID
        if helmet == 0 then
            ui:ExternalInterfaceCall("setHelmetOption", 1)
            ui:ExternalInterfaceCall("setHelmetOption", 0)
        else
            ui:ExternalInterfaceCall("setHelmetOption", 0)
            ui:ExternalInterfaceCall("setHelmetOption", 1)
        end
        Ext.Net.PostMessageToServer("DyeItem", Ext.Json.Stringify({
            Item = item.NetID,
            Dye = "CUSTOM",
            Colors = {primary, secondary, tertiary},
            InInventory = Ext.UI.HandleToDouble(item.InventoryParentHandle) ~= 0
        }))
    end
end

-- All clients need to sync the dye calls
Ext.RegisterNetListener("DyeItemClient", function(call, payload)
    local infos = Ext.Json.Parse(payload)
    if string.match(infos.Dye, "CUSTOM", 1) then
        local colors = GetColorFromCustomDyeName(infos.Dye)
        DyeItemCustom(Ext.Entity.GetItem(tonumber(infos.Item)), colors.Color1, colors.Color2, colors.Color3, true)
    else
        DyeItem(Ext.Entity.GetItem(tonumber(infos.Item)), infos.Dye, true)
    end
    Ext.Net.PostMessageToServer("DyeItemApply", payload)
end)

--- Used to setup the first tab drop down menu
--- @param root any|UIObject
local function SetupBuiltinDyes(root)
    root.dyer_mc.colorSelector_mc.ddCombo_mc.removeAll()
    root.addEntry("Default", "Default", tonumber("0x00"), tonumber("0x00"), tonumber("0x00"))
    for i, infos, color in pairs (dyes) do
        root.addEntry(color, infos.Name, tonumber("0x"..infos.Colors[1]), tonumber("0x"..infos.Colors[2]), tonumber("0x"..infos.Colors[3]))
    end
end

--- Used to setup the second tab drop down menu
--- @param root any|UIObject
local function SetupCustomDyes(root)
    root.dyer_mc.colorSelector_mc.ddCombo_mc.removeAll()
    root.addEntry("Default", "Default", tonumber("0x00"), tonumber("0x00"), tonumber("0x00"))
    if GetTableSize(customDyesNames) > 0 then
        for i, colors, name in pairs(customDyesNames) do
            root.addEntry(name, name, tonumber("0x"..colors[1]), tonumber("0x"..colors[2]), tonumber("0x"..colors[3]))
        end
    end
end

---@param root any|UIObject
---@param itemDye string
local function SetupColorSelector(root, itemDye)
    root.dyer_mc.colorSelector_mc.ddCombo_mc.top_mc.text_txt.htmlText = ""
    root.dyer_mc.colorSelector_mc.ddCombo_mc.top_mc.cSet_mc.visible = false
    if not itemDye or itemDye == "" or itemDye == "DefaultGray" then
        root.dyer_mc.colorSelector_mc.cSet_mc.visible = false
        root.dyer_mc.colorSelector_mc.currentColor_txt.htmlText = "Default"
    elseif string.match(itemDye, "CUSTOM", 1) then
        root.dyer_mc.colorSelector_mc.cSet_mc.visible = true
        if not Ext.Stats.ItemColor.Get(itemDye) then
            Ext.Stats.ItemColor.Update(GetColorFromCustomDyeName(itemDye))
        end
        local cSet = Ext.Stats.ItemColor.Get(itemDye)
        ChangeDyerMcColors("Custom", {
            string.format("%x", cSet.Color1),
            string.format("%x", cSet.Color2),
            string.format("%x", cSet.Color3)
        })
    else
        root.dyer_mc.colorSelector_mc.cSet_mc.visible = true
        local cSet = dyes[itemDye]
        if not cSet then
            root.dyer_mc.colorSelector_mc.cSet_mc.visible = false
            root.dyer_mc.colorSelector_mc.currentColor_txt.htmlText = "Default"
            return
        end
        ChangeDyerMcColors(cSet.Name, cSet.Colors)
    end
end

--- @param root any|UIObject
--- @param item EclItem
local function SetupActiveTab(root, item)
    local itemDye = LookForItemColorBoost(Ext.Entity.GetItem(currentItem))
    if root.dyer_mc.tabButton1_mc.activated then
        SetupBuiltinDyes(root)
        SetupColorSelector(root, itemDye)
    elseif root.dyer_mc.tabButton2_mc then
        SetupCustomDyes(root)
        SetupColorSelector(root, itemDye)
    end
end

--- @param root any|UIObject
local function ApplyDyeButtonPressed(root)
    if root.dyer_mc.colorSelector_mc.visible then
        local dye = root.dyer_mc.colorSelector_mc.ddCombo_mc.color_id
        local name = ""
        if customDyesNames[dye] then
            name = "CUSTOM_"..tonumber("0x"..customDyesNames[dye][1]).."-"..tonumber("0x"..customDyesNames[dye][2]).."-"..tonumber("0x"..customDyesNames[dye][3])
            if not Ext.Stats.ItemColor.Get(name) then
                Ext.Stats.ItemColor.Update(GetColorFromCustomDyeName(name))
            end
        end
        local cSet = Ext.Stats.ItemColor.Get(dye)
        if name ~= "" then
            DyeItem(Ext.Entity.GetItem(currentItem), name)
            cSet = Ext.Stats.ItemColor.Get(name)
        else
            DyeItem(Ext.Entity.GetItem(currentItem), dye)
        end

        if dye == "Default" then
            ChangeDyerMcColors("Default", {"000000", "000000", "000000"})
            return
        end
        
        if string.match(name, "CUSTOM", 1) then
            name = "Custom"
        else
            name = dyes[dye].Name
        end
        ChangeDyerMcColors(name, {
            string.format("%x", cSet.Color1),
            string.format("%x", cSet.Color2),
            string.format("%x", cSet.Color3)
        })
    elseif root.dyer_mc.colorMaker_mc.visible then
        local primary = ((root.dyer_mc.colorMaker_mc.colorButton1_mc.red & 0x0ff)<<16|
                        ((root.dyer_mc.colorMaker_mc.colorButton1_mc.green & 0x0ff)<<8)|
                        (root.dyer_mc.colorMaker_mc.colorButton1_mc.blue & 0x0ff))
        local secondary = ((root.dyer_mc.colorMaker_mc.colorButton2_mc.red & 0x0ff)<<16|
                        ((root.dyer_mc.colorMaker_mc.colorButton2_mc.green & 0x0ff)<<8)|
                        (root.dyer_mc.colorMaker_mc.colorButton2_mc.blue & 0x0ff))
        local tertiary = ((root.dyer_mc.colorMaker_mc.colorButton3_mc.red & 0x0ff)<<16|
                        ((root.dyer_mc.colorMaker_mc.colorButton3_mc.green & 0x0ff)<<8)|
                        (root.dyer_mc.colorMaker_mc.colorButton3_mc.blue & 0x0ff))
        DyeItemCustom(Ext.Entity.GetItem(currentItem), primary, secondary, tertiary, false)
    end
end

--- @param item EclItem
function PrepareDye(item)
    currentItem = item.NetID
    local ui = Ext.UI.GetByName("LXN_Dye")
    ui:SetCustomIcon("dye_equipment", item.RootTemplate.Icon, 57, 57)
    local root = ui:GetRoot()
    root.dyer_mc.equipment_txt.htmlText = item.DisplayName or item.CustomDisplayName
    ui:Show()
    SetupActiveTab(root, item)
end

Ext.Events.SessionLoaded:Subscribe(function(e)
    if Ext.Utils.GameVersion() == "v3.6.51.9303" then return end
    Ext.UI.Create("LXN_Dye", "Public/lx_dye_4d23677f-beef-4a9e-87ac-c885e1be39a4/Game/GUI/dye.swf", 10)
    local ui = Ext.UI.GetByName("LXN_Dye")
    local root = ui:GetRoot()
    ui:Hide()
    root.dyer_mc.tabButton1_mc.text_txt.htmlText = "Standard"
    root.dyer_mc.tabButton2_mc.text_txt.htmlText = "Saved"
    root.dyer_mc.tabButton3_mc.text_txt.htmlText = "Create"
    root.dyer_mc.tabButton1_mc.setActive()
    root.dyer_mc.colorMaker_mc.visible = false
    root.dyer_mc.colorSelector_mc.delete_mc.ext_callback = "delete"
    SetupBuiltinDyes(root)

    Ext.RegisterUICall(ui, "dye_setTab", function(arg1, call, tab)
        local ui = Ext.UI.GetByName("LXN_Dye")
        local root = ui:GetRoot()
        SetupActiveTab(root, Ext.Entity.GetItem(currentItem))
    end)
    
    Ext.RegisterUICall(ui, "dye_apply", function(...)
        local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
        ApplyDyeButtonPressed(root)
    end)
    Ext.RegisterUICall(ui, "dye_close", function(ui, ...)
        ui:Hide()
    end)
    Ext.RegisterUICall(ui, "dye_tab2", function(...)
        local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
        root.dyer_mc.colorSelector_mc.delete_mc.visible = true
    end)
    Ext.RegisterUICall(ui, "dye_tab1", function(...)
        local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
        root.dyer_mc.colorSelector_mc.delete_mc.visible = false
    end)
    Ext.RegisterUICall(ui, "dye_redSlider", function(ui, call, value)
        local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
        local activated_mc = root.dyer_mc.colorMaker_mc.activated_mc
        activated_mc.red = value
        root.dyer_mc.colorMaker_mc.activated_mc.cSquare_mc.changeColor(
            GetRGBInteger(
                activated_mc.red,
                activated_mc.green,
                activated_mc.blue
            )
        )
        root.dyer_mc.colorMaker_mc.redValue_txt.htmlText = value
    end)
    Ext.RegisterUICall(ui, "dye_greenSlider", function(ui, call, value)
        local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
        local activated_mc = root.dyer_mc.colorMaker_mc.activated_mc
        activated_mc.green = value
        root.dyer_mc.colorMaker_mc.activated_mc.cSquare_mc.changeColor(
            GetRGBInteger(
                activated_mc.red,
                activated_mc.green,
                activated_mc.blue
            )
        )
        root.dyer_mc.colorMaker_mc.greenValue_txt.htmlText = value
    end)
    Ext.RegisterUICall(ui, "dye_blueSlider", function(ui, call, value)
        local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
        local activated_mc = root.dyer_mc.colorMaker_mc.activated_mc
        activated_mc.blue = value
        root.dyer_mc.colorMaker_mc.activated_mc.cSquare_mc.changeColor(
            GetRGBInteger(
                activated_mc.red,
                activated_mc.green,
                activated_mc.blue
            )
        )
        root.dyer_mc.colorMaker_mc.blueValue_txt.htmlText = value
    end)
    Ext.RegisterUICall(ui, "dye_save", function(...)
        local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
        local colorMaker_mc = root.dyer_mc.colorMaker_mc
        OpenInputBox("Save Dye as:", "", 5101, Ext.Json.Stringify({
            Color1 = GetRGBInteger(
                colorMaker_mc.colorButton1_mc.red, 
                colorMaker_mc.colorButton1_mc.green,
                colorMaker_mc.colorButton1_mc.blue
            ),
            Color2 = GetRGBInteger(
                colorMaker_mc.colorButton2_mc.red, 
                colorMaker_mc.colorButton2_mc.green,
                colorMaker_mc.colorButton2_mc.blue
            ),
            Color3 = GetRGBInteger(
                colorMaker_mc.colorButton3_mc.red, 
                colorMaker_mc.colorButton3_mc.green,
                colorMaker_mc.colorButton3_mc.blue
            ),
        }))
    end)
    Ext.RegisterUICall(ui, "dye_delete", function(...)
        local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
        local top_mc = root.dyer_mc.colorSelector_mc.ddCombo_mc.top_mc
        if top_mc.text_txt.htmlText ~= "Default" then
            RemoveCustomDye(top_mc.text_txt.htmlText)
            local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
            SetupActiveTab(root, Ext.Entity.GetItem(currentItem))
        end
    end)

    -- Track followers in GM mode
    if Ext.Utils.GetGameMode() == "GameMaster" then
        Ext.Events.InputEvent:Subscribe(function(e)
            if e.Event.EventId == 2 then
                contextCharacter = Ext.UI.GetPickingState().HoverCharacter
            end
        end)
        Ext.RegisterUITypeCall(11, "buttonPressed", function(ui, event, id, actionID, handle)
            if id == 3 and actionID == 56 and contextCharacter then
                Ext.Net.PostMessageToServer("DyeTagFollower", Ext.Json.Stringify({
                    Character = Ext.Entity.GetCharacter(contextCharacter).NetID
                }))
            end
        end)
    end
end)

Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.ToState == "PrepareRunning" and e.FromState ~= "Running" then
        Ext.Net.PostMessageToServer("DyeFetchList", "")
    end
end)

-- Executed on client startup
Ext.RegisterNetListener("DyeSetup", function(call, payload)
    local items = Ext.Json.Parse(payload)
    for netid, color in pairs(items) do
        if string.match(color, "CUSTOM", 1) then
            Ext.Stats.ItemColor.Update(GetColorFromCustomDyeName(color))
        end
        local item = Ext.ClientEntity.GetItem(tonumber(netid))
        DyeItem(item, color, false)
    end
end)