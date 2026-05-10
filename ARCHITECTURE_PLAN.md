# План модульного разделения Incremental

## Главный принцип

Проект **не переписывается с нуля**. Текущие рабочие `IncrementalServer` и `IncrementalClient` аккуратно делятся на модули. Gameplay, имена value-объектов, RemoteEvent-ы, Workspace/ReplicatedStorage references, циклы и unlock-логика должны остаться прежними.

`MainServer.lua` и `MainClient.lua` должны быть только bootstrap-скриптами: они собирают общий контекст, подключают модули, вызывают `Init()` в правильном порядке и не содержат gameplay logic.

## Текущие источники логики

- Server gameplay переносится из `IncrementalServer.txt`.
- Client UI/runtime переносится из `IncrementalClient.txt`.
- Уже существующие сервисные модули сохраняются и подключаются в новой структуре: `Modules/RuneSystemService.lua`, `Modules/LeaderboardService.lua`.

## Общие правила переноса

1. Переносить только существующую рабочую логику, без fake placeholder systems.
2. Делать по 2 системы за этап.
3. После каждого этапа проверять runtime, GUI, boards, rebirths, unlocks, currencies, remotes, output.
4. Не менять названия существующих RemoteEvent-ов:
   - `PurchaseUpgrade`
   - `PurchaseRebirth`
   - `AdminAction`
   - `Notify`
   - `WoodClick`
   - `FactoryAction`
   - `PassiveAction`
   - `RuneAction`
   - `XPAction`
5. Не менять names/folders у player data, потому что клиент уже ждёт эти объекты через `WaitForChild`.
6. Общие config tables лучше сначала вынести в shared server/client modules только если они уже используются несколькими системами. На первом этапе можно оставить config рядом с системой, из которой он переносится.

---

# SERVER SIDE

## Итоговая структура

```text
ServerScriptService
├── MainServer.lua
├── Modules
│   ├── RuneSystemService.lua
│   └── LeaderboardService.lua
└── Systems
    ├── Core
    │   ├── ServerContext.lua
    │   ├── RemoteRegistry.lua
    │   ├── PlayerDataSystem.lua
    │   ├── GamepassSystem.lua
    │   └── AdminEventSystem.lua
    ├── CoinSystem.lua
    ├── WoodSystem.lua
    ├── PaperFactorySystem.lua
    ├── HaySystem.lua
    ├── RebirthSystem.lua
    ├── SaveSystem.lua
    ├── XPSystem.lua
    ├── PassiveSystem.lua
    ├── LeaderboardSystem.lua
    ├── UpgradeBoards
    │   ├── CoinUpgradeBoard.lua
    │   ├── WoodUpgradeBoard.lua
    │   ├── PaperUpgradeBoard.lua
    │   ├── XPUpgradeBoard.lua
    │   └── HayUpgradeBoard.lua
    ├── RuneSystems
    │   ├── RuneStatsSystem.lua
    │   ├── RuneRollSystem.lua
    │   ├── RuneInventorySystem.lua
    │   ├── RuneSessionSystem.lua
    │   ├── RuneLuckSystem.lua
    │   ├── RuneSpeedSystem.lua
    │   ├── RuneBulkSystem.lua
    │   └── RuneIndexSystem.lua
    └── Runes
        ├── NatureRune.lua
        ├── ForestRune.lua
        ├── HayRune.lua
        ├── PaperRune.lua
        └── BaseRuneSet.lua
```

## Server bootstrap

### `ServerScriptService/MainServer.lua`

**Type:** server bootstrap.

**Responsibility:**

- require `Systems/Core/ServerContext.lua`;
- initialize remotes first;
- initialize data/save systems before gameplay systems;
- initialize gameplay systems in dependency order;
- bind player lifecycle once;
- contain no purchase math, roll math, save serialization, board logic, or UI logic.

**Init order target:**

1. `ServerContext`
2. `RemoteRegistry`
3. `PlayerDataSystem`
4. `GamepassSystem`
5. `AdminEventSystem`
6. `XPSystem`
7. `PassiveSystem`
8. `RuneStatsSystem`
9. `RuneInventorySystem`
10. `RuneSessionSystem`
11. `RuneRollSystem`
12. `CoinSystem`
13. `WoodSystem`
14. `PaperFactorySystem`
15. `HaySystem`
16. upgrade boards
17. `RebirthSystem`
18. `LeaderboardSystem`
19. `SaveSystem`

---

## Server core systems

### `Systems/Core/ServerContext.lua`

**Type:** server shared context.

**Responsibility:**

- keep common Roblox services: `Players`, `ServerStorage`, `ReplicatedStorage`, `Workspace`, `RunService`, `DataStoreService`, `PhysicsService`, `HttpService`, `MarketplaceService`, `MessagingService`;
- keep common workspace references: `ZonePart`, `CoinPart`, `RebirthWall`, `TreeBlock`, `RuneRollBlock`, `ForestRuneBlock`, `NatureRuneBlock`, `HayBlock`;
- expose shared constants that must not be duplicated incorrectly;
- expose helper functions used by several systems, for example `safeNumber`, `roundToTenth`, `ensureFolder`, `createValue`, `markDirty`.

### `Systems/Core/RemoteRegistry.lua`

**Type:** server core system.

**Responsibility:**

- create/find `ReplicatedStorage.IncrementalRemotes`;
- create/find the existing RemoteEvent names exactly as they are now;
- return references to all remotes for other systems.

### `Systems/Core/PlayerDataSystem.lua`

**Type:** server core system.

**Responsibility:**

- create all existing `PlayerData` folders and values;
- preserve value names and defaults for currencies, upgrades, rebirths, XP, passives, runes, gamepasses;
- keep existing helper getters such as `getPlayerData`, `getCoinsObject`, `getWoodFolder`, `getPaperFactoryFolder`, `getHayFolder`, `getRebirthFolder`, `getPassiveFolder`, `getXPFolder`;
- own `setupPlayerDataObjects` and data reset helpers used by rebirth/save.

### `Systems/Core/GamepassSystem.lua`

**Type:** server core system.

**Responsibility:**

- preserve `GamepassIds`;
- preserve `refreshPlayerGamepasses`;
- preserve `playerHasGamepass` and `getGamepassMultiplier`;
- expose multipliers for coin, wood, paper, and rune luck systems.

### `Systems/Core/AdminEventSystem.lua`

**Type:** server core system.

**Responsibility:**

- preserve admin name, global event store/channel, active server events, duration and MessagingService/DataStore logic;
- own `AdminAction` server handling;
- own admin event payload broadcasting through `Notify`;
- expose server event multipliers and rune event boosts to currency/rune systems.

---

## Server gameplay systems

### `Systems/CoinSystem.lua`

**Type:** server gameplay system.

**Responsibility:**

- coin spawning in `SpawnedCoins`;
- coin visuals/physics/collision setup;
- pickup/touch handling;
- final coin gain calculation;
- coin respawn delay calculation;
- coin reset on rebirth;
- pickup notification through `Notify`.

### `Systems/WoodSystem.lua`

**Type:** server gameplay system.

**Responsibility:**

- `WoodClick` remote handling;
- wood reward calculation;
- wood cooldown calculation;
- tree unlock/collision visibility support through rebirth state;
- wood reset logic used by rebirth.

### `Systems/PaperFactorySystem.lua`

**Type:** server gameplay system.

**Responsibility:**

- `FactoryAction` remote handling;
- paper production cycle;
- fuel consumption/wood-to-paper logic;
- paper amount and paper cycle time calculations;
- paper reset logic used by rebirth.

### `Systems/HaySystem.lua`

**Type:** server gameplay system.

**Responsibility:**

- hay block interaction rules;
- hay reward calculation;
- hay cooldown calculation;
- hay save normalization;
- hay reset/unlock integration.

### `Systems/RebirthSystem.lua`

**Type:** server gameplay system.

**Responsibility:**

- `PurchaseRebirth` remote handling;
- preserve `REBIRTH_STAGES` and `MAX_REBIRTH_COUNT`;
- validate cost/currency;
- recalculate rebirth multipliers/unlocks;
- reset the correct currencies/upgrades per rebirth stage;
- update wall/tree/gate collision groups and unlock flags.

### `Systems/SaveSystem.lua`

**Type:** server persistence system.

**Responsibility:**

- preserve `SAVE_STORE_NAME`, `SAVE_INTERVAL`, `SAVE_COOLDOWN`;
- own save serialization and load application;
- call `markDirty` from systems that mutate data;
- handle player removing and server shutdown saves;
- include runes, passives, hay, XP, rebirth, gamepasses, upgrades exactly as before.

### `Systems/XPSystem.lua`

**Type:** server gameplay system.

**Responsibility:**

- preserve XP folders, XP upgrades, XP boost config;
- own `XPAction` remote handling;
- expose XP boost multiplier to coin/wood/paper/rune systems;
- reset XP progress where current rebirth logic does it.

### `Systems/PassiveSystem.lua`

**Type:** server gameplay system.

**Responsibility:**

- preserve `PASSIVE_DEFS`, passive roll cost/capacity/cooldown;
- own `PassiveAction` remote handling;
- choose random passive;
- read/write passive inventory state;
- expose passive multipliers/special boosts to coin/wood/paper/rune systems;
- fire passive roll notifications.

### `Systems/LeaderboardSystem.lua`

**Type:** server gameplay/UI data system.

**Responsibility:**

- keep leaderboard formatting;
- build top player data from current players;
- use existing `Modules/LeaderboardService.lua`;
- update world leaderboard values without changing the data source.

---

## Server upgrade board systems

### `Systems/UpgradeBoards/CoinUpgradeBoard.lua`

**Type:** server upgrade system.

**Responsibility:**

- preserve `COIN_UPGRADES` config;
- handle coin upgrade purchases from `PurchaseUpgrade`;
- keep coin value, multiplier, spawn speed, wood boost upgrade behavior;
- expose active flags to client boards.

### `Systems/UpgradeBoards/WoodUpgradeBoard.lua`

**Type:** server upgrade system.

**Responsibility:**

- preserve `WOOD_UPGRADES` config;
- handle wood value, multiplier, speed, coin boost upgrades;
- expose active flags to client boards.

### `Systems/UpgradeBoards/PaperUpgradeBoard.lua`

**Type:** server upgrade system.

**Responsibility:**

- preserve `PAPER_UPGRADES` config;
- handle paper value, multiplier, speed upgrades;
- integrate with paper factory amount/cycle calculations.

### `Systems/UpgradeBoards/XPUpgradeBoard.lua`

**Type:** server upgrade system.

**Responsibility:**

- preserve `XP_UPGRADES` and `XP_BOOST_CONFIG` purchase behavior;
- handle max-level and active flags;
- integrate with `XPAction` if current server logic keeps XP purchases there.

### `Systems/UpgradeBoards/HayUpgradeBoard.lua`

**Type:** server upgrade system.

**Responsibility:**

- preserve `HAY_UPGRADES` and `HAY_UPGRADE_KEYS`;
- handle hay amount, multiplier, cooldown upgrades;
- integrate with hay reward/cooldown calculations.

---

## Server rune systems

### `Systems/RuneSystems/RuneStatsSystem.lua`

**Type:** server rune system.

**Responsibility:**

- preserve effective rune stat calculation;
- combine rune inventory bonuses, rune upgrades, passive boosts, XP boosts, gamepasses, admin events;
- keep `getRuneBonusMultipliers`, `getRuneSpeedOverflowBulk`, `getEffectiveRuneStats` behavior;
- sync with existing `Modules/RuneSystemService.lua`.

### `Systems/RuneSystems/RuneRollSystem.lua`

**Type:** server rune system.

**Responsibility:**

- own rune rolling start/stop from `RuneAction`;
- preserve open duration, roll interval, character-on-block checks;
- call rune-set modules for weighted selection;
- spend correct currency/open cost.

### `Systems/RuneSystems/RuneInventorySystem.lua`

**Type:** server rune system.

**Responsibility:**

- preserve empty rune state structure;
- preserve `getRuneFolder`, `getRuneState`, `writeRuneStateValue`;
- apply stack caps/effective stacks;
- save/load rune counts.

### `Systems/RuneSystems/RuneSessionSystem.lua`

**Type:** server rune system.

**Responsibility:**

- track active rolling sessions per player/system;
- expose session data to client through existing values/remotes;
- preserve start/stop cleanup behavior.

### `Systems/RuneSystems/RuneLuckSystem.lua`

**Type:** server rune upgrade system.

**Responsibility:**

- preserve `RUNE_UPGRADES.Luck`;
- handle luck purchase and max purchase;
- feed luck into roll chance calculations.

### `Systems/RuneSystems/RuneSpeedSystem.lua`

**Type:** server rune upgrade system.

**Responsibility:**

- preserve `RUNE_UPGRADES.Speed`;
- handle speed purchase and max purchase;
- feed speed into roll interval/open duration calculations.

### `Systems/RuneSystems/RuneBulkSystem.lua`

**Type:** server rune upgrade system.

**Responsibility:**

- preserve `RUNE_UPGRADES.Bulk`;
- handle bulk purchase and max purchase;
- feed bulk into roll count and overflow bulk calculations.

### `Systems/RuneSystems/RuneIndexSystem.lua`

**Type:** server rune/index support system.

**Responsibility:**

- expose discovered/owned rune information using the current state format;
- support client rune index boards without changing how counts are stored.

---

## Server rune set modules

### `Systems/Runes/BaseRuneSet.lua`

**Type:** server config/helper module.

**Responsibility:**

- shared helpers for rune set modules;
- weighted selection helpers currently embedded in the server;
- common cap/default behavior.

### `Systems/Runes/NatureRune.lua`

**Type:** server rune config module.

**Responsibility:**

- preserve nature rune unlock and open-cost config;
- preserve nature rune list/chances/effects from current `RUNE_TYPES`.

### `Systems/Runes/ForestRune.lua`

**Type:** server rune config module.

**Responsibility:**

- preserve forest rune unlock and paper open cost;
- preserve forest rune names and effect definitions.

### `Systems/Runes/PaperRune.lua`

**Type:** server rune config module.

**Responsibility:**

- contain paper-related rune set logic if current `processRuneSet` separates a paper rune set;
- if no standalone paper rune exists yet, this file should only be created when the old logic is actually moved.

### `Systems/Runes/HayRune.lua`

**Type:** server rune config module.

**Responsibility:**

- contain hay-related rune set logic if current `processRuneSet` separates a hay rune set;
- if no standalone hay rune exists yet, this file should only be created when the old logic is actually moved.

---

# CLIENT SIDE

## Итоговая структура

```text
StarterPlayer
└── StarterPlayerScripts
    ├── MainClient.lua
    └── ClientSystems
        ├── Core
        │   ├── ClientContext.lua
        │   ├── GuiFactory.lua
        │   ├── ResponsiveUI.lua
        │   └── ClientFormatters.lua
        ├── GUIUpdater.lua
        ├── BoardVisualSystem.lua
        ├── UpgradeBoardUI.lua
        ├── XPProgressUI.lua
        ├── PassiveInventoryUI.lua
        ├── RuneBoardUI.lua
        ├── RuneInventoryUI.lua
        ├── RuneSessionUI.lua
        ├── LeaderboardUI.lua
        ├── AdminPanelUI.lua
        ├── NotificationUI.lua
        ├── InputBindingSystem.lua
        └── RuntimeLoopSystem.lua
```

## Client bootstrap

### `StarterPlayerScripts/MainClient.lua`

**Type:** client bootstrap.

**Responsibility:**

- require `ClientSystems/Core/ClientContext.lua`;
- require UI/runtime modules;
- call `Init()` in dependency order;
- contain no board creation details, no purchase state logic, no animation implementation, no GUI update loop.

**Init order target:**

1. `ClientContext`
2. `GuiFactory`
3. `ResponsiveUI`
4. `ClientFormatters`
5. `NotificationUI`
6. `AdminPanelUI`
7. `UpgradeBoardUI`
8. `XPProgressUI`
9. `PassiveInventoryUI`
10. `RuneInventoryUI`
11. `RuneBoardUI`
12. `RuneSessionUI`
13. `BoardVisualSystem`
14. `LeaderboardUI`
15. `InputBindingSystem`
16. `GUIUpdater`
17. `RuntimeLoopSystem`

---

## Client core modules

### `ClientSystems/Core/ClientContext.lua`

**Type:** client shared context.

**Responsibility:**

- keep references to `Players`, `ReplicatedStorage`, `Workspace`, `MarketplaceService`, local player, `PlayerGui`, `IncrementalRemotes`;
- keep player data references exactly as current client expects them;
- keep workspace references for boards/blocks/gates;
- expose existing constants such as `ADMIN_NAME`, `MAX_REBIRTH_COUNT`, `PASSIVE_ROLL_COST`, `PASSIVE_INVENTORY_CAPACITY`.

### `ClientSystems/Core/GuiFactory.lua`

**Type:** client UI helper module.

**Responsibility:**

- preserve shared UI creation helpers: corners, strokes, gradients, hover scale, panel animation, decorative dots, world board creation, headers, upgrade cards, scrollers;
- no gameplay rules.

### `ClientSystems/Core/ResponsiveUI.lua`

**Type:** client UI helper module.

**Responsibility:**

- preserve device detection/profile/preset logic;
- apply responsive scale/panels;
- refresh scrollers for device changes.

### `ClientSystems/Core/ClientFormatters.lua`

**Type:** client helper module.

**Responsibility:**

- preserve `formatNumber`, `roundToTenth`, currency colors, rarity colors, rune stat formatting, cost formatting;
- keep icon asset lookup helpers.

---

## Client UI/runtime systems

### `ClientSystems/GUIUpdater.lua`

**Type:** client runtime UI system.

**Responsibility:**

- preserve main `updateBoards` behavior;
- update text/visibility/state of existing boards;
- update button visuals based on current purchasability;
- subscribe to value changes that currently trigger board refreshes.

### `ClientSystems/BoardVisualSystem.lua`

**Type:** client world visual system.

**Responsibility:**

- preserve world node/board visibility logic;
- preserve wall/tree/gate visual updates;
- preserve unlock debug behavior if still needed;
- preserve rune/hay burst visual triggers.

### `ClientSystems/UpgradeBoardUI.lua`

**Type:** client board UI system.

**Responsibility:**

- create and update coin, wood, paper, hay, and generic upgrade board cards;
- bind `PurchaseUpgrade`, rune upgrade buttons, and max-buy buttons through existing remotes;
- preserve purchase-state checks and button visual behavior.

### `ClientSystems/XPProgressUI.lua`

**Type:** client board UI system.

**Responsibility:**

- create/update XP progress board;
- create/update XP upgrade cards;
- display XP estimates and XP boost state;
- use existing `XPAction` remote for XP purchases.

### `ClientSystems/PassiveInventoryUI.lua`

**Type:** client UI system.

**Responsibility:**

- create passive roll board/inventory/index UI;
- parse passive state;
- display slot grid/index grid/equipped passive;
- preserve roll animation and reward reveal;
- bind passive roll/equip actions to `PassiveAction`.

### `ClientSystems/RuneBoardUI.lua`

**Type:** client world rune board UI system.

**Responsibility:**

- create rune roll/index/stats boards for each rune system;
- preserve rune board themes and visuals;
- display rune chances/effects/details;
- update rune world displays.

### `ClientSystems/RuneInventoryUI.lua`

**Type:** client rune UI system.

**Responsibility:**

- parse rune state;
- render owned rune counts/effective stacks;
- update rune summary GUI;
- support rune index display without changing state format.

### `ClientSystems/RuneSessionUI.lua`

**Type:** client rune runtime UI system.

**Responsibility:**

- preserve rune session screen;
- update active session rows/order;
- start/stop rune rolling client actions through `RuneAction`;
- display active roll timers and bulk/speed/luck stats.

### `ClientSystems/LeaderboardUI.lua`

**Type:** client UI system.

**Responsibility:**

- own client-side leaderboard display if present in `IncrementalClient`;
- consume server-created leaderboard values without changing names.

### `ClientSystems/AdminPanelUI.lua`

**Type:** client admin UI system.

**Responsibility:**

- preserve admin panel layout/device refresh;
- preserve quick currency buttons, event buttons, gamepass buttons;
- bind admin controls to `AdminAction`;
- render active admin events from `Notify` payloads.

### `ClientSystems/NotificationUI.lua`

**Type:** client UI system.

**Responsibility:**

- preserve toast notifications;
- preserve pickup popups;
- preserve passive roll notification handling;
- subscribe to `Notify.OnClientEvent`.

### `ClientSystems/InputBindingSystem.lua`

**Type:** client binding system.

**Responsibility:**

- preserve world input bindings;
- bind upgrade cards, passive buttons, rune buttons, admin panel actions;
- no UI drawing beyond connecting events.

### `ClientSystems/RuntimeLoopSystem.lua`

**Type:** client runtime system.

**Responsibility:**

- preserve periodic UI update loops;
- preserve admin event timer ticks;
- preserve runtime refresh cadence;
- call public refresh methods from other client systems.

---

# Suggested migration stages

Each stage moves only two systems, then the game should be tested before continuing.

1. `RemoteRegistry` + `PlayerDataSystem`.
2. `CoinSystem` + `CoinUpgradeBoard`.
3. `WoodSystem` + `WoodUpgradeBoard`.
4. `PaperFactorySystem` + `PaperUpgradeBoard`.
5. `HaySystem` + `HayUpgradeBoard`.
6. `XPSystem` + `XPProgressUI`.
7. `PassiveSystem` + `PassiveInventoryUI`.
8. `RuneInventorySystem` + `RuneInventoryUI`.
9. `RuneStatsSystem` + `RuneBoardUI`.
10. `RuneSessionSystem` + `RuneSessionUI`.
11. `RuneRollSystem` + rune set modules.
12. `RuneLuckSystem` + `RuneSpeedSystem`.
13. `RuneBulkSystem` + `RuneIndexSystem`.
14. `RebirthSystem` + `BoardVisualSystem`.
15. `AdminEventSystem` + `AdminPanelUI`.
16. `LeaderboardSystem` + `LeaderboardUI`.
17. `SaveSystem` + final bootstrap cleanup.
18. `GUIUpdater` + `RuntimeLoopSystem` final client cleanup.

# Required checks after every migration stage

- Player joins without output errors.
- `PlayerData` contains the same folders/values as before.
- All RemoteEvent names still exist in `ReplicatedStorage.IncrementalRemotes`.
- Coins spawn and can be collected.
- Upgrade boards display correct costs/levels/max state.
- Rebirth wall/tree/area unlocks match old behavior.
- Wood, paper, hay systems unlock at the same rebirths as before.
- Passive roll/inventory/equip still works.
- Rune roll, rune inventory, rune index, rune stats, speed/luck/bulk still work.
- XP progress and XP upgrades still work.
- Save/load keeps all old fields.
- Admin events and notifications still render.
- No old loops are accidentally duplicated after moving a system.
