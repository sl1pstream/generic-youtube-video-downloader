# A Generic YouTube Video Downloader

***Now includes video quality selection***

[Click here for the latest changes to ytdlp.sh](https://github.com/sl1pstream/generic-youtube-video-downloader/blob/main/Changelog.md)

A bash script TUI for Arch Linux (*possibly* Windows) that can download YouTube videos, or just audio from videos (with a few options to choose from)

*Note*: This script was made largely with the help of multiple coding AIs, specifically GPT-4, as well as the following coding extensions on VSCode: CodeBuddy, Codeium, Amazon Q. Please understand that while I can confirm that the script is not malicious, you bear the burden of risk by running anonymous scripts you find on the internet. I am only posting this as a proof-of-concept after spending months brainstorming features and troubleshooting.

The script will also auto-update yt-dlp for you before the media download begins. While this ensures you are always up to date with the latest yt-dlp and minimizes the chances of running into erros due to an outdated version, you can disable this by opening the script file and removing all of the -U flags from the download commands, if you feel the need.

### Why?
Because those "download YouTube videos" websites don't stay up forever (most have liimted options anyway), are ad-filled, and all have different UIs that you have to adapt to just to forget them when they inevitably disappear and get replaced.

# Screenshots
![1](https://github.com/user-attachments/assets/9225bf1c-3cc4-4d71-91b6-cb5c12198e43)

![2](https://github.com/user-attachments/assets/c0187e61-b6f0-49d9-86db-801e6d05c3fa)

![3](https://github.com/user-attachments/assets/77ea2b85-f91f-46e5-877a-fca55101b637)

![4](https://github.com/user-attachments/assets/740622b1-3d12-4cf4-9827-6dc821bb7c3e)





# Requirements
### System Requirements:

- Linux system or equivalent (instructions for setting up WSL2 below, a virtual machine may also work)

### Required Software:

- `yt-dlp` - YouTube downloader tool

- `dialog` - Text-based user interface utility

- `kdialog` - KDE dialog utility

- `firefox` - Browser for cookie extraction (**Note that you must be signed into YouTube on Firefox**)

- `mktemp` and `mkfifo` - System utilities for temporary files and named pipes

# Usage

### For Linux Users

**If you already have this repo cloned, skip to step 3.** Run the following in terminal:
1. Clone this repo: `git clone https://github.com/sl1pstream/generic-youtube-video-downloader.git`
2. Set the directory: `cd generic-youtube-video-downloader`
3. (Optional) Update all files: `git pull --all`
4. Make the script executable: `chmod +x ytdlp.sh` (only required on first run)
5. Run: `./ytdlp.sh`

### For Windows Users (WSL Setup)

Since this is a bash script designed for Arch Linux, Windows users need to set up WSL2 with Arch:

1. **Enable WSL2**: Open PowerShell as Administrator and run:
   ```powershell
   wsl --install
   ```
2. **Install Arch Linux**: Download and install Arch Linux WSL from the Microsoft Store or use:
   ```powershell
   wsl --install -d ArchLinux
   ```
3. **Restart your computer** when prompted
4. **Set up Arch Linux**: After restart, create a username and password when prompted
5. **Install prerequisites** in Arch Linux terminal:
   ```bash
   sudo pacman -Syu
   sudo pacman -S yt-dlp dialog kdialog firefox git
   ```
(You can skip installing Firefox if you remove all the `---cookies-from-browser firefox` flags in the script. _Downside: if you get rate limited or flagged for potential bot behavior, you will have to add them back, install Firefox in WSL, and sign into YouTube with it._)
   
5. **Continue with the Linux instructions above**

### Other Linux Distros
Install `boxbuddy` and set up an Arch Linux environment, and install the prerequisites (see "Required Software" above).

### About Selecting Video Quality
- **Single Video, Clip:** Some videos have less qualities available to download vs stream. HD options will still be available
- **Playlist, Channel, Custom:**
  - For any maximum quality, if a video is not available in that quality, it will choose the next lowest one
  - If the max quality selected is lower than the minimum quality available for a video, the lowest quality will be downloaded

---
The script itself is fairly intuitive to use, and most options throughout the script have basic descriptions that tells users what each one does. If you are knowledgeable in coding (specifically bash), you are free to read through the code to see how each part works.

**Please direct all yt-dlp related issues to the [yt-dlp repo](https://github.com/yt-dlp/yt-dlp). I am not responsible for issues with the tool itself, nor am I a very experienced coder/dev. I make scripts every now and then at best**
