## 2026-04-05
- QOL: Remove "output" text showing above TUI after script finishes running
---
## 2026-03-22
- Suppress useless kdialog warning: "qt.qpa.services: Failed to register with host portal QDBusError("org.freedesktop.portal.Error.Failed", "Could not register app ID: Connection already associated with an application ID")". TUI works fine regardless
---
## 2026-02-03
- Hotfix for an error with deno. Script now uses `--extractor-args "youtube:player_js_variant=tv"`. This change will be kept as long as it works
---
## 2026-02-01
- Integrated SponsorBlock, to some extent (see the new Settings tab for existing options. More settings may be added in the future)
- Script will now create and write to file `$HOME/.config/ytdlp_settings` to keep current/future settings options persistent across instances
---
## 2026-01-04
- Add support for downloading thumbnails for single videos, playlists, and entire channels
- Channel downloads now support audio, video, and thumbnails (refer to ["About Selecting Video Quality"](https://github.com/sl1pstream/generic-youtube-video-downloader?tab=readme-ov-file#about-selecting-video-quality) in README.md)
---
## 2026-01-13
- For single videos/audio, displays title on completion
- For channel downloads, display channel name on completion
- For avatar downloads, use fzf window and displays channel name on completion
- Fixed Clip (unsure why this broke in the first place lol). Also displays title on completion
---
## 2025-12-08
- **All dialog windows now use `fzf`**. This allows showing the verbose output of downloads instead of the buggy progress bar that wouldn't tell you when the script returned an error (also, it's better on the eyes). Fzf also allows for typing in the selection menus (a kind of search feature), or you can double-click on the options (used to be single-click with the old layout)
- **Fixed audio downloading** - audio files are now downloaded as m4a files. This seems to be a change on yt-dlp's side (possibly a YouTube side change?)
