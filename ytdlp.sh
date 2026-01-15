#!/bin/bash

# Function to select directory using kdialog
select_directory() {
    kdialog --getexistingdirectory "$1"
}

# Function to prompt for a URL using kdialog
prompt_url() {
    url=$(kdialog --inputbox "$1")
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
    tail -f "$tmpfile" | fzf --height 40 --reverse --border --prompt="Downloading... " --header="Progress" --disabled --tac --no-sort &
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
            yt-dlp -U --cookies-from-browser firefox -f "$format_selector" \
            -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$video_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        elif [ "$download_type" == "Audio" ]; then
            # Download audio as m4a
            yt-dlp -U --cookies-from-browser firefox -x --audio-format m4a \
            -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$video_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        else
            # Download thumbnail
            yt-dlp --write-thumbnail --skip-download --convert-thumbnails jpg \
            -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$video_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        fi
        title=$(ls -t "$save_path" | head -1 | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} - //' | sed 's/\.[^.]*$//')
        echo ""
        if [ "$download_type" == "Thumbnail" ]; then
            echo "Downloaded thumbnail of \"${title}\". Press Enter to continue..."
        else
            echo "Downloaded \"${title}\". Press Enter to continue..."
        fi
    ) > "$tmpfile" 2>&1
    wait $fzf_pid
    rm -f "$tmpfile"
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
    tail -f "$tmpfile" | fzf --height 40 --reverse --border --prompt="Downloading... " --header="Progress" --disabled --tac --no-sort &
    fzf_pid=$!
    (
        if [ "$download_type" == "Video" ]; then
            # Download videos with max quality
            height=$(get_quality_height "$max_quality")
            format_selector="bestvideo[height<=${height}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${height}][ext=mp4]/worst[ext=mp4]/worst"
            yt-dlp -U --cookies-from-browser firefox -f "$format_selector" \
            -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$playlist_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        elif [ "$download_type" == "Audio" ]; then
            # Download audio as m4a
            yt-dlp -U --cookies-from-browser firefox -x --audio-format m4a \
            -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$playlist_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        else
            # Download thumbnails
            yt-dlp --write-thumbnail --skip-download --convert-thumbnails jpg \
            -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$playlist_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        fi
        echo ""
        if [ "$download_type" == "Thumbnail" ]; then
            echo "Downloaded thumbnails. Press Enter to continue..."
        else
            echo "Download completed. Press Enter to continue..."
        fi
    ) > "$tmpfile" 2>&1
    wait $fzf_pid
    rm -f "$tmpfile"
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
    tail -f "$tmpfile" | fzf --height 40 --reverse --border --prompt="Downloading... " --header="Progress" --disabled --tac --no-sort &
    fzf_pid=$!
    (
        if [ "$download_type" == "Video" ]; then
            height=$(get_quality_height "$max_quality")
            format_selector="bestvideo[height<=${height}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${height}][ext=mp4]/worst[ext=mp4]/worst"
            yt-dlp -U --cookies-from-browser firefox -f "$format_selector" \
            -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$channel_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        elif [ "$download_type" == "Audio" ]; then
            yt-dlp -U --cookies-from-browser firefox -x --audio-format m4a \
            -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$channel_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        else
            yt-dlp --write-thumbnail --skip-download --convert-thumbnails jpg \
            -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$channel_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        fi
        channel_name=$(yt-dlp --print "%(channel)s" "$channel_url" 2>/dev/null | head -1)
        echo ""
        if [ "$download_type" == "Thumbnail" ]; then
            echo "Downloaded thumbnails from \"${channel_name}\". Press Enter to continue..."
        else
            echo "Downloaded all videos from \"${channel_name}\". Press Enter to continue..."
        fi
    ) > "$tmpfile" 2>&1
    wait $fzf_pid
    rm -f "$tmpfile"
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
    tail -f "$tmpfile" | fzf --height 40 --reverse --border --prompt="Downloading... " --header="Progress" --disabled --tac --no-sort &
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
            echo ""
            echo "\"${channel_name}\" avatar downloaded. Press Enter to continue..."
        else
            echo ""
            echo "Could not find channel avatar. Press Enter to continue..."
        fi
    ) > "$tmpfile" 2>&1
    wait $fzf_pid
    rm -f "$tmpfile"
}

# Function to download videos from a .txt file
download_from_txt() {
    txt_file=$(kdialog --getopenfilename "" "Select a .txt file containing video URLs")
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
    tail -f "$tmpfile" | fzf --height 40 --reverse --border --prompt="Downloading... " --header="Progress" --disabled --tac --no-sort &
    fzf_pid=$!
    (
        for video_url in $(cat "$txt_file"); do
            if [ "$download_type" == "Video" ]; then
                height=$(get_quality_height "$max_quality")
                format_selector="bestvideo[height<=${height}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${height}][ext=mp4]/worst[ext=mp4]/worst"
                yt-dlp -U --cookies-from-browser firefox -f "$format_selector" \
                -o "$save_path/%(uploader)s - %(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$video_url" 2>&1 | stdbuf -oL tr '\r' '\n'
            else
                yt-dlp -U --cookies-from-browser firefox -x --audio-format m4a \
                -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$video_url" 2>&1 | stdbuf -oL tr '\r' '\n'
            fi
        done
        echo ""
        echo "Download completed. Press Enter to continue..."
    ) > "$tmpfile" 2>&1
    wait $fzf_pid
    rm -f "$tmpfile"
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

    start_time=$(kdialog --inputbox "Enter start time (HH:MM:SS):")
    if [ $? -ne 0 ]; then
        return 1
    fi

    end_time=$(kdialog --inputbox "Enter end time (HH:MM:SS):")
    if [ $? -ne 0 ]; then
        return 1
    fi

    tmpfile=$(mktemp)
    tail -f "$tmpfile" | fzf --height 40 --reverse --border --prompt="Downloading... " --header="Progress" --disabled --tac --no-sort &
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
            yt-dlp -U --cookies-from-browser firefox -f "$format_selector" \
            -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" \
            --exec "echo %(filepath)s > $save_path/filename.txt" "$video_url" 2>&1 | stdbuf -oL tr '\r' '\n'
        else
            # Download audio as m4a
            yt-dlp -U --cookies-from-browser firefox -x --audio-format m4a \
            -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" \
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
        
        # Delete the original downloaded video
        rm -f "$full_filename"
        rm -f "$save_path/filename.txt"
        
        echo ""
        echo "Clipped \"${title}\". Press Enter to continue..."
    ) > "$tmpfile" 2>&1
    wait $fzf_pid
    rm -f "$tmpfile"
}


# Main menu
main_menu() {
    printf 'Single Video\nPlaylist\nChannel\nAvatar\nCustom\nClip\nExit' | fzf --height 17 --reverse --border --prompt="Select an option: " --header="YouTube Downloader"
}

# Main script
while true; do
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
        "Exit")
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done
