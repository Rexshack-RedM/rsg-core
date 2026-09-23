RSGCore.Players = {}
RSGCore.Player = {}

-- On player login get their data or set defaults
-- Don't touch any of this unless you know what you are doing
-- Will cause major issues!

local resourceName = GetCurrentResourceName()
local jsonColumns = { 'money', 'job', 'gang', 'position', 'metadata', 'charinfo' }

local function decodePlayerRow(PlayerData)
    for i = 1, #jsonColumns do
        local col = jsonColumns[i]
        PlayerData[col] = json.decode(PlayerData[col] or 'null')
    end
    return PlayerData
end

local function playerLabel(src)
    return GetPlayerName(src) or ('ID ' .. tostring(src))
end
function RSGCore.Player.Login(source, citizenid, newData)
    if source and source ~= '' then
        if citizenid then
            local license = RSGCore.Functions.GetIdentifier(source, 'license')
            local PlayerData = MySQL.prepare.await('SELECT * FROM players where citizenid = ?', { citizenid })
            if PlayerData and license == PlayerData.license then
                RSGCore.Player.CheckPlayerData(source, decodePlayerRow(PlayerData))
            else
                TriggerEvent('rsg-log:server:CreateLog', 'anticheat', 'Anti-Cheat', 'white', playerLabel(source) .. ' Has Been Dropped For Character Joining Exploit', false)
                DropPlayer(source, Lang:t('info.exploit_dropped'))
                return false
            end
        else
            RSGCore.Player.CheckPlayerData(source, newData)
        end
        return true
    else
        RSGCore.ShowError(resourceName, 'ERROR RSGCore.PLAYER.LOGIN - NO SOURCE GIVEN!')
        return false
    end
end

function RSGCore.Player.GetOfflinePlayer(citizenid)
    if citizenid then
        local PlayerData = MySQL.prepare.await('SELECT * FROM players where citizenid = ?', { citizenid })
        if PlayerData then
            return RSGCore.Player.CheckPlayerData(nil, decodePlayerRow(PlayerData))
        end
    end
    return nil
end

function RSGCore.Player.GetPlayerByLicense(license)
    if license then
        local source = RSGCore.Functions.GetSource(license)
        if source > 0 then
            return RSGCore.Players[source]
        else
            return RSGCore.Player.GetOfflinePlayerByLicense(license)
        end
    end
    return nil
end

function RSGCore.Player.GetOfflinePlayerByLicense(license)
    if license then
        local PlayerData = MySQL.prepare.await('SELECT * FROM players where license = ?', { license })
        if PlayerData then
            return RSGCore.Player.CheckPlayerData(nil, decodePlayerRow(PlayerData))
        end
    end
    return nil
end

local function applyDefaults(playerData, defaults)
    for key, value in pairs(defaults) do
        if type(value) == 'function' then
            playerData[key] = playerData[key] or value()
        elseif type(value) == 'table' then
            playerData[key] = playerData[key] or {}
            applyDefaults(playerData[key], value)
        else
            playerData[key] = playerData[key] or value
        end
    end
end

function RSGCore.Player.CheckPlayerData(source, PlayerData)
    PlayerData = PlayerData or {}
    local Offline = not source

    if source then
        PlayerData.source = source
        PlayerData.license = PlayerData.license or RSGCore.Functions.GetIdentifier(source, 'license')
        PlayerData.name = GetPlayerName(source)
    end

    local validatedJob = false
    if PlayerData.job and PlayerData.job.name ~= nil and PlayerData.job.grade and PlayerData.job.grade.level ~= nil then
        local jobInfo = RSGCore.Shared.Jobs[PlayerData.job.name]

        if jobInfo then
            local jobGradeInfo = jobInfo.grades[tostring(PlayerData.job.grade.level)]
            if jobGradeInfo then
                PlayerData.job.label = jobInfo.label
                PlayerData.job.grade.name = jobGradeInfo.name
                PlayerData.job.payment = jobGradeInfo.payment
                PlayerData.job.grade.isboss = jobGradeInfo.isboss or false
                PlayerData.job.isboss = jobGradeInfo.isboss or false
                validatedJob = true
            end
        end
    end

    if validatedJob == false then
        -- set to nil, as the default job (unemployed) will be added by `applyDefaults`
        PlayerData.job = nil
    end

    local validatedGang = false
    if PlayerData.gang and PlayerData.gang.name ~= nil and PlayerData.gang.grade and PlayerData.gang.grade.level ~= nil then
        local gangInfo = RSGCore.Shared.Gangs[PlayerData.gang.name]

        if gangInfo then
            local gangGradeInfo = gangInfo.grades[tostring(PlayerData.gang.grade.level)]
            if gangGradeInfo then
                PlayerData.gang.label = gangInfo.label
                PlayerData.gang.grade.name = gangGradeInfo.name
                PlayerData.gang.payment = gangGradeInfo.payment
                PlayerData.gang.grade.isboss = gangGradeInfo.isboss or false
                PlayerData.gang.isboss = gangGradeInfo.isboss or false
                validatedGang = true
            end
        end
    end

    if validatedGang == false then
        -- set to nil, as the default gang (unemployed) will be added by `applyDefaults`
        PlayerData.gang = nil
    end

    applyDefaults(PlayerData, RSGCore.Config.Player.PlayerDefaults)

    if GetResourceState('rsg-inventory') ~= 'missing' then
        PlayerData.items = exports['rsg-inventory']:LoadInventory(PlayerData.source, PlayerData.citizenid)
    end

    return RSGCore.Player.CreatePlayer(PlayerData, Offline)
end

-- On player logout

function RSGCore.Player.Logout(source)
    TriggerClientEvent('RSGCore:Client:OnPlayerUnload', source)
    TriggerEvent('RSGCore:Server:OnPlayerUnload', source)
    -- save directly on the server instead of round-tripping through the client
    if RSGCore.Players[source] then RSGCore.Players[source].Functions.Save() end
    Wait(200)
    RSGCore.Players[source] = nil
end

-- Create a new character
-- Don't touch any of this unless you know what you are doing
-- Will cause major issues!

local stateBagKeys = { 'hunger', 'thirst', 'cleanliness', 'stress', 'health' }

-- numeric metadata that must stay within a range
local clampedMeta = {
    hunger = { 0, 100 },
    thirst = { 0, 100 },
    cleanliness = { 0, 100 },
    stress = { 0, 100 },
    health = { 0, 10000 },
    armor = { 0, 100 },
}

local function isValidAmount(amount)
    return amount ~= nil and amount == amount and amount >= 0 and amount ~= math.huge
end

local function moneyLog(self, action, color, moneytype, amount, reason, verb)
    local d = self.PlayerData
    TriggerEvent('rsg-log:server:CreateLog', 'playermoney', action, color,
        ('**%s (citizenid: %s | id: %s)** $%s (%s) %s, new %s balance: %s reason: %s'):format(
            playerLabel(d.source), d.citizenid, d.source, amount, moneytype, verb, moneytype, d.money[moneytype], reason),
        amount > 100000)
end

function RSGCore.Player.CreatePlayer(PlayerData, Offline)
    local self = {}
    self.Functions = {}
    self.PlayerData = PlayerData
    self.Offline = Offline

    function self.Functions.UpdatePlayerData()
        if self.Offline then return end

        if RSGCore.Config.Money.EnableMoneyItems or RSGCore.Config.Gold.EnableGoldItems then
            self.PlayerData = SynchronizeMoneyItems(self.PlayerData)
        end

        TriggerEvent('RSGCore:Player:SetPlayerData', self.PlayerData)
        TriggerClientEvent('RSGCore:Player:SetPlayerData', self.PlayerData.source, self.PlayerData)
    end

    function self.Functions.SetJob(job, grade)
        if type(job) ~= 'string' then return false end
        job = job:lower()
        grade = grade or '0'
        if not RSGCore.Shared.Jobs[job] then return false end
        self.PlayerData.job = {
            name = job,
            label = RSGCore.Shared.Jobs[job].label,
            onduty = RSGCore.Shared.Jobs[job].defaultDuty,
            type = RSGCore.Shared.Jobs[job].type or 'none',
            payment = 0,
            isboss = false,
            grade = {
                name = 'No Grades',
                level = 0,
                payment = 30,
                isboss = false
            }
        }
        local gradeKey = tostring(grade)
        local jobGradeInfo = RSGCore.Shared.Jobs[job].grades[gradeKey]
        if jobGradeInfo then
            self.PlayerData.job.grade.name = jobGradeInfo.name
            self.PlayerData.job.grade.level = tonumber(gradeKey)
            self.PlayerData.job.grade.payment = jobGradeInfo.payment
            self.PlayerData.job.payment = jobGradeInfo.payment or 0
            self.PlayerData.job.grade.isboss = jobGradeInfo.isboss or false
            self.PlayerData.job.isboss = jobGradeInfo.isboss or false
        end

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            TriggerEvent('RSGCore:Server:OnJobUpdate', self.PlayerData.source, self.PlayerData.job)
            TriggerClientEvent('RSGCore:Client:OnJobUpdate', self.PlayerData.source, self.PlayerData.job)
        end

        return true
    end

    function self.Functions.SetGang(gang, grade)
        if type(gang) ~= 'string' then return false end
        gang = gang:lower()
        grade = grade or '0'
        if not RSGCore.Shared.Gangs[gang] then return false end
        self.PlayerData.gang = {
            name = gang,
            label = RSGCore.Shared.Gangs[gang].label,
            isboss = false,
            grade = {
                name = 'No Grades',
                level = 0,
                isboss = false
            }
        }
        local gradeKey = tostring(grade)
        local gangGradeInfo = RSGCore.Shared.Gangs[gang].grades[gradeKey]
        if gangGradeInfo then
            self.PlayerData.gang.grade.name = gangGradeInfo.name
            self.PlayerData.gang.grade.level = tonumber(gradeKey)
            self.PlayerData.gang.grade.isboss = gangGradeInfo.isboss or false
            self.PlayerData.gang.isboss = gangGradeInfo.isboss or false
        end

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            TriggerEvent('RSGCore:Server:OnGangUpdate', self.PlayerData.source, self.PlayerData.gang)
            TriggerClientEvent('RSGCore:Client:OnGangUpdate', self.PlayerData.source, self.PlayerData.gang)
        end

        return true
    end

    function self.Functions.HasItem(items, amount)
        return RSGCore.Functions.HasItem(self.PlayerData.source, items, amount)
    end

    function self.Functions.SetJobDuty(onDuty)
        self.PlayerData.job.onduty = not not onDuty
        TriggerEvent('RSGCore:Server:OnJobUpdate', self.PlayerData.source, self.PlayerData.job)
        TriggerClientEvent('RSGCore:Client:OnJobUpdate', self.PlayerData.source, self.PlayerData.job)
        self.Functions.UpdatePlayerData()
    end

    function self.Functions.SetPlayerData(key, val)
        if not key or type(key) ~= 'string' then return end
        self.PlayerData[key] = val
        self.Functions.UpdatePlayerData()
    end

    function self.Functions.SetMetaData(meta, val)
        local function validateData(key, value)
            if clampedMeta[key] then
                -- non-numeric values (e.g. a client-set statebag) previously crashed Save()
                value = tonumber(value)
                if not value or value ~= value then return self.PlayerData.metadata[key] end
                value = lib.math.clamp(value, clampedMeta[key][1], clampedMeta[key][2])
            end
            return value
        end

        if type(meta) == 'table' then
            for key, value in pairs(meta) do
                self.PlayerData.metadata[key] = validateData(key, value)
            end
            self.Functions.UpdatePlayerData()
            return
        end
    
        if type(meta) ~= 'string' then return end
        self.PlayerData.metadata[meta] = validateData(meta, val)
        self.Functions.UpdatePlayerData()
    end

    function self.Functions.GetMetaData(meta)
        if not meta or type(meta) ~= 'string' then return end
        return self.PlayerData.metadata[meta]
    end

    function self.Functions.AddRep(rep, amount)
        local addAmount = tonumber(amount)
        if not rep or not addAmount then return end
        local currentRep = self.PlayerData.metadata['rep'][rep] or 0
        self.PlayerData.metadata['rep'][rep] = currentRep + addAmount
        self.Functions.UpdatePlayerData()
    end

    function self.Functions.RemoveRep(rep, amount)
        local removeAmount = tonumber(amount)
        if not rep or not removeAmount then return end
        local currentRep = self.PlayerData.metadata['rep'][rep] or 0
        self.PlayerData.metadata['rep'][rep] = math.max(0, currentRep - removeAmount)
        self.Functions.UpdatePlayerData()
    end

    function self.Functions.GetRep(rep)
        if not rep then return end
        return self.PlayerData.metadata['rep'][rep] or 0
    end

    ---Shared validation for money operations. Returns the normalised moneytype and amount, or nil.
    local function prepMoney(moneytype, amount)
        if type(moneytype) ~= 'string' then return end
        moneytype = moneytype:lower()
        amount = tonumber(amount)
        if not isValidAmount(amount) then return end -- rejects nil, NaN, negative and infinite amounts
        if moneytype == 'gold' and amount % 1 ~= 0 then return end
        if not self.PlayerData.money[moneytype] then return end
        return moneytype, amount
    end

    local function onMoneyChanged(moneytype, amount, operation, reason, hudAmount, hudIsMinus)
        if not IsMoneyItemEnabled(moneytype) then
            TriggerClientEvent('hud:client:OnMoneyChange', self.PlayerData.source, moneytype, hudAmount, hudIsMinus)
        end
        TriggerClientEvent('RSGCore:Client:OnMoneyChange', self.PlayerData.source, moneytype, amount, operation, reason)
        TriggerEvent('RSGCore:Server:OnMoneyChange', self.PlayerData.source, moneytype, amount, operation, reason)
    end

    function self.Functions.AddMoney(moneytype, amount, reason)
        reason = reason or 'unknown'
        moneytype, amount = prepMoney(moneytype, amount)
        if not moneytype then return false end
        self.PlayerData.money[moneytype] = self.PlayerData.money[moneytype] + amount

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            moneyLog(self, 'AddMoney', 'lightgreen', moneytype, amount, reason, 'added')
            onMoneyChanged(moneytype, amount, 'add', reason, amount, false)
        end

        return true
    end

    function self.Functions.RemoveMoney(moneytype, amount, reason)
        reason = reason or 'unknown'
        moneytype, amount = prepMoney(moneytype, amount)
        if not moneytype then return false end
        local newBalance = self.PlayerData.money[moneytype] - amount
        for _, mtype in pairs(RSGCore.Config.Money.DontAllowMinus) do
            if mtype == moneytype and newBalance < 0 then return false end
        end
        if newBalance < RSGCore.Config.Money.MinusLimit then return false end
        self.PlayerData.money[moneytype] = newBalance

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            moneyLog(self, 'RemoveMoney', 'red', moneytype, amount, reason, 'removed')
            onMoneyChanged(moneytype, amount, 'remove', reason, amount, true)
        end

        return true
    end

    function self.Functions.SetMoney(moneytype, amount, reason)
        reason = reason or 'unknown'
        moneytype, amount = prepMoney(moneytype, amount)
        if not moneytype then return false end
        local difference = amount - self.PlayerData.money[moneytype]
        self.PlayerData.money[moneytype] = amount

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            moneyLog(self, 'SetMoney', 'green', moneytype, amount, reason, 'set')
            onMoneyChanged(moneytype, amount, 'set', reason, math.abs(difference), difference < 0)
        end

        return true
    end

    function self.Functions.GetMoney(moneytype)
        if type(moneytype) ~= 'string' then return false end
        moneytype = moneytype:lower()
        return self.PlayerData.money[moneytype]
    end

    function self.Functions.Save()
        if self.Offline then
            RSGCore.Player.SaveOffline(self.PlayerData)
        else
            self.Functions.PersistStateBags()
            RSGCore.Player.Save(self.PlayerData.source)
        end
    end

    function self.Functions.Logout()
        if self.Offline then return end
        RSGCore.Player.Logout(self.PlayerData.source)
    end

    function self.Functions.AddMethod(methodName, handler)
        self.Functions[methodName] = handler
    end

    function self.Functions.AddField(fieldName, data)
        self[fieldName] = data
    end

    function self.Functions.PersistStateBags()
        local metadata = {}
        local state = Player(self.PlayerData.source).state
        for _, key in ipairs(stateBagKeys) do
            if state[key] ~= nil then
                metadata[key] = state[key]
            end
        end
    
        if next(metadata) then
            self.Functions.SetMetaData(metadata)
        end
    end

    function self.Functions.InitializeStateBags()
        local metadata = self.PlayerData.metadata
        local state = Player(self.PlayerData.source).state
        for _, key in ipairs(stateBagKeys) do
            if metadata[key] ~= nil then
                state[key] = metadata[key]
            end
        end
    end

    if self.Offline then
        return self
    else
        self.Functions.InitializeStateBags()
        RSGCore.Players[self.PlayerData.source] = self
        RSGCore.Player.Save(self.PlayerData.source)
        TriggerEvent('RSGCore:Server:PlayerLoaded', self)
        self.Functions.UpdatePlayerData()
    end
end

-- Add a new function to the Functions table of the player class
-- Use-case:
--[[
    AddEventHandler('RSGCore:Server:PlayerLoaded', function(Player)
        RSGCore.Functions.AddPlayerMethod(Player.PlayerData.source, "functionName", function(oneArg, orMore)
            -- do something here
        end)
    end)
]]

function RSGCore.Functions.AddPlayerMethod(ids, methodName, handler)
    local idType = type(ids)
    if idType == 'number' then
        if ids == -1 then
            for _, v in pairs(RSGCore.Players) do
                v.Functions.AddMethod(methodName, handler)
            end
        else
            if not RSGCore.Players[ids] then return end

            RSGCore.Players[ids].Functions.AddMethod(methodName, handler)
        end
    elseif idType == 'table' and table.type(ids) == 'array' then
        for i = 1, #ids do
            RSGCore.Functions.AddPlayerMethod(ids[i], methodName, handler)
        end
    end
end

-- Add a new field table of the player class
-- Use-case:
--[[
    AddEventHandler('RSGCore:Server:PlayerLoaded', function(Player)
        RSGCore.Functions.AddPlayerField(Player.PlayerData.source, "fieldName", "fieldData")
    end)
]]

function RSGCore.Functions.AddPlayerField(ids, fieldName, data)
    local idType = type(ids)
    if idType == 'number' then
        if ids == -1 then
            for _, v in pairs(RSGCore.Players) do
                v.Functions.AddField(fieldName, data)
            end
        else
            if not RSGCore.Players[ids] then return end

            RSGCore.Players[ids].Functions.AddField(fieldName, data)
        end
    elseif idType == 'table' and table.type(ids) == 'array' then
        for i = 1, #ids do
            RSGCore.Functions.AddPlayerField(ids[i], fieldName, data)
        end
    end
end

-- Save player info to database (make sure citizenid is the primary key in your database)

local SAVE_QUERY = 'INSERT INTO players (citizenid, cid, license, name, money, charinfo, job, gang, position, metadata, weight, slots) VALUES (:citizenid, :cid, :license, :name, :money, :charinfo, :job, :gang, :position, :metadata, :weight, :slots) ON DUPLICATE KEY UPDATE cid = :cid, name = :name, money = :money, charinfo = :charinfo, job = :job, gang = :gang, position = :position, metadata = :metadata, weight = :weight, slots = :slots'

local function savePlayerRow(PlayerData, position)
    MySQL.insert(SAVE_QUERY, {
        citizenid = PlayerData.citizenid,
        cid = tonumber(PlayerData.cid),
        license = PlayerData.license,
        name = PlayerData.name,
        money = json.encode(PlayerData.money),
        charinfo = json.encode(PlayerData.charinfo),
        job = json.encode(PlayerData.job),
        gang = json.encode(PlayerData.gang),
        position = json.encode(position),
        metadata = json.encode(PlayerData.metadata),
        weight = PlayerData.weight,
        slots = PlayerData.slots,
    })
end

function RSGCore.Player.Save(source)
    local Player = RSGCore.Players[source]
    if not Player or not Player.PlayerData then
        return RSGCore.ShowError(resourceName, 'ERROR RSGCore.PLAYER.SAVE - PLAYERDATA IS EMPTY!')
    end
    local PlayerData = Player.PlayerData
    local pcoords = GetEntityCoords(GetPlayerPed(source))
    -- keep the last known position if the ped is not available (e.g. mid-disconnect), instead of saving 0,0,0
    if pcoords.x == 0.0 and pcoords.y == 0.0 and pcoords.z == 0.0 then
        pcoords = PlayerData.position
    end
    savePlayerRow(PlayerData, pcoords)
    if GetResourceState('rsg-inventory') ~= 'missing' then exports['rsg-inventory']:SaveInventory(source) end
    RSGCore.ShowSuccess(resourceName, PlayerData.name .. ' PLAYER SAVED!')
end

function RSGCore.Player.SaveOffline(PlayerData)
    if not PlayerData then
        return RSGCore.ShowError(resourceName, 'ERROR RSGCore.PLAYER.SAVEOFFLINE - PLAYERDATA IS EMPTY!')
    end
    savePlayerRow(PlayerData, PlayerData.position)
    if GetResourceState('rsg-inventory') ~= 'missing' then exports['rsg-inventory']:SaveInventory(PlayerData, true) end
    RSGCore.ShowSuccess(resourceName, PlayerData.name .. ' OFFLINE PLAYER SAVED!')
end

-- Delete character

local playertables = { -- Add tables as needed
    { table = 'players'},
    { table = 'playeroutfit'},
    { table = 'playerskins'},
    { table = 'player_horses'},
    { table = 'player_weapons'},
    { table = 'address_book'},
    { table = 'telegrams'},
}

local function deleteCharacterRows(citizenid, onDone)
    local queries = table.create(#playertables, 0)
    for i = 1, #playertables do
        queries[i] = { query = ('DELETE FROM %s WHERE citizenid = ?'):format(playertables[i].table), values = { citizenid } }
    end
    MySQL.transaction(queries, function(result)
        if result then onDone() end
    end)
end

function RSGCore.Player.DeleteCharacter(source, citizenid)
    local license = RSGCore.Functions.GetIdentifier(source, 'license')
    local result = MySQL.scalar.await('SELECT license FROM players where citizenid = ?', { citizenid })
    if license and license == result then
        deleteCharacterRows(citizenid, function()
            TriggerEvent('rsg-log:server:CreateLog', 'joinleave', 'Character Deleted', 'red', ('**%s** %s deleted **%s**..'):format(playerLabel(source), license, citizenid))
        end)
    else
        TriggerEvent('rsg-log:server:CreateLog', 'anticheat', 'Anti-Cheat', 'white', playerLabel(source) .. ' Has Been Dropped For Character Deletion Exploit', true)
        DropPlayer(source, Lang:t('info.exploit_dropped'))
    end
end

function RSGCore.Player.ForceDeleteCharacter(citizenid)
    local result = MySQL.scalar.await('SELECT license FROM players where citizenid = ?', { citizenid })
    if not result then return end
    local Player = RSGCore.Functions.GetPlayerByCitizenId(citizenid)
    if Player then
        DropPlayer(Player.PlayerData.source, Lang:t('info.character_deleted_by_admin'))
    end
    deleteCharacterRows(citizenid, function()
        TriggerEvent('rsg-log:server:CreateLog', 'joinleave', 'Character Force Deleted', 'red', 'Character **' .. citizenid .. '** got deleted')
    end)
end

-- Inventory Backwards Compatibility

function RSGCore.Player.SaveInventory(source)
    if GetResourceState('rsg-inventory') == 'missing' then return end
    exports['rsg-inventory']:SaveInventory(source, false)
end

function RSGCore.Player.SaveOfflineInventory(PlayerData)
    if GetResourceState('rsg-inventory') == 'missing' then return end
    exports['rsg-inventory']:SaveInventory(PlayerData, true)
end

function RSGCore.Player.GetTotalWeight(items)
    if GetResourceState('rsg-inventory') == 'missing' then return end
    return exports['rsg-inventory']:GetTotalWeight(items)
end

function RSGCore.Player.GetSlotsByItem(items, itemName)
    if GetResourceState('rsg-inventory') == 'missing' then return end
    return exports['rsg-inventory']:GetSlotsByItem(items, itemName)
end

function RSGCore.Player.GetFirstSlotByItem(items, itemName)
    if GetResourceState('rsg-inventory') == 'missing' then return end
    return exports['rsg-inventory']:GetFirstSlotByItem(items, itemName)
end

-- Util Functions

function RSGCore.Player.CreateCitizenId()
    local CitizenId = tostring(RSGCore.Shared.RandomStr(3) .. RSGCore.Shared.RandomInt(5)):upper()
    local result = MySQL.prepare.await('SELECT EXISTS(SELECT 1 FROM players WHERE citizenid = ?) AS uniqueCheck', { CitizenId })
    if result == 0 then return CitizenId end
    return RSGCore.Player.CreateCitizenId()
end

function RSGCore.Functions.CreateAccountNumber()
    local AccountNumber = 'US0' .. math.random(1, 9) .. 'RSGCore' .. math.random(1111, 9999) .. math.random(1111, 9999) .. math.random(11, 99)
    local result = MySQL.prepare.await('SELECT EXISTS(SELECT 1 FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(charinfo, "$.account")) = ?) AS uniqueCheck', { AccountNumber })
    if result == 0 then return AccountNumber end
    return RSGCore.Functions.CreateAccountNumber()
end

function RSGCore.Player.CreateFingerId()
    local FingerId = tostring(RSGCore.Shared.RandomStr(2) .. RSGCore.Shared.RandomInt(3) .. RSGCore.Shared.RandomStr(1) .. RSGCore.Shared.RandomInt(2) .. RSGCore.Shared.RandomStr(3) .. RSGCore.Shared.RandomInt(4))
    local result = MySQL.prepare.await('SELECT EXISTS(SELECT 1 FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(metadata, "$.fingerprint")) = ?) AS uniqueCheck', { FingerId })
    if result == 0 then return FingerId end
    return RSGCore.Player.CreateFingerId()
end

function RSGCore.Player.CreateWalletId()
    local WalletId = 'RSG-' .. math.random(11111111, 99999999)
    local result = MySQL.prepare.await('SELECT EXISTS(SELECT 1 FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(metadata, "$.walletid")) = ?) AS uniqueCheck', { WalletId })
    if result == 0 then return WalletId end
    return RSGCore.Player.CreateWalletId()
end

function RSGCore.Player.CreateSerialNumber()
    local SerialNumber = math.random(11111111, 99999999)
    local result = MySQL.prepare.await('SELECT EXISTS(SELECT 1 FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(metadata, "$.phonedata.SerialNumber")) = ?) AS uniqueCheck', { SerialNumber })
    if result == 0 then return SerialNumber end
    return RSGCore.Player.CreateSerialNumber()
end

PaycheckInterval() -- This starts the paycheck system
