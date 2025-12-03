hs.window.setShadows(false)
hs.window.animationDuration = 0.1
hs.window.setFrameCorrectness = false

local hyper = {"alt"}
local hyper_shift = {"alt", "shift"}

hs.hotkey.bind(hyper, "t", function()
    hs.task.new("/Applications/kitty.app/Contents/MacOS/kitty", nil, function() end, {"--single-instance", "-d", "~"}):start()
end)

hs.hotkey.bind(hyper, "q", function()
    local win = hs.window.focusedWindow()
    if not win then return end
    
    local app = win:application()
    if not app then return end

    local bundleID = app:bundleID()
    local no_quit_apps = {
        ["com.apple.finder"] = true,
        ["org.hammerspoon.Hammerspoon"] = true,
        ["com.apple.Music"] = true,
    }

    if no_quit_apps[bundleID] then
        hs.eventtap.keyStroke({"cmd"}, "w", app)
        return
    end

    local count = 0
    for _, w in pairs(app:allWindows()) do
        if w:isStandard() then
            count = count + 1
        end
    end

    if count > 1 then
        hs.eventtap.keyStroke({"cmd"}, "w", app)
    else
        hs.eventtap.keyStroke({"cmd"}, "q", app)
    end
end)

hs.hotkey.bind(hyper, "d", function()
    hs.eventtap.keyStroke({"cmd"}, "space")
end)

hs.hotkey.bind(hyper, "e", function()
    hs.osascript.applescript([[
        tell application "Finder"
            activate
            make new Finder window to home
        end tell
    ]])
end)

hs.hotkey.bind(hyper, "o", function()
    hs.spaces.toggleMissionControl()
end)

hs.loadSpoon("SpoonInstall")
local Install = spoon.SpoonInstall

Install.repos.PaperWM = {
    url = "https://github.com/mogenson/PaperWM.spoon",
    desc = "PaperWM.spoon",
    branch = "release",
}

Install.repos.FocusMode = {
    url = "https://github.com/selimacerbas/FocusMode.spoon",
    desc = "FocusMode.spoon",
    branch = "release",
}

Install.use_syncinstall = true 

Install:andUse("PaperWM", {
    repo = "PaperWM",
    start = true,
    config = {
        window_ratios = { 1/3, 1/2, 2/3 }
    },
    hotkeys = {
        -- switch to a new focused window in tiled grid
        focus_left  = {hyper, "h"},
        focus_right = {hyper, "l"},
        focus_up    = {hyper, "k"},
        focus_down  = {hyper, "j"},

        -- move windows around in tiled grid
        swap_left  = {hyper_shift, "h"},
        swap_right = {hyper_shift, "l"},
        swap_up    = {hyper_shift, "k"},
        swap_down  = {hyper_shift, "j"},

        -- position and resize focused window
        center_window        = {hyper, "c"},
        full_width           = {hyper, "f"},
        cycle_width          = {hyper, "r"},
        cycle_height         = {hyper_shift, "r"},

        -- move the focused window into / out of the tiling layer
        toggle_floating = {hyper, "p"},

        -- switch to a new Mission Control space
        switch_space_l = {hyper, ","},
        switch_space_r = {hyper, "."},
        switch_space_1 = {hyper, "1"},
        switch_space_2 = {hyper, "2"},
        switch_space_3 = {hyper, "3"},
        switch_space_4 = {hyper, "4"},
        switch_space_5 = {hyper, "5"},
        switch_space_6 = {hyper, "6"},
        switch_space_7 = {hyper, "7"},
        switch_space_8 = {hyper, "8"},
        switch_space_9 = {hyper, "9"},

        -- move focused window to a new space and tile
        move_window_1 = {hyper_shift, "1"},
        move_window_2 = {hyper_shift, "2"},
        move_window_3 = {hyper_shift, "3"},
        move_window_4 = {hyper_shift, "4"},
        move_window_5 = {hyper_shift, "5"},
        move_window_6 = {hyper_shift, "6"},
        move_window_7 = {hyper_shift, "7"},
        move_window_8 = {hyper_shift, "8"},
        move_window_9 = {hyper_shift, "9"}
    }
})