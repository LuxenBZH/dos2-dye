Ext.Require("Shared/Dyes.lua")
Ext.Require("Shared/Helpers.lua")

function TableConcat(t1,t2)
    for i=1,#t2 do
       t1[#t1+1] = t2[i]
       _P(#t1+1, t2[i])
    end
    return t1
 end