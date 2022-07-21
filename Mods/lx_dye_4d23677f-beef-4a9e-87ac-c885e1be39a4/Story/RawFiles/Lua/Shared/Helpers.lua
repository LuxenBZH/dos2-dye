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