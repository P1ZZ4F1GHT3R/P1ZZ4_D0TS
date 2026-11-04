require ("config/variables")

hl.window_rule({
   match = {
       class = "^(GitHub Desktop)$",
   },
   workspace = "8",
   fullscreen = true,
})

hl.window_rule({
   match = {
       class = "^(fdm)$",
   },
   workspace = "9",
   fullscreen = true,
})

hl.window_rule({
   match = {
       class = "^(Spotify)$",
   },
   workspace = "10",
   fullscreen = true,
})

hl.window_rule({
   match = {
       class = "^(looking-glass-client)$",
   },
   fullscreen = true,
})

hl.workspace_rule({
   workspace = "special:Discord",
})

hl.on("workspace.created", function(ws)
    if ws.name == "special:Discord" then
        hl.exec_cmd("discord", { workspace = "special:Discord silent" })
    end
end)

local topGap = math.floor(gapsOut + (gapsOut / 3))

hl.workspace_rule({ 
   workspace = "w[tv1-10]", 
   gaps_out = {
       top = topGap,
       right = gapsOut,
       bottom = gapsOut,
       left = gapsOut,
   },
   gaps_in = gapsIn 
})
