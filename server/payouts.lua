-- Held payouts: money that could not be delivered is stored here until the player claims it.
-- Used when a money item does not fit in the inventory, and for paying offline characters (QueuePayout).

Payouts = {}

local CLAIM_COOLDOWN_MS = 5000
local claiming = {}  -- [citizenid] = true while a claim is running (stops double claims)
local lastClaim = {} -- [source] = game timer of the last claim
local queued = {}    -- [citizenid] = number of payouts stored since start

local function validPayout(moneytype, amount)
    if type(moneytype) ~= 'string' or RSGCore.Config.Money.MoneyTypes[moneytype] == nil then return nil end
    amount = tonumber(amount)
    if not amount or amount ~= amount or amount <= 0 or amount >= 1e12 then return nil end
    if moneytype == 'gold' then
        if amount % 1 ~= 0 then return nil end
        return math.floor(amount)
    end
    amount = math.floor(amount * 100 + 0.5) / 100
    return amount > 0 and amount or nil
end

local function logFailure(citizenid, moneytype, amount, reason, err)
    print(('^1[rsg-core] LOST PAYOUT, could not store it: %s %s %s (%s): %s^7'):format(tostring(citizenid), tostring(amount), tostring(moneytype), tostring(reason), tostring(err)))
    TriggerEvent('rsg-log:server:CreateLog', 'moneyitems', 'Held payout failed', 'red', ('%s: %s %s (%s)'):format(tostring(citizenid), tostring(amount), tostring(moneytype), tostring(reason)))
end

---Store money for a character (online or offline) to claim later.
---@param citizenid string
---@param moneytype string
---@param amount number
---@param reason string?
---@return boolean accepted
function Payouts.Queue(citizenid, moneytype, amount, reason)
    if type(citizenid) ~= 'string' or citizenid == '' then return false end
    local value = validPayout(moneytype, amount)
    if not value then return false end
    reason = tostring(reason or 'unknown'):sub(1, 100)
    local ok, err = pcall(MySQL.insert, 'INSERT INTO rsg_held_payouts (citizenid, moneytype, amount, reason) VALUES (?, ?, ?, ?)', { citizenid, moneytype, value, reason })
    if not ok then
        logFailure(citizenid, moneytype, value, reason, err)
        return false
    end
    queued[citizenid] = (queued[citizenid] or 0) + 1
    return true
end

---Collect everything held for an online player
---@param src number
function Payouts.Claim(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local now = GetGameTimer()
    if claiming[citizenid] or (lastClaim[src] and now - lastClaim[src] < CLAIM_COOLDOWN_MS) then return end
    claiming[citizenid], lastClaim[src] = true, now

    local ok, err = pcall(function()
        -- snapshot: anything that still does not fit is stored again as a new row and is not retried here
        local rows = MySQL.query.await('SELECT id, moneytype, amount FROM rsg_held_payouts WHERE citizenid = ? ORDER BY id LIMIT 100', { citizenid }) or {}
        if #rows == 0 then
            return TriggerClientEvent('RSGCore:Client:Notify', src, { title = locale('payout.title'), description = locale('payout.none'), type = 'inform' })
        end
        local claimed = 0
        for _, row in ipairs(rows) do
            if RSGCore.Players[src] ~= Player then break end -- left or switched character
            -- delete first: only the request that removes the row may pay it
            local removed = MySQL.update.await('DELETE FROM rsg_held_payouts WHERE id = ? AND citizenid = ?', { row.id, citizenid })
            if removed == 1 then
                local amount = tonumber(row.amount)
                local before = queued[citizenid] or 0
                if RSGCore.Players[src] == Player and Player.Functions.AddMoney(row.moneytype, amount, 'held-payout') then
                    -- AddMoney also succeeds when the money item did not fit and was held again
                    if (queued[citizenid] or 0) == before then claimed = claimed + 1 end
                else
                    Payouts.Queue(citizenid, row.moneytype, amount, 'held-payout')
                end
            end
        end
        if claimed > 0 then
            TriggerClientEvent('RSGCore:Client:Notify', src, { title = locale('payout.title'), description = locale('payout.claimed'), type = 'success' })
        end
    end)
    claiming[citizenid] = nil
    if not ok then print(('^1[rsg-core] payout claim failed for %s: %s^7'):format(citizenid, tostring(err))) end
end

RSGCore.Commands.Add('claimmoney', locale('payout.command'), {}, false, function(source)
    if source > 0 then Payouts.Claim(source) end
end, 'user')

-- remind players about waiting money shortly after they load in
AddEventHandler('RSGCore:Server:PlayerLoaded', function(Player)
    if (tonumber(source) or 0) > 0 then return end
    local src = Player.PlayerData.source
    SetTimeout(10000, function()
        if RSGCore.Players[src] ~= Player then return end
        local count = MySQL.scalar.await('SELECT COUNT(*) FROM rsg_held_payouts WHERE citizenid = ?', { Player.PlayerData.citizenid })
        if (tonumber(count) or 0) > 0 then
            TriggerClientEvent('RSGCore:Client:Notify', src, { title = locale('payout.title'), description = locale('payout.waiting'), type = 'inform', duration = 10000 })
        end
    end)
end)

AddEventHandler('playerDropped', function()
    lastClaim[source] = nil
end)

RSGCore.Functions.QueuePayout = Payouts.Queue
exports('QueuePayout', Payouts.Queue)
