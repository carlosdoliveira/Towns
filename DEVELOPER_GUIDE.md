# Towns — Developer Guide

This guide is intended for developers who want to understand, build, maintain, or mod the Towns game. It covers the overall architecture, the main systems, the data-driven configuration layer, and the build process.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Repository Layout](#2-repository-layout)
3. [Build Process](#3-build-process)
4. [Architecture Overview](#4-architecture-overview)
5. [Entry Point and Bootstrap](#5-entry-point-and-bootstrap)
6. [Core Systems](#6-core-systems)
   - 6.1 [World & Map](#61-world--map)
   - 6.2 [Entities](#62-entities)
   - 6.3 [Tasks](#63-tasks)
   - 6.4 [Actions](#64-actions)
   - 6.5 [Pathfinding (A\*)](#65-pathfinding-a)
   - 6.6 [Map Generation](#66-map-generation)
   - 6.7 [Dungeon Generation](#67-dungeon-generation)
   - 6.8 [Zones](#68-zones)
   - 6.9 [Stockpiles](#69-stockpiles)
   - 6.10 [Caravans & Trade](#610-caravans--trade)
   - 6.11 [Effects](#611-effects)
   - 6.12 [Skills (Heroes)](#612-skills-heroes)
   - 6.13 [Gods](#613-gods)
   - 6.14 [Events](#614-events)
   - 6.15 [Campaigns & Missions](#615-campaigns--missions)
   - 6.16 [Terrain & Fluids](#616-terrain--fluids)
7. [UI & Rendering](#7-ui--rendering)
8. [Audio](#8-audio)
9. [Configuration Files (.ini)](#9-configuration-files-ini)
10. [Data Files (XML)](#10-data-files-xml)
11. [Save / Load System](#11-save--load-system)
12. [Modding System](#12-modding-system)
13. [Logging & Error Handling](#13-logging--error-handling)
14. [Key Classes Quick Reference](#14-key-classes-quick-reference)

---

## 1. Project Overview

Towns is a colony management / dungeon-builder game written in **Java**. The game uses **LWJGL** (Lightweight Java Game Library) for OpenGL rendering and OpenAL audio, and **JNA** for optional Steam integration.

The source lives under `src/xaos/` (the package root is `xaos`).

---

## 2. Repository Layout

```
Towns/
├── CHANGELOG.md          — version history
├── LICENSE               — GNU GPL v3
├── README.md             — project intro
└── src/
    ├── audio.ini         — audio settings
    ├── graphics.ini      — graphics / tileset / UI mappings
    ├── towns.ini         — main game configuration
    └── xaos/             — all Java source code
        ├── Towns.java         — application entry point
        ├── TownsProperties.java — compile-time constants (debug flags, etc.)
        ├── actions/           — Action and ActionManager (citizen work steps)
        ├── campaign/          — Campaign, Mission, Tutorial system
        ├── caravans/          — Merchant caravan logic
        ├── data/              — Plain data-holder objects (DTOs)
        ├── dungeons/          — Underground dungeon generation & management
        ├── effects/           — Status effects (poison, buffs, etc.)
        ├── events/            — Scripted world events
        ├── generator/         — Procedural map & item generators
        ├── gods/              — God / religion mechanics
        ├── main/              — Game.java (singleton) & World.java (game state)
        ├── panels/            — All UI panels and the main rendering loop
        ├── property/          — .ini property wrappers
        ├── skills/            — Hero skill system
        ├── stockpiles/        — Stockpile areas
        ├── tasks/             — High-level player orders (Task)
        ├── tiles/             — Tile, Cell, Entity hierarchy (buildings, items, living)
        │   ├── entities/
        │   │   ├── buildings/ — Building entity
        │   │   ├── items/     — Item, Container, MilitaryItem
        │   │   └── living/    — LivingEntity, Citizen, Hero, Enemy, Ally, Friendly, Projectile
        │   └── terrain/       — Terrain types, Water, Lava
        ├── utils/             — A*, OpenGL helpers, XML utils, audio, fonts, etc.
        └── zones/             — Zone (Hospital, Barracks, HeroRoom, Personal, etc.)
        data/
        ├── actions.xml        — definitions of all citizen actions
        ├── buildings.xml      — building definitions
        ├── campaigns.xml      — campaign & mission metadata
        ├── caravans.xml       — caravan merchandise lists
        ├── effects.xml        — status effect definitions
        ├── events.xml         — world event triggers & outcomes
        ├── gen_events.xml     — map-generation event hooks
        ├── gods.xml           — god definitions (likes/dislikes, events)
        ├── heroes.xml         — hero definitions
        ├── items.xml          — all item definitions
        ├── livingentities.xml — all living entity definitions (citizens, monsters, animals)
        ├── matspanel.xml      — materials panel layout
        ├── menu.xml           — main context menu
        ├── menu_production.xml— production sub-menu
        ├── menu_right.xml     — right-click context menu
        ├── names.xml          — random name pool
        ├── prefixsuffix.xml   — magic item prefix/suffix definitions
        ├── prices.xml         — default trade prices
        ├── priorities.xml     — worker priority definitions
        ├── skills.xml         — hero skill definitions
        ├── terrain.xml        — terrain type definitions
        ├── types.xml          — item category (type) definitions
        └── zones.xml          — zone type definitions
```

---

## 3. Build Process

The project is a plain Java project using **LWJGL 2.x** and **JNA**. There is no build script committed to the repository, but the process is straightforward:

### Dependencies

| Library | Purpose |
|---------|---------|
| LWJGL 2.x | OpenGL rendering + OpenAL audio + keyboard/mouse input |
| JNA (Java Native Access) | Loading the Steam API native library (`steam_api` / `steam_api64`) |

### Compilation steps

1. **Obtain LWJGL 2.x** — download from [lwjgl.org](https://www.lwjgl.org/). You need `lwjgl.jar` plus the native libraries for your OS (`lwjgl-natives-*.jar` or the unpacked `.dll`/`.so`/`.dylib` files).
2. **Obtain JNA** — download `jna.jar` from [GitHub](https://github.com/java-native-access/jna/releases).
3. **Compile** all `.java` files under `src/` with both jars on the classpath:
   ```bash
   javac -cp "lwjgl.jar:jna.jar" -sourcepath src -d out \
       src/xaos/Towns.java
   ```
4. **Run** the game from the `src/` directory (so the `.ini` files are resolved relative to the working directory):
   ```bash
   cd src/
   java -cp "../out:lwjgl.jar:jna.jar" \
        -Djava.library.path=<path-to-lwjgl-natives> \
        xaos.Towns
   ```

> **Note:** The game reads `towns.ini` and `graphics.ini` from the current working directory on startup. All asset paths configured in those files are relative to that directory.

### IDE setup (Eclipse / IntelliJ)

- Set the source root to `src/`.
- Add `lwjgl.jar` and `jna.jar` to the module/project classpath.
- Add the LWJGL natives directory to the JVM library path (`-Djava.library.path=...`).
- Mark `xaos.Towns` as the main class.
- Set the working directory to `src/` so the `.ini` files are found.

---

## 4. Architecture Overview

```
Towns (main)
│
├── Game (singleton, static) ────────────────────────────────────────┐
│   Controls: game state machine, panels, settings, save/load        │
│                                                                     │
├── World (serializable) ───────────────────────────────────────────┐│
│   Holds: cells[][][] map, entities, stockpiles, zones, events ...  ││
│                                                                     ││
├── Rendering loop (Game constructor / LWJGL Display)                ││
│   MainPanel (world view) ◄──────────────────────────────── World ◄─┘│
│   CommandPanel (bottom HUD)                                         │
│   UIPanel (right panel)                                             │
│   MessagesPanel (message log)                                       │
│   MiniMapPanel (overview)                                           │
│                                                                     │
└── Task (player order) ──► Citizen/Hero ──► Action (work step) ◄────┘
         ▲
         │ created by
    ContextMenu / SmartMenu (right-click UI)
```

The game runs a single-threaded **turn loop** inside the LWJGL display loop. Every N frames (controlled by `World.FRAMES_PER_TURN` and `World.SPEED`) the game advances one "turn", ticking all entities, processing fluids, running events, etc. Pathfinding is offloaded to a separate thread via `AStarQueue`.

---

## 5. Entry Point and Bootstrap

**`xaos.Towns`** — `main(String[] args)`

1. Optionally loads the Steam API native library via JNA (`SteamAPI_Init`).
2. Instantiates `new Game()`.

**`xaos.main.Game`** (constructor)

1. Reads `towns.ini` / `graphics.ini` via `Towns.getPropertiesString(...)`.
2. Creates the LWJGL `Display` window.
3. Initialises OpenGL and loads all textures (`loadAllIniTextures()`).
4. Creates the main UI panels (`MainPanel`, `CommandPanel`, `UIPanel`, `MessagesPanel`, `MiniMapPanel`, `MainMenuPanel`).
5. Enters the main render/game loop.
6. Routes keyboard/mouse input to the appropriate panel or task system.

Static helpers on `Game`:

| Method | Purpose |
|--------|---------|
| `startGame(campaignID, missionID)` | Begin a new game for the given mission |
| `continueGame(savegameName, ...)` | Resume a saved game |
| `setupGame(...)` | Internal — wires up map gen, loads world |
| `getWorld()` | Access the current `World` instance |
| `exit()` | Clean shutdown |
| `createTask(taskID)` | Dispatch a player order |

---

## 6. Core Systems

### 6.1 World & Map

**`xaos.main.World`** is the central game-state object. It is **serializable** (`Externalizable`) so it can be saved and loaded.

Key fields:

| Field | Description |
|-------|-------------|
| `Cell[][][] cells` | 3-D grid: `[x][y][z]`, size `MAP_WIDTH × MAP_HEIGHT × MAP_DEPTH` (200×200×64 max) |
| `citizenIDs`, `soldierIDs`, `heroIDs` | Lists of entity IDs for each living-entity type |
| `buildings` | All placed `Building` instances |
| `items` | All `Item` instances keyed by ID |
| `containers` | All `Container` instances |
| `stockpiles` | All `Stockpile` instances |
| `zones` | All `Zone` instances |
| `events`, `globalEvents` | Active and global scripted events |
| `coins` | Current gold/coin count |
| `turn` | Current turn counter |
| `date` | In-game date (year/month/day/hour) |
| `taskManager` | Manages the queue of pending `Task` objects |

**`Cell`** (`xaos.tiles.Cell`) represents a single grid cell. It holds:
- The `Terrain` tile.
- Up to one `Building` reference.
- A list of `Item` references.
- A list of `LivingEntity` references.
- Visibility / discovery flags.
- Zone ID for A\* pathfinding partitioning.

**Time constants** (in `World`): `TIME_MODIFIER_HALF_MINUTE`, `TIME_MODIFIER_MINUTE`, `TIME_MODIFIER_HOUR`, `TIME_MODIFIER_DAY`, `TIME_MODIFIER_MONTH`, `TIME_MODIFIER_YEAR` — used throughout the codebase for scheduling recurring events.

---

### 6.2 Entities

All in-world objects extend `xaos.tiles.entities.Entity`.

```
Entity
├── Building       — static constructions; require materials to complete
├── Item           — movable/equippable objects
│   ├── Container  — items that hold other items
│   └── MilitaryItem — weapons/armour with optional prefix/suffix enchants
└── LivingEntity   — autonomous actors
    ├── Citizen    — player-controlled townspeople (can become soldiers)
    ├── Hero       — special adventurer characters with skills
    ├── Enemy      — hostile NPCs
    ├── Ally       — friendly NPCs under the player's control
    ├── Friendly   — passive/neutral NPCs
    └── Projectile — fired arrows/bolts
```

#### LivingEntity stats (`LivingEntityData`)

| Stat | Description |
|------|-------------|
| `healthPoints` | Current HP |
| `healthPointsMAXBase/Current` | Maximum HP (base + modifiers) |
| `attackBase/Current` | Attack value |
| `attackSpeedBase/Current` | How fast the entity attacks |
| `defenseBase/Current` | Defense value |
| `damageBase/Current` | Damage per hit |
| `LOSBase/Current` | Line-of-sight range |
| `movePCTBase/Current` | Movement percentage modifier |
| `walkSpeedBase/Current` | Walking speed |
| `moral` | Morale counter |
| `effects` | Active `EffectData` list (status effects) |

#### Citizen specifics (`CitizenData`)

- Tracks hunger, sleep, happiness.
- Has a `SoldierData` companion that controls patrol points, guard state, and soldier group membership.
- Citizens are assigned to `CitizenGroups` for batch commands.

#### Hero specifics (`HeroData`)

- Tracks XP, level, skill points.
- Has a `FocusData` for targeting.
- Uses a `HeroSkills` component and `HeroBehaviour` for AI decision-making.
- Requires prerequisite items/zones via `HeroPrerequisite`.

#### Building lifecycle

1. Player places a build order → a `Building` is created with `operative = false` and a list of `prerequisites` (required items).
2. Citizens haul the materials to the site.
3. When all prerequisites are met, `setOperative(true, true)` is called.
4. Operative buildings can produce items (queue-based production or `nonStop` mode).

---

### 6.3 Tasks

**`xaos.tasks.Task`** represents a **player order**. Tasks are the bridge between player input and citizen behaviour.

Key task IDs (constants on `Task`):

| Constant | Description |
|----------|-------------|
| `TASK_DIG` | Dig down (create a floor below) |
| `TASK_MINE` | Mine a wall tile |
| `TASK_MINE_LADDER` | Mine and place a ladder |
| `TASK_BUILD` | Construct a building |
| `TASK_DESTROY_BUILDING` | Demolish a building |
| `TASK_CREATE` | Craft an item |
| `TASK_CREATE_IN_A_BUILDING` | Craft in a specific building |
| `TASK_HAUL` | Move an item to a stockpile |
| `TASK_WEAR` / `TASK_WEAR_OFF` | Equip/unequip a citizen |
| `TASK_AUTOEQUIP` | Auto-equip best available gear |
| `TASK_CONVERT_TO_SOLDIER` / `_TO_CIVILIAN` | Toggle citizen/soldier role |
| `TASK_FIGHT` | Engage in combat |
| `TASK_HEAL` | Seek healing |
| `TASK_SLEEP` | Sleep in a bed |
| `TASK_EAT` | Eat food |
| `TASK_STOCKPILE` | Define a stockpile area |
| `TASK_CREATE_ZONE` / `TASK_DELETE_ZONE` | Zone management |
| `TASK_TERRAIN_RAISE` / `LOWER` / `CHANGE` | Terraform |
| `TASK_TERRAIN_ADD_FLUID` / `REMOVE_FLUID` | Place/remove water or lava |
| `TASK_MOVE_TO_CARAVAN` | Move item to trade with caravan |
| `TASK_QUEUE` / `TASK_QUEUE_AND_PLACE` | Production queue commands |
| `TASK_SOLDIER_SET_STATE` | Change soldier AI state (guard/patrol/boss) |
| `TASK_CUSTOM_ACTION` | Execute a data-driven custom action from `actions.xml` |

**`TaskManager`** maintains the list of all active tasks. When a citizen becomes idle, it searches this list for a task it can perform.

**`HotPoint`** — a spatial hint attached to a task indicating where work needs to happen, used by citizens to determine proximity and route selection.

---

### 6.4 Actions

**`xaos.actions.Action`** is a single **work step** that a citizen is currently executing (e.g., "walk to tile X", "mine for N turns", "pick up item Y").

An action has:
- `id` — string key matching an entry in `actions.xml`
- `turns` — countdown to completion (decremented each game turn)
- `terrainPoint` / `destinationPoint` — spatial context
- `entityID` — item or living entity reference
- `queue` — an ordered list of `QueueItem` steps for complex multi-step actions
- `face` — rotation of the item being placed

**`ActionManager`** (data manager) loads all action definitions from `actions.xml` and returns `ActionManagerItem` definitions by key.

**`ActionPriorityManager`** loads `priorities.xml` and controls which job types a citizen will accept, in what order — the in-game priorities screen modifies this.

---

### 6.5 Pathfinding (A\*)

**`xaos.utils.AStarQueue`** runs on a dedicated background thread. Any code that needs a path for a `LivingEntity` calls `AStarQueue.addRequest(item)` and the result is picked up asynchronously.

**`AStarBinaryHeap`** / **`AStarNodo`** implement the actual A\* algorithm over the 3-D cell grid.

The map is partitioned into **A\* zones** (IDs on each `Cell`). When buildings are placed or removed, `World.setRecheckASZID(true)` triggers a zone ID recomputation so the pathfinder can quickly determine whether two points are reachable at all before launching a full search.

---

### 6.6 Map Generation

**`xaos.generator.MapGenerator`** reads `gen_map.xml` (inside the campaign/mission folder hierarchy) and procedurally generates the cell grid.

Key concepts:

- **Seeds** (`SeedData`, `HeightSeedData`) — random placement anchors used to scatter terrain features.
- **Bezier curves** (`BezierData`) — used to generate rivers, paths, and geological features.
- **Generator / GeneratorItem / GeneratorNode** — a simple tree of XML-driven generation instructions. Each `GeneratorItem` has a name, a value (which can be a dice expression like `2d6+3`), and child items.
- **`ItemGenerator`** / **`LivingEntityGenerator`** — scatter items and living entities on the map at generation time.

The generator supports **mission-specific overrides**: for each file (e.g., `gen_map.xml`) it looks in the campaign/mission subfolder first, then falls back to the base `data/` folder.

---

### 6.7 Dungeon Generation

**`xaos.dungeons.DungeonManager`** loads `gen_dungeons.xml` and maintains a list of `DungeonData` entries.

**`DungeonGenerator`** — when a dungeon is triggered (usually after the player digs to a certain depth), it spawns the dungeon's `MonsterData` entries into the world.

Each `DungeonData` has:
- `level` — which underground floor the dungeon occupies
- A list of `MonsterData` entries (which living-entity type, how many)

---

### 6.8 Zones

Zones are player-designated rectangular areas that assign a function to a region.

**`xaos.zones.Zone`** — base class. Fields: `iniHeader` (type key), `ID`, `points` (list of cells), `operative`.

Subtypes:

| Class | Purpose |
|-------|---------|
| `ZonePersonal` | Personal room for a specific citizen |
| `ZoneHeroRoom` | Room that attracts/unlocks a specific hero type |
| `ZoneBarracks` | Military quarters for soldiers |

Zone types are defined in `zones.xml` and loaded by **`ZoneManager`** (returns `ZoneManagerItem` definitions by key).

Citizens and heroes use zone membership to determine where to sleep, eat, and store personal items.

---

### 6.9 Stockpiles

**`xaos.stockpiles.Stockpile`** — a set of cells designated to store items of a given `Type` (item category).

- Each stockpile has a `type` (e.g., food, raw materials, weapons).
- `filledPoints` tracks how many cells already hold an item.
- `lockedToCopy` — prevents the configuration from being overwritten by copy/paste.

When items are dropped or produced, the hauling system checks available stockpile space to determine where to route them.

---

### 6.10 Caravans & Trade

**`xaos.caravans.CaravanManager`** loads `caravans.xml` and returns `CaravanManagerItem` definitions (what a particular merchant type sells/buys).

**`CaravanItemData`** / **`CaravanItemDataInstance`** — per-item trade data (price, stock).

**`PricesManager`** loads `prices.xml` for base item valuations.

**`CaravanData`** (in `World`) holds the state of the currently-visiting caravan: which items are on offer, the player's pending trade items, and the negotiation state.

The **`TradePanel`** UI presents the trade interface and dispatches `TASK_MOVE_TO_CARAVAN` tasks for items the player wants to sell.

---

### 6.11 Effects

**`xaos.effects.EffectManager`** loads `effects.xml`. Each `EffectManagerItem` defines:

- Duration and tick behaviour
- Stat modifiers (attack, defense, HP, speed, etc.)
- `afterEffects` — effects applied when this one expires
- `onHitEffects` / `onRangedHitEffects` — effects applied when the carrier deals damage
- `effectsImmune` — effects this entity is immune to if it has this effect
- `castEffects` — effects applied to the target when this entity attacks

Effects are stored as `EffectData` objects in each `LivingEntityData.effects` list and are ticked every turn.

---

### 6.12 Skills (Heroes)

**`xaos.skills.SkillManager`** loads `skills.xml`. Each `SkillManagerItem` defines:

- XP cost to unlock
- `SkillEffectItem` list — concrete stat changes or special behaviours granted

**`HeroSkills`** tracks which skills a given `Hero` has learned.

Skills can unlock new combat abilities, passive bonuses, or special interactions with the world.

---

### 6.13 Gods

**`xaos.gods.GodManager`** loads `gods.xml`. Each `GodManagerItem` defines:

- Items the god **likes** (offerings that increase approval)
- Items the god **dislikes** (offerings that decrease approval)
- `eventsWhenHappy` — events triggered when the god is pleased
- `eventsWhenAngry` — events triggered when the god is displeased

**`GodData`** (in `World`) tracks the current happiness level for each active god.

The god system links into the event system to fire blessings or punishments.

---

### 6.14 Events

**`xaos.events.EventManager`** loads `events.xml`. Each `EventManagerItem` defines a scripted occurrence:

- Trigger conditions (population, date, random chance, min population)
- Outcomes (spawn entities, modify world, show message, etc.)

**`EventData`** tracks an active event instance. **`GlobalEventData`** holds always-on global modifiers.

Events are checked on a timer each turn. The `gen_events.xml` file defines generation-time events (fired during map generation).

---

### 6.15 Campaigns & Missions

**`xaos.campaign.CampaignManager`** loads `campaigns.xml` and builds an `ArrayList<CampaignData>`.

Each `CampaignData` has a list of `MissionData` entries. A `MissionData` holds:
- Map generation parameters (path to the mission folder)
- `ObjectiveData` list — win/loss conditions
- Optional tutorial flag

**`TutorialFlow`** / **`TutorialTrigger`** drive the image-based tutorial system. Triggers are checked each turn; when fired, they display a tutorial image panel.

The active mission is stored in `Game.getCurrentMissionData()` and consulted throughout the game for objective tracking (shown in `MissionPanel`).

---

### 6.16 Terrain & Fluids

**`xaos.tiles.terrain.Terrain`** is a single terrain tile (grass, stone, dirt, sand, water, lava, …). Terrains are defined in `terrain.xml` and loaded by **`TerrainManager`** (returns `TerrainManagerItem` by key).

Special terrain subclasses:

| Class | Description |
|-------|-------------|
| `Water` | Simulated fluid; flows between cells |
| `Lava` | Simulated fluid; damages entities |
| `StockpileTile` | Visual overlay for stockpile areas |
| `Orders` | Visual overlay for pending dig/mine orders |
| `MouseCursor` / `MouseCursorBAD` | Mouse highlight overlays |

**Fluid simulation** runs in `World` each turn: up to `FLUIDS_MOVED_PER_INVOCATION` (64) fluid cells are processed. Fluids flow downhill and can evaporate up to `FLUIDS_MAX_EVAPORATION` level.

**Terraforming** (added in v14d) uses `TASK_TERRAIN_RAISE`, `TASK_TERRAIN_LOWER`, and `TASK_TERRAIN_CHANGE` tasks. Items can have a `maxAgeTerrain` tag that defines what terrain they turn into when they "die".

---

## 7. UI & Rendering

All rendering uses **LWJGL OpenGL 1.x / 2.x** (immediate mode). Helper utilities:

| Class | Purpose |
|-------|---------|
| `UtilsGL` | Texture loading, sprite rendering helpers |
| `UtilFont` | Bitmap font rendering (`cantarell_17.fnt`) |
| `UtilsAL` | OpenAL audio (music + FX) |
| `ColorGL` | OpenGL colour helpers |
| `ImageData` / `TextureData` | Texture cache |

**Panels:**

| Class | Description |
|-------|-------------|
| `MainPanel` | Renders the 3-D isometric world view. Handles mouse clicks to create tasks. |
| `MainFrame` | Top-level LWJGL Display setup |
| `MainMenuPanel` | Title screen and loading screen |
| `CommandPanel` | Bottom HUD bar (buttons, citizen info) |
| `UIPanel` | Right-side panel (citizens list, priorities, etc.) |
| `MessagesPanel` | Scrollable message log |
| `MiniMapPanel` | Overhead minimap |
| `TradePanel` | Caravan trade interface |
| `TypingPanel` | Text input (e.g., naming zones) |
| `ImagesPanel` | Full-screen image display (tutorial images) |
| `InfoPanel` | Entity detail panel |
| `MissionPanel` | Objectives display |
| `ContextMenu` | Right-click contextual menu |
| `SmartMenu` | Dynamic sub-menu generation |

**Rendering coordinates:** The world uses an isometric projection. Each cell is rendered as an angled tile. The `view` field in `World` is the camera position (`Point3D`). Keyboard shortcuts scroll and zoom the view (see `towns.ini` for key bindings).

---

## 8. Audio

Audio is configured in `audio.ini` (not committed; resolved at runtime from the user folder or the working directory). Settings are also in `towns.ini`:

```ini
MUSIC = false
VOLUME_MUSIC = 10
FX = false
VOLUME_FX = 10
AUDIO_FOLDER = data/audio/
```

`UtilsAL` wraps OpenAL for both music streaming and sound effects. Music and FX can be toggled at runtime from the options menu, which writes back to the user's `towns.ini`.

---

## 9. Configuration Files (.ini)

### `towns.ini` (main)

| Key | Description |
|-----|-------------|
| `WINDOW_WIDTH` / `WINDOW_HEIGHT` | Initial window size (min 1024×600) |
| `DATA_FOLDER` | Path to the `data/` directory |
| `GRAPHICS_FOLDER` | Path to the graphics assets |
| `AUDIO_FOLDER` | Path to audio assets |
| `CAMPAIGNS_FOLDER` | Path to campaign folders |
| `USER_FOLDER` | Override for per-user save/mod folder |
| `FPS_MAINMENU` / `FPS_INGAME` | Frame rate caps |
| `MUSIC` / `FX` | Enable music / sound effects |
| `VOLUME_MUSIC` / `VOLUME_FX` | Volume 0–10 |
| `MOUSE_SCROLL` | Enable edge-of-screen scrolling |
| `MOUSE_2D_CUBES` | Show 2-D cube mouse cursor |
| `SIEGES` | Siege difficulty (`0`=off, `1`=easy … `5`=insane) |
| `ALLOW_BURY` | Enable the online Bury feature |
| `PATHFINDING_LEVEL` | CPU usage for pathfinding (1–3) |
| `MODS` | Comma-separated list of active mod IDs |
| `SERVERS` | Bury server URL |
| `FN_*` | Keyboard shortcut bindings |

Properties are read lazily via `Towns.getPropertiesString()` / `getPropertiesInt()`. The user folder's copy of `towns.ini` overrides the base file.

### `graphics.ini`

Maps every graphical asset to a texture file and tile coordinates. Format:
```
[tile_id]TILE_X = <column>
[tile_id]TILE_Y = <row>
[tile_id]TILE_HEIGHT = <pixel height>
[tile_id]TEXTURE_FILE = <filename>
[tile_id]COLOR_MINIMAP = <r,g,b>
```

This file drives `UtilsGL` and `Tile` to look up the correct sprite for every game object.

---

## 10. Data Files (XML)

All XML files are loaded by their corresponding `*Manager` class. They support **mod overrides** (see §12). Every manager follows the same pattern:
1. Load from `data/<file>.xml`.
2. For each active mod, load from `<userFolder>/mods/<modID>/data/<file>.xml` and merge/override.
3. `<DELETE id="...">` tags remove entries added by a previous file.

### `livingentities.xml`

Defines all living entities (citizens, enemies, animals). Key attributes per entity:
- `name`, `iniHeader` — display name and internal ID
- `healthPoints`, `attack`, `defense`, `damage`, `attackSpeed`, `LOS`, `walkSpeed`, `movePCT`
- `canFly`, `canSwim` — movement flags
- `hostile` — whether this entity attacks citizens
- `drops` — item drop table on death
- `effects` — inherent status effects

### `items.xml`

Defines every item. Key attributes:
- `name`, `iniHeader`
- `type` — item category (references `types.xml`)
- `buildTime` — turns to craft
- `prerequisites` — items required to craft
- `productionBuilding` — which building produces this item
- `nonStop` — whether the building continuously produces this
- `canEquip` — whether citizens/heroes can wear it
- `stats` — combat stat modifiers when equipped
- `maxAgeTerrain` — terrain this item becomes when it decays

### `buildings.xml`

Defines every building. Key attributes:
- `name`, `iniHeader`
- `size` — footprint in tiles
- `ground` — cell-by-cell walkability map (`E`=entrance, `1`=walkable, `0`=blocked, `X`=no-build)
- `prerequisites` — items required to build
- `produces` — items this building can produce

### `actions.xml`

Defines citizen action templates. Each action has:
- A string ID matching `Action.id`
- Required tool/item
- Turn duration
- Movement and interaction flags

### `zones.xml`

Defines zone types. Each zone has:
- `iniHeader`, display name
- Whether it grants sleeping/eating/working functionality
- Maximum occupants

### `skills.xml`

Defines hero skills: XP cost and a list of `SkillEffectItem` modifiers.

### `effects.xml`

Defines status effects: duration, stat modifiers, chain effects (see §6.11).

### `gods.xml`

Defines gods: item preferences, happiness events (see §6.13).

### `events.xml`

Defines scripted world events: triggers, conditions, and outcomes (see §6.14).

### `campaigns.xml`

Lists campaigns and their missions. Each mission references a subfolder under `CAMPAIGNS_FOLDER` containing its own XML overrides.

### `caravans.xml`

Lists caravan types with their inventories (item ID, quantity, price).

### `types.xml`

Defines item categories (`Type`) used by stockpiles to filter what they accept.

### `prefixsuffix.xml`

Defines magic prefixes and suffixes for procedurally generated `MilitaryItem`s.

---

## 11. Save / Load System

The save system uses Java's **Externalizable** interface. `World` and most entities implement `readExternal` / `writeExternal`.

Save files are stored in `<userFolder>/save/<name>/` and are zip-compressed (`Utils.saveGame()` / `Utils.loadGame()`).

**Version constants** in `Game`:

| Constant | Version |
|----------|---------|
| `SAVEGAME_V9_V10a` | 1 |
| `SAVEGAME_V10b` | 2 |
| `SAVEGAME_V11` | 3 |
| `SAVEGAME_V12` | 4 |
| `SAVEGAME_V13` | 5 |
| `SAVEGAME_V14` | 6 |
| `SAVEGAME_V14d` | 7 |
| `SAVEGAME_V14e` | 8 (current) |

`Game.SAVEGAME_LOADING_VERSION` is set while loading so that `readExternal` methods can branch on the version for backward compatibility.

**Autosave** is controlled by `autosaveDays` in `towns.ini`. `World.currentAutosaveDays` counts down and triggers a save when it reaches zero.

---

## 12. Modding System

Towns has a built-in mod loader. Mods override game data by placing XML files in:

```
<userFolder>/mods/<modID>/data/<filename>.xml
```

And graphics in:

```
<userFolder>/mods/<modID>/graphics.ini
```

Active mods are listed (comma-separated) in `towns.ini` under `MODS=`.

Mod loading rules:
- Mods are loaded in the order listed in `MODS=`.
- An XML element with the same `iniHeader` replaces the base definition.
- A `<DELETE id="...">` element removes an existing definition.
- Graphics `.ini` entries are merged on top of the base `graphics.ini`.

Campaign missions can also override any data file by placing it in the mission subfolder:
```
<CAMPAIGNS_FOLDER>/<campaignID>/<missionID>/data/<filename>.xml
```

---

## 13. Logging & Error Handling

**`xaos.utils.Log`** — simple static logger with three levels:

| Level | Constant |
|-------|---------|
| Debug | `Log.LEVEL_DEBUG` |
| Warning | `Log.LEVEL_WARNING` |
| Error | `Log.LEVEL_ERROR` |

Debug logging is gated by `TownsProperties.DEBUG_MODE` (compile-time constant). Error-level logs are written to a log file and, for fatal errors, `Game.exit()` is called.

**`Game.iError`** — integer error code set before crash, logged in the `Towns.main` catch-all.

---

## 14. Key Classes Quick Reference

| Class | Package | Role |
|-------|---------|------|
| `Towns` | `xaos` | Entry point, .ini property access |
| `TownsProperties` | `xaos` | Compile-time flags (debug mode, etc.) |
| `Game` | `xaos.main` | Singleton: window, loop, state, panels |
| `World` | `xaos.main` | All game state; 3-D cell grid |
| `Cell` | `xaos.tiles` | A single map cell |
| `Tile` | `xaos.tiles` | A renderable sprite (terrain, overlay) |
| `Terrain` | `xaos.tiles.terrain` | Terrain tile instance |
| `TerrainManager` | `xaos.tiles.terrain` | Loads `terrain.xml` |
| `Building` | `xaos.tiles.entities.buildings` | Placed structure |
| `BuildingManager` | `xaos.tiles.entities.buildings` | Loads `buildings.xml` |
| `Item` | `xaos.tiles.entities.items` | In-world item |
| `ItemManager` | `xaos.tiles.entities.items` | Loads `items.xml` |
| `MilitaryItem` | `xaos.tiles.entities.items.military` | Weapon/armour with enchant support |
| `LivingEntity` | `xaos.tiles.entities.living` | Base actor class |
| `Citizen` | `xaos.tiles.entities.living` | Townie; can become a soldier |
| `Hero` | `xaos.tiles.entities.living.heroes` | Special hero character |
| `Enemy` | `xaos.tiles.entities.living.enemies` | Hostile NPC |
| `LivingEntityManager` | `xaos.tiles.entities.living` | Loads `livingentities.xml` |
| `Task` | `xaos.tasks` | Player order |
| `TaskManager` | `xaos.tasks` | Queue of pending tasks |
| `Action` | `xaos.actions` | Single citizen work step |
| `ActionManager` | `xaos.actions` | Loads `actions.xml` |
| `ActionPriorityManager` | `xaos.actions` | Loads `priorities.xml` |
| `Zone` | `xaos.zones` | Designated area (barracks, room, …) |
| `ZoneManager` | `xaos.zones` | Loads `zones.xml` |
| `Stockpile` | `xaos.stockpiles` | Item storage area |
| `MapGenerator` | `xaos.generator` | Procedural world generation |
| `DungeonManager` | `xaos.dungeons` | Loads and spawns dungeons |
| `EffectManager` | `xaos.effects` | Loads `effects.xml` |
| `SkillManager` | `xaos.skills` | Loads `skills.xml` |
| `GodManager` | `xaos.gods` | Loads `gods.xml` |
| `EventManager` | `xaos.events` | Loads `events.xml` |
| `CampaignManager` | `xaos.campaign` | Loads `campaigns.xml` |
| `CaravanManager` | `xaos.caravans` | Loads `caravans.xml` |
| `AStarQueue` | `xaos.utils` | Background-thread pathfinding dispatcher |
| `UtilsGL` | `xaos.utils` | OpenGL sprite rendering helpers |
| `UtilsAL` | `xaos.utils` | OpenAL audio helpers |
| `UtilsXML` | `xaos.utils` | XML parsing helpers |
| `Utils` | `xaos.utils` | Save/load, dice rolling, misc |
| `Log` | `xaos.utils` | Logging |
| `MainPanel` | `xaos.panels` | World view renderer and mouse handler |
| `CommandPanel` | `xaos.panels` | Bottom HUD |
| `UIPanel` | `xaos.panels` | Right-side panel |
| `MessagesPanel` | `xaos.panels` | Message log |
| `MiniMapPanel` | `xaos.panels` | Minimap |
| `TradePanel` | `xaos.panels` | Caravan trade UI |
