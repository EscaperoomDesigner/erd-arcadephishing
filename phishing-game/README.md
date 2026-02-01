# Phishing Game Setup Instructions

## External Phishing Folder Setup

This game loads phishing images from an external folder, allowing you to update the content without re-exporting the game.

### Required Folder Structure

Create a folder called `phishing` next to the game executable with the following structure:

```
phishing_game.exe
phishing/
├── bad/           (phishing/malicious images - PNG files)
│   ├── 1.png
│   ├── 2.png
│   └── ...
├── good/          (legitimate images - PNG files)
│   ├── 1.png
│   ├── 2.png
│   └── ...
└── bad_solution/  (solution images for phishing examples - PNG files)
    ├── 1m.png     (solution for bad/1.png)
    ├── 2m.png     (solution for bad/2.png)
    └── ...
```

### Image Requirements

- **Format**: All images must be PNG files
- **Bad folder**: Contains phishing/malicious website screenshots
- **Good folder**: Contains legitimate website screenshots
- **Bad solution folder**: Contains annotated versions of the bad images showing why they're phishing (filename should match the bad image with 'm' suffix)

### Example Structure

```
Game Folder/
├── phishing_game.exe
└── phishing/
    ├── bad/
    │   ├── 1.png        (phishing example)
    │   ├── 2.png        (phishing example)
    │   └── 3.png        (phishing example)
    ├── good/
    │   ├── 1.png        (legitimate example)
    │   ├── 2.png        (legitimate example)
    │   └── 3.png        (legitimate example)
    └── bad_solution/
        ├── 1m.png       (solution for bad/1.png)
        ├── 2m.png       (solution for bad/2.png)
        └── 3m.png       (solution for bad/3.png)
```

### Troubleshooting

If the game shows "No images were loaded!", check:

1. The `phishing` folder exists next to the executable
2. The subfolders `bad`, `good`, and `bad_solution` exist
3. The folders contain PNG files
4. File permissions allow the game to read the files

The game will show debug messages in the console when running to help identify any issues.