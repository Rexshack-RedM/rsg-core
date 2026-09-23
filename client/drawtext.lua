local positions = {
    left = 'left-center',
    right = 'right-center',
    top = 'top-center'
}

local function resolvePos(pos)
    return positions[pos] or pos or 'right-center'
end

local function showText(text, pos)
    lib.showTextUI(text, {
        position = resolvePos(pos)
    })
end

-- lib.showTextUI replaces any text already shown, so no hide is needed first
local updateText = showText

local function hideText()
    lib.hideTextUI()
end

local keyPressed = hideText

RegisterNetEvent('rsg-core:client:DrawText', showText)
RegisterNetEvent('rsg-core:client:ChangeText', updateText)
RegisterNetEvent('rsg-core:client:HideText', hideText)
RegisterNetEvent('rsg-core:client:KeyPressed', keyPressed)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        lib.hideTextUI()
    end
end)

exports('DrawText', showText)
exports('ChangeText', updateText)
exports('HideText', hideText)
exports('KeyPressed', keyPressed)
