<img width="2288" height="464" alt="rsg_banner" src="https://github.com/user-attachments/assets/8c1b5a18-9a1f-4308-af78-8c7b43a1d030" />

# rsg-core

The core framework for RSG RedM servers: players, characters, money, jobs, gangs, permissions, commands, callbacks and shared data.

Documentation: https://rsgcore.com/docs

## Dependencies

- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_lib](https://github.com/overextended/ox_lib) (notifications, text UI, locales, callbacks)
- Optional: `rsg-inventory`, `rsg-banking` (society paychecks), `rsg-multijob`, `rsg-log`

## Installation

1. Import the SQL for `players` and `bans` (the `weight` / `slots` columns are added automatically if missing).
2. Ensure the resources in this order in `server.cfg`:
   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure rsg-core
   ```
3. Set the server language (see below) and review `config.lua`.

## Language / Locales

Translations live in `locales/*.json` and are loaded by ox_lib.
Supported languages: `en`, `de`, `el`, `es`, `fr`, `ja`, `nl`, `pl`, `pt-br`, `ro`.

```cfg
setr ox:locale en
```

To add a language, copy `locales/en.json` to `locales/<code>.json` and translate the values. Keep `%s` placeholders in the same order.

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

## Usage

```lua
local RSGCore = exports['rsg-core']:GetCoreObject()

-- server
local Player = RSGCore.Functions.GetPlayer(source)
Player.Functions.AddMoney('cash', 10, 'reason')

-- client: server callbacks (concurrent calls to the same callback are safe)
RSGCore.Functions.TriggerCallback('my:callback', function(result) end, arg1)
```

Runtime shared-data exports (`AddJob(s)`, `UpdateJob`, `RemoveJob`, `AddItem(s)`, `UpdateItem`, `RemoveItem`, `AddGang(s)`, `UpdateGang`, `RemoveGang`) sync to all clients, including players who join later. The batch versions are all-or-nothing.

## Security notes

- Money and metadata are only changed on the server. Clients can only set the metadata keys listed in `RSGConfig.ClientWritableMetadata`, and the values are clamped.
- Client-requested saves are rate limited, and character login/deletion is checked against the player's license.
- The server vehicle spawn callback only allows models in `RSGShared.Vehicles`.

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
