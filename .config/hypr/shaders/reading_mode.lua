#!/usr/bin/env lua

-- PATHS
local home = os.getenv("HOME")
local shader_path = home .. "/.config/hypr/shaders/grayscale.glsl"
local theme_script = home .. "/.config/quickshell/snes-hub/bar/theme-mode.sh"
local current_theme_file = home .. "/.cache/quickshell/theme_mode"
local restore_file = home .. "/.cache/quickshell/reading_mode_restore"
local wallpaper_reading = home .. "/Pictures/desktop/WP/6.jpg"

-- HELPERS
local function exec_capture(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end

-- Execute a shell 
local function exec(cmd, async)
    if async then
        os.execute(cmd .. " &")
    else
        os.execute(cmd)
    end
end

-- File I/O
local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content:gsub("%s+", "")
end

local function write_file(path, content)
    local f = io.open(path, "w")
    if not f then return end
    f:write(content)
    f:close()
end

-- SWITCHER
-- Check if shader is active
local current_shader = exec_capture("hyprshade current")

if string.find(current_shader, "grayscale") then

    -- [[ DEACTIVATE: TURN OFF READING MODE ]] --

    -- Determine which theme to restore
    local prev_theme = read_file(restore_file)
    if prev_theme == nil or prev_theme == "" then
        prev_theme = "dark" -- Default fallback
    end

    -- Turn off shader & restore theme
    --exec("hyprshade off", true)
    exec(theme_script .. " " .. prev_theme, true)

    -- Restore Hyprland
    exec("hyprctl reload", false)

    -- Cleanup
    os.remove(restore_file)

    -- Restart Shell
    exec("qs -c snes-hub", true)

else
    -- [[ ACTIVATE: TURN ON READING MODE ]] --

    -- Save current theme state
    local current_theme = read_file(current_theme_file)
    if current_theme == nil then current_theme = "dark" end
    write_file(restore_file, current_theme)

    -- Enable Shader & Switch to Light Theme
    exec("hyprshade on " .. shader_path, false)
    exec("pkill qs", false)
    exec(theme_script .. " light", false)

    -- Set Wallpaper & Brightness (Async)
    exec("swww img " .. wallpaper_reading .. " --transition-type none", true)
    exec("brightnessctl set 37%", true)

    -- Apply E-ink Overrides
    local overrides = {
        "keyword animations:enabled 0",
        "keyword decoration:shadow:enabled 0", 
        "keyword decoration:blur:enabled 0",
        "keyword decoration:rounding 0",
        "keyword general:gaps_in 0",
        "keyword general:gaps_out 0",
        "keyword general:border_size 2",
        "keyword general:col.active_border rgba(000000ff)",
        "keyword general:col.inactive_border rgba(000000ff)",
        "keyword decoration:dim_inactive 0"
    }
    
    local batch_cmd = "hyprctl --batch '" .. table.concat(overrides, ";") .. "'"
    exec(batch_cmd, false)

end