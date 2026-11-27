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

local function refreshInventory(src)
    if Player(src).state.inv_busy then
        TriggerClientEvent('rsg-inventory:client:updateInventory', src)
    end
end

local function removeItems(player, itemName, amountToRemove, reason)
    for _, item in ipairs(player.Functions.GetItemsByName(itemName) or {}) do
        local removeAmount = math.min(item.amount, amountToRemove)
        player.Functions.RemoveItem(item.name, removeAmount, item.slot, reason)
        amountToRemove = amountToRemove - removeAmount
        if amountToRemove <= 0 then break end
    end
end

-- work in whole cents to avoid float errors (e.g. 0.29 * 100 = 28.999... which lost a cent)
local function getParts(number)
    local totalCents = math.floor(number * 100 + 0.5)
    return totalCents // 100, totalCents % 100
end

local function calculateTotal(dollars, cents)
    return tonumber(string.format("%.2f", dollars + (cents / 100)))
end

local initialized = {}
local initializing = {} -- [citizenid] = true while the login reconciliation runs

-- AddItem returns ok, err. Money that does not fit is held for the player to collect with /claimmoney.
local function giveMoneyItem(player, itemName, amount)
    local ok, err = player.Functions.AddItem(itemName, amount)
    if ok == false then
        local src = player.PlayerData.source
        print(('^1[rsg-core] could not give %sx %s to %s (%s): %s^7'):format(amount, itemName, tostring(player.PlayerData.citizenid), tostring(src), tostring(err)))
        TriggerEvent('rsg-log:server:CreateLog', 'moneyitems', 'Money item failed', 'red', ('**%s** (%s) could not receive %sx %s: %s'):format(GetPlayerName(src) or 'unknown', player.PlayerData.citizenid, amount, itemName, tostring(err)))
        local citizenid = player.PlayerData.citizenid
        local held = false
        -- before the login reconciliation the balance still includes this money and it is retried there,
        -- so holding it as well would duplicate it
        if initialized[citizenid] or initializing[citizenid] then
            local moneytype, value = 'gold', amount
            if itemName == moneyItems.cash.dollar then moneytype = 'cash'
            elseif itemName == moneyItems.cash.cent then moneytype, value = 'cash', amount / 100
            elseif itemName == moneyItems.bloodmoney.dollar then moneytype = 'bloodmoney'
            elseif itemName == moneyItems.bloodmoney.cent then moneytype, value = 'bloodmoney', amount / 100
            end
            held = Payouts.Queue(citizenid, moneytype, value, 'inventory-full')
        end
        TriggerClientEvent('RSGCore:Client:Notify', src, { title = locale('payout.title'), description = held and locale('payout.held') or locale('error.money_item_failed'), type = held and 'warning' or 'error', duration = 10000 })
        return false
    end
    return true
end

----------------------------
-- Money operations handlers
----------------------------

local function handleAddMoney(src, moneytype, amount)
    local player = RSGCore.Functions.GetPlayer(src)
    if not player or not moneyItems[moneytype] then return end

    if moneytype == 'gold' then
        if amount > 0 then
            giveMoneyItem(player, moneyItems.gold.unit, amount)
        end
        refreshInventory(src)
        return
    end

    local dollars, cents = getParts(amount)

    if dollars > 0 then
        giveMoneyItem(player, moneyItems[moneytype].dollar, dollars)
    end
    if cents > 0 then
        giveMoneyItem(player, moneyItems[moneytype].cent, cents)
    end

    refreshInventory(src)
end

local function handleRemoveMoney(src, moneytype, amount)
    local player = RSGCore.Functions.GetPlayer(src)
    if not player or not moneyItems[moneytype] then return false end

    local inventoryMoney = getInventoryMoney(player.PlayerData)

    if moneytype == 'gold' then
        if inventoryMoney.gold < amount then return false end
        removeItems(player, moneyItems.gold.unit, amount)
        refreshInventory(src)
        return true
    end

    local centName = moneyItems[moneytype].cent
    local dollarName = moneyItems[moneytype].dollar

    local availableDollars = inventoryMoney[moneyMap[dollarName]] or 0
    local availableCents = inventoryMoney[moneyMap[centName]] or 0
    local totalAvailableCents = (availableDollars * 100) + availableCents
    local requiredCents = math.floor(amount * 100 + 0.5)

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
        giveMoneyItem(player, centName, changeInCents) 
    end

    refreshInventory(src)

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
        if amount > 0 then giveMoneyItem(player, moneyItems.gold.unit, amount) end
        refreshInventory(src)
        return
    end

    removeAllItems(moneyItems[moneytype].cent)
    removeAllItems(moneyItems[moneytype].dollar)

    local dollars, cents = getParts(amount)

    if dollars > 0 then giveMoneyItem(player, moneyItems[moneytype].dollar, dollars) end
    if cents > 0 then giveMoneyItem(player, moneyItems[moneytype].cent, cents) end

    refreshInventory(src)
end

-----------------------------------------------------------------
-- If config changed, handle inventory items accordingly on login
-----------------------------------------------------------------

local applying = {} -- [src] = true while a money change is being turned into items (pauses the sync)

local function initializeMoneyItems(src)
    local player = RSGCore.Functions.GetPlayer(src)
    if not player or not player.Functions.GetItemsByName then return end -- inventory not attached yet
    -- only run once per login; the client could otherwise re-trigger the item <-> balance reset at will
    local citizenid = player.PlayerData.citizenid
    if initialized[citizenid] or initializing[citizenid] then return end
    initializing[citizenid] = true

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
    initialized[citizenid] = true
    initializing[citizenid] = nil
    -- match the balance to the items now (anything that did not fit is held, not left spendable)
    player.Functions.UpdatePlayerData()
end

-- Started by the server. It used to wait for the client's OnPlayerLoaded, so a client that never sent it
-- kept the item <-> balance sync switched off and could duplicate money.
-- Deferred one tick so every PlayerLoaded handler (rsg-inventory adds the player item methods) has run.
AddEventHandler('RSGCore:Server:PlayerLoaded', function(Player)
    if (tonumber(source) or 0) > 0 then return end -- never from a client
    local src = Player and Player.PlayerData and Player.PlayerData.source
    if not src then return end
    SetTimeout(0, function() initializeMoneyItems(src) end)
end)

-- fallback for load flows where the inventory attaches late
RegisterNetEvent('RSGCore:Server:OnPlayerLoaded', function()
    initializeMoneyItems(source)
end)

local function clearInitialized(src)
    local player = RSGCore.Functions.GetPlayer(src)
    if player then initialized[player.PlayerData.citizenid] = nil end
end

-- server only (see the guards below): re-running the login reconciliation on demand must not be possible
AddEventHandler('RSGCore:Server:OnPlayerUnload', function(src)
    if (tonumber(source) or 0) > 0 then return end
    clearInitialized(src)
end)
AddEventHandler('RSGCore:Server:PlayerDropped', function(player)
    if (tonumber(source) or 0) > 0 then return end
    initialized[player.PlayerData.citizenid] = nil
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
        -- server only: even if another resource net-registers this event, a client must not create money with it
        if (tonumber(source) or 0) > 0 then return end
        if not IsMoneyItemEnabled(moneytype) then return end
        local handler = moneyHandlers[operation]
        if handler then
            applying[src] = true
            local ok, err = pcall(handler, src, moneytype, amount)
            applying[src] = nil -- always cleared, even after an error
            if not ok then print(('^1[rsg-core] money item %s failed for %s: %s^7'):format(operation, tostring(src), tostring(err))) end
            TriggerClientEvent('hud:client:OnMoneyChange', src, moneytype, amount, operation == 'remove')
        end
    end)

    function SynchronizeMoneyItems(playerData)
        if not initialized[playerData.citizenid] or applying[playerData.source] then return playerData end

        local money = getInventoryMoney(playerData)

        if RSGCore.Config.Money.EnableMoneyItems then
            local cash = calculateTotal(money.cashDollars, money.cashCents)
            local bloodmoney = calculateTotal(money.bloodDollars, money.bloodCents)

            if cash ~= playerData.money.cash then
                local old = playerData.money.cash or 0
                playerData.money.cash = cash
                Transactions.Record(playerData, 'cash', 'items', cash - old, cash, 'inventory change')
                TriggerClientEvent('hud:client:OnMoneyChange', playerData.source, 'cash', math.abs(cash - old), cash < old)
            end

            if bloodmoney ~= playerData.money.bloodmoney then
                local old = playerData.money.bloodmoney or 0
                playerData.money.bloodmoney = bloodmoney
                Transactions.Record(playerData, 'bloodmoney', 'items', bloodmoney - old, bloodmoney, 'inventory change')
                TriggerClientEvent('hud:client:OnMoneyChange', playerData.source, 'bloodmoney', math.abs(bloodmoney - old), bloodmoney < old)
            end
        end

        if RSGCore.Config.Gold.EnableGoldItems and money.gold ~= playerData.money.gold then
            local old = playerData.money.gold or 0
            playerData.money.gold = money.gold
            Transactions.Record(playerData, 'gold', 'items', money.gold - old, money.gold, 'inventory change')
            TriggerClientEvent('hud:client:OnMoneyChange', playerData.source, 'gold', math.abs(money.gold - old), money.gold < old)
        end

        return playerData
    end

end

