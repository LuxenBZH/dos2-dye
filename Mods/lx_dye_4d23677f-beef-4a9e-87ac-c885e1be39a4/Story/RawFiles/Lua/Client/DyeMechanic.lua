local currentItem

local function ChangeDyerMcColors(name, colors)
    local root = Ext.GetUI("LXN_Dye"):GetRoot()
    root.dyer_mc.colorSelector_mc.cSet_mc.visible = true
    root.dyer_mc.colorSelector_mc.cSet_mc.changePartColor(0, tonumber("0x"..colors[1]))
    root.dyer_mc.colorSelector_mc.cSet_mc.changePartColor(1, tonumber("0x"..colors[2]))
    root.dyer_mc.colorSelector_mc.cSet_mc.changePartColor(2, tonumber("0x"..colors[3]))
    root.dyer_mc.colorSelector_mc.currentColor_txt.htmlText = name
    root.dyer_mc.colorSelector_mc.ddCombo_mc.top_mc.text_txt.htmlText = tostring(name)
    if name == "Default" then
        root.dyer_mc.colorSelector_mc.cSet_mc.visible = false
    end
end

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

--- @param item EclItem
function PrepareDye(item)
    currentItem = item
    local ui = Ext.GetUI("LXN_Dye")
    ui:SetCustomIcon("dye_equipment", item.RootTemplate.Icon, 57, 57)
    local root = ui:GetRoot()
    root.dyer_mc.equipment_txt.htmlText = item.DisplayName or item.CustomDisplayName
    local itemDye = LookForItemColorBoost(item)
    root.dyer_mc.visible = true
    if root.dyer_mc.tabButton1_mc.activated then
        if not itemDye then
            root.dyer_mc.colorSelector_mc.cSet_mc.visible = false
            root.dyer_mc.colorSelector_mc.currentColor_txt.htmlText = "Default"
        else
            root.dyer_mc.colorSelector_mc.cSet_mc.visible = true
            local cSet = dyes[itemDye]
            ChangeDyerMcColors(cSet.Name, cSet.Colors)
        end
    end
end

---@param item EclItem
function DyeItem(item, dye)
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
    Ext.PostMessageToServer("DyeItem", Ext.JsonStringify({
        Item = item.NetID,
        Dye = dye,
        InInventory = Ext.HandleToDouble(item.InventoryParentHandle) ~= 0
    }))
end

---@param item EclItem
---@param tooltip TooltipData
local function EquipmentTooltips(item, tooltip)
    if tooltip == nil then return end
	-- if item.ItemType ~= "Weapon" then return end
    if item.Stats then
        local dye = LookForItemColorBoost(item)
        if dye and dye ~= "Default" then
            local description = tooltip:GetElement("ItemDescription")
            description.Label = description.Label.."\nDye : <font color=\""..dyes[dye].Colors[1].."\">"..dyes[dye].Name.."</font>"
        end
    end
end

local function LXN_Tooltips_Dye_Init()
    Game.Tooltip.RegisterListener("Item", nil, EquipmentTooltips)
end

Ext.RegisterListener("SessionLoaded", LXN_Tooltips_Dye_Init)

Ext.RegisterNetListener("DyeSetup", function(call, payload)
    local items = Ext.JsonParse(payload)
    Ext.Dump(items)
    for netid, color in pairs(items) do
        local item = Ext.GetItem(tonumber(netid))
        Ext.Print(item, color)
        DyeItem(item, color)
    end
end)

--- @param root UIObject
local function SetupBuiltinDyes(root)
    for i, infos, color in pairs (dyes) do
        root.addEntry(color, infos.Name, tonumber("0x"..infos.Colors[1]), tonumber("0x"..infos.Colors[2]), tonumber("0x"..infos.Colors[3]))
    end
end

--- @param root UIObject
--- @param item EclItem
local function SetupActiveTab(root, item)
    local itemDye = LookForItemColorBoost(currentItem)
    if root.dyer_mc.tabButton1_mc.activated then
        SetupBuiltinDyes(root)
        if not itemDye then
            root.dyer_mc.colorSelector_mc.cSet_mc.visible = false
            root.dyer_mc.colorSelector_mc.currentColor_txt.htmlText = "Default"
        else
            root.dyer_mc.colorSelector_mc.cSet_mc.visible = true
            local cSet = dyes[itemDye]
            ChangeDyerMcColors(cSet.Name, cSet.Colors)
        end
    elseif root.dyer_mc.tabButton2_mc then
    elseif root.dyer_mc.tabButton3_mc then
    end
end

local function ApplyDyeButtonPressed(root)
    if root.dyer_mc.colorSelector_mc.visible then
        local dye = root.dyer_mc.colorSelector_mc.ddCombo_mc.color_id
        Ext.Print(dye)
        DyeItem(currentItem, dye)
        if dye == "Default" then
            ChangeDyerMcColors("Default", {"000000", "000000", "000000"})
            return
        end
        local cSet = dyes[dye]
        ChangeDyerMcColors(cSet.Name, cSet.Colors)
    end
end

Ext.RegisterListener("SessionLoaded", function()
    if Ext.GameVersion() == "v3.6.51.9303" then return end
    Ext.CreateUI("LXN_Dye", "Public/lx_dye_4d23677f-beef-4a9e-87ac-c885e1be39a4/Game/GUI/dye.swf", 10)
    local ui = Ext.GetUI("LXN_Dye")
    local root = ui:GetRoot()
    root.addEntry("Default", "Default", tonumber("0x00"), tonumber("0x00"), tonumber("0x00"))
    root.dyer_mc.visible = false
    root.dyer_mc.tabButton1_mc.text_txt.htmlText = "Standard"
    root.dyer_mc.tabButton2_mc.text_txt.htmlText = "Saved"
    root.dyer_mc.tabButton3_mc.text_txt.htmlText = "Create"
    root.dyer_mc.tabButton1_mc.setActive()
    root.dyer_mc.colorMaker_mc.visible = false
    SetupBuiltinDyes(root)

    Ext.RegisterUICall(ui, "dye_setTab", function(arg1, call, tab)
        Ext.Print(tab)
        local ui = Ext.GetUI("LXN_Dye")
        local root = ui:GetRoot()
        SetupActiveTab(root, current)
    end)
    
    Ext.RegisterUICall(ui, "dye_apply", function(...)
        local root = Ext.GetUI("LXN_Dye"):GetRoot()
        ApplyDyeButtonPressed(root)
    end)
    Ext.RegisterUICall(ui, "dye_close", function(...)
        local root = Ext.GetUI("LXN_Dye"):GetRoot()
        currentItem = nil
        root.dyer_mc.visible = false
    end)
    Ext.RegisterUICall(ui, "dye_tab2", function(...)
        local root = Ext.GetUI("LXN_Dye"):GetRoot()
        root.dyer_mc.colorSelector_mc.delete_mc.visible = true
    end)
    Ext.RegisterUICall(ui, "dye_tab1", function(...)
        local root = Ext.GetUI("LXN_Dye"):GetRoot()
        root.dyer_mc.colorSelector_mc.delete_mc.visible = false
    end)
    Ext.RegisterUICall(ui, "dye_redSlider", function(ui, call, value)
        local root = Ext.GetUI("LXN_Dye"):GetRoot()
        root.dyer_mc.colorMaker_mc.activated_mc.red = value
        root.dyer_mc.colorMaker_mc.activated_mc.cSquare_mc.changeColor(
            ((root.dyer_mc.colorMaker_mc.activated_mc.red & 0x0ff)<<16|
            ((root.dyer_mc.colorMaker_mc.activated_mc.green & 0x0ff)<<8)|
            (root.dyer_mc.colorMaker_mc.activated_mc.blue & 0x0ff))
        )
        root.dyer_mc.colorMaker_mc.redValue_txt.htmlText = value
    end)
    Ext.RegisterUICall(ui, "dye_greenSlider", function(ui, call, value)
        local root = Ext.GetUI("LXN_Dye"):GetRoot()
        root.dyer_mc.colorMaker_mc.activated_mc.green = value
        root.dyer_mc.colorMaker_mc.activated_mc.cSquare_mc.changeColor(
            ((root.dyer_mc.colorMaker_mc.activated_mc.red & 0x0ff)<<16|
            ((root.dyer_mc.colorMaker_mc.activated_mc.green & 0x0ff)<<8)|
            (root.dyer_mc.colorMaker_mc.activated_mc.blue & 0x0ff))
        )
        root.dyer_mc.colorMaker_mc.greenValue_txt.htmlText = value
    end)
    Ext.RegisterUICall(ui, "dye_blueSlider", function(ui, call, value)
        local root = Ext.GetUI("LXN_Dye"):GetRoot()
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
        Ext.PostMessageToServer("DyeFetchList", "")
    end
end)

