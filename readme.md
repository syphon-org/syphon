<br>

<p align='center'>
<img height="128"  src="assets/logo/current/app_logo_cyan.svg"/>
</p>

<p align='center'>
a privacy centric matrix client - now in open alpha*
</p>
 
<p align='center'>
    <a href='https://play.google.com/store/apps/details?id=org.tether.tether'>
        <img  height="56"  alt='Get it on Google Play' style="padding-right:8px;" src='assets/external/en_badge_web_generic.png' />
    </a>
    <a href='https://apps.apple.com/us/app/syphon/id1496285352'>
        <img height="56" alt='Download on the App Store' style="padding-right:8px;" src='assets/external/download_on_the_app_store.svg'/>
    </a>
    <a href='https://f-droid.org/packages/org.tether.tether/'>
        <img height="56" src="assets/external/get-it-on-fdroid.png">
    </a>
</p>

<br>

<p align='center'>
    <img src="https://img.shields.io/github/license/syphon-org/syphon?color=teal"/>
    <img src="https://img.shields.io/github/v/release/syphon-org/syphon?include_prereleases&color=teal"/>
    <img src="https://img.shields.io/github/commits-since/syphon-org/syphon/0.1.13?color=teal"/> 
    <a href="https://pub.dev/packages/lint">
        <img src="https://img.shields.io/badge/style-lint-4BC0F5.svg?color=teal"/> 
    </a>
    <a href="https://github.com/syphon-org/syphon/releases">
        <img src="https://img.shields.io/github/downloads/syphon-org/syphon/total?color=teal"/>  
    </a>
    <a href="https://matrix.to/#/#syphon:matrix.org">
        <img src="https://img.shields.io/matrix/syphon:matrix.org?color=teal&logo=matrix"/>
    </a>
    <a href="https://hosted.weblate.org/engage/syphon/">
      <img src="https://hosted.weblate.org/widgets/syphon/-/svg-badge.svg" alt="Translation status" />
    </a>
</p>

<p align='center'> 
    <img src="assets/screenshots/01-android-tiny.png"/>
    <img src="assets/screenshots/03-android-tiny.png"/>
    <img src="assets/screenshots/05-android-tiny.png"/> 
</p>

<p align='center'>
 Syphon is still in alpha and we <b>do not recommend</b><br> 
 using it where proven and independently verified security is required.
</p>
<br>

## 🤔 Why

**Syphon aims to be built on the foundations of privacy, branding, and user experience** 
<br>in an effort to pull others away from proprietary chat platforms to the matrix protocol.

Matrix has the potential to be a standardized peer-to-peer chat protocol, [and in a way already is,](https://matrix.org/blog/2020/06/02/introducing-p-2-p-matrix) that allows people to communicate and control their conversation data. Email has been standardized in this way for a long time. For example, someone using Outlook can still email someone using Gmail. Most popular proprietary chat platforms do not adhere to a federated or decentralized protocol, and as a result have too much control over users data.

If the goal for Matrix is adoption, a network effect is required for this paradigm shift. Syphon makes the bet that the best way to attract new users is through strong branding and user experience. I hope that contributing and maintaining Syphon will help kick start this process and help those in need. 

Syphon will always be a not for profit, community driven application.

## ✨ Features
- no analytics. period.
- no proprietary third party services
    - iOS will have APNS support, but will be made clear to the user
- all data is AES-256 encrypted at rest
- E2EE for direct chats using [Olm/Megolm](https://gitlab.matrix.org/matrix-org/olm)
- all indicators of presence are opt-in only (typing indicators, read receipts, etc)
- customize themes and colors throughout the app

## 🚀 Goals
- [x] desktop clients meet parity with mobile
- [ ] screen lock and pin protected cache features
- [ ] P2P messaging through a locally run server on the client
- [ ] allow transfering user data from one homeserver to another, or from local to remote servers 
- [ ] cli client using ncurses and the same redux store contained here (common)
 
## 🌙 Nightlies
- Nightly dev builds - per pushed commit builds - can be found under our [Gitea Releases](https://git.syphon.org/syphon-org/syphon/releases)
- Unofficial "community" Windows x64 releases can be found under [@EdGeraghty's fork](https://github.com/EdGeraghty/syphon/releases)

## 📝 Contributing
- Instructions can be found under our [contributing.md](./contributing.md). Please fully read the document before beginning to write code or produce any material contribution for Syphon.
- Donations are always welcome! The best way to donate is through the [Syphon creator's Patreon](https://patreon.com/ereio).
- Coming soon, we'll have a merch store! If you'd like to support the project but want a little something in return, this is the way to do it!

## 🏗️ Building
You may notice Syphon does not look very dart-y (for example, no \_private variable declarations, or using redux instead of provider) in an effort to reduce the learning curve from other languages or platforms. The faster one can get people contributing, the easier it will be for others to maintain or oversee a tool that does not exploit the user.

### general
- you'll to do several things to setup the environment for Syphon
    - install flutter (stable channel for all platforms)
    - install necessary third party sdks and tooling
        - ios -> xcode
        - android -> android studio
    - install cmake version for workstation platform (for olm/megolm)
        - [macos](https://cmake.org/files/v3.10/cmake-3.10.2-Darwin-x86_64.dmg) 
        - [linux](https://cmake.org/files/v3.10/cmake-3.10.2-Linux-x86_64.sh)
        - [windows](https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=Community&rel=16)
    - install libs needed for cmake
        - macos -> ```brew install ninja```
        - linux -> ```sudo apt install ninja-build```
        - windows -> ```choco install ninja```
    - clone repo and init submodules
        - ```git submodule update --init --recursive```
    - run the following prebuild commands
        - ```flutter pub get```
        - ```flutter pub run build_runner build```

### ios/android
0. pull dependencies needed 
   - ```flutter pub get```
1. generate json conversion for models
   - ```flutter pub run build_runner build --delete-conflicting-outputs```
2. generate json conversion for models
   - ```flutter run```

### macos  
1. ```flutter config --enable-macos-desktop```
2. ```brew install libolm``` to install native olm dependencies
3. follow instructions for linking the dylib generated from brew to the Syphon project
  - refer to [macos dylib linking guide](https://flutter.dev/docs/development/platform-integration/c-interop#compiled-dynamic-library-macos)
4. ```flutter build macos``` to build the .app bundle

### linux
1. ```flutter config --enable-linux-desktop```
2. ```apt install libolm3 libsqlite3-dev``` or ```pacman -S libolm``` or platform equivalent for libolm
3. ```flutter build linux && flutter build bundle```
4. navigate to release at ```$SYPHON_ROOT/build/linux/release/bundle```
5. Confirm build works with running ```$SYPHON_ROOT/build/linux/release/bundle/syphon```

### windows
1. ```flutter doctor``` should give you warnings for anything missing
2. ```flutter config --enable-windows-desktop```
3. Compile olm & move `olm.dll` to `libolm.dll` in the executable directory
4. Fetch sqlite's **Precompiled Binaries for Windows** dll [from the website](https://www.sqlite.org/download.html)

## 📐 Architecture

### store
- views (flutter)
- state (redux)
- cache (redux_persist + json_serializable + [sembast](https://pub.dev/packages/sembast))
- storage (sembast + sqflite + [codec cipher](https://github.com/tekartik/sembast.dart/blob/master/sembast/doc/codec.md))

### assets
- Looking for branding or design files? They can all be found [here](https://github.com/syphon-org/syphon/tree/main/assets), in the top level assets folder.

### integrations
- Notifications
  - utitlizes [android_alarm_manager](https://pub.dev/packages?q=background_alarm_manager) on Android to run the matrix /sync requests in a background thread and display notifications with [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
  - no third party notification provider will ever be used outside Apples APNS for iOS only
- Equatable
  - This library allows comparisons of objects within Flutter to tell if they have changed.
- JsonSerializable
  - Unfortunately, Json is not integrated directly in Dart/Flutter for your own objects. Code generation is required, for now, and will convert Syphon's custom objects to a 'Map' of respective json fields
- Freezed (future)
  - Because every object in Syphon is immutable, freezed will help create objects doing the same thing all the 'copyWith' helper functions do today, with the improvement of allowing 'null' values to overwrite non-null values
- Fastline Directory
  - fastline is not used as tool, but is there to provide a schema of metadata to FDroid

### references
- [Redux vs. Bloc](https://github.com/ereio/state)
- [Redux Tutorial](https://www.netguru.com/codestories/-implement-redux-with-flutter-app)
- [Redux Examples](https://github.com/brianegan/flutter_architecture_samples/blob/master/firestore_redux/)
- [End-To-End Encryption implimentation guide from Matrix.org](https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide)
- [iOS file management flutter](https://stackoverflow.com/questions/55220612/how-to-save-a-text-file-in-external-storage-in-ios-using-flutter)
- [scrolling With Text Inputs](https://github.com/flutter/flutter/issues/13339)
- [multi-line text field](https://stackoverflow.com/questions/45900387/multi-line-textfield-in-flutter)
- [keyboard dismissal](https://stackoverflow.com/questions/55863766/how-to-prevent-keyboard-from-dismissing-on-pressing-submit-key-in-flutter)
- [changing transition styles](https://stackoverflow.com/questions/50196913/how-to-change-navigation-animation-using-flutter)
- [animations](https://flutter.dev/docs/development/ui/animations)
- [serialize Uint8List bytes](https://stackoverflow.com/questions/63716036/how-to-serialize-uint8list-to-json-with-json-annotation-in-dart)
- adding a border without needing ctrl-p
```dart
decoration: BoxDecoration(
   border: Border.all(width: 1, color: Colors.white),
),
```
- understanding why olm chose the world 'pickle' for serialization, [its from python](https://gitlab.matrix.org/matrix-org/olm/-/tree/master/python)

## from those who made it possible
lub youu
