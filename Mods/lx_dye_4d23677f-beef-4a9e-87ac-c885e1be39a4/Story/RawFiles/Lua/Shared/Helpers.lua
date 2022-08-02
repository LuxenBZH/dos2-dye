--- @param table array[]
function GetTableSize(table)
    if table == nil then return 0 end
    local i = 0
    for j,k in pairs(table) do
        i = i + 1
    end
    return i
end

--- @param character string | EsvCharacter
function CharacterIsPolymorphed(character)
    if type(character) == "string" then
        character = Ext.Entity.GetCharacter(character)
    end
    if character:GetStatusByType("POLYMORPHED") then
        return true
    end
    return false
end

--- @param red integer 0 to 255
--- @param green integer 0 to 255
--- @param blue integer 0 to 255
function GetRGBInteger(red, green, blue)
    return ((red & 0x0ff) << 16 | (green & 0x0ff) << 8 |(blue & 0x0ff))
end

--- @param item EclItem
function LookForItemColorBoost(item)
    if not item then return nil end
    local i = 1
    local itemColor
    -- while item.Stats.DynamicStats[i] do
    --     local color = item.Stats.DynamicStats[i].ItemColor
    --     if color ~= "" and not defaultDyes[color] then
    --         itemColor = item.Stats.DynamicStats[i].ItemColor
    --         _P(i, itemColor)
    --         -- break
    --     end
    --     i = i + 1 
    -- end
    if item.ItemType == "Unique" then
        return item.Stats.DynamicStats[1].ItemColor -- [1] is reliable on uniques in all cases
    end
    if item.Stats.DynamicStats[2].ItemColor ~= "" then
        return item.Stats.DynamicStats[1].ItemColor -- [1] is reliable to read only if [2] is set from a previous game
    else
        return nil -- If [2] is missing, then [1] is not the real color so can safely return nil.
    end
end

---@class DyeNetMessage
---@field Dye string
---@field Item integer
---@field InInventory boolean
---@field Colors table

function GetColorFromCustomDyeName(name)
    local color1 = string.gsub(name, "CUSTOM_", ""):gsub("-.*", "")
    local color2 = string.gsub(name, "CUSTOM_[a-z0-9]+-", ""):gsub("-.*", "")
    local color3 = string.gsub(name, "CUSTOM_.*-", "")
    return {Name = name, Color1 = color1, Color2 = color2, Color3 = color3}
end

EquipmentSlots = {
	[0]="Helmet",
	[1]="Breast",
	[2]="Leggings",
	[3]="Weapon",
	[4]="Shield",
	[5]="Ring",
	[6]="Belt",
	[7]="Boots",
	[8]="Gloves",
	[9]="Amulet",
	[10]="Ring2",
	[11]="Wings",
	[12]="Horns",
	[13]="Overhead",
	[14]="Sentinel"
}