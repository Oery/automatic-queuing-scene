# AutoQueuingScene

AQS or AutoQueuingScene is a script for OBS Studio that automatically switches scenes when queuing for a Bedwars game in Minecraft. It provides a seamless transition between scenes during the queuing process, game start, and game finish.

Currently supports Bedwars, Skywars, Murder Mystery, TNT Games

## Prerequisites

- OBS Studio: Make sure you have OBS Studio installed on your system.
- Hypixel Lang: Hypixel must be set to english for the script to work.

## Installation

1. Go to the [Releases](https://github.com/oery/automatic-queuing-scene/releases) section of the repository.
2. Download the latest version of the .lua script file.
3. Open OBS Studio.
4. Go to "Tools" > "Scripts".
5. Click on the "+" button under the "Scripts" window.
6. Browse and select the .lua file you downloaded.
7. Click on "OK" to add the script.
8. Customize the settings in the "Scripts" window.

## Configuration

The script provides the following configuration options:

- **Enable Script**: Toggle to enable or disable the script.
- **Minecraft Client**: Select the Minecraft client you are using from the dropdown list.
- **Queuing Scene**: Select the scene to switch to during the queuing process.
- **Custom Logs Path**: If you selected "Custom" as the Minecraft client, enter the path to the custom logs file.
- **Delay after win (s)**: Set the delay in seconds to wait after the game finishes before switching scenes. A delay too low will hide the win screen.
- **Hide Screen in lobbies**: Toggle to hide the screen in lobbies. Useful to hide the map you're about to queue.

## Usage

1. Launch Minecraft and start queuing for a Bedwars game.
2. The script will automatically detect the queuing process and switch to the queuing scene configured in the settings.
3. When the game starts, the script will switch to the game scene.
4. After the game finishes, there will be a delay (as configured) before switching back to the queuing scene.

Note: Make sure to set up the scenes in OBS Studio and configure the scene names correctly in the script settings.

## Customization

You can customize the script behavior by modifying the variables and logic within the script file (`automatic-queuing-scene-v1.lua`).

## Troubleshooting

If the script is not working as expected, try the following steps:

1. Double-check that the scene names in OBS Studio match the scene names configured in the script settings.
2. Verify that the Minecraft client you are using is selected correctly in the script settings.
3. Ensure that the custom logs path is correct (if using the "Custom" Minecraft client option).
4. Check the OBS Studio console or logs for any error messages related to the script.

## Credits

This script was developed by Oery.

## License

The script is released under the [MIT License](LICENSE). Feel free to modify and distribute it according to the terms of the license.
