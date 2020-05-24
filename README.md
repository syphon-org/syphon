# Tether

A privacy centric messenger for the people

## Why


## Todo
- SVG Icons
- Finish .env selection
- Loader screen with animations

## From Scatch 
Another reason this project was so important was the ability to go from zero to usable open-source cross-platform app as soon as possible. The more accessible a platform is, the easier it is for people to create alternatives to tools that may be prohibited, discouraged, or just daunting. 

## Before Hitting The Code
- Urls are always referencing matrix mxc:// protocol resources. Though they're actually URIs, they are referenced as URLs in the app to be consistant with the protocol spec

## Architecture
### Storage
There are three layers to storage in Tether:
    - Remote (Matrix Homeserver)
    - Cache (Redux + Redux Persist +  Hive)
        * cache is encrypted at rest
    - Cold Storage (Hive)


## Getting Started
- (Redux Tutorial)[https://www.netguru.com/codestories/-implement-redux-with-flutter-app]
- (Redux Examples)[https://github.com/brianegan/flutter_architecture_samples/blob/master/firestore_redux/lib/selectors/selectors.dart]

## Resources
- (Paid Icon)[https://thenounproject.com/search/?q=polygon&i=2596282]
- (iOS icons)[https://github.com/smallmuou/ios-icon-generator]

## Layouts and Styling
- (Scrolling With Text Inputs)[https://github.com/flutter/flutter/issues/13339]