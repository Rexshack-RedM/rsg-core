# rsg-core Developer Documentation

> Version **3.7.0** · RedM · Lua 5.4 · Depends only on `oxmysql`
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
30. [Zones, Points, Raycast & Table Helpers](#30-zones-points-raycast--table-helpers)
31. [Function Examples](#31-function-examples)
32. [Architecture, Data Flow & Persistence](#32-architecture-data-flow--persistence)
33. [Internal Callbacks & Events](#33-internal-callbacks--events)
34. [Server Owner How-tos](#34-server-owner-how-tos)
35. [Troubleshooting](#35-troubleshooting)

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
setr rsg:locale "en"   # falls back to ox:locale, then en
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
| `SpawnVehicle(source, model, coords?, warp?)` | Uses `CreateVehicle` server-side. Yields. Returns the entity handle, or `nil` if it did not appear within 5 s |
| `CreateVehicle(source, model, vehtype, coords, warp)` | `CreateVehicleServerSetter`. Yields. Returns the entity handle or `nil` |

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
- Paychecks every `PayCheckTimeOut` minutes use the grade `payment`; `offDutyPay` on the job decides if off-duty players are paid. With `PayCheckSociety = true` and rsg-society started, wages come out of the society account and are skipped when it is empty.
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
| `Key` | `''` | Default key for `/myjobs` (unbound; rebindable in the game's key settings) |
| `Admin.Command` | `'jobadmin'` | Chat command that opens the job editor |
| `Admin.Permission` | `'admin'` | Permission level required for the editor |
| `JobIcons` | table | Fallback Font Awesome icon per job name. An icon saved in `/jobadmin` wins |

`server/multijob/sv_config.lua` → `MultiJobWebhookConfig` (server-only so URLs never reach clients):

| Key | |
|---|---|
| `Enabled` | Master switch for all job webhook logging |
| `DefaultURL` | Used by any event without its own `URL` |
| `BotName`, `BotAvatar`, `FooterText`, `FooterIcon`, `DefaultColor` | Embed styling |
| `Events.<Name>` | `{ Enabled, URL, Title, Color }` per event: `JobAdded`, `JobSwitched`, `JobDeleted`, `JobRemovedByAdmin`, `JobCreated`, `JobUpdated`, `JobDefinitionDeleted` |

```lua
-- send "Job Removed By Admin" to its own channel and silence "Job Switched"
MultiJobWebhookConfig.Events.JobRemovedByAdmin.URL = 'https://discord.com/api/webhooks/...'
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

Joining while the server is closed requires ACE `rsgadmin.join` or the `RSGConfig.Server.WhitelistPermission` permission.

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
| `/claimmoney` | user | Collect held payouts (5 second cooldown) |
| `/playtime [target]` | user | Own playtime; a target needs `admin` |
| `/transactions <id\|citizenid> [count]` | admin | Recent transactions, max 30 |
| `/ban <id> <30m\|12h\|7d\|2w\|perm> [reason]` | admin | Drops every connected client on that license |
| `/offlineban <citizenid> <duration> [reason]` | admin | License ban only (no Discord or IP) |
| `/unban <banId>`, `/banlist [search]` | admin | Search matches name, license or reason |
| `/whitelist add\|remove\|list [target]` | admin | Target: server id, citizenid or `license:hex` |

All of these except `/claimmoney` also work from the console where a target is given.

### Held payouts

`exports['rsg-core']:QueuePayout(citizenid, moneytype, amount, reason)` (also `RSGCore.Functions.QueuePayout`) returns `true` when the payout was accepted. `moneytype` must exist in `Money.MoneyTypes`, `amount` must be positive (cents are kept; gold is whole numbers). It does not check that the citizen ID exists, and the insert is not awaited.

When a money item cannot be added after the character has loaded, the value is queued with reason `inventory-full`. The row is deleted before it is paid, so it can only be paid once. If it still does not fit it is stored again. A server crash between the delete and the player save can lose that one claim.

### Playtime and history

`exports['rsg-core']:GetPlaytime(citizenid)` (server, yields) returns seconds, including the current session. Playtime is counted from installation of 3.7.0.
Transactions are written in batches every 5 seconds. They cover changes made through the core money functions, plus money item movement in the inventory (operation `items`, signed amount). Edits made directly to the database are not recorded.

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
| `RegisterKey(name, description, defaultKey, onPress?, onRelease?, opts?)` | Rebindable key (see below) |
| `UnregisterKey(name)` | Stops a registered key from doing anything |
| `RSGCore.Debug(...)` | Prints to F8 console |
| `exports['rsg-core']:GenerateCSRFToken()` | Token for securing NUI callbacks |

Login check:

```lua
if LocalPlayer.state.isLoggedIn then ... end
```

### Rebindable keys (`RegisterKey`)

`RegisterKey` wraps `RegisterKeyMapping` and a `+name` / `-name` command pair. The key you pass is only the **default**: players rebind it in the game's key settings, so a server owner can no longer force a key from a config file alone.

```lua
RSGCore.Functions.RegisterKey('myres_open', locale('key_open'), 'I',
    function() OpenMenu() end,   -- key down
    function() end,              -- key up (only called if the press was accepted)
    { canTrigger = function() return not IsPauseMenuActive() end })
```

| Parameter | Description |
|---|---|
| `name` | Unique id. Becomes the command `+name` / `-name`. Use your resource name as a prefix |
| `description` | Text in the key settings. Pass `locale('...')` |
| `defaultKey` | Default key name: `'I'`, `'Z'`, `'1'`, `'F5'` |
| `onPress` / `onRelease` | Callbacks. A release only fires if its press was accepted |
| `opts.mapper` | Mapper, default `'keyboard'` |
| `opts.requireLogin` | Default `true`: ignored until the player is logged in |
| `opts.allowWhileNui` | Default `false`: ignored while a NUI has focus |
| `opts.canTrigger` | Extra check, return `false` to ignore the press |

Notes:
- Registering the same `name` again replaces the handlers (restarts are safe). Handlers from a stopped resource are removed automatically.
- A mapping does **not** stop the game's own action on that key. If the default key is also used by the game (for example `I` or `1`-`5`), keep calling `DisableControlAction` for it.
- A key mapping cannot be removed during a session; `UnregisterKey` only stops the handler.
- Keep a config switch (for example `Config.UseKeyMapping`) so servers can fall back to control-hash polling if mapping misbehaves on their build.

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
| `RSGCore:Server:OnPlayerLoaded` | Net event fired by the client once the character is ready; core only uses it as a fallback for money item sync (the sync now starts server-side on `PlayerLoaded`). Prefer `PlayerLoaded` for your own code |
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
| `hud:client:OnMoneyChange` | `moneytype, amount, isMinus` (HUD feedback, sent after a money change for types that are not money items) |
| `RSGCore:Client:OnPlayerDied` | Local client event (use `AddEventHandler`): `killerServerId|nil, weaponHash`. A client-side hint only, never reward from it |

### Events rsg-core sends to other resources

| Event | Sent | Payload |
|---|---|---|
| `rsg-log:server:CreateLog` | server `TriggerEvent` | `name, title, color, message, tagEveryone?`. Handled by your log resource (rsg-essentials) |
| `rsg-inventory:client:updateInventory` | to a client | none; sent after money items are reconciled |
| `chat:addMessage`, `chat:addSuggestions`, `chat:removeSuggestion` | to a client | standard chat resource events, used for command output and help |

```lua
-- a minimal log handler, if you do not run rsg-essentials
AddEventHandler('rsg-log:server:CreateLog', function(name, title, color, message, tagEveryone)
    print(('[%s] %s: %s'):format(name, title, message))
end)

-- client: local death hint (screen effects, sounds). Rewards belong in RSGCore:Server:OnPlayerKilled
AddEventHandler('RSGCore:Client:OnPlayerDied', function(killer, weapon)
    print('you died', killer, weapon)
end)
```

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

`RSGCore:Server:TriggerCallbackId`, `RSGCore:Server:TriggerClientCallback`, `RSGCore:Client:TriggerCallbackId` and `RSGCore:Client:TriggerClientCallback` carry the callback request/response traffic. Pending client callbacks are keyed by source and request id (`RSGCore.Functions.ClientCallbackKey(source, requestId)`), so one client can never answer another client's request and two calls to the same callback do not overwrite each other. Do not trigger these directly; use `TriggerCallback` / `AwaitCallback` and the client-callback equivalents from §5.

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
| `Money.PayCheckSociety` | `true` | Wages come from rsg-society accounts when it is running; an empty account skips the wage |
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
| `Death.Enabled` | `true` | Turns the death and kill events on |
| `Death.MaxKillDistance` | `500.0` | Metres allowed between the victim and the claimed killer (server positions) |
| `Death.RequireKillerConfirm` | `true` | The killer's client must confirm the kill. `false` credits it on the other checks alone, which is easier to abuse |
| `Death.ConfirmTimeout` | `3000` | Milliseconds to wait for that confirmation |
| `Death.MinSecondsBetween` | `8` | Repeat death reports from one victim inside this window are ignored |
| `Transactions` | `Enabled = true, RetentionDays = 30` | Money history; `0` days keeps everything |
| `Playtime` | `Enabled = true` | Playtime tracking |
| `AllowPushToTalkWhileOpen` / `PushToTalkControls` | `true` / `{ 0x4BC9DABB }` | While `/myjobs` or `/jobadmin` is open, game controls are blocked but push-to-talk keeps working |
| `Notify` | Position, Duration, MaxVisible, Sound | |
| `Progress` | CancelKey `0x8CC9CD42` (X), CancelLabel | |
| `ClientWritableMetadata` | hunger, thirst, cleanliness, stress, health, armor | |

`shared/multijob.lua` (`RSGConfig.MultiJob`): `MaxJobs = 3`, `JobSwitchCooldown = 3000`, `Key = ''` (default `/myjobs` key, unbound), `Admin = { Command = 'jobadmin', Permission = 'admin' }`, `JobIcons` (see §9).

`shared/main.lua` (`RSGShared.StarterItems`): items given to new characters, `{ bread = { amount = 5, item = 'bread' }, water = { amount = 5, item = 'water' } }`.

Config is read on both sides, so a change needs a resource restart (`ensure rsg-core`) or a server restart.
`server/multijob/sv_config.lua`: Discord webhooks per job event (server-only).

### Database

- Created automatically when `RSGConfig.AutoDatabase = true` (default): `players`, `bans`, `multijob_jobs`, `player_jobs`, `rsg_held_payouts`, `rsg_transactions`, `rsg_playtime`, `rsg_whitelist`, and the `weight`/`slots`/`outlawstatus` columns.
- Manual install: set `RSGConfig.AutoDatabase = false` and import `install.sql` (same schema, kept in sync).

| Option | Default | Description |
|---|---|---|
| `RSGConfig.AutoDatabase` | `true` | Create the tables on start |
| `RSGConfig.Limits` | see config | `SpawnPermission`, `DutyCooldownMs`, `SpawnCooldownMs`, `SpawnMaxDistance`, `MeCooldownMs`, `OocCooldownMs`, `OocRange`. `SpawnPermission` (default `'admin'`) is needed for the `RSGCore:Server:SpawnVehicle` callback; `false` allows any player |
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
| `AddPlayerMethod(ids, name, fn)` / `AddPlayerField(ids, name, value)` | | Extend Player objects (`ids` = a numeric server id, an array of ids, or `-1` for all online players; citizen ids are not accepted) |
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
- `GenerateCSRFToken()` ties a NUI request to a recent token. It runs on the client, so it is **not** a security boundary.
- Closed server: `RSGCore.Functions.CanJoinClosed(src)` (ACE `rsgadmin.join` or the whitelist permission) is used both when joining and when closing the server, so the two checks agree.
- Admin commands are audit logged (console + rsg-log). `/tp x y` probes ground; `SafeTeleport` moves mounts/vehicles with the player.
- New server exports `SetJobs`, `SetItems`, `SetGangs` add or overwrite many shared entries with one client broadcast.
- Prompts created through the exports are tracked per resource and removed when that resource stops.
- Failed money item grants (e.g. full inventory) are logged and held for `/claimmoney`. `error.money_item_failed` is only shown if the amount could not be held.
- `RSGCore:CallCommand` checks command permissions server-side (`RSGCore.Commands.CanUse(src, cmd)`) and only passes string/number arguments (max 20) to command callbacks.
- `RSGCore.Functions.IsPlayerBanned` checks every ban row for a license (the longest active ban wins; expired rows are cleaned up).
- Players cannot connect until the job definitions have loaded from `multijob_jobs` (otherwise their saved job would be reset to unemployed).
- `/ooc` is limited to 255 characters and a 2 second cooldown per player.
- `PrepForSQL` validates strings before raw SQL; always prefer parameterised `MySQL` queries.
- Multi-job admin callbacks are permission- and rate-limited.
- The version checker (`server/versionchecker.lua`) only reads `version.txt` from GitHub on resource start and prints whether you are up to date; it changes nothing.

### CSRF-protected NUI callback

`GenerateCSRFToken()` returns a single-use token that expires after 30 seconds; several can be pending at once. The NUI sends it back to `validateCSRF`. See `client/events.lua` for the failed-attempt handling.

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
| `rsg_held_payouts` | automatic | Money waiting to be claimed; removed when a character is deleted |
| `rsg_transactions` | automatic | Money history; kept after character deletion, pruned by `RetentionDays` |
| `rsg_playtime` | automatic | Seconds played per character; removed when a character is deleted |
| `rsg_whitelist` | automatic | In-game whitelist, keyed by license |

This is `install.sql`. Automatic creation builds the same tables and columns; there, `player_jobs` also gets a plain `citizenid` index, and the two job tables use your database's default engine and character set:

```sql
-- rsg-core database schema (also created automatically when RSGConfig.AutoDatabase = true)

CREATE TABLE IF NOT EXISTS `players` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `cid` int(11) DEFAULT NULL,
  `license` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `money` text NOT NULL,
  `charinfo` text DEFAULT NULL,
  `job` text NOT NULL,
  `gang` text DEFAULT NULL,
  `position` text NOT NULL,
  `metadata` text NOT NULL,
  `inventory` longtext DEFAULT NULL,
  `weight` int(11) DEFAULT 35000,
  `slots` int(11) DEFAULT 25,
  `outlawstatus` int(11) NOT NULL DEFAULT 0,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`citizenid`),
  KEY `id` (`id`),
  KEY `last_updated` (`last_updated`),
  KEY `license` (`license`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `bans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `license` varchar(50) DEFAULT NULL,
  `discord` varchar(50) DEFAULT NULL,
  `ip` varchar(50) DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `expire` int(11) DEFAULT NULL,
  `bannedby` varchar(255) NOT NULL DEFAULT 'Unknown',
  PRIMARY KEY (`id`),
  KEY `license` (`license`),
  KEY `discord` (`discord`),
  KEY `ip` (`ip`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `multijob_jobs` (
  `name` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `type` varchar(50) DEFAULT NULL,
  `icon` varchar(100) DEFAULT NULL,
  `default_duty` tinyint(1) NOT NULL DEFAULT 1,
  `off_duty_pay` tinyint(1) NOT NULL DEFAULT 0,
  `grades` longtext NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `player_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `job` varchar(50) NOT NULL,
  `grade` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_player_job` (`citizenid`,`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `rsg_held_payouts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `moneytype` varchar(20) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `reason` varchar(100) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `rsg_transactions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `moneytype` varchar(20) NOT NULL,
  `operation` varchar(10) NOT NULL,
  `amount` decimal(20,2) NOT NULL,
  `balance` decimal(20,2) NOT NULL,
  `reason` varchar(150) DEFAULT NULL,
  `resource` varchar(60) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `rsg_playtime` (
  `citizenid` varchar(50) NOT NULL,
  `seconds` bigint(20) NOT NULL DEFAULT 0,
  `first_seen` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_seen` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `rsg_whitelist` (
  `license` varchar(60) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `added_by` varchar(100) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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

## 30. Zones, Points, Raycast & Table Helpers

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

---

## 31. Function Examples

Examples for the functions that earlier sections only list. Server snippets assume `src` is a player's server id, client snippets run in a thread where a function yields, and `RSGCore` is the core object (§1).

### Server: players and identity

```lua
local license = RSGCore.Functions.GetIdentifier(src, 'license')   -- 'license:xxxx' or nil
local online  = RSGCore.Functions.GetSource(license)              -- server id, 0 if no loaded character
local ids     = RSGCore.Functions.GetPlayers()                    -- { 1, 4, 7 }

for id, Player in pairs(RSGCore.Functions.GetRSGPlayers()) do     -- loaded Player objects
    print(id, Player.PlayerData.citizenid)
end

local byAccount = RSGCore.Functions.GetPlayerByAccount(accountNumber)  -- online only
local byLicense = RSGCore.Functions.GetPlayerByLicense(license)        -- online, else loaded from the DB (yields)
local lawmen    = RSGCore.Functions.GetDutyCount('vallaw')
local inUse     = RSGCore.Functions.IsLicenseInUse(license)           -- true if any connected client has it
local job, gang = exports['rsg-core']:GetJob(src), exports['rsg-core']:GetGang(src)
```

### Server: `RSGCore.Player` lifecycle

These are low level. Character selection scripts use `Login` / `Logout`; most resources only need the offline getters.

```lua
-- load an existing character (it must belong to this player's license, otherwise they are dropped)
local ok = RSGCore.Player.Login(src, citizenid)
-- create a new one
RSGCore.Player.Login(src, nil, { cid = 1, charinfo = { firstname = 'Arthur', lastname = 'Morgan', birthdate = '1863-01-01', gender = 0, nationality = 'American' } })
RSGCore.Player.Logout(src)   -- saves and unloads (yields 200 ms)

-- offline characters: both return nil when nothing is found, and both yield
local offline = RSGCore.Player.GetOfflinePlayer(citizenid)
local newest  = RSGCore.Player.GetOfflinePlayerByLicense(license) -- most recently saved character
if offline then
    offline.Functions.SetMetaData('injail', 0)
    offline.Functions.Save()            -- required: offline changes are not saved automatically
    -- RSGCore.Player.SaveOffline(offline.PlayerData) is the same thing
end
```

Never edit an offline object for a character that is online: check `GetPlayerByCitizenId` first, or the online copy overwrites your change at its next save. For paying an offline character, prefer `QueuePayout`.

```lua
-- character deletion
RSGCore.Player.DeleteCharacter(src, citizenid)   -- player-initiated; drops the player if the character is not theirs
RSGCore.Player.ForceDeleteCharacter(citizenid)   -- admin; drops the owner if they are playing it
```

`CheckPlayerData(src|nil, playerData)` fills in missing defaults and calls `CreatePlayer(playerData, offline)`, which builds the Player object. They are used by `Login` and the offline getters; do not call them yourself, since calling them with a server id registers that player.

```lua
-- id generators (checked against the database, so they yield)
local citizenid = RSGCore.Player.CreateCitizenId()
local finger    = RSGCore.Player.CreateFingerId()
local wallet    = RSGCore.Player.CreateWalletId()       -- 'RSG-12345678'
local serial    = RSGCore.Player.CreateSerialNumber()
local account   = RSGCore.Functions.CreateAccountNumber()

-- inventory proxies (return nil if rsg-inventory is missing)
RSGCore.Player.SaveInventory(src)
RSGCore.Player.SaveOfflineInventory(offline.PlayerData)
local weight = RSGCore.Player.GetTotalWeight(Player.PlayerData.items)
local slots  = RSGCore.Player.GetSlotsByItem(Player.PlayerData.items, 'bread')      -- all slot numbers
local first  = RSGCore.Player.GetFirstSlotByItem(Player.PlayerData.items, 'bread')  -- one slot number
```

### Server: Player object extras

```lua
Player.Functions.SetMoney('bank', 250, 'myres-reset')   -- sets the balance; returns boolean
Player.Functions.RemoveRep('trapper', 5)                -- never goes below 0
Player.Functions.UpdatePlayerData()                     -- re-sync after editing PlayerData fields directly
Player.Functions.AddMethod('Hello', function() print('hi') end)
Player.Functions.AddField('myres', { visits = 0 })      -- Player.myres
Player.Functions.PersistStateBags()                     -- copy hunger/thirst/cleanliness/stress/health state bags into metadata
Player.Functions.InitializeStateBags()                  -- copy metadata back into the state bags
Player.Functions.Logout()
```

`AddMethod` and `AddField` apply to that session only; re-add them on `RSGCore:Server:PlayerLoaded`.

### Server: inventory, weight and items

```lua
if RSGCore.Functions.CanCarryItem(src, 'resource_wood', 5) then   -- weight check only, not free slots
    exports['rsg-inventory']:AddItem(src, 'resource_wood', 5, nil, nil, 'myres-chop')
end
RSGCore.Functions.ChangeWeight(src, 45000)   -- max carry weight (grams)
RSGCore.Functions.ChangeSlots(src, 30)
RSGCore.Functions.UseItem(src, 'bread')      -- proxy to rsg-inventory:UseItem
```

### Server: permissions, bans, whitelist and access

```lua
if RSGCore.Functions.IsValidPermission('mod') then        -- is it listed in RSGConfig.Server.Permissions?
    RSGCore.Functions.AddPermission(src, 'mod')           -- false for unknown levels
end
local perms = RSGCore.Functions.GetPermission(src)        -- e.g. { admin = true }

local banned, message = RSGCore.Functions.IsPlayerBanned(src)  -- yields; removes expired rows it matches
local allowed = RSGCore.Functions.IsWhitelisted(src)           -- yields; true when the whitelist is off
local mayJoin = RSGCore.Functions.CanJoinClosed(src)

if RSGCore.Functions.IsOptin(src) then end   -- admin who opted in to admin messages
RSGCore.Functions.ToggleOptin(src)           -- ignored for non-admins

RSGCore.Commands.Refresh(src)                -- re-send command suggestions after changing ACEs yourself
```

### Server: held payouts and playtime

```lua
-- pay a character whether or not they are online; they collect it with /claimmoney
local accepted = exports['rsg-core']:QueuePayout(citizenid, 'cash', 37.50, 'auction-sale')
if not accepted then
    -- bad citizenid, money type or amount: keep your own record, do not mark the sale as paid
end

CreateThread(function()   -- GetPlaytime yields
    local seconds = exports['rsg-core']:GetPlaytime(citizenid)
    print(('played %.1f hours'):format(seconds / 3600))
end)
```

### Server: world, buckets and entities

```lua
local pos = RSGCore.Functions.GetCoords(GetPlayerPed(src))       -- vector4
local obj, objDist = RSGCore.Functions.GetClosestObject(src)     -- -1, -1 when there is none
local veh, vehDist = RSGCore.Functions.GetClosestVehicle(src, vector3(pos.x, pos.y, pos.z))

CreateThread(function()
    -- vehtype is the native's vehicle type string, matching the model
    local cart = RSGCore.Functions.CreateVehicle(src, 'cart01', vehType, pos, false)
    if cart then RSGCore.Functions.SetEntityBucket(cart, 0) end
end)

local playerBuckets, entityBuckets = RSGCore.Functions.GetBucketObjects()
local inBucket = RSGCore.Functions.GetPlayersInBucket(5) or {}   -- returns false when no bucket was ever set
```

### Server: miscellaneous

```lua
local db = RSGCore.Functions.GetDatabaseInfo()          -- { exists = true, database = 'rsg' }
local version = exports['rsg-core']:GetCoreVersion()    -- pass a resource name to print who asked
local key = RSGCore.Functions.ClientCallbackKey(src, 12) -- 'src:12', internal key for pending client callbacks

RSGCore.Debug({ money = Player.PlayerData.money })      -- pretty-print to the server console
RSGCore.ShowError(GetCurrentResourceName(), 'config is missing')
RSGCore.ShowSuccess(GetCurrentResourceName(), 'ready')
```

### Server: shared data

All of these return `ok, reason` (see §29) and sync to clients.

```lua
exports['rsg-core']:AddItems({                                    -- all or nothing
    ore_copper = { name = 'ore_copper', label = 'Copper Ore', weight = 500, type = 'item', image = 'ore_copper.png', unique = false, useable = false, shouldClose = true, description = '' },
    ore_tin    = { name = 'ore_tin',    label = 'Tin Ore',    weight = 500, type = 'item', image = 'ore_tin.png',    unique = false, useable = false, shouldClose = true, description = '' },
})
local item = RSGCore.Shared.Items.ore_tin
item.weight = 400
exports['rsg-core']:UpdateItem('ore_tin', item)                   -- replaces the whole definition
exports['rsg-core']:SetItems({ ore_tin = item })                  -- add or overwrite
exports['rsg-core']:RemoveItem('ore_tin')                         -- removes the definition, not copies players hold

local ranch = { label = 'Ranch Hand', defaultDuty = true, grades = { ['0'] = { name = 'Worker', payment = 5 } } }
exports['rsg-core']:AddJob('ranchhand', ranch)
exports['rsg-core']:AddJobs({ miller = { label = 'Miller', defaultDuty = true, grades = { ['0'] = { name = 'Worker', payment = 5 } } } })
exports['rsg-core']:SetJobs({ ranchhand = ranch })
exports['rsg-core']:UpdateJob('ranchhand', ranch)
exports['rsg-core']:RemoveJob('ranchhand')

local riders = { label = 'Riders', grades = { ['0'] = { name = 'Member' } } }
exports['rsg-core']:AddGang('riders', riders)
exports['rsg-core']:AddGangs({ drifters = { label = 'Drifters', grades = { ['0'] = { name = 'Member' } } } })
exports['rsg-core']:SetGangs({ riders = riders })
exports['rsg-core']:UpdateGang('riders', riders)
exports['rsg-core']:RemoveGang('riders')
```

These changes live in memory: re-register them each time your resource starts. For jobs that must survive restarts and appear in `/jobadmin`, use `SaveJobDefinition` (§9).

### Shared utilities

```lua
RSGCore.Shared.Trim('  Arthur  ')          -- 'Arthur' (nil for nil)
local weapons = exports['rsg-core']:GetWeapons()
local cattleman = weapons[joaat('weapon_revolver_cattleman')]   -- { name, label, weapontype, ammotype, ... }
```

### Client: closest and nearby entities

```lua
local me = GetEntityCoords(PlayerPedId())
local at = RSGCore.Functions.GetCoords(PlayerPedId())            -- vector4

local players = RSGCore.Functions.GetPlayers()                   -- GetActivePlayers()
local close   = RSGCore.Functions.GetPlayersFromCoords(me, 10.0) -- includes yourself; default radius 5.0
local pid, pdist = RSGCore.Functions.GetClosestPlayer()          -- only searches within 5 m; -1, -1 if none

local peds     = RSGCore.Functions.GetPeds({ PlayerPedId() })    -- every ped except the ignore list
local vehicles = RSGCore.Functions.GetVehicles()
local objects  = RSGCore.Functions.GetObjects()
local veh, vd  = RSGCore.Functions.GetClosestVehicle(me)         -- -1, -1 if none
local obj, od  = RSGCore.Functions.GetClosestObject(me)

for _, v in ipairs(RSGCore.Functions.GetNearbyPeds(me, 5.0)) do print(v.ped, v.distance) end
for _, v in ipairs(RSGCore.Functions.GetNearbyVehicles(me, 10.0)) do print(v.vehicle, v.distance) end
for _, v in ipairs(RSGCore.Functions.GetNearbyObjects(me, 3.0)) do print(v.object, v.distance) end
```

### Client: loading assets

Each takes an optional timeout in ms (default 10000) and raises an error on timeout, so wrap in `pcall` if a failure is acceptable.

```lua
local set   = RSGCore.Functions.RequestAnimSet(setName)            -- alias LoadAnimSet
local asset = RSGCore.Functions.RequestNamedPtfxAsset(assetName)   -- alias LoadParticleDictionary
local ok    = pcall(RSGCore.Functions.RequestStreamedTextureDict, dictName, 5000)

CreateThread(function()
    RSGCore.Functions.PlayAnimOnPed(PlayerPedId(), animDict, animName, 8.0, -8.0, 3000, 1)
end)
```

`setName`, `assetName`, `dictName`, `animDict` and `animName` stand for real asset names: look them up in rdr3_discoveries rather than guessing.

### Client: entities, props, vehicles and bones

```lua
CreateThread(function()
    RSGCore.Functions.LookAtEntity(targetPed, 3000, 2.0)    -- turn to face it (yields, max 5 s)

    local prop = RSGCore.Functions.AttachProp(PlayerPedId(), propModel, boneId, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false)
    Wait(3000)
    DeleteEntity(prop)                                      -- you own the prop: delete it, also on resource stop

    RSGCore.Functions.SpawnVehicle('cart01', function(veh)
        Wait(10000)
        RSGCore.Functions.DeleteVehicle(veh)
    end, at, true, false)
end)

local bone, boneCoords, dist = RSGCore.Functions.GetClosestBone(entity, { { id = 0, name = 'root' } })
local d1 = RSGCore.Functions.GetBoneDistance(ped, 1, boneId)       -- type 1: ped bone id
local d2 = RSGCore.Functions.GetBoneDistance(entity, 2, boneName)  -- otherwise: bone name
```

### Client: ground, text and particles

```lua
local grounded = RSGCore.Functions.GetGroundZCoord(me)   -- vector3 on the ground, or the input if not found
local material, hitEntity, normal, hitCoords = RSGCore.Functions.GetGroundHash(PlayerPedId())

CreateThread(function()
    while showLabel do
        RSGCore.Functions.DrawText3D(grounded.x, grounded.y, grounded.z + 1.0, 'Dig here')  -- call every frame
        Wait(0)
    end
end)

-- particle helpers (deprecated, kept for compatibility). They yield for `duration` when looped.
CreateThread(function()
    RSGCore.Functions.StartParticleAtCoord(ptfxDict, ptfxName, true, me, vec3(0, 0, 0), 1.0, 1.0, nil, 3000)
    RSGCore.Functions.StartParticleOnEntity(ptfxDict, ptfxName, true, PlayerPedId(), nil, vec3(0, 0, 0), vec3(0, 0, 0), 1.0, 1.0, nil, nil, 3000)
end)
```

### Client: progress, keys, text UI and debug

```lua
CreateThread(function()
    local done = RSGCore.Functions.ProgressCircle({ duration = 4000, label = 'Searching', canCancel = true })
end)
if RSGCore.Functions.IsProgressActive() then
    RSGCore.Functions.CancelProgress()           -- the waiting call returns false
end

RSGCore.Functions.UnregisterKey('myres_open')    -- the key stops doing anything

exports['rsg-core']:DrawText('Press E to dig', 'left')
exports['rsg-core']:KeyPressed()                 -- hides the text UI (same as HideText)

RSGCore.Debug({ job = RSGCore.PlayerData.job })  -- F8 console
```

---

## 32. Architecture, Data Flow & Persistence

### Files

| Path | Role |
|---|---|
| `shared/config.lua`, `shared/multijob.lua` | `RSGConfig` |
| `shared/main.lua`, `items`, `jobs`, `gangs`, `vehicles`, `weapons`, `locations`, `keybinds` | `RSGShared` data and helpers |
| `shared/locale.lua`, `require.lua`, `table.lua` | Libraries other resources include with `@rsg-core/...` |
| `server/main.lua`, `functions.lua`, `player.lua` | Core object, server functions, paychecks, Player objects, saving |
| `server/events.lua` | Database setup, connection checks, callbacks, client-callable events |
| `server/moneyitems.lua` | Keeps money balances and money items in step |
| `server/commands.lua`, `management.lua` | Admin and player commands, bans, whitelist |
| `server/history.lua`, `payouts.lua` | Transactions, playtime, held payouts |
| `server/death.lua`, `cron.lua`, `debug.lua`, `versionchecker.lua` | Death events, scheduler, debug printing, update check |
| `server/exports.lua`, `api.lua` | Shared data API, exports (`api.lua` loads last) |
| `server/multijob/*` | Job registry, player job lists, admin menu, webhooks (`sv_config.lua` holds URLs, server only) |
| `client/main.lua`, `functions.lua`, `lib.lua`, `events.lua` | Client core, helpers, loaders, events |
| `client/drawtext.lua`, `progress.lua`, `prompts.lua`, `keys.lua` | UI helpers |
| `client/pvp.lua`, `death.lua`, `multijob.lua`, `api.lua` | PVP, death reports, job menus, exports |
| `client/zones.lua`, `points.lua` | Included by other resources, not run inside rsg-core |
| `html/` | Notifications, text UI, progress; `html/multijob/` the job menus |

Load order matters and is set in `fxmanifest.lua`. rsg-core also `provide`s `rsg-multijob`.

### Player data flow

1. `playerConnecting` checks bans, whitelist, closed state and duplicate license.
2. Character selection calls `RSGCore.Player.Login`. The row is loaded, defaults are applied and the Player object is stored in `RSGCore.Players[src]`.
3. The server is the source of truth. Changes go through `Player.Functions.*`, which sync `PlayerData` to the client. The client copy is for display only.
4. Logout or disconnect saves the character and removes the object.

### What is saved, and when

| Data | Written |
|---|---|
| Character row (`players`) | At login, every `UpdateInterval` minutes (staggered), on logout and disconnect, and on `Player.Functions.Save()` |
| Job lists and job definitions | When changed |
| Bans, whitelist, held payouts | When changed (a payout insert is not awaited) |
| Transactions | In batches every 5 s and when rsg-core stops; up to 5000 are buffered |
| Playtime | On unload and disconnect, every 5 minutes, and when rsg-core stops |
| `SetMethod`, `AddPlayerMethod`, runtime shared data | Memory only |

Stopping or restarting rsg-core on a live server does **not** save characters: changes since the last save are lost and players must reconnect. Restart the whole server instead (players are saved as they disconnect).

---

## 33. Internal Callbacks & Events

Listed so you can recognise them in logs and avoid name clashes. Do not call them from other resources unless §20 or §24 says so. Server handlers can be reached by any client, so each one checks the player, arguments and any permission or cooldown itself.

| Server callback | Arguments |
|---|---|
| `RSGCore:Server:SpawnVehicle` (needs `RSGConfig.Limits.SpawnPermission`) | `model, coords, warp` |
| `rsg-multijob:server:myJobs` | none |
| `rsg-multijob:server:admin:getJobs` / `rsg-multijob:server:admin:importCore` | none |
| `rsg-multijob:server:admin:saveJob` | `job, isNew` |
| `rsg-multijob:server:admin:deleteJob` / `rsg-multijob:server:admin:getHolders` | `name` / `job` |
| `rsg-multijob:server:admin:assignJob` / `rsg-multijob:server:admin:setGrade` / `rsg-multijob:server:admin:removeHolder` | `data` |

| Client callback | Arguments | Result |
|---|---|---|
| `RSGCore:Client:ConfirmKill` | `victimServerId` | boolean |

| Event | Side | Arguments |
|---|---|---|
| `RSGCore:Server:TriggerCallbackId` | server | `name, requestId, ...` |
| `RSGCore:Server:TriggerClientCallback` | server | `requestId, ...` (the answer) |
| `RSGCore:CallCommand` | server | `command, args` (permission is checked on the server) |
| `RSGCore:Server:ReportDeath` | server | `killerServerId, weaponHash` |
| `rsg-multijob:server:changeJob` / `deleteJob` | server | `job` (must be one the player holds) |
| `RSGCore:Client:TriggerCallbackId` / `TriggerClientCallback` | client | `requestId, ...` / `name, requestId, ...` |
| `RSGCore:Command:GoToMarker`, `RSGCore:Command:TeleportToPlayer`, `RSGCore:Command:TeleportToCoords`, `RSGCore:Command:ToggleNoClip`, `RSGCore:Command:SpawnVehicle`, `RSGCore:Command:DeleteVehicle`, `RSGCore:Command:ShowMe3D` | client | sent by the matching commands |
| `rsg-multijob:client:openmenu` | client | opens `/myjobs` |
| `rsg-multijob:client:openAdmin`, `refreshJobs` | client | sent by the server |
| `rsg-core:client:DrawText` / `rsg-core:client:ChangeText` | client | `text, position?` |
| `rsg-core:client:HideText` / `rsg-core:client:KeyPressed` / `rsg-core:client:CancelProgress` | client | none |

```lua
-- from a server script: show and hide the text UI on one player
TriggerClientEvent('rsg-core:client:DrawText', src, 'Waiting for the train', 'left')
TriggerClientEvent('rsg-core:client:HideText', src)
```

---

## 34. Server Owner How-tos

| Task | How |
|---|---|
| Install | Follow the README. Tables are created on first start |
| Install tables by hand | Set `RSGConfig.AutoDatabase = false`, import `install.sql` |
| Change the language | `setr rsg:locale de` in `server.cfg`, restart |
| Make yourself admin | Add the ACE lines in §12 to `server.cfg` |
| Add or edit a job | `/jobadmin` in game. Editing `shared/jobs.lua` after the first start does not change jobs already in the database (use the admin menu's import for new ones) |
| Add an item or gang | Edit `shared/items.lua` / `shared/gangs.lua`, restart the server |
| Set up job logs | Put webhook URLs in `server/multijob/sv_config.lua`. Keep that file private |
| Run a whitelist | `RSGConfig.Server.Whitelist = true`, then `/whitelist add <id, citizenid or license:hex>` (works from the console) |
| Ban and unban | `/ban`, `/offlineban`, `/banlist`, `/unban` (§13) |
| Close for maintenance | `/closeserver <reason>`, then `/openserver` |
| Trace a money report | `/transactions <id or citizenid> 30`; query `rsg_transactions` for more |
| Keep history longer or forever | `RSGConfig.Transactions.RetentionDays` (`0` keeps everything; watch table size) |
| Pay wages from society funds | `RSGConfig.Money.PayCheckSociety` is `true` by default and applies when rsg-society runs; set it to `false` to pay wages without society accounts |
| Bind a key for `/myjobs` | It is unbound by default; set `RSGConfig.MultiJob.Key` or let players bind it in the game's key settings |
| Update | Back up the database, replace the resource, keep your config and `sv_config.lua` edits, read `CHANGELOG.md`, restart the server |

---

## 35. Troubleshooting

| Symptom | Likely cause and fix |
|---|---|
| Red database error at start | Check oxmysql starts first and the connection string; or install `install.sql` manually |
| `RSGCore.Functions.X` is nil in your resource | You hold an old copy of the core object, or rsg-core is outdated. Fetch it after rsg-core has started |
| `export skipped` warning | A file failed to load earlier: fix the first error in the console |
| Text shows as a locale key | The key is missing from your `locales/*.json`, or `files { 'locales/*.json' }` is not in your manifest |
| Callback returns `nil` | It timed out, the name is misspelt, or the handler errored before calling `cb` |
| Money item missing after a reward | Inventory was full: the player runs `/claimmoney` |
| `AddMoney` returns `false` | Unknown money type, negative or non-numeric amount, or fractional gold |
| Cannot join: whitelist | The console prints the refused license; `whitelist add <license>` |
| Jobs missing or reset to unemployed | The job is not in `multijob_jobs`; check the start-up warnings and `/jobadmin` |
| Old `rsg-multijob` errors | Remove that resource; rsg-core provides it |
| Kills report no killer | Expected for kills from a horse or wagon, with PVP off, out of range, or when the killer does not confirm in time |
| No `/transactions` rows | `Transactions.Enabled` is false, or the rows are older than `RetentionDays` |
| Progress bar returns `false` at once | Another one is running, `duration` is missing, or the ped is dead, ragdolled, swimming, falling or cuffed without the matching `allow*` option |
| Discord job logs missing | URL blank or event disabled in `sv_config.lua`; the console shows webhook errors |

---

Support: https://rexshack.tebex.store
