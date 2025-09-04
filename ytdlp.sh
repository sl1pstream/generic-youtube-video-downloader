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

# Function to prompt for download type (video or audio) using dialog
prompt_download_type() {
    dialog --stdout --menu "Select Download Type" 10 30 2 \
        "Video" "Download Video" \
        "Audio" "Download Audio (MP3)"
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
    local menu_items=()
    declare -A added_qualities
    
    # Get all available video formats (including webm and other formats)
    local heights=$(yt-dlp -F "$video_url" 2>/dev/null | grep -v "audio only" | grep -E "[0-9]+p|[0-9]+x[0-9]+" | grep -o "[0-9]*p\|[0-9]*x[0-9]*" | sed 's/x.*//;s/p//' | sort -nr | uniq)
    
    for height in $heights; do
        case "$height" in
            2160|3840) 
                if [[ ! ${added_qualities["2160p"]} ]]; then
                    menu_items+=("2160p (4K)" "")
                    added_qualities["2160p"]=1
                fi ;;
            1440|2560) 
                if [[ ! ${added_qualities["1440p"]} ]]; then
                    menu_items+=("1440p (HD)" "")
                    added_qualities["1440p"]=1
                fi ;;
            1080|1920) 
                if [[ ! ${added_qualities["1080p"]} ]]; then
                    menu_items+=("1080p (HD)" "")
                    added_qualities["1080p"]=1
                fi ;;
            720|1280) 
                if [[ ! ${added_qualities["720p"]} ]]; then
                    menu_items+=("720p" "")
                    added_qualities["720p"]=1
                fi ;;
            360|640) 
                if [[ ! ${added_qualities["360p"]} ]]; then
                    menu_items+=("360p" "")
                    added_qualities["360p"]=1
                fi ;;
            240|426) 
                if [[ ! ${added_qualities["240p"]} ]]; then
                    menu_items+=("240p" "")
                    added_qualities["240p"]=1
                fi ;;
            144|256) 
                if [[ ! ${added_qualities["144p"]} ]]; then
                    menu_items+=("144p" "")
                    added_qualities["144p"]=1
                fi ;;
        esac
    done
    
    [[ ${#menu_items[@]} -eq 0 ]] && menu_items=("Best available" "")
    
    dialog --stdout --menu "Select Video Quality" 12 40 6 "${menu_items[@]}"
}

# Function to prompt for max quality (playlist/channel/custom)
prompt_max_quality() {
    dialog --stdout --menu "Select Maximum Quality" 12 40 8 \
        "2160p (4K)" "" \
        "1440p (HD)" "" \
        "1080p (HD)" "" \
        "720p" "" \
        "480p" "" \
        "360p" "" \
        "240p" "" \
        "144p" ""
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

    # Create a named pipe for progress
    progress_pipe=$(mktemp -u)
    mkfifo "$progress_pipe"

    # Display "Downloading..." message with progress
    (
        while read -r line; do
            if [[ $line =~ ([0-9]+)\.[0-9]+% ]]; then
                progress=${BASH_REMATCH[1]}
                echo "$progress"
            elif [[ $line =~ ^\[download\].*Destination:\ (.*)$ ]]; then
                title=$(basename "${BASH_REMATCH[1]}")
                echo "XXX"
                echo "$progress"
                echo "Downloading: $title"
                echo "XXX"
            fi
        done < "$progress_pipe"
    ) | dialog --gauge "Downloading..." 8 40 0 &

    gauge_pid=$!

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
        yt-dlp -U --newline --cookies-from-browser firefox -f "$format_selector" \
        -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$video_url" > "$progress_pipe" 2>&1
    else
        # Download audio as mp3
        yt-dlp -U --newline --cookies-from-browser firefox -f 'bestaudio' --extract-audio --audio-format mp3 \
        -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$video_url" > "$progress_pipe" 2>&1
    fi

    wait $gauge_pid
    rm "$progress_pipe"

    # Display "Download completed" message
    dialog --msgbox "Download completed" 5 30
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

    # Create a named pipe for progress
    progress_pipe=$(mktemp -u)
    mkfifo "$progress_pipe"

    # Display "Downloading..." message with progress
    (
        while read -r line; do
            if [[ $line =~ ([0-9]+)\.[0-9]+% ]]; then
                progress=${BASH_REMATCH[1]}
                echo "$progress"
            elif [[ $line =~ ^\[download\].*Destination:\ (.*)$ ]]; then
                title=$(basename "${BASH_REMATCH[1]}")
                echo "XXX"
                echo "$progress"
                echo "Downloading: $title"
                echo "XXX"
            fi
        done < "$progress_pipe"
    ) | dialog --gauge "Downloading..." 8 40 0 &

    gauge_pid=$!

    if [ "$download_type" == "Video" ]; then
        # Download videos with max quality
        height=$(get_quality_height "$max_quality")
        format_selector="bestvideo[height<=${height}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${height}][ext=mp4]/worst[ext=mp4]/worst"
        yt-dlp -U --newline --cookies-from-browser firefox -f "$format_selector" \
        -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$playlist_url" > "$progress_pipe" 2>&1
    else
        # Download audio as mp3
        yt-dlp -U --newline --cookies-from-browser firefox -f 'bestaudio' --extract-audio --audio-format mp3 \
        -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$playlist_url" > "$progress_pipe" 2>&1
    fi

    wait $gauge_pid
    rm "$progress_pipe"

    # Display "Download completed" message
    dialog --msgbox "Download completed" 5 30
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

    # Get max quality for video downloads
    max_quality=$(prompt_max_quality)
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Create a named pipe for progress
    progress_pipe=$(mktemp -u)
    mkfifo "$progress_pipe"

    # Display "Downloading..." message with progress
    (
        while read -r line; do
            if [[ $line =~ ([0-9]+)\.[0-9]+% ]]; then
                progress=${BASH_REMATCH[1]}
                echo "$progress"
            elif [[ $line =~ ^\[download\].*Destination:\ (.*)$ ]]; then
                title=$(basename "${BASH_REMATCH[1]}")
                echo "XXX"
                echo "$progress"
                echo "Downloading: $title"
                echo "XXX"
            fi
        done < "$progress_pipe"
    ) | dialog --gauge "Downloading..." 8 40 0 &

    gauge_pid=$!

    # Download all videos from the channel with max quality
    height=$(get_quality_height "$max_quality")
    format_selector="bestvideo[height<=${height}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${height}][ext=mp4]/worst[ext=mp4]/worst"
    yt-dlp -U --newline --cookies-from-browser firefox -f "$format_selector" \
    -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$channel_url" > "$progress_pipe" 2>&1

    wait $gauge_pid
    rm "$progress_pipe"

    # Display "Download completed" message
    dialog --msgbox "Download completed" 5 30
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

    for video_url in $(cat "$txt_file"); do
        # Create a named pipe for progress
        progress_pipe=$(mktemp -u)
        mkfifo "$progress_pipe"

        # Display "Downloading..." message with progress
        (
            while read -r line; do
                if [[ $line =~ ([0-9]+)\.[0-9]+% ]]; then
                    progress=${BASH_REMATCH[1]}
                    echo "$progress"
                elif [[ $line =~ ^\[download\].*Destination:\ (.*)$ ]]; then
                    title=$(basename "${BASH_REMATCH[1]}")
                    echo "XXX"
                    echo "$progress"
                    echo "Downloading: $title"
                    echo "XXX"
                fi
            done < "$progress_pipe"
        ) | dialog --gauge "Downloading..." 8 40 0 &

        gauge_pid=$!

        if [ "$download_type" == "Video" ]; then
            height=$(get_quality_height "$max_quality")
            format_selector="bestvideo[height<=${height}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${height}][ext=mp4]/worst[ext=mp4]/worst"
            yt-dlp -U --newline --cookies-from-browser firefox -f "$format_selector" \
            -o "$save_path/%(uploader)s - %(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$video_url" > "$progress_pipe" 2>&1
        else
            yt-dlp -U --newline --cookies-from-browser firefox -f 'bestaudio' --extract-audio --audio-format mp3 \
            -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$video_url" > "$progress_pipe" 2>&1
        fi

        wait $gauge_pid
        rm "$progress_pipe"
    done

    #Display "Download completed" message
    dialog --msgbox "Download completed" 5 30
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

    # Create a named pipe for progress
    progress_pipe=$(mktemp -u)
    mkfifo "$progress_pipe"

    # Display "Downloading..." message with progress
    (
        while read -r line; do
            if [[ $line =~ ([0-9]+)\.[0-9]+% ]]; then
                progress=${BASH_REMATCH[1]}
                echo "$progress"
            elif [[ $line =~ ^\[download\].*Destination:\ (.*)$ ]]; then
                title=$(basename "${BASH_REMATCH[1]}")
                echo "XXX"
                echo "$progress"
                echo "Downloading: $title"
                echo "XXX"
            fi
        done < "$progress_pipe"
    ) | dialog --gauge "Downloading..." 8 40 0 &

    gauge_pid=$!


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
        yt-dlp -U --newline --cookies-from-browser firefox -f "$format_selector" \
        -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" \
        --exec "echo %(filepath)s > $save_path/filename.txt" "$video_url" > "$progress_pipe" 2>&1
    else
        # Download audio as mp3
        yt-dlp -U --newline --cookies-from-browser firefox -f 'bestaudio' --extract-audio --audio-format mp3 \
        -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" \
        --exec "echo %(filepath)s > $save_path/filename.txt" "$video_url" > "$progress_pipe" 2>&1
    fi

    full_filename=$(cat "$save_path/filename.txt")

    wait $gauge_pid
    rm "$progress_pipe"

    # Display "Trimming..." message
    dialog --infobox "Trimming..." 3 20

    # Trim the video
    dialog --infobox "Trimming..." 3 20
    ffmpeg -i "$full_filename" -ss "$start_time" -to "$end_time" \
        -c:v libx264 -c:a aac \
        "$save_path/$(basename "$full_filename" .mp4)_clip.mp4" \
        > /dev/null 2>&1
    
    # Delete the original downloaded video
    rm -f "$(cat "$save_path/filename.txt")"

    # Delete filename.txt
    rm -f "$save_path/filename.txt"

    # Display completion message
    dialog --msgbox "Trim completed" 5 30
}


# Main menu
main_menu() {
    dialog --stdout --title "YouTube Downloader" --menu "Select an option:" 15 60 5 \
        "Single Video" "Download a single video" \
        "Playlist" "Download a playlist" \
        "Channel" "Download all videos from a channel" \
        "Custom" "Download videos from .txt (URL)" \
        "Clip" "Download and trim a video" \
        "Exit" "Exit the program"
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
