-- Server-only: Discord webhook logging for jobs (kept off the client so URLs can't be read)
-----------------------------------------------------------------------
-- Discord Webhook Logging
-----------------------------------------------------------------------
MultiJobWebhookConfig = {
    Enabled = true, -- master on/off switch for all webhook logging

    -- Used for any event below that doesn't have its own URL set
    DefaultURL = '', -- e.g. 'https://discord.com/api/webhooks/XXXXXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'

    BotName = 'RSG Jobs',
    BotAvatar = '', -- URL to an image, leave blank for Discord default
    FooterText = 'rsg-core jobs',
    FooterIcon = '',
    DefaultColor = 3092790, -- decimal RGB, used if an event has no Color set

    -- Per-event configuration. Set `URL` on an event to route it to a
    -- different Discord channel than DefaultURL, or set `Enabled = false`
    -- to silence just that one event.
    Events = {
        JobAdded = {
            Enabled = true,
            URL = '',
            Title = '📋 Job Added',
            Color = 3066993, -- green
        },
        JobSwitched = {
            Enabled = true,
            URL = '',
            Title = '🔁 Job Switched',
            Color = 3447003, -- blue
        },
        JobDeleted = {
            Enabled = true,
            URL = '',
            Title = '🗑️ Job Deleted',
            Color = 15158332, -- red
        },
        JobRemovedByAdmin = {
            Enabled = true,
            URL = '',
            Title = '🛠️ Job Removed (Admin)',
            Color = 15105570, -- orange
        },
        JobCreated = {
            Enabled = true,
            URL = '',
            Title = '🆕 Job Created',
            Color = 3066993,
        },
        JobUpdated = {
            Enabled = true,
            URL = '',
            Title = '✏️ Job Edited',
            Color = 3447003,
        },
        JobDefinitionDeleted = {
            Enabled = true,
            URL = '',
            Title = '❌ Job Deleted From Server',
            Color = 15158332,
        },
        EmployeeFired = {
            Enabled = true,
            URL = '',
            Title = '🔥 Employee Fired',
            Color = 10038562, -- dark red
        },
    }
}
