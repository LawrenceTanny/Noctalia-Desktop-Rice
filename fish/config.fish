source /usr/share/cachyos-fish-config/cachyos-config.fish

# --- Responsive Fastfetch (Auto-scales for half-screen & full-screen) ---
function fastfetch
    set -l imgs (find /home/lawrencetan/Pictures/Fastfetch -maxdepth 1 -name "*.png" 2>/dev/null)
    set -l has_img (count $imgs)
    
    # Check terminal width (half-screen vs full-screen)
    if test "$COLUMNS" -lt 105
        # Half-screen / Split Window mode (compact words, small logo)
        if test $has_img -gt 0
            set -l pick (random choice $imgs)
            command fastfetch -c ~/.config/fastfetch/small.jsonc --logo-type kitty-direct --logo $pick --logo-width 18 --logo-height 11 --logo-padding-left 1 --logo-padding-right 1 $argv
        else
            command fastfetch -c ~/.config/fastfetch/small.jsonc $argv
        end
    else
        # Full-screen / Wide mode (full words, large logo)
        if test $has_img -gt 0
            set -l pick (random choice $imgs)
            command fastfetch -c ~/.config/fastfetch/config.jsonc --logo-type kitty-direct --logo $pick --logo-width 36 --logo-height 20 $argv
        else
            command fastfetch -c ~/.config/fastfetch/config.jsonc $argv
        end
    end
end

function fish_greeting
    fastfetch
end

# --- Aliases ---
alias roblox='flatpak run org.vinegarhq.Sober'
alias Roblox='flatpak run org.vinegarhq.Sober'
alias eagle="QT_QPA_PLATFORM=xcb /usr/bin/eagle"
alias Eagle="QT_QPA_PLATFORM=xcb /usr/bin/eagle"

# Added by Antigravity CLI installer
set -gx PATH "/home/lawrencetan/.local/bin" $PATH

function vivado
    bash -c "source ~/Downloads/SCHOOL/2026.1/Vivado/settings64.sh && export _JAVA_AWT_WM_NONREPARENTING=1 && vivado"
end
