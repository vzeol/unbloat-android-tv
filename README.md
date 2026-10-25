# Kit TV Toshiba (Vestel) Android TV : plus rapide, sans pubs

**TOSHIBA / VESTEL COSMOS EDITION** — Un accueil léger et un allègement réversible, testés sur une Toshiba 43QA4163DG.

**Français** · [English](README-en.md)


> [!WARNING]
> **Projet personnel partagé tel quel, sans aucune garantie.** Je ne suis pas responsable des problèmes que son utilisation pourrait causer à votre TV, à vos appareils ou à vos données. Chaque TV est différente : vérifiez votre modèle et lisez le profil avant de l’utiliser.

## Pour quelle TV ?

Le profil a été **testé sur une unité réelle en octobre 2026** : **Toshiba 43QA4163DG**, QLED 4K de 2022, fabriquée par Vestel. Elle tourne sous **Android TV 11 (SDK 30), pas Google TV**, avec le correctif de sécurité du **2025-08-01**. Les essais matériels et mesures ci-dessous proviennent de cette unité ; les scripts de cette édition sont vérifiés hors TV par simulation.

Vérifiez l’étiquette à l’arrière, puis **Paramètres → Préférences de l’appareil → À propos**. L’option **1** affiche aussi l’empreinte du firmware (fingerprint) :

```text
Vestel/Cosmos170/yeoksam:11/RTOC.251019.001/14296264:user/release-keys
```

| Identification observée | Valeur |
|---|---|
| Fabricant / marque Android | `Vestel` / `Vestel` |
| Modèle / appareil / produit Android | `Cosmos` / `yeoksam` / `Cosmos170` |
| Mémoire | 1,3 Go (`MemTotal 1368668 kB`), zram 512 Mo, `ro.config.low_ram=true` |
| Processeur / ABI | MediaTek, 4 cœurs, `armeabi-v7a` (32 bits) |
| Stockage `/data` | 4,2 Go, auparavant rempli à 85 % |
| Interface | 1920 × 1080 à 60 Hz uniquement, malgré la dalle 4K |
| Vidéo | HDR10, HLG, Dolby Vision ; décodage matériel H.264, HEVC, VP9, MPEG-2, VC-1 et Dolby Vision |
| AV1 | Logiciel uniquement, trop lent sur cette TV |

Les 50/55/65QA4163DG sont **probablement** proches : comparez leur fingerprint. Vestel distribue ce firmware sous plusieurs marques, dont Toshiba, JVC, Hitachi et Telefunken. L’empreinte est identique à celle de l’exemple espagnol `examples/toshiba-cosmos-android-tv` de [CleanYourTV](https://github.com/Gathin23/cleanyourtv/tree/main/examples/toshiba-cosmos-android-tv). Ce rapprochement ne vaut pas un test sur chaque variante.

Le profil est proposé si le fabricant **ou** la marque vaut Vestel et si l’appareil est `yeoksam` **ou** le modèle `Cosmos`. Un firmware différent déclenche un avertissement : lisez [le profil](scripts/profils/toshiba-cosmos.txt) avant de continuer.

Les autres Android TV restent prises en charge par les **listes génériques**, avec leurs listes et chemins propres à chaque marque. Cette édition est un fork MIT du [projet d’origine xMazaki/unbloat-android-tv](https://github.com/xMazaki/unbloat-android-tv). Les résultats Toshiba ne préjugent pas de ceux d’une autre TV. Fire TV conserve les limites du projet d’origine pour le remplacement de l’accueil.

## Résultats mesurés

Mesures au repos sur l’accueil, environ 8 à 13 minutes après redémarrage dans les mêmes conditions, sauf les relevés explicitement pris après 9 jours sans redémarrage. Valeurs arrondies, pas une promesse de gain identique.

| Mesure | Avant | Après |
|---|---|---|
| RAM disponible | ~470 Mo | ~520 Mo |
| Swap zram utilisé | ~230 Mo | ~164 Mo |
| Mémoire de l’accueil | 127 Mo peu après démarrage ; 212 Mo + 30 Mo de swap après 9 jours | Zen Home : 48 Mo avec photos ; **35 Mo avec fond noir**, 4 grandes tuiles |
| Mémoire réellement utilisée par les applis (`dumpsys meminfo`, « used pss ») | 870 Mo, après 9 jours | 587 Mo |
| Stockage libre | 683 Mo | ~1 Go **après désinstallation manuelle d’applis inutilisées** |

Le kit désactive les paquets ; il ne les désinstalle pas. Le gain de stockage ne vient donc pas de la seule désactivation. Android garde volontairement environ 300 Mo d’applis récentes en cache pour les relancer immédiatement. La RAM « disponible » ne reflète pas tout le gain.

Le changement le plus sensible : la TV est utilisable dès l’apparition de l’accueil après l’allumage. Elle ne se dégrade plus au fil des jours dans les essais de cette unité.

## Préparer la TV (5 minutes)

1. Allumez la TV et mettez-la sur le même réseau local que l’ordinateur.
2. Ouvrez **Paramètres → Préférences de l’appareil → À propos**. Appuyez **7 fois sur OK sur « Build »**.
3. Revenez dans **Options pour les développeurs → Débogage USB** et activez-le.
4. Sur cette Toshiba, ce seul réglage ouvre ADB réseau sur le **port 5555**. Il n’y a **aucun bouton séparé de débogage réseau ou sans fil**, ni de jumelage à faire.
5. Retrouvez l’adresse réseau dans **Paramètres → Réseau**, ou **À propos → État**. Vous la saisirez dans le kit. Validez l’autorisation de débogage affichée sur la TV.

Réveillez la TV avant chaque connexion : le Wi-Fi s’arrête en veille et ADB se coupe. Sur une autre marque, suivez les options de débogage proposées par son firmware ; le kit conserve la connexion avec jumelage quand elle existe.

## Utilisation

Décompressez tout le kit dans un dossier. Gardez `scripts/`, `ecran-accueil/` et les lanceurs ensemble. Au premier lancement, le kit télécharge les outils ADB officiels de Google s’ils ne sont pas déjà installés.

| Ordinateur | Lancer |
|---|---|
| Windows | Double-cliquer sur `LANCER.bat` |
| macOS | Ouvrir `LANCER.command` (clic droit → Ouvrir si nécessaire) |
| Linux | `./LANCER.sh` ; si nécessaire `bash LANCER.sh` |

Suivez **1 → 2 → 3 → 4 (facultatif)** :

1. **Diagnostic + sauvegarde.** Vérifiez le modèle, le fingerprint et le message « Profil testé détecté : Toshiba / Vestel Cosmos (43QA4163DG) ».
2. **Alléger → Suivre le profil testé (recommandé).** Le kit ne propose que les paquets présents et actifs. Un accord couvre les éléments d’office d’un lot. Pour « Utilisez-vous… ? », répondez **non** pour désactiver. Les choix personnels des essais ne sont pas imposés. Testez après chaque lot. **n** à « Tout fonctionne ? » réactive seulement ce que ce lot vient de désactiver, puis arrête le profil. Les lots précédents restent appliqués. La démo magasin est traitée seule avec un test Input immédiat.
3. **Installer Zen Home.** Le dock propose **4 grandes tuiles** par défaut. Le fond noir est proposé par défaut sur Cosmos (35 Mo contre 48 Mo avec photos). Vérifiez Zen Home et les entrées avant d’accepter de couper l’ancien accueil. Sur ce firmware, l’ancien accueil refuse un autre accueil par défaut tant qu’il est actif : le kit lance d’abord Zen Home pour l’essai, puis désactive l’ancien accueil et vérifie le résultat. `com.google.android.tvlauncher` et `com.google.android.tvrecommendations` ne passent jamais par le profil de l’option 2. Le lot accueil a son propre retour arrière. Les lots « Masquer les tuiles à risque », puis « Synthèse vocale » sont proposés ensuite, dans l’ordre testé. Si Zen Home est déjà l’accueil, l’option 2 peut aussi proposer ces lots.
4. **Photos (facultatif).** Placez vos images paysage dans `mes_photos/` (1920 × 1080 conseillé), puis utilisez l’option 4. Elle permet aussi le fond noir et le retour aux photos fournies. Le fond noir remplace les photos personnalisées présentes sur la TV.

**Play Protect :** pour Zen Home (`targetSdk 24`), la TV affiche **« Appli non sécurisée bloquée »**. Choisissez **« Plus de détails » → « Installer quand même »**. Appuyer simplement sur **OK annule l’installation**. Relancez l’option 3 si elle a été annulée.

Pour modifier Zen Home ensuite : appui long sur OK ou bouton « Modifier l’accueil ». La tuile **« Entrées TV »** reconnaît `com.mediatek.wwtv.tvcenter` ; la touche **Input** fonctionne aussi avec Zen Home sur l’unité testée.

## Ce que le profil désactive

Les lignes et les tests bilingues sont dans [scripts/profils/toshiba-cosmos.txt](scripts/profils/toshiba-cosmos.txt). Rien n’est désinstallé. Chaque lot exige son test avant la suite. Les lots après Zen Home sont différés tant que l’accueil n’est pas installé et vérifié.

### Télémétrie et services inutiles

| Paquet | Fonction | Pourquoi | Mode |
|---|---|---|---|
| `com.vestel.vestelreporter` | Rapports Vestel | Rapports non nécessaires au fonctionnement. | D’office, après confirmation du lot |
| `android.autoinstalls.config.vestel.cosmos` | Installations automatiques partenaires | Évite les installations partenaires. | D’office, après confirmation du lot |
| `com.google.android.feedback` | Rapports Google | Rapports facultatifs. | D’office, après confirmation du lot |
| `com.google.android.syncadapters.calendar` | Synchronisation de l'agenda | Pas d’agenda utilisé sur cette TV. | D’office, après confirmation du lot |
| `com.android.printspooler` | Service d'impression | Pas d’impression depuis la TV. | D’office, après confirmation du lot |
| `com.google.android.apps.nbu.smartconnect.tv` | Smart Connect (compteur de données et VPN) | Service non utilisé. | D’office, après confirmation du lot |
| `com.google.android.play.games` | Google Play Jeux | Jeux Google non utilisés. | D’office, après confirmation du lot |
| `com.google.android.videos` | Google Play Films | Films Google non utilisés. | D’office, après confirmation du lot |

### Fonctions inutilisées : vos choix

| Paquet | Fonction | Pourquoi | Mode |
|---|---|---|---|
| `com.google.android.katniss` | Assistant Google (Hey Google depuis téléphone ou Nest) | Télécommande sans micro ; gardez-le si vous utilisez Hey Google depuis un téléphone/Nest. | Question : non pour désactiver |
| `com.google.android.youtube.tvmusic` | YouTube Music | Choix selon votre usage musical. | Question : non pour désactiver |
| `com.mediatek.wwtv.mediaplayer` | Lecteur de clé USB MediaTek | Gardez-le pour lire une clé USB avec ce lecteur. | Question : non pour désactiver |
| `com.mediatek.tv.freeviewplay` | Guide Freeview Play britannique | Guide britannique non utilisé ici. | Question : non pour désactiver |
| `com.cltv.fast` | Chaînes FAST avec publicité (ce n'est pas la TV en direct) | Chaînes publicitaires, distinctes de la TV en direct. | D’office, après confirmation du lot |
| `com.google.android.backdrop` | Économiseur d'écran Google | Fond ambiant Google non utilisé. | Question : non pour désactiver |

### Démo magasin : test Input immédiat

| Paquet | Fonction | Pourquoi | Mode |
|---|---|---|---|
| `fusion.android.tv.demo` | Démo magasin (peut gérer Input sur d'autres cartes) | Démo inutile ici ; risque Input sur certaines cartes MTC. | Séparément + test immédiat |

### Lot 3 — Accueil Zen Home

Le lot accueil, réservé à **l’option 3** :

| Paquet | Fonction | Pourquoi | Mode |
|---|---|---|---|
| `com.google.android.tvlauncher` | Accueil Android TV classique | Publicités et mémoire qui augmente avec le temps | Accord après essai de Zen Home |
| `com.google.android.tvrecommendations` | Recommandations de l’ancien accueil | Inutiles avec Zen Home | Avec le lot accueil, après vérification |

### Masquer les tuiles à risque

| Paquet | Fonction | Pourquoi | Mode |
|---|---|---|---|
| `com.vestel.tv.eib` | Manuel électronique Vestel | Masque le manuel si vous ne le consultez pas. | Question : non pour désactiver |
| `com.vestel.tv.speedup` | System Speed Up (nettoyeur inutile) | Évite le nettoyeur et sa tuile. | D’office, après confirmation du lot |
| `com.mstar.android.tv.disclaimercustomization` | Avertissement de première configuration | Avertissement de configuration déjà passée. | D’office, après confirmation du lot |
| `mediatek.factorymenu.ui` | Écrans du menu usine (pas le service com.mediatek.tv.factory) | Évite une manipulation usine accidentelle ; garde le service usine. | Question : non pour désactiver |

### Synthèse vocale

| Paquet | Fonction | Pourquoi | Mode |
|---|---|---|---|
| `com.google.android.tts` | Synthèse vocale Google (accessibilité) | Seulement si aucune fonction d’accessibilité n’en a besoin. | Question : non pour désactiver |

Déjà désactivés avant les essais : `com.google.android.marvin.talkback`, `com.google.android.tv.remote.service` et les paquets `uk.co.freeview.*` suivants : `mdsclient`, `amc_catchup`, `onnow`, `uktv`, `fvpconfigauth`, `bbc_sounds`, `tifbridge`, `explore`, `bbc`, `ch5`, `itv`, `stv`, `amc_horror`, `ch4_vod`. Le profil les laisse tels quels ; il ne les réactive pas automatiquement, y compris lors de l’annulation d’un lot.

## Ce qu’on garde et pourquoi

| Paquet conservé | Pourquoi |
|---|---|
| `com.mediatek.wwtv.tvcenter` | TV en direct, HDMI et touche Input : protégé |
| `com.google.android.apps.mediashell` | Chromecast conservé ; optionnel en mode générique |
| `com.google.android.youtube.tv` | YouTube utilisé et touche dédiée |
| `com.amazon.amazonvideo.livingroom` | Prime Video utilisé et touche dédiée |
| `com.netflix.ninja` | Netflix utilisé et touche dédiée |
| `com.mediatek.wwtv.webview` | Navigateur HbbTV non testé, laissé intact |
| `com.google.android.leanbacklauncher.partnercustomizer` | Évite les plantages de tv.service et la perte de la touche Input |
| `com.google.android.tungsten.setupwraith` | Assistant système conservé sur Cosmos |
| `com.vestel.tv.service` | Service central Vestel |
| `com.vestel.tv.servicepatch` | Correctifs du service Vestel |
| `com.vestel.tv.keycontroller` | Gestion de la télécommande |
| `com.vestel.tv.backlight` | Rétroéclairage |
| `com.vestel.tv.rcupdater` | Mise à jour de la télécommande |
| `com.mediatek.tv.service` | Service TV central et observateur Netflix |
| `com.mediatek.tvinput` | Entrées TV |
| `com.mediatek.tv.factory` | Service usine en arrière-plan : ne jamais toucher |
| `com.mediatek.tvinputservice.arbitratorservice` | Arbitrage des entrées |
| `com.mediatek.network` | Réseau MediaTek |
| `com.android.vending` | Play Store |
| `com.google.android.gms` | Services Google Play |
| `com.google.android.inputmethod.latin` | Clavier Gboard |

Les paquets de fonctionnement TV de cette table sont protégés dans les scripts, ainsi que les protections existantes (réglages, Play Store, services Google, clavier, etc.). Chromecast n’est pas protégé : on peut le retirer volontairement dans la liste facultative générique. Sur les autres Google TV, le traitement existant de l’accueil de secours `setupwraith` reste possible dans l’option 3 ; **il est toujours conservé sur Cosmos**.

Deux tuiles de « Toutes les applis » restent visibles et sont sans danger : **« com.mstar.netflixobserver »**, une activité de `com.mediatek.tv.service` (probablement la touche Netflix), et **« Service API Vestel »**, `com.vestel.tv.service/.PasswordDialogActivity`. Ne désactivez pas les services pour les cacher. Le shell de ce firmware ne peut pas désactiver un composant isolé d’une appli système (« Shell cannot change component state »).

## Pièges connus sur cette TV

| Point | À retenir |
|---|---|
| Télécommande IR, sans microphone | Assistant n’est utile ici que pour Hey Google depuis un téléphone/Nest selon l’usage. |
| Touches YouTube et Prime Video | Gérées par le firmware Vestel sous Android. Si l’appli est désactivée, sa touche ne fait rien. Aucun remappage possible. |
| Touche Input | Tester après chaque lot, surtout `fusion.android.tv.demo`. Ne jamais couper `tvcenter`, `partnercustomizer` ou les services TV. `com.cltv.fast` n’est pas la TV en direct. |
| Play Protect | « Plus de détails » → « Installer quand même ». OK seul annule. |
| Captures d’écran | `screencap` écrit du texte parasite avant le PNG (« Init wrapper sys mutex successful… », « open mma dev failed »). Le kit conserve la capture dans un fichier sur la TV, puis le transfert ; pas de `exec-out screencap -p`. |
| Veille | Le Wi-Fi s’éteint ; réveillez la TV avant de reconnecter ADB. |
| Options pour les développeurs | Couper seulement Débogage USB à la fin. Couper le commutateur général réinitialise animations et limite des processus. |
| Animations | Elles étaient déjà à 0,0. Le kit ne les remonte jamais ; il ne réduit que les valeurs supérieures à 0,5. |
| Freeview | Des paquets peuvent déjà être désactivés sur les modèles hors Royaume-Uni. Laissez-les dans cet état si tout fonctionne. |
| Navigateur HbbTV | `com.mediatek.wwtv.webview` n’a pas été testé désactivé et reste intact. |

## Après le kit

Facultatif, à régler **à la main** : **Options pour les développeurs → Limite des processus en arrière-plan → 2**. C’est le compromis utilisé sur 1,3 Go. Avec **0**, chaque appli redémarre à froid et perd sa position. Le kit ne force pas ce réglage.

À la fin, désactivez seulement **Débogage USB**. Gardez les Options pour les développeurs actives pour conserver vos réglages. Les mises à jour système restent actives ; certaines peuvent réactiver des applis. L’option 1 signale les réactivations depuis le passage du kit.

À envisager selon vos usages : SmartTube, LocalSend, Aerial Views.

## Retour en arrière

L’**option 6** réactive les paquets enregistrés par le kit, remet l’accueil et les animations d’origine et propose de désinstaller Zen Home. Elle ne réactive pas les paquets déjà désactivés avant le kit. L’annulation d’un lot ne touche que ce lot ; si une réactivation échoue, le paquet reste dans l’état pour réessayer avec l’option 6.

Conservez **`sauvegardes/<identifiant local>/etat_kit.json`** et les sauvegardes : ce fichier contient les paquets modifiés et les réglages d’origine. Le kit vérifie l’identité de la TV avant chaque action. Ces fichiers et `config_tv.json` sont privés et exclus du suivi Git : **ne les partagez pas**. Le kit enregistre ces données localement à l’usage ; aucun relevé personnel de la TV testée n’est fourni dans cette édition.

Sans ordinateur : **Paramètres → Applis → Voir toutes les applis → Afficher les applis système → choisir l’appli → Activer**. En dernier recours, la **réinitialisation d’usine réactive tout**, et efface aussi les comptes, applis et réglages.

## Responsabilité

Ce kit est un projet personnel, partagé gratuitement **tel quel, sans aucune garantie**. En l’utilisant, vous acceptez que :

- **je ne suis pas responsable** des problèmes, pannes, pertes de données, dysfonctionnements ou annulations de garantie que son utilisation pourrait causer, directement ou indirectement ;
- vous l’utilisez **à vos propres risques**, sur un appareil qui vous appartient ;
- il vous revient de vérifier que le kit convient à votre TV avant de l’utiliser, et de l’adapter si nécessaire (voir « Pour quelle TV ? » et le profil).

Le kit n’est ni affilié, ni soutenu par Toshiba, Vestel, Google, TCL, Sony, Philips, Xiaomi, Amazon ou un autre fabricant. Les noms de marques cités appartiennent à leurs propriétaires.

## Crédits et licence

- **Projet d’origine :** [xMazaki/unbloat-android-tv](https://github.com/xMazaki/unbloat-android-tv), licence MIT. Cette édition conserve les autres marques et ne modifie ni l’APK Zen Home ni ses sources Java.
- **Référence Vestel :** [CleanYourTV, examples/toshiba-cosmos-android-tv](https://github.com/Gathin23/cleanyourtv/tree/main/examples/toshiba-cosmos-android-tv), même fingerprint sur une unité du marché espagnol.
- **Listes génériques :** [Universal Android Debloater NG](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation), [CleanYourTV](https://github.com/Gathin23/cleanyourtv), [shield_optimizer](https://github.com/bryanroscoe/shield_optimizer), [dumbtv](https://github.com/humblemuzzu/dumbtv) et guides communautaires.
- **Photos :** 19 « Featured pictures » de Wikimedia Commons, CC BY-SA. Attributions conservées dans [CREDITS.md](CREDITS.md).
- **Police :** Poppins, SIL Open Font License.
- **ADB :** Android SDK Platform-Tools de Google, téléchargé depuis le site officiel au premier lancement.
- **Code du kit et de Zen Home :** MIT, voir [LICENSE](LICENSE).
