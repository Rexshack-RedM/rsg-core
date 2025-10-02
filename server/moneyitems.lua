---------------------------------------------------
-- Helper tables to map money items - do not change
---------------------------------------------------

local moneyItems = {
    cash = {
        dollar = 'dollar',
        cent = 'cent',
    },
    bloodmoney = {
        dollar = 'blood_dollar',
        cent = 'blood_cent',
    },
}

local moneyMap = {
    dollar = "cashDollars",
    cent = "cashCents",
    blood_dollar = "bloodDollars",
    blood_cent = "bloodCents"
}

-------------------
-- Helper functions
-------------------

local function getInventoryMoney(playerData)
    local money = {
        cashDollars = 0,
        cashCents = 0,
        bloodDollars = 0,
        bloodCents = 0
    }

    for _, item in pairs(playerData.items) do
        if item and moneyMap[item.name] then
            money[moneyMap[item.name]] = money[moneyMap[item.name]] + item.amount
        end
    end

    return money
end

local function removeItems(player, itemName, amountToRemove)
    for _, item in ipairs(player.Functions.GetItemsByName(itemName) or {}) do
        local removeAmount = math.min(item.amount, amountToRemove)
        player.Functions.RemoveItem(item.name, removeAmount, item.slot)
        amountToRemove = amountToRemove - removeAmount
        if amountToRemove <= 0 then break end
    end
end

local function getParts(number)
    local integerPart, decimalPart = math.modf(number)
    local decimalValue = math.floor(decimalPart * 100)
    return integerPart, decimalValue
end

local function calculateTotal(dollars, cents)
    return tonumber(string.format("%.2f", dollars + (cents / 100)))
end

----------------------------
-- Money operations hanlders
----------------------------

local function handleAddMoney(src, moneytype, amount)
    local player = RSGCore.Functions.GetPlayer(src)
    if not player or not moneyItems[moneytype] then return end

    local dollars, cents = getParts(amount)

    if dollars > 0 then
        player.Functions.AddItem(moneyItems[moneytype].dollar, dollars)
    end
    if cents > 0 then
        player.Functions.AddItem(moneyItems[moneytype].cent, cents)
    end

    if Player(src).state.inv_busy then
        TriggerClientEvent('rsg-inventory:client:updateInventory', src)
    end
end

local function handleRemoveMoney(src, moneytype, amount)
    local player = RSGCore.Functions.GetPlayer(src)
    if not player or not moneyItems[moneytype] then return false end

    local inventoryMoney = getInventoryMoney(player.PlayerData)
    local centName = moneyItems[moneytype].cent
    local dollarName = moneyItems[moneytype].dollar

    local availableDollars = inventoryMoney[moneyMap[dollarName]] or 0
    local availableCents = inventoryMoney[moneyMap[centName]] or 0
    local totalAvailableCents = (availableDollars * 100) + availableCents
    local requiredCents = math.round(amount * 100)

    if totalAvailableCents < requiredCents then
        return false
    end

    local centsToRemove = math.min(availableCents, requiredCents)
    local remainingRequired = requiredCents - centsToRemove
    local dollarsToRemove = math.ceil(remainingRequired / 100)
    local changeInCents = (dollarsToRemove * 100) - remainingRequired

    if centsToRemove > 0 then 
        removeItems(player, centName, centsToRemove) 
    end
    
    if dollarsToRemove > 0 then 
        removeItems(player, dollarName, dollarsToRemove) 
    end
    
    if changeInCents > 0 then 
        player.Functions.AddItem(centName, changeInCents) 
    end

    if Player(src).state.inv_busy then
        TriggerClientEvent('rsg-inventory:client:updateInventory', src)
    end

    return true
end

local function handleSetMoney(src, moneytype, amount)
    local player = RSGCore.Functions.GetPlayer(src)
    if not player or not moneyItems[moneytype] then return end

    local function removeAllItems(itemName)
        for _, item in ipairs(player.Functions.GetItemsByName(itemName) or {}) do
            player.Functions.RemoveItem(item.name, item.amount, item.slot)
        end
    end

    removeAllItems(moneyItems[moneytype].cent)
    removeAllItems(moneyItems[moneytype].dollar)

    local dollars, cents = math.modf(amount)
    cents = math.floor(cents * 100)

    if dollars > 0 then player.Functions.AddItem(moneyItems[moneytype].dollar, dollars) end
    if cents > 0 then player.Functions.AddItem(moneyItems[moneytype].cent, cents) end

    if Player(src).state.inv_busy then
        TriggerClientEvent('rsg-inventory:client:updateInventory', src)
    end
end

-----------------------------------------------------------------
-- If config changed, handle inventory items accordingly on login
-----------------------------------------------------------------

local initialized = {}
RegisterNetEvent('RSGCore:Server:OnPlayerLoaded')
AddEventHandler('RSGCore:Server:OnPlayerLoaded', function()
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if not player then return end

    local money = getInventoryMoney(player.PlayerData)

    if RSGCore.Config.Money.EnableMoneyItems then
        local cash = calculateTotal(money.cashDollars, money.cashCents)
        local bloodmoney = calculateTotal(money.bloodDollars, money.bloodCents)

        if cash ~= player.PlayerData.money.cash then
            handleSetMoney(src, 'cash', player.PlayerData.money.cash)
        end

        if bloodmoney ~= player.PlayerData.money.bloodmoney then
            handleSetMoney(src, 'bloodmoney', player.PlayerData.money.bloodmoney)
        end
    else
        local function removeAllItems(itemName)
            for _, item in ipairs(player.Functions.GetItemsByName(itemName) or {}) do
                player.Functions.RemoveItem(item.name, item.amount, item.slot, 'money-item-cleanup')
            end
        end

        removeAllItems(moneyItems['cash'].cent)
        removeAllItems(moneyItems['cash'].dollar)
        removeAllItems(moneyItems['bloodmoney'].cent)
        removeAllItems(moneyItems['bloodmoney'].dollar)
    end

    -- failsafe to prevent early override by synchronization
    initialized[player.PlayerData.citizenid] = true
end)

-------------------------------------------------------------
-- Enable handlers and synchronization when enabled in config
-------------------------------------------------------------

if RSGCore.Config.Money.EnableMoneyItems then

    local moneyHandlers = {
        add = handleAddMoney,
        remove = handleRemoveMoney,
        set = handleSetMoney,
    }

    AddEventHandler('RSGCore:Server:OnMoneyChange', function(src, moneytype, amount, operation, reason)
        local handler = moneyHandlers[operation]
        if handler then
            handler(src, moneytype, amount)
            TriggerClientEvent('hud:client:OnMoneyChange', src, moneytype, amount, operation == 'remove')
        end
    end)

    function SynchronizeMoneyItems(playerData)
        if not initialized[playerData.citizenid] then return playerData end

        local money = getInventoryMoney(playerData)

        local cash = calculateTotal(money.cashDollars, money.cashCents)
        local bloodmoney = calculateTotal(money.bloodDollars, money.bloodCents)

        if cash ~= playerData.money.cash then
            local operation = cash > (playerData.money.cash or 0) and 'add' or 'remove'
            local amount = math.abs(cash - (playerData.money.cash or 0))
            playerData.money.cash = cash
            TriggerClientEvent('hud:client:OnMoneyChange', playerData.source, 'cash', amount, operation)
        end

        if bloodmoney ~= playerData.money.bloodmoney then
            local operation = bloodmoney > (playerData.money.bloodmoney or 0) and 'add' or 'remove'
            local amount = math.abs(bloodmoney - (playerData.money.bloodmoney or 0))
            playerData.money.bloodmoney = bloodmoney
            TriggerClientEvent('hud:client:OnMoneyChange', playerData.source, 'bloodmoney', amount, operation)
        end

        return playerData
    end

end

