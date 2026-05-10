# RT-архитектур-план (master architecture plan)

## Главный принцип
- Игра **не переписывается с нуля**.
- `IncrementalServer`/`IncrementalClient` остаются источником legacy-логики.
- Переносим только рабочие блоки в модульные системы, сохраняя совместимость `RemoteEvent`, `PlayerData`, формул и текущих геймплейных контрактов.
- `MainServer.lua` и `MainClient.lua` — только bootstrap/controller (инициализация, wiring, вызов `Init()` по зависимостям).
- После этого плана **не создаём новые migration-over-migration слои**: продолжаем прямой перенос legacy-логики в уже утверждённые systems/modules.

---

## Единая структура проекта

### Server structure
```text
ServerScriptService
├── MainServer.lua                        # bootstrap-only
└── Systems
    ├── Core
    │   ├── RemoteRegistry.lua            # server/core
    │   ├── PlayerDataSystem.lua          # server/core/data
    │   └── GamepassSystem.lua            # server/core/gamepass
    ├── CoinSystem.lua                    # server/gameplay
    ├── WoodSystem.lua                    # server/gameplay
    ├── PaperFactorySystem.lua            # server/gameplay/runtime-driven
    ├── HaySystem.lua                     # server/gameplay/runtime-driven
    ├── XPSystem.lua                      # server/gameplay
    ├── PassiveSystem.lua                 # server/gameplay
    ├── UpgradeBoards                     # board systems (server)
    │   ├── CoinUpgradeBoard.lua
    │   ├── WoodUpgradeBoard.lua
    │   ├── PaperUpgradeBoard.lua
    │   ├── XPUpgradeBoard.lua
    │   ├── HayUpgradeBoard.lua
    │   ├── UpgradePurchaseSystem.lua
    │   ├── UpgradeActiveFlagsSystem.lua
    │   ├── UpgradeCostSystem.lua
    │   ├── UpgradeEligibilitySystem.lua
    │   └── UpgradeNotifySystem.lua
    ├── RuneSystems                       # rune systems (server)
    │   ├── RuneRollSystem.lua
    │   ├── RuneStatsSystem.lua
    │   ├── RuneInventorySystem.lua
    │   ├── RuneSessionSystem.lua
    │   ├── RuneActionSystem.lua
    │   ├── RuneLuckSystem.lua
    │   ├── RuneSpeedSystem.lua
    │   ├── RuneBulkSystem.lua
    │   ├── RuneIndexSystem.lua
    │   ├── RuneBlockCheckSystem.lua
    │   ├── RuneCurrencySystem.lua
    │   ├── RuneDenominatorSystem.lua
    │   ├── RuneNotifySystem.lua
    │   └── RuneSetRuntimeSystem.lua
    ├── Runes                             # rune set modules/config
    │   ├── BaseRuneSet.lua
    │   ├── NatureRune.lua
    │   ├── ForestRune.lua
    │   ├── PaperRune.lua
    │   └── HayRune.lua
    └── RuntimeLoops                      # runtime systems (server)
        ├── CoinAnimationSystem.lua
        ├── PaperRuntimeSystem.lua
        ├── HayRuntimeSystem.lua
        └── RuneRuntimeSystem.lua
```

### Client structure
```text
StarterPlayer
└── StarterPlayerScripts
    ├── MainClient.lua                    # bootstrap-only
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

---

## Системы и зоны ответственности

### Existing systems (уже существующие целевые домены)
- Core systems: `RemoteRegistry`, `PlayerDataSystem`, `GamepassSystem`.
- Gameplay systems: `CoinSystem`, `WoodSystem`, `PaperFactorySystem`, `HaySystem`, `XPSystem`, `PassiveSystem`.
- Board systems: серверные `UpgradeBoards/*` + клиентские `UpgradeBoardUI`, `XPProgressUI`, `RuneBoardUI`, `BoardVisualSystem`.
- Rune systems: `RuneSystems/*` + `Runes/*` + клиентские `RuneInventoryUI`, `RuneSessionUI`.
- Runtime systems: `RuntimeLoops/*` (server), `RuntimeLoopSystem`, `GUIUpdater` (client).
- UI systems: `NotificationUI`, `AdminPanelUI`, `LeaderboardUI`, `PassiveInventoryUI`, `InputBindingSystem`, `ResponsiveUI`, `GuiFactory`, `ClientFormatters`.
- Player systems: всё, что работает с PlayerData, прогрессией, валютами, апгрейдами, инвентарями и ребёртом.

### Responsibilities
- Server bootstrap (`MainServer.lua`): только require + `Init()` + wiring.
- Client bootstrap (`MainClient.lua`): только require + `Init()` в порядке зависимостей; без реализации board/runtime логики внутри bootstrap.
- Core: хранение ссылок/контекста/констант, remotes, доступ к данным и gamepass-флагам.
- Board/UI modules: рендер/обновление интерфейсов и привязка к существующим remote-контрактам.
- Runtime modules: только циклы/tick/heartbeat и вызовы публичных refresh/update API.

---

## Bootstrap flow

### Server bootstrap flow
1. Init `RemoteRegistry`.
2. Init `PlayerDataSystem`.
3. Init `GamepassSystem`.
4. Init gameplay systems (`Coin/Wood/PaperFactory/Hay/XP/Passive`).
5. Init board systems (`UpgradeBoards/*` + shared board helpers).
6. Init rune systems (`RuneSystems/*`) и подключение `Runes/*` конфигов.
7. Init runtime loops (`RuntimeLoops/*`).

### Client bootstrap flow (target order)
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

## Dependency order (единый)
- Всегда: `Core -> Gameplay -> Boards/Rune -> Runtime -> Visual/UI polish`.
- Запрещено подключать runtime-петли до готовности доменных систем, чтобы избежать дублирования старых и новых циклов.
- Любой перенос: сначала серверный источник данных и remote-контракт, потом клиентское отображение.

---

## Migration stages (фиксированный маршрут)
Каждый этап переносит ограниченный набор систем и завершается тестами:
1. `RemoteRegistry` + `PlayerDataSystem`
2. `CoinSystem` + `CoinUpgradeBoard`
3. `WoodSystem` + `WoodUpgradeBoard`
4. `PaperFactorySystem` + `PaperUpgradeBoard`
5. `HaySystem` + `HayUpgradeBoard`
6. `XPSystem` + `XPProgressUI`
7. `PassiveSystem` + `PassiveInventoryUI`
8. `RuneInventorySystem` + `RuneInventoryUI`
9. `RuneStatsSystem` + `RuneBoardUI`
10. `RuneSessionSystem` + `RuneSessionUI`
11. `RuneRollSystem` + `Runes/*`
12. `RuneLuckSystem` + `RuneSpeedSystem`
13. `RuneBulkSystem` + `RuneIndexSystem`
14. `RebirthSystem` + `BoardVisualSystem`
15. `AdminEventSystem` + `AdminPanelUI`
16. `LeaderboardSystem` + `LeaderboardUI`
17. `SaveSystem` + финальный bootstrap cleanup
18. `GUIUpdater` + `RuntimeLoopSystem` final client cleanup

> Дальше — только реализация по этому маршруту; без новых migration layers, architecture rewrites, temporary wrappers и parallel systems.

---

## Checks after migration (после каждого этапа)
- Игрок входит без ошибок в output.
- `PlayerData` содержит те же folders/values, что и раньше.
- Все `RemoteEvent` имена существуют в `ReplicatedStorage.IncrementalRemotes`.
- Монеты спавнятся и собираются.
- Upgrade boards показывают корректные cost/level/max состояния.
- Rebirth wall/tree/area unlocks совпадают со старым поведением.
- Wood/paper/hay открываются на тех же rebirth-порогах.
- Passive roll/inventory/equip работает.
- Rune roll/inventory/index/stats/speed/luck/bulk работает.
- XP progress и XP upgrades работают.
- Save/load сохраняет все старые поля.
- Admin events и notifications отображаются.
- Нет дублирования старых и новых loops после переноса.

---

## Неприкосновенные контракты совместимости
- Не переименовывать remotes: `PurchaseUpgrade`, `PurchaseRebirth`, `AdminAction`, `Notify`, `WoodClick`, `FactoryAction`, `PassiveAction`, `RuneAction`, `XPAction`.
- Не переименовывать `PlayerData` folders/values, которые клиент ожидает через `WaitForChild`.
- Не менять названия уже подключённых системных модулей без обновления всех точек require/wiring.

---

## Already created modules (реестр уже заведённых модулей)
- Server Core: `RemoteRegistry`, `PlayerDataSystem`, `GamepassSystem`.
- Server Gameplay: `CoinSystem`, `WoodSystem`, `PaperFactorySystem`, `HaySystem`, `XPSystem`, `PassiveSystem`.
- Server Boards: `Coin/Wood/Paper/XP/HayUpgradeBoard` + `UpgradePurchaseSystem`, `UpgradeActiveFlagsSystem`, `UpgradeCostSystem`, `UpgradeEligibilitySystem`, `UpgradeNotifySystem`.
- Server Runes: `RuneRollSystem`, `RuneStatsSystem`, `RuneInventorySystem`, `RuneSessionSystem`, `RuneActionSystem`, `RuneLuckSystem`, `RuneSpeedSystem`, `RuneBulkSystem`, `RuneIndexSystem`, `RuneBlockCheckSystem`, `RuneCurrencySystem`, `RuneDenominatorSystem`, `RuneNotifySystem`, `RuneSetRuntimeSystem`.
- Server Rune sets: `BaseRuneSet`, `NatureRune`, `ForestRune`, `PaperRune`, `HayRune`.
- Server Runtime: `CoinAnimationSystem`, `PaperRuntimeSystem`, `HayRuntimeSystem`, `RuneRuntimeSystem`.
- Client Core/UI Runtime: `ClientContext`, `GuiFactory`, `ResponsiveUI`, `ClientFormatters`, `GUIUpdater`, `BoardVisualSystem`, `UpgradeBoardUI`, `XPProgressUI`, `PassiveInventoryUI`, `RuneBoardUI`, `RuneInventoryUI`, `RuneSessionUI`, `LeaderboardUI`, `AdminPanelUI`, `NotificationUI`, `InputBindingSystem`, `RuntimeLoopSystem`.


## Текущий статус реализации (2026-05-10)

### Server systems: текущий этап
- Сервер находится на позднем этапе переноса: базовые Core/Gamepay/Board/Rune/Runtime системы уже вынесены в `ServerScriptService/Systems` и подключены через `MainServer.lua`.
- По фиксированному маршруту миграции фактически закрыты этапы 1-13.
- В работе остаётся закрытие хвоста серверного маршрута (этапы 14-17), но **без** создания новых слоёв миграции.

### Server systems: что осталось перенести
- `RebirthSystem` (этап 14).
- `AdminEventSystem` (этап 15).
- `LeaderboardSystem` (этап 16).
- `SaveSystem` + финальный server bootstrap cleanup (этап 17).

### Когда переход на client systems
- Переход на финальную клиентскую фазу планируется после закрытия серверного этапа 17 (когда серверные данные/remote-контракты стабилизированы).
- Частичный клиентский перенос допускается только для уже закрытых серверных доменов, строго по dependency order: `Core -> Gameplay data contract -> UI`.

### Какие client systems делать первыми
1. `ClientContext`
2. `GuiFactory`
3. `ResponsiveUI`
4. `ClientFormatters`
5. `NotificationUI`
6. `AdminPanelUI`

Далее — board/rune UI по target order из раздела **Client bootstrap flow**.

### Какие systems уже стабилизированы
- **Server Core:** `RemoteRegistry`, `PlayerDataSystem`, `GamepassSystem`.
- **Server Gameplay:** `CoinSystem`, `WoodSystem`, `PaperFactorySystem`, `HaySystem`, `XPSystem`, `PassiveSystem`.
- **Server Upgrade Boards:** `CoinUpgradeBoard`, `WoodUpgradeBoard`, `PaperUpgradeBoard`, `HayUpgradeBoard`, `XPUpgradeBoard`, `UpgradePurchaseSystem`, `UpgradeActiveFlagsSystem`, `UpgradeCostSystem`, `UpgradeEligibilitySystem`, `UpgradeNotifySystem`.
- **Server Rune systems:** `RuneRollSystem`, `RuneStatsSystem`, `RuneInventorySystem`, `RuneSessionSystem`, `RuneActionSystem`, `RuneLuckSystem`, `RuneSpeedSystem`, `RuneBulkSystem`, `RuneIndexSystem`, `RuneBlockCheckSystem`, `RuneCurrencySystem`, `RuneDenominatorSystem`, `RuneNotifySystem`, `RuneSetRuntimeSystem`.
- **Server Runtime loops:** `CoinAnimationSystem`, `PaperRuntimeSystem`, `HayRuntimeSystem`, `RuneRuntimeSystem`.
