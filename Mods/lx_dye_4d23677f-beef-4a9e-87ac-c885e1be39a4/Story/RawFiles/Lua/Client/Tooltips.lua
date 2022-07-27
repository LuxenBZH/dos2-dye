---@param item EclItem
---@param tooltip TooltipData
local function EquipmentTooltips(item, tooltip)
    if tooltip == nil then return end
	-- if item.ItemType ~= "Weapon" then return end
    if item.Stats then
        local dye = LookForItemColorBoost(item)
        if dye and Ext.Stats.ItemColor.Get(dye) and dye ~= "Default" and string.match(dye, "CUSTOM", 1) == nil then
            local description = tooltip:GetElement("ItemDescription")
            description.Label = description.Label.."\nDye : <font color=\""..dyes[dye].Colors[1].."\">"..dyes[dye].Name.."</font>"
        elseif dye and string.match(dye, "CUSTOM", 1) then
            local description = tooltip:GetElement("ItemDescription")
            description.Label = description.Label.."\nDye : Custom"
        end
    end
end

local function LXN_Tooltips_Dye_Init(e)
    Game.Tooltip.RegisterListener("Item", nil, EquipmentTooltips)
end

Ext.Events.SessionLoaded:Subscribe(LXN_Tooltips_Dye_Init)