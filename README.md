# CS:GO Cheat Revealer (1.0.0)
A plugin for Counter-Strike: Global Offensive that detects if players have used cheats.

## Features
- Checks players' Steam IDs against a cheat detection API
- Caches results for the duration of the map
- Notifies players if cheats are detected
- Rate limiting to prevent API abuse (10 requests per 10 seconds)
- Skips bots and invalid clients

## Configuration
The plugin uses a config file located at `addons/sourcemod/configs/revealer.cfg`:
You can read more here: https://docs.alyx.ro/authorization

```
"Revealer"
{
    "api_key"    "YOUR_API_KEY_HERE"
}
```

## API Integration
This plugin uses the Alyx Network API to detect cheats. The API returns information about whether a player has used cheats in the past.

## Requirements
- SourceMod 1.11 or higher
- ripext extension (https://github.com/ErikMinekus/sm-ripext)
- Counter-Strike: Global Offensive
- Valid API key from Alyx Network

## Installation
1. Ensure SourceMod and ripext extension are installed
2. Copy the plugin to `addons/sourcemod/plugins/`
3. Create or edit the config file in `addons/sourcemod/configs/revealer.cfg`
4. Set your API key in the config file
5. Restart the server or reload plugins

## How It Works
1. When a player connects, the plugin checks if they've been cached
2. If not cached, it makes an API request to check for cheats
3. Results are cached for the duration of the map
4. Players detected with cheats will receive a notification

## Notes
- Plugin version: 1.0.0
- Author: dragos112

## You can test this plugin on our servers! Take a look: alyx.ro/servers
