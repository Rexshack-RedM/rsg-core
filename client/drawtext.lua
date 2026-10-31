-- rsg-core text UI (replaces lib.showTextUI / lib.hideTextUI)
local positions = {
    left = 'left-center',
    right = 'right-center',
    top = 'top-center',
}

local function resolvePos(pos)
    return positions[pos] or pos or 'right-center'
end

local shown = false

local function showText(text, pos)
    if type(text) ~= 'string' or text == '' then return end
    shown = true
    SendNUIMessage({ action = 'textui', data = { show = true, text = text, position = resolvePos(pos) } })
end

-- showing new text replaces any text already shown, so no hide is needed first
local updateText = showText

local function hideText()
    if not shown then return end
    shown = false
    SendNUIMessage({ action = 'textui', data = { show = false } })
end

local keyPressed = hideText

RegisterNetEvent('rsg-core:client:DrawText', showText)
RegisterNetEvent('rsg-core:client:ChangeText', updateText)
RegisterNetEvent('rsg-core:client:HideText', hideText)
RegisterNetEvent('rsg-core:client:KeyPressed', keyPressed)

exports('DrawText', showText)
exports('ChangeText', updateText)
exports('HideText', hideText)
exports('KeyPressed', keyPressed)
exports('IsTextShown', function() return shown end)
