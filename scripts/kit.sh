#!/usr/bin/env bash
# =====================================================================
#  Kit TV Toshiba / Vestel Cosmos - allègement réversible + écran d'accueil Zen Home
#  Toshiba / Vestel Cosmos kit - reversible debloat + Zen Home launcher
#  macOS / Linux (bash 3.2+)  -  lancé par LANCER.command ou LANCER.sh
#  Portage de kit.ps1 : mêmes listes, mêmes fichiers de sauvegarde.
# =====================================================================
KIT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$KIT/scripts"
TOOLS="$KIT/outils"
SAVES="$KIT/sauvegardes"
APK_PATH="$KIT/ecran-accueil/ZenHome.apk"
PHOTOS_DIR="$KIT/mes_photos"
CONF_FILE="$KIT/config_tv.json"
ZEN_PKG="tv.zenhome"
COSMOS_FINGERPRINT="Vestel/Cosmos170/yeoksam:11/RTOC.251019.001/14296264:user/release-keys"
GTV_FALLBACK="com.google.android.tungsten.setupwraith"   # accueil de secours de Google TV
mkdir -p "$TOOLS" "$SAVES"

LANG_FR=0
case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in fr*) LANG_FR=1 ;; esac
if [ "$(uname)" = "Darwin" ]; then
    case "$(defaults read -g AppleLocale 2>/dev/null)" in fr*) LANG_FR=1 ;; esac
fi

if [ -t 1 ]; then
    C_Gray=$'\033[0;37m'; C_DarkGray=$'\033[0;90m'; C_White=$'\033[1;37m'; C_Cyan=$'\033[0;36m'
    C_DarkCyan=$'\033[0;36m'; C_Green=$'\033[0;32m'; C_Yellow=$'\033[0;33m'; C_Red=$'\033[0;31m'; C_0=$'\033[0m'
else
    C_Gray=; C_DarkGray=; C_White=; C_Cyan=; C_DarkCyan=; C_Green=; C_Yellow=; C_Red=; C_0=
fi
color() { eval "printf '%s' \"\$C_$1\""; }

T()    { if [ "$LANG_FR" = 1 ]; then printf '%s' "$1"; else printf '%s' "$2"; fi; }
Say()  { printf '%s%s%s\n' "$(color "${3:-Gray}")" "$(T "$1" "$2")" "$C_0"; }
Ok()   { Say "  ✔ $1" "  ✔ $2" Green; }
Warn() { Say "  ! $1" "  ! $2" Yellow; }
Err()  { Say "  ✖ $1" "  ✖ $2" Red; }
Ask()  { local r; printf '%s: ' "$(T "$1" "$2")" >&2; IFS= read -r r; printf '%s' "$r"; }
YesNo() {
    local sfx r
    if [ "${3:-1}" = 1 ]; then sfx="$(T " [O/n]" " [Y/n]")"; else sfx="$(T " [o/N]" " [y/N]")"; fi
    printf '%s%s: ' "$(T "$1" "$2")" "$sfx" >&2
    IFS= read -r r
    r="$(printf '%s' "$r" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
    [ -z "$r" ] && { [ "${3:-1}" = 1 ]; return; }
    case "$r" in o|oui|y|yes) return 0 ;; *) return 1 ;; esac
}
Pause_Kit() { printf '\n%s' "$(T "Entrée pour revenir au menu" "Press Enter to go back to the menu")"; read -r _; }
trim() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
now()  { date +%Y%m%d_%H%M%S; }
open_path() { if command -v open >/dev/null 2>&1 && [ "$(uname)" = "Darwin" ]; then open "$1"; elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$1" >/dev/null 2>&1 & fi; }

# ---------------------------------------------------------------- JSON minimal
# Lit aussi les fichiers écrits par kit.ps1 (BOM, ConvertTo-Json multi-lignes).
BOM="$(printf '\357\273\277')"
json_flat() { LC_ALL=C sed "1s/^$BOM//" "$1" | tr -d '\r\n'; }
json_str() {
    json_flat "$1" | LC_ALL=C grep -oE "\"$2\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" | head -n 1 \
        | LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*"//' -e 's/"$//' -e 's/\\"/"/g' -e 's/\\\\/\\/g'
}
json_arr() {
    local flat; flat="$(json_flat "$1")"
    if printf '%s' "$flat" | grep -q "\"$2\"[[:space:]]*:[[:space:]]*\["; then
        printf '%s' "$flat" | LC_ALL=C grep -o "\"$2\"[[:space:]]*:[[:space:]]*\[[^]]*\]" | head -n 1 \
            | LC_ALL=C sed 's/^[^[]*\[//' | LC_ALL=C grep -o '"[^"]*"' | tr -d '"'
    else
        json_str "$1" "$2"
    fi
}
jq_s() { if [ -z "$1" ]; then printf 'null'; else printf '"%s"' "$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"; fi; }

# ---------------------------------------------------------------- ADB
Get_Adb() {
    local p="$TOOLS/platform-tools/adb" os zip
    if [ -x "$p" ]; then printf '%s' "$p"; return; fi
    if command -v adb >/dev/null 2>&1; then command -v adb; return; fi
    case "$(uname)" in Darwin) os=darwin ;; *) os=linux ;; esac
    Say "Téléchargement des outils ADB officiels de Google (environ 7 Mo)..." "Downloading Google's official ADB tools (about 7 MB)..." Cyan >&2
    zip="$TOOLS/platform-tools.zip"
    if command -v curl >/dev/null 2>&1; then curl -fsSL -o "$zip" "https://dl.google.com/android/repository/platform-tools-latest-$os.zip"
    else wget -q -O "$zip" "https://dl.google.com/android/repository/platform-tools-latest-$os.zip"; fi
    unzip -q -o "$zip" -d "$TOOLS" && rm -f "$zip"
    printf '%s' "$p"
}
ADB="$(Get_Adb)"
if [ ! -x "$ADB" ] && ! command -v "$ADB" >/dev/null 2>&1; then
    Err "ADB introuvable et téléchargement impossible (curl/wget et unzip nécessaires)." "ADB not found and download failed (curl/wget and unzip required)."
    exit 1
fi
T_=""      # ip:port de la TV
ID=""      # identifiant unique de la TV

A()    { "$ADB" -s "$T_" "$@" 2>&1 | tr -d '\r'; }
Sh()   { A shell "$1"; }
Prop() { trim "$(Sh "getprop $1" | tr -d '\n')"; }

Get_TvIdentity() {
    local serial aid id
    serial="$(Prop ro.serialno)"
    if [ -z "$serial" ] || [ "$serial" = "unknown" ]; then serial="$(Prop ro.boot.serialno)"; fi
    aid="$(trim "$(Sh "settings get secure android_id" | tr -d '\n')")"
    if [ -n "$serial" ] && [ "$serial" != "unknown" ]; then id="$serial"; else id="aid-$aid"; fi
    INFO_Id="$(printf '%s' "$id" | sed 's/[^A-Za-z0-9_-]/_/g')"
    INFO_Brand="$(Prop ro.product.brand)"; INFO_Model="$(Prop ro.product.model)"
    INFO_Manufacturer="$(Prop ro.product.manufacturer)"
    INFO_Device="$(Prop ro.product.device)"; INFO_Fingerprint="$(Prop ro.build.fingerprint)"
    INFO_Android="$(Prop ro.build.version.release)"; INFO_Sdk="$(Prop ro.build.version.sdk)"
    INFO_Patch="$(Prop ro.build.version.security_patch)"; INFO_Build="$(Prop ro.build.display.id)"
    INFO_Name="$(trim "$(Sh "settings get global device_name" | tr -d '\n')")"
}

Test_Cosmos() {
    local maker brand model device
    maker="$(printf '%s' "$INFO_Manufacturer" | tr '[:upper:]' '[:lower:]')"
    brand="$(printf '%s' "$INFO_Brand" | tr '[:upper:]' '[:lower:]')"
    model="$(printf '%s' "$INFO_Model" | tr '[:upper:]' '[:lower:]')"
    device="$(printf '%s' "$INFO_Device" | tr '[:upper:]' '[:lower:]')"
    { [ "$maker" = vestel ] || [ "$brand" = vestel ]; } && { [ "$device" = yeoksam ] || [ "$model" = cosmos ]; }
}
Show_Profile() {
    Test_Cosmos || return 0
    Say "Profil testé détecté : Toshiba / Vestel Cosmos (43QA4163DG)" "Tested profile detected: Toshiba / Vestel Cosmos (43QA4163DG)" Cyan
    if [ "$INFO_Fingerprint" != "$COSMOS_FINGERPRINT" ]; then
        Warn "Firmware différent de l'exemplaire testé : lisez scripts/profils/toshiba-cosmos.txt avant de continuer." "Firmware differs from the tested unit: read scripts/profils/toshiba-cosmos.txt before continuing."
    fi
}
Cosmos_Reminders() {
    Test_Cosmos || return 0
    Say "À la main : limite des processus en arrière-plan = 2 (facultatif ; 0 recharge chaque appli)." "By hand: background process limit = 2 (optional; 0 cold-starts every app)." Cyan
    Say "À la fin, coupez seulement « Débogage USB », pas tout « Options pour les développeurs » : cela réinitialise animations et limite des processus." "At the end, turn off only USB debugging, not Developer options: the master switch resets animations and the process limit." Yellow
}

Connect_Target() {
    local target="$1" i st out asked=0 refused=0 unreach=0
    case "$target" in *:*) ;; *) target="$target:5555" ;; esac
    T_="$target"
    i=0
    while [ $i -lt 60 ]; do
        out="$("$ADB" connect "$target" 2>&1 | tr -d '\r' | tr '\n' ' ')"
        st="$("$ADB" -s "$target" get-state 2>&1 | tr -d '\r\n')"
        case "$st" in device*) return 0 ;; esac
        # on distingue : TV joignable qui attend l'autorisation / TV qui refuse (débogage réseau inactif) / TV injoignable
        case "$out $st" in
            *unauthorized*|*authenticate*)
                [ $asked = 0 ] && { Say ">>> Regardez la TV : « Autoriser le débogage ? » doit s'afficher. Cochez « Toujours autoriser » puis OK." ">>> Look at the TV: 'Allow debugging?' should appear. Tick 'Always allow' then OK." Cyan; asked=1; } ;;
            *refused*|*10061*)
                refused=$((refused + 1))
                if [ $refused -ge 3 ]; then
                    Err "La TV répond mais refuse la connexion : son débogage réseau n'est pas actif." "The TV answers but refuses the connection: its network debugging is not enabled."
                    Say "   Toshiba Cosmos : activez seulement « Débogage USB » (port 5555), puis réveillez la TV. Autres TV : selon le modèle, Débogage ADB réseau ou Débogage sans fil avec jumelage." "   Toshiba Cosmos: enable only USB debugging (port 5555), then wake the TV. Other TVs: depending on model, Network ADB or Wireless debugging with pairing." DarkGray
                    return 1
                fi ;;
            *"timed out"*|*10060*|*nreachable*|*10065*|*"No route"*)
                unreach=$((unreach + 1))
                if [ $unreach -ge 2 ]; then
                    Err "Aucun appareil ne répond à l'adresse $target." "No device answers at $target."
                    Say "   Vérifiez l'adresse IP, que la TV est allumée (pas en veille) et sur le même réseau que l'ordinateur (pas un réseau invité). Un VPN sur l'ordinateur peut aussi bloquer." "   Check the IP address, that the TV is on (not in standby) and on the same network as the computer (not a guest network). A VPN on the computer can also block it." DarkGray
                    return 1
                fi ;;
            *)
                [ $i -eq 1 ] && [ $asked = 0 ] && { Say ">>> Regardez la TV : si « Autoriser le débogage ? » s'affiche, cochez « Toujours autoriser » puis OK." ">>> Look at the TV: if 'Allow debugging?' appears, tick 'Always allow' then OK." Cyan; asked=1; } ;;
        esac
        sleep 2
        i=$((i + 1))
    done
    return 1
}

Choose_TV() {
    local ip pp code cp
    echo
    Say "Trouvez l'adresse IP de la TV : Paramètres > Réseau (ou À propos > État)." "Find the TV's IP address: Settings > Network (or About > Status)." Cyan
    Say "Le débogage ADB doit être activé (voir README)." "ADB debugging must be enabled (see README)." DarkGray
    ip="$(trim "$(Ask "Adresse IP de la TV" "TV IP address")")"
    [ -z "$ip" ] && return 1
    if ! Connect_Target "$ip"; then
        Err "Connexion impossible." "Could not connect."
        if YesNo "Votre TV affiche-t-elle un code de jumelage (Débogage sans fil, Android 11+) ?" "Does your TV show a pairing code (Wireless debugging, Android 11+)?" 0; then
            pp="$(trim "$(Ask "IP:port de JUMELAGE affiché sur la TV" "PAIRING IP:port shown on the TV")")"
            code="$(trim "$(Ask "Code de jumelage" "Pairing code")")"
            "$ADB" pair "$pp" "$code"
            cp="$(trim "$(Ask "IP:port de CONNEXION (écran Débogage sans fil)" "CONNECTION IP:port (Wireless debugging screen)")")"
            if ! Connect_Target "$cp"; then Err "Toujours impossible. Voir README > Dépannage." "Still failing. See README > Troubleshooting."; return 1; fi
        else return 1; fi
    fi
    Get_TvIdentity
    echo
    Say "Appareil trouvé :" "Device found:" White
    printf '   %s %s  (%s)  - Android %s, patch %s\n' "$INFO_Brand" "$INFO_Model" "$INFO_Name" "$INFO_Android" "$INFO_Patch"
    printf '   ID : %s\n' "$INFO_Id"
    printf '   Fingerprint : %s\n' "$INFO_Fingerprint"
    Show_Profile
    if ! YesNo "Est-ce bien la TV que vous voulez modifier ?" "Is this the TV you want to modify?" 1; then
        "$ADB" disconnect "$T_" >/dev/null 2>&1; T_=""; return 1
    fi
    ID="$INFO_Id"
    printf '{\n    "target":  %s,\n    "id":  %s,\n    "label":  %s\n}\n' "$(jq_s "$T_")" "$(jq_s "$INFO_Id")" "$(jq_s "$INFO_Brand $INFO_Model")" > "$CONF_FILE"
    Ok "TV enregistrée. Toutes les actions vérifieront qu'il s'agit bien d'elle." "TV saved. Every action will check it is the same TV."
    return 0
}

# Reconnecte la TV enregistrée et vérifie son identité avant toute action
Ensure_TV() {
    local c_target c_id c_label
    [ -f "$CONF_FILE" ] || { Choose_TV; return; }
    c_target="$(json_str "$CONF_FILE" target)"; c_id="$(json_str "$CONF_FILE" id)"; c_label="$(json_str "$CONF_FILE" label)"
    if ! Connect_Target "$c_target"; then
        Err "La TV $c_label ($c_target) ne répond pas. Allumée ? Même Wi-Fi ? IP changée ?" "TV $c_label ($c_target) is not answering. On? Same Wi-Fi? IP changed?"
        if YesNo "Saisir une autre adresse ?" "Enter another address?" 1; then rm -f "$CONF_FILE"; Choose_TV; return; fi
        return 1
    fi
    Get_TvIdentity
    if [ "$INFO_Id" != "$c_id" ]; then
        Err "SÉCURITÉ : l'appareil à cette adresse n'est PAS la TV enregistrée ($INFO_Brand $INFO_Model). Rien n'a été fait." "SAFETY: the device at this address is NOT the saved TV ($INFO_Brand $INFO_Model). Nothing was done."
        "$ADB" disconnect "$T_" >/dev/null 2>&1
        return 1
    fi
    ID="$INFO_Id"
    Ok "TV vérifiée : $c_label" "TV verified: $c_label"
    printf '   Fingerprint : %s\n' "$INFO_Fingerprint"
    Show_Profile
    return 0
}

# ---------------------------------------------------------------- état / sauvegarde
TvDir() { mkdir -p "$SAVES/$ID"; printf '%s' "$SAVES/$ID"; }
StateFile() { printf '%s/etat_kit.json' "$(TvDir)"; }
# état chargé dans des variables ST_* (ST_DISABLED = un paquet par ligne)
Get_State() {
    local f; f="$(StateFile)"
    ST_DISABLED=""; ST_HAS_ANIM=0; ST_ANIM_WINDOW=""; ST_ANIM_TRANSITION=""; ST_ANIM_ANIMATOR=""
    ST_ORIGINAL_HOME=""; ST_LAUNCHER_DISABLED=""; ST_BACKUP=""
    [ -f "$f" ] || return 0
    ST_DISABLED="$(json_arr "$f" disabled)"
    if json_flat "$f" | grep -q '"anim"[[:space:]]*:[[:space:]]*{'; then
        ST_HAS_ANIM=1
        ST_ANIM_WINDOW="$(json_str "$f" window)"; ST_ANIM_TRANSITION="$(json_str "$f" transition)"; ST_ANIM_ANIMATOR="$(json_str "$f" animator)"
    fi
    ST_ORIGINAL_HOME="$(json_str "$f" original_home)"
    ST_LAUNCHER_DISABLED="$(json_str "$f" launcher_disabled)"
    ST_BACKUP="$(json_str "$f" backup)"
}
Save_State() {
    local arr="" p anim="null"
    while IFS= read -r p; do [ -n "$p" ] && arr="$arr${arr:+,}
        $(jq_s "$p")"; done <<EOF
$ST_DISABLED
EOF
    if [ "$ST_HAS_ANIM" = 1 ]; then
        anim="{
        \"window\":  $(jq_s "$ST_ANIM_WINDOW"),
        \"transition\":  $(jq_s "$ST_ANIM_TRANSITION"),
        \"animator\":  $(jq_s "$ST_ANIM_ANIMATOR")
    }"
    fi
    cat > "$(StateFile)" <<EOF
{
    "disabled":  [$arr
    ],
    "anim":  $anim,
    "original_home":  $(jq_s "$ST_ORIGINAL_HOME"),
    "launcher_disabled":  $(jq_s "$ST_LAUNCHER_DISABLED"),
    "backup":  $(jq_s "$ST_BACKUP")
}
EOF
}
in_list() { printf '%s\n' "$2" | grep -qxF -- "$1"; }

Capture_TV() {
    local dir dest
    dir="$(TvDir)/captures"; mkdir -p "$dir"
    dest="$dir/$(now)_$1.png"
    A shell screencap -p /sdcard/_kit_cap.png >/dev/null
    A pull /sdcard/_kit_cap.png "$dest" >/dev/null
    A shell rm /sdcard/_kit_cap.png >/dev/null
    [ -f "$dest" ] && printf '%s   %s%s%s\n' "$C_DarkGray" "$(T "Capture : " "Screenshot: ")" "$dest" "$C_0" >&2
    CAPTURE="$dest"
}

# PERF_TOTAL / PERF_DISPO en Mo, PERF_CPU en %
Get_Perf() {
    local mem top line tot idle
    mem="$(Sh "cat /proc/meminfo")"
    PERF_TOTAL="$(printf '%s\n' "$mem" | awk '/^MemTotal:/ { printf "%d", $2 / 1024 + 0.5 }')"; PERF_TOTAL="${PERF_TOTAL:-0}"
    PERF_DISPO="$(printf '%s\n' "$mem" | awk '/^MemAvailable:/ { printf "%d", $2 / 1024 + 0.5 }')"; PERF_DISPO="${PERF_DISPO:-0}"
    PERF_CPU=""
    top="$(Sh "top -b -n 1 -m 5")"
    line="$(printf '%s\n' "$top" | grep -o '[0-9][0-9]*%cpu.*[^0-9][0-9][0-9]*%idle' | head -n 1)"
    if [ -n "$line" ]; then
        tot="$(printf '%s' "$line" | sed 's/%cpu.*//')"
        idle="$(printf '%s' "$line" | sed 's/.*[^0-9]\([0-9][0-9]*\)%idle$/\1/')"
        PERF_CPU="$(awk -v t="$tot" -v i="$idle" 'BEGIN { if (t > 0) printf "%d", 100 * (1 - i / t) + 0.5 }')"
    fi
}

Get_Home() {
    local line
    line="$(Sh "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME" \
        | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -E '^[A-Za-z0-9_.]+/[A-Za-z0-9_.$]+$' | tail -n 1)"
    case "$line" in ""|android/*) ;; *) printf '%s' "$line" ;; esac
}
Get_Packages() { Sh "pm list packages $1" | grep '^package:' | sed -e 's/^package://' -e 's/[[:space:]]*$//'; }

Do_Backup() {
    local quiet="${1:-0}" d homeAct wifi freq rssi speed wf sum
    d="$(TvDir)/sauvegarde_$(now)"
    mkdir -p "$d"
    Say "Sauvegarde de l'état de la TV (lecture seule)..." "Backing up the TV's state (read-only)..." Cyan
    {
        for k in Id Brand Model Manufacturer Android Sdk Patch Build Name; do eval "printf '%-12s : %s\n' \"$k\" \"\$INFO_$k\""; done
    } > "$d/appareil.txt"
    Sh "getprop" > "$d/getprop.txt"
    Sh "pm list packages -f" > "$d/paquets_tous.txt"
    Sh "pm list packages -d" > "$d/paquets_desactives.txt"
    Sh "pm list packages -3" > "$d/paquets_installes_par_vous.txt"
    for ns in global secure system; do Sh "settings list $ns" > "$d/settings_$ns.txt"; done
    homeAct="$(Get_Home)"
    printf '%s\n' "$homeAct" > "$d/ecran_accueil.txt"
    Sh "df -h" > "$d/stockage.txt"
    Sh "top -b -n 1 -m 25" > "$d/processus.txt"
    wifi="$(Sh "dumpsys wifi")"
    Get_Perf
    freq="$(printf '%s\n' "$wifi" | sed -n 's/.*Frequency: \([0-9][0-9]*\).*/\1/p' | head -n 1)"; freq="${freq:-0}"
    rssi="$(printf '%s\n' "$wifi" | sed -n 's/.*RSSI: \(-\{0,1\}[0-9][0-9]*\).*/\1/p' | head -n 1)"; rssi="${rssi:-0}"
    speed="$(printf '%s\n' "$wifi" | sed -n 's/.*Link speed: \([0-9][0-9]*\).*/\1/p' | head -n 1)"; speed="${speed:-0}"
    Get_State
    if [ -z "$ST_BACKUP" ]; then ST_BACKUP="$d"; ST_ORIGINAL_HOME="$homeAct"; fi   # 1re sauvegarde = état d'origine
    if [ "$ST_HAS_ANIM" != 1 ]; then
        ST_HAS_ANIM=1
        ST_ANIM_WINDOW="$(trim "$(Sh "settings get global window_animation_scale" | tr -d '\n')")"
        ST_ANIM_TRANSITION="$(trim "$(Sh "settings get global transition_animation_scale" | tr -d '\n')")"
        ST_ANIM_ANIMATOR="$(trim "$(Sh "settings get global animator_duration_scale" | tr -d '\n')")"
    fi
    Save_State
    # ce que le kit a désactivé mais que la TV a réactivé d'elle-même (fréquent sur Google TV)
    if [ -n "$ST_DISABLED" ]; then
        local offNow back="" q
        offNow="$(Get_Packages -d)"
        for q in $ST_DISABLED; do in_list "$q" "$offNow" || back="$back${back:+, }$q"; done
        [ -n "$back" ] && Warn "Réactivés par la TV depuis le passage du kit : $back. Relancez l'option 2 ou 3 si besoin." "Re-enabled by the TV since the kit ran: $back. Run option 2 or 3 again if needed."
    fi
    Capture_TV "etat_initial"
    [ -f "$CAPTURE" ] && cp "$CAPTURE" "$d/capture.png"
    if [ "$freq" -gt 4000 ]; then wf="5 GHz"; elif [ "$freq" -gt 0 ]; then wf="2.4 GHz"; else wf="$(T "câble ou inconnu" "cable or unknown")"; fi
    sum="$(T "Appareil" "Device") : $INFO_Brand $INFO_Model - Android $INFO_Android (SDK $INFO_Sdk), patch $INFO_Patch
$(T "Écran d'accueil" "Home screen") : $homeAct
RAM : $PERF_DISPO / $PERF_TOTAL Mo $(T "disponibles" "available")
$(T "Processeur utilisé (instantané)" "CPU used (snapshot)") : $PERF_CPU %
Wi-Fi : $wf, $rssi dBm, $speed Mb/s"
    printf '%s\n' "$sum" > "$d/RESUME.txt"
    if [ "$quiet" != 1 ]; then echo; printf '%s\n' "$sum" | sed 's/^/   /'; fi
    if [ "$freq" -gt 0 ] && [ "$freq" -lt 3000 ]; then Warn "La TV est en Wi-Fi 2,4 GHz : préférez le 5 GHz ou un câble pour le streaming." "The TV uses 2.4 GHz Wi-Fi: prefer 5 GHz or a cable for streaming."; fi
    if [ "$PERF_TOTAL" -gt 0 ] && [ "$PERF_DISPO" -lt 400 ]; then Warn "Peu de mémoire disponible : l'allègement (menu 2) devrait aider." "Low available memory: slimming (menu 2) should help."; fi
    Ok "Sauvegarde : $d" "Backup: $d"
}
Ensure_Backup() { Get_State; if [ -z "$ST_BACKUP" ]; then Say "Première utilisation sur cette TV : sauvegarde d'abord." "First use on this TV: backing up first." Cyan; Do_Backup 1; fi; }

# ---------------------------------------------------------------- listes
# Remplit L_PKGS[i] (paquets séparés par des espaces), L_FR[i], L_EN[i]
Read_List() {
    local l pk fr en n=0
    L_PKGS=(); L_FR=(); L_EN=()
    while IFS= read -r l || [ -n "$l" ]; do
        l="$(trim "$(printf '%s' "$l" | LC_ALL=C sed "s/^$BOM//" | tr -d '\r')")"
        case "$l" in ""|"#"*) continue ;; esac
        # une ligne peut regrouper plusieurs paquets d'une meme fonction : paquet1,paquet2 | ...
        pk="$(printf '%s' "$l" | cut -d'|' -f1 | tr ',' ' ' | xargs)"
        fr=""; en=""
        case "$l" in *"|"*) fr="$(trim "$(printf '%s' "$l" | cut -d'|' -f2)")" ;; esac
        case "$l" in *"|"*"|"*) en="$(trim "$(printf '%s' "$l" | cut -d'|' -f3)")" ;; esac
        [ -z "$pk" ] && continue
        L_PKGS[$n]="$pk"; L_FR[$n]="$fr"; L_EN[$n]="$en"; n=$((n + 1))
    done < "$SCRIPTS/listes/$1"
}
PROTECTED="android com.android.systemui com.android.settings com.android.tv.settings com.android.vending
com.google.android.gms com.google.android.gsf com.android.providers.settings com.android.providers.tv
com.google.android.webview com.android.webview com.android.bluetooth com.android.phone com.android.shell
com.android.packageinstaller com.google.android.packageinstaller com.android.inputdevices com.android.externalstorage
com.android.providers.media com.android.providers.downloads com.google.android.inputmethod.latin
com.mediatek.wwtv.tvcenter com.mediatek.wwtv.webview com.google.android.leanbacklauncher.partnercustomizer
com.vestel.tv.service com.vestel.tv.servicepatch
com.vestel.tv.keycontroller com.vestel.tv.backlight
com.vestel.tv.rcupdater com.mediatek.tv.service
com.mediatek.tvinput com.mediatek.tv.factory com.mediatek.tvinputservice.arbitratorservice
com.mediatek.network com.mediatek.tv.network com.google.android.tungsten.setupwraith $ZEN_PKG"
PROTECTED="$(printf '%s' "$PROTECTED" | tr ' ' '\n')"

Test_Protected() {
    # Preserve existing Google TV fallback handling outside the Cosmos profile.
    if [ "$1" = "$GTV_FALLBACK" ] && [ "${2:-slim}" = launcher ] && ! Test_Cosmos; then return 1; fi
    in_list "$1" "$PROTECTED"
}
Disable_Packages() {
    local why="$1" homePkg skipped=0 p r; shift
    LAST_DISABLED=""
    Get_State
    homePkg="$(Get_Home)"; homePkg="${homePkg%%/*}"
    for p in "$@"; do
        if Test_Protected "$p" "$why"; then Warn "$p protégé, ignoré" "$p is protected, skipped"; continue; fi
        if [ "$p" = "$homePkg" ] && [ "$why" != "launcher" ]; then Warn "$p est l'écran d'accueil actuel : ignoré (voir menu 3)" "$p is the current home screen: skipped (see menu 3)"; continue; fi
        r="$(Sh "pm disable-user --user 0 $p" | tr '\n' ' ')"
        case "$r" in
            *"new state: disabled"*) Ok "$p" "$p"; in_list "$p" "$ST_DISABLED" || ST_DISABLED="$ST_DISABLED${ST_DISABLED:+
}$p"
                LAST_DISABLED="$LAST_DISABLED${LAST_DISABLED:+
}$p"; Save_State ;;
            *)  # la TV refuse (paquet systeme verrouille, absent, etc.) : on ignore et on continue
                printf '%s  - %s%s%s\n' "$C_DarkGray" "$p" "$(T " : ignoré (non modifiable sur cette TV)" " : skipped (cannot be changed on this TV)")" "$C_0"
                skipped=$((skipped + 1)) ;;
        esac
    done
    Save_State
    [ $skipped -gt 0 ] && Say "  $skipped élément(s) ignoré(s) : c'est normal, rien n'a été modifié pour eux." "  $skipped item(s) skipped: that's normal, nothing was changed for them." DarkGray
    return 0
}

# ne garde que les paquets presents et actifs sur CETTE TV (les autres sont ignores)
Filter_List() {
    local i p keep
    F_PKGS=(); F_FR=(); F_EN=()
    for i in "${!L_PKGS[@]}"; do
        keep=""
        for p in ${L_PKGS[$i]}; do in_list "$p" "$ENABLED" && [ "$p" != "$HOME_PKG" ] && ! Test_Protected "$p" && keep="$keep${keep:+ }$p"; done
        [ -n "$keep" ] && { F_PKGS[${#F_PKGS[@]}]="$keep"; F_FR[${#F_FR[@]}]="${L_FR[$i]}"; F_EN[${#F_EN[@]}]="${L_EN[$i]}"; }
    done
}

Profile_Trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    printf '%s' "${value%"${value##*[![:space:]]}"}"
}
Read_Profile() {
    [ -r "$SCRIPTS/profils/toshiba-cosmos.txt" ] || { Err "Profil introuvable" "Profile not found"; return 1; }
    local l tag rest fr en pk mode extra separators b=-1 n=0 i count alone
    B_FR=(); B_EN=(); B_PHASE=(); B_TEST_FR=(); B_TEST_EN=()
    P_BATCH=(); P_PKG=(); P_FR=(); P_EN=(); P_MODE=()
    while IFS= read -r l || [ -n "$l" ]; do
        l="${l#$BOM}"; l="$(Profile_Trim "$l")"
        separators="${l//[^|]/}"
        case "$l" in
            ""|\#*) continue ;;
            \[garder\]*) break ;;
            \[*\]*)
                tag="${l%%]*}"; tag="${tag#\[}"; rest="${l#*]}"
                [ "${#separators}" = 1 ] || { Err "Titre de profil invalide" "Invalid profile heading"; return 1; }
                IFS='|' read -r fr en <<< "$rest"
                b=$((b + 1)); B_FR[$b]="$(Profile_Trim "$fr")"; B_EN[$b]="$(Profile_Trim "$en")"
                B_PHASE[$b]=slim; case "$tag" in "apres zen"*) B_PHASE[$b]=zen ;; esac
                B_TEST_FR[$b]=""; B_TEST_EN[$b]="" ;;
            test:*)
                [ "$b" -ge 0 ] && [ "${#separators}" = 1 ] || { Err "Test de profil invalide" "Invalid profile test"; return 1; }
                IFS='|' read -r fr en <<< "${l#test:}"
                B_TEST_FR[$b]="$(Profile_Trim "$fr")"; B_TEST_EN[$b]="$(Profile_Trim "$en")" ;;
            *)
                [ "$b" -ge 0 ] && [ "${#separators}" = 3 ] || { Err "Ligne de profil invalide" "Invalid profile entry"; return 1; }
                IFS='|' read -r pk fr en mode extra <<< "$l"
                pk="$(Profile_Trim "$pk")"; mode="$(Profile_Trim "$mode")"
                case "$pk" in ""|*[!a-zA-Z0-9_.]*) return 1 ;; esac
                case "$mode" in auto|ask|alone) ;; *) return 1 ;; esac
                P_BATCH[$n]="$b"; P_PKG[$n]="$pk"; P_FR[$n]="$(Profile_Trim "$fr")"; P_EN[$n]="$(Profile_Trim "$en")"; P_MODE[$n]="$mode"; n=$((n + 1)) ;;
        esac
    done < "$SCRIPTS/profils/toshiba-cosmos.txt"
    for b in "${!B_FR[@]}"; do
        count=0; alone=0
        for i in "${!P_PKG[@]}"; do
            [ "${P_BATCH[$i]}" = "$b" ] || continue
            count=$((count + 1)); [ "${P_MODE[$i]}" = alone ] && alone=1
        done
        if [ -z "${B_TEST_FR[$b]}" ] || [ -z "${B_TEST_EN[$b]}" ] || [ "$count" = 0 ] || { [ "$alone" = 1 ] && [ "$count" != 1 ]; }; then
            Err "Lot de profil incomplet (alone exige un lot séparé)" "Incomplete profile batch (alone requires a separate batch)"; return 1
        fi
    done
    return 0
}
Undo_ProfileBatch() {
    local p r
    Get_State
    for p in "$@"; do
        r="$(Sh "pm enable $p" | tr '\n' ' ')"
        case "$r" in
            *"new state: enabled"*) Ok "$p réactivé" "$p re-enabled"
                ST_DISABLED="$(printf '%s\n' "$ST_DISABLED" | grep -vxF -- "$p")"; Save_State ;;
            *) Warn "$p : réactivation refusée ; conservé dans l'état pour l'option 6." "$p: re-enable failed; retained in state for option 6." ;;
        esac
    done
}
Run_Profile() {
    local phase="$1" b i p enabled homePkg changed autoAsked autoYes disable eligible=()
    # Validate everything before the first change; never source profile text as code.
    Read_Profile || return 1
    for b in "${!B_FR[@]}"; do
        [ "${B_PHASE[$b]}" = "$phase" ] || continue
        enabled="$(Get_Packages -e)"; homePkg="$(Get_Home)"; homePkg="${homePkg%%/*}"; eligible=()
        for i in "${!P_PKG[@]}"; do
            [ "${P_BATCH[$i]}" = "$b" ] || continue
            p="${P_PKG[$i]}"
            in_list "$p" "$enabled" && [ "$p" != "$homePkg" ] && ! Test_Protected "$p" || continue
            case "$p" in com.google.android.tvlauncher|com.google.android.tvrecommendations) continue ;; esac
            eligible[${#eligible[@]}]="$i"
        done
        [ ${#eligible[@]} -gt 0 ] || continue
        Say "${B_FR[$b]}" "${B_EN[$b]}" White
        for i in "${eligible[@]}"; do printf '   %s | %s [%s]\n' "${P_PKG[$i]}" "$(T "${P_FR[$i]}" "${P_EN[$i]}")" "${P_MODE[$i]}"; done
        changed=""; autoAsked=0; autoYes=0
        for i in "${eligible[@]}"; do
            p="${P_PKG[$i]}"; in_list "$p" "$(Get_Packages -e)" || continue
            disable=0
            case "${P_MODE[$i]}" in
                auto)
                    if [ "$autoAsked" = 0 ]; then
                        YesNo "Désactiver les éléments d'office de ce lot ?" "Disable this batch's automatic items?" 1 && autoYes=1
                        autoAsked=1
                    fi
                    disable="$autoYes" ;;
                ask) YesNo "Utilisez-vous : ${P_FR[$i]} ?" "Do you use: ${P_EN[$i]}?" 1 || disable=1 ;;
                alone) YesNo "Désactiver séparément : ${P_FR[$i]} ? Test Input juste après." "Disable separately: ${P_EN[$i]}? Test Input immediately afterwards." 0 && disable=1 ;;
            esac
            if [ "$disable" = 1 ]; then
                Disable_Packages profile "$p"
                [ -n "$LAST_DISABLED" ] && changed="$changed${changed:+
}$LAST_DISABLED"
            fi
        done
        if [ -n "$changed" ]; then
            Say "${B_TEST_FR[$b]}" "${B_TEST_EN[$b]}" Cyan
            if ! YesNo "Tout fonctionne ? (o = continuer / n = annuler ce lot)" "Everything works? (y = continue / n = undo this batch)" 0; then
                Undo_ProfileBatch $changed
                Warn "Profil arrêté après annulation du lot." "Profile stopped after undoing the batch."
                return 1
            fi
        fi
    done
    return 0
}

# ---------------------------------------------------------------- 2. allègement
Do_Slim() {
    local i lbl toOff="" safeAll="" b_dispo b_cpu k
    Ensure_Backup
    if Test_Cosmos; then
        Show_Profile
        Say "1. Suivre le profil testé (recommandé)" "1. Follow the tested profile (recommended)" White
        Say "2. Listes génériques" "2. Generic lists" White
        if [ "$(trim "$(Ask "Votre choix (Entrée = 1)" "Your choice (Enter = 1)")")" != 2 ]; then
            if Run_Profile slim; then
                case "$(Get_Home)" in "$ZEN_PKG"/*) Run_Profile zen ;; *) Say "Les lots après Zen Home seront proposés par l'option 3." "The after-Zen-Home batches will be offered by option 3." Cyan ;; esac
            fi
            Cosmos_Reminders
            return
        fi
    fi
    ENABLED="$(Get_Packages -e)"
    HOME_PKG="$(Get_Home)"; HOME_PKG="${HOME_PKG%%/*}"
    Read_List "pubs_telemetrie.txt"; Filter_List
    S_PKGS=("${F_PKGS[@]}"); S_FR=("${F_FR[@]}"); S_EN=("${F_EN[@]}")
    Read_List "optionnel.txt"; Filter_List
    Get_Perf; b_dispo="$PERF_DISPO"; b_cpu="$PERF_CPU"
    Capture_TV "avant_allegement"
    echo
    if [ ${#S_PKGS[@]} -gt 0 ]; then
        Say "Publicités, télémétrie et services inutiles trouvés sur cette TV :" "Ads, telemetry and useless services found on this TV:" White
        for i in "${!S_PKGS[@]}"; do
            printf '   - %-48s %s\n' "$(printf '%s' "${S_PKGS[$i]}" | sed 's/ /, /g')" "$(T "${S_FR[$i]}" "${S_EN[$i]}")"
            safeAll="$safeAll ${S_PKGS[$i]}"
        done
        if YesNo "Les désactiver (réversible, rien n'est désinstallé) ?" "Disable them (reversible, nothing is uninstalled)?" 1; then
            Disable_Packages slim $safeAll
        fi
    else Ok "Aucune pub/télémétrie connue trouvée." "No known ads/telemetry found."; fi

    if [ ${#F_PKGS[@]} -gt 0 ]; then
        echo
        Say "Fonctions et applis que vous utilisez peut-être (une question par élément) :" "Features and apps you may use (one question each):" White
        for i in "${!F_PKGS[@]}"; do
            lbl="$(T "${F_FR[$i]}" "${F_EN[$i]}")"
            YesNo "   Utilisez-vous : $lbl ?" "   Do you use: $lbl ?" 1 || toOff="$toOff ${F_PKGS[$i]}"
        done
        [ -n "$toOff" ] && Disable_Packages slim $toOff
    fi

    echo
    local animToLower="" animNeedsQuestion=0 v
    for k in window_animation_scale transition_animation_scale animator_duration_scale; do
        v="$(trim "$(Sh "settings get global $k" | tr -d '\n')")"
        if printf '%s\n' "$v" | LC_ALL=C awk '/^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?$/ { valid=1 } END { exit !valid }'; then
            if LC_ALL=C awk -v v="$v" 'BEGIN { exit !(v > 0.5) }'; then
                animToLower="$animToLower $k"; animNeedsQuestion=1
            fi
        else animToLower="$animToLower $k"; animNeedsQuestion=1; fi   # non défini = 1.0 par défaut
    done
    if [ "$animNeedsQuestion" = 0 ]; then
        Say "Animations déjà rapides ou coupées : inchangées" "Animations already fast or off: unchanged"
    elif YesNo "Accélérer les animations (×0,5) ?" "Speed up animations (×0.5)?" 1; then
        for k in $animToLower; do Sh "settings put global $k 0.5" >/dev/null; done
        [ -n "$animToLower" ] && Ok "Animations ×0,5" "Animations ×0.5"
    fi
    Say "Libération de la mémoire..." "Freeing memory..." Cyan
    Sh "am kill-all" >/dev/null
    sleep 15
    Sh "input keyevent KEYCODE_HOME" >/dev/null
    sleep 6
    Get_Perf
    Capture_TV "apres_allegement"
    echo
    printf '%s   RAM %s : %s Mo → %s Mo%s\n' "$C_White" "$(T "disponible" "available")" "$b_dispo" "$PERF_DISPO" "$C_0"
    printf '%s   CPU : %s %% → %s %%  %s%s\n' "$C_White" "$b_cpu" "$PERF_CPU" "$(T "(instantané, varie d'une mesure à l'autre)" "(snapshot, varies between readings)")" "$C_0"
    Say "Astuce : le plus gros gain vient souvent du remplacement de l'écran d'accueil (menu 3)." "Tip: the biggest gain often comes from replacing the home screen (menu 3)." DarkGray
    Cosmos_Reminders
}

# ---------------------------------------------------------------- 3. écran d'accueil
DOCK_PKGS=(com.netflix.ninja com.google.android.youtube.tv com.amazon.amazonvideo.livingroom
    com.disney.disneyplus com.canal.android.canal com.wbd.stream
    com.apple.atve.androidtv.appletv com.spotify.tv.android com.plexapp.android
    fr.francetv.pluzz fr.tf1.mytf1 fr.m6.m6replay tv.arte.plus7
    tv.molotov.app com.cbs.ott com.dazn tv.twitch.android.app
    org.xbmc.kodi com.google.android.youtube.tvkids)
DOCK_NAMES=("Netflix" "YouTube" "Prime Video"
    "Disney+" "myCANAL" "Max"
    "Apple TV" "Spotify" "Plex"
    "france.tv" "TF1+" "M6+" "Arte"
    "Molotov" "Paramount+" "DAZN" "Twitch"
    "Kodi" "YouTube Kids")
# Android 10+ : l'accueil par défaut est un « rôle » système, en plus de set-home-activity
Set_HomeRole() { [ "${INFO_Sdk:-0}" -ge 29 ] 2>/dev/null && Sh "cmd role add-role-holder android.app.role.HOME $1" >/dev/null; return 0; }

# TCL : les boutons Netflix / YouTube / Prime Video de la télécommande ne marchent qu'avec l'accueil Google TV.
# Quand il est désactivé, le service d'accessibilité de Zen Home (KeyService) prend le relais pour ces seules touches.
KEY_SVC="tv.zenhome/tv.zenhome.KeyService"
Enable_KeyService() {
    local cur
    case "$INFO_Brand $INFO_Manufacturer" in *TCL*|*tcl*|*Tcl*) ;; *) return 0 ;; esac
    cur="$(trim "$(Sh "settings get secure enabled_accessibility_services" | tr -d '\n')")"
    [ "$cur" = "null" ] && cur=""
    case ":$cur:" in *":$KEY_SVC:"*) ;; *) Sh "settings put secure enabled_accessibility_services ${cur:+$cur:}$KEY_SVC" >/dev/null ;; esac
    Sh "settings put secure accessibility_enabled 1" >/dev/null
    Ok "Boutons Netflix, YouTube et Prime Video de la télécommande rebranchés sur leurs applis." "Remote's Netflix, YouTube and Prime Video buttons reconnected to their apps."
}
Disable_KeyService() {
    local cur rest
    cur="$(trim "$(Sh "settings get secure enabled_accessibility_services" | tr -d '\n')")"
    case "$cur" in ""|null) return 0 ;; esac
    rest="$(printf '%s' "$cur" | tr ':' '\n' | grep -vxF -e "$KEY_SVC" -e "tv.zenhome/.KeyService" | grep -v '^$' | paste -sd: -)"
    [ "$rest" = "$cur" ] && return 0
    if [ -n "$rest" ]; then Sh "settings put secure enabled_accessibility_services $rest" >/dev/null
    else Sh "settings delete secure enabled_accessibility_services" >/dev/null; Sh "settings put secure accessibility_enabled 0" >/dev/null; fi
}

# Vrai si un réseau Wi-Fi enregistré a été créé par setupwraith (assistant de première configuration de Google TV)
Test_WraithWifi() {
    local w; w="$(Sh "dumpsys wifi")"
    # seulement les réseaux réellement enregistrés : le reste du rapport contient aussi des historiques (anciens réseaux)
    if printf '%s\n' "$w" | grep -q "Configured networks Begin"; then
        w="$(printf '%s\n' "$w" | awk '/Configured networks Begin/ { f = 1 } f { print } /Configured networks End/ { f = 0 }')"
    fi
    printf '%s\n' "$w" | grep -Eq '(cname|creatorName)=com\.google\.android\.tungsten\.setupwraith'
}

# Vrai si le kit est connecté à la TV par son câble Ethernet : supprimer le Wi-Fi ne couperait alors pas la connexion
Test_OnEthernet() {
    local ip="${T_%:*}"
    Sh "ip -o -4 addr show" | awk -v ip="$ip" '{ split($4, a, "/"); if ($3 == "inet" && a[1] == ip) { print $2; exit } }' | grep -q '^eth'
}

# Désactive l'accueil d'origine (et l'écran de secours Google TV), puis vérifie que Zen Home a bien pris la place.
# Si la TV n'a plus d'accueil utilisable, tout est réactivé aussitôt : la TV ne peut pas rester sans accueil.
# Paquets des écrans d'accueil candidats de priorité >= 0, un par ligne
Get_HomeCandidates() {
    Sh "cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME" \
        | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
        | awk '/priority=/ { p = $0; sub(/.*priority=/, "", p); sub(/ .*/, "", p); next }
               /^[A-Za-z0-9_.]+\/[A-Za-z0-9_.$]+$/ { if (p + 0 >= 0) { split($0, a, "/"); print a[1] } }'
}

Disable_OrigHome() {
    local orig="$1" toOff q wraithKept extra picked
    toOff="$orig"; wraithKept=0
    # Google TV : sans son accueil, l'écran de secours setupwraith prend la main (logo Google TV en boucle)
    if ! Test_Cosmos && in_list "$GTV_FALLBACK" "$(Get_Packages -e)"; then
        # mais si le Wi-Fi lui appartient, Android supprime ce réseau en le désactivant : la TV perdrait sa connexion (et ADB)
        if Test_WraithWifi && Test_OnEthernet; then
            Warn "Un réseau Wi-Fi enregistré appartient à l'écran de secours Google (setupwraith). La TV est branchée en Ethernet : le kit peut quand même le désactiver, mais ce réseau Wi-Fi sera supprimé (à reconfigurer ensuite si vous en avez besoin)." "A saved Wi-Fi network belongs to the Google fallback screen (setupwraith). The TV is on Ethernet: the kit can still disable it, but that Wi-Fi network will be deleted (set it up again later if you need it)."
            if YesNo "Le désactiver quand même ?" "Disable it anyway?" 1; then toOff="$toOff $GTV_FALLBACK"; else wraithKept=1; fi
        elif Test_WraithWifi; then
            Warn "Le Wi-Fi de la TV a été enregistré pendant sa configuration initiale : il appartient à l'écran de secours Google (setupwraith). Le désactiver supprimerait ce réseau et couperait la connexion, il est donc laissé actif." "The TV's Wi-Fi was saved during its initial setup: it belongs to the Google fallback screen (setupwraith). Disabling it would delete that network and cut the connection, so it is left enabled."
            Say "   Pour pouvoir le désactiver : sur la TV, Paramètres > Réseau, « Oublier » votre Wi-Fi ET les autres réseaux enregistrés (se reconnecter ne suffit pas), reconnectez-vous en retapant le mot de passe, puis relancez l'option 3. Ou branchez la TV en Ethernet." "   To be able to disable it: on the TV, Settings > Network, 'Forget' your Wi-Fi AND the other saved networks (reconnecting is not enough), reconnect by typing the password again, then run option 3 again. Or plug the TV into Ethernet." DarkGray
            wraithKept=1
        else toOff="$toOff $GTV_FALLBACK"; fi
    fi
    Disable_Packages launcher $toOff
    Get_State; ST_LAUNCHER_DISABLED="$orig"; Save_State
    Sh "cmd package set-home-activity $ZEN_PKG/.Home" >/dev/null
    Set_HomeRole "$ZEN_PKG"
    Sh "input keyevent KEYCODE_HOME" >/dev/null
    sleep 5
    case "$(Get_Home)" in "$ZEN_PKG"/*) Enable_KeyService; return 0 ;; esac
    # d'autres écrans d'accueil (second launcher Google ou du fabricant) peuvent encore passer avant Zen Home
    extra=""
    while read -r q; do
        [ -z "$q" ] && continue
        [ "$q" = "$ZEN_PKG" ] && continue
        in_list "$q" "$PROTECTED" && continue
        in_list "$q" "$(printf '%s\n' $toOff)" && continue
        [ $wraithKept = 1 ] && [ "$q" = "$GTV_FALLBACK" ] && continue
        in_list "$q" "$(printf '%s\n' $extra)" || extra="$extra${extra:+ }$q"
    done <<EOF
$(Get_HomeCandidates)
EOF
    if [ -n "$extra" ]; then
        Warn "D'autres écrans d'accueil passent encore avant Zen Home : $(printf '%s' "$extra" | sed 's/ /, /g')." "Other home screens still come before Zen Home: $(printf '%s' "$extra" | sed 's/ /, /g')."
        if YesNo "Les désactiver aussi (réversible, retour arrière automatique si ça ne suffit pas) ?" "Disable them too (reversible, automatic rollback if that's not enough)?" 1; then
            Disable_Packages launcher $extra
            toOff="$toOff $extra"
            Sh "cmd package set-home-activity $ZEN_PKG/.Home" >/dev/null
            Set_HomeRole "$ZEN_PKG"
            Sh "input keyevent KEYCODE_HOME" >/dev/null
            sleep 5
            case "$(Get_Home)" in "$ZEN_PKG"/*) Enable_KeyService; return 0 ;; esac
        fi
    fi
    picked="$(Get_Home)"; [ -z "$picked" ] && picked="$(T "aucun, ou fenêtre de choix" "none, or a chooser")"
    Err "La TV n'accepte pas Zen Home sans son accueil d'origine : réactivation immédiate, rien n'est perdu." "The TV won't accept Zen Home without its original home screen: re-enabling it now, nothing is lost."
    Say "   Accueil retenu par la TV : $picked" "   Home screen picked by the TV: $picked" DarkGray
    for q in $toOff; do Sh "pm enable $q" >/dev/null; done
    Get_State
    for q in $toOff; do ST_DISABLED="$(printf '%s\n' "$ST_DISABLED" | grep -vxF -- "$q")"; done
    ST_LAUNCHER_DISABLED=""; Save_State
    Sh "input keyevent KEYCODE_HOME" >/dev/null
    [ $wraithKept = 1 ] && Say "   L'écran de secours Google a pris la place de l'accueil. Reconnectez le Wi-Fi comme indiqué ci-dessus, puis relancez l'option 3." "   The Google fallback screen took the home screen's place. Reconnect the Wi-Fi as explained above, then run option 3 again." DarkGray
    return 1
}

Complete_CosmosHome() {
    local orig="$1" before p changed=""
    before="$(Get_Packages -e)"
    Sh "am start -n $ZEN_PKG/.Home" >/dev/null
    YesNo "Vérifiez Zen Home, Entrées TV et Input → HDMI. Tout fonctionne avant de couper l'ancien accueil ?" "Check Zen Home, TV inputs and Input → HDMI. Does everything work before disabling the old home?" 0 || return 0
    if [ -n "$orig" ] && [ "$orig" != "$ZEN_PKG" ] && in_list "$orig" "$before"; then
        YesNo "Désactiver l'ancien accueil et ses recommandations (réversible) ?" "Disable the old home and its recommendations (reversible)?" 1 || return 0
        Disable_OrigHome "$orig" || return 0
    fi
    case "$(Get_Home)" in "$ZEN_PKG"/*) ;; *) Warn "Zen Home doit être l'accueil avant de continuer." "Zen Home must be the default home before continuing."; return 0 ;; esac
    if in_list com.google.android.tvrecommendations "$(Get_Packages -e)"; then Disable_Packages launcher com.google.android.tvrecommendations; fi
    Get_State
    for p in "$orig" com.google.android.tvrecommendations; do
        [ -n "$p" ] && in_list "$p" "$before" && in_list "$p" "$ST_DISABLED" && changed="$changed${changed:+ }$p"
    done
    if [ -n "$changed" ] && ! YesNo "Testez Accueil, Entrées TV, Input → HDMI et Netflix. Tout fonctionne ? (o = continuer / n = annuler ce lot)" "Test Home, TV inputs, Input → HDMI and Netflix. Everything works? (y = continue / n = undo this batch)" 0; then
        Undo_ProfileBatch $changed
        Get_State; ST_LAUNCHER_DISABLED=""; Save_State
        Sh "input keyevent KEYCODE_HOME" >/dev/null
        return 0
    fi
    Run_Profile zen
    Capture_TV zen_home
}

Do_Launcher() {
    local curHome title titleMode devName lc layout enabled i n k sel dockCsv="auto" found=() fnames=() pk=() r origPkg nowHome hasOrig
    case "$INFO_Brand $INFO_Manufacturer" in *Amazon*)
        Err "Fire TV : Amazon bloque le remplacement de l'écran d'accueil. Utilisez seulement l'allègement (menu 2)." "Fire TV: Amazon blocks replacing the home screen. Use slimming only (menu 2)."
        return ;;
    esac
    if [ ! -f "$APK_PATH" ]; then Err "ZenHome.apk introuvable dans ecran-accueil/" "ZenHome.apk not found in ecran-accueil/"; return; fi
    Ensure_Backup
    Get_State
    curHome="$(Get_Home)"
    case "$curHome" in ""|"$ZEN_PKG"/*) ;; *) [ -z "$ST_ORIGINAL_HOME" ] && { ST_ORIGINAL_HOME="$curHome"; Save_State; } ;; esac

    echo
    # --- titre ---
    devName="$(trim "$(Sh "settings get global device_name" | tr -d '\n')")"
    { [ -z "$devName" ] || [ "$devName" = "null" ]; } && devName="$INFO_Model"
    Say "Titre affiché en haut à gauche de l'écran d'accueil :" "Title shown at the top left of the home screen:" White
    Say "   Entrée = nom de la TV (« $devName »)   ·   tapez - pour ne rien afficher" "   Enter = the TV's name ('$devName')   ·   type - to show nothing" DarkGray
    title="$(trim "$(Ask "Titre (ex. « Accueil »)" "Title (e.g. 'Home')")")"
    if [ -z "$title" ]; then titleMode="device"; elif [ "$title" = "-" ]; then titleMode="none"; else titleMode="custom"; fi

    # --- disposition ---
    echo
    Say "Disposition du dock :" "Dock layout:" White
    echo "   1. $(T "4 applis, grandes tuiles" "4 apps, large tiles")"
    echo "   2. $(T "6 applis sur une ligne" "6 apps in one row")"
    echo "   3. $(T "8 applis sur deux lignes" "8 apps in two rows")"
    lc="$(trim "$(Ask "Votre choix (Entrée = 1)" "Your choice (Enter = 1)")")"
    case "$lc" in 2) layout=6 ;; 3) layout=8 ;; *) layout=4 ;; esac

    # --- applis du dock ---
    enabled="$(Get_Packages -e)"
    for i in "${!DOCK_PKGS[@]}"; do
        in_list "${DOCK_PKGS[$i]}" "$enabled" && { found[${#found[@]}]="${DOCK_PKGS[$i]}"; fnames[${#fnames[@]}]="${DOCK_NAMES[$i]}"; }
    done
    if [ ${#found[@]} -gt 0 ]; then
        echo
        Say "Applis trouvées pour le dock ($layout maximum) :" "Apps found for the dock ($layout max):" White
        for i in "${!found[@]}"; do printf '   %d. %s\n' $((i + 1)) "${fnames[$i]}"; done
        sel="$(Ask "Numéros dans l'ordre voulu, ex. 1,2,4 (Entrée = choix automatique)" "Numbers in the order you want, e.g. 1,2,4 (Enter = automatic)")"
        if [ -n "$(trim "$sel")" ]; then
            for n in $(printf '%s' "$sel" | tr ',;' '  '); do
                case "$n" in *[!0-9]*|"") continue ;; esac
                k=$((10#$n - 1))
                if [ $k -ge 0 ] && [ $k -lt ${#found[@]} ] && [ ${#pk[@]} -lt $layout ]; then
                    in_list "${found[$k]}" "$(printf '%s\n' "${pk[@]}")" || pk[${#pk[@]}]="${found[$k]}"
                fi
            done
            [ ${#pk[@]} -gt 0 ] && dockCsv="$(IFS=,; printf '%s' "${pk[*]}")"
        fi
    fi
    Say "   Vous pourrez tout changer ensuite directement sur la TV (appui long sur OK)." "   You can change everything later right on the TV (long-press OK)." DarkGray

    Say "Installation de Zen Home..." "Installing Zen Home..." Cyan
    Say ">>> Toshiba : « Appli non sécurisée bloquée » (Play Protect) : OK annule. Si un avertissement apparaît, choisissez « Plus de détails » puis « Installer quand même »." ">>> Toshiba: Play Protect may block this app; pressing OK cancels. If a warning appears, choose 'More details' then 'Install anyway'." Cyan
    r="$(A install -r "$APK_PATH" | tr '\n' ' ')"
    case "$r" in *Success*) ;; *) Err "Échec de l'installation : $r" "Install failed: $r"; Say "   Si la TV a affiché un avertissement Play Protect, relancez l'option 3 et choisissez « Plus de détails » puis « Installer quand même »." "   If the TV showed a Play Protect warning, run option 3 again and choose 'More details' then 'Install anyway'." DarkGray; return ;; esac
    Ok "Installé" "Installed"
    Sh "settings put global zenhome_title_mode $titleMode" >/dev/null
    if [ "$titleMode" = "custom" ]; then Sh "settings put global zenhome_title_b64 $(printf '%s' "$title" | base64 | tr -d '\n')" >/dev/null
    else Sh "settings delete global zenhome_title_b64" >/dev/null; fi
    Sh "settings put global zenhome_layout $layout" >/dev/null
    Sh "settings put global zenhome_dock $dockCsv" >/dev/null
    Sh "settings put global zenhome_rev $(date +%s)" >/dev/null   # la TV applique cette config
    Sh "pm grant $ZEN_PKG android.permission.READ_EXTERNAL_STORAGE" >/dev/null

    if Test_Cosmos; then
        Say "Fond noir : Zen Home mesuré à 35 Mo, contre 48 Mo avec photos (4 grandes tuiles). Remplace les photos actuelles." "Black background: Zen Home measured at 35 MB versus 48 MB with photos (4 large tiles). Replaces current photos." Cyan
        if YesNo "Appliquer le fond noir uni (recommandé) ?" "Apply the plain black background (recommended)?" 1; then Set_BlackBackground; fi
    fi

    Sh "cmd package set-home-activity $ZEN_PKG/.Home" >/dev/null
    Set_HomeRole "$ZEN_PKG"
    Sh "am force-stop $ZEN_PKG" >/dev/null
    Sh "input keyevent KEYCODE_HOME" >/dev/null
    sleep 6
    nowHome="$(Get_Home)"
    origPkg="${ST_ORIGINAL_HOME%%/*}"
    hasOrig=0; [ -n "$origPkg" ] && [ "$origPkg" != "$ZEN_PKG" ] && hasOrig=1
    if Test_Cosmos; then
        Complete_CosmosHome "$origPkg"
        Cosmos_Reminders
        return
    fi
    echo
    case "$nowHome" in
        "$ZEN_PKG"/*)
            Ok "Zen Home est l'écran d'accueil." "Zen Home is the home screen."
            if [ $hasOrig = 1 ]; then
                Say "L'écran d'accueil d'origine ($origPkg) tourne souvent en fond et consomme beaucoup." "The original home screen ($origPkg) often runs in the background and uses a lot of resources." White
                Warn "Sur certaines TV (surtout Google TV), la touche Source de la télécommande ne marche plus dans les applis une fois l'accueil d'origine désactivé. L'option 6 remet tout." "On some TVs (especially Google TV), the remote's Source button stops working inside apps once the original home screen is disabled. Option 6 puts everything back."
                if YesNo "Le désactiver (recommandé, réversible) ?" "Disable it (recommended, reversible)?" 1; then Disable_OrigHome "$origPkg"; fi
            fi ;;
        *)
            if [ $hasOrig = 1 ]; then
                # Google TV et d'autres refusent un autre accueil tant que le leur est actif : seule solution, le désactiver
                Warn "La TV garde son accueil d'origine ($origPkg) et refuse Zen Home tant qu'il est actif (fréquent sur Google TV)." "The TV keeps its original home screen ($origPkg) and refuses Zen Home while it is active (common on Google TV)."
                Say "Le kit peut le désactiver pour forcer Zen Home. Il vérifie ensuite que la TV accepte Zen Home, et réactive tout de suite l'accueil d'origine sinon." "The kit can disable it to force Zen Home. It then checks that the TV accepts Zen Home, and re-enables the original home screen right away otherwise." White
                Warn "Sur certaines TV (surtout Google TV), la touche Source de la télécommande ne marche plus dans les applis une fois l'accueil d'origine désactivé. L'option 6 remet tout." "On some TVs (especially Google TV), the remote's Source button stops working inside apps once the original home screen is disabled. Option 6 puts everything back."
                if YesNo "Forcer Zen Home (réversible) ?" "Force Zen Home (reversible)?" 1; then
                    Disable_OrigHome "$origPkg" && Ok "Zen Home est l'écran d'accueil." "Zen Home is the home screen."
                else Say "Rien n'a été désactivé. Zen Home reste disponible dans « Toutes les applis »." "Nothing was disabled. Zen Home stays available in 'All apps'." DarkGray; fi
            else
                Warn "La TV n'a pas confirmé Zen Home par défaut ($nowHome). Appuyez sur la touche Accueil : si un choix s'affiche, prenez « Zen Home » puis « Toujours »." "The TV did not confirm Zen Home as default ($nowHome). Press Home: if a chooser appears, pick 'Zen Home' then 'Always'."
            fi ;;
    esac
    Capture_TV "zen_home"
    echo
    Say "Sur la TV : appui long sur OK (ou touche Menu) sur une appli du dock pour la déplacer, la remplacer, la retirer, changer la disposition ou le titre." "On the TV: long-press OK (or the Menu key) on a dock app to move, replace or remove it, or change the layout or title." Cyan
    Get_Perf
    printf '%s   RAM %s : %s Mo%s\n' "$C_White" "$(T "disponible" "available")" "$PERF_DISPO" "$C_0"
}

# ---------------------------------------------------------------- 4. photos perso
Set_BlackBackground() {
        local blackPng="$KIT/ecran-accueil/fond-noir.png"
        if [ ! -f "$blackPng" ]; then Err "fond-noir.png introuvable dans ecran-accueil/" "fond-noir.png not found in ecran-accueil/"; return; fi
        Sh "rm -rf /sdcard/ZenHome" >/dev/null
        Sh "mkdir -p /sdcard/ZenHome" >/dev/null
        A push "$blackPng" /sdcard/ZenHome/noir.png >/dev/null
        Sh "pm grant $ZEN_PKG android.permission.READ_EXTERNAL_STORAGE" >/dev/null
        Sh "am force-stop $ZEN_PKG" >/dev/null
        Sh "input keyevent KEYCODE_HOME" >/dev/null
        Ok "Fond noir appliqué." "Black background applied."
}
Do_Photos() {
    if YesNo "Fond noir uni (le plus léger en mémoire) ?" "Plain black background (lightest on memory)?" 0; then Set_BlackBackground; return; fi
    local files=() f iv
    mkdir -p "$PHOTOS_DIR"
    for f in "$PHOTOS_DIR"/*; do
        [ -f "$f" ] || continue
        case "$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')" in *.jpg|*.jpeg|*.png|*.webp) files[${#files[@]}]="$f" ;; esac
    done
    echo
    Say "Dossier de vos photos : $PHOTOS_DIR" "Your photos folder: $PHOTOS_DIR" White
    if [ ${#files[@]} -eq 0 ]; then
        Warn "Aucune photo dedans. Copiez-y des .jpg (paysage, 1920×1080 idéalement) puis revenez ici." "No photos in it. Copy .jpg files there (landscape, ideally 1920×1080) then come back."
        if YesNo "Revenir aux photos fournies avec Zen Home ?" "Go back to the photos bundled with Zen Home?" 0; then
            Sh "rm -rf /sdcard/ZenHome" >/dev/null; Sh "am force-stop $ZEN_PKG" >/dev/null; Sh "input keyevent KEYCODE_HOME" >/dev/null
            Ok "Photos d'origine rétablies." "Bundled photos restored."
        fi
        open_path "$PHOTOS_DIR"
        return
    fi
    Say "${#files[@]} photo(s) à envoyer." "${#files[@]} photo(s) to send." White
    Sh "rm -rf /sdcard/ZenHome" >/dev/null
    Sh "mkdir -p /sdcard/ZenHome" >/dev/null
    for f in "${files[@]}"; do A push "$f" "/sdcard/ZenHome/$(basename "$f")" >/dev/null; printf '   → %s\n' "$(basename "$f")"; done
    Sh "pm grant $ZEN_PKG android.permission.READ_EXTERNAL_STORAGE" >/dev/null
    Sh "am force-stop $ZEN_PKG" >/dev/null
    Sh "input keyevent KEYCODE_HOME" >/dev/null
    sleep 5
    Capture_TV "photos_perso"
    Ok "Photos envoyées. Elles remplacent celles fournies." "Photos sent. They replace the bundled ones."
    iv="$(Ask "Secondes entre deux photos (Entrée = 60)" "Seconds between photos (Enter = 60)")"
    case "$iv" in ""|*[!0-9]*) ;; *) Sh "settings put global zenhome_interval $iv" >/dev/null; Sh "am force-stop $ZEN_PKG" >/dev/null; Sh "input keyevent KEYCODE_HOME" >/dev/null ;; esac
}

# ---------------------------------------------------------------- 6. restauration
Do_Restore() {
    local p r k v
    Get_State
    echo
    Say "Restauration : réactive tout ce que le kit a désactivé sur cette TV, remet l'écran d'accueil et les animations d'origine." "Restore: re-enables everything the kit disabled on this TV, puts back the original home screen and animations." White
    YesNo "Continuer ?" "Continue?" 1 || return
    Undo_ProfileBatch $ST_DISABLED
    Get_State
    if [ "$ST_HAS_ANIM" = 1 ]; then
        for k in window_animation_scale:"$ST_ANIM_WINDOW" transition_animation_scale:"$ST_ANIM_TRANSITION" animator_duration_scale:"$ST_ANIM_ANIMATOR"; do
            v="${k#*:}"; k="${k%%:*}"
            if [ -n "$v" ] && [ "$v" != "null" ]; then Sh "settings put global $k $v" >/dev/null; else Sh "settings delete global $k" >/dev/null; fi
        done
        Ok "Animations d'origine" "Original animations"
    fi
    case "$ST_ORIGINAL_HOME" in ""|"$ZEN_PKG"/*) ;; *) Sh "cmd package set-home-activity $ST_ORIGINAL_HOME" >/dev/null; Set_HomeRole "${ST_ORIGINAL_HOME%%/*}"; Ok "Écran d'accueil : $ST_ORIGINAL_HOME" "Home screen: $ST_ORIGINAL_HOME" ;; esac
    Disable_KeyService
    if in_list "$ZEN_PKG" "$(Get_Packages "")"; then
        if YesNo "Désinstaller Zen Home ?" "Uninstall Zen Home?" 1; then A uninstall "$ZEN_PKG" >/dev/null; Ok "Zen Home désinstallé" "Zen Home uninstalled"; fi
        for k in zenhome_title_b64 zenhome_title_mode zenhome_layout zenhome_dock zenhome_rev zenhome_interval; do Sh "settings delete global $k" >/dev/null; done
        Sh "rm -rf /sdcard/ZenHome" >/dev/null
    fi
    in_list "$ST_LAUNCHER_DISABLED" "$ST_DISABLED" || ST_LAUNCHER_DISABLED=""
    Save_State
    Sh "input keyevent KEYCODE_HOME" >/dev/null
    sleep 6
    Capture_TV "apres_restauration"
    if [ -n "$ST_DISABLED" ]; then Warn "Restauration incomplète : paquets conservés dans l'état, réessayez l'option 6." "Restore incomplete: packages retained in state, retry option 6."
    else Ok "Restauration terminée. Redémarrez la TV pour finir proprement." "Restore done. Restart the TV to finish cleanly."; fi
}

Run_Choice() {
    Ensure_TV || return 0
    case "$1" in
        1) Do_Backup ;;
        2) Do_Slim ;;
        3) Do_Launcher ;;
        4) Do_Photos ;;
        5) Capture_TV "capture"; [ -f "$CAPTURE" ] && open_path "$CAPTURE" ;;
        6) Do_Restore ;;
    esac
}

# ---------------------------------------------------------------- menu
while true; do
    clear
    printf '%s  ╔══════════════════════════════════════════════╗%s\n' "$C_DarkCyan" "$C_0"
    printf '%s  ║   %s  ║%s\n' "$C_DarkCyan" "$(T "Toshiba / Vestel Cosmos + Zen Home      " "Toshiba / Vestel Cosmos + Zen Home      ")" "$C_0"
    printf '%s  ╚══════════════════════════════════════════════╝%s\n' "$C_DarkCyan" "$C_0"
    Show_Profile
    if [ -f "$CONF_FILE" ]; then printf '%s   TV : %s  (%s)%s\n' "$C_Gray" "$(json_str "$CONF_FILE" label)" "$(json_str "$CONF_FILE" target)" "$C_0"
    else Say "   Aucune TV choisie" "   No TV selected" DarkGray; fi
    echo
    echo "   1. $(T "Diagnostic + sauvegarde (ne modifie rien)" "Diagnosis + backup (changes nothing)")"
    echo "   2. $(T "Alléger : pubs, télémétrie, applis inutiles" "Slim down: ads, telemetry, useless apps")"
    echo "   3. $(T "Installer l'écran d'accueil Zen Home" "Install the Zen Home launcher")"
    echo "   4. $(T "Mettre mes propres photos" "Use my own photos")"
    echo "   5. $(T "Capture d'écran de la TV" "Take a TV screenshot")"
    echo "   6. $(T "Tout restaurer comme avant" "Restore everything as before")"
    echo "   7. $(T "Choisir une autre TV" "Choose another TV")"
    echo "   0. $(T "Quitter" "Quit")"
    echo
    ch="$(trim "$(Ask "Votre choix" "Your choice")")"
    [ "$ch" = "0" ] && break
    if [ "$ch" = "7" ]; then rm -f "$CONF_FILE"; Choose_TV; Pause_Kit; continue; fi
    case "$ch" in 1|2|3|4|5|6) ;; *) continue ;; esac
    log="$SAVES/journal_$(date +%Y%m%d).txt"
    # Keep detected identity in this shell so the next menu can display its profile.
    { echo "===== $(date) - menu $ch ====="; Run_Choice "$ch"; } > >(tee -a "$log") 2>&1
    Pause_Kit
done
