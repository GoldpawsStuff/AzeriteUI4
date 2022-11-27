[![patreon](https://www.goldpawsstuff.com/shared/img/common/pa-button.png)](https://www.patreon.com/goldpawsstuff)
[![paypal](https://www.goldpawsstuff.com/shared/img/common/pp-button.png)](https://www.paypal.me/goldpawsstuff)
[![discord](https://www.goldpawsstuff.com/shared/img/common/dd-button.png)](https://discord.gg/MUSfWXd)
[![twitter](https://www.goldpawsstuff.com/shared/img/common/tw-button.png)](https://twitter.com/GoldpawsStuff)

Work in progress. You probably have questions. I'll answer a few:

- Yes, I killed the EditMode on purpose.
- Yes, the chat frames will be made movable in retail too.
- Yes, I plan to make a config menu instead of these chat commands.
- Yes, the config menu will allow you to manually disable nearly every module in the UI.
- Yes, I will be making boss-, raid- and arena frames.
- No, I will not be adding `/go legacy`for the alternate theme. If anything I'll release a version of that as another standalone UI. But I will no longer attempt to integrate multiple UIs into a single addon.
- Yes, I do accept donations and will love you for it. Links above.

## Chat Commands
Note that the following commands do NOT work while engaged in combat. All settings are stored in the addons saved settings.

### Action Bars
Change actionbar settings like enabled bars, number of buttons and fading.
- **/setbuttons \<bar\> \<numbuttons\>** - Sets number of visible buttons on a bar. *(7-12 for bar 1, 1-12 for bar 2.)*
- **/enablebar \<bar\>** - Enable a bar. *(1 = primary, 2 = bottom left bar in the blizz UI.)*
- **/disablebar \<bar\>** - Disable a bar.
- **/enablebarfade** - Enable bar fading.
- **/disablebarfade** - Disable bar fading, keeping buttons always visible.

### Movable Frames
Toggle movable frames. *(Frames can be reset to default position when they are unlocked.)*
- **/lock** - Hide frame anchors, disabling movement.
- **/unlock** - Show frame anchors, enabling movement.
- **/togglelock** - Toggle frame anchors.

### Scale
Change the relative scale of the custom user interface elements created by the addon.
- **/setscale n** - Set the scale to `n`. *(n = [0.75 to 1.25])*
- **/resetscale** - Resets the relative scale.

### Minimap Clock
Change how the time is displayed on the minimap.
- **/setclock**
  - **12** - Use a 12-hour AM/PM clock. *(default)*
  - **24** - Use a 24-hour clock.
  - **local** - Use local computer time. *(default)*
  - **realm** - Use the game server time.
