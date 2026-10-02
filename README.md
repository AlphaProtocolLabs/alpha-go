# Alpha GO

Alpha GO is the mobile app for [Alpha Protocol Network](https://www.alphaprotocol.network): private networks on hardware you own, joined to a global mesh.

**Status: in testing.** The Android app is open to download.

**Known issue in 1.5.0 and 1.6.0: the Bitcoin wallet does not work.** The wallet's native library was left out of these builds, so creating or importing a wallet fails, no bitcoin address is shown, and the app asks you to set up a wallet again each time it starts. Do not rely on these builds to hold bitcoin. The event guide, account, chats and VIBE features do not depend on it. A fixed build is being prepared.

 The mesh network features are still being built, so today the app talks to its backend over the internet like any other app.

- Download for Android: https://go.alphaprotocol.network/download
- Web version (no install): https://go.alphaprotocol.network
- Releases and checksums: https://github.com/AlphaProtocolLabs/alpha-go/releases

## What is in this build

- One account shared with the web guide at go.alphaprotocol.network: profile, saved events, check-ins and testnet VIBE
- An event map with a day and time dial. Pins appear while an event is on or about to start. The current guide covers TOKEN2049 Singapore 2026
- A searchable list of every event, with filters for day, type, saved and free
- Register, get directions, save, and check in on site to earn testnet VIBE
- A self-custody Bitcoin wallet (mainnet): not working in 1.5.0 and 1.6.0, see the known issue above
- A read-only testnet VIBE balance on Aptos, from an account derived from the same recovery phrase
- Chats and direct messages with other members, and Topsi, an in-app assistant paid for in VIBE
- Send VIBE to other members, and withdraw bought VIBE to your own Aptos testnet wallet. VIBE earned for signing up, checking in or inviting people can be spent in the app but not sent or withdrawn

Not in this build: the mesh features (phone-to-phone links, relaying). Those are planned.

## Verify a download

Releases are signed with the Alpha Protocol Labs key.

```
Signing certificate SHA-256:
8f5791ad9c812ba0266972972f294a46a41baa2153cb37aeb7de73aa16b79c85
```

Check a file with `apksigner verify --print-certs <file>.apk`, and compare its SHA-256 with `SHA256SUMS.txt` on the release.

## VIBE

VIBE is live on the Aptos testnet:
[`0x24cb561c…d65388::vibe_token`](https://explorer.aptoslabs.com/account/0x24cb561c64c32942eb8600d5135f0185c23bcd06cd8cf33422ce2f9b77d65388/modules/code/vibe_token?network=testnet).
Testnet VIBE is for use inside the Alpha Protocol ecosystem. It is not a share, a security or a promise of future value.

## Build it yourself

You need Flutter 3.44 or newer and the Android SDK.

1. Copy `.env.example` to `.env` and fill it in:
   - `API_BASE`: the Alpha GO backend, `https://go.alphaprotocol.network`
   - `MAPBOX_TOKEN`: a public Mapbox token (`pk.…`)
   - `MAPBOX_STYLE_URL`: a Mapbox style, for example `mapbox://styles/mapbox/dark-v11`
   - `ORDISCAN_API_KEY`: optional, can stay empty
2. `flutter pub get`
3. `flutter run`, or `flutter build apk --release --split-per-abi`

A release build is signed with your own key if `ALPHA_GO_KEY_PROPERTIES` points to a properties file with `storeFile`, `storePassword`, `keyAlias` and `keyPassword`. Without it the build falls back to the debug key, which is fine for testing and wrong for distribution.

Run the tests with `flutter test`.

## Branches

`release-prep` holds the current release. `main` is the earlier demo line. This repository continues the original work at [M4dhav/alpha-go](https://github.com/M4dhav/alpha-go).

## Who builds it

The Alpha GO app was built by Madhav Gupta. Alpha Protocol Network was founded by Jessy Artman and is designed, built and operated by [Powerclub Global](https://powerclubglobal.com).

Found a problem? Open an issue here, or tell us in the [Telegram group](https://t.me/+ccm4dRdIdVsxYmYx). Contact: apn@powerclubglobal.com
