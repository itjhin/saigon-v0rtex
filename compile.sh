#!/bin/bash
echo "[*] Compiling Saïgon.."
$(which xcodebuild) clean build CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" -sdk `xcrun --sdk iphoneos --show-sdk-path` -arch arm64
mv build/Release-iphoneos/saigon.app saigon.app
mkdir Payload
mv saigon.app Payload/saigon.app
echo "[*] Zipping into .ipa"
zip -r9 Saigon.ipa Payload/saigon.app
rm -rf build Payload
echo "[*] Done! Install .ipa with Impactor"
