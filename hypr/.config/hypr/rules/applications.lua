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
   ["on_created_empty"] = "discord",
})

hl.workspace_rule({ workspace = "w[tv1-10]", gaps_out = 15, gaps_in = 5 })
