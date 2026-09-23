local MAX_DEPTH = 10

local function tPrint(tbl, indent)
    indent = indent or 0
    if type(tbl) ~= 'table' then
        return print(('%s ^0%s'):format(string.rep('  ', indent), tbl))
    end
    if indent > MAX_DEPTH then
        return print(('%s ^1<max depth reached>^0'):format(string.rep('  ', indent)))
    end
    for k, v in pairs(tbl) do
        local tblType = type(v)
        local formatting = ('%s ^3%s:^0'):format(string.rep('  ', indent), k)
        if tblType == 'table' then
            print(formatting)
            tPrint(v, indent + 1)
        elseif tblType == 'boolean' then
            print(('%s^1 %s ^0'):format(formatting, v))
        elseif tblType == 'function' then
            print(('%s^9 %s ^0'):format(formatting, v))
        elseif tblType == 'number' then
            print(('%s^5 %s ^0'):format(formatting, v))
        elseif tblType == 'string' then
            print(("%s ^2'%s' ^0"):format(formatting, v))
        else
            print(('%s^2 %s ^0'):format(formatting, v))
        end
    end
end

local function debugPrint(tbl, indent, resource)
    print(('\x1b[4m\x1b[36m[ %s : DEBUG]\x1b[0m'):format(resource or 'unknown'))
    tPrint(tbl, indent)
    print('\x1b[4m\x1b[36m[ END DEBUG ]\x1b[0m')
end

-- Server-only event (no longer a net event: clients could previously flood the server console with it)
AddEventHandler('RSGCore:DebugSomething', debugPrint)

function RSGCore.Debug(tbl, indent)
    debugPrint(tbl, indent, GetInvokingResource() or GetCurrentResourceName())
end

function RSGCore.ShowError(resource, msg)
    print('\x1b[31m[' .. resource .. ':ERROR]\x1b[0m ' .. msg)
end

function RSGCore.ShowSuccess(resource, msg)
    print('\x1b[32m[' .. resource .. ':LOG]\x1b[0m ' .. msg)
end
