# rsg-core Developer Documentation

> Version **3.4.0** · RedM · Lua 5.4 · Depends only on `oxmysql`
> rsg-core has no **ox_lib** dependency and no ox_lib compatibility code: notifications, callbacks, progress bars, text UI, prompts, locales, `require` and asset loaders are all built in.

---

## Contents

1. [Getting the Core Object](#1-getting-the-core-object)
2. [Resource Setup (fxmanifest)](#2-resource-setup-fxmanifest)
3. [Locales](#3-locales)
4. [Module Loader (`require`)](#4-module-loader-require)
5. [Callbacks](#5-callbacks)
6. [Server Functions](#6-server-functions)
7. [The Player Object (server)](#7-the-player-object-server)
8. [Money](#8-money)
9. [Jobs, Gangs & Multi-Job](#9-jobs-gangs--multi-job)
10. [Shared Data (Items / Jobs / Gangs)](#10-shared-data-items--jobs--gangs)
11. [Usable Items](#11-usable-items)
12. [Permissions](#12-permissions)
13. [Commands](#13-commands)
14. [Client Functions](#14-client-functions)
15. [Notifications](#15-notifications)
16. [Progress Bar / Circle](#16-progress-bar--circle)
17. [Text UI (DrawText)](#17-text-ui-drawtext)
18. [Prompts](#18-prompts)
19. [Routing Buckets](#19-routing-buckets)
20. [Events Reference](#20-events-reference)
21. [State Bags](#21-state-bags)
22. [Shared Utilities (`RSGCore.Shared`)](#22-shared-utilities-rsgcoreshared)
23. [Configuration Reference](#23-configuration-reference)
24. [Exports Reference](#24-exports-reference)
25. [ox_lib Migration Cheat Sheet](#25-ox_lib-migration-cheat-sheet)
26. [Security Notes](#26-security-notes)
27. [Complete Example Resource](#27-complete-example-resource)
28. [Database Schema](#28-database-schema)
29. [Return Values & Error Codes](#29-return-values--error-codes)

---

## 1. Getting the Core Object

Works on both client and server:

```lua
local RSGCore = exports['rsg-core']:GetCoreObject()
```

If your resource needs to see functions/fields added at runtime by other resources (`SetMethod`, `SetField`, `AddItem`, …), refresh your copy:

```lua
-- server
AddEventHandler('RSGCore:Server:UpdateObject', function()
    RSGCore = exports['rsg-core']:GetCoreObject()
end)
-- client
RegisterNetEvent('RSGCore:Client:UpdateObject', function()
    RSGCore = exports['rsg-core']:GetCoreObject()
end)
```

Top-level tables on the object:

| Field | Side | Description |
|---|---|---|
| `RSGCore.Functions` | both | All framework functions |
| `RSGCore.Shared` | both | Items, Jobs, Gangs, Weapons, Vehicles, Locations, Keybinds + helpers |
| `RSGCore.Config` | both | `RSGConfig` from `shared/config.lua` |
| `RSGCore.PlayerData` | client | Local player's data (kept in sync) |
| `RSGCore.Players` | server | `[source] = Player` for every logged-in player |
| `RSGCore.Player` | server | Player lifecycle helpers (Login, Save, CreateCitizenId…) |
| `RSGCore.Commands` | server | Command registry (`Add`, `Refresh`) |

---

## 2. Resource Setup (fxmanifest)

```lua
fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'
lua54 'yes'

shared_scripts {
    '@rsg-core/shared/locale.lua',   -- locale()
    '@rsg-core/shared/require.lua',  -- require() (optional)
    'config.lua',
}
client_scripts { 'client/*.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/*.lua' }
files { 'locales/*.json' }

dependencies { 'rsg-core', 'oxmysql' }
```

Load order in `server.cfg`:

```cfg
ensure oxmysql
ensure rsg-core
```

> rsg-core `provide`s **rsg-multijob**, so old `dependency 'rsg-multijob'` lines and `exports['rsg-multijob']:...` calls still resolve. Do **not** run the old rsg-multijob resource.

---

## 3. Locales

Include `@rsg-core/shared/locale.lua` and ship `locales/<lang>.json` in your resource.

```cfg
setr rsg:locale "en"   # falls back to en
```

```lua
locale('notify.bought', itemLabel, price) -- string.format args
locale()                                   -- whole flattened dictionary (e.g. send to NUI)
GetLocaleLanguage()                        -- 'en'
```

- Nested JSON is flattened to dot keys: `{ "notify": { "bought": "..." } }` → `locale('notify.bought')`.
- `"${other.key}"` inside a string is substituted.
- Missing keys fall back to `en.json`, then to the key itself.
- Locale files support nested keys and `${key}` references.
- Server standard languages: `en, de, el, es, fr, ja, nl, pl, pt-br, ro, ru`.

---

## 4. Module Loader (`require`)

Include `@rsg-core/shared/require.lua`:

```lua
local data  = require 'data.clothing'                 -- this resource: data/clothing.lua
local cfg   = require 'shared.config'                 -- or shared/config/init.lua
local items = require '@rsg-inventory.shared.items'   -- file in another started resource
```

Modules are cached per resource and side. Circular requires raise an error. A module returning nothing is cached as `true`.

---

## 5. Callbacks

Each request has its own id, so concurrent calls to the same callback never overwrite each other.

### Server callbacks (client → server)

```lua
-- server
RSGCore.Functions.CreateCallback('myres:server:getData', function(source, cb, arg1)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end
    cb({ cash = Player.Functions.GetMoney('cash') })
end)

-- client: async
RSGCore.Functions.TriggerCallback('myres:server:getData', function(result)
    print(result.cash)
end, 'arg1')

-- client: sync (inside a thread) — replaces lib.callback.await
local result = RSGCore.Functions.AwaitCallback('myres:server:getData', 10000, 'arg1')
```

`AwaitCallback(name, timeout?, ...)` — `timeout` defaults to `10000` ms; `false`/`0` waits forever. Returns `nil` on timeout.

### Client callbacks (server → client)

```lua
-- client
RSGCore.Functions.CreateClientCallback('myres:client:getHeading', function(cb)
    cb(GetEntityHeading(PlayerPedId()))
end)

-- server: async
RSGCore.Functions.TriggerClientCallback('myres:client:getHeading', source, function(h) end)
-- server: sync (inside a thread)
local heading = RSGCore.Functions.AwaitClientCallback('myres:client:getHeading', source, 5000)
```

---

## 6. Server Functions

### Players

| Function | Returns | Notes |
|---|---|---|
| `GetPlayer(source)` | Player \| nil | Accepts a server id |
| `GetPlayerByCitizenId(citizenid)` | Player \| nil | Online only |
| `GetOfflinePlayerByCitizenId(citizenid)` | Player \| nil | Loads from DB (Offline player object) |
| `GetPlayerByLicense(license)` | Player \| nil | |
| `GetPlayerByAccount(account)` | Player \| nil | Matches `charinfo.account` |
| `GetPlayerByCharInfo(property, value)` | Player \| nil | e.g. `('firstname', 'Arthur')` |
| `GetPlayers()` | `{ source, … }` | All connected server ids |
| `GetRSGPlayers()` | `RSGCore.Players` | Table of Player objects |
| `GetPlayersOnDuty(job)` | `players, count` | |
| `GetDutyCount(job)` | number | |
| `GetIdentifier(source, idtype?)` | string | default `'license'` |
| `GetSource(identifier)` | number \| 0 | From license etc. |
| `IsLicenseInUse(license)` | boolean | |
| `Kick(source, reason, setKickReason?, deferrals?)` | | Appends Discord link |
| `IsWhitelisted(source)` / `IsPlayerBanned(source)` | boolean(, msg) | |
| `SetServerClosed(closed, reason)` | | |
| `IsOptin(source)` / `ToggleOptin(source)` | | Admin message opt-in |

### World / Entities

| Function | Notes |
|---|---|
| `GetCoords(entity)` | `vector4` |
| `GetClosestPlayer(source, coords?)` | `playerId, distance` |
| `GetClosestObject(source, coords?)` / `GetClosestVehicle` / `GetClosestPed` | server-side entity pools |
| `SpawnVehicle(source, model, coords?, warp?)` | Uses `CreateVehicle` server-side, returns netId |
| `CreateVehicle(source, model, vehtype, coords, warp)` | `CreateVehicleServerSetter` |

### Inventory helpers (proxy to rsg-inventory)

| Function | Notes |
|---|---|
| `HasItem(source, items, amount?)` | `items` can be a string or table |
| `CanCarryItem(source, item, amount)` | |
| `ChangeWeight(source, weight)` / `ChangeSlots(source, slots)` | Updates player's max weight / slots |
| `UseItem(source, item)` | |

### Misc

| Function | Notes |
|---|---|
| `Notify(source, text, type?, duration?)` | `text` may be a full table (see §15) |
| `PrepForSQL(source, data, pattern)` | Returns `true` if the **whole** string matches the Lua pattern. On failure it logs an `anticheat` entry and returns `false` (it does **not** kick; you decide what to do) |
| `GetDatabaseInfo()` | `{ exists, database }` |
| `RSGCore.Debug(tbl, indent?)` | Pretty-prints to server console |
| `RSGCore.ShowError(resource, msg)` / `ShowSuccess(resource, msg)` | Coloured console output |
| `RSGCore.Functions.CreateAccountNumber()` | |
| `RSGCore.Functions.CreateCron(expression, job, options?)` | Scheduled task, replaces `lib.cron.new` – see *Cron scheduler* below |
| `RSGCore.Functions.StopCron(taskOrId)` | Stops a cron task |
| `RSGCore.Player.CreateCitizenId()` / `CreateFingerId()` / `CreateWalletId()` / `CreateSerialNumber()` | Unique id generators |

### Server function examples

```lua
-- find a player and read their data
local Player = RSGCore.Functions.GetPlayer(source)
if not Player then return end
local citizenid = Player.PlayerData.citizenid

-- online lookups
local target  = RSGCore.Functions.GetPlayerByCitizenId('ABC12345')       -- nil if offline
local offline = RSGCore.Functions.GetOfflinePlayerByCitizenId('ABC12345') -- loads from DB
local byName  = RSGCore.Functions.GetPlayerByCharInfo('firstname', 'Arthur')

-- everyone on duty as a lawman
local onDuty, count = RSGCore.Functions.GetPlayersOnDuty('vallaw')
for _, src in ipairs(onDuty) do
    RSGCore.Functions.Notify(src, 'Alarm at the bank!', 'warning')
end

-- nearest other player (returns -1, -1 if nobody else is connected)
local closestId, distance = RSGCore.Functions.GetClosestPlayer(source)
if closestId ~= -1 and distance < 3.0 then
    -- close enough to interact
end

-- inventory helpers (proxy to rsg-inventory)
if RSGCore.Functions.HasItem(source, 'bandage', 2) then end
if RSGCore.Functions.HasItem(source, { 'water', 'bread' }) then end

-- validate untrusted strings before they touch SQL
if not RSGCore.Functions.PrepForSQL(source, data.name, '^[%w ]+$') then return end

-- kick with the Discord link appended
RSGCore.Functions.Kick(source, 'You have been removed from the server')

-- close / open the server
RSGCore.Functions.SetServerClosed(true, 'Restarting in 5 minutes')
```

### Cron scheduler (replaces `lib.cron`)

```lua
local task = RSGCore.Functions.CreateCron('0 * * * *', function(task, date)
    -- runs every hour on the hour (server local time); date = os.date('*t')
end, { debug = false })        -- or exports['rsg-core']:CreateCron(...)

RSGCore.Functions.StopCron(task.id)   -- or task:stop() / task:isActive() / task:run()
```

- Standard 5-field expression: `minute hour day month weekday`.
- Supports `*`, `n`, `a-b`, `a,b,c`, `*/n`, `a-b/n`, month names `jan`–`dec`, day names `sun`–`sat` (`0` or `7` = Sunday).
- Macros: `@yearly`/`@annually`, `@monthly`, `@weekly`, `@daily`/`@midnight`, `@hourly`.
- If both day-of-month and weekday are restricted, either matching runs the task (standard cron behaviour).
- Each task runs at most once per matching minute in its own thread; errors are caught and printed with the owning resource.
- An invalid expression raises an error at creation.
- Tasks are stopped automatically when the resource that created them stops.
- Examples: `'*/15 * * * *'` every 15 min · `'0 6 * * mon-fri'` 06:00 weekdays · `'30 3 1 * *'` 03:30 on the 1st.

### Extending the core at runtime

```lua
exports['rsg-core']:SetMethod('MyFunc', function(...) end) -- adds RSGCore.Functions.MyFunc
exports['rsg-core']:SetField('MyTable', {})                 -- adds RSGCore.MyTable

-- add a method/field to Player objects ('-1' = all, or a source / list of sources)
RSGCore.Functions.AddPlayerMethod(-1, 'Greet', function() print('hi') end)
RSGCore.Functions.AddPlayerField(-1, 'customData', {})
```

---

## 7. The Player Object (server)

```lua
local Player = RSGCore.Functions.GetPlayer(source)
local pd = Player.PlayerData
```

### `PlayerData` structure

| Key | Type | Description |
|---|---|---|
| `source` | number | Server id |
| `citizenid` | string | Unique character id (use this as your DB key) |
| `license` | string | Rockstar license |
| `cid` | number | Character slot |
| `name` | string | Account name |
| `money` | table | `{ cash, gold, bank, bloodmoney }` |
| `charinfo` | table | `firstname, lastname, birthdate, gender, nationality, account` |
| `job` | table | `name, label, payment, type, onduty, isboss, grade = { name, level }` |
| `gang` | table | `name, label, isboss, grade = { name, level }` |
| `metadata` | table | `health, hunger, thirst, cleanliness, stress, isdead, armor, ishandcuffed, injail, jailitems, status, rep, callsign, bloodtype, fingerprint, walletid, criminalrecord` |
| `position` | vector | Last saved position |
| `items` | table | Inventory (managed by rsg-inventory) |
| `weight` / `slots` | number | Inventory limits (defaults 35000 / 25) |
| `optin` | boolean | Admin-message opt-in |

### `Player.Functions`

| Function | Description |
|---|---|
| `SetJob(job, grade)` | Sets active job; fires `OnJobUpdate` events. Returns boolean |
| `SetGang(gang, grade)` | Sets gang; fires `OnGangUpdate` events |
| `SetJobDuty(onDuty)` | |
| `HasItem(items, amount?)` | |
| `SetPlayerData(key, val)` | Set any top-level PlayerData key and sync |
| `SetMetaData(key, val)` / `SetMetaData(tbl)` | Set metadata and sync |
| `GetMetaData(key)` | |
| `AddRep(rep, amount)` / `RemoveRep` / `GetRep(rep)` | Reputation stored in `metadata.rep` |
| `AddMoney(type, amount, reason?)` | Returns boolean |
| `RemoveMoney(type, amount, reason?)` | Respects `DontAllowMinus` / `MinusLimit` |
| `SetMoney(type, amount, reason?)` | |
| `GetMoney(type)` | number \| false |
| `UpdatePlayerData()` | Push PlayerData to the client |
| `Save()` | Write to DB (also persists state bags) |
| `Logout()` | |
| `AddMethod(name, fn)` / `AddField(name, data)` | Per-player extension |

### Player object examples

```lua
local Player = RSGCore.Functions.GetPlayer(source)
if not Player then return end

-- read
local pd        = Player.PlayerData
local fullName  = pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname
local isLawman  = pd.job.type == 'leo' and pd.job.onduty
local isBoss    = pd.job.isboss

-- metadata (server-side may set any key)
Player.Functions.SetMetaData('callsign', 'ALPHA-1')
local callsign = Player.Functions.GetMetaData('callsign')

-- reputation stored in metadata.rep
Player.Functions.AddRep('hunter', 5)
local rep = Player.Functions.GetRep('hunter')

-- job / gang
Player.Functions.SetJob('vallaw', 1)      -- name, grade (string or number)
Player.Functions.SetJobDuty(true)
Player.Functions.SetGang('none', 0)

-- items
if Player.Functions.HasItem('lockpick', 1) then end

-- force a save (also runs on drop and every RSGConfig.UpdateInterval minutes)
Player.Functions.Save()
```

Extend every Player object with your own method:

```lua
RSGCore.Functions.AddPlayerMethod(-1, 'IsLawman', function(self)
    return self.PlayerData.job.type == 'leo'
end)
-- later:
if Player.Functions.IsLawman() then ... end
```

### Player lifecycle (`RSGCore.Player`)

`Login(source, citizenid?, newData?)`, `Logout(source)`, `Save(source)`, `SaveOffline(PlayerData)`, `GetOfflinePlayer(citizenid)`, `GetOfflinePlayerByLicense(license)`, `DeleteCharacter(source, citizenid)`, `ForceDeleteCharacter(citizenid)`, `SaveInventory(source)`, `SaveOfflineInventory(PlayerData)`, `CheckPlayerData(source, PlayerData)` (fills defaults and validates data before a player object is created), `CreatePlayer(PlayerData, Offline?)` (builds the Player object with its `Functions`), `GetTotalWeight(items)`, `GetSlotsByItem(items, name)`, `GetFirstSlotByItem(items, name)`.

Player data auto-saves every `RSGConfig.UpdateInterval` minutes and on drop.

---

## 8. Money

Money types (`RSGConfig.Money.MoneyTypes`): `cash = 50, gold = 0, bank = 0, bloodmoney = 0` (start amounts).

```lua
if Player.Functions.RemoveMoney('cash', 25, 'bought-horse') then
    -- paid
end
```

- `bank` is kept for compatibility; **rsg-banking v3** forwards it to the player's home branch. Old `valbank`/`rhobank`/`blkbank`/`armbank` types are removed.
- **Money items:** with `EnableMoneyItems = true`, `cash` and `bloodmoney` are mirrored as inventory items and kept in sync automatically (`server/moneyitems.lua`). Gold items are controlled by `RSGConfig.Gold.EnableGoldItems` + `Money.GoldItem`.
- Paychecks every `PayCheckTimeOut` minutes use the grade `payment`; `offDutyPay` on the job decides if off-duty players are paid. `PayCheckSociety` is **not supported** with rsg-banking v3.
- Hook changes: `RSGCore:Server:OnMoneyChange (src, moneytype, amount, operation, reason)` — `operation` is `'add' | 'remove' | 'set'`.
- Amounts must be finite numbers `>= 0`. With `DontAllowMinus`, `RemoveMoney` returns `false` and changes nothing when the player cannot afford it.

```lua
-- charge first, then hand over the goods
local price = Config.Items[item].price                -- price comes from config, never from the client
if not Player.Functions.RemoveMoney('cash', price, 'shop-' .. item) then
    return RSGCore.Functions.Notify(src, 'Not enough cash', 'error')
end
exports['rsg-inventory']:AddItem(src, item, 1, nil, nil, 'shop-purchase')

-- pay a player
Player.Functions.AddMoney('cash', 50, 'delivery-reward')
Player.Functions.AddMoney('bloodmoney', 20, 'robbery')

-- read balances
local cash = Player.Functions.GetMoney('cash')        -- number, or false for an unknown type
local gold = Player.PlayerData.money.gold

-- react to any change (server)
AddEventHandler('RSGCore:Server:OnMoneyChange', function(src, moneytype, amount, operation, reason)
    if moneytype == 'cash' and operation == 'remove' and amount >= 1000 then
        print(('[big spend] %s spent $%s (%s)'):format(src, amount, reason))
    end
end)

-- react to any change (client)
RegisterNetEvent('RSGCore:Client:OnMoneyChange', function(moneytype, amount, operation, reason) end)
```

> With `EnableMoneyItems = true`, never add the `dollar` / `cent` / `blood_dollar` / `blood_cent` items yourself. Always go through `AddMoney` / `RemoveMoney` so the player data, the inventory items and the HUD stay in sync (`server/moneyitems.lua`).

---

## 9. Jobs, Gangs & Multi-Job

Multi-job is built into rsg-core. **Job definitions live in the database** (`multijob_jobs` table), managed in game with `/jobadmin` (permission `admin`). `shared/jobs.lua` only contains `unemployed` as a fallback. The tables `multijob_jobs` and `player_jobs` are created automatically.

Players see their jobs with `/myjobs` and can switch (cooldown `JobSwitchCooldown`), up to `MaxJobs` (default 3).

### Job definition shape

```lua
{
    name = 'vallaw', label = 'Valentine Law', type = 'leo',
    defaultDuty = true, offDutyPay = false,
    grades = {
        ['0'] = { name = 'Deputy', payment = 10 },
        ['1'] = { name = 'Sheriff', payment = 25, isboss = true },
    },
}
```

### Multi-job exports (server)

`identifier` is a **server id** (online) or a **citizenid** (online or offline).

| Export | Returns |
|---|---|
| `AddPlayerJob(identifier, job, grade, bypassMax?)` | `ok, reason` — `'invalid_job' \| 'invalid_grade' \| 'player_not_found' \| 'max_jobs'`. Re-grades if already held |
| `RemovePlayerJob(identifier, job)` | `ok, reason` — `'invalid_job' \| 'player_not_found' \| 'job_not_held'` |
| `GetPlayerJobs(identifier)` | `{ { job, salary, jobLabel, gradeLabel, grade }, … }` |
| `HasPlayerJob(identifier, job)` | `held, grade` |
| `CanTakePlayerJob(identifier, job, bypassMax?)` | `ok, reason` (`'already_held'`, `'max_jobs'`, …) |
| `GetPlayerJobCount(identifier)` | `count, max` |
| `GetJobDefinition(name)` | job table |
| `GetJobDefinitions()` | all jobs |
| `SaveJobDefinition(def)` | `def, err` — creates or updates a job at runtime (validated, saved to `multijob_jobs`, synced to clients). `def = { name, label, type?, icon?, defaultDuty?, offDutyPay?, grades = { ['0'] = { name, payment, isboss? } } }`. `err`: `'not_loaded'` or an `adm_err_*` key |
| `DeleteJobDefinition(name)` | `ok, err, holders` — deletes a job at runtime; anyone holding it drops to unemployed |

```lua
local ok, reason = exports['rsg-core']:AddPlayerJob(source, 'vallaw', 0)
if not ok then RSGCore.Functions.Notify(source, reason, 'error') end
```

> Naming: `AddJob/RemoveJob` on rsg-core manage job **definitions** (see §10). The player job list uses `*PlayerJob*` names. Legacy `exports['rsg-multijob']:AddJob/RemoveJob/GetJobs/HasJob/CanTakeJob/GetJobCount` still map to the player-job functions.

Discord logging for job events is configured server-side in `server/multijob/sv_config.lua`.

### Duty

```lua
TriggerServerEvent('RSGCore:ToggleDuty')               -- client toggles own duty
Player.Functions.SetJobDuty(true)                      -- server
-- events: RSGCore:Server:SetDuty (src, onDuty) / RSGCore:Client:SetDuty (onDuty)
```

`RSGShared.ForceJobDefaultDutyAtLogin = true` resets duty to the job's `defaultDuty` at login.

### Multi-job examples

```lua
-- give a player a job (online server id or offline citizenid)
local ok, reason = exports['rsg-core']:AddPlayerJob(source, 'medic', 0)
if not ok then
    print('could not add job:', reason)       -- 'max_jobs', 'invalid_job', ...
end

-- bypass the MaxJobs limit (staff action)
exports['rsg-core']:AddPlayerJob('ABC12345', 'vallaw', 2, true)

-- check before offering a job at your NPC
local canTake, why = exports['rsg-core']:CanTakePlayerJob(source, 'taxi')
if not canTake then return RSGCore.Functions.Notify(source, why, 'error') end

-- list everything a player holds
for _, j in ipairs(exports['rsg-core']:GetPlayerJobs(source)) do
    print(j.job, j.jobLabel, j.gradeLabel, j.grade, j.salary)
end

-- gate a feature on a held job (not just the active one)
local held, grade = exports['rsg-core']:HasPlayerJob(source, 'gunsmith')
if held and grade >= 1 then end

local count, max = exports['rsg-core']:GetPlayerJobCount(source)   -- 2, 3
```

Create or edit a job definition from another resource at runtime (validated, saved to `multijob_jobs`, synced to clients):

```lua
local def, err = exports['rsg-core']:SaveJobDefinition({
    name = 'ranchhand', label = 'Ranch Hand', type = 'none', icon = 'fa-solid fa-horse',
    defaultDuty = true, offDutyPay = false,
    grades = {
        ['0'] = { name = 'Hand',    payment = 8 },
        ['1'] = { name = 'Foreman', payment = 18, isboss = true },
    },
})
if not def then print('save failed:', err) end    -- 'not_loaded' or an adm_err_* key

local ok, err, holders = exports['rsg-core']:DeleteJobDefinition('ranchhand')
```

> Call `SaveJobDefinition` only after `rsg-multijob:server:jobsLoaded` has fired, otherwise it returns `'not_loaded'`.

### Multi-job events

| Event | Side | Notes |
|---|---|---|
| `rsg-multijob:server:jobsLoaded` | server (local) | Job definitions have been loaded from the database. Wait for it before calling `SaveJobDefinition` / `GetJobDefinition(s)` at resource start |
| `rsg-multijob:client:openmenu` | client | Opens the player's jobs menu (same as `/myjobs`) |
| `rsg-multijob:client:refreshJobs` | client | `(jobs, currentJobName)` pushed after the player's job list changes |
| `rsg-multijob:client:openAdmin` | client | Opens the `/jobadmin` panel (server checks permission first) |
| `rsg-multijob:server:changeJob` | server (net) | `(job)` sent by the menu to switch the active job. Cooldown and ownership are validated server-side |
| `rsg-multijob:server:deleteJob` | server (net) | `(job)` sent by the menu to drop a held job |
| `rsg-bossmenu:server:FireEmployee` | server (net) | `(target)`. Used by boss menus to remove the boss's job from an employee |

```lua
-- run code once the job table is ready
AddEventHandler('rsg-multijob:server:jobsLoaded', function()
    local n = 0
    for name in pairs(exports['rsg-core']:GetJobDefinitions()) do n += 1 end
    print(('loaded %d jobs'):format(n))
end)

-- open the jobs menu from your own UI / radial menu
TriggerEvent('rsg-multijob:client:openmenu')

-- keep local state when the active job changes (client)
RegisterNetEvent('RSGCore:Client:OnJobUpdate', function(job)
    print(job.name, job.grade.level, job.onduty)
end)
```

### Multi-job configuration

`shared/multijob.lua` → `RSGConfig.MultiJob`:

| Key | Default | |
|---|---|---|
| `MaxJobs` | `3` | Maximum jobs one player may hold |
| `JobSwitchCooldown` | `3000` | Milliseconds between job switches |
| `Admin.Command` | `'jobadmin'` | Chat command that opens the job editor |
| `Admin.Permission` | `'admin'` | Permission level required for the editor |
| `JobIcons` | table | Fallback Font Awesome icon per job name. An icon saved in `/jobadmin` wins |

`server/multijob/sv_config.lua` → `MultiJobWebhookConfig` (server-only so URLs never reach clients):

| Key | |
|---|---|
| `Enabled` | Master switch for all job webhook logging |
| `DefaultURL` | Used by any event without its own `URL` |
| `BotName`, `BotAvatar`, `FooterText`, `FooterIcon`, `DefaultColor` | Embed styling |
| `Events.<Name>` | `{ Enabled, URL, Title, Color }` per event: `JobAdded`, `JobSwitched`, `JobDeleted`, `JobRemovedByAdmin`, `JobCreated`, `JobUpdated`, `JobDefinitionDeleted`, `EmployeeFired` |

```lua
-- send "Employee Fired" to its own channel and silence "Job Switched"
MultiJobWebhookConfig.Events.EmployeeFired.URL = 'https://discord.com/api/webhooks/...'
MultiJobWebhookConfig.Events.JobSwitched.Enabled = false
```

First run: if `multijob_jobs` is empty it is seeded from `shared/jobs.lua` and `server/multijob/default_jobs.lua`.

### Gangs

Defined in `shared/gangs.lua`; set with `Player.Functions.SetGang(gang, grade)` or `/setgang`.

```lua
Player.Functions.SetGang('odriscoll', 1)

exports['rsg-core']:AddGang('mygang', {
    label = 'My Gang',
    grades = { ['0'] = { name = 'Recruit' }, ['1'] = { name = 'Boss', isboss = true } },
})

RegisterNetEvent('RSGCore:Client:OnGangUpdate', function(gang) print(gang.name, gang.grade.level) end)
```

---

## 10. Shared Data (Items / Jobs / Gangs)

Runtime changes are synced to all clients **and** replayed to players who join later.

| Export | Returns |
|---|---|
| `AddItem(name, data)` / `AddItems({ [name] = data })` | `ok, msg(, failedData)` |
| `UpdateItem(name, data)` / `RemoveItem(name)` | `ok, msg` |
| `AddJob` / `AddJobs` / `UpdateJob` / `RemoveJob` | same pattern |
| `AddGang` / `AddGangs` / `UpdateGang` / `RemoveGang` | same pattern |

Error codes: `invalid_<x>_name`, `<x>_exists`, `<x>_not_exists`. `Add*s` validates all entries first, so a failure never leaves a half-applied batch.

```lua
exports['rsg-core']:AddItem('treasure_map', {
    name = 'treasure_map', label = 'Treasure Map', weight = 50, type = 'item',
    image = 'treasure_map.png', unique = true, useable = true, shouldClose = true,
    description = 'An old map', category = 'misc',
})
```

Item fields: `name, label, weight, type ('item'|'weapon'), image, unique, useable, shouldClose, description, category`.

Clients react to `RSGCore:Client:OnSharedUpdate (tableName, key, value)` and `RSGCore:Client:OnSharedUpdateMultiple (tableName, entries)`.

---

## 11. Usable Items

```lua
RSGCore.Functions.CreateUseableItem('bandage', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    -- item = inventory slot data (name, amount, info, slot…)
end)

RSGCore.Functions.CanUseItem('bandage') -- returns the handler or nil
```

---

## 12. Permissions

Levels come from `RSGConfig.Server.Permissions`: `god, developer, headadmin, admin, mod, helper`. They are ACE based:

```cfg
add_principal identifier.license:xxxxxxxx rsgcore.god
```

| Function | Description |
|---|---|
| `HasPermission(source, perm \| {perms})` | true if any ACE matches |
| `GetPermission(source)` | `{ admin = true, … }` |
| `AddPermission(source, perm)` / `RemovePermission(source, perm)` | Only valid configured levels |
| `IsValidPermission(perm)` | |

Server join while closed requires ACE `rsgadmin.join`.

```lua
-- guard an admin-only event
RegisterNetEvent('myres:server:wipe', function()
    local src = source
    if not RSGCore.Functions.HasPermission(src, 'admin') then return end
    -- ...
end)

-- several levels at once: true if ANY matches
if RSGCore.Functions.HasPermission(src, { 'god', 'developer' }) then end

-- grant / revoke at runtime (levels must exist in RSGConfig.Server.Permissions)
RSGCore.Functions.AddPermission(src, 'mod')
RSGCore.Functions.RemovePermission(src, 'mod')
```

```cfg
# server.cfg
add_ace group.admin rsgcore.admin allow
add_principal identifier.license:xxxxxxxx group.admin
add_ace rsgcore.admin rsgadmin.join allow
```

---

## 13. Commands

```lua
RSGCore.Commands.Add('heal', 'Heal a player', {
    { name = 'id', help = 'Player ID' },
}, true, function(source, args)
    -- args[1]
end, 'admin')        -- permission: 'user' (default) or any level
```

Signature: `Add(name, help, arguments, argsrequired, callback, permission?)`. Chat suggestions are refreshed per player via `RSGCore.Commands.Refresh(source)`.

### Built-in commands

| Command | Perm | |
|---|---|---|
| `/tp [id \| x y z \| location]`, `/tpm` | admin | Teleport. `/tpm` freezes the entity, streams collision, probes for real ground and only then places it; if no ground is found the player is returned to their start position |
| `/noclip` | admin | |
| `/togglepvp` | admin | Flips PVP for the whole server; sets `GlobalState.pvp` and shows every player an ON/OFF notification (`info.pvp_on*` / `info.pvp_off*` locales) |
| `/addpermission`, `/removepermission` | god | |
| `/openserver`, `/closeserver [reason]` | admin | |
| `/vehicle`, `/dv`, `/dvall`, `/dvp`, `/dvo` | admin | Spawn / delete vehicles, peds, objects |
| `/givemoney`, `/setmoney` | admin | |
| `/setjob`, `/setgang` | admin | |
| `/jobadmin` | admin (configurable) | Job definition editor NUI |
| `/removejob` | admin | Remove a job from a player |
| `/job`, `/gang`, `/myjobs`, `/id`, `/cid`, `/ooc`, `/me` | user | |

---

## 14. Client Functions

| Function | Description |
|---|---|
| `GetPlayerData(cb?)` | Returns / passes `RSGCore.PlayerData` |
| `HasItem(items, amount?)` | Checks local inventory |
| `GetCoords(entity)` | `vector4` |
| `GetPlayers()` / `GetPlayersFromCoords(coords?, dist?)` / `GetClosestPlayer(coords?)` | |
| `GetPeds(ignore?)` / `GetClosestPed(coords?, ignore?)` | |
| `GetVehicles()` / `GetClosestVehicle(coords?)` | |
| `GetObjects()` / `GetClosestObject(coords?)` | |
| `SpawnVehicle(model, cb, coords?, isNetworked?, teleportInto?)` / `DeleteVehicle(veh)` | |
| `SpawnClear(coords, radius)` | true if no vehicles in radius |
| `RequestModel(model, timeout?)` | Returns hash; errors on timeout (alias `LoadModel`) |
| `RequestAnimDict(dict, timeout?)` | |
| `RequestAnimSet(set, timeout?)` | alias `LoadAnimSet` |
| `RequestNamedPtfxAsset(asset, timeout?)` | alias `LoadParticleDictionary` |
| `PlayAnim(dict, name, upperbodyOnly?, duration?)` | |
| `PlayAnimOnPed(ped, dict, name, blendIn, blendOut, duration, flag, rate, lockX, lockY, lockZ)` | |
| `LookAtEntity(entity, timeout, speed)` | |
| `AttachProp(ped, model, boneId, x, y, z, xR, yR, zR, vertex)` | Returns object |
| `StartParticleAtCoord(dict, name, looped, coords, rot, scale, alpha, color, duration)` | |
| `StartParticleOnEntity(dict, name, looped, entity, bone, offset, rot, scale, alpha, color, evolution, duration)` | |
| `GetClosestBone(entity, list)` / `GetBoneDistance(entity, type, index)` | |
| `DrawText(x, y, w, h, scale, r, g, b, a, text)` / `DrawText3D(x, y, z, text)` | Native-drawn text |
| `GetCardinalDirection(entity?)` | `'North'`, … |
| `GetCurrentTime()` | `{ hour, min, formattedHour, formattedMin, ampm }` |
| `GetGroundZCoord(coords)` / `GetGroundHash(entity)` | |
| `RSGCore.Debug(...)` | Prints to F8 console |
| `exports['rsg-core']:GenerateCSRFToken()` | Token for securing NUI callbacks |

Login check:

```lua
if LocalPlayer.state.isLoggedIn then ... end
```

### Client function examples

```lua
-- load assets (all yield; call from a thread)
local hash = RSGCore.Functions.RequestModel('A_C_HORSE_ARABIAN_WHITE', 5000)
RSGCore.Functions.RequestAnimDict('amb_misc@world_human_stand_waiting@male_a@base', 5000)

-- play an animation on the local ped
RSGCore.Functions.PlayAnim('amb_misc@world_human_stand_waiting@male_a@base', 'base', false, 3000)

-- is this a clear spot for a vehicle?
if RSGCore.Functions.SpawnClear(GetEntityCoords(PlayerPedId()), 5.0) then end

-- spawn a wagon and sit in it
RSGCore.Functions.SpawnVehicle('wagon02x', function(veh)
    print('spawned', veh)
end, vector4(-324.2, 803.9, 117.9, 90.0), true, true)

-- nearest player / ped
local playerId, dist = RSGCore.Functions.GetClosestPlayer()
local ped, pedDist = RSGCore.Functions.GetClosestPed()

-- clock + compass
local t = RSGCore.Functions.GetCurrentTime()          -- { hour, min, formattedHour, formattedMin, ampm }
local dir = RSGCore.Functions.GetCardinalDirection()  -- 'North', ...

-- check the local inventory
if RSGCore.Functions.HasItem('lockpick', 1) then end

-- raycast from the camera (replaces lib.raycast)
local hit, entity, endCoords = RSGCore.Functions.RaycastCamera(511, 4, 10.0)
```

---

## 15. Notifications

**Client**

```lua
RSGCore.Functions.Notify({ title = 'Stable', description = 'Horse stored', type = 'success', duration = 5000, icon = 'fa-solid fa-horse' })
RSGCore.Functions.Notify('Title', 'Description', 'error', 5000, 'fa-solid fa-xmark')
RSGCore.Functions.Notify('Simple text', 'success', 3000)            -- legacy QB style
exports['rsg-core']:Notify({ ... })
```

**Server**

```lua
RSGCore.Functions.Notify(source, 'Not enough cash', 'error', 4000)
RSGCore.Functions.Notify(source, { title = 'Bank', description = 'Paid $5', type = 'success' })
TriggerClientEvent('RSGCore:Client:Notify', source, { title = '...', type = 'inform' })
```

Types: `primary | inform | info | success | error | warning | warn`. Extra table keys: `id`, `position`, `sound` (bool). Positions: `top-right, top-left, top, bottom-right, bottom-left, bottom, center-right, center-left`.

---

## 16. Progress Bar / Circle

Must be called from a thread (it yields).

```lua
local done = RSGCore.Functions.ProgressBar({
    duration = 5000,
    label = locale('progress.crafting'),
    canCancel = true,              -- X key by default (RSGConfig.Progress.CancelKey)
    useWhileDead = false, allowRagdoll = false, allowSwimming = false,
    allowCuffed = false, allowFalling = false, allowMounted = false,
    anim = { dict = 'mech_inventory@crafting@fallbacks', clip = 'full_craft_and_stow', flag = 27 },
    -- or anim = { scenario = 'WORLD_HUMAN_CROUCH_INSPECT' }
    prop = { model = 'p_bottle01x', bone = 'SKEL_R_Hand', pos = vec3(0,0,0), rot = vec3(0,0,0) },
    disable = { move = true, sprint = true, mount = true, combat = true, mouse = false },
})
if done then ... else ... end -- false = cancelled / interrupted
```

Also: `ProgressCircle(data)`, `IsProgressActive()`, `CancelProgress()` (all exported; `rsg-core:client:CancelProgress` event). The progress auto-cancels if the calling resource stops.

---

## 17. Text UI (DrawText)

```lua
exports['rsg-core']:DrawText('[E] Open Shop', 'left')  -- left | right | top | or a full position string
exports['rsg-core']:ChangeText('[E] Close')
exports['rsg-core']:HideText()
exports['rsg-core']:IsTextShown()
```

Events: `rsg-core:client:DrawText`, `ChangeText`, `HideText`, `KeyPressed`.

---

## 18. Prompts

Hold-to-activate native prompts, shown within `RSGConfig.PromptDistance` (1.5).

```lua
exports['rsg-core']:createPrompt('valentine_shop', vector3(-324.2, 803.9, 117.9),
    RSGCore.Shared.Keybinds['J'], 'Open Shop', {
        type = 'client',            -- 'client' or 'server'
        event = 'myshop:client:open',
        args = { 'valentine' },
    })

exports['rsg-core']:createPromptGroup('bank_group', 'Valentine Bank', coords, {
    { key = RSGCore.Shared.Keybinds['J'], text = 'Open Bank', options = { type = 'client', event = 'bank:open' } },
})

exports['rsg-core']:deletePrompt('valentine_shop')
exports['rsg-core']:deletePromptGroup('bank_group')
exports['rsg-core']:getPrompt() / getPromptGroup()
```

Use `RSGCore.Shared.Keybinds` (`shared/keybinds.lua`) for key hashes.

---

## 19. Routing Buckets

| Function | |
|---|---|
| `SetPlayerBucket(source, bucket)` | Also sets `Player(src).state.instance` |
| `SetEntityBucket(entity, bucket)` | |
| `GetPlayersInBucket(bucket)` / `GetEntitiesInBucket(bucket)` | |
| `GetBucketObjects()` | `playerBuckets, entityBuckets` |

```lua
-- put a player and a prop in a private instance
RSGCore.Functions.SetPlayerBucket(source, 50)
RSGCore.Functions.SetEntityBucket(entity, 50)

-- who is in the instance?
local players = RSGCore.Functions.GetPlayersInBucket(50)     -- list of server ids
local entities = RSGCore.Functions.GetEntitiesInBucket(50)   -- non-player entities only

-- leave the instance (bucket 0 is the default world)
RSGCore.Functions.SetPlayerBucket(source, 0)
```

Both setters return `false` if an argument is missing.

---

## 20. Events Reference

### Server (listen with `AddEventHandler`)

| Event | Args |
|---|---|
| `RSGCore:Server:PlayerLoaded` | `Player` |
| `RSGCore:Server:OnPlayerUnload` | `source` |
| `RSGCore:Server:PlayerDropped` | `Player` |
| `RSGCore:Server:OnJobUpdate` | `source, job` |
| `RSGCore:Server:OnGangUpdate` | `source, gang` |
| `RSGCore:Server:OnMoneyChange` | `source, moneytype, amount, operation, reason` |
| `RSGCore:Server:SetDuty` | `source, onDuty` |
| `RSGCore:Server:OnPlayerDeath` | `victim, killer|nil, data`. Every reported death. `data = { weapon, coords, confirmed }`. Server-only, clients cannot fire it |
| `RSGCore:Server:OnPlayerKilled` | `victim, killer, data`. Only player-vs-player kills that passed validation and the killer's confirmation |
| `RSGCore:Server:UpdateObject` | — |
| `RSGCore:Server:OnPlayerLoaded` | Net event fired by the client once the character is ready; core uses it to sync money items. Prefer `PlayerLoaded` for your own code |
| `RSGCore:Server:CloseServer` / `OpenServer` | Net events (admin permission checked server-side) |
| `RSGCore:Server:KickCSRF` | Net event: drops the sender for a failed CSRF check |
| `RSGCore:DebugSomething` | Server-only: `(tbl, indent, resource)` pretty-prints a table to the console |

### Client (listen with `RegisterNetEvent`)

| Event | Args |
|---|---|
| `RSGCore:Client:OnPlayerLoaded` | — |
| `RSGCore:Client:OnPlayerUnload` | — |
| `RSGCore:Player:SetPlayerData` | `PlayerData` (fires on every change) |
| `RSGCore:Client:OnJobUpdate` | `job` |
| `RSGCore:Client:OnGangUpdate` | `gang` |
| `RSGCore:Client:OnMoneyChange` | `moneytype, amount, operation, reason` |
| `RSGCore:Client:SetDuty` | `onDuty` |
| `RSGCore:Client:PvpHasToggled` | `pvp` |
| `RSGCore:Client:OnSharedUpdate` / `OnSharedUpdateMultiple` | `tableName, key, value` / `tableName, entries` |
| `RSGCore:Client:UpdateObject` | — |
| `RSGCore:Client:Notify` | notify table |
| `RSGCore:Notify` | Legacy QBCore-style notify: `(text, type, duration)` |
| `hud:client:OnMoneyChange` | `moneytype, amount, isMinus` (HUD feedback, sent after every money change) |

> **PVP state:** read `GlobalState.pvp` (bool) for the live server value. `client/pvp.lua` enforces it every second (relationship 5/1, `NetworkSetFriendlyFireOption`, `SetCanAttackFriendly`, `SetEntityCanBeDamagedByRelationshipGroup` for the PLAYER group so fists/melee are blocked when PVP is off, and `SetLockonToFriendlyPlayers`), so other scripts should not set PLAYER↔PLAYER relationships or friendly fire themselves.

```lua
-- react to PVP being toggled
RegisterNetEvent('RSGCore:Client:PvpHasToggled', function(pvp)
    print('PVP is now', pvp and 'ON' or 'OFF')
end)
-- or just read it
if GlobalState.pvp then end
```

Typical client pattern:

```lua
local PlayerData = {}
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function() PlayerData = RSGCore.Functions.GetPlayerData() end)
RegisterNetEvent('RSGCore:Player:SetPlayerData', function(val) PlayerData = val end)
RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function() PlayerData = {} end)
```

### Internal callback events

`RSGCore:Server:TriggerCallback`, `RSGCore:Server:TriggerCallbackId`, `RSGCore:Server:TriggerClientCallback`, `RSGCore:Client:TriggerCallback`, `RSGCore:Client:TriggerCallbackId` and `RSGCore:Client:TriggerClientCallback` carry the callback request/response traffic. Pending client callbacks are keyed per source (`RSGCore.Functions.ClientCallbackKey`) so one client can never answer another client's request. Do not trigger these directly; use `TriggerCallback` / `AwaitCallback` and the client-callback equivalents from §5.

### Event handler examples

```lua
-- server: runs for every player after their character is fully loaded
AddEventHandler('RSGCore:Server:PlayerLoaded', function(Player)
    print(Player.PlayerData.citizenid .. ' joined')
end)

-- server: clean up when the player leaves
AddEventHandler('RSGCore:Server:PlayerDropped', function(Player)
    MyCache[Player.PlayerData.citizenid] = nil
end)

-- server: job or gang changed
AddEventHandler('RSGCore:Server:OnJobUpdate', function(src, job)
    print(src, 'is now', job.name, 'grade', job.grade.level)
end)

-- client: react to shared data added at runtime (new item, job, gang)
RegisterNetEvent('RSGCore:Client:OnSharedUpdate', function(tableName, key, value)
    if tableName == 'Items' then print('item added/changed:', key) end
end)
```

### Death and kill events

`client/death.lua` watches the local ped. On death it reports the killer's server id and the cause-of-death weapon hash to `RSGCore:Server:ReportDeath` (the only client-callable part). `server/death.lua` then credits a killer only if the killer is online, not the victim, in the same routing bucket, within `RSGConfig.Death.MaxKillDistance` (server positions), PVP is on, and the killer's client confirms (`RSGCore:Client:ConfirmKill`: it sees the victim dead with itself as the source of death). Otherwise `killer` is `nil`. Repeat reports inside `MinSecondsBetween` are ignored.

```lua
AddEventHandler('RSGCore:Server:OnPlayerKilled', function(victim, killer, data)
    -- data.weapon (hash), data.coords (vector3), data.confirmed (true)
end)
local last = exports['rsg-core']:GetLastDeath(src) -- { killer, weapon, coords, time, confirmed } or nil
```

Limits: kills made from a horse or wagon, and deaths with no player source, report `killer = nil`. A victim client can still lie about being dead, but cannot frame a player who did not confirm.

### Client → server events you may call

| Event | Notes |
|---|---|
| `RSGCore:Server:SetMetaData (key, value)` | **Only** keys in `RSGConfig.ClientWritableMetadata` (hunger, thirst, cleanliness, stress, health, armor) |
| `RSGCore:ToggleDuty` | |
| `RSGCore:UpdatePlayer` | Saves current stats |
| `RSGCore:Server:ReportDeath (killerServerId, weapon)` | Used by `client/death.lua`; validated and rate limited server-side |

---

## 21. State Bags

- `LocalPlayer.state.isLoggedIn` — set on load/unload.
- `Player(src).state.instance` — current routing bucket.
- Certain metadata keys (e.g. `hunger`, `thirst`, …) are mirrored into player state bags on login and persisted back to metadata on save (`InitializeStateBags` / `PersistStateBags`). Read them client-side via `LocalPlayer.state.thirst`.

Example (thirst adjust, client):

```lua
TriggerEvent('hud:client:UpdateThirst', math.max(0, math.min(100, (LocalPlayer.state.thirst or 0) + 25)))
```

---

## 22. Shared Utilities (`RSGCore.Shared`)

| Field / Function | |
|---|---|
| `Items`, `Jobs`, `Gangs`, `Weapons`, `Vehicles`, `Locations`, `Keybinds` | Data tables |
| `RandomStr(len)` / `RandomInt(len)` | |
| `SplitStr(str, delim)` | |
| `Trim(str)` / `FirstToUpper(str)` | |
| `Round(value, decimals)` | |
| `exports['rsg-core']:GetWeapons()` | Weapons table |
| `RSGCore.Shared.StarterItems` | Starter items table (see §23) |

```lua
local id   = RSGCore.Shared.RandomStr(8)                  -- 'aZ3kP9qL'
local pin  = RSGCore.Shared.RandomInt(4)                  -- '4821'
local bits = RSGCore.Shared.SplitStr('a,b,c', ',')        -- { 'a', 'b', 'c' }
local name = RSGCore.Shared.FirstToUpper('arthur')        -- 'Arthur'
local n    = RSGCore.Shared.Round(3.14159, 2)             -- 3.14
local key  = RSGCore.Shared.Keybinds['J']                 -- hash for prompts
local item = RSGCore.Shared.Items['bandage']              -- shared item definition
```

---

## 23. Configuration Reference

`shared/config.lua` (`RSGConfig`):

| Key | Default | |
|---|---|---|
| `DefaultSpawn` | `vector4(-1035.71, -2731.87, 12.86, 0.0)` | |
| `UpdateInterval` | `5` | Minutes between auto-saves |
| `MaxPlayers` | `GetConvarInt('sv_maxclients', 48)` | Read from `sv_maxclients` |
| `HidePlayerNames` | `true` | Shows the `info.stranger` locale instead of real names above heads |
| `Money.MoneyTypes` | `cash=50, gold=0, bank=0, bloodmoney=0` | |
| `Money.DontAllowMinus` | `cash, gold, bloodmoney, bank` | |
| `Money.MinusLimit` | `-5000` | |
| `Money.PayCheckTimeOut` | `10` | Minutes |
| `Money.EnableMoneyItems` | `true` | |
| `Gold.EnableGoldItems` | `false` | |
| `Player.PlayerDefaults` | — | Defaults for new characters |
| `Player.RevealMap` | `true` | |
| `Server.Closed / ClosedReason / Whitelist / WhitelistPermission / PVP / CheckDuplicateLicense` | `false / 'Server Closed' / false / 'admin' / true / true` | |
| `Server.Discord` | `''` | Invite link appended to kick / ban messages |
| `Commands.OOCColor` | `{ 255, 151, 133 }` | RGB for `/ooc` |
| `Player.Bloodtypes` | `A+ … O-` | Random pick at character creation |
| `Gold.EnableGoldItems` / `Money.GoldItem` | `false` / `'gold'` | Represent gold as an inventory item |
| `Server.Permissions` | god…helper | |
| `PromptDistance` | `1.5` | |
| `AllowPushToTalkWhileOpen` / `PushToTalkControls` | `true` / `{ 0x4BC9DABB }` | While `/myjobs` or `/jobadmin` is open, game controls are blocked but push-to-talk keeps working |
| `Notify` | Position, Duration, MaxVisible, Sound | |
| `Progress` | CancelKey `0x8CC9CD42` (X), CancelLabel | |
| `ClientWritableMetadata` | hunger, thirst, cleanliness, stress, health, armor | |

`shared/multijob.lua` (`RSGConfig.MultiJob`): `MaxJobs = 3`, `JobSwitchCooldown = 3000`, `Admin = { Command = 'jobadmin', Permission = 'admin' }`, `JobIcons` (see §9).

`shared/main.lua` (`RSGShared.StarterItems`): items given to new characters, `{ bread = { amount = 5, item = 'bread' }, water = { amount = 5, item = 'water' } }`.

Config is read on both sides, so a change needs a resource restart (`ensure rsg-core`) or a server restart.
`server/multijob/sv_config.lua`: Discord webhooks per job event (server-only).

### Database

- Created automatically when `RSGConfig.AutoDatabase = true` (default): `players`, `bans`, `multijob_jobs`, `player_jobs`, and the `weight`/`slots`/`outlawstatus` columns.
- Manual install: set `RSGConfig.AutoDatabase = false` and import `install.sql` (same schema, kept in sync).

| Option | Default | Description |
|---|---|---|
| `RSGConfig.AutoDatabase` | `true` | Create the tables on start |
| `RSGConfig.Limits` | see config | `SaveCooldown`, `DutyCooldownMs`, `SpawnCooldownMs`, `SpawnMaxDistance`, `MeCooldownMs`, `OocCooldownMs`, `OocRange` |
| `RSGConfig.ServerSideSave` | `true` | Server saves every player each `UpdateInterval` minutes; the client no longer triggers periodic saves |
| `RSGConfig.LogSaves` | `false` | Print a console line on every save |
| `RSGConfig.Ban` | `CheckDiscord = true`, `CheckIP = false` | Extra identifiers matched against the `bans` table (license is always checked) |
| `RSGConfig.AdminLogChannel` | `'admin'` | rsg-log channel for admin command audit entries |

---

## 24. Exports Reference

Everything below is called as `exports['rsg-core']:Name(...)`. The same functions are also on the core object (`RSGCore.Functions.Name`), which is faster for resources that call them often. Exports are the simplest way to use rsg-core without holding the whole core object.

### 24.1 Shared

| Export | Returns | Notes |
|---|---|---|
| `GetCoreObject()` | table | The core object (client and server) |
| `GetWeapons()` | table | Weapon definitions from `RSGShared.Weapons` |

### 24.2 Server: players

| Export | Returns | Notes |
|---|---|---|
| `GetPlayer(src)` | Player or nil | Online player by server id |
| `GetPlayerByCitizenId(cid)` | Player or nil | Online only |
| `GetOfflinePlayerByCitizenId(cid)` | Player or nil | Loads from the database when offline |
| `GetPlayerByLicense(license)` | Player or nil | |
| `GetPlayerByAccount(account)` | Player or nil | Bank account number |
| `GetPlayerByCharInfo(prop, value)` | Player or nil | First player whose `charinfo[prop] == value` |
| `GetPlayers()` | `number[]` | Server ids of loaded players |
| `GetRSGPlayers()` | `table<src, Player>` | All loaded Player objects |
| `GetPlayersOnDuty(job)` | `number[], number` | Server ids on duty and their count |
| `GetDutyCount(job)` | number | |
| `GetIdentifier(src, type)` | string or nil | `license`, `discord`, `ip`... |
| `GetSource(identifier)` | number | `0` when not online |
| `AddMoney(src, type, amount, reason?)` | boolean | `false` when offline or refused |
| `RemoveMoney(src, type, amount, reason?)` | boolean | `false` when offline or not enough |
| `GetMoney(src, type)` | number | `0` when offline |
| `GetMetaData(src, key)` | any | |
| `SetMetaData(src, key, value)` | boolean | Server side only, no whitelist applies here |
| `GetJob(src)` / `GetGang(src)` | table or nil | The player's current job / gang table |

Money types are `cash`, `gold`, `bank` and `bloodmoney`. `cash`, `bloodmoney` and `gold` are inventory items when money items are enabled, always use these functions instead of adding the items.

```lua
-- server: pay a player for a delivery
RegisterNetEvent('myres:server:deliver', function()
    local src = source
    if not exports['rsg-core']:GetPlayer(src) then return end
    if exports['rsg-core']:AddMoney(src, 'cash', 25, 'myres-delivery') then
        exports['rsg-core']:Notify(src, { title = 'Delivery', description = 'You earned $25', type = 'success' })
    end
end)
```

### 24.3 Server: permissions, access and moderation

| Export | Returns | Notes |
|---|---|---|
| `HasPermission(src, permission)` | boolean | `god`, `developer`, `headadmin`, `admin`, `mod`, `helper` |
| `AddPermission(src, permission)` / `RemovePermission(src, permission)` | boolean | Updates ACE principals |
| `GetPermission(src)` | table | |
| `IsValidPermission(permission)` | boolean | |
| `IsWhitelisted(src)` | boolean | |
| `IsPlayerBanned(src)` | `boolean, string?` | Checks license, and Discord/IP per `RSGConfig.Ban`; the second value is the ban message |
| `CanJoinClosed(src)` | boolean | ACE `rsgadmin.join` or the whitelist permission |
| `SetServerClosed(closed, reason?)` | | Closing kicks everyone who fails `CanJoinClosed` |
| `Kick(src, reason, setKickReason?, deferrals?)` | | |
| `ExploitBan(src, reason)` | | Permanent ban and anti-cheat log entry |
| `AdminLog(src, action, details?)` | | Audit entry on the console and the rsg-log channel `RSGConfig.AdminLogChannel` |

```lua
-- server: an admin tool that writes to the same audit trail as the core commands
RegisterCommand('wipezone', function(src)
    if not exports['rsg-core']:HasPermission(src, 'admin') then return end
    -- ...do the work...
    exports['rsg-core']:AdminLog(src, 'wipezone', 'cleared 12 props')
end)
```

### 24.4 Server: items, notifications, buckets, cron

| Export | Returns | Notes |
|---|---|---|
| `CreateUseableItem(name, fn)` | | `fn(source, item)` |
| `CanUseItem(name)` / `UseItem(src, name)` | | |
| `Notify(src, data\|text, type?, duration?)` | | Data table form: `{ title, description, type, duration, icon, position, id }` |
| `SetPlayerBucket(src, bucket)` / `SetEntityBucket(entity, bucket)` | boolean | |
| `GetPlayersInBucket(bucket)` / `GetEntitiesInBucket(bucket)` | table | |
| `CreateCron(expression, job, options?)` | task | `task:stop()`, `task:isActive()`; see section 6 |
| `StopCron(id)` | | |
| `SetMethod(name, fn)` / `SetField(name, value)` | | Extend the core object at runtime |
| `AddPlayerMethod(ids, name, fn)` / `AddPlayerField(ids, name, value)` | | Extend Player objects (`ids` = a source/citizenid, a list, or `-1` for all) |
| `GetCoreVersion()` | string | |

### 24.5 Server: shared data (items, jobs, gangs)

Changes sync to all clients (and to players who join later) with `RSGCore:Client:OnSharedUpdate(Multiple)`.

| Items | Jobs | Gangs | Behaviour |
|---|---|---|---|
| `AddItem(name, data)` | `AddJob` | `AddGang` | Fails if the name exists |
| `AddItems(map)` | `AddJobs` | `AddGangs` | All-or-nothing, fails if any name exists |
| `SetItems(map)` | `SetJobs` | `SetGangs` | Adds or overwrites many entries with one broadcast |
| `UpdateItem(name, data)` | `UpdateJob` | `UpdateGang` | Fails if the name does not exist |
| `RemoveItem(name)` | `RemoveJob` | `RemoveGang` | Fails if the name does not exist |

All return `ok, reason` (`reason` is `item_exists`, `job_not_exists`, `invalid_gang_name`...). `AddJob` and friends are job *definitions*; players hold jobs through the multi-job functions below.

```lua
local ok, reason = exports['rsg-core']:AddItem('moonshine_jar', {
    name = 'moonshine_jar', label = 'Moonshine', weight = 500, type = 'item',
    image = 'moonshine_jar.png', unique = false, useable = true, shouldClose = true,
    description = 'Strong stuff',
})
if not ok then print('could not add item: ' .. tostring(reason)) end
```

### 24.6 Server: multi-job (`id` = server id or citizenid)

| Export | Returns |
|---|---|
| `AddPlayerJob(id, job, grade, bypassMax?)` | `ok, reason` (`invalid_job`, `invalid_grade`, `player_not_found`, `max_jobs`) |
| `RemovePlayerJob(id, job)` | `ok, reason` (`invalid_job`, `player_not_found`, `job_not_held`) |
| `GetPlayerJobs(id)` | `{ job, salary, jobLabel, gradeLabel, grade, icon }[]` |
| `HasPlayerJob(id, job)` | `held, grade` |
| `CanTakePlayerJob(id, job, bypassMax?)` | `ok, reason` |
| `GetPlayerJobCount(id)` | `count, max` |
| `GetJobDefinition(name)` / `GetJobDefinitions()` | definition(s) in core shape plus `icon` |
| `SaveJobDefinition(def)` / `DeleteJobDefinition(name)` | `def, err` / `ok, err, holders` |

The legacy `exports['rsg-multijob']:...` names keep working (rsg-core `provide`s rsg-multijob).

```lua
-- server: hire a player as a deputy at grade 1, then make it their active job
local src = source
local ok, reason = exports['rsg-core']:AddPlayerJob(src, 'lawman', 1)
if not ok then
    print('hire failed: ' .. tostring(reason))
    return
end
exports['rsg-core']:GetPlayer(src).Functions.SetJob('lawman', 1)
```

### 24.7 Client

| Export | Notes |
|---|---|
| `GetPlayerData()` / `GetPlayerData(cb)` | The local player data table |
| `HasItem(items, amount?)` | Asks rsg-inventory (`false` when it is not started) |
| `GetCoords(entity)` | `vector4` (x, y, z, heading) |
| `GetClosestPlayer(coords?)`, `GetClosestPed(coords?, ignoreList?)`, `GetClosestVehicle(coords?)`, `GetClosestObject(coords?)` | `entity (or player id), distance` |
| `GetPlayersFromCoords(coords?, distance?)` | Player ids near the coords |
| `GetNearbyPeds/Vehicles/Objects(coords, maxDistance)` | Entity lists |
| `Raycast(from, to, flags?, ignore?)`, `RaycastCamera(flags?, ignore?, distance?)` | Hit info |
| `PlayAnim(dict, name, upperOnly?, duration?)`, `LookAtEntity(...)` | |
| `SpawnVehicle`, `DeleteVehicle`, `GetGroundZCoord`, `GetCardinalDirection`, `GetCurrentTime` | |
| `Notify(...)` | Same accepted shapes as section 15 |
| `ProgressBar(data)`, `ProgressCircle(data)`, `IsProgressActive()`, `CancelProgress()` | Section 16 |
| `DrawText(text, pos?)`, `ChangeText(text, pos?)`, `HideText()`, `KeyPressed()`, `IsTextShown()` | Section 17 |
| `createPrompt`, `createPromptGroup`, `deletePrompt`, `deletePromptGroup`, `getPrompt`, `getPromptGroup` | Section 18. Prompts are removed automatically when the creating resource stops |
| `RequestModel`, `RequestAnimDict`, `RequestAnimSet`, `RequestNamedPtfxAsset`, `RequestStreamedTextureDict` | `fn(name, timeout?)` loads with a timeout in ms and returns the hash (model) or the name (dict/set/asset) |
| `TriggerCallback`, `AwaitCallback`, `CreateClientCallback` | Section 5 |
| `GenerateCSRFToken()` | Returns a token; validate it from your NUI through the `validateCSRF` NUI callback |

```lua
-- client: show a progress bar, then notify
local done = exports['rsg-core']:ProgressBar({ duration = 5000, label = 'Skinning...', canCancel = true })
if done then
    exports['rsg-core']:Notify({ title = 'Skinning', description = 'Done', type = 'success' })
end
```

### 24.8 Hooking in with events

Other resources can react to core activity without being called by it. Listen with `AddEventHandler` (server) or `RegisterNetEvent` (client); the full list with payloads is in section 20. The most useful:

```lua
-- server: run code once a character is fully loaded
AddEventHandler('RSGCore:Server:PlayerLoaded', function(Player)
    print(('%s loaded as %s'):format(Player.PlayerData.citizenid, Player.PlayerData.job.name))
end)

-- server: job definitions are ready (safe to call GetJobDefinition / AddPlayerJob)
AddEventHandler('rsg-multijob:server:jobsLoaded', function() end)

-- client: react to a job change
RegisterNetEvent('RSGCore:Client:OnJobUpdate', function(job) print(job.name, job.grade.level) end)
```

---

## 25. ox_lib Migration Cheat Sheet

| ox_lib | rsg-core |
|---|---|
| `lib.notify(data)` | `RSGCore.Functions.Notify(data)` |
| `lib.callback.register` (server) | `RSGCore.Functions.CreateCallback(name, function(source, cb, ...) end)` |
| `lib.callback.await` (client) | `RSGCore.Functions.AwaitCallback(name, timeout, ...)` |
| `lib.callback.await` (server → client) | `RSGCore.Functions.AwaitClientCallback(name, source, timeout, ...)` |
| `lib.progressBar / progressCircle` | `RSGCore.Functions.ProgressBar / ProgressCircle` |
| `lib.progressActive / cancelProgress` | `IsProgressActive / CancelProgress` |
| `lib.showTextUI / hideTextUI` | `exports['rsg-core']:DrawText / HideText` |
| `lib.requestModel / requestAnimDict / requestAnimSet / requestNamedPtfxAsset` | `RSGCore.Functions.Request*` |
| `lib.locale()` + `locale()` | `@rsg-core/shared/locale.lua` → `locale()` |
| `lib.require` / `require` | `@rsg-core/shared/require.lua` |
| `lib.cron.new(expr, job, opts)` | `RSGCore.Functions.CreateCron(expr, job, opts)` |
| `'@ox_lib/init.lua'` | remove |

---

## 26. Security Notes

- **Never trust the client.** Do money, items and job checks on the server inside the event/callback, using `source`.
- Clients can only set metadata keys whitelisted in `RSGConfig.ClientWritableMetadata`.
- Use `exports['rsg-core']:ExploitBan(source, 'reason')` for confirmed exploit attempts.
- Protect NUI callbacks with `GenerateCSRFToken()`; a wrong token while one is pending triggers `RSGCore:Server:KickCSRF` after two strikes. A callback with no pending token is rejected without a kick.
- Closed server: `RSGCore.Functions.CanJoinClosed(src)` (ACE `rsgadmin.join` or the whitelist permission) is used both when joining and when closing the server, so the two checks agree.
- Admin commands are audit logged (console + rsg-log). `/tp x y` probes ground; `SafeTeleport` moves mounts/vehicles with the player.
- New server exports `SetJobs`, `SetItems`, `SetGangs` add or overwrite many shared entries with one client broadcast.
- Prompts created through the exports are tracked per resource and removed when that resource stops.
- Failed money item grants (`AddItem` returned false, e.g. full inventory) are logged and the player gets `error.money_item_failed`.
- `RSGCore:CallCommand` checks command permissions server-side (`RSGCore.Commands.CanUse(src, cmd)`) and only passes string/number arguments (max 20) to command callbacks.
- `RSGCore.Functions.IsPlayerBanned` checks every ban row for a license (the longest active ban wins; expired rows are cleaned up).
- Players cannot connect until the job definitions have loaded from `multijob_jobs` (otherwise their saved job would be reset to unemployed).
- `/ooc` is limited to 255 characters and a 2 second cooldown per player.
- `PrepForSQL` validates strings before raw SQL; always prefer parameterised `MySQL` queries.
- Multi-job admin callbacks are permission- and rate-limited.
- The version checker (`server/versionchecker.lua`) only reads `version.txt` from GitHub on resource start and prints whether you are up to date; it changes nothing.

### CSRF-protected NUI callback

`GenerateCSRFToken()` returns a single-use token. The NUI must send it back to `validateCSRF`; a wrong token drops the player (`RSGCore:Server:KickCSRF`).

```lua
-- client
RegisterNUICallback('buyItem', function(data, cb)
    local token = exports['rsg-core']:GenerateCSRFToken()
    SendNUIMessage({ action = 'csrf', token = token })   -- hand the token to the page
    cb('ok')
end)
```

```js
// NUI (JavaScript): validate before trusting a sensitive action
const res = await fetch('https://rsg-core/validateCSRF', {
  method: 'POST',
  body: JSON.stringify({ clientToken: token }),
});
const { valid } = await res.json();
if (valid) { /* proceed with the action */ }
```

> The NUI callback is registered by rsg-core, so a page in another resource reaches it through the `https://rsg-core/` origin (the same pattern QBCore-style resources use). Validation only proves the NUI is the one that requested the token. The server must **still** re-check price, item, job and distance in the net event it receives.

### Validating a client request (pattern)

```lua
RegisterNetEvent('myres:server:sell', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    if type(item) ~= 'string' or type(amount) ~= 'number' or amount < 1 or amount > 100 then
        return exports['rsg-core']:ExploitBan(src, 'myres:sell invalid args')
    end
    local entry = Config.Buyers[item]; if not entry then return end             -- config, not client, decides price
    local coords = GetEntityCoords(GetPlayerPed(src))
    if #(coords - Config.BuyerCoords) > 5.0 then return end                     -- distance check
    if not RSGCore.Functions.HasItem(src, item, amount) then return end
    exports['rsg-inventory']:RemoveItem(src, item, amount, nil, 'myres-sell')
    Player.Functions.AddMoney('cash', entry.price * amount, 'myres-sell')
end)
```

## 27. Complete Example Resource

A minimal but complete resource that follows every convention in this document: locale files, a usable item, a server callback, a prompt, a command and a validated server event.

```
rsg-example/
├── fxmanifest.lua
├── shared/config.lua
├── locales/en.json        (plus de, el, es, fr, ja, nl, pl, pt-br, ro, ru with the same keys)
├── client/client.lua
└── server/server.lua
```

**fxmanifest.lua**

```lua
fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'
lua54 'yes'

description 'rsg-example'
version '1.0.0'

shared_scripts {
    '@rsg-core/shared/locale.lua',
    'shared/config.lua',
}
client_scripts { 'client/client.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/server.lua' }
files { 'locales/*.json' }

dependencies { 'rsg-core', 'rsg-inventory', 'oxmysql' }
```

**shared/config.lua**

```lua
Config = {}

Config.Shop = {
    coords = vector3(-324.2, 803.9, 117.9),
    distance = 3.0,
    items = {
        bandage = { price = 5 },
        water   = { price = 1 },
    },
}
```

**locales/en.json**

```json
{
  "prompt": { "open": "Open Shop" },
  "notify": {
    "bought": "Bought %s for $%s",
    "no_cash": "Not enough cash",
    "too_far": "You are too far away",
    "full": "Inventory full"
  },
  "progress": { "buying": "Buying..." }
}
```

**server/server.lua**

```lua
local RSGCore = exports['rsg-core']:GetCoreObject()

-- callback: client asks what it may buy
RSGCore.Functions.CreateCallback('rsg-example:server:getItems', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end
    cb(Config.Shop.items)
end)

-- validated purchase
RegisterNetEvent('rsg-example:server:buy', function(item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local entry = type(item) == 'string' and Config.Shop.items[item]
    if not entry then return end

    local coords = GetEntityCoords(GetPlayerPed(src))
    if #(coords - Config.Shop.coords) > Config.Shop.distance + 2.0 then
        return RSGCore.Functions.Notify(src, locale('notify.too_far'), 'error')
    end

    if not exports['rsg-inventory']:CanAddItem(src, item, 1) then
        return RSGCore.Functions.Notify(src, locale('notify.full'), 'error')
    end
    if not Player.Functions.RemoveMoney('cash', entry.price, 'example-shop') then
        return RSGCore.Functions.Notify(src, locale('notify.no_cash'), 'error')
    end

    exports['rsg-inventory']:AddItem(src, item, 1, nil, nil, 'example-shop')
    RSGCore.Functions.Notify(src, locale('notify.bought', RSGCore.Shared.Items[item].label, entry.price), 'success')
end)

-- usable item
RSGCore.Functions.CreateUseableItem('bandage', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    if exports['rsg-inventory']:RemoveItem(source, 'bandage', 1, item.slot, 'used-bandage') then
        TriggerClientEvent('rsg-example:client:heal', source)
    end
end)

-- admin command
RSGCore.Commands.Add('shopprice', 'Show a shop price', {
    { name = 'item', help = 'Item name' },
}, true, function(source, args)
    local e = Config.Shop.items[args[1]]
    RSGCore.Functions.Notify(source, e and ('$' .. e.price) or 'unknown item', e and 'inform' or 'error')
end, 'admin')
```

**client/client.lua**

```lua
local RSGCore = exports['rsg-core']:GetCoreObject()
local PlayerData = {}

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function() PlayerData = RSGCore.Functions.GetPlayerData() end)
RegisterNetEvent('RSGCore:Player:SetPlayerData', function(val) PlayerData = val end)
RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function() PlayerData = {} end)

-- prompt at the shop
CreateThread(function()
    exports['rsg-core']:createPrompt('rsg-example:shop', Config.Shop.coords,
        RSGCore.Shared.Keybinds['J'], locale('prompt.open'), {
            type = 'client', event = 'rsg-example:client:openshop',
        })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    exports['rsg-core']:deletePrompt('rsg-example:shop')
end)

RegisterNetEvent('rsg-example:client:openshop', function()
    local items = RSGCore.Functions.AwaitCallback('rsg-example:server:getItems', 5000)
    if not items then return end
    local done = RSGCore.Functions.ProgressBar({
        duration = 2000, label = locale('progress.buying'), canCancel = true,
        disable = { move = true, combat = true },
    })
    if done then TriggerServerEvent('rsg-example:server:buy', 'bandage') end
end)

RegisterNetEvent('rsg-example:client:heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), GetEntityHealth(ped) + 50))
end)
```

---

## 28. Database Schema

| Table | Created by | Notes |
|---|---|---|
| `players` | automatic (`AutoDatabase`) or `install.sql` | One row per character, keyed by `citizenid` |
| `bans` | automatic (`AutoDatabase`) or `install.sql` | Used by join checks and `ExploitBan` |
| `players.weight`, `players.slots` | automatic | Added at start if missing (defaults `35000` / `25`) |
| `players.outlawstatus` | automatic | Added at start if missing (default `0`); used by rsg-hud, rsg-lawman, rsg-looting, rsg-prison, rsg-playerinfo |
| `multijob_jobs` | automatic | Job definitions |
| `player_jobs` | automatic | Jobs each character holds; unique key `uniq_player_job (citizenid, job)` (duplicates are removed on first start) |

```sql
CREATE TABLE IF NOT EXISTS `multijob_jobs` (
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `type` VARCHAR(50) NULL DEFAULT NULL,
    `icon` VARCHAR(100) NULL DEFAULT NULL,
    `default_duty` TINYINT(1) NOT NULL DEFAULT 1,
    `off_duty_pay` TINYINT(1) NOT NULL DEFAULT 0,
    `grades` LONGTEXT NOT NULL,            -- JSON: { "0": { "name": "...", "payment": 10 }, ... }
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`name`)
);

CREATE TABLE IF NOT EXISTS `player_jobs` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `job` VARCHAR(50) NOT NULL,
    `grade` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`)
);
```

Query by character from your own resource (always parameterised):

```lua
local rows = MySQL.query.await('SELECT job, grade FROM player_jobs WHERE citizenid = ?', { citizenid })
```

---

## 29. Return Values & Error Codes

| Call | Success | Failure |
|---|---|---|
| `Player.Functions.AddMoney / RemoveMoney / SetMoney` | `true` | `false` (bad type, bad amount, or insufficient funds on remove) |
| `Player.Functions.GetMoney(type)` | number | `false` for unknown type |
| `Player.Functions.SetJob(job, grade)` | `true` | `false` for unknown job or grade |
| `AddPlayerJob` | `true` | `false, 'invalid_job' \| 'invalid_grade' \| 'player_not_found' \| 'max_jobs'` |
| `RemovePlayerJob` | `true` | `false, 'invalid_job' \| 'player_not_found' \| 'job_not_held'` |
| `CanTakePlayerJob` | `true` | `false, 'already_held' \| 'max_jobs' \| …` |
| `SaveJobDefinition` | `def` | `nil, 'not_loaded' \| 'adm_err_*'` |
| `AddItem / AddJob / AddGang` (and `Update*`, `Remove*`) | `true, msg` | `false, 'invalid_<x>_name' \| '<x>_exists' \| '<x>_not_exists'` |
| `AddItems / AddJobs / AddGangs` | `true, msg` | `false, msg, failedData` (nothing applied) |
| `SetPlayerBucket / SetEntityBucket` | `true` | `false` (missing argument) |
| `GetClosestPlayer` (server) | `id, distance` | `-1, -1` when no other player |
| `AwaitCallback / AwaitClientCallback` | value | `nil` on timeout |
| `PrepForSQL` | `true` | `false` (and logs an anticheat entry) |
| `GetPlayer / GetPlayerByCitizenId …` | Player | `nil` |

```lua
local ok, err = exports['rsg-core']:AddItem('rope', { name = 'rope', label = 'Rope', weight = 100, type = 'item' })
if not ok then print('AddItem failed:', err) end   -- e.g. 'item_exists'
```

---

## Zones, raycast, nearby entities, table helpers

### Zones – `@rsg-core/client/zones.lua` (replaces `lib.zones`)
Include it in the resource that owns the zones (callbacks stay local to that resource):
```lua
client_scripts { '@rsg-core/client/zones.lua', 'client/*.lua' }
```
```lua
local z = zones.sphere({ coords = vec3(0, 0, 0), radius = 2.0, debug = false,
    onEnter = function(self) end, onExit = function(self) end, inside = function(self) end })
zones.box({ coords = vec3(...), size = vec3(2, 2, 2), rotation = 45.0 })
zones.poly({ points = { vec3(...), vec3(...), vec3(...) }, thickness = 4.0 })
z:contains(coords)   z:remove()
zones.getAllZones()  zones.getCurrentZones()  zones.getNearbyZones()
```
Each zone has `id`, `coords`, `distance` (to the player, updated every 300 ms), `near` (distance at which the zone starts being checked: 75 m, or larger for big spheres/boxes/polygons so towns and districts always trigger) and `insideZone`. Extra fields you pass are kept. The globals `Zones` (id → zone) and `zones` are set in the including resource. `inside` and debug drawing run per frame only while needed.

### Points – `@rsg-core/client/points.lua` (replaces `lib.points`)
Include it in the resource that owns the points:
```lua
client_scripts { '@rsg-core/client/points.lua', 'client/*.lua' }
```
```lua
local p = points.new({ coords = vec3(0, 0, 0), distance = 50.0,
    onEnter = function(self) end, onExit = function(self) end, nearby = function(self) end })
points.new(coords, distance, { onEnter = ... })   -- positional form
p:remove()
points.getAllPoints()  points.getNearbyPoints()  points.getClosestPoint()
```
Each point has `id`, `coords`, `distance`, `currentDistance` (while nearby, updated every 300 ms) and `isClosest`. Extra fields you pass are kept. `nearby` runs every frame only while the player is in range. Points are removed (with `onExit`) when the owning resource stops. The global `points` is set in the including resource.

### Raycast (replaces `lib.raycast`)
```lua
local hit, entity, endCoords, normal = RSGCore.Functions.RaycastCamera(flags, ignore, distance)
local hit, entity, endCoords, normal = RSGCore.Functions.Raycast(fromVec3, toVec3, flags, ignore)
```
`flags` defaults to 511 and `ignore` to 4. Both yield, so call them from a thread.

### Nearby entities (replaces `lib.getNearbyPeds/Vehicles/Objects`)
`RSGCore.Functions.GetNearbyPeds(coords, maxDist)` returns `{ { ped, coords, distance } }` (non-player peds). `GetNearbyVehicles(coords, maxDist, includePlayerVehicle)` and `GetNearbyObjects(coords, maxDist)` return the same shape with a `vehicle` / `object` key.

### Other
- `RSGCore.Functions.RequestStreamedTextureDict(dict, timeout)` replaces `lib.requestStreamedTextureDict`.
- `@rsg-core/shared/table.lua` adds `table.type`, `table.wipe`, `table.clone` and `table.contains` when the runtime lacks them. It is also loaded by rsg-core itself (`server/player.lua` already uses `table.type`).
- Progress detection: `RSGCore.Functions.IsProgressActive()` replaces `lib.progressActive`.
- rsg-core has no context menu, so there is no `lib.getOpenContextMenu` equivalent.

<!-- BEGIN AUTO-REFERENCE (generated from the code; re-run the generator instead of editing by hand) -->

## Technical reference

Generated from the source of **rsg-core 3.3.1**. Names, arguments and defaults below are read straight from the code.

### Dependencies

`oxmysql`

### Database

Tables: `players`, `bans`, `multijob_jobs`, `player_jobs`.

Tables are created automatically on start while `Config.AutoDatabase = true` (default). Nothing is ever dropped or overwritten.
For a manual install set `Config.AutoDatabase = false` and import `install.sql` once.

```lua
-- shared/config.lua
Config.AutoDatabase = true -- false = import the SQL file yourself
```

### Exports

**Server**

| Export | Arguments | File |
|---|---|---|
| `AddMoney` | `src, moneytype, amount, reason` | `server/api.lua` |
| `RemoveMoney` | `src, moneytype, amount, reason` | `server/api.lua` |
| `GetMoney` | `src, moneytype` | `server/api.lua` |
| `GetMetaData` | `src, key` | `server/api.lua` |
| `SetMetaData` | `src, key, value` | `server/api.lua` |
| `GetJob` | `src` | `server/api.lua` |
| `GetGang` | `src` | `server/api.lua` |
| `CreateCron` | `` | `server/cron.lua` |
| `StopCron` | `` | `server/cron.lua` |
| `SetMethod` | `` | `server/exports.lua` |
| `SetField` | `` | `server/exports.lua` |
| `GetCoreVersion` | `` | `server/exports.lua` |
| `ExploitBan` | `` | `server/exports.lua` |
| `GetCoreObject` | `` | `server/main.lua` |
| `GetWeapons` | `` | `shared/main.lua` |

**Client**

| Export | Arguments | File |
|---|---|---|
| `DrawText` | `` | `client/drawtext.lua` |
| `ChangeText` | `` | `client/drawtext.lua` |
| `HideText` | `` | `client/drawtext.lua` |
| `KeyPressed` | `` | `client/drawtext.lua` |
| `IsTextShown` | `` | `client/drawtext.lua` |
| `GenerateCSRFToken` | `` | `client/events.lua` |
| `Notify` | `...` | `client/functions.lua` |
| `RequestModel` | `` | `client/lib.lua` |
| `RequestAnimDict` | `` | `client/lib.lua` |
| `RequestAnimSet` | `` | `client/lib.lua` |
| `RequestNamedPtfxAsset` | `` | `client/lib.lua` |
| `RequestStreamedTextureDict` | `` | `client/lib.lua` |
| `Raycast` | `` | `client/lib.lua` |
| `RaycastCamera` | `` | `client/lib.lua` |
| `GetNearbyPeds` | `` | `client/lib.lua` |
| `GetNearbyVehicles` | `` | `client/lib.lua` |
| `GetNearbyObjects` | `` | `client/lib.lua` |
| `GetCoreObject` | `` | `client/main.lua` |
| `ProgressBar` | `` | `client/progress.lua` |
| `ProgressCircle` | `` | `client/progress.lua` |
| `IsProgressActive` | `` | `client/progress.lua` |
| `CancelProgress` | `` | `client/progress.lua` |
| `createPrompt` | `` | `client/prompts.lua` |
| `createPromptGroup` | `` | `client/prompts.lua` |
| `getPrompt` | `` | `client/prompts.lua` |
| `getPromptGroup` | `` | `client/prompts.lua` |
| `deletePrompt` | `` | `client/prompts.lua` |
| `deletePromptGroup` | `` | `client/prompts.lua` |

```lua
-- example
local result = exports['rsg-core']:AddMoney(src, moneytype, amount, reason)
```

### Callbacks

| Callback | Side | Arguments | File |
|---|---|---|---|
| `RSGCore:Server:SpawnVehicle` | server | `source, cb, model, coords, warp` | `server/events.lua` |
| `rsg-multijob:server:admin:getJobs` | server | `source` | `server/multijob/admin.lua` |
| `rsg-multijob:server:admin:saveJob` | server | `source, job, isNew` | `server/multijob/admin.lua` |
| `rsg-multijob:server:admin:deleteJob` | server | `source, name` | `server/multijob/admin.lua` |
| `rsg-multijob:server:admin:importCore` | server | `source` | `server/multijob/admin.lua` |
| `rsg-multijob:server:admin:getHolders` | server | `source, job` | `server/multijob/admin.lua` |
| `rsg-multijob:server:admin:assignJob` | server | `source, data` | `server/multijob/admin.lua` |
| `rsg-multijob:server:admin:setGrade` | server | `source, data` | `server/multijob/admin.lua` |
| `rsg-multijob:server:admin:removeHolder` | server | `source, data` | `server/multijob/admin.lua` |
| `rsg-multijob:server:myJobs` | server | `source` | `server/multijob/server.lua` |

```lua
-- client side
RSGCore.Functions.TriggerCallback('RSGCore:Server:SpawnVehicle', function(result)
    -- use result
end, model, coords, warp)
```

### Events

Server events can be fired by any client, so every handler re-validates the player, the arguments and any permission, distance or cooldown on the server. Never add a reward to a handler without those checks.

| Event | Side | Arguments | File |
|---|---|---|---|
| `rsg-core:client:DrawText` | client | `` | `client/drawtext.lua` |
| `rsg-core:client:ChangeText` | client | `` | `client/drawtext.lua` |
| `rsg-core:client:HideText` | client | `` | `client/drawtext.lua` |
| `rsg-core:client:KeyPressed` | client | `` | `client/drawtext.lua` |
| `RSGCore:Client:OnPlayerLoaded` | client | `` | `client/events.lua` |
| `RSGCore:Client:OnPlayerUnload` | client | `` | `client/events.lua` |
| `RSGCore:Client:PvpHasToggled` | client | `pvp_state` | `client/events.lua` |
| `RSGCore:Command:GoToMarker` | client | `` | `client/events.lua` |
| `RSGCore:Command:TeleportToPlayer` | client | `coords` | `client/events.lua` |
| `RSGCore:Command:TeleportToCoords` | client | `x, y, z, h` | `client/events.lua` |
| `RSGCore:Command:ToggleNoClip` | client | `` | `client/events.lua` |
| `RSGCore:Command:SpawnVehicle` | client | `vehName` | `client/events.lua` |
| `RSGCore:Command:DeleteVehicle` | client | `` | `client/events.lua` |
| `RSGCore:Client:Notify` | client | `...` | `client/events.lua` |
| `RSGCore:Notify` | client | `...` | `client/events.lua` |
| `RSGCore:Player:SetPlayerData` | client | `val` | `client/events.lua` |
| `RSGCore:Player:UpdatePlayerData` | client | `` | `client/events.lua` |
| `RSGCore:Client:TriggerClientCallback` | client | `name, ...` | `client/events.lua` |
| `RSGCore:Client:TriggerCallback` | client | `name, ...` | `client/events.lua` |
| `RSGCore:Client:TriggerCallbackId` | client | `requestId, ...` | `client/events.lua` |
| `RSGCore:Command:ShowMe3D` | client | `senderId, msg` | `client/events.lua` |
| `RSGCore:Client:OnSharedUpdate` | client | `tableName, key, value` | `client/events.lua` |
| `RSGCore:Client:OnSharedUpdateMultiple` | client | `tableName, values` | `client/events.lua` |
| `rsg-multijob:client:openmenu` | client | `` | `client/multijob.lua` |
| `rsg-multijob:client:refreshJobs` | client | `jobs, currentJobName` | `client/multijob.lua` |
| `RSGCore:Client:OnJobUpdate` | client | `job` | `client/multijob.lua` |
| `rsg-multijob:client:openAdmin` | client | `` | `client/multijob.lua` |
| `rsg-core:client:CancelProgress` | client | `` | `client/progress.lua` |
| `RSGCore:Server:CloseServer` | server | `reason` | `server/events.lua` |
| `RSGCore:Server:OpenServer` | server | `` | `server/events.lua` |
| `RSGCore:Server:TriggerClientCallback` | server | `name, ...` | `server/events.lua` |
| `RSGCore:Server:TriggerCallback` | server | `name, ...` | `server/events.lua` |
| `RSGCore:Server:TriggerCallbackId` | server | `name, requestId, ...` | `server/events.lua` |
| `RSGCore:UpdatePlayer` | server | `` | `server/events.lua` |
| `RSGCore:Server:SetMetaData` | server | `meta, data` | `server/events.lua` |
| `RSGCore:ToggleDuty` | server | `` | `server/events.lua` |
| `RSGCore:CallCommand` | server | `command, args` | `server/events.lua` |
| `RSGCore:Server:KickCSRF` | server | `` | `server/events.lua` |
| `RSGCore:Server:OnPlayerLoaded` | server | `` | `server/moneyitems.lua` |
| `rsg-multijob:server:changeJob` | server | `job` | `server/multijob/server.lua` |
| `rsg-multijob:server:deleteJob` | server | `job` | `server/multijob/server.lua` |
| `rsg-bossmenu:server:FireEmployee` | server | `target` | `server/multijob/server.lua` |

```lua
-- from a client script
TriggerServerEvent('RSGCore:Server:CloseServer', reason)
-- from a server script
TriggerClientEvent('rsg-core:client:DrawText', source)
```

### Commands

| Command | Notes | File |
|---|---|---|
| `/tp` | locale('command.tp.help') | `server/commands.lua` |
| `/tpm` | locale('command.tpm.help') | `server/commands.lua` |
| `/togglepvp` | locale('command.togglepvp.help') | `server/commands.lua` |
| `/noclip` | locale('command.noclip.help') | `server/commands.lua` |
| `/addpermission` | locale('command.addpermission.help') | `server/commands.lua` |
| `/removepermission` | locale('command.removepermission.help') | `server/commands.lua` |
| `/openserver` | locale('command.openserver.help') | `server/commands.lua` |
| `/closeserver` | locale('command.closeserver.help') | `server/commands.lua` |
| `/vehicle` | locale('command.car.help') | `server/commands.lua` |
| `/dv` | locale('command.dv.help') | `server/commands.lua` |
| `/dvall` | locale('command.dvall.help') | `server/commands.lua` |
| `/dvp` | locale('command.dvp.help') | `server/commands.lua` |
| `/dvo` | locale('command.dvo.help') | `server/commands.lua` |
| `/givemoney` | locale('command.givemoney.help') | `server/commands.lua` |
| `/setmoney` | locale('command.setmoney.help') | `server/commands.lua` |
| `/job` | locale('command.job.help') | `server/commands.lua` |
| `/setjob` | locale('command.setjob.help') | `server/commands.lua` |
| `/gang` | locale('command.gang.help') | `server/commands.lua` |
| `/setgang` | locale('command.setgang.help') | `server/commands.lua` |
| `/ooc` | locale('command.ooc.help') | `server/commands.lua` |
| `/me` | locale('command.me.help') | `server/commands.lua` |
| `/id` | locale('command.id.help') | `server/commands.lua` |
| `/cid` | locale('command.cid.help') | `server/commands.lua` |
| `/myjobs` | locale('cmd_myjobs_desc') | `server/multijob/server.lua` |
| `/removejob` | locale('cmd_removejob_desc') | `server/multijob/server.lua` |

### Locales

Language files in `locales/`: `de`, `el`, `en`, `es`, `fr`, `ja`, `nl`, `pl`, `pt-br`, `ro`, `ru`. Set the language with `setr rsg:locale "en"`.

<!-- END AUTO-REFERENCE -->
