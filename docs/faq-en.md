# Syphon FAQ

## What makes Syphon "privacy focussed"?

The following are some of the benefits we find core to Syphon. Some may overlap with other clients now but some were unique to Syphon as a mobile client for a while (like Multi-Accounts)

- Read Receipts off by default (privacy)
- Focus on minimal metadata transfer (privacy)
- Lack of any analytics or such libraries (privacy)
- App Lock with encryption (privacy)
- Separate encrypted storages per Multi-Account (privacy)
- Proxy support (privacy)

- Simple and modern default UI (ease-of-use)
- Extreme customisability (ease-of-use)
- Focus on P2P when it's mature enough (privacy, security, resilience)
- Custom Matrix library (finer control which contributes to privacy and security)
- Flutter (cross platform / ease-of-use)

## Where is [X] feature?

Syphon is currently in early development. Whilst we believe the code to be of a standard where we can share with a wider userbase, Syphon does not rely on public Matrix libraries, instead coding against [the Matrix specification](https://spec.matrix.org/latest/).
  
This means that Syphon is currently missing features found in other Matrix chat clients as the development team work to implement them.

[Syphon's feature roadmap can be found here](https://syphon.org/roadmap).

## [X] feature is acting strange/my settings aren't saved

Syphon is currently in open alpha, meaning development is currently rapid so each release consists of quite a "jump" in features.
  
In the first instance, if you've updated your client and are experiencing "weird" behaviour, please **uninstall** your local version and **clean install** the app with its latest version to ensure any local settings files are recreated at their latest settings.
  
If you're still encountering errors or weird behaviour, you've probably encountered a bug so please ask for help!

## How do I...

### ...Verify my session?

The option to manually/non-interactively verify sessions has been "hidden" in recent Element client releases.

In order to cross-sign/verify your Syphon session, with the Element client:

1. Open any chat you're in - though to make your life easier the smaller the better
1. Click the ![](images/info.png) button in the top-right to show room information
1. Click ![](images/people.png)
1. Click on your name (if you're in a large room, you may have to search)
1. Click on the untrusted session ![](images/syphon_not_trusted.png)
1. Click "Manually Verify By Text" ![](images/verify.png)
1. Compare the text between the two devices, and **only** accept if they match

n.b. Interactive cross-signing is [roadmapped](https://syphon.org/roadmap) as part of the `0.3.0` release.

### ...Get Notifications?

Notifications are currently **Android-Only**.
  
Like most features in Syphon, notifications are disabled by default.

### ...Send Read Receipts?

Like most features in Syphon, Read Receipts are disabled by default and must be enabled in the Settings.

### ...Decrypt past messages?

- Export your keys from Element: 
  - Settings > Security & Privacy > Cryptography
  - Export E2E room keys (this will generate element-keys.txt)
- Send element-key.txt to your phone
- Import the keys to Syphon:
  - Settings > Privacy & Security > Encryption Keys
  - Import Keys (select element-keys.txt)

n.b. Key sharing is [roadmapped](https://syphon.org/roadmap) as part of the `0.3.0` release.
