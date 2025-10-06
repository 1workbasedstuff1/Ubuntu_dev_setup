#!/bin/bash
# File: ~/Bash-scripts/pywal-sys-colors.sh
# Usage: ./pywal-sys-colors.sh /path/to/image.jpg
# new comment
# new change not staged

IMAGE="$1"

# Validate input
if [ -z "$IMAGE" ] || [ ! -f "$IMAGE" ]; then
    echo "Usage: $0 /path/to/image.jpg"
    exit 1
fi

# Run pywal and source colors
wal -i "$IMAGE"
source ~/.cache/wal/colors.sh 2>/dev/null || exit 1

# Set wallpapers for all monitors
monitors=$(xrandr --query | grep " connected" | cut -d" " -f1)
temp_images=()
for monitor in $monitors; do
    resolution=$(xrandr --query | grep "$monitor" | grep -o '[0-9]*x[0-9]*')
    temp_img=~/.cache/wal/$(basename "$IMAGE")_$monitor.jpg
    convert "$IMAGE" -resize "${resolution}^" -gravity center -extent "$resolution" "$temp_img"
    temp_images+=("$temp_img")
done

feh --no-fehbg --bg-scale "${temp_images[@]}"

# Update Ghostty theme
mkdir -p ~/.config/ghostty/themes
cat > ~/.config/ghostty/themes/pywal-theme <<EOF
# Generated from pywal
background = $background
foreground = $color7
cursor-color = $color7
selection-background = $foreground
selection-foreground = $background
EOF

# Update Polybar colors
polybar_config=~/.config/polybar/config.ini
sed -i.bak "
s/^background =.*/background = $color0/
s/^background-alt =.*/background-alt = $color0/
s/^foreground =.*/foreground = $color7/
s/^primary =.*/primary = $color3/
s/^secondary =.*/secondary = $color6/
s/^alert =.*/alert = $color1/
s/^disabled =.*/disabled = $color8/
" "$polybar_config"

# Restart Polybar
killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 0.1; done
polybar top &
polybar top-external &
polybar top-external-4k &

# Get most vibrant color from pywal
most_vibrant=$(grep -o '#[0-9a-fA-F]\{6\}' ~/.cache/wal/colors.sh | sort -r | head -n1)

# Apply most vibrant color directly to bspwm borders
bspc config focused_border_color "$most_vibrant"
bspc config normal_border_color "$color0"
bspc config urgent_border_color "$color0"

# Update bspwm config file
bspwm_config=~/.config/bspwm/bspwmrc
sed -i "
s/^bspc config focused_border_color.*/bspc config focused_border_color \"$most_vibrant\"/
s/^bspc config normal_border_color.*/bspc config normal_border_color \"$color0\"/
s/^bspc config urgent_border_color.*/bspc config urgent_border_color \"$color0\"/
" "$bspwm_config"

# Set bold terminal path prompt in most vibrant color
hex_to_rgb() {
    local hex=${1#"#"}
    echo "$((16#${hex:0:2})) $((16#${hex:2:2})) $((16#${hex:4:2}))"
}
read r g b <<< $(hex_to_rgb "$most_vibrant")
PS1="\[\e[1;38;2;${r};${g};${b}m\]\w\[\e[0m\]\$ "

echo "All settings updated successfully"
