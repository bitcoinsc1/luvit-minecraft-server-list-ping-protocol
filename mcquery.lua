local net = require('net')
local json_parse = require('json').parse

local function short(val)
    return string.char(bit.rshift(val, 8), bit.band(val, 255))
end

local function unpack_varint(data, pos)
    local res = 0
    local sht = 0

    pos = pos or 1

    repeat
        if pos > #data then
            return nil, pos
        end

        local b = string.byte(data, pos)

        pos = pos + 1
        res = res + bit.band(b, 0x7f) * (2 ^ sht)
        sht = sht + 7

        if sht > 35 then
            return nil, pos
        end
    until bit.band(b, 0x80) == 0

    return res, pos
end

return function(host, port)
    local socket = net.createConnection(port, host)
    local co = coroutine.running()

    socket:setTimeout(2000, function()
        socket:destroy()
    end)

    socket:on('close', function()
        coroutine.resume(co)
    end)

    socket:on('connect', function()
        local data = string.format('\000\004%s%s%s\001', string.char(#host), host, short(port))
        socket:write(string.char(#data) .. data)
        socket:write('\001\000')
    end)

    local res = ''
    local json_len = 0

    socket:on('data', function(data)
        res = res .. data

        if json_len == 0 then
            local pos = 1

            for i = 1, 2 do
                local _, _pos = unpack_varint(res, pos)
                if not _pos then return end

                pos = _pos
            end

            json_len = unpack_varint(res, pos)
            if not json_len then return end
        end

        local res_len = #res
        if res_len > json_len then
            socket:removeListener('close')
            socket:destroy()
            coroutine.resume(co, json_parse(res:sub(res_len - json_len + 1, res_len)))
        end
    end)

    return coroutine.yield()
end