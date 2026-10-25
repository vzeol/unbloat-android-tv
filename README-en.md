# Toshiba (Vestel) Android TV kit: faster, without ads

**TOSHIBA / VESTEL COSMOS EDITION** — A lightweight home and reversible debloat, tested on a Toshiba 43QA4163DG.

[Français](README.md) · **English**


> [!WARNING]
> **Personal project shared as is, without any warranty.** I am not responsible for problems its use might cause to your TV, devices or data. Every TV is different: check your model and read the profile first.

## Which TV?

The profile was **tested on a real unit in October 2026**: **Toshiba 43QA4163DG**, a 2022 QLED 4K TV made by Vestel. It runs **Android TV 11 (SDK 30), not Google TV**, security patch **2025-08-01**. Hardware tests and measurements below were supplied from this unit; this edition’s scripts are checked offline with mocks.

Check the rear label, then **Settings → Device Preferences → About**. Option **1** also displays the firmware fingerprint:

```text
Vestel/Cosmos170/yeoksam:11/RTOC.251019.001/14296264:user/release-keys
```

| Observed identification | Value |
|---|---|
| Android manufacturer / brand | `Vestel` / `Vestel` |
| Android model / device / product | `Cosmos` / `yeoksam` / `Cosmos170` |
| Memory | 1.3 GB (`MemTotal 1368668 kB`), 512 MB zram, `ro.config.low_ram=true` |
| CPU / ABI | MediaTek, 4 cores, `armeabi-v7a` (32-bit) |
| `/data` storage | 4.2 GB, previously 85% full |
| UI | 1920 × 1080 at 60 Hz only, despite the 4K panel |
| Video | HDR10, HLG, Dolby Vision; hardware H.264, HEVC, VP9, MPEG-2, VC-1 and Dolby Vision decoding |
| AV1 | Software only, too slow on this TV |

The 50/55/65QA4163DG models are **probably** similar: compare fingerprints. Vestel ships this firmware under Toshiba, JVC, Hitachi, Telefunken and other badges. The fingerprint matches the Spain-market unit in [CleanYourTV’s examples/toshiba-cosmos-android-tv](https://github.com/Gathin23/cleanyourtv/tree/main/examples/toshiba-cosmos-android-tv). This does not establish testing on every variant.

Detection requires manufacturer **or** brand Vestel, plus device `yeoksam` **or** model `Cosmos`. A different fingerprint triggers a warning to read [the profile](scripts/profils/toshiba-cosmos.txt) first.

Other Android TVs still use the **generic lists**, retaining other brands’ lists and code paths. This is an MIT fork of [xMazaki/unbloat-android-tv](https://github.com/xMazaki/unbloat-android-tv). Toshiba results do not predict results on another TV. Fire TV retains the original project’s restrictions on replacing its home screen.

## Measured results

Idle on home, around 8–13 minutes after reboot under the same conditions, except readings explicitly taken after 9 days without rebooting. Rounded observations, not a guarantee of identical gains.

| Measurement | Before | After |
|---|---|---|
| Available RAM | ~470 MB | ~520 MB |
| Used zram swap | ~230 MB | ~164 MB |
| Home memory | 127 MB shortly after boot; 212 MB + 30 MB swap after 9 days | Zen Home: 48 MB with photos; **35 MB with black background**, 4 large tiles |
| Memory actually used by apps (`dumpsys meminfo`, “used pss”) | 870 MB after 9 days | 587 MB |
| Free storage | 683 MB | ~1 GB **after manually uninstalling unused apps** |

The kit disables packages; it does not uninstall them. The storage gain is not due to disabling alone. Android deliberately caches about 300 MB of recent apps for instant relaunch, so “available RAM” understates the gain.

The biggest felt improvement: the TV is usable as soon as home appears after power-on, and no longer slows down over days in this unit’s tests.

## Prepare the TV (5 minutes)

1. Wake the TV and connect it to the same local network as the computer.
2. Open **Settings → Device Preferences → About**. Press **OK 7 times on “Build”**. French menus: **Paramètres → Préférences de l’appareil → À propos**.
3. Open **Developer options → USB debugging** (**Options pour les développeurs → Débogage USB**) and enable it.
4. On this Toshiba, USB debugging alone opens network ADB on **port 5555**. There is **no separate network/wireless debugging toggle** and no pairing step.
5. Find the network address in **Settings → Network**, or **About → Status**, and enter it in the kit. Accept the TV’s debugging authorisation prompt.

Wake the TV before each connection: Wi-Fi turns off in standby, disconnecting ADB. For other brands, use their firmware’s debugging settings; pairing remains supported where available.

## Use the kit

Extract the whole kit into a folder. Keep `scripts/`, `ecran-accueil/` and the launchers together. On first run the kit downloads official Google ADB tools if they are not already installed.

| Computer | Start |
|---|---|
| Windows | Double-click `LANCER.bat` |
| macOS | Open `LANCER.command` (right-click → Open if needed) |
| Linux | `./LANCER.sh`; if needed, `bash LANCER.sh` |

Follow **1 → 2 → 3 → 4 (optional)**:

1. **Diagnosis + backup.** Check the model, fingerprint and “Tested profile detected: Toshiba / Vestel Cosmos (43QA4163DG)” message.
2. **Slim down → Follow the tested profile (recommended).** Only present, enabled packages are offered. One confirmation covers a batch’s automatic items. Answer **no** to “Do you use…?” to disable an optional feature. The tested unit’s personal choices are not imposed. Test each batch. Answering **n** to “Everything works?” re-enables only packages just disabled in that batch and stops the profile. Earlier batches remain applied. Store demo is handled alone with an immediate Input test.
3. **Install Zen Home.** Default layout: **4 large tiles**. The profile defaults to offering a black background (35 MB versus 48 MB with photos). Check Zen Home and inputs before agreeing to disable the old home. This firmware refuses another default home while its own remains enabled: the kit opens Zen Home for a preview, then disables the old home and checks the result. `com.google.android.tvlauncher` and `com.google.android.tvrecommendations` are handled only by option 3. This home batch has its own rollback. “Hide risky tiles”, then “Text-to-speech” follow, preserving the tested order. Option 2 can also offer these batches when Zen Home is already the default home.
4. **Photos (optional).** Put landscape pictures in `mes_photos/` (1920 × 1080 recommended), then use option 4. It also offers black background or restoring bundled photos. Black background replaces custom photos on the TV.

**Play Protect:** Zen Home (`targetSdk 24`) may show **“Appli non sécurisée bloquée”** in the French UI. Choose **“Plus de détails” → “Installer quand même”** (“More details” → “Install anyway”). Simply pressing **OK cancels installation**. Run option 3 again if cancelled.

To edit Zen Home later, long-press OK or use “Edit home”. The **TV inputs** tile recognises `com.mediatek.wwtv.tvcenter`; the remote’s **Input** key also works with Zen Home on the tested unit.

## What the profile disables

See [scripts/profils/toshiba-cosmos.txt](scripts/profils/toshiba-cosmos.txt) for bilingual entries and tests. Nothing is uninstalled. Each changed batch requires its test before continuing. After-Zen-Home batches are deferred until the home is installed and verified.

### Telemetry and useless services

| Package | Function | Why | Mode |
|---|---|---|---|
| `com.vestel.vestelreporter` | Vestel reports | Reports are not needed for TV operation. | Automatic, after batch confirmation |
| `android.autoinstalls.config.vestel.cosmos` | Partner auto-installs | Avoids partner auto-installs. | Automatic, after batch confirmation |
| `com.google.android.feedback` | Google feedback reports | Optional feedback reports. | Automatic, after batch confirmation |
| `com.google.android.syncadapters.calendar` | Calendar sync | No calendar used on this TV. | Automatic, after batch confirmation |
| `com.android.printspooler` | Print service | No printing from the TV. | Automatic, after batch confirmation |
| `com.google.android.apps.nbu.smartconnect.tv` | Smart Connect (data meter and VPN) | Unused service. | Automatic, after batch confirmation |
| `com.google.android.play.games` | Google Play Games | Google gaming service unused. | Automatic, after batch confirmation |
| `com.google.android.videos` | Google Play Movies | Google movie service unused. | Automatic, after batch confirmation |

### Unused features: your choices

| Package | Function | Why | Mode |
|---|---|---|---|
| `com.google.android.katniss` | Google Assistant (Hey Google from phone or Nest) | No remote microphone; keep it if you use Hey Google from a phone/Nest. | Question: no to disable |
| `com.google.android.youtube.tvmusic` | YouTube Music | Choose based on music use. | Question: no to disable |
| `com.mediatek.wwtv.mediaplayer` | MediaTek USB player | Keep it if you use this USB player. | Question: no to disable |
| `com.mediatek.tv.freeviewplay` | UK Freeview Play guide | UK guide unused on the tested unit. | Question: no to disable |
| `com.cltv.fast` | Ad-supported FAST channels (not live TV) | Ad-supported channels, separate from live TV. | Automatic, after batch confirmation |
| `com.google.android.backdrop` | Google ambient screensaver | Google ambient background unused. | Question: no to disable |

### Store demo: immediate Input test

| Package | Function | Why | Mode |
|---|---|---|---|
| `fusion.android.tv.demo` | Store demo (may handle Input on other boards) | Unneeded demo here; Input risk on some MTC boards. | Separately + immediate test |

### Batch 3 — Zen Home

The home batch belongs exclusively to **option 3**:

| Package | Function | Why | Mode |
|---|---|---|---|
| `com.google.android.tvlauncher` | Classic Android TV home | Ads and memory growth over time | Confirmation after Zen Home preview |
| `com.google.android.tvrecommendations` | Old home recommendations | Unneeded with Zen Home | With home batch, after verification |

### Hide risky tiles

| Package | Function | Why | Mode |
|---|---|---|---|
| `com.vestel.tv.eib` | Vestel electronic manual | Hides the manual if you do not use it. | Question: no to disable |
| `com.vestel.tv.speedup` | System Speed Up (unnecessary cleaner) | Removes the cleaner and its tile. | Automatic, after batch confirmation |
| `com.mstar.android.tv.disclaimercustomization` | First-setup disclaimer | Disclaimer for a setup already completed. | Automatic, after batch confirmation |
| `mediatek.factorymenu.ui` | Factory menu screens (not the com.mediatek.tv.factory service) | Avoids accidental factory changes; keeps the factory service. | Question: no to disable |

### Text-to-speech

| Package | Function | Why | Mode |
|---|---|---|---|
| `com.google.android.tts` | Google text-to-speech (accessibility) | Only if no accessibility feature needs it. | Question: no to disable |

Already disabled before testing: `com.google.android.marvin.talkback`, `com.google.android.tv.remote.service` and these `uk.co.freeview.*` packages: `mdsclient`, `amc_catchup`, `onnow`, `uktv`, `fvpconfigauth`, `bbc_sounds`, `tifbridge`, `explore`, `bbc`, `ch5`, `itv`, `stv`, `amc_horror`, `ch4_vod`. The profile leaves them as they are and never automatically re-enables them, including during batch rollback.

## What stays, and why

| Kept package | Why |
|---|---|
| `com.mediatek.wwtv.tvcenter` | Live TV, HDMI and Input key: protected |
| `com.google.android.apps.mediashell` | Chromecast kept; optional in generic mode |
| `com.google.android.youtube.tv` | YouTube used and dedicated remote button |
| `com.amazon.amazonvideo.livingroom` | Prime Video used and dedicated remote button |
| `com.netflix.ninja` | Netflix used and dedicated remote button |
| `com.mediatek.wwtv.webview` | Untested HbbTV browser, left alone |
| `com.google.android.leanbacklauncher.partnercustomizer` | Prevents tv.service crash loops and loss of Input key |
| `com.google.android.tungsten.setupwraith` | System setup helper kept on Cosmos |
| `com.vestel.tv.service` | Core Vestel service |
| `com.vestel.tv.servicepatch` | Vestel service patches |
| `com.vestel.tv.keycontroller` | Remote key handling |
| `com.vestel.tv.backlight` | Backlight control |
| `com.vestel.tv.rcupdater` | Remote updater |
| `com.mediatek.tv.service` | Core TV service and Netflix observer |
| `com.mediatek.tvinput` | TV inputs |
| `com.mediatek.tv.factory` | Background factory service: never touch |
| `com.mediatek.tvinputservice.arbitratorservice` | Input arbitration |
| `com.mediatek.network` | MediaTek networking |
| `com.android.vending` | Play Store |
| `com.google.android.gms` | Google Play Services |
| `com.google.android.inputmethod.latin` | Gboard keyboard |

TV plumbing in this table is protected in both scripts, alongside existing protections for settings, Play Store, Google services, keyboard and other essentials. Chromecast is not protected: generic optional lists can remove it by choice. Existing Google TV fallback handling for `setupwraith` remains available through option 3 on other TVs; **Cosmos always keeps it**.

Two harmless entries cannot be hidden from All apps: **“com.mstar.netflixobserver”**, an activity inside `com.mediatek.tv.service` (probably the Netflix remote key), and **“Service API Vestel”**, `com.vestel.tv.service/.PasswordDialogActivity`. Do not disable their services to hide them. This firmware refuses shell changes to individual system-app components (“Shell cannot change component state”).

## Known pitfalls on this TV

| Item | What to know |
|---|---|
| IR remote, no microphone | Assistant is only useful here for Hey Google from a phone/Nest, depending on use. |
| YouTube / Prime Video buttons | Handled by Vestel firmware below Android. Disabled app = dead button; they cannot be remapped. |
| Input key | Test after batches, especially `fusion.android.tv.demo`. Never disable `tvcenter`, `partnercustomizer` or TV services. `com.cltv.fast` is not live TV. |
| Play Protect | More details → Install anyway. OK alone cancels. |
| Screenshots | `screencap` emits junk before PNG data (“Init wrapper sys mutex successful…”, “open mma dev failed”). The kit keeps the on-TV file + pull method, not `exec-out screencap -p`. |
| Standby | Wi-Fi turns off; wake the TV before reconnecting ADB. |
| Developer options | Turn off only USB debugging at the end. The master switch resets animation scales and background process limit. |
| Animations | Already 0.0 on this unit. The kit never raises them; only values above 0.5 are reduced. |
| Freeview | Packages may already be disabled on non-UK units. Leave them that way if everything works. |
| HbbTV | Disabling `com.mediatek.wwtv.webview` was not tested, so it stays untouched. |

## After the kit

Optional, **by hand**: **Developer options → Background process limit → 2**. This was a good compromise on 1.3 GB. **0** cold-starts every app and loses its place. The kit does not force this setting.

At the end, turn off only **USB debugging**. Keep Developer options enabled to retain your settings. System updates remain enabled and may re-enable apps; option 1 reports packages re-enabled since the kit ran.

Optional apps to consider: SmartTube, LocalSend, Aerial Views.

## Undo

**Option 6** re-enables packages recorded by the kit, restores the original home and animation settings, and offers to uninstall Zen Home. It does not re-enable packages that were disabled before the kit. Batch rollback affects only that batch; failed re-enables stay recorded for retry with option 6.

Keep **`sauvegardes/<local identifier>/etat_kit.json`** and the backups. This state file records changed packages and original settings. The kit checks the TV’s identity before each action. Backups and `config_tv.json` contain private information and are ignored by Git: **do not share them**. They are generated locally during use; no personal device records from the tested TV are included in this edition.

Without a computer: **Settings → Apps → See all apps → Show system apps → select app → Enable**. As a last resort, a **factory reset re-enables everything**, while also erasing accounts, apps and settings.

## Disclaimer

This kit is a personal project, shared for free **as is, without any warranty**. By using it, you accept that:

- **I am not responsible** for any problem, failure, data loss, malfunction or voided warranty that its use may cause, directly or indirectly;
- you use it **at your own risk**, on a device that you own;
- it is up to you to check that the kit suits your TV before using it, and to adapt it if needed (see “Which TV?” and the profile).

The kit is not affiliated with or endorsed by Toshiba, Vestel, Google, TCL, Sony, Philips, Xiaomi, Amazon or any other manufacturer. Brand names mentioned belong to their owners.

## Credits and license

- **Original project:** [xMazaki/unbloat-android-tv](https://github.com/xMazaki/unbloat-android-tv), MIT. Other brands remain supported; neither the Zen Home APK nor its Java sources are modified by this edition.
- **Vestel reference:** [CleanYourTV, examples/toshiba-cosmos-android-tv](https://github.com/Gathin23/cleanyourtv/tree/main/examples/toshiba-cosmos-android-tv), matching fingerprint on a Spain-market unit.
- **Generic lists:** [Universal Android Debloater NG](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation), [CleanYourTV](https://github.com/Gathin23/cleanyourtv), [shield_optimizer](https://github.com/bryanroscoe/shield_optimizer), [dumbtv](https://github.com/humblemuzzu/dumbtv) and community guides.
- **Photos:** 19 Wikimedia Commons Featured pictures, CC BY-SA. Existing attributions are preserved in [CREDITS.md](CREDITS.md).
- **Font:** Poppins, SIL Open Font License.
- **ADB:** Google’s Android SDK Platform-Tools, downloaded from the official site on first run.
- **Kit and Zen Home code:** MIT, see [LICENSE](LICENSE).
