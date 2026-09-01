# FrankerFaceZ for Safari

A Safari Web Extension that loads [FrankerFaceZ](https://www.frankerfacez.com/)
on Twitch.

FrankerFaceZ does not ship a Safari build. Its own advice to Safari users is to
install a userscript manager such as Tampermonkey and load the FrankerFaceZ
userscript through that. This extension does the same job on its own, so no
userscript manager is needed.

Add-ons work as they do elsewhere, including 7TV Emotes, which is enabled from
FrankerFaceZ's own control centre rather than here.

## Install

Download the latest `FrankerFaceZ-v*.zip` from
[Releases](https://github.com/kimberninger/frankerfacez-safari/releases), then:

1. Unzip it and drag `FrankerFaceZ.app` to your Applications folder.
2. Launch the app once. It registers the extension with Safari and then tells
   you whether the extension is on.
3. In Safari, open Settings → Extensions and switch on **FrankerFaceZ**.
4. Give it access to Twitch. The extension's toolbar button is where Safari
   offers that, so if you have hidden the button, use the website access
   dropdown in Settings → Extensions instead.

Builds are signed with a Developer ID certificate and notarised by Apple, so
they open without warnings and without enabling anything in Safari's Develop
menu.

## What it does

A content script runs on `*.twitch.tv` and adds a `<script>` tag pointing at
FrankerFaceZ's CDN, which is how FrankerFaceZ itself loads. Everything after
that is FrankerFaceZ, running as an ordinary page script and updating itself
from the CDN. The extension holds no copy of FrankerFaceZ and requests no
permissions beyond access to Twitch.

Safari shows a toolbar button for the extension. That button belongs to Safari,
not to this extension: it indicates whether the extension can see the current
page and is where per-site access is granted. Clicking it does nothing else,
because the extension adds no interface of its own. It can be removed from the
toolbar by right-clicking the toolbar and choosing Customise Toolbar.

## Build from source

Requires Xcode and a macOS machine.

```sh
open FrankerFaceZ.xcodeproj
```

Build and run the **FrankerFaceZ (macOS)** scheme. A locally built app is
signed for development, so Safari will only load its extension while
Develop → Allow Unsigned Extensions is ticked, and that resets whenever Safari
restarts. Enable the Develop menu under Settings → Advanced → "Show features
for web developers".

To produce a signed, notarised build instead, see `Scripts/release.sh`.
