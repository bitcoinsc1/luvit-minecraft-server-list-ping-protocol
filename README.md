# Minecraft Server List Ping Protocol implementation in Luvit

How to use:

```lua
  local query = require('mcquery')

  coroutine.wrap(function()
    p(query('IP_ADDRESS', port))
  end)()
```

https://minecraft.wiki/w/Java_Edition_protocol/Server_List_Ping
