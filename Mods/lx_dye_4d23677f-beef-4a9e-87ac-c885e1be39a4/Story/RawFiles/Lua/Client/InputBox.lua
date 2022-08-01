---@param infos array[] contain all infos to transmit to the server
---@param title string
---@param message string
---@param buttonID number
function OpenInputBox(title, message, buttonID, infos)
    local ui = Ext.UI.GetByPath("Public/Game/GUI/msgBox.swf")
    if ui then
        ui:Hide()
        infos = Ext.Json.Parse(infos)
        local root = ui:GetRoot()
        root.popup_mc.input_mc.input_txt.htmlText = ""
        root.setPopupType(1)
        if not buttonID then
            buttonID = 4040
        end
        ui:Invoke("removeButtons")
        ui:Invoke("addButton", buttonID, "Accept", "", "")
        ui:Invoke("addBlueButton", 4049, "Cancel")
        ui:Invoke("setInputEnabled", true)
        ui:Invoke("focusInputEnabled")
        infos.ButtonID = buttonID
        ui:Invoke("setTooltip", 1, Ext.Json.Stringify(infos))
        ui:Invoke("showPopup", title, message)
        ui:Show()
    end
end

local function ManageInputBoxAnswer(ui, call, buttonID, device)
    local ui = Ext.UI.GetByPath("Public/Game/GUI/msgBox.swf")
    local root = ui:GetRoot()
    local infos = nil
    if root.popup_mc.input_mc.copy_mc.tooltip then
        infos = Ext.Json.Parse(root.popup_mc.input_mc.copy_mc.tooltip)
    else
        return
    end
    infos.ButtonID = tonumber(infos.ButtonID)
    ui:Invoke("setTooltip", 1, "")
    if math.floor(buttonID) == 4049 then
        ui:Hide()
        return
    end
    -- if infos.ButtonID > 5100 and infos.ButtonID < 5200 then
    --     infos.Value = ui:GetRoot().popup_mc.input_mc.input_txt.htmlText
    --     Ext.Net.PostMessageToServer("UGM_InputBox", Ext.Json.Stringify(infos))
    --     ui:Hide()
    -- end
    if infos.ButtonID == 5101 then
        local name = ui:GetRoot().popup_mc.input_mc.input_txt.htmlText
        SaveCustomDye(name, {
            string.format("%x", infos.Color1),
            string.format("%x", infos.Color2),
            string.format("%x", infos.Color3)
        })
        ui:Hide()
    end
end

Ext.Events.SessionLoaded:Subscribe(function(e)
    local msgBox = Ext.GetBuiltinUI("Public/Game/GUI/msgBox.swf")
    Ext.RegisterUICall(msgBox, "ButtonPressed", ManageInputBoxAnswer)
    -- Ext.RegisterNetListener("UGM_InitInputBoxClient", function(channel, payload)
    --     InputBoxAnswers = Ext.JsonParse(payload)
    -- end)
end)