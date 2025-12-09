---
## 2025-12-08
- **All dialog windows now use `fzf`**. This allows showing the verbose output of downloads instead of the buggy progress bar that wouldn't tell you when the script returned an error (also, it's better on the eyes)
- **Fixed audio downloading** - audio files are now downloaded as m4a files. This seems to be a change on yt-dlp's side (possibly a YouTube side change?)
