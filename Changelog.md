## 2025-12-08
- **All dialog windows now use `fzf`**. This allows showing the verbose output of downloads instead of the buggy progress bar that wouldn't tell you when the script returned an error (also, it's better on the eyes). Fzf also allows for typing in the selection menus (a kind of search feature), or you can double-click on the options (used to be single-click with the old layout)
- **Fixed audio downloading** - audio files are now downloaded as m4a files. This seems to be a change on yt-dlp's side (possibly a YouTube side change?)
