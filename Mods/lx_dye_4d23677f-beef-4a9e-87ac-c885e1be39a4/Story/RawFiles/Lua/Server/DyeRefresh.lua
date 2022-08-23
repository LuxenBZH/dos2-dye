local levelKey
local clientCount = 0

--- Triggered when a player apply a new dye. Calls all other players to sync it.
Ext.RegisterNetListener("DyeItem", function(call, payload)
    local infos = Ext.Json.Parse(payload)
    -- _P("DYES: server dye call", infos.Dye)
    clientCount = 0
    Ext.Net.BroadcastMessage("DyeItemClient", payload)
end)

local function RefreshVisuals(character)
    ApplyStatus(character, "DYE_APPLY", 0.0, 1, character) -- Only POLYMORPHED statuses can refresh the entire armor
    ApplyStatus(character, "DYE_APPLY_2", 0.0, 1, character)
    if CharacterIsInCombat(character) == 1 then
        RemoveStatus(character, "DYE_APPLY_2")
    end
end

---@param infos DyeNetMessage
local function RefreshCharacterDyes(infos)
    local item = Ext.Entity.GetItem(tonumber(infos.Item)) --- @type EsvItem
    if infos.InInventory then
        local inventory = GetInventoryOwner(item.MyGuid)
        if ObjectIsCharacter(inventory) == 1 then
            -- _P("Applying refresh...", inventory)
            RefreshVisuals(inventory)
            local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
            PersistentVars.DyedItems[levelKey][GetUUID(item.MyGuid)] = true
        end
    else
        local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
        PersistentVars.DyedItems[levelKey][GetUUID(item.MyGuid)] = true
        Transform(item.MyGuid, item.RootTemplate.Id, 0, 0, 0)
    end
    if infos.Dye == "Default" then
        SetTag(item.MyGuid, "DYE_Default")
        NRD_ItemSetPermanentBoostString(item.MyGuid, "ItemColor", "")
    elseif infos.Dye == "CUSTOM" then
        local dye = "CUSTOM_"..infos.Colors[1]..infos.Colors[2]..infos.Colors[3]
        -- Ext.Dump(Ext.Stats.ItemColor.Get(dye))
        if not Ext.Stats.ItemColor.Get(dye) then
            Ext.Stats.ItemColor.Update({Name=dye, Color1=tonumber(infos.Colors[1]), Color2=tonumber(infos.Colors[2]), Color3=tonumber(infos.Colors[3])})
        end
        NRD_ItemSetPermanentBoostString(item.MyGuid, "ItemColor", dye)
        SetTag(item.MyGuid, "DYE_"..dye)
    else
        NRD_ItemSetPermanentBoostString(item.MyGuid, "ItemColor", infos.Dye)
        SetTag(item.MyGuid, "DYE_"..infos.Dye)
    end
end

--- Trigger the world refresh once all clients applied the new dye to the equipped item
--- @param call string
--- @param payload any
Ext.RegisterNetListener("DyeItemApply", function(call, payload)
    clientCount = clientCount + 1
    -- _P("Clients answers:", clientCount, "/", GetTableSize(Mods.LeaderLib.SharedData.CharacterData))
    -- Wait for all clients to receive the information before applying the refresh
    if clientCount ~= GetTableSize(Mods.LeaderLib.SharedData.CharacterData) then return end
    clientCount = 0
    RefreshCharacterDyes(Ext.Json.Parse(payload))
end)

--- Get dyed items in all players inventories
local function GetPlayersInventoriesDyes()
    local players = Osi.DB_IsPlayer:Get(nil)
    local dyedItems = {}
    for i,player in pairs(players) do
        player = player[1]
        for i, item in pairs(Ext.Entity.GetCharacter(player):GetInventoryItems()) do
            local eItem = Ext.Entity.GetItem(item)
            if eItem.Stats then
                local color = NRD_ItemGetPermanentBoostString(item, "ItemColor")
                if eItem.Stats and color ~= "" then
                    dyedItems[tostring(eItem.NetID)] = color
                end
            end
        end
    end
    for character, b in pairs(PersistentVars.Followers) do
        if Osi.ObjectExists(character) == 1 then
            for i, item in pairs(Ext.Entity.GetCharacter(character):GetInventoryItems()) do
                local eItem = Ext.Entity.GetItem(item)
                local color = NRD_ItemGetPermanentBoostString(item, "ItemColor")
                if eItem.Stats and color ~= "" then
                    dyedItems[tostring(eItem.NetID)] = color
                end
            end
        end
    end
    return dyedItems
end

Ext.RegisterNetListener("RefreshAllDyes", function(...)
    local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
    local characters = {}
    if not PersistentVars.DyedItems[levelKey] then return end
    for guid,bool in pairs(PersistentVars.DyedItems[levelKey]) do
        if ObjectExists(guid) == 0 then
            PersistentVars.DyedItems[levelKey][guid] = false
        else
            characters[#characters+1] = Osi.GetInventoryOwner(guid)
        end
    end
    for i,player in pairs(Osi.DB_IsPlayer:Get(nil)) do
        characters[#characters+1] = player[1]
    end
    for i,char in pairs(characters) do
        RefreshVisuals(char)
    end
end)

-- Send the list of dyed items to the clients to refresh and remove deleted/undyed items
Ext.RegisterNetListener("DyeFetchList", function(call, payload, clientID)
    local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
    local netIDs = {}
    if not PersistentVars.DyedItems[levelKey] then return end
    for guid,bool in pairs(PersistentVars.DyedItems[levelKey]) do
        if ObjectExists(guid) == 0 then
            PersistentVars.DyedItems[levelKey][guid] = false
        else
            netIDs[Ext.Entity.GetItem(guid).NetID] = NRD_ItemGetPermanentBoostString(guid, "ItemColor")
        end
    end
    for ni, color in pairs(GetPlayersInventoriesDyes()) do
        netIDs[ni] = color
    end
    Ext.Net.PostMessageToUser(clientID, "DyeSetup", Ext.Json.Stringify(netIDs))
end)

-- Create a table for a level if it doesn't exists yet
---@param level string
---@param isEditor integer
Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.ToState == "Sync" then
        levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
        if not PersistentVars.DyedItems[levelKey] then
            PersistentVars.DyedItems[levelKey] = {}
        end
    end
end)

-- if a character drops an item, make sure it's included in the floating dyes list
---@param item string
Ext.Osiris.RegisterListener("ItemDropped", 1, "before", function(item)
    local item = Ext.Entity.GetItem(item)
    local dye = NRD_ItemGetPermanentBoostString(item.MyGuid, "ItemColor")
    if dye and dye ~= "" then
        local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
        PersistentVars.DyedItems[levelKey][item.MyGuid] = true
    end
end)

-- if a player pickup a dyed item, it can be removed from the list since players are automatically scanned
---@param item string
---@param character string
Ext.Osiris.RegisterListener("ItemAddedToCharacter", 2, "before", function(item, character)
    local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
    if Ext.GetGameState() == "Running" and PersistentVars.DyedItems[levelKey] and PersistentVars.DyedItems[levelKey][item] then
        local char = Ext.Entity.GetCharacter(character)
        if char.IsPlayer and not char.IsPossessed then
            PersistentVars.DyedItems[levelKey][GetUUID(item)] = nil
        end
    end
end)

--- Triggers a synchronisation at game start
---@param e EsvLuaGameStateChangeEventParams
Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.FromState == "Sync" and e.ToState == "Running" then
        local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
        local inventories = {}
        for item, b in pairs(PersistentVars.DyedItems[levelKey]) do
            if ObjectExists(item) == 1 then
                item = Ext.Entity.GetItem(item) --- @type EsvItem
                local parent = NRD_ItemGetParent(item.MyGuid)
                local dye = NRD_ItemGetPermanentBoostString(item.MyGuid, "ItemColor")
                if parent and not inventories[parent] and ObjectIsCharacter(parent) and CharacterGetEquippedItem(parent, item.Stats.ItemSlot) == item.MyGuid then
                    if dye == "" or dye == "DefaultGray" then
                        PersistentVars.DyedItems[levelKey][item.MyGuid] = nil
                    else
                        inventories[parent] = true
                    end
                end
                if not parent then
                    Transform(item.MyGuid, item.RootTemplate.Id, 0, 0, 0)
                end
            else
                PersistentVars.DyedItems[levelKey][item] = nil
            end
        end
        for character, i in pairs(PersistentVars.Followers) do
            inventories[character] = true
        end
        for character, i in pairs(inventories) do
            RefreshVisuals(character)
        end
    end
end)

--- In GM mode, it is necessary to track character following the party across the scene to ensure their items dyes are sync. They are treated like player characters in that case.
Ext.RegisterNetListener("DyeTagFollower", function(call, payload)
    if not PersistentVars.Followers then
        PersistentVars.Followers = {}
    end
    local character = Ext.Entity.GetCharacter(tonumber(Ext.Json.Parse(payload).Character))
    if not PersistentVars.Followers[character.MyGuid] then
        PersistentVars.Followers[character.MyGuid] = true
        local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
        for i, item in pairs(character:GetInventoryItems()) do
            local eItem = Ext.Entity.GetItem(item)
            local color = NRD_ItemGetPermanentBoostString(item, "ItemColor")
            if eItem.Stats and color ~= "" then
                PersistentVars.DyedItems[levelKey][eItem.MyGuid] = nil
            end
        end
    else
        PersistentVars.Followers[character.MyGuid] = nil
        local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
        for i, item in pairs(character:GetInventoryItems()) do
            local eItem = Ext.Entity.GetItem(item)
            local color = NRD_ItemGetPermanentBoostString(item, "ItemColor")
            if eItem.Stats and color ~= "" then
                PersistentVars.DyedItems[levelKey][eItem.MyGuid] = true
            end
        end
    end
end)