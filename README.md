# country_flour

country flour mobile app

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


Platform setup still needed
Android — add your google-services.json to android/app/ and ensure the SHA-1 fingerprint is registered in Google Cloud Console.

iOS — add the REVERSED_CLIENT_ID URL scheme from GoogleService-Info.plist to ios/Runner/Info.plist:

<key>CFBundleURLTypes</key>
<array>
<dict>
<key>CFBundleURLSchemes</key>
<array>
<string>YOUR_REVERSED_CLIENT_ID</string>
</array>
</dict>
</array>