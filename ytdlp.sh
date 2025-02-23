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
        # Download video
        yt-dlp -U --newline -f 'bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]' \
        -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$video_url" > "$progress_pipe" 2>&1
    else
        # Download audio as mp3
        yt-dlp -U --newline -f 'bestaudio' --extract-audio --audio-format mp3 \
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
        # Download videos
        yt-dlp -U --newline -f 'bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]' \
        -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$playlist_url" > "$progress_pipe" 2>&1
    else
        # Download audio as mp3
        yt-dlp -U --newline -f 'bestaudio' --extract-audio --audio-format mp3 \
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

    # Download all videos from the channel
    yt-dlp -U --newline -f 'bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]' \
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
            yt-dlp -U --newline -f 'bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]' \
            -o "$save_path/%(uploader)s - %(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" "$video_url" > "$progress_pipe" 2>&1
        else
            yt-dlp -U --newline -f 'bestaudio' --extract-audio --audio-format mp3 \
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
        # Download video
        yt-dlp -U --newline -f 'bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]' \
        -o "$save_path/%(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s" \
        --exec "echo %(filepath)s > $save_path/filename.txt" "$video_url" > "$progress_pipe" 2>&1
    else
        # Download audio as mp3
        yt-dlp -U --newline -f 'bestaudio' --extract-audio --audio-format mp3 \
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
