#!/bin/bash

# Settings file path
SETTINGS_FILE="$HOME/.config/ytdlp_settings"
ARCHIVE_FILE="$HOME/.config/ytdlp_archive.txt"

# Load SponsorBlock settings
load_sponsorblock_settings() {
    if [ -f "$SETTINGS_FILE" ]; then
        source "$SETTINGS_FILE"
    fi
}

# Save SponsorBlock settings
save_sponsorblock_settings() {
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    cat > "$SETTINGS_FILE" << EOF
SPONSOR=${SPONSOR:-false}
UNPAID=${UNPAID:-false}
INTERACTION=${INTERACTION:-false}
HIGHLIGHT=${HIGHLIGHT:-false}
INTERMISSION=${INTERMISSION:-false}
ENDCARDS=${ENDCARDS:-false}
PREVIEW=${PREVIEW:-false}
HOOK=${HOOK:-false}
TANGENTS=${TANGENTS:-false}
DOWNLOAD_ARCHIVE=${DOWNLOAD_ARCHIVE:-false}
FILENAME_TEMPLATE=${FILENAME_TEMPLATE:-\$d - \$t}
EOF
}

# Build yt-dlp output template from user-defined shorthand
build_output_template() {
    local tmpl="${FILENAME_TEMPLATE:-\$d - \$t}"
    tmpl="${tmpl//\$d/%(upload_date>%Y-%m-%d)s}"
    tmpl="${tmpl//\$t/%(title)s}"
    tmpl="${tmpl//\$u/%(uploader)s}"
    tmpl="${tmpl//\$i/%(id)s}"
    tmpl="${tmpl//\$r/%(resolution)s}"
    tmpl="${tmpl//\$p/%(playlist_index)s}"
    echo "${tmpl}.%(ext)s"
}

# Build archive arguments
build_archive_args() {
    [ "$DOWNLOAD_ARCHIVE" = "true" ] && echo "--download-archive $ARCHIVE_FILE" || echo ""
}

# Build SponsorBlock arguments
build_sponsorblock_args() {
    local args=""
    local categories=""
    local mark_categories=""
    
    [ "$SPONSOR" = "true" ] && categories="${categories}sponsor,"
    [ "$UNPAID" = "true" ] && categories="${categories}selfpromo,"
    [ "$INTERACTION" = "true" ] && categories="${categories}interaction,"
    [ "$HIGHLIGHT" = "true" ] && categories="${categories}poi_highlight,"
    [ "$INTERMISSION" = "true" ] && categories="${categories}intro,"
    [ "$ENDCARDS" = "true" ] && categories="${categories}outro,"
    [ "$PREVIEW" = "true" ] && categories="${categories}preview,"
    [ "$TANGENTS" = "true" ] && categories="${categories}filler,"
    [ "$HOOK" = "true" ] && mark_categories="${mark_categories}music_offtopic,"
    
    categories=${categories%,}
    mark_categories=${mark_categories%,}
    
    [ -n "$categories" ] && args="$args --sponsorblock-remove $categories"
    [ -n "$mark_categories" ] && args="$args --sponsorblock-mark $mark_categories"
    
    echo "$args"
}

# SponsorBlock settings menu
sponsorblock_settings() {
    while true; do
        local menu_items=""
        menu_items+="$([ "$SPONSOR" = "true" ] && echo "✓ ")Sponsor - Paid promotion, paid referrals and direct advertisements\n"
        menu_items+="$([ "$UNPAID" = "true" ] && echo "✓ ")Unpaid/Self Promotion - Similar to Sponsor except for unpaid or self promotion\n"
        menu_items+="$([ "$INTERACTION" = "true" ] && echo "✓ ")Interaction reminder - Short reminder to like, subscribe or follow\n"
        menu_items+="$([ "$HIGHLIGHT" = "true" ] && echo "✓ ")Highlight - The part of the video that most people are looking for\n"
        menu_items+="$([ "$INTERMISSION" = "true" ] && echo "✓ ")Intermission/Intro Animation - Interval without actual content\n"
        menu_items+="$([ "$ENDCARDS" = "true" ] && echo "✓ ")Endcards/Credits - Credits or when YouTube endcards appear\n"
        menu_items+="$([ "$PREVIEW" = "true" ] && echo "✓ ")Preview/Recap - Collection of clips showing what's coming up\n"
        menu_items+="$([ "$HOOK" = "true" ] && echo "✓ ")Hook/Greetings - Narrated trailers, greetings and goodbyes (marked, not removed)\n"
        menu_items+="$([ "$TANGENTS" = "true" ] && echo "✓ ")Tangents/Jokes - Tangential scenes or jokes\n"
        menu_items+="Back"
        
        choice=$(echo -e "$menu_items" | fzf --height 20 --reverse --border --prompt="Toggle SponsorBlock categories: " --header="SponsorBlock Settings (✓ = enabled)")
        
        case "$choice" in
            *"Sponsor -"*) SPONSOR=$([ "$SPONSOR" = "true" ] && echo "false" || echo "true") ;;
            *"Unpaid/Self Promotion -"*) UNPAID=$([ "$UNPAID" = "true" ] && echo "false" || echo "true") ;;
            *"Interaction reminder -"*) INTERACTION=$([ "$INTERACTION" = "true" ] && echo "false" || echo "true") ;;
            *"Highlight -"*) HIGHLIGHT=$([ "$HIGHLIGHT" = "true" ] && echo "false" || echo "true") ;;
            *"Intermission/Intro Animation -"*) INTERMISSION=$([ "$INTERMISSION" = "true" ] && echo "false" || echo "true") ;;
            *"Endcards/Credits -"*) ENDCARDS=$([ "$ENDCARDS" = "true" ] && echo "false" || echo "true") ;;
            *"Preview/Recap -"*) PREVIEW=$([ "$PREVIEW" = "true" ] && echo "false" || echo "true") ;;
            *"Hook/Greetings -"*) HOOK=$([ "$HOOK" = "true" ] && echo "false" || echo "true") ;;
            *"Tangents/Jokes -"*) TANGENTS=$([ "$TANGENTS" = "true" ] && echo "false" || echo "true") ;;
            "Back"|"")
                save_sponsorblock_settings
                return
                ;;
        esac
    done
}

# Filename template settings
filename_template_settings() {
    clear
    echo "Edit Filename Scheme"
    echo ""
    echo "Default : \$d - \$t"
    echo "Current : ${FILENAME_TEMPLATE:-\$d - \$t}"
    echo ""
    echo "Available tokens:"
    echo "  \$d  Upload date (YYYY-MM-DD)"
    echo "  \$t  Video title"
    echo "  \$u  Uploader / channel name"
    echo "  \$i  Video ID"
    echo "  \$r  Resolution (e.g. 1280x720)"
    echo "  \$p  Playlist index"
    echo ""
    echo "Example: \$u_\$d_\$r_\$t  →  ChannelName_2024-01-15_1280x720_Video Title.mp4"
    echo ""
    local error=""
    while true; do
        if [ -n "$error" ]; then
            echo -e "\e[31m$error\e[0m"
        fi
        read -e -i "${new_template:-${FILENAME_TEMPLATE:-\$d - \$t}}" -p "Scheme: " new_template
        if [ -z "$new_template" ]; then
            return
        elif [[ "$new_template" == */* || "$new_template" == *\\* ]]; then
            error="Error: Slashes are not allowed in the filename scheme."
        else
            FILENAME_TEMPLATE="$new_template"
            save_sponsorblock_settings
            clear
            return
        fi
    done
}

# Settings menu
settings_menu() {
    while true; do
        choice=$(printf 'SponsorBlock Settings\n%sDownload History\nEdit Filename Scheme (%s)\nBack' \
            "$([ "$DOWNLOAD_ARCHIVE" = "true" ] && echo "✓ ")" \
            "${FILENAME_TEMPLATE:-\$d - \$t}" \
            | fzf --height 10 --reverse --border --prompt="Select setting: " --header="Settings")

        case "$choice" in
            "SponsorBlock Settings")
                sponsorblock_settings
                ;;
            *"Download History"*)
                DOWNLOAD_ARCHIVE=$([ "$DOWNLOAD_ARCHIVE" = "true" ] && echo "false" || echo "true")
                save_sponsorblock_settings
                ;;
            *"Edit Filename Scheme"*)
                filename_template_settings
                ;;
            "Back"|"")
                return
                ;;
        esac
    done
}

# Show result menu after download completes
show_result_menu() {
    local logfile="$1"
    local status_msg="$2"
    local summary="$3"
    local header="$status_msg"
    [ -n "$summary" ] && header="$status_msg  |  $summary"
    while true; do
        local choice
        choice=$(printf 'Continue\nView Log\nSave Log' | fzf --height 10 --reverse --border --prompt="Select an option: " --header="$header" --no-sort)
        case "$choice" in
            "View Log")
                printf 'Continue\nSave Log' | fzf --height 80% --reverse --border \
                    --prompt="Select an option: " --header="$header" --no-sort \
                    --preview="cat '$logfile'" \
                    --preview-window=bottom:80%:wrap \
                    --bind='enter:become(echo {})' > /tmp/log_action_$$.txt 2>/dev/null
                local log_choice; log_choice=$(cat /tmp/log_action_$$.txt 2>/dev/null)
                rm -f /tmp/log_action_$$.txt
                case "$log_choice" in
                    "Save Log")
                        local dest
                        dest=$(kdialog --getsavefilename "$HOME/download_log.txt" 2>/dev/null)
                        [ -n "$dest" ] && cp "$logfile" "$dest"
                        ;;
                    *) return ;;
                esac
                return
                ;;
            "Save Log")
                local dest
                dest=$(kdialog --getsavefilename "$HOME/download_log.txt" 2>/dev/null)
                [ -n "$dest" ] && cp "$logfile" "$dest"
                return
                ;;
            *) return ;;
        esac
    done
}

# Function to select directory using kdialog
select_directory() {
    kdialog --getexistingdirectory "$1" 2>/dev/null
}

# Function to prompt for a URL using kdialog
prompt_url() {
    url=$(kdialog --inputbox "$1" 2>/dev/null)
    if [ $? -ne 0 ]; then
        return 1
    else
        echo "$url"
    fi
}

# Function to prompt for download type (video or audio) using fzf
prompt_download_type() {
    printf 'Video\nAudio\nThumbnail' | fzf --height 10 --reverse --border --prompt="Select Download Type: " --header="Video, Audio (M4A), or Thumbnail"
    if [ $? -ne 0 ]; then
        return 1
    fi
}

# Function to get available qualities for a single video
get_available_qualities() {
    local video_url="$1"
    yt-dlp -F "$video_url" 2>/dev/null | grep -E "^[0-9]+" | grep -E "mp4|webm" | grep -v "audio only" | \
    awk '{print $3}' | sort -nr | uniq | head -10
}

# Function to prompt for video quality (single video/clip)
prompt_video_quality() {
    local video_url="$1"
    local qualities=()
    declare -A added_qualities
    
    # Get all available video formats (including webm and other formats)
    local heights=$(yt-dlp -F "$video_url" 2>/dev/null | grep -v "audio only" | grep -E "[0-9]+p|[0-9]+x[0-9]+" | grep -o "[0-9]*p\|[0-9]*x[0-9]*" | sed 's/x.*//;s/p//' | sort -nr | uniq)
    
    for height in $heights; do
        case "$height" in
            2160|3840) 
                if [[ ! ${added_qualities["2160p"]} ]]; then
                    qualities+=("2160p (4K)")
                    added_qualities["2160p"]=1
                fi ;;
            1440|2560) 
                if [[ ! ${added_qualities["1440p"]} ]]; then
                    qualities+=("1440p (HD)")
                    added_qualities["1440p"]=1
                fi ;;
            1080|1920) 
                if [[ ! ${added_qualities["1080p"]} ]]; then
                    qualities+=("1080p (HD)")
                    added_qualities["1080p"]=1
                fi ;;
            720|1280) 
                if [[ ! ${added_qualities["720p"]} ]]; then
                    qualities+=("720p")
                    added_qualities["720p"]=1
                fi ;;
            360|640) 
                if [[ ! ${added_qualities["360p"]} ]]; then
                    qualities+=("360p")
                    added_qualities["360p"]=1
                fi ;;
            240|426) 
                if [[ ! ${added_qualities["240p"]} ]]; then
                    qualities+=("240p")
                    added_qualities["240p"]=1
                fi ;;
            144|256) 
                if [[ ! ${added_qualities["144p"]} ]]; then
                    qualities+=("144p")
                    added_qualities["144p"]=1
                fi ;;
        esac
    done
    
    [[ ${#qualities[@]} -eq 0 ]] && qualities=("Best available")
    
    printf '%s\n' "${qualities[@]}" | fzf --height 15 --reverse --border --prompt="Select Video Quality: " --header="Available Qualities"
}

# Function to prompt for max quality (playlist/channel/custom)
prompt_max_quality() {
    printf '2160p (4K)\n1440p (HD)\n1080p (HD)\n720p\n480p\n360p\n240p\n144p' | fzf --height 15 --reverse --border --prompt="Select Maximum Quality: " --header="Max Quality"
}

# Function to convert quality display name to numeric value
get_quality_height() {
    case "$1" in
        "2160p (4K)") echo "2160" ;;
        "1440p (HD)") echo "1440" ;;
        "1080p (HD)") echo "1080" ;;
        "720p") echo "720" ;;
        "480p") echo "480" ;;
        "360p") echo "360" ;;
        "240p") echo "240" ;;
        "144p") echo "144" ;;
    esac
}

# Function to download a single video
download_single_video() {
    video_url=$(prompt_url "Enter the video URL:")
    if [ $? -ne 0 ]; then
        return 1
    fi

    save_path=$(select_directory "Select Directory to Save Video")
    if [ $? -ne 0 ]; then
        return 1
    fi

    download_type=$(prompt_download_type)
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Get video quality if downloading video
    if [ "$download_type" == "Video" ]; then
        quality=$(prompt_video_quality "$video_url")
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi

    tmpfile=$(mktemp)
    downloaded_file=$(mktemp)
    statusfile=$(mktemp)
    fifo="/tmp/progress_fifo.$$"
    mkfifo "$fifo"
    tail -f "$tmpfile" > "$fifo" &
    tail_pid=$!
    fzf --height 40 --reverse --border --prompt="Downloading... " --header="Progress" --tac --no-sort < "$fifo" > /dev/null &
    fzf_pid=$!
    (
        if [ "$download_type" == "Video" ]; then
            # Download video with selected quality
            if [ "$quality" == "Best available" ]; then
                format_selector="best[ext=mp4]/best"
            else
                case "$quality" in
                    "2160p (4K)") height="2160" ;;
                    "1440p (HD)") height="1440" ;;
                    "1080p (HD)") height="1080" ;;
                    "720p") height="720" ;;
                    "360p") height="360" ;;
                    "240p") height="240" ;;
                    "144p") height="144" ;;
                esac
                format_selector="bestvideo[height<=${height}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${height}][ext=mp4]/best"
            fi
            sponsorblock_args=$(build_sponsorblock_args)
            archive_args=$(build_archive_args)
            local output_template
            output_template=$(build_output_template)
            yt-dlp -U --extractor-args "youtube:player_js_variant=tv" --cookies-from-browser firefox -f "$format_selector" \
            -o "$save_path/$output_template" --print-to-file after_move:filepath "$downloaded_file" $sponsorblock_args $archive_args "$video_url" 2>&1 | stdbuf -oL tr '\r' '\n'
            download_status=${PIPESTATUS[0]}
        elif [ "$download_type" == "Audio" ]; then
            # Download audio as m4a
            sponsorblock_args=$(build_sponsorblock_args)
            archive_args=$(build_archive_args)
            local output_template
            output_template=$(build_output_template)
            yt-dlp -U --extractor-args "youtube:player_js_variant=tv" --cookies-from-browser firefox -x --audio-format m4a \
            -o "$save_path/$output_template" --print-to-file after_move:filepath "$downloaded_file" $sponsorblock_args $archive_args "$video_url" 2>&1 | stdbuf -oL tr '\r' '\n'
            download_status=${PIPESTATUS[0]}
        else
            # Download thumbnail
            archive_args=$(build_archive_args)
            local output_template
            output_template=$(build_output_template)
            yt-dlp --extractor-args "youtube:player_js_variant=tv" --write-thumbnail --skip-download --convert-thumbnails jpg \
            -o "$save_path/$output_template" --print-to-file after_move:filepath "$downloaded_file" $archive_args "$video_url" 2>&1 | stdbuf -oL tr '\r' '\n'
            download_status=${PIPESTATUS[0]}
        fi
        if [ "$download_status" -eq 0 ] && [ -s "$downloaded_file" ]; then
            full_filename=$(tail -n 1 "$downloaded_file")
            title=$(basename "$full_filename" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} - //' | sed 's/\.[^.]*$//')
            if [ "$download_type" == "Thumbnail" ]; then
                echo "success:Downloaded thumbnail of \"${title}\"."
            else
                echo "success:Downloaded \"${title}\"."
            fi
        else
            echo "failed:Download failed."
        fi > "$statusfile"
        kill $fzf_pid 2>/dev/null
    ) > "$tmpfile" 2>&1
    kill $tail_pid 2>/dev/null
    wait $fzf_pid 2>/dev/null
    local status_line; status_line=$(cat "$statusfile")
    local dl_status_msg summary
    if [[ "$status_line" == success:* ]]; then
        dl_status_msg="✓ Download completed"
        summary="${status_line#success:}"
    else
        dl_status_msg="✗ Download failed"
        summary="${status_line#failed:}"
    fi
    show_result_menu "$tmpfile" "$dl_status_msg" "$summary"
    rm -f "$tmpfile" "$fifo" "$downloaded_file" "$statusfile"
}

# Function to download a playlist
download_playlist() {
    playlist_url=$(prompt_url "Enter the playlist URL:")
    if [ $? -ne 0 ]; then
        return 1
    fi

    save_path=$(select_directory "Select Directory to Save Videos")
    if [ $? -ne 0 ]; then
        return 1
    fi

    download_type=$(prompt_download_type)
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Get max quality if downloading video
    if [ "$download_type" == "Video" ]; then
        max_quality=$(prompt_max_quality)
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi

    tmpfile=$(mktemp)
    statusfile=$(mktemp)
    fifo="/tmp/progress_fifo.$$"
    mkfifo "$fifo"
    tail -f "$tmpfile" > "$fifo" &
    tail_pid=$!
    fzf --height 40 --reverse --border --prompt="Downloading... " --header="Progress" --tac --no-sort < "$fifo" > /dev/null &
    fzf_pid=$!
    (
        if [ "$download_type" == "Video" ]; then
            # Download videos with max quality
            height=$(get_quality_height "$max_quality")
            format_selector="bestvideo[height<=${height}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${height}][ext=mp4]/worst[ext=mp4]/worst"
            sponsorblock_args=$(build_sponsorblock_args)
            archive_args=$(build_archive_args)
            local output_template
            output_template=$(build_output_template)
            yt-dlp -U --extractor-args "youtube:player_js_variant=tv" --cookies-from-browser firefox -f "$format_selector" \
            -o "$save_path/$output_template" $sponsorblock_args $archive_args "$playlist_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        elif [ "$download_type" == "Audio" ]; then
            # Download audio as m4a
            sponsorblock_args=$(build_sponsorblock_args)
            archive_args=$(build_archive_args)
            local output_template
            output_template=$(build_output_template)
            yt-dlp -U --extractor-args "youtube:player_js_variant=tv" --cookies-from-browser firefox -x --audio-format m4a \
            -o "$save_path/$output_template" $sponsorblock_args $archive_args "$playlist_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        else
            # Download thumbnails
            archive_args=$(build_archive_args)
            local output_template
            output_template=$(build_output_template)
            yt-dlp --extractor-args "youtube:player_js_variant=tv" --write-thumbnail --skip-download --convert-thumbnails jpg \
            -o "$save_path/$output_template" $archive_args "$playlist_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        fi
        if [ "$download_type" == "Thumbnail" ]; then
            echo "success:Downloaded thumbnails."
        else
            echo "success:Download completed."
        fi > "$statusfile"
        kill $fzf_pid 2>/dev/null
    ) > "$tmpfile" 2>&1
    kill $tail_pid 2>/dev/null
    wait $fzf_pid 2>/dev/null
    local status_line; status_line=$(cat "$statusfile")
    show_result_menu "$tmpfile" "✓ Download completed" "${status_line#success:}"
    rm -f "$tmpfile" "$fifo" "$statusfile"
}

# Function to download all videos from a channel
download_channel_videos() {
    channel_url=$(prompt_url "Enter the channel URL:")
    if [ $? -ne 0 ]; then
        return 1
    fi

    save_path=$(select_directory "Select Directory to Save Videos")
    if [ $? -ne 0 ]; then
        return 1
    fi

    download_type=$(prompt_download_type)
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Get max quality if downloading video
    if [ "$download_type" == "Video" ]; then
        max_quality=$(prompt_max_quality)
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi

    tmpfile=$(mktemp)
    statusfile=$(mktemp)
    fifo="/tmp/progress_fifo.$$"
    mkfifo "$fifo"
    tail -f "$tmpfile" > "$fifo" &
    tail_pid=$!
    fzf --height 40 --reverse --border --prompt="Downloading... " --header="Progress" --tac --no-sort < "$fifo" > /dev/null &
    fzf_pid=$!
    (
        if [ "$download_type" == "Video" ]; then
            height=$(get_quality_height "$max_quality")
            format_selector="bestvideo[height<=${height}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${height}][ext=mp4]/worst[ext=mp4]/worst"
            sponsorblock_args=$(build_sponsorblock_args)
            archive_args=$(build_archive_args)
            local output_template
            output_template=$(build_output_template)
            yt-dlp -U --extractor-args "youtube:player_js_variant=tv" --cookies-from-browser firefox -f "$format_selector" \
            -o "$save_path/$output_template" $sponsorblock_args $archive_args "$channel_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        elif [ "$download_type" == "Audio" ]; then
            sponsorblock_args=$(build_sponsorblock_args)
            archive_args=$(build_archive_args)
            local output_template
            output_template=$(build_output_template)
            yt-dlp -U --extractor-args "youtube:player_js_variant=tv" --cookies-from-browser firefox -x --audio-format m4a \
            -o "$save_path/$output_template" $sponsorblock_args $archive_args "$channel_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        else
            archive_args=$(build_archive_args)
            local output_template
            output_template=$(build_output_template)
            yt-dlp --extractor-args "youtube:player_js_variant=tv" --write-thumbnail --skip-download --convert-thumbnails jpg \
            -o "$save_path/$output_template" $archive_args "$channel_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        fi
        channel_name=$(yt-dlp --extractor-args "youtube:player_js_variant=tv" --print "%(channel)s" "$channel_url" 2>/dev/null | head -1)
        if [ "$download_type" == "Thumbnail" ]; then
            echo "success:Downloaded thumbnails from \"${channel_name}\"."
        else
            echo "success:Downloaded all videos from \"${channel_name}\"."
        fi > "$statusfile"
        kill $fzf_pid 2>/dev/null
    ) > "$tmpfile" 2>&1
    kill $tail_pid 2>/dev/null
    wait $fzf_pid 2>/dev/null
    local status_line; status_line=$(cat "$statusfile")
    show_result_menu "$tmpfile" "✓ Download completed" "${status_line#success:}"
    rm -f "$tmpfile" "$fifo" "$statusfile"
}

# Function to download channel avatar
download_avatar() {
    channel_url=$(prompt_url "Enter the channel URL:")
    if [ $? -ne 0 ]; then
        return 1
    fi

    save_path=$(select_directory "Select Directory to Save Avatar")
    if [ $? -ne 0 ]; then
        return 1
    fi

    tmpfile=$(mktemp)
    statusfile=$(mktemp)
    fifo="/tmp/progress_fifo.$$"
    mkfifo "$fifo"
    tail -f "$tmpfile" > "$fifo" &
    tail_pid=$!
    fzf --height 40 --reverse --border --prompt="Downloading... " --header="Progress" --tac --no-sort < "$fifo" > /dev/null &
    fzf_pid=$!
    (
        echo "Fetching channel page..."
        # Use curl to get the channel page and extract avatar URL
        page_content=$(curl -s "$channel_url")
        echo "Extracting avatar URL..."
        avatar_url=$(echo "$page_content" | grep -o '"avatar":{"thumbnails":\[{"url":"[^"]*' | head -1 | cut -d'"' -f8)
        
        if [ -z "$avatar_url" ]; then
            # Try alternative pattern
            avatar_url=$(echo "$page_content" | grep -o 'channelMetadataRenderer.*avatar.*url":"[^"]*' | head -1 | sed 's/.*url":"//' | cut -d'"' -f1)
        fi
        
        if [ -n "$avatar_url" ]; then
            # Get channel name
            channel_name=$(echo "$page_content" | grep -o '<title>[^<]*' | head -1 | sed 's/<title>//' | sed 's/ - YouTube//')
            [ -z "$channel_name" ] && channel_name="channel"
            
            # Clean filename
            clean_name=$(echo "$channel_name" | tr -d '/<>:"|?*')
            
            echo "Downloading avatar for ${channel_name}..."
            wget -q "$avatar_url" -O "$save_path/${clean_name}_avatar.jpg" 2>/dev/null
            echo "success:\"${channel_name}\" avatar downloaded." > "$statusfile"
        else
            echo "failed:Could not find channel avatar." > "$statusfile"
        fi
        kill $fzf_pid 2>/dev/null
    ) > "$tmpfile" 2>&1
    kill $tail_pid 2>/dev/null
    wait $fzf_pid 2>/dev/null
    local status_line; status_line=$(cat "$statusfile")
    local av_status_msg summary
    if [[ "$status_line" == success:* ]]; then
        av_status_msg="✓ Download completed"; summary="${status_line#success:}"
    else
        av_status_msg="✗ Download failed"; summary="${status_line#failed:}"
    fi
    show_result_menu "$tmpfile" "$av_status_msg" "$summary"
    rm -f "$tmpfile" "$fifo" "$statusfile"
}

# Function to download videos from a .txt file
download_from_txt() {
    txt_file=$(kdialog --getopenfilename "" "Select a .txt file containing video URLs" 2>/dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi

    save_path=$(select_directory "Select Directory to Save Videos")
    if [ $? -ne 0 ]; then
        return 1
    fi

    download_type=$(prompt_download_type)
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Get max quality if downloading video
    if [ "$download_type" == "Video" ]; then
        max_quality=$(prompt_max_quality)
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi

    tmpfile=$(mktemp)
    statusfile=$(mktemp)
    fifo="/tmp/progress_fifo.$$"
    mkfifo "$fifo"
    tail -f "$tmpfile" > "$fifo" &
    tail_pid=$!
    fzf --height 40 --reverse --border --prompt="Downloading... " --header="Progress" --tac --no-sort < "$fifo" > /dev/null &
    fzf_pid=$!
    (
        sponsorblock_args=$(build_sponsorblock_args)
        archive_args=$(build_archive_args)
        local dl_status=0
        for video_url in $(cat "$txt_file"); do
            if [ "$download_type" == "Video" ]; then
                height=$(get_quality_height "$max_quality")
                format_selector="bestvideo[height<=${height}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${height}][ext=mp4]/worst[ext=mp4]/worst"
                local output_template
                output_template=$(build_output_template)
                yt-dlp -U --extractor-args "youtube:player_js_variant=tv" --cookies-from-browser firefox -f "$format_selector" \
                -o "$save_path/$output_template" $sponsorblock_args $archive_args "$video_url" 2>&1 | stdbuf -oL tr '\r' '\n'
            else
                local output_template
                output_template=$(build_output_template)
                yt-dlp -U --extractor-args "youtube:player_js_variant=tv" --cookies-from-browser firefox -x --audio-format m4a \
                -o "$save_path/$output_template" $sponsorblock_args $archive_args "$video_url" 2>&1 | stdbuf -oL tr '\r' '\n'
            fi
            [ ${PIPESTATUS[0]} -ne 0 ] && dl_status=1
        done
        if [ $dl_status -eq 0 ]; then
            echo "success:Download completed."
        else
            echo "failed:Download completed with errors."
        fi > "$statusfile"
        kill $fzf_pid 2>/dev/null
    ) > "$tmpfile" 2>&1
    kill $tail_pid 2>/dev/null
    wait $fzf_pid 2>/dev/null
    local status_line; status_line=$(cat "$statusfile")
    local txt_status_msg summary
    if [[ "$status_line" == success:* ]]; then
        txt_status_msg="✓ Download completed"; summary="${status_line#success:}"
    else
        txt_status_msg="✗ Download failed"; summary="${status_line#failed:}"
    fi
    show_result_menu "$tmpfile" "$txt_status_msg" "$summary"
    rm -f "$tmpfile" "$fifo" "$statusfile"
}

# Function to download a clipped video
download_clip() {
    video_url=$(prompt_url "Enter the video URL:")
    if [ $? -ne 0 ]; then
        return 1
    fi

    save_path=$(select_directory "Select Directory to Save Video")
    if [ $? -ne 0 ]; then
        return 1
    fi

    download_type=$(printf 'Video\nAudio' | fzf --height 10 --reverse --border --prompt="Select Download Type: " --header="Video or Audio (M4A)")
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Get video quality if downloading video
    if [ "$download_type" == "Video" ]; then
        quality=$(prompt_video_quality "$video_url")
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi

    start_time=$(kdialog --inputbox "Enter start time (HH:MM:SS):" 2>/dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi

    end_time=$(kdialog --inputbox "Enter end time (HH:MM:SS):" 2>/dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi

    tmpfile=$(mktemp)
    statusfile=$(mktemp)
    fifo="/tmp/progress_fifo.$$"
    mkfifo "$fifo"
    tail -f "$tmpfile" > "$fifo" &
    tail_pid=$!
    fzf --height 40 --reverse --border --prompt="Downloading... " --header="Progress" --tac --no-sort < "$fifo" > /dev/null &
    fzf_pid=$!
    (
        if [ "$download_type" == "Video" ]; then
            # Download video with selected quality
            if [ "$quality" == "Best available" ]; then
                format_selector="best[ext=mp4]/best"
            else
                case "$quality" in
                    "2160p (4K)") height="2160" ;;
                    "1440p (HD)") height="1440" ;;
                    "1080p (HD)") height="1080" ;;
                    "720p") height="720" ;;
                    "360p") height="360" ;;
                    "240p") height="240" ;;
                    "144p") height="144" ;;
                esac
                format_selector="bestvideo[height<=${height}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${height}][ext=mp4]/best"
            fi
            local output_template
            output_template=$(build_output_template)
            yt-dlp -U --extractor-args "youtube:player_js_variant=tv" --cookies-from-browser firefox -f "$format_selector" \
            -o "$save_path/$output_template" \
            --exec "echo %(filepath)s > $save_path/filename.txt" "$video_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        else
            # Download audio as m4a
            local output_template
            output_template=$(build_output_template)
            yt-dlp -U --extractor-args "youtube:player_js_variant=tv" --cookies-from-browser firefox -x --audio-format m4a \
            -o "$save_path/$output_template" \
            --exec "echo %(filepath)s > $save_path/filename.txt" "$video_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        fi
        
        full_filename=$(cat "$save_path/filename.txt")
        title=$(basename "$full_filename" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} - //' | sed 's/\.[^.]*$//')
        
        echo ""
        echo "Trimming video..."
        
        # Trim the video
        ffmpeg -i "$full_filename" -ss "$start_time" -to "$end_time" \
            -c:v libx264 -c:a aac \
            "$save_path/$(basename "$full_filename" .mp4)_clip.mp4" 2>&1 | grep -E "time=|Duration:" | stdbuf -oL tr '\r' '\n'
        local ffmpeg_status=${PIPESTATUS[0]}
        
        rm -f "$full_filename" "$save_path/filename.txt"
        if [ $ffmpeg_status -eq 0 ]; then
            echo "success:Clipped \"${title}\"."
        else
            echo "failed:Clip failed."
        fi > "$statusfile"
        kill $fzf_pid 2>/dev/null
    ) > "$tmpfile" 2>&1
    kill $tail_pid 2>/dev/null
    wait $fzf_pid 2>/dev/null
    local status_line; status_line=$(cat "$statusfile")
    local clip_status_msg summary
    if [[ "$status_line" == success:* ]]; then
        clip_status_msg="✓ Download completed"; summary="${status_line#success:}"
    else
        clip_status_msg="✗ Download failed"; summary="${status_line#failed:}"
    fi
    show_result_menu "$tmpfile" "$clip_status_msg" "$summary"
    rm -f "$tmpfile" "$fifo" "$statusfile"
}


# Main menu
main_menu() {
    printf 'Single Video\nPlaylist\nChannel\nAvatar\nCustom\nClip\nSettings\nExit' | fzf --height 18 --reverse --border --prompt="Select an option: " --header="YouTube Downloader"
}

# Load settings on startup
load_sponsorblock_settings

# Main script
while true; do
    clear
    choice=$(main_menu)

    case $choice in
        "Single Video")
            download_single_video
            ;;
        "Playlist")
            download_playlist
            ;;
        "Channel")
            download_channel_videos
            ;;
        "Avatar")
            download_avatar
            ;;
        "Custom")
            download_from_txt
            ;;
        "Clip")
            download_clip
            ;;
        "Settings")
            settings_menu
            ;;
        "Exit")
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done
