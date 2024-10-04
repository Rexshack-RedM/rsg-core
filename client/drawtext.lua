local positions = {
    left = 'left-center',
    right = 'right-center',
    top = 'top-center'
}

local function hideText()
    lib.hideTextUI()
end

local function drawText(text, position)
    position = positions[position] or position
    lib.showTextUI(text, {
        position = position
    })
end

local function changeText(text, position)
    position = positions[position] or position
    lib.hideTextUI()
    lib.showTextUI(text, {
        position = position
    })
end

local function keyPressed()
    CreateThread(function() -- Not sure if a thread is needed but why not eh?
        lib.hideTextUI()
    end)
end

RegisterNetEvent('rsg-core:client:DrawText', function(text, position)
    drawText(text, position)
end)

RegisterNetEvent('rsg-core:client:ChangeText', function(text, position)
    changeText(text, position)
end)

RegisterNetEvent('rsg-core:client:HideText', function()
    hideText()
end)

RegisterNetEvent('rsg-core:client:KeyPressed', function()
    keyPressed()
end)

exports('DrawText', drawText)
exports('ChangeText', changeText)
exports('HideText', hideText)
exports('KeyPressed', keyPressed)