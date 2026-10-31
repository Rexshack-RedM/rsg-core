<img width="2288" height="464" alt="rsg_banner" src="https://github.com/user-attachments/assets/8c1b5a18-9a1f-4308-af78-8c7b43a1d030" />

# rsg-core

The core framework for RSG RedM servers: players, characters, money, jobs (with built-in multi-job), gangs, permissions, commands, callbacks, notifications and shared data.

Documentation: https://rsgcore.com/docs

## Dependencies

- [oxmysql](https://github.com/overextended/oxmysql)
- Optional: `rsg-inventory`, `rsg-banking` (paychecks go to the home branch), `rsg-log`

rsg-core no longer needs ox_lib. Notifications, callbacks, locales, text UI and the model/anim loaders are built in. Other resources may still need ox_lib for their own locales.

## Installation

1. Import the SQL for `players` and `bans`. The `weight` / `slots` columns and the multi-job tables (`multijob_jobs`, `player_jobs`) are created automatically.
2. Remove `rsg-multijob` if you had it: it is built in now, and its tables are reused as they are.
3. Ensure the resources in this order in `server.cfg`:
   ```cfg
   ensure oxmysql
   ensure rsg-core
   ```
4. Set the language (below) and review `shared/config.lua` and `shared/multijob.lua`. Put Discord webhook URLs in `server/multijob/sv_config.lua` (server only).

## Language / Locales

Translations live in `locales/*.json`. Supported languages: `en`, `de`, `el`, `es`, `fr`, `ja`, `nl`, `pl`, `pt-br`, `ro`.

```cfg
setr rsg:locale en   # falls back to ox:locale, then en
```

Missing keys fall back to English. To add a language, copy `locales/en.json` to `locales/<code>.json` and translate the values, keeping `%s` placeholders in the same order.

## Permissions

Permission levels are set in `RSGConfig.Server.Permissions` (`god`, `developer`, `headadmin`, `admin`, `mod`, `helper`) and granted with aces/principals:

```cfg
add_principal identifier.license:xxxxxxxx rsgcore.god
```

`/addpermission` and `/removepermission` only accept levels listed in the config.

## Commands

| Command | Permission | Description |
|---|---|---|
| `/tp [id \| x y z \| location]` | admin | Teleport to a player, coords or a named location |
| `/tpm` | admin | Teleport to waypoint |
| `/noclip` | admin | Toggle noclip (txAdmin) |
| `/togglepvp` | admin | Toggle PVP for everyone |
| `/addpermission [id] [level]` | god | Give a permission level |
| `/removepermission [id] [level]` | god | Remove a permission level |
| `/openserver` / `/closeserver [reason]` | admin | Open / close the server to non-whitelisted players |
| `/vehicle [model]` `/dv` `/dvall` `/dvp` `/dvo` | admin | Spawn / delete vehicles, peds, objects |
| `/givemoney [id] [type] [amount]` | admin | Add money |
| `/setmoney [id] [type] [amount]` | admin | Set money |
| `/setjob [id] [job] [grade]` | admin | Set job (job and grade are validated) |
| `/setgang [id] [gang] [grade]` | admin | Set gang (gang and grade are validated) |
| `/job` `/gang` `/id` `/cid` | user | Show your job, gang, server id, citizen id |
| `/ooc [msg]` `/me [msg]` | user | Proximity OOC chat / 3D emote text |
| `/myjobs` | user | Open your jobs menu (switch / leave jobs, toggle duty) |
| `/jobadmin` | admin | Create, edit and delete server jobs, and give players jobs / set their grade (Employees tab) |
| `/removejob [id \| citizenid] [job]` | admin | Remove a job from a player's job list |

## Usage

```lua
local RSGCore = exports['rsg-core']:GetCoreObject()
```

### Callbacks
```lua
-- server
RSGCore.Functions.CreateCallback('my:server:getData', function(source, cb, arg)
    cb({ ok = true })
end)

-- client (async)
RSGCore.Functions.TriggerCallback('my:server:getData', function(result) end, arg)

-- client (await, inside a thread/event). Timeout in ms, default 10000; returns nil on timeout
local result = RSGCore.Functions.AwaitCallback('my:server:getData', 5000, arg)
```
The server can ask a client with `CreateClientCallback` (client) and `TriggerClientCallback` / `AwaitClientCallback(name, source, timeout, ...)` (server).

### Notifications
```lua
-- client
RSGCore.Functions.Notify({ title = 'Title', description = 'Message', type = 'success', duration = 5000, icon = 'fa-solid fa-horse' })
-- server
TriggerClientEvent('RSGCore:Client:Notify', source, { title = 'Title', description = 'Message', type = 'error' })
```
Types: `success`, `error`, `warning`, `inform`. Optional `position` and `id` (a notification with the same id replaces the old one). Defaults are in `RSGConfig.Notify`. The older `Notify(text, type, duration)` form and the `RSGCore:Notify` event still work, and `ox_lib:notify` is picked up once ox_lib is stopped.

### Multi-job
Players can hold several jobs (`RSGConfig.MultiJob.MaxJobs`) and switch with `/myjobs`. Job definitions live in the `multijob_jobs` table and are managed with `/jobadmin`. Its **Employees** tab lists everyone holding the selected job (online and offline), and lets admins give the job to a player (server ID or citizen ID) at any grade, change grades and remove holders.

Server API (`RSGCore.Functions.*` and `exports['rsg-core']:*`, `id` = server id or citizenid):

| Function | Returns |
|---|---|
| `AddPlayerJob(id, job, grade, bypassMax?)` | `ok, reason` |
| `RemovePlayerJob(id, job)` | `ok, reason` |
| `GetPlayerJobs(id)` | `{ job, salary, jobLabel, gradeLabel, grade, icon }[]` |
| `HasPlayerJob(id, job)` | `held, grade` |
| `CanTakePlayerJob(id, job, bypassMax?)` | `ok, reason` |
| `GetPlayerJobCount(id)` | `count, max` |
| `GetJobDefinition(name)` / `GetJobDefinitions()` | job definition(s) |

`AddJob` / `UpdateJob` / `RemoveJob` on rsg-core are for job *definitions*, not player jobs. Old `exports['rsg-multijob']:*` calls and `rsg-multijob:*` events still work because rsg-core `provide`s rsg-multijob.

### Progress bar / circle
Replaces `lib.progressBar`, `lib.progressCircle`, `lib.progressActive` and `lib.cancelProgress` with the same option table, so migrating is a rename. It blocks (call it from a thread) and returns `true` when finished, `false` when cancelled or interrupted.
```lua
local done = RSGCore.Functions.ProgressBar({      -- or exports['rsg-core']:ProgressBar({...})
    duration = 5000,
    label = locale('searching'),
    canCancel = true,                              -- X by default (RSGConfig.Progress.CancelKey)
    useWhileDead = false,                          -- also: allowRagdoll, allowSwimming, allowFalling, allowCuffed, allowMounted
    disable = { move = true, sprint = true, mount = true, combat = true, mouse = false },
    anim = { scenario = 'WORLD_HUMAN_CROUCH_INSPECT' },   -- or { dict, clip, flag, blendIn, blendOut, playbackRate, lockX/Y/Z }
    prop = { model = 'p_bottle01x', bone = 'SKEL_R_Hand', pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }, -- or a list of props
})
```
- `RSGCore.Functions.ProgressCircle(data)` takes the same options plus `position = 'middle' | 'bottom'`.
- `RSGCore.Functions.IsProgressActive()` / `exports['rsg-core']:IsProgressActive()`.
- `RSGCore.Functions.CancelProgress()` / `exports['rsg-core']:CancelProgress()` / `TriggerClientEvent('rsg-core:client:CancelProgress', src)`.
- Only one progress runs at a time (a second call returns `false`). It is cancelled automatically if the calling resource stops.
- Props and anims are cleaned up on finish and on cancel. The cancel hint text is the `info.progress_cancel` locale key.

### Other client helpers
- `RSGCore.Functions.RequestModel / RequestAnimDict / RequestAnimSet / RequestNamedPtfxAsset(name, timeout?)` (also exports)
- `RSGCore.Functions.PlayAnimOnPed(ped, dict, name, blendIn, blendOut, duration, flag, ...)`
- `exports['rsg-core']:DrawText(text, 'left' | 'right' | 'top')`, `HideText()`, `IsTextShown()`

Runtime shared-data exports (`AddJob(s)`, `UpdateJob`, `RemoveJob`, `AddItem(s)`, `UpdateItem`, `RemoveItem`, `AddGang(s)`, `UpdateGang`, `RemoveGang`) sync to all clients, including players who join later. The batch versions are all-or-nothing.

## Security notes

- Money and metadata are only changed on the server. Clients can only set the metadata keys listed in `RSGConfig.ClientWritableMetadata`, and the values are clamped.
- Client-requested saves, duty toggles, `/me` and job menu actions are rate limited. Character login/deletion is checked against the player's license.
- The server vehicle spawn callback only allows models in `RSGShared.Vehicles`, only near the player, and at most once every 5 seconds.
- `SetJob` / `SetGang` refuse grades that don't exist.
- Notification and text UI content is always rendered as plain text.

## Support

Support: https://buymeacoffee.com/rexshack

## Credits

Thanks to Kakarot and the QB Team for the original work: https://discord.gg/qbcore

## License

    RSG RedM Framework
    Copyright (C) 2015-2022 ESX (Jérémie N'gadi), Joshua Eger

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>
