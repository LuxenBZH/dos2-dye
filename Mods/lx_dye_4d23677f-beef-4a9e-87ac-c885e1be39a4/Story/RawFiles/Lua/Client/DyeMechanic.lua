local currentItem

local function ChangeDyerMcColors(name, colors)
    local root = Ext.GetUI("LXN_Dye"):GetRoot()
    root.dyer_mc.cSet_mc.visible = true
    root.dyer_mc.cSet_mc.changePartColor(0, tonumber("0x"..colors[1]))
    root.dyer_mc.cSet_mc.changePartColor(1, tonumber("0x"..colors[2]))
    root.dyer_mc.cSet_mc.changePartColor(2, tonumber("0x"..colors[3]))
    root.dyer_mc.currentColor_txt.htmlText = name
end

local function LookForItemColorBoost(item)
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
    if not itemDye then
        root.dyer_mc.cSet_mc.visible = false
        root.dyer_mc.currentColor_txt.htmlText = "Default"
    else
        root.dyer_mc.cSet_mc.visible = true
        local cSet = dyes[itemDye]
        ChangeDyerMcColors(cSet.Name, cSet.Colors)
    end
end

---@param item EclItem
function DyeItem(item, dye)
    if item.Stats.WeaponType or item.Stats.Slot then
        item.ItemColorOverride = dye
    end
    item.Stats.DynamicStats[1].ItemColor = dye
    item.Stats.StatsEntry.ItemGroup = ""
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
        if dye then
            local equipment = {
                Type = "ItemDescription",
                Label = "Dye : <font color=\""..dyes[dye].Colors[1].."\">"..dyes[dye].Name.."</font>",
                RequirementMet = true,
            }
            local description = tooltip:GetElement("ItemDescription")
            description.Label = description.Label.."\nDye : <font color=\"#e674bf\">something</font>"
        end
    end
end


local function LXN_Tooltips_Dye_Init()
    Game.Tooltip.RegisterListener("Item", nil, EquipmentTooltips)
end

Ext.RegisterListener("SessionLoaded", LXN_Tooltips_Dye_Init)

Ext.RegisterNetListener("DyeSetup", function(call, payload)
    local items = Ext.JsonParse(payload)
    for i,netid in pairs(items) do
        local item = Ext.GetItem(netid)
        DyeItem(item, item.Stats.DynamicStats[1].ItemColor)
    end
end)

Ext.RegisterListener("SessionLoaded", function()
    if Ext.GameVersion() == "v3.6.51.9303" then return end
    Ext.CreateUI("LXN_Dye", "Public/lx_dye_4d23677f-beef-4a9e-87ac-c885e1be39a4/Game/GUI/dye.swf", 10)
    local ui = Ext.GetUI("LXN_Dye")
    local root = ui:GetRoot()
    for i, infos, color in pairs(dyes) do
        root.addEntry(color, infos.Name, tonumber("0x"..infos.Colors[1]), tonumber("0x"..infos.Colors[2]), tonumber("0x"..infos.Colors[3]))
    end
    root.dyer_mc.visible = false
    Ext.RegisterUICall(ui, "dye_apply", function(...)
        local root = Ext.GetUI("LXN_Dye"):GetRoot()
        local dye = root.dyer_mc.ddCombo_mc.color_id
        DyeItem(currentItem, dye)
        local cSet = dyes[dye]
        ChangeDyerMcColors(cSet.Name, cSet.Colors)
    end)
    Ext.RegisterUICall(ui, "dye_close", function(...)
        local root = Ext.GetUI("LXN_Dye"):GetRoot()
        currentItem = nil
        root.dyer_mc.visible = false
    end)
    Ext.PostMessageToServer("DyeFetchList", "")
end)

