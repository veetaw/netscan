# Building packages

[Build packages](https://github.com/veetaw/netscan/actions/workflows/build-release.yml) runs manually or on `v*` tags. It validates the app, then builds Android, Windows and macOS in separate jobs. The workflow has read-only repository permission and pins actions to reviewed commit SHAs.

Artifacts contain the package, MIT license, `SIGNING.txt` and SHA-256 checksums. Download them from the workflow run. Publishing a GitHub Release or an app-store listing is separate; this workflow does not do it automatically.

| Artifact | Contents |
| --- | --- |
| `netscan-android` | Installable release-mode APK. Uses a project release key if all signing secrets exist; otherwise a development/debug key, labelled in `SIGNING.txt`. |
| `netscan-windows-x64` | Inno Setup `.exe` installer with the executable, required DLLs and data. Installs per user and registers the `netscan:` scheme. Unsigned without a publisher certificate. |
| `netscan-macos` | `.dmg` containing the app and an Applications shortcut. Ad-hoc signed; no Developer ID certificate or Apple notarisation is configured. |

The initial multi-platform run completed successfully: [run 43211533794](https://github.com/veetaw/netscan/actions/runs/43211533794). Later changes must pass their own checks/builds; this link is not a claim about all future commits.

## Android release signing

Configure these repository Actions secrets together:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

Keep an independently protected backup of the keystore and credentials. The workflow decodes the key into the runner’s temporary directory and writes ignored Gradle properties; it does not print credentials or commit the key. Never upload a keystore through issues, logs or source files.

Without these secrets, generated development keys can differ between runs. Android may refuse to update an existing installation signed by a different key. A stable release identity requires a stable project keystore.

## Windows and macOS signing

The installer and disk image can be built without paid signing identities. Windows publisher signing and macOS Developer ID/notarisation require distributor-owned credentials and a separate release configuration. No developer certificate or account credentials are embedded in this repository.

## Local web build

```sh
flutter build web --no-web-resources-cdn
```

Serve the `build/web` directory over HTTPS for public use. Browser local-network operations still depend on browser policy, CORS and device certificates. The web-to-app button requires the installed application and operating-system scheme registration.

## Versioning

Package versions come from `pubspec.yaml`. Keep release tags and the package version consistent. No production signing status is inferred from a Git tag alone.
