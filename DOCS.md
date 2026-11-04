# rsg-core Developer Documentation

> Version **3.1.2** · RedM · Lua 5.4 · Depends only on `oxmysql`
> rsg-core no longer requires **ox_lib**: notifications, callbacks, progress bars, text UI, prompts, locales, `require` and asset loaders are all built in.

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
- Compatible with ox_lib locale files.
- Server standard languages: `en, de, el, es, fr, ja, nl, pl, pt-br, ro`.

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
| `PrepForSQL(source, data, pattern)` | Validates a string against a Lua pattern; kicks on fail |
| `GetDatabaseInfo()` | `{ exists, database }` |
| `RSGCore.Debug(tbl, indent?)` | Pretty-prints to server console |
| `RSGCore.ShowError(resource, msg)` / `ShowSuccess(resource, msg)` | Coloured console output |
| `RSGCore.Functions.CreateAccountNumber()` | |
| `RSGCore.Player.CreateCitizenId()` / `CreateFingerId()` / `CreateWalletId()` / `CreateSerialNumber()` | Unique id generators |

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

### Player lifecycle (`RSGCore.Player`)

`Login(source, citizenid?, newData?)`, `Logout(source)`, `Save(source)`, `SaveOffline(PlayerData)`, `GetOfflinePlayer(citizenid)`, `GetOfflinePlayerByLicense(license)`, `DeleteCharacter(source, citizenid)`, `ForceDeleteCharacter(citizenid)`, `SaveInventory(source)`, `GetTotalWeight(items)`, `GetSlotsByItem(items, name)`, `GetFirstSlotByItem(items, name)`.

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

### Gangs

Defined in `shared/gangs.lua`; set with `Player.Functions.SetGang(gang, grade)` or `/setgang`.

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
| `/tp [id \| x y z \| location]`, `/tpm` | admin | Teleport |
| `/noclip` | admin | |
| `/togglepvp` | admin | |
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

Types: `primary | inform | info | success | error | warning | warn`. Extra table keys: `id`, `position`, `sound` (bool). Positions: `top-right, top-left, top, bottom-right, bottom-left, bottom, center-right, center-left`. `ox_lib:notify` events are also caught for compatibility.

---

## 16. Progress Bar / Circle

Same option table as ox_lib — migrating is a rename. Must be called from a thread (it yields).

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
| `RSGCore:Server:UpdateObject` | — |

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

Typical client pattern:

```lua
local PlayerData = {}
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function() PlayerData = RSGCore.Functions.GetPlayerData() end)
RegisterNetEvent('RSGCore:Player:SetPlayerData', function(val) PlayerData = val end)
RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function() PlayerData = {} end)
```

### Client → server events you may call

| Event | Notes |
|---|---|
| `RSGCore:Server:SetMetaData (key, value)` | **Only** keys in `RSGConfig.ClientWritableMetadata` (hunger, thirst, cleanliness, stress, health, armor) |
| `RSGCore:ToggleDuty` | |
| `RSGCore:UpdatePlayer` | Saves current stats |

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

---

## 23. Configuration Reference

`shared/config.lua` (`RSGConfig`):

| Key | Default | |
|---|---|---|
| `DefaultSpawn` | `vector4(-1035.71, -2731.87, 12.86, 0.0)` | |
| `UpdateInterval` | `5` | Minutes between auto-saves |
| `HidePlayerNames` | `true` | |
| `Money.MoneyTypes` | `cash=50, gold=0, bank=0, bloodmoney=0` | |
| `Money.DontAllowMinus` | `cash, gold, bloodmoney, bank` | |
| `Money.MinusLimit` | `-5000` | |
| `Money.PayCheckTimeOut` | `10` | Minutes |
| `Money.EnableMoneyItems` | `true` | |
| `Gold.EnableGoldItems` | `false` | |
| `Player.PlayerDefaults` | — | Defaults for new characters |
| `Player.RevealMap` | `true` | |
| `Server.Closed / Whitelist / PVP / CheckDuplicateLicense` | | |
| `Server.Permissions` | god…helper | |
| `PromptDistance` | `1.5` | |
| `Notify` | Position, Duration, MaxVisible, Sound | |
| `Progress` | CancelKey `0x8CC9CD42` (X), CancelLabel | |
| `ClientWritableMetadata` | hunger, thirst, cleanliness, stress, health, armor | |

`shared/multijob.lua` (`RSGConfig.MultiJob`): `MaxJobs = 3`, `JobSwitchCooldown = 3000`, `Admin = { Command = 'jobadmin', Permission = 'admin' }`, `JobIcons`.
`server/multijob/sv_config.lua`: Discord webhooks per job event (server-only).

### Database

- Manual import: `players`, `bans`.
- Created automatically: `weight`/`slots` columns, `multijob_jobs`, `player_jobs`.

---

## 24. Exports Reference

**Shared:** `GetCoreObject`, `GetWeapons`

**Server:** `SetMethod`, `SetField`, `GetCoreVersion`, `ExploitBan(playerId, origin)`, `AddItem(s)`, `UpdateItem`, `RemoveItem`, `AddJob(s)`, `UpdateJob`, `RemoveJob`, `AddGang(s)`, `UpdateGang`, `RemoveGang`, `AddPlayerJob`, `RemovePlayerJob`, `GetPlayerJobs`, `HasPlayerJob`, `CanTakePlayerJob`, `GetPlayerJobCount`, `GetJobDefinition`, `GetJobDefinitions`

**Client:** `Notify`, `ProgressBar`, `ProgressCircle`, `IsProgressActive`, `CancelProgress`, `DrawText`, `ChangeText`, `HideText`, `KeyPressed`, `IsTextShown`, `createPrompt`, `createPromptGroup`, `getPrompt`, `getPromptGroup`, `deletePrompt`, `deletePromptGroup`, `RequestModel`, `RequestAnimDict`, `RequestAnimSet`, `RequestNamedPtfxAsset`, `GenerateCSRFToken`

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
| `'@ox_lib/init.lua'` | remove |

---

## 26. Security Notes

- **Never trust the client.** Do money, items and job checks on the server inside the event/callback, using `source`.
- Clients can only set metadata keys whitelisted in `RSGConfig.ClientWritableMetadata`.
- Use `exports['rsg-core']:ExploitBan(source, 'reason')` for confirmed exploit attempts.
- Protect NUI callbacks with `GenerateCSRFToken()`; mismatches trigger `RSGCore:Server:KickCSRF`.
- `RSGCore:CallCommand` checks command permissions server-side.
- `PrepForSQL` validates strings before raw SQL; always prefer parameterised `MySQL` queries.
- Multi-job admin callbacks are permission- and rate-limited.

## ox_lib replacements: zones, raycast, nearby entities, table helpers

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
Each zone has `id`, `coords`, `distance` (to the player, updated every 300 ms) and `insideZone`. Extra fields you pass are kept. The global `Zones` (id → zone) and `lib.zones` are set for ox_lib-style code. `inside` and debug drawing run per frame only while needed.

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
