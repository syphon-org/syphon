start: 
	make builder && flutter run # -d <device_id>
start-fresh: 
	flutter run --no-fast-start # -d <device_id>
devices: 
	flutter devices
install: 
	flutter pub get
builder: 
	make install && flutter pub run build_runner build --delete-conflicting-outputs
watch: 
	flutter pub run build_runner watch --delete-conflicting-outputs
uninstall: 
	adb shell && pm uninstall org.tether.tether # (sometimes doesn't uninstall when debugging?)
format: 
	flutter dartfmt --line-length=120 .

# environment
setup:
	make builder && git submodule update --init --recursive

# building
build-release-ios: 
	flutter build ipa  --release # open under xcworkspace, not xcodeproj
build-release-macos: 
	flutter pub run build_runner build --delete-conflicting-outputs && flutter build macos --release
build-release-android: 
	flutter pub run build_runner build --delete-conflicting-outputs && flutter build apk --release

# mobile development commands
setup-ios: 
	pod install && flutter precache --ios
clean-ios: 
	xcrun simctl delete unavailable
list-ios: 
	xcrun simctl list devices
boot-ios: 
	xcrun simctl boot #<device_id>
list-android: 
	emulator -list-avds
boot-android: 
	emulator -avd #<device_id>
inspect-android: 
	adb shell && run-as org.tether.tether # cache inspection
log-android: 
	adb logcat ActivityManager:I flutter:I *:S

# configuration and troubleshooting
reset-xcode: 
	defaults delete com.apple.dt.Xcode
dev-tools: 
	flutter pub global run devtools
cache-clean: 
	pub cache repair && flutter pub cache repair
upgrade-deps: 
	flutter pub upgrade --major-versions
init-platform-dirs: 
	flutter create --org org.tether.tether
enable-desktop: 
	flutter config --enable-macos-desktop --enable-linux-desktop # --no-enable-<type>-desktop
