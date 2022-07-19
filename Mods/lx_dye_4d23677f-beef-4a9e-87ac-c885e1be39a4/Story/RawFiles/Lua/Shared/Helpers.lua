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