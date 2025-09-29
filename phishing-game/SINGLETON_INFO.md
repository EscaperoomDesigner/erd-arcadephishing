# PhishingResourceManager Singleton

This document explains the new singleton structure for managing phishing game resources.

## Overview

The `PhishingResourceManager` is a global singleton that handles:
- Loading phishing images from external or internal folders
- Managing solution images
- Providing texture loading functionality
- Centralizing resource management across the game

## Files Created/Modified

### New Files:
- `globals/phishing_resource_manager.gd` - The main singleton script
- Added to `project.godot` autoload section

### Modified Files:
- `screens/phishing_display/phishing_display.gd` - Now uses the singleton instead of local resource loading
- `project.godot` - Added PhishingResourceManager to autoloads

## Key Features

### 1. External Folder Support
- Automatically detects external `phishing` folder next to executable
- Falls back to internal `res://assets/phishing` if external folder not found
- Handles both external files and internal resources seamlessly

### 2. Centralized Resource Management
- Single point of control for all phishing-related assets
- Reusable across multiple scenes
- Consistent error handling and logging

### 3. Async Loading with Signals
- `images_loaded()` - Emitted when all resources load successfully
- `loading_failed(error_message)` - Emitted if resource loading fails
- Non-blocking resource loading

## API Reference

### Methods:
- `load_all_resources()` - Initiates loading of all phishing resources
- `get_images()` - Returns array of loaded image data
- `get_solutions()` - Returns dictionary of solution data
- `has_solution(id: String)` - Check if solution exists for given ID
- `load_texture(path: String, is_external: bool)` - Load texture from path
- `get_solution_info(id: String)` - Get solution data for specific ID

### Signals:
- `images_loaded()` - All resources loaded successfully
- `loading_failed(error_message: String)` - Resource loading failed

## Usage Example

```gdscript
func _ready():
    # Connect to signals
    PhishingResourceManager.images_loaded.connect(_on_images_loaded)
    PhishingResourceManager.loading_failed.connect(_on_loading_failed)
    
    # Start loading
    PhishingResourceManager.load_all_resources()

func _on_images_loaded():
    # Get resources
    var images = PhishingResourceManager.get_images()
    var solutions = PhishingResourceManager.get_solutions()
    # Start game logic...

func _on_loading_failed(error: String):
    print("Failed to load resources: ", error)
    # Handle error (show error screen, return to menu, etc.)
```

## Benefits

1. **Reusability**: Can be used by any scene that needs phishing resources
2. **Maintainability**: All resource loading logic in one place
3. **Flexibility**: Supports both external and internal resources
4. **Error Handling**: Comprehensive error handling and user feedback
5. **Performance**: Resources loaded once and shared across scenes

## Next Steps

After Godot recognizes the new singleton (may require editor restart), you can replace the temporary `get_node("/root/PhishingResourceManager")` calls with direct `PhishingResourceManager` references.