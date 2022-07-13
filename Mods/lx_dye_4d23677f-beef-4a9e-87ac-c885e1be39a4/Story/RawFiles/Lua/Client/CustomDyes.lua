local _order = {}
customDyes = {}
customDyesNames = {}
-- Credits : LaughingLeader
-- Alphabetical ordering of the dye terms
setmetatable(customDyesNames, {
    __newindex = function(tbl,k,v)
        _order[#_order+1] = k
        rawset(tbl, k, v)
    end,
    __pairs = function(tbl)
        local function stateless_iter(tbl, i)
            i = i + 1
            local v = _order[i]
            if nil~=v then return i, customDyesNames[v], v end
        end
        return stateless_iter, tbl, 0
    end
})

Ext.RegisterListener("SessionStarted", function()
    if PersistentVars.CustomDyes then
        for name,color in pairs(PersistentVars.CustomDyesNames) do
            customDyesNames[name] = color
        end
        table.sort(_order)
    end
end)


-- customDyesNames["Default"] = {Name="Default", Color1=}
-- table.sort(_order)