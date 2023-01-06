# AzeriteUI4 for Wrath Classic Change Log
All notable changes to this project will be documented in this file. Be aware that the [Unreleased] features are not yet available in the official tagged builds.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [4.0.30-Release] 2023-01-06 (Wrath)
### Changed
- Player buffs now have a dark gray border, while debuffs should be colored by school of magic, if any.

## [4.0.29-Release] 2023-01-06 (Wrath)
### Fixed
- Fixed an issue with unit names in raid groups.

## [4.0.28-Release] 2022-12-29 (Wrath)
### Changed
- Removed a lot of redundant retail code.

### Fixed
- Fixed an issue that would cause the XP- and Reputation percentages on the minimap toggle button to never show up.
- Fixed an issue that would prevent the minimap ring bar from ever showing when Reputation was currently tracked.

## [4.0.27-Release] 2022-12-20 (Wrath)
### Fixed
- Bosses should no longer sometimes get a wooden target frame.

## [4.0.26-Release] 2022-12-17 (Wrath)
### Added
- The Wrath quest tracker is now movable as intended.

### Changed
- The command `/lock` now will toggle movable frame anchors, not just hide them. Reason? It's shorter and easier to write than the other commands.

## [4.0.25-Release] 2022-12-17
### Changed
- Increased the size of most tooltips by roughly ten percent, to make font sizes more on par with the rest of the on-screen text in the user interface.
- The target frame can no longer forcefully be faded out by immersion.

### Fixed
- The plus icon for MBB users have come out of hiding.

## [4.0.24-Release] 2022-12-11
### Changed
- Increased the allowed scale range with `/setscale`. Was *(n = [0.75 to 1.25])*, now is *(n = [0.5 to 1.5])*.

### Fixed
- The minimap shouldn't require a position reset to return to where it lives anymore.
- The editmode files will no longer wrongfully attempt to load themselves in wrath. Bad editmode files! Bad!

## [4.0.23-Release] 2022-12-10
### Changed
- We now allow the retail editmode to open, but have removed most of the blizzard frames from it.
- Since any change whatsoever to the retail objectuves tracker appears to be tainting the edit mode, we are neither sizing nor moving this frame any more. You'll have to do this yourself using the edit mode.
- Our own movable frame anchors now follow the retail editmode visibility.

### Fixed
- A lot more retail editmode taints were fixed.
- Possibly fixed missing extra button textures in retail.

## [4.0.22-Release] 2022-12-10
### Fixed
- Fixed actionbars SetAlpha issue related to mouseover visibility.
- Fixed a retail issue where a blizzard mixin would override our own pet button meta methods.

## [4.0.21-Release] 2022-12-09
### Fixed
- Chat bubble font sizes should now be more sane.

## [4.0.20-Release] 2022-12-09
### Changed
- Empty action buttons will remain invisible by default now. Their backdrops will become visible when an item or action is placed on the cursor.

## [4.0.19-Release] 2022-12-09
### Fixed
- Our micro menu module should no longer interfere with ConsolePort.

## [4.0.18-Release] 2022-12-08
### Changed
- The chat module will now auto-disable if the addons Prat or Glass are enabled.

### Fixed
- Fixed an issue with retail warlock class resource points like soul shards where the backdrop and point textures had been accidentally switched causing a rather ugly result.

## [4.0.17-Release] 2022-12-08
### Fixed
- Fixed faulty text color references when switching between protected and interruptable casts on the player- and target unitframes.

## [4.0.16-Release] 2022-12-07
### Fixed
- Fixed a fuckload of EditMode problems in retail.

## [4.0.15-Beta] 2022-12-07
### Fixed
- Fixed a bug related to faulty event registration when handling compatibility and interactions with Bartender4.

## [4.0.14-Beta] 2022-12-06
### Fixed
- Critter target frames should look less horrible now.
- Added a missing upvalue that would cause a nameplate bug each time you targeted something.
- The target highlight outline on the party frames are properly attached to the health bar now, and not the middle of the portrait.

## [4.0.13-Beta] 2022-12-02
### Changed
- We need some cheering up.

## [4.0.12-Beta] 2022-12-01
### Changed
- Updated TaintLess.xml to 22-11-27.

## [4.0.11-Beta] 2022-12-01
### Added
- Added chat bubble styling.

### Changed
- Updated Narcissus minimap button to match how it was in AzeriteUI3.

## [4.0.10-Beta] 2022-12-01
### Fixed
- Fixed minimap left clicks in retail.

## [4.0.9-Beta] 2022-11-28
### Fixed
- Fixed inconsistent action button text element handling and positioning.

## [4.0.8-Beta] 2022-11-28
### Fixed
- Fixed an issue where the nameplate castbar overlay would appear too small, not covering the entire health bar.

## [4.0.7-Beta] 2022-11-28
### Fixed
- Fixed a bug where protected casts appeared borderless, instead of with the spiked border as intended.

## [4.0.6-Beta] 2022-11-28
### Fixed
- Fixed a bug that would render primary action bar keybinds useless after leaving a vehicle or petbattle.

## [4.0.5-Beta] 2022-11-28
- No 4.0.4 build. It can't be found.

### Fixed
- Party frame layout should be slightly more sane now.

## [4.0.3-Beta] 2022-11-27
### Fixed
- Fixed the faulty arguments to a CreateTexture call in the boss frames that caused the previous build to bug out in retail.

## [4.0.2-Beta] 2022-11-27
### Added
- Added first draft of boss frames.

## [4.0.1-Beta] 2022-11-27
### Added
- Added first draft of party frames.

## [4.0.0-Alpha] 2022-11-25
- First public alpha.
