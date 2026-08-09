require("config/variables")

hl.window_rule({ match = {title = "Open File"}, float = true})
hl.window_rule({ match = {title = "Select a File"}, float = true})
hl.window_rule({ match = {title = "Choose wallpaper"}, float = true})
hl.window_rule({ match = {title = "Open Folder"}, float = true})
hl.window_rule({ match = {title = "Rename"}, float = true})
hl.window_rule({ match = {title = "Save As"}, float = true})
hl.window_rule({ match = {title = "Library"}, float = true})
hl.window_rule({ match = {title = "File Upload"}, float = true})
hl.window_rule({ match = {title = "File Operation Progress"}, float = true})
hl.window_rule({ match = {title = "Confirm to replace files"}, float = true})
hl.window_rule({ match = {title = "Extension: (Bitwarden Password Manager) - Bitwarden — Zen Browser"}, float = true})

-- File dialogs with specific sizes
hl.window_rule({ match = {class = browser}, match = {title = "Save As"}, size = {800, 600}})
hl.window_rule({ match = {class = browser}, match = {title = "Choose Files"}, size = {800, 600}})
hl.window_rule({ match = {class = browser}, match = {title = "Open File"}, size = {800, 600}})
hl.window_rule({ match = {class = browser}, match = {title = "Open Folder"}, size = {800, 600}})