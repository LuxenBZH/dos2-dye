Ext.RegisterNetListener("DyeItem", function(call, payload)
    local infos = Ext.JsonParse(payload)
    local item = Ext.GetItem(tonumber(infos.Item)) --- @type EsvItem
    if infos.InInventory then
        local inventory = GetInventoryOwner(item.MyGuid)
        if ObjectIsCharacter(inventory) == 1 then
            ApplyStatus(inventory, "DYE_APPLY", 0.0)
            if Ext.GetCharacter(inventory).IsPossessed then
                local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.GetCurrentLevelData().UniqueKey or Ext.GetCurrentLevelData().LevelName
                PersistentVars.DyedItems[levelKey][item.MyGuid] = true
            end
        end
    else
        local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.GetCurrentLevelData().UniqueKey or Ext.GetCurrentLevelData().LevelName
        PersistentVars.DyedItems[levelKey][item.MyGuid] = true
        Transform(item.MyGuid, item.RootTemplate.Id, 0, 0, 0)
    end
    NRD_ItemSetPermanentBoostString(item.MyGuid, "ItemColor", infos.Dye)
end)

Ext.RegisterNetListener("")

local function GetPlayersInventoriesDyes()
    local players = Osi.DB_IsPlayer:Get(nil)
    local dyedItems = {}
    for i,player in pairs(players) do
        player = player[1]
        for i, item in pairs(Ext.GetCharacter(player):GetInventoryItems()) do
            local eItem = Ext.GetItem(item)
            local color = NRD_ItemGetPermanentBoostString(item, "ItemColor")
            if eItem.Stats and color ~= "" then
                dyedItems[tostring(eItem.NetID)] = color
            end
        end
    end
    return dyedItems
end

Ext.RegisterNetListener("DyeFetchList", function(call, payload, clientID)
    local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.GetCurrentLevelData().UniqueKey or Ext.GetCurrentLevelData().LevelName
    local netIDs = {}
    for guid,bool in pairs(PersistentVars.DyedItems[levelKey]) do
        if ObjectExists(guid) == 0 then
            PersistentVars.DyedItems[levelKey][guid] = false
        else
            netIDs[Ext.GetItem(guid).NetID] = NRD_ItemGetPermanentBoostString(guid, "ItemColor")
        end
    end
    Ext.PostMessageToUser(clientID, "DyeSetup", Ext.JsonStringify(TableConcat(netIDs, GetPlayersInventoriesDyes())))
end)

Ext.RegisterOsirisListener("GameStarted", 2, "before", function(level, isEditor)
    local levelKey = Ext.Utils.GetGameMode() == "GameMaster" and Ext.GetCurrentLevelData().UniqueKey or Ext.GetCurrentLevelData().LevelName
    if not PersistentVars.DyedItems[levelKey] then
        PersistentVars.DyedItems[levelKey] = {}
    end
end)