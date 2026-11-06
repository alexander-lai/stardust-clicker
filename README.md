# ⭐ Stardust Clicker

An original Roblox clicker simulator: click to collect Stardust, buy upgrades, hatch space pets that boost your earnings, and rebirth for a permanent multiplier. Progress saves with DataStores.

**Core loop:** Click → buy **Bigger Clicks** / **Star Collector** → hatch eggs for pets (your best 3 auto-equip and multiply everything) → **Rebirth** (reset Stardust and upgrades, keep pets, earn +50% forever) → repeat, faster.

**Egg Roll (RNG):** roll for free every 1.5s (or turn on Auto) for 10 eggs from *Plain* (1 in 1) to *Singularity* (1 in 250,000). Your rarest egg ever found multiplies all Stardust, up to x25. **Lucky Stars** upgrades and rebirths raise your luck, and 1-in-1,000+ rolls are announced to the whole server.

**Map:** a colorful candy-space world built in code when the server starts: rainbow plaza, paths and arches, candy trees, glowing crystals, floating islands and planets in the sky.

## What's in here

```
stardust-clicker/
├─ default.project.json          Rojo map: which file goes where in Studio
├─ rokit.toml                    pins the Rojo version
└─ src/
   ├─ shared/   → ReplicatedStorage > Shared
   │   ├─ Config.luau            ALL game numbers (prices, pets, odds). Edit me!
   │   └─ Util.luau              number formatting (1.2K, 3.4M...)
   ├─ server/   → ServerScriptService
   │   ├─ GameServer.server.luau clicks, shop, eggs, rebirth, leaderstats, world
   │   ├─ DataService.luau       DataStore load/save
   │   └─ MapBuilder.luau        builds the colorful map + lighting
   ├─ client/   → StarterPlayer > StarterPlayerScripts
   │   └─ PetFollowers.client.luau pets that orbit your character
   └─ gui/      → StarterGui > MainUI (ScreenGui)
       └─ ClickerUI.client.luau  builds the whole UI in code
```

The file ending tells you the script type: `.server.luau` = **Script**, `.client.luau` = **LocalScript**, plain `.luau` = **ModuleScript**.

RemoteEvents (`ReplicatedStorage > Remotes`) are created automatically by the server, so you don't need to make them by hand.

---

## Step 1: Install Roblox Studio

1. Go to **https://create.roblox.com** and sign in with your Roblox account.
2. Click **Start Creating** (or "Download Studio"), run the installer, and sign in when Studio opens.

## Step 2: Make a place and turn on saving

1. In Studio, click **New** → **Baseplate**.
2. **File → Publish to Roblox** → "Create new game" → name it *Stardust Clicker* → **Create**. (DataStores only work on a published place.)
3. **Home → Game Settings → Security** → turn on **Enable Studio Access to API Services** → **Save**.

Skip step 2 and 3 if you just want to try it: the game still runs, but it shows "Saving is OFF".

## Step 3: Get the scripts into Studio

Pick **one** option.

### Option A: Rojo (recommended, keeps code in files for GitHub)

Rojo syncs the files in this folder into Studio live while you edit.

1. **Install Rokit** (a tool installer): open https://github.com/rojo-rbx/rokit/releases, download the `windows-x86_64` zip from the newest release, unzip it, then in a terminal in that folder run:
   ```powershell
   .\rokit.exe self-install
   ```
   Close and reopen your terminal afterwards.
2. In this project folder, install Rojo and its Studio plugin:
   ```powershell
   rokit install
   rojo plugin install
   ```
3. Restart Studio, open your place, then start syncing:
   ```powershell
   rojo serve
   ```
4. In Studio, open the **Plugins** tab → **Rojo** → **Connect**. The scripts appear in the Explorer. Leave `rojo serve` running while you work.

### Option B: Copy-paste (no extra tools)

In Studio's **Explorer** panel (View → Explorer if hidden), hover an object and click **+** to insert. Create these exactly (names matter), then paste each file's contents into the matching script:

| Where | Insert | Name it | Paste from |
|---|---|---|---|
| ReplicatedStorage | Folder | `Shared` | |
| ReplicatedStorage > Shared | ModuleScript | `Config` | `src/shared/Config.luau` |
| ReplicatedStorage > Shared | ModuleScript | `Util` | `src/shared/Util.luau` |
| ServerScriptService | Script | `GameServer` | `src/server/GameServer.server.luau` |
| ServerScriptService | ModuleScript | `DataService` | `src/server/DataService.luau` |
| ServerScriptService | ModuleScript | `MapBuilder` | `src/server/MapBuilder.luau` |
| StarterPlayer > StarterPlayerScripts | LocalScript | `PetFollowers` | `src/client/PetFollowers.client.luau` |
| StarterGui | ScreenGui | `MainUI` | (then untick **ResetOnSpawn** in Properties) |
| StarterGui > MainUI | LocalScript | `ClickerUI` | `src/gui/ClickerUI.client.luau` |

Replace the default `print("Hello world!")` in each new script with the pasted code.

## Step 4: Play-test

Press **Play** (or F5). Then check:

- [ ] The top bar shows your Stardust, and the leaderboard (top right) shows **Stardust** and **Rebirths**.
- [ ] Clicking the big **CLICK!** button (or the glowing crystal) gives Stardust with a "+1" pop.
- [ ] At 15 Stardust, **Bigger Clicks** turns green; buy it and clicks give +2.
- [ ] **Star Collector** gives Stardust every second without clicking.
- [ ] At 100 Stardust, hatch a **Space Egg**: a message appears, the pet shows in the left panel, and a glowing ball orbits you.
- [ ] At 10K Stardust, **Rebirth** resets Stardust and upgrades but keeps pets, and the boost goes up.
- [ ] **ROLL!** shows a rolling animation and lands on an egg; a new best egg raises the boost in the top bar. **AUTO** keeps rolling.
- [ ] Stop, press Play again: your progress is still there (only if you did Step 2).

Problems? Open **View → Output**. Red text = an error with the script name and line number. Most issues are a misnamed object in Option B.

**Tip:** to test faster, temporarily change `BaseClickGain = 1` to `1000` in `Config.luau`.

## Publish to Roblox (make it playable for everyone)

**Shortcut:** instead of Step 3, build one ready-made place file and open it in Studio:

```powershell
rojo build default.project.json -o StardustClicker.rbxlx
```

The world looks empty in edit mode. That's expected: the server builds the map, spawn point and Star Crystal when the game starts.

1. Open the place in Studio (**File → Open from File** → `StardustClicker.rbxlx`) and press **Play** once to check it works.
2. **File → Publish to Roblox** → **Create new experience** → name *Stardust Clicker*, genre *Simulation*, pick devices (Computer, Phone, Tablet) → **Create**.
3. Optional, for testing saves in Studio: **Game Settings → Security → Enable Studio Access to API Services**. Saving always works in the live game.
4. Go to **https://create.roblox.com/dashboard/creations**, click your experience, and:
   - Fill out the **Maturity & Compliance** questionnaire. Roblox requires it before an experience can go public. Answer honestly: this game has no violence, chat features beyond the default, or paid items.
   - Under **Settings / Audience**, switch it from Private to **Public**.
   - Optional: upload an **icon** (512×512) and **thumbnails** so it looks good in search.
5. Click **Play** on the experience page to play the live version and share the link with friends.

**Updating an already-published game with a new build:** open the new `StardustClicker.rbxlx`, then **File → Publish As…** and pick your existing *Stardust Clicker* (not a new experience) to overwrite it.

**Updating later:** open the published place in Studio (it shows in Studio's home screen), run `rojo serve` and connect the plugin so your changes sync in, then **File → Publish to Roblox** (Alt+P) again.

## Step 5: Make it yours

Everything is in `src/shared/Config.luau`: add pets, change egg odds, prices, rebirth bonus. Ideas for next features:

- Show pets to other players (create them on the server instead of the client)
- Gamepasses (2x Stardust) with `MarketplaceService`
- More worlds unlocked by rebirths, or a global leaderboard with `OrderedDataStore`
- Sounds and particle effects on click and hatch

## Put it on GitHub

From this folder:

```powershell
git init
git add .
git commit -m "Stardust Clicker: clicker sim with pets, upgrades, rebirths, saving"
gh repo create stardust-clicker --public --source . --push
```

## How it's built (good for interviews)

- **Server-authoritative:** the client only sends requests ("I clicked", "buy this"); the server checks prices and owns all values, so exploiters can't give themselves money.
- **Rate-limited clicks:** the server ignores more than 20 clicks per second.
- **Safe saving:** retries on failure, autosaves every 60s, saves on leave and on server shutdown, and never saves if loading failed (so a glitch can't wipe a real save).
- **Data-driven design:** all balance numbers live in one shared config used by both server and UI.
