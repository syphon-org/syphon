# Syphon Release Checklist

- [ ] Bump version in [Pubspec](../pubspec.yaml)
- [ ] Update [FDroid Change Log](../fastlane/metadata/android/en-US/changelogs) 
- [ ] Merge `dev` to `main`
- [ ] Build `android` release and `macos` release locally
- [ ] Create github draft with attached change log
- [ ] Copy `linux` nightly release to the github draft
- [ ] Copy `android` release and `macos` release to the github draft
- [ ] Finalize and publish draft github release
- [ ] Bump [FDroid Version.txt](../version.txt) 
- [ ] Release through Google Play Console
- [ ] Release through App Store Connect
