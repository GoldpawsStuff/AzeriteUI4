# AzeriteUI Change Log
All notable changes to this project will be documented in this file. Be aware that the [Unreleased] features are not yet available in the official tagged builds.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

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
