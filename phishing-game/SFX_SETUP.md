# SFX Manager Setup Instructions

## 1. Add to AutoLoad
To make the SFX Manager available globally across all screens:

1. Open **Project → Project Settings**
2. Go to the **AutoLoad** tab
3. Click the folder icon next to "Path"
4. Navigate to `res://globals/sfx_manager.gd` and select it
5. Set the "Node Name" to: `SfxManager`
6. Make sure "Enable" is checked
7. Click "Add"

## 2. Usage Examples

### Basic Usage
```gdscript
# Play UI sounds
SfxManager.play_ui_hover()      # For menu navigation
SfxManager.play_ui_select()     # For button clicks/selection

# Play countdown sounds
SfxManager.play_countdown()     # For "3", "2", "1"
SfxManager.play_countdown_ready() # For "GO!"

# Play custom sounds
var my_sound = preload("res://path/to/sound.wav")
SfxManager.play_sound(my_sound, "game")
```

### Volume Control
```gdscript
# Adjust volumes (0.0 to 1.0)
SfxManager.set_master_volume(0.8)
SfxManager.set_sfx_volume(0.7)
SfxManager.set_ui_volume(0.5)
```

### Utility Functions
```gdscript
# Stop all sounds
SfxManager.stop_all_sounds()

# Check if a sound is playing
if SfxManager.is_playing("ui"):
    print("UI sound is playing")
```

## 3. Adding New Sound Effects

1. Place your `.wav` or `.ogg` files in `res://assets/sounds/sfx/`
2. Add them to the SFX Manager by editing `globals/sfx_manager.gd`:

```gdscript
# Add to the preloaded sounds section
var new_sound: AudioStream = preload("res://assets/sounds/sfx/new_sound.wav")

# Add a function to play it
func play_new_sound():
    if new_sound:
        game_player.stream = new_sound
        game_player.play()
```

## 4. Current Integration

The SFX Manager is already integrated into:
- **Start Screen**: UI hover/select sounds for menu navigation
- **Tutorial Screen**: UI select sound for confirmation
- **Main Game**: Countdown sounds (3-2-1-GO!)

## 5. Recommended Sound Categories

- **UI Sounds**: Menu navigation, button clicks, confirmations
- **Game Sounds**: Correct/incorrect answers, score updates, life lost
- **Countdown Sounds**: Number countdown, game start
- **Ambient**: Background effects, transitions

## 6. Performance Notes

- Sounds are preloaded for instant playback
- Multiple AudioStreamPlayer nodes prevent sound cutting off
- Uses linear_to_db() for proper volume scaling
- Minimal memory footprint with efficient sound management
