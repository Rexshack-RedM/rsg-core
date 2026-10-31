-----------------------------------------------------------------------
-- Discord MultiJobWebhook Logging for rsg-core multijob
--
-- Exposes a global `MultiJobWebhook` table so server/server.lua (and anything
-- else in this resource) can log an event without worrying about
-- queuing, rate limits, or missing/blank URLs.
-----------------------------------------------------------------------


MultiJobWebhook = {}

-- Simple FIFO queue + processor so a burst of events (e.g. an admin
-- mass-removing jobs) can't spam Discord's rate limit or fire dozens of
-- concurrent HTTP requests at once.
local queue = {}
local processing = false

local function isValidUrl(url)
    return type(url) == 'string' and url ~= '' and url:find('^https?://')
end

local function processQueue()
    if processing then return end
    processing = true

    CreateThread(function()
        while #queue > 0 do
            local job = table.remove(queue, 1)

            PerformHttpRequest(job.url, function(statusCode, _, _)
                if statusCode ~= 200 and statusCode ~= 204 then
                    print(('[rsg-core multijob] WARNING: Discord webhook "%s" returned HTTP %s'):format(job.eventName, tostring(statusCode)))
                end
            end, 'POST', json.encode(job.payload), { ['Content-Type'] = 'application/json' })

            -- Discord's webhook rate limit is ~5 requests / 2s per webhook,
            -- so a small delay between sends keeps this resource well clear of it.
            Wait(300)
        end

        processing = false
    end)
end

-- Builds and queues an embed for the given event.
--
-- eventName : string   -- must match a key under MultiJobWebhookConfig.Events
-- data      : table {
--     description = string,        -- optional, main embed body text
--     fields      = { { name, value, inline } , ... }, -- optional
--     title       = string,        -- optional, overrides the configured title
--     color       = number,        -- optional, overrides the configured color
-- }
function MultiJobWebhook.Send(eventName, data)
    if not MultiJobWebhookConfig or not MultiJobWebhookConfig.Enabled then return end

    local eventCfg = MultiJobWebhookConfig.Events and MultiJobWebhookConfig.Events[eventName]
    if not eventCfg then
        print(('[rsg-core multijob] WARNING: MultiJobWebhook.Send called with unknown event "%s"'):format(tostring(eventName)))
        return
    end

    if not eventCfg.Enabled then return end

    data = data or {}

    local url = isValidUrl(eventCfg.URL) and eventCfg.URL or MultiJobWebhookConfig.DefaultURL
    if not isValidUrl(url) then
        -- No URL configured anywhere for this event; nothing to send to.
        return
    end

    local embed = {
        title = data.title or eventCfg.Title,
        description = data.description,
        color = data.color or eventCfg.Color or MultiJobWebhookConfig.DefaultColor,
        fields = data.fields or {},
        footer = {
            text = MultiJobWebhookConfig.FooterText or 'rsg-core multijob',
            icon_url = MultiJobWebhookConfig.FooterIcon ~= '' and MultiJobWebhookConfig.FooterIcon or nil
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
    }

    queue[#queue + 1] = {
        eventName = eventName,
        url = url,
        payload = {
            username = MultiJobWebhookConfig.BotName,
            avatar_url = MultiJobWebhookConfig.BotAvatar ~= '' and MultiJobWebhookConfig.BotAvatar or nil,
            embeds = { embed }
        }
    }

    processQueue()
end
