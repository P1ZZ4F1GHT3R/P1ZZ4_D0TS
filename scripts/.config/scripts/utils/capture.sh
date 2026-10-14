#!/usr/bin/env bash

# Config / Temp Files
REC_PID="/tmp/wf-recorder.pid"
VID_DIR="$HOME/Videos/Captures"
IMG_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$VID_DIR" "$IMG_DIR"

# Helper function to send notifications without an app name header
notify() {
    notify-send -a "" "$@"
}

# 1. Screenshot (Area selection to clipboard & file)
screenshot() {
    local file="$IMG_DIR/screenshot_$(date +'%Y-%m-%d@%H:%M:%S').png"
    local area="${1:-$(slurp)}"
    if [ -z "$area" ]; then exit 1; fi
    
    if grim -g "$area" "$file" 2>/dev/null && [ -s "$file" ]; then
        wl-copy < "$file"
        notify "Screenshot" "Saved to $file & copied to clipboard" -i "$file"
    else
        rm -f "$file"
        notify -u critical "Screenshot Failed" "Invalid capture geometry: '$area'"
    fi
}

# 2. Screen Recording (Toggle Start/Stop)
record_toggle() {
    if [ -f "$REC_PID" ]; then
        local pid
        pid=$(cat "$REC_PID")
        kill -INT "$pid" 2>/dev/null
        rm -f "$REC_PID"
        notify "Screen Recorder" "Recording stopped and saved to $VID_DIR"
    else
        local area="$1"
        local file="$VID_DIR/recording_$(date +'%Y-%m-%d@%H:%M:%S').mp4"
        
        if [ -n "$area" ]; then
            wf-recorder -g "$area" -f "$file" &
        else
            local active_out
            active_out=$(hyprctl monitors | awk '/Monitor/{name=$2} /focused: yes/{print name}')
            if [ -z "$active_out" ]; then
                active_out=$(hyprctl monitors | awk '/Monitor/{print $2; exit}')
            fi
            wf-recorder -o "$active_out" -f "$file" &
        fi
        
        echo $! > "$REC_PID"
        notify "Screen Recorder" "Recording started..."
    fi
}

# 3. OCR (Extract text to clipboard)
ocr() {
    local tmp="/tmp/ocr_capture.png"
    local area="${1:-$(slurp)}"
    if [ -z "$area" ]; then exit 1; fi
    
    if ! command -v tesseract &>/dev/null; then
        notify -u critical "OCR Failed" "tesseract is not installed."
        exit 1
    fi

    if grim -g "$area" "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
        local text
        text=$(tesseract "$tmp" stdout --psm 6 2>/dev/null | xargs)
        
        if [ -z "$text" ]; then
            text=$(tesseract "$tmp" stdout 2>/dev/null | xargs)
        fi

        if [ -n "$text" ]; then
            echo -n "$text" | wl-copy
            notify "OCR Captured" "${text:0:120}"
        else
            notify -u critical "OCR Failed" "No text detected in cropped region."
        fi
    else
        notify -u critical "OCR Failed" "Invalid capture area: '$area'"
    fi
    rm -f "$tmp"
}

# 4. Color Picker
color_picker() {
    local color
    color=$(hyprpicker -a -f hex)
    if [ -n "$color" ]; then
        notify "Color Picker" "Hex value $color copied to clipboard!"
    fi
}

# 5. Visual Search (Google Lens)
visual_search() {
    local tmp="/tmp/lens_capture.jpg"
    local area="${1:-$(slurp)}"
    if [ -z "$area" ]; then exit 1; fi

    if ! command -v curl &>/dev/null || ! command -v xdg-open &>/dev/null; then
        notify -u critical "Google Lens Failed" "curl and xdg-open are required."
        exit 1
    fi

    # Capture directly to JPEG at 80% quality for small payload size (~100-200KB)
    if grim -t jpeg -q 80 -g "$area" "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
        notify "Google Lens" "Uploading image..."

        # 1. Primary: Catbox
        local img_url
        img_url=$(curl -s --max-time 5 -F "reqtype=fileupload" -F "fileToUpload=@$tmp" https://catbox.moe/user/api.php | tr -d '\r\n')

        # 2. Fallback 1: 0x0.st
        if [[ ! "$img_url" =~ ^https?:// ]]; then
            img_url=$(curl -s --max-time 5 -A "Mozilla/5.0" -F "file=@$tmp" https://0x0.st | tr -d '\r\n')
        fi

        # 3. Fallback 2: Litterbox (Temporary 1-hour Catbox host)
        if [[ ! "$img_url" =~ ^https?:// ]]; then
            img_url=$(curl -s --max-time 5 -F "reqtype=fileupload" -F "time=1h" -F "fileToUpload=@$tmp" https://litterbox.catbox.moe/resources/internals/api.php | tr -d '\r\n')
        fi

        if [[ "$img_url" =~ ^https?:// ]]; then
            local lens_url="https://lens.google.com/uploadbyurl?url=$(echo -n "$img_url" | jq -sRr @uri 2>/dev/null || echo -n "$img_url")"
            
            if [ -n "$BROWSER" ]; then
                "$BROWSER" "$lens_url" &>/dev/null &
            else
                xdg-open "$lens_url" &>/dev/null &
            fi
            
            notify "Google Lens" "Opening search results..."
        else
            notify -u critical "Google Lens Failed" "All upload hosts failed or timed out."
        fi
    else
        notify -u critical "Google Lens Failed" "Invalid capture area: '$area'"
    fi
    rm -f "$tmp"
}

# Subcommand Router
case "$1" in
    screenshot)   screenshot "$2" ;;
    record)       record_toggle "$2" ;;
    ocr)          ocr "$2" ;;
    colorpicker)  color_picker ;;
    lens)         visual_search "$2" ;;
    *)            echo "Usage: $0 {screenshot|record|ocr|colorpicker|lens}" ;;
esac