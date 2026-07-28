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
    gold = {
        unit = RSGCore.Config.Money.GoldItem,
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
        bloodCents = 0,
        gold = 0,
    }

    for _, item in pairs(playerData.items) do
        if item then
            if moneyMap[item.name] then
                money[moneyMap[item.name]] = money[moneyMap[item.name]] + item.amount
            elseif item.name == moneyItems.gold.unit then
                money.gold = money.gold + item.amount
            end
        end
    end

    return money
end

local function removeItems(player, itemName, amountToRemove, reason)
    for _, item in ipairs(player.Functions.GetItemsByName(itemName) or {}) do
        local removeAmount = math.min(item.amount, amountToRemove)
        player.Functions.RemoveItem(item.name, removeAmount, item.slot, reason)
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

    if moneytype == 'gold' then
        if amount > 0 then
            player.Functions.AddItem(moneyItems.gold.unit, amount)
        end
        if Player(src).state.inv_busy then
            TriggerClientEvent('rsg-inventory:client:updateInventory', src)
        end
        return
    end

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

    if moneytype == 'gold' then
        if inventoryMoney.gold < amount then return false end
        removeItems(player, moneyItems.gold.unit, amount)
        if Player(src).state.inv_busy then
            TriggerClientEvent('rsg-inventory:client:updateInventory', src)
        end
        return true
    end

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

    if moneytype == 'gold' then
        removeAllItems(moneyItems.gold.unit)
        if amount > 0 then player.Functions.AddItem(moneyItems.gold.unit, amount) end
        if Player(src).state.inv_busy then
            TriggerClientEvent('rsg-inventory:client:updateInventory', src)
        end
        return
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
        removeItems(player, moneyItems.cash.cent, math.huge, 'money-item-cleanup')
        removeItems(player, moneyItems.cash.dollar, math.huge, 'money-item-cleanup')
        removeItems(player, moneyItems.bloodmoney.cent, math.huge, 'money-item-cleanup')
        removeItems(player, moneyItems.bloodmoney.dollar, math.huge, 'money-item-cleanup')
    end

    if RSGCore.Config.Gold.EnableGoldItems then
        if money.gold ~= player.PlayerData.money.gold then
            handleSetMoney(src, 'gold', player.PlayerData.money.gold)
        end
    else
        removeItems(player, moneyItems.gold.unit, math.huge, 'gold-item-cleanup')
    end

    -- failsafe to prevent early override by synchronization
    initialized[player.PlayerData.citizenid] = true
end)

-------------------------------------------------------------
-- Enable handlers and synchronization when enabled in config
-------------------------------------------------------------

function IsMoneyItemEnabled(moneytype)
    if moneytype == 'gold' then
        return RSGCore.Config.Gold.EnableGoldItems
    end

    return RSGCore.Config.Money.EnableMoneyItems
        and (moneytype == 'cash' or moneytype == 'bloodmoney')
end

if RSGCore.Config.Money.EnableMoneyItems or RSGCore.Config.Gold.EnableGoldItems then

    local moneyHandlers = {
        add = handleAddMoney,
        remove = handleRemoveMoney,
        set = handleSetMoney,
    }

    AddEventHandler('RSGCore:Server:OnMoneyChange', function(src, moneytype, amount, operation, reason)
        if not IsMoneyItemEnabled(moneytype) then return end
        local handler = moneyHandlers[operation]
        if handler then
            handler(src, moneytype, amount)
            TriggerClientEvent('hud:client:OnMoneyChange', src, moneytype, amount, operation == 'remove')
        end
    end)

    function SynchronizeMoneyItems(playerData)
        if not initialized[playerData.citizenid] then return playerData end

        local money = getInventoryMoney(playerData)

        if RSGCore.Config.Money.EnableMoneyItems then
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
        end

        if RSGCore.Config.Gold.EnableGoldItems and money.gold ~= playerData.money.gold then
            local operation = money.gold > (playerData.money.gold or 0) and 'add' or 'remove'
            local amount = math.abs(money.gold - (playerData.money.gold or 0))
            playerData.money.gold = money.gold
            TriggerClientEvent('hud:client:OnMoneyChange', playerData.source, 'gold', amount, operation)
        end

        return playerData
    end

end

