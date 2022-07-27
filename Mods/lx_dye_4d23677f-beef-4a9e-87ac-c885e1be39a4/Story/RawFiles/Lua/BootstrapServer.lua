-- Mods.LeaderLib.Import(Mods.ItemDye)

if not PersistentVars then
    PersistentVars = {}
end

if PersistentVars.DyedItems == nil then
    PersistentVars.DyedItems = {}
end

if not PersistentVars.Followers then
    PersistentVars.Followers = {}
end

Ext.Require("BootstrapShared.lua")
Ext.Require("Server/_InitServer.lua")
