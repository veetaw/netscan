# Netscan

[![Checks](https://github.com/veetaw/netscan/actions/workflows/ci.yml/badge.svg)](https://github.com/veetaw/netscan/actions/workflows/ci.yml) [![MIT license](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Understand the devices on your home network and what to do next. Netscan is a free, open-source Flutter app with English and Italian interfaces, local scanning, evidence-based findings and practical security guidance. No account or scanning server is required.

A scan reports what it observed and what remains unknown. An open port is not automatically a vulnerability; no findings is not a guarantee of safety.

## What you can do

- **Find advertised devices** using native Bonjour / Android NSD, then select a device to inspect. Services include HTTP(S), RTSP, SSH, SMB, Google Cast, AirPlay and HomeKit. Silent devices can be entered manually.
- **Inspect services** with bounded TCP checks, passive SSH/Telnet/FTP greetings, ONVIF product information, and RTSP checks without viewing video.
- **Review UPnP** and read up to eight forwarding mappings from a compatible gateway. No router settings are changed.
- **Check access from outside** using the installed mobile app on cellular data and your connection’s dedicated public IPv4, without a Netscan scanning server.
- **Keep a local inventory**, assign trusted / IoT / guest labels, and compare observations from consecutive checks. Saving between sessions is optional.
- **Import Netscan JSON and Nmap XML locally**. Imported observations remain clearly identified; importing never starts a scan.
- **Search NVD** and compare confirmed product details against reviewed local advisory rules. Local rules currently cover specific TP-Link, ASUS and Hikvision products; other NVD results remain candidates.
- **Look up CISA KEV and FIRST EPSS** on request to understand exploitation context, with feed dates and unknown states when information is unavailable.
- **Follow a practical guide** for router administration, camera cloud/P2P access, forwarding, segmentation, Wi-Fi, accounts, updates and recovery.
- **Start on the web**, import reports or try a limited HTTP check, then open the installed app with the selected private IP. Links never start a scan automatically.

Read the [exact scan coverage and limitations](docs/scanning.md), [supported advisory rules](docs/advisory-rules.md), and [research and product comparisons](docs/related-work.md).

## Run it

Requires Flutter **3.44.4 / Dart 3.12.2** or a compatible environment. Dependency versions are locked. Bonjour and connectivity packages are intentionally pinned to a mutually compatible set for this SDK.

```sh
flutter pub get
flutter run -d chrome       # web light
flutter run -d macos        # installed desktop app
flutter devices            # find a connected phone
flutter run -d <device-id>
```

On the original development machine, Flutter is at `/Users/vito/flutter/bin/flutter`.

For discovery, connect to a network you own or are authorised to assess and grant local network permission. On Linux, native service discovery also needs the system’s supported mDNS service. Discovery only sees supported services advertised on the reachable network; it does not enumerate every device or traverse VLANs.

## Packages

The [Build packages workflow](https://github.com/veetaw/netscan/actions/workflows/build-release.yml) builds Android APK, a Windows x64 `.exe` installer and a macOS `.dmg`, including checksums and signing information. Run it manually or push a `v*` tag. It uploads workflow artifacts; it does not automatically publish a GitHub Release or an app-store listing.

See [packaging and signing](docs/releases.md). Without project signing credentials, the Android artifact uses a development key, Windows is unsigned, and macOS is ad-hoc signed without Apple notarisation. These states are recorded in each artifact’s `SIGNING.txt`.

## Privacy

| Operation | What leaves the device |
| --- | --- |
| LAN discovery and service checks | Requests to devices on the selected local network |
| Optional external check | Requests from your phone to the dedicated public IPv4 you authorise |
| Local advisory rules, report import and inventory comparison | Nothing |
| NVD search | Manufacturer/model search text and your public IP, sent to NIST |
| KEV lookup | Public IP when downloading the full CISA catalog from GitHub |
| EPSS lookup | Selected CVE IDs and public IP, sent to FIRST |
| Opening a source or download link | Normal browser connection to that site |

No analytics, advertising, cloud inventory or automatic vulnerability lookups. Inventory is held in memory by default. Optional device storage is not encrypted by Netscan and may be included in OS backups. Exported reports and clipboard data may contain private or public network addresses. The web build bundles its rendering resources rather than requiring the Google rendering CDN.

Netscan does not claim regulatory compliance or security certification. Distribution requirements depend on the actual offering, operator and data flows.

## Development

```sh
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
```

Tests cover real local TCP/UDP and simulated RTSP/ONVIF/UPnP services, conservative version matching, feed failures, report import boundaries, change comparison, deep-link validation, and English/Italian layouts at 320, 768, 1024 and 1440 pixels. Protocol fixtures do not replace tests against real routers and cameras or mobile permission flows.

Localisation sources are in `assets/l10n/en.json` and `assets/l10n/it.json`. To regenerate the compiled catalog:

```sh
python3 scripts/generate_localizations.py
dart format lib/l10n/catalog.dart
```

The interface follows the device language with English fallback and an in-app language selector. Original third-party advisory descriptions remain in their source language.

## License

[MIT](LICENSE). Third-party dependencies retain their own licenses, available through the app’s license viewer. Nmap is not bundled; Netscan imports its XML format.
