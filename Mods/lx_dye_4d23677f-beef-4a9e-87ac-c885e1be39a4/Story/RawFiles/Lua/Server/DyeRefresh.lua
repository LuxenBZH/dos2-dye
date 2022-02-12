if not PersistentVars.DyedItems then
    PersistentVars.DyedItems = {}
end

Ext.RegisterNetListener("DyeItem", function(call, payload)
    local infos = Ext.JsonParse(payload)
    local item = Ext.GetItem(tonumber(infos.NetID)) --- @type EsvItem
    if infos.InInventory then
        local inventory = GetInventoryOwner(item.MyGuid)
        if ObjectIsCharacter(inventory) == 1 then
            ApplyStatus(inventory, "DYE_APPLY", 0.0)
        end
    else
        local levelKey = Ext.GetCurrentLevelData().UniqueKey and Ext.Utils.GetGameMode == "GameMaster" or Ext.GetCurrentLevelData().LevelName
        PersistentVars.DyedItems[levelKey][item.MyGuid] = true
    end
    NRD_ItemSetPermanentBoostString(item.MyGuid, "ItemColor", infos.Dye)
end)

local function GetPlayersInventoriesDyes()
    local players = Osi.DB_IsPlayer:Get(nil)
    local dyedItems = {}
    for i,player in pairs(players) do
        player = player[1]
        for i, item in pairs(Ext.GetCharacter(player):GetInventoryItems()) do
            local eItem = Ext.GetItem(item)
            if eItem.Stats and NRD_ItemGetPermanentBoostString(item, "ItemColor") ~= "" then
                dyedItems[eItem.NetID] = true
            end
        end
    end
    return dyedItems
end

Ext.RegisterNetListener("DyeFetchList", function(call, payload, clientID)
    local levelKey = Ext.GetCurrentLevelData().UniqueKey and Ext.Utils.GetGameMode == "GameMaster" or Ext.GetCurrentLevelData().LevelName
    local netIDs = {}
    for guid,bool in pairs(PersistentVars.DyedItems[levelKey]) do
        if ObjectExists(guid) == 0 then
            PersistentVars.DyedItems[levelKey][guid] = false
        else
            netIDs = Ext.GetItem(PersistentVars.DyedItems[levelKey][guid]).NetID
        end
    end
    Ext.PostMessageToUser(clientID, "DyeSetup", Ext.JsonStringify(netIDs))
end)

Ext.RegisterOsirisListener("GameStarted", 2, "before", function(level, isEditor)
    local levelKey = Ext.GetCurrentLevelData().UniqueKey and Ext.Utils.GetGameMode == "GameMaster" or Ext.GetCurrentLevelData().LevelName
    if not PersistentVars.DyedItems[levelKey] then
        PersistentVars.DyedItems[levelKey] = {}
    end
end)