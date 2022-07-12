if Mods.LeaderLib then
    UI = Mods.LeaderLib.UI
    local ts = Mods.LeaderLib.Classes.TranslatedString

    -- UI.ContextMenu.Register.ShouldOpenListener(function(contextMenu, x, y)
    --     local request = Game.Tooltip.GetCurrentOrLastRequest()
    --     Ext.Dump(request)
    --     if Game.Tooltip.LastRequestTypeEquals("Item") and Ext.GetItem(request.ItemNetID).Stats then
    --         return true
    --     end
    --     -- if Game.Tooltip.IsOpen() then
    --     --     local root = Ext.GetBuiltinUI("Public/Game/GUI/characterSheet.swf"):GetRoot()
    --     --     if root.isGameMasterChar then
    --     --         if Game.Tooltip.LastRequestTypeEquals("Stat") or Game.Tooltip.LastRequestTypeEquals("Ability")  then
    --     --             if not (bannedStats[request.Stat]) then
    --     --                 return true
    --     --             end
    --     --         elseif Game.Tooltip.LastRequestTypeEquals("Generic") and request.Tags == "Tags" then
    --     --             return true
    --     --         end
    --     --     end
    --     -- end
    -- end)

    UI.ContextMenu.Register.BuiltinOpeningListener(function(contextMenu, x, y)
        if Game.Tooltip.IsOpen() then
            ---@type TooltipCustomStatRequest
            local request = Game.Tooltip.GetCurrentOrLastRequest()
            local character = Ext.GetCharacter(Ext.Entity.GetInventory(Ext.GetItem(Ext.DoubleToHandle(request.ObjectHandleDouble)).InventoryParentHandle).ParentHandle)
            if not character then return end
            local infos = {
                Context = Ext.GetItem(request.ItemNetID),
                Character = character.NetID
            }
            contextMenu:AddBuiltinEntry("LXN_Dye", function(cMenu, ui, id, actionID, handle)
                local root = Ext.GetUI("LXN_Dye"):GetRoot()
                PrepareDye(Ext.GetItem(Ext.DoubleToHandle(request.ObjectHandleDouble)))
            end, "Dye")
        end
    end)

    -- UI.ContextMenu.Register.BuiltinOpeningListener(function(contextMenu, ui, this, buttonArr, buttons)
    --     local cursor = Ext.GetPickingState()
    --     Ext.Print("cursor",cursor)
    --     if cursor then
    --         local target = GameHelpers.TryGetObject(cursor.HoverCharacter or cursor.HoverItem)
    --         Ext.Print(target)
    --         if target then
    --             local request = Game.Tooltip.GetCurrentOrLastRequest()
    --             local infos = {
    --                 Character = target.NetID
    --             }
    --             contextMenu:AddBuiltinEntry("UGMT_SetScale", function(contextMenu, ui, id, actionID, handle)
    --                 infos.Context = "SetScale"
    --                 OpenInputBox("Enter a value en percentage", "", 4454, infos)
    --             end, "UGMT_SetScale", true, true, false, true, 0)   
    --             if target.PlayerCustomData.Name ~= "" then
    --                 contextMenu:AddBuiltinEntry("UGMT_Respec", function(contextMenu, ui, id, actionID, handle)
    --                     infos.Context = "Respec"
    --                     Ext.PostMessageToServer("UGM_ContextMenu", Ext.JsonStringify(infos))
    --                 end, "UGMT_Respec", true, true, false, true, 0)
    --             end
    --         end
    --     end
    -- end)
end