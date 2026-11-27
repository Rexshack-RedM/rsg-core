# Changelog

All notable changes to rsg-core. Newest first.

## 3.7.0

### Added
- **Held payouts.** Money that cannot be delivered as a money item (full inventory, including change) is stored in `rsg_held_payouts` and collected with `/claimmoney`. Players are reminded after loading in. New export `QueuePayout(citizenid, moneytype, amount, reason)` also pays offline characters.
- **Transaction history** in `rsg_transactions`, with `/transactions` and `RSGConfig.Transactions`.
- **Ban commands:** `/ban`, `/offlineban`, `/unban`, `/banlist`.
- **In-game whitelist:** `/whitelist add|remove|list`, stored in `rsg_whitelist`. Used together with the ace permission when the whitelist is on. Refused players are printed to the console with their license.
- **Playtime** in `rsg_playtime`, with `/playtime`, export `GetPlaytime(citizenid)` and `RSGConfig.Playtime`.
- `/myjobs`: on-duty count for each job, next paycheck countdown, and a rebindable key (`RSGConfig.MultiJob.Key`, unbound by default).
- 40 new locale keys in all 11 languages.

### Fixed
- Cash, change and other money items are no longer lost when the inventory is full.
- Lowering or removing a grade in `/jobadmin` also updates offline holders.
- Two job additions at the same moment can no longer exceed the job limit.
- Prompts can be added or removed safely while another prompt is firing.
- The two default grade names in the job editor are translated.

### Changed
- `GenerateCSRFToken` now allows several pending single-use tokens, each valid for 30 seconds. It is not a security boundary: the server must still validate every request.

### Final review
- Fixed: an extremely large `/ban` duration could overflow and create an already expired ban; it now caps at permanent.
- Fixed: `GetOfflinePlayerByLicense` failed for licenses with more than one character; it now returns the most recently saved one.
- Fixed: spending an exact balance could fail because of floating point rounding.
- Fixed: a save error on disconnect could leave the player stuck in the online player list.
- Security: the money item unload and disconnect handlers now ignore client-triggered calls.
- Fixed: points and zones can be created or removed from inside their own callbacks.
- `/myjobs` and `/jobadmin` close when the character unloads, and a failed admin menu load now shows a message.
- Job webhooks retry when Discord rate limits them (HTTP 429).
- Removed the unused `RSGConfig.Server.Uptime` setting and two unused locale keys.
- Docs: added function examples, full database schema, death settings, architecture and persistence, internal events, server owner how-tos and troubleshooting; replaced the outdated auto-generated reference.

## 3.6.0

### Security
- Money item sync now starts on the server when a character loads. It used to wait for the client's `OnPlayerLoaded` event, so a modified client could keep it off and duplicate money.
- The `RSGCore:Server:SpawnVehicle` callback now requires `RSGConfig.Limits.SpawnPermission` (default `admin`).

### Fixed
- Money items are updated before player data is sent and logged, fixing wrong HUD popups and log balances. `RSGCore:Server:OnMoneyChange` now fires before the client event.
- Two client callbacks with the same name running at once no longer leave the first waiting forever. Pending requests are dropped when the player leaves.
- The periodic save and paycheck loops work on a copy of the player list.
- The database column and table checks use `DATABASE()` instead of reading the database name from the connection string.
- `/me` and `/ooc` respect routing buckets; a new `/me` message replaces the old one; empty messages are rejected.
- Missing-argument messages work from the console, as do multi-job messages. `/removejob` ignores job name case.
- `/setmoney` is written to the admin log. Long names no longer exceed the `bans.name` column.
- `/myjobs` no longer opens over the job admin menu, and shows an error on timeout instead of an empty list.
- Routing bucket records are cleared when an entity is removed, and `CanCarryItem` checks that rsg-inventory is running.
- The default unemployed job has fallbacks when its text or type is missing.

### Removed (check third-party scripts)
- Events `RSGCore:Server:CloseServer`, `RSGCore:Server:OpenServer` (use the commands), `RSGCore:Server:TriggerCallback`, `RSGCore:Client:TriggerCallback`, `RSGCore:UpdatePlayer` and `RSGCore:Player:UpdatePlayerData`.
- Config `RSGConfig.ServerSideSave` (server saving is always on) and `RSGConfig.Limits.SaveCooldown`.
- `client/loops.lua`, dead code in the job admin script and three unused locale keys.

### Changed
- Internal client-callback events now carry a request id.
- New locale key `menu_load_failed` in all 11 languages.

## 3.5.2

### Fixed
- The locale loader now falls back to the `ox:locale` convar when `rsg:locale` is not set (then `en`), matching the other RSG resources, so a server that only sets `ox:locale` no longer gets a mix of languages.

## 3.5.1

### Removed
- The `rsg-bossmenu:server:FireEmployee` net event, its boss check and the `EmployeeFired` job webhook. rsg-society replaces rsg-bossmenu and removes a fired employee's job directly with the `RemovePlayerJob` export, so nothing sends this event any more.

## 3.5.0

### Added
- **Rebindable keys:** new client function and export `RegisterKey(name, description, defaultKey, onPress, onRelease, opts)` and `UnregisterKey(name)` (new file `client/keys.lua`). Wraps `RegisterKeyMapping` with a `+`/`-` command pair, login and NUI-focus gating, an optional `canTrigger` check and automatic cleanup when the owning resource stops.

## 3.4.0

### Added
- Death and kill events. The victim's client reports a death; the server checks that the killer is online, in range, in the same routing bucket and that PVP is on, then asks the killer's client to confirm. New server-only events `RSGCore:Server:OnPlayerDeath (victim, killer|nil, data)` and `RSGCore:Server:OnPlayerKilled (victim, killer, data)`, local client event `RSGCore:Client:OnPlayerDied (killerServerId|nil, weaponHash)`, export `GetLastDeath(src)` and `RSGConfig.Death`.

## 3.3.1

### Fixed
- `players.outlawstatus` column is now part of the schema and added automatically to existing databases when missing (fixes `Unknown column 'outlawstatus'` errors from rsg-hud and others).

### Documentation
- `DOCS.md`: added a generated technical reference (dependencies, database, configuration, exports, callbacks, events, commands, items, locales) with code examples, read straight from the source.

## 3.3.0

### API
- New server exports so other resources don't need the whole core object: `GetPlayer`, `GetPlayerByCitizenId`, `GetOfflinePlayerByCitizenId`, `GetPlayerByLicense`, `GetPlayerByAccount`, `GetPlayerByCharInfo`, `GetPlayers`, `GetRSGPlayers`, `GetPlayersOnDuty`, `GetDutyCount`, `GetIdentifier`, `GetSource`, `HasPermission`, `AddPermission`, `RemovePermission`, `GetPermission`, `IsValidPermission`, `IsWhitelisted`, `IsPlayerBanned`, `CanJoinClosed`, `SetServerClosed`, `Kick`, `CreateUseableItem`, `CanUseItem`, `UseItem`, `Notify`, bucket helpers, `AddPlayerMethod`, `AddPlayerField`.
- New nil-safe server helpers by server id: `AddMoney`, `RemoveMoney`, `GetMoney`, `GetMetaData`, `SetMetaData`, `GetJob`, `GetGang`.
- New `AdminLog(src, action, details?)` for writing to the same audit trail as the core admin commands.
- New bulk shared-data exports `SetJobs`, `SetItems`, `SetGangs` (add or overwrite many entries with one client broadcast).
- New client exports: `GetPlayerData`, `HasItem`, `GetCoords`, `GetClosest*`, `GetPlayersFromCoords`, `PlayAnim`, `LookAtEntity`, `SpawnVehicle`, `DeleteVehicle`, `GetGroundZCoord`, `GetCardinalDirection`, `GetCurrentTime`, `TriggerCallback`, `AwaitCallback`, `CreateClientCallback`.
- DOCS.md section 24 rewritten as a full export reference with signatures, return values and examples.

### Added
- `RSGConfig.AutoDatabase`: `players` and `bans` are created automatically. `install.sql` is provided for manual installs.
- `RSGConfig.Limits`: save, duty, spawn, `/me` and `/ooc` cooldowns, spawn distance and OOC range are configurable.
- `RSGConfig.ServerSideSave`: the server saves every player each `UpdateInterval` minutes (staggered). `RSGConfig.LogSaves` controls the per-save console line (off by default).
- `RSGConfig.Ban`: bans can also match Discord (default on) and IP.
- `RSGConfig.AdminLogChannel`: admin commands (`/dvall`, `/dvp`, `/dvo`, `/setjob`, `/setgang`, `/givemoney`, `/addpermission`, `/removepermission`, `/openserver`, `/closeserver`, `/togglepvp`, and the open/close events) are audit logged.
- `RSGConfig.AllowPushToTalkWhileOpen` / `PushToTalkControls`: push-to-talk keeps working while `/myjobs` and `/jobadmin` are open.
- Localized notification labels (`notify_label_*`).
- Font Awesome bundled in `html/vendor/fontawesome`; the UI no longer needs the cdnjs CDN.
- `/tp x y` (no z) probes for ground. `/tp` and `/tpm` share one safe-teleport routine (collision wait, heading, mounts and vehicles move with the player).

### Fixed
- `math.round` (does not exist) in money item handling replaced with integer-cent maths.
- Ban check read only the first ban row for a license; it now checks all rows and uses the longest active ban.
- Players joining before job definitions loaded were reset to unemployed; the join gate now waits for the job registry.
- Large zones never triggered because the proximity cut-off ignored zone size.
- A progress bar could stay locked as active after a script error.
- Duplicate `playerDropped` handler and missing `lastSpawn` cleanup removed.
- CSRF check no longer kicks on a duplicate callback with no token pending, and needs two wrong tokens before kicking.
- Closed-server joins and closing the server now use the same permission check (`CanJoinClosed`).
- A full inventory no longer silently loses money items: the failure is logged and the player is notified.
- `player_jobs` could contain duplicate rows; duplicates are removed and a unique key `uniq_player_job (citizenid, job)` is added.

### Security
- `RSGCore:CallCommand` checks command permissions and only forwards up to 20 string/number arguments.
- `/ooc` has a cooldown and a 255 character cap.
- Prompts created by a resource are removed when that resource stops.

### Performance
- Job registration at start is one shared-data update instead of one per job.
- The periodic save no longer relies on every client firing an event.
- Progress state checks run every 100 ms instead of every frame.

### Removed
- Unused locale keys (`error.company_too_poor`, `error.connecting_database_timeout`, `error.item_not_exist`, `error.too_heavy`, `error.tp_error`).
- Untranslated English leftovers in the `de`, `el`, `es`, `fr`, `ja`, `nl`, `pl` and `ro` locales are now fully translated.

### Upgrade notes
- Back up `player_jobs` before first start: duplicate rows are deleted (the oldest per player and job is kept).
- To keep the old behaviour of client-triggered saves, set `RSGConfig.ServerSideSave = false`.
- To install the database manually, set `RSGConfig.AutoDatabase = false` and import `install.sql`.
