# Notes for Claude

A Safari Web Extension wrapping the FrankerFaceZ userscript. See `README.md`
for what it is and how it installs.

## Layout

Xcode 16 synchronized folders, so files are picked up from disk rather than
listed individually. Each target keeps an explicit `membershipExceptions` list
in `project.pbxproj` naming the files it builds. **Adding or removing a file
under `Shared (Extension)/Resources` means editing both of those lists**, one
for the iOS target and one for macOS. Folders added wholesale (`images`,
`_locales`) appear as a single entry, so files inside them need no change.

The extension ships four things: `content.js`, `manifest.json`, `images`, and
`_locales`. There is no background script and no popup.

`SafariWebExtensionHandler.swift` is the bundle's entry point named in
`Info.plist`, so it must stay even though nothing sends it a native message.

## content.js is vendored, keep it verbatim

It is FrankerFaceZ's published injector
(`https://cdn2.frankerfacez.com/script/ffz_injector.user.js`), byte for byte,
so it can be updated by downloading the new version over the top. Do not tidy
it.

Most of it cannot run here: the settings provider needs `GM.*` and
`unsafeWindow`, which exist in Tampermonkey and Greasemonkey but not in a
Safari extension. Those lookups throw, get swallowed by the surrounding
try/catch, and log one warning plus one error per page. That noise is the
accepted price of keeping the file syncable.

The part that matters is `ffz_init()`, which appends a `<script>` tag pointing
at FrankerFaceZ's CDN. After that FrankerFaceZ is a page script, outside the
extension entirely — which is why revoking the extension's site access does
not unload it from a page that already has it.

## Icons

`Shared (Extension)/Resources/images/icon-*.png` are **one colour with the
shape in the alpha channel**. Safari treats a monochrome icon as a template:
it discards the colour and fills the shape to suit the toolbar, which is what
makes it work on light, dark and site-tinted toolbars. Adding a second colour
silently breaks that. `icon-64.png` exists but the manifest does not reference
it.

The app's icons are the opposite and must keep their purple ground.
`Assets.xcassets/AppIcon` macOS entries sit inside a margin with their own
rounded corners; the iOS entries are edge to edge, and the light one must have
no alpha channel or the App Store rejects it. `Resources/Icon.png` is drawn by
`Main.html` in a web view whose stylesheet sets `color-scheme: light dark`, so
it needs its own background to stay visible.

All of them derive from `https://www.frankerfacez.com/static/images/logo.png`,
which is 256px — the only genuine size. Anything larger is enlarged.

## Releasing

Two files declare the version and a tagged build refuses to run unless they
agree with the tag:

1. Bump `"version"` in `Shared (Extension)/Resources/manifest.json` and
   `MARKETING_VERSION` in `project.pbxproj`.
2. Commit.
3. `git tag -a v1.1 -m v1.1 && git push origin v1.1`

`Scripts/check-version.sh <tag>` is what enforces that, and runs first in CI.
`.github/workflows/release.yml` then builds on a macOS runner and publishes a
GitHub Release with the zip attached. Running the workflow by hand instead
produces only an artifact and no Release.

`Scripts/release.sh` does the same locally: archive, export with Developer ID,
notarise, staple, zip into `build/`. It needs a Developer ID Application
certificate and either a `notarytool` keychain profile named `FrankerFaceZ` or
`NOTARY_APPLE_ID` and `NOTARY_PASSWORD` in the environment. Only the Account
Holder of an Apple team can create a Developer ID certificate; Admins cannot.

The archive names the signing identity explicitly, because the project's
day-to-day setting is automatic "Apple Development" and a release machine has
only the Developer ID certificate.

## Checking a change

```sh
xcodebuild -project FrankerFaceZ.xcodeproj -scheme "FrankerFaceZ (macOS)" \
    -configuration Debug -destination "platform=macOS" build
```

Safari cannot be driven from the shell to confirm injection: the extension's
on/off state lives in a container macOS blocks, and `do JavaScript` needs
"Allow JavaScript from Apple Events" enabled by hand in Safari's settings. Ask
rather than assume it works.

If the app's Dock icon looks wrong after a change, it is LaunchServices caching
it. Re-register the bundle with `lsregister -f -R -trusted` and restart the
Dock.
