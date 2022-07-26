local levelKey
local clientCount = 0

--- Triggered when a player apply a new dye. Calls all other players to sync it.
Ext.RegisterNetListener("DyeItem", function(call, payload)
    local infos = Ext.Json.Parse(payload)
    -- _P("DYES: server dye call", infos.Dye)
    clientCount = 0
    Ext.Net.BroadcastMessage("DyeItemClient", payload)
end)

---@param infos DyeNetMessage
local function RefreshCharacterDyes(infos)
    local item = Ext.Entity.GetItem(tonumber(infos.Item)) --- @type EsvItem
    if infos.InInventory then
        local inventory = GetInventoryOwner(item.MyGuid)
        if ObjectIsCharacter(inventory) == 1 then
            -- _P("Applying refresh...", inventory)
            ApplyStatus(inventory, "DYE_APPLY", 0.0, 1, inventory) -- Only POLYMORPHED statuses can refresh the entire armor
            if CharacterIsInCombat(inventory) == 1 then
                RemoveStatus(inventory, "DYE_APPLY")
            end
            if Ext.Entity.GetCharacter(inventory).IsPossessed then
                local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
                PersistentVars.DyedItems[levelKey][GetUUID(item.MyGuid)] = true
            end
        end
    else
        local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
        PersistentVars.DyedItems[levelKey][GetUUID(item.MyGuid)] = true
        Transform(item.MyGuid, item.RootTemplate.Id, 0, 0, 0)
    end
    if infos.Dye == "Default" then
        NRD_ItemSetPermanentBoostString(item.MyGuid, "ItemColor", "")
    elseif infos.Dye == "CUSTOM" then
        local dye = "CUSTOM_"..infos.Colors[1]..infos.Colors[2]..infos.Colors[3]
        -- Ext.Dump(Ext.Stats.ItemColor.Get(dye))
        if not Ext.Stats.ItemColor.Get(dye) then
            Ext.Stats.ItemColor.Update({Name=dye, Color1=tonumber(infos.Colors[1]), Color2=tonumber(infos.Colors[2]), Color3=tonumber(infos.Colors[3])})
        end
        NRD_ItemSetPermanentBoostString(item.MyGuid, "ItemColor", dye)
    else
        NRD_ItemSetPermanentBoostString(item.MyGuid, "ItemColor", infos.Dye)
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
            local color = NRD_ItemGetPermanentBoostString(item, "ItemColor")
            if eItem.Stats and color ~= "" then
                dyedItems[tostring(eItem.NetID)] = color
            end
        end
    end
    return dyedItems
end

-- Send the list of dyed items to the clients to refresh and remove deleted/undyed items
Ext.RegisterNetListener("DyeFetchList", function(call, payload, clientID)
    local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
    local netIDs = {}
    for guid,bool in pairs(PersistentVars.DyedItems[levelKey]) do
        if ObjectExists(guid) == 0 then
            PersistentVars.DyedItems[levelKey][guid] = false
        else
            netIDs[Ext.Entity.GetItem(guid).NetID] = NRD_ItemGetPermanentBoostString(guid, "ItemColor")
        end
    end
    Ext.Net.PostMessageToUser(clientID, "DyeSetup", Ext.Json.Stringify(TableConcat(netIDs, GetPlayersInventoriesDyes())))
end)

-- Create a table for a level if it doesn't exists yet
---@param level string
---@param isEditor integer
Ext.Osiris.RegisterListener("GameStarted", 2, "before", function(level, isEditor)
    levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
    if not PersistentVars.DyedItems[levelKey] then
        PersistentVars.DyedItems[levelKey] = {}
    end
end)

-- if a character drops an item, make sure it's included in the floating dyes list
---@param item string
Ext.Osiris.RegisterListener("ItemDropped", 1, "before", function(item)
    if Ext.Entity.GetItem(item).Stats and NRD_ItemGetPermanentBoostString(item, "ItemColor") ~= "" then
        local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
        PersistentVars.DyedItems[levelKey][item] = true
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
            PersistentVars.DyedItems[levelKey][item] = nil
        end
    end
end)

---@param e EsvLuaGameStateChangeEventParams
Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.FromState == "GameMasterPause" and e.ToState == "Running" then
        local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.ServerEntity.GetCurrentLevelData().UniqueKey or Ext.ServerEntity.GetCurrentLevelData().LevelName
        for item, b in pairs(PersistentVars.DyedItems[levelKey]) do
            item = Ext.Entity.GetItem(item) --- @type EsvItem
            if item.ParentInventoryHandle and
                ObjectIsCharacter(Ext.Entity.GetInventory(item.ParentInventoryHandle).GUID) == 1 and
                CharacterGetEquippedItem(Ext.Entity.GetCharacter(item.InventoryHandle).MyGuid, SlotsNames[item.Slot]) then
                RefreshCharacterDyes({
                    Item = item.NetID,
                    Dye = NRD_ItemGetPermanentBoostString(item.MyGuid, "ItemColor"),
                    InInventory = Ext.Utils.IsValidHandle(item.ParentInventoryHandle)
                })
            end
        end
    end
end)