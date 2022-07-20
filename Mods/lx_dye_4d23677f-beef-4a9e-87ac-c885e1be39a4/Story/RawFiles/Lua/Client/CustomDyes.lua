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

local function LoadCustomDyes()
    local content = Ext.IO.LoadFile("Dyes.json")
    if content then
        content = Ext.Json.Parse(content)
    end
    for name, dye in pairs(content) do
        customDyesNames[name] = dye
    end
    table.sort(_order)
end

Ext.Events.SessionLoaded:Subscribe(function(e)
    LoadCustomDyes()
end)

local function SaveCustomDye(name, dye)
    customDyesNames[name] = dye
    Ext.IO.SaveFile("Dyes.json", Ext.Json.Stringify(customDyesNames))
end

-- customDyesNames["Default"] = {Name="Default", Color1=}
-- table.sort(_order)