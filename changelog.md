# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [0.2.7](https://github.com/syphon-org/syphon/releases/tag/0.2.6) - 2021-12-27


### Added
- removes exif information for image uploads

### Fixed
- fixed sending images from the quick select menu
- fixed inviting users to chats
- 


## [0.2.6](https://github.com/syphon-org/syphon/releases/tag/0.2.6) - 2021-12-27

### Fixed
- screen lock regression on confirming after toggled on

## [0.2.5](https://github.com/syphon-org/syphon/releases/tag/0.2.5) - 2021-12-24

### Fixed
- issue with chat colors and message details screens

## [0.2.4](https://github.com/syphon-org/syphon/releases/tag/0.2.4) - 2021-12-24

### Added 
- Screen Lock
- Pin Protected Encrypted Storage
- Improved Edit Message UI
- Improved Chat UI spacing
- UserID Quick Copy

### Fixed
- major performance improvements and optimizations
- fixed editing encrypted messages 
- fixed deleting encrypted messages
- fixed read receipts locally if toggled on
- fixed defaulting to device language
- fixed editing messages higher in the chat
- fixed opening links in Android 11
- fixed showing more icon in user previews
- fixed input text border regression

### Changed

## [0.1.6](https://github.com/syphon-org/syphon/releases/tag/0.1.5) - 20XX-XX-XX

### Added 
- cold storage backups of all essential cache stores (redundant / failover local backups)

### Fixed
- Fixed issue where avatar urls would load indefinitely if not found
- Fixed issue where login/signup information could get saved in the encrypted cache

### Changed

## [0.1.5](https://github.com/syphon-org/syphon/releases/tag/0.1.5) - 2020-12-15

### Added 
- Block users (removes direct chats and hides messages)

### Fixed
- Lots of improvements in regards to storing data and initial sign in
- Overhauled caching again for performance and desktop client support

### Changed 
- Old cache management (hive) was removed, may need to sign out/sign in

## [0.1.4](https://github.com/syphon-org/syphon/releases/tag/0.1.4) - 2020-10-28

### Added
- Invite Friends from Chat Menu (if allowed to)
- Avatars can be set to square shape in Theme settings
- Much better Local Notification handling with room names

### Fixed
- Overhauled caching to solve lag on home screen
- Lazy loading data on the initial sync
- Uses can no longer send empty messages
- Users of homeservers with a forward slash "/" in their m.homeserver config can login
- Issues with room names appearing as the current user
- Issues with room avatars appearing as joined users
- Password restrictions on login were tied to signup password restrictions
- Intermittent syncing issues when not opening the app for a while
- Smaller bug fixes and performance improvements

## [0.1.3](https://github.com/syphon-org/syphon/releases/tag/0.1.3-4) - 2020-09-18

### Added
- New Icon!
- Native splash screens
- Better Performance on first load
- Toggle 24 Hour Time Format

### Fixed
- E2E had cross client pre-key sharing issues. Element to Syphon messages work again.
- Better anonymous, human readable device IDs that are still unique to your device.
- General bug fixes and performance improvements
- Other issues regarding FDroid deployments and auto updates


## [0.1.2](https://github.com/syphon-org/syphon/releases/tag/0.1.2) - 2020-08-11

### Added 
- Private group E2EE encryption*
- Create public and private groups - w/ photos
- User Profiles (both quick view and fullscreen
- Invite users to any joined room
- mark all messages read (locally or remotely)
- tons of code refactoring to help dev and performance
- a lot more (new fonts, colors, etc)

### Fixed
- Confirmation Alert Improvements
- Standardized view mounting and unmounting
- Disabled all non-available features in menus
- New Action Ring Icons

### Removed
- Dead clickable links in menus

## [0.0.23](https://github.com/syphon-org/syphon/releases/tag/0.0.23) - 2020-07-20
### Added
- hot fixes for FDroid and iOS publishing

## [0.0.21](https://github.com/syphon-org/syphon/releases/tag/0.0.21) - 2020-07-20
### Added
- opt-in read receipts
- signup email input and verification (working with matrix.org again)
- signup/login bug fixes, standardizing secure text inputs
- global error alerts and confirmations will show up
- better small screen UI scaling
- lots of code cleanup and refactoring
