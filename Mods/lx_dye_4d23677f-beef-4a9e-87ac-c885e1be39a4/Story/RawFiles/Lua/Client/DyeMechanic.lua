local currentItem

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

--- @param item EclItem
local function LookForItemColorBoost(item)
    if not item then return nil end
    local i = 1
    local itemColor
    while item.Stats.DynamicStats[i] do
        local color = item.Stats.DynamicStats[i].ItemColor
        if color ~= "" and not defaultDyes[color] then
            itemColor = item.Stats.DynamicStats[i].ItemColor
            break
        end
        i = i + 1 
    end
    return itemColor
end

--- Call this to dye an item if the dye already exists
--- @param item EclItem
--- @param dye string
--- @param fromPeer boolean Won't call the server for a refresh if true
function DyeItem(item, dye, fromPeer)
    if item.Stats.WeaponType or item.Stats.Slot then
        item.ItemColorOverride = dye
    end
    item.Stats.DynamicStats[1].ItemColor = dye
    item.Stats.StatsEntry.ItemGroup = ""
    if dye == "Default" then
        item.ItemColorOverride = ""
        item.Stats.DynamicStats[1].ItemColor = ""
        item.Stats.StatsEntry.ItemGroup = Ext.GetStat(item.StatsId).ItemGroup
    end
    if not fromPeer then
        -- Force refresh on the character sheet (doesn't work on possessed NPCs)
        local ui = Ext.GetBuiltinUI("Public/Game/GUI/characterSheet.swf")
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
--- @param fromPeer bool
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
        local ui = Ext.GetBuiltinUI("Public/Game/GUI/characterSheet.swf")
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
            InInventory = Ext.HandleToDouble(item.InventoryParentHandle) ~= 0
        }))
    end
end

-- All clients need to sync the dye calls
Ext.RegisterNetListener("DyeItemClient", function(call, payload)
    local infos = Ext.Json.Parse(payload)
    if infos.Dye == "CUSTOM" then
        DyeItemCustom(Ext.Entity.GetItem(tonumber(infos.Item)), infos.Colors[1], infos.Colors[2], infos.Colors[3], true)
    else
        DyeItem(Ext.Entity.GetItem(tonumber(infos.Item)), infos.Dye, true)
    end
    Ext.Net.PostMessageToServer("DyeItemApply", payload)
end)

Ext.RegisterNetListener("DyeSetup", function(call, payload)
    local items = Ext.Json.Parse(payload)
    -- Ext.Dump(items)
    for netid, color in pairs(items) do
        if string.match(color, "CUSTOM", 1) ~= null then
            local color = LookForItemColorBoost(Ext.Entity.GetItem(tonumber(netid)))
            if string.match(color, "CUSTOM", 1) ~= null then
                local color1 = string.gsub(color, "CUSTOM_", ""):gsub("-.*", "")
                local color2 = string.gsub(color, "CUSTOM_[0-9]+-", ""):gsub("-.*", "")
                local color3 = string.gsub(color, "CUSTOM_.*-", "")
                Ext.Stats.ItemColor.Update({Name = color, Color1 = color1, Color2 = color2, Color3 = color3})
            end
        end
        local item = Ext.Entity.GetItem(tonumber(netid))
        DyeItem(item, color, true)
    end
end)

--- Used to setup the first tab drop down menu
--- @param root UIObject
local function SetupBuiltinDyes(root)
    root.dyer_mc.colorSelector_mc.ddCombo_mc.removeAll()
    root.addEntry("Default", "Default", tonumber("0x00"), tonumber("0x00"), tonumber("0x00"))
    for i, infos, color in pairs (dyes) do
        root.addEntry(color, infos.Name, tonumber("0x"..infos.Colors[1]), tonumber("0x"..infos.Colors[2]), tonumber("0x"..infos.Colors[3]))
    end
end

--- Used to setup the second tab drop down menu
--- @param root UIObject
local function SetupCustomDyes(root)
    root.dyer_mc.colorSelector_mc.ddCombo_mc.removeAll()
    root.addEntry("Default", "Default", tonumber("0x00"), tonumber("0x00"), tonumber("0x00"))
    if GetTableSize(customDyesNames) > 0 then
        for i, colors, name in pairs(customDyesNames) do
            root.addEntry(name, name, tonumber("0x"..colors[1]), tonumber("0x"..colors[2]), tonumber("0x"..colors[3]))
        end
    end
end

local function SetupColorSelector(root, itemDye)
    root.dyer_mc.colorSelector_mc.ddCombo_mc.top_mc.text_txt.htmlText = ""
    root.dyer_mc.colorSelector_mc.ddCombo_mc.top_mc.cSet_mc.visible = false
    if not itemDye then
        root.dyer_mc.colorSelector_mc.cSet_mc.visible = false
        root.dyer_mc.colorSelector_mc.currentColor_txt.htmlText = "Default"
    elseif string.match(itemDye, "CUSTOM", 1) ~= null then
        root.dyer_mc.colorSelector_mc.cSet_mc.visible = true
        local cSet = Ext.Stats.ItemColor.Get(itemDye)
        -- if not cSet then
        --     Ext.Stats.ItemColor.Update()
        ChangeDyerMcColors("Custom", {
            string.format("%x", cSet.Color1),
            string.format("%x", cSet.Color2),
            string.format("%x", cSet.Color3)
        })
    -- else
    --     root.dyer_mc.colorSelector_mc.cSet_mc.visible = true
    --     local cSet = dyes[itemDye]
    --     ChangeDyerMcColors(cSet.Name, cSet.Colors)
    end
end

--- @param root UIObject
--- @param item EclItem
local function SetupActiveTab(root, item)
    local itemDye = LookForItemColorBoost(currentItem)
    if root.dyer_mc.tabButton1_mc.activated then
        SetupBuiltinDyes(root)
        SetupColorSelector(root, itemDye)
    elseif root.dyer_mc.tabButton2_mc then
        SetupCustomDyes(root)
        SetupColorSelector(root, itemDye)
    elseif root.dyer_mc.tabButton3_mc then
    end
end

local function ApplyDyeButtonPressed(root)
    if root.dyer_mc.colorSelector_mc.visible then
        local dye = root.dyer_mc.colorSelector_mc.ddCombo_mc.color_id
        if not Ext.Stats.ItemColor.Get(dye) then
            local color1 = string.gsub(color, "CUSTOM_", ""):gsub("-.*", "")
            local color2 = string.gsub(color, "CUSTOM_[0-9]+-", ""):gsub("-.*", "")
            local color3 = string.gsub(color, "CUSTOM_.*-", "")
            Ext.Stats.ItemColor.Update({Name = color, Color1 = color1, Color2 = color2, Color3 = color3})
        end
        _D(dye)
        DyeItem(currentItem, dye)

        if dye == "Default" then
            ChangeDyerMcColors("Default", {"000000", "000000", "000000"})
            return
        end
        local cSet = Ext.Stats.ItemColor.Get(dye)
        local name = ""
        if string.match(dye, "CUSTOM", 1) ~= null then
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
        DyeItemCustom(currentItem, primary, secondary, tertiary)
    end
end

--- @param item EclItem
function PrepareDye(item)
    currentItem = item
    local ui = Ext.GetUI("LXN_Dye")
    ui:SetCustomIcon("dye_equipment", item.RootTemplate.Icon, 57, 57)
    local root = ui:GetRoot()
    root.dyer_mc.equipment_txt.htmlText = item.DisplayName or item.CustomDisplayName
    root.dyer_mc.visible = true
    SetupActiveTab(root, item)
end

Ext.Events.SessionLoaded:Subscribe(function(e)
    if Ext.Utils.GameVersion() == "v3.6.51.9303" then return end
    Ext.UI.Create("LXN_Dye", "Public/lx_dye_4d23677f-beef-4a9e-87ac-c885e1be39a4/Game/GUI/dye.swf", 10)
    local ui = Ext.UI.GetByName("LXN_Dye")
    local root = ui:GetRoot()
    root.dyer_mc.visible = false
    root.dyer_mc.tabButton1_mc.text_txt.htmlText = "Standard"
    root.dyer_mc.tabButton2_mc.text_txt.htmlText = "Saved"
    root.dyer_mc.tabButton3_mc.text_txt.htmlText = "Create"
    root.dyer_mc.tabButton1_mc.setActive()
    root.dyer_mc.colorMaker_mc.visible = false
    SetupBuiltinDyes(root)

    Ext.RegisterUICall(ui, "dye_setTab", function(arg1, call, tab)
        local ui = Ext.UI.GetByName("LXN_Dye")
        local root = ui:GetRoot()
        SetupActiveTab(root, current)
    end)
    
    Ext.RegisterUICall(ui, "dye_apply", function(...)
        local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
        ApplyDyeButtonPressed(root)
    end)
    Ext.RegisterUICall(ui, "dye_close", function(...)
        local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
        currentItem = nil
        root.dyer_mc.visible = false
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
        root.dyer_mc.colorMaker_mc.activated_mc.red = value
        root.dyer_mc.colorMaker_mc.activated_mc.cSquare_mc.changeColor(
            ((root.dyer_mc.colorMaker_mc.activated_mc.red & 0x0ff)<<16|
            ((root.dyer_mc.colorMaker_mc.activated_mc.green & 0x0ff)<<8)|
            (root.dyer_mc.colorMaker_mc.activated_mc.blue & 0x0ff))
        )
        root.dyer_mc.colorMaker_mc.redValue_txt.htmlText = value
    end)
    Ext.RegisterUICall(ui, "dye_greenSlider", function(ui, call, value)
        local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
        root.dyer_mc.colorMaker_mc.activated_mc.green = value
        root.dyer_mc.colorMaker_mc.activated_mc.cSquare_mc.changeColor(
            ((root.dyer_mc.colorMaker_mc.activated_mc.red & 0x0ff)<<16|
            ((root.dyer_mc.colorMaker_mc.activated_mc.green & 0x0ff)<<8)|
            (root.dyer_mc.colorMaker_mc.activated_mc.blue & 0x0ff))
        )
        root.dyer_mc.colorMaker_mc.greenValue_txt.htmlText = value
    end)
    Ext.RegisterUICall(ui, "dye_blueSlider", function(ui, call, value)
        local root = Ext.UI.GetByName("LXN_Dye"):GetRoot()
        root.dyer_mc.colorMaker_mc.activated_mc.blue = value
        root.dyer_mc.colorMaker_mc.activated_mc.cSquare_mc.changeColor(
            ((root.dyer_mc.colorMaker_mc.activated_mc.red & 0x0ff)<<16|
            ((root.dyer_mc.colorMaker_mc.activated_mc.green & 0x0ff)<<8)|
            (root.dyer_mc.colorMaker_mc.activated_mc.blue & 0x0ff))
        )
        root.dyer_mc.colorMaker_mc.blueValue_txt.htmlText = value
    end)
end)

Ext.RegisterListener("GameStateChanged", function(fromState, toState)
    if toState == "Running" and fromState ~= "GameMasterPause" then
        Ext.Net.PostMessageToServer("DyeFetchList", "")
    end
end)

