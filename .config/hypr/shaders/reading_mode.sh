#!/usr/bin/env bash

# Path to shader
SHADER="$HOME/.config/hypr/shaders/grayscale.glsl"
THEME="$HOME/.config/quickshell/snes-hub/bar/theme-mode.sh"
WALLPAPER="$HOME/Pictures/desktop/WP/6.jpg"
WALLPAPER_DEF="$HOME/Pictures/desktop/l2.png"

# Check active shader
if hyprshade current | grep -q "grayscale"; then
    # Deactivate and Reload
    hyprshade off
    hyprctl reload
    brightnessctl set 60%
    swww img "$WALLPAPER_DEF" --transition-type none
    qs -c snes-hub
    
    

else
    # ACTIVATES
    hyprshade on "$SHADER"
    "$THEME" light
    swww img "$WALLPAPER" --transition-type none
    # Force E-ink visuals: No animations, no shadows, thin black borders
    hyprctl keyword animations:enabled 0
    hyprctl keyword decoration:drop_shadow 0
    # hyprctl keyword decoration:blur:enabled 0
    hyprctl keyword decoration:rounding 0
    hyprctl keyword general:gaps_in 0
    hyprctl keyword general:gaps_out 0
    hyprctl keyword general:border_size 2
    hyprctl keyword general:col.active_border "rgba(000000ff)"
    hyprctl keyword general:col.inactive_border "rgba(000000ff)"
    hyprctl keyword decoration:dim_inactive 0
    brightnessctl set 37% 
    pkill qs
fi