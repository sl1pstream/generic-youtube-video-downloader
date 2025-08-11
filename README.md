# generic-youtube-video-downloader
A bash script TUI for Arch Linux that can download YouTube videos, or just audio from videos (with a few options to choose from)

*Note*: This script was made largely with the help of multiple coding AIs, specifically GPT-4, as well as the following coding extensions on VSCode: CodeBuddy, Codeium, Amazon Q. Please understand that while I can confirm that the script is not malicious, you bear the burden of risk by running anonymous scripts you find on the internet. I am only posting this as a proof-of-concept after spending months brainstorming features and troubleshooting.

The script will also auto-update yt-dlp for you before the media download begins. While this ensures you are always up to date with the latest yt-dlp and minimizes the chances of running into erros due to an outdated version, you can disable this by opening the script file and removing all of the -U flags from the download commands, if you feel the need.

### Why?
Because those "download YouTube videos" websites don't stay up forever (most have liimted options anyway), are ad-filled, and all have different UIs that you have to adapt to just to forget them when they inevitably disappear and get replaced.

# Screenshots
![OnPaste 20250223-133357](https://github.com/user-attachments/assets/0543683b-9e32-4740-9902-d4cb257b4a22)
![OnPaste 20250223-133449](https://github.com/user-attachments/assets/06f37414-5bd5-4bfa-8c04-b19bad5d67a9)
![OnPaste 20250223-133632](https://github.com/user-attachments/assets/f39ca0fa-18d6-4c7a-b725-3ae85294fb97)




# Requirements
### System Requirements:

- Linux system or equivalent (virtual machine may work)

### Required Software:

- `yt-dlp` - YouTube downloader tool

- `dialog` - Text-based user interface utility

- `kdialog` - KDE dialog utility

- `firefox` - Browser (for cookie extraction)

- `mktemp` and `mkfifo` - System utilities for temporary files and named pipes

# Usage

**If you already have this repo cloned, skip to step 3.** Run the following in terminal:
1. Clone this repo: `git clone https://github.com/sl1pstream/generic-youtube-video-downloader.git`
2. Set the directory: `cd generic-youtube-video-downloader`
3. (Optional) Update all files: `git pull --all`
4. Make the script executable: `chmod +x ytdlp.sh` (only required on first run)
5. Run: `./ytdlp.sh`

The script itself is fairly intuitive to use, and most options throughout the script have basic descriptions that tells users what each one does. If you are knowledgeable in coding (specifically bash), you are free to read through the code to see how each part works.

**Please direct all yt-dlp related issues to the [yt-dlp repo](https://github.com/yt-dlp/yt-dlp). I am not responsible for issues with the tool itself, nor am I a very experienced coder/dev. I make scripts every now and then at best**
