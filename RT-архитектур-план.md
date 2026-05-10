# RT-архитектур-план (единый master architecture plan)

## 1) Главный принцип
- Это **не новая архитектура** и **не новый migration-plan**.
- Игра **не переписывается с нуля**: `IncrementalServer`/`IncrementalClient` остаются источником legacy-логики.
- Мы делаем только консолидацию в один master-файл и продолжаем перенос рабочих систем в уже существующую модульную структуру.
- `MainServer.lua` и `MainClient.lua` — только bootstrap/controller (инициализация, wiring, запуск runtime), без тяжелой gameplay-логики внутри.
- Запрещено вводить новые parallel/temporary/legacy-wrapper слои: перенос идет сразу в `existing systems`.

---

## 2) Единая структура проекта

### 2.1 Server structure (актуальная)

```text
ServerScriptService
├── MainServer.lua                                # bootstrap-only
└── Systems
    ├── Core
    │   ├── RemoteRegistry.lua                    # server/core remotes
    │   ├── PlayerDataSystem.lua                  # server/core player data
    │   └── GamepassSystem.lua                    # server/core gamepass/multipliers
    ├── CoinSystem.lua                            # gameplay: coin flow
    ├── WoodSystem.lua                            # gameplay: wood click/progression
    ├── PaperFactorySystem.lua                    # gameplay/runtime-driven factory
    ├── HaySystem.lua                             # gameplay/runtime-driven hay
    ├── XPSystem.lua                              # gameplay: xp/progression
    ├── PassiveSystem.lua                         # gameplay: passive rewards
    ├── UpgradeBoards
    │   ├── CoinUpgradeBoard.lua
    │   ├── WoodUpgradeBoard.lua
    │   ├── PaperUpgradeBoard.lua
    │   ├── XPUpgradeBoard.lua
    │   ├── HayUpgradeBoard.lua
    │   ├── UpgradePurchaseSystem.lua             # shared purchase pipeline
    │   ├── UpgradeActiveFlagsSystem.lua          # shared active-flag updates
    │   ├── UpgradeCostSystem.lua                 # shared cost progression
    │   ├── UpgradeEligibilitySystem.lua          # shared lock checks
    │   └── UpgradeNotifySystem.lua               # shared notify helper
    ├── RuneSystems
    │   ├── RuneRollSystem.lua                    # main rune runtime/controller
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
    ├── Runes
    │   ├── BaseRuneSet.lua
    │   ├── NatureRune.lua
    │   ├── ForestRune.lua
    │   ├── PaperRune.lua
    │   └── HayRune.lua
    └── RuntimeLoops
        ├── CoinAnimationSystem.lua
        ├── PaperRuntimeSystem.lua
        ├── HayRuntimeSystem.lua
        └── RuneRuntimeSystem.lua
```

### 2.2 Client structure (единая целевая, без новых архитектурных слоев)

```text
StarterPlayerScripts
├── MainClient.lua                                # bootstrap-only
└── ClientSystems
    ├── Core
    │   ├── ClientRemoteRegistry.lua              # получение/подписка на remotes
    │   ├── ClientDataMirror.lua                  # mirror PlayerData (read-side)
    │   └── ClientControllerRegistry.lua          # init order + wiring
    ├── UI
    │   ├── NotifyUISystem.lua
    │   ├── HUDSystem.lua
    │   ├── ShopUISystem.lua
    │   ├── RuneUISystem.lua
    │   └── BoardUISystem.lua
    ├── Boards
    │   ├── CoinBoardClient.lua
    │   ├── WoodBoardClient.lua
    │   ├── PaperBoardClient.lua
    │   ├── XPBoardClient.lua
    │   └── HayBoardClient.lua
    ├── Player
    │   ├── MovementClientSystem.lua
    │   ├── InteractionClientSystem.lua
    │   └── InputClientSystem.lua
    └── Runtime
        ├── AnimationRuntimeClient.lua
        ├── PassiveRuntimeClient.lua
        └── RuneRuntimeClient.lua
```

> Примечание: client-side структура выше — это **допструктура, объединённая в master-файл**, а не новая rewrite-архитектура.

---

## 3) Системы по доменам

### 3.1 Player systems
- Server: `PlayerDataSystem`, gameplay-системы, читающие/пишущие `PlayerData`.
- Client: `ClientDataMirror`, `MovementClientSystem`, `InteractionClientSystem`, `InputClientSystem`.
- Задача: непрерывный поток `input -> remote -> authoritative server update -> ui refresh`.

### 3.2 Runtime systems
- Server runtime: `RuntimeLoops/*`, `PaperFactorySystem`, `HaySystem`, `PassiveSystem`.
- Client runtime: `AnimationRuntimeClient`, `PassiveRuntimeClient`, `RuneRuntimeClient`.
- Правило: runtime-модули не содержат bootstrap и не дублируют бизнес-логику.

### 3.3 Rune systems
- Оркестрация: `RuneRollSystem`, `RuneSessionSystem`, `RuneSetRuntimeSystem`.
- Статы/шансы: `RuneStatsSystem`, `RuneDenominatorSystem`, `RuneLuckSystem`, `RuneSpeedSystem`, `RuneBulkSystem`.
- Инвентарь/индексация/действия: `RuneInventorySystem`, `RuneIndexSystem`, `RuneActionSystem`.
- Клиент: `RuneUISystem` + `RuneRuntimeClient`.

### 3.4 Board systems
- Server boards: `UpgradeBoards/*` + shared `Upgrade*System`.
- Client boards: `Boards/*BoardClient.lua` + `BoardUISystem`.
- Задача: единый purchase flow без дублирования формул.

### 3.5 UI systems
- UI инициируется только из client-bootstrap.
- `NotifyUISystem`, `HUDSystem`, `ShopUISystem`, `RuneUISystem`, `BoardUISystem`.
- Только отображение/взаимодействие; authoritative расчеты остаются на сервере.

---

## 4) Responsibilities (границы ответственности)

### Bootstrap responsibilities
- `MainServer.lua` / `MainClient.lua`:
  - подключают модули,
  - передают зависимости,
  - вызывают `Init()` в корректном порядке,
  - стартуют runtime-циклы.

### Domain-system responsibilities
- Каждая система владеет своим bounded-context и публичным API.
- Межсистемное взаимодействие — через явные интерфейсы, не через копипасту legacy-блоков.

### Compatibility responsibilities
- Сохранение совместимости legacy-контрактов обязательно до конца миграции.

---

## 5) Bootstrap flow (обязательный порядок запуска)
1. Core registry (server/client remote registries).
2. Data systems (`PlayerDataSystem`, `ClientDataMirror`).
3. Domain gameplay systems (coin/wood/paper/hay/xp/passive).
4. Upgrade board systems.
5. Rune systems.
6. UI systems (client).
7. Runtime loops (server/client).
8. Пост-инициализационные health-checks.

---

## 6) Dependency order (порядок зависимостей)
- `RemoteRegistry` -> все системы, использующие remotes.
- `PlayerDataSystem` -> gameplay/boards/runes (server).
- Gameplay systems -> board/rune cost+reward вычисления.
- Rune set configs (`Runes/*`) -> `RuneRollSystem`/`RuneStatsSystem`.
- Client remote/data core -> UI и client runtime.
- Запрещены циклические зависимости между bootstrap и доменными системами.

---

## 7) Migration stages (без migration-over-migration)

### Stage 1: Core stabilization
- Фиксируем remotes/data-контракты.
- Проверяем, что bootstrap-only соблюден.

### Stage 2: Gameplay extraction
- Переносим legacy-блоки в существующие gameplay-модули (`Coin/Wood/Paper/Hay/XP/Passive`).

### Stage 3: Board consolidation
- Подключаем все purchase-пути через `UpgradeBoards` shared pipeline.

### Stage 4: Rune consolidation
- Переносим rune-логику в `RuneSystems` + `Runes` config modules.

### Stage 5: Client/UI alignment
- Приводим client-side к единому `MainClient + ClientSystems` flow.

### Stage 6: Runtime hardening
- Финализируем runtime loops и убираем оставшиеся legacy-дубли.

Правило этапов:
- Работа пакетами по 5 систем.
- После каждого пакета: smoke-test, фиксация regressions, обновление этого master-файла.
- **Никаких новых migration layers, temporary wrappers или parallel systems.**

---

## 8) Checks after migration (обязательные проверки)
- Remote compatibility check: имена и payload remotes не изменены.
- PlayerData compatibility check: `WaitForChild`-ожидания клиента не сломаны.
- Economy check: формулы дохода/стоимости/пассивов совпадают с legacy.
- Rune probability check: denominator/weights не регрессировали.
- Board purchase check: unlock/required rebirth/active flags работают идентично.
- Bootstrap check: heavy logic не утекла в `MainServer`/`MainClient`.
- Runtime check: циклы не создают дублирующиеся обработчики.

---

## 9) Existing systems (уже существующие системы)

### Server core
- `Systems/Core/RemoteRegistry.lua`
- `Systems/Core/PlayerDataSystem.lua`
- `Systems/Core/GamepassSystem.lua`

### Server gameplay
- `Systems/CoinSystem.lua`
- `Systems/WoodSystem.lua`
- `Systems/PaperFactorySystem.lua`
- `Systems/HaySystem.lua`
- `Systems/XPSystem.lua`
- `Systems/PassiveSystem.lua`

### Server upgrade boards
- `Systems/UpgradeBoards/CoinUpgradeBoard.lua`
- `Systems/UpgradeBoards/WoodUpgradeBoard.lua`
- `Systems/UpgradeBoards/PaperUpgradeBoard.lua`
- `Systems/UpgradeBoards/XPUpgradeBoard.lua`
- `Systems/UpgradeBoards/HayUpgradeBoard.lua`
- `Systems/UpgradeBoards/UpgradePurchaseSystem.lua`
- `Systems/UpgradeBoards/UpgradeActiveFlagsSystem.lua`
- `Systems/UpgradeBoards/UpgradeCostSystem.lua`
- `Systems/UpgradeBoards/UpgradeEligibilitySystem.lua`
- `Systems/UpgradeBoards/UpgradeNotifySystem.lua`

### Server runes
- `Systems/RuneSystems/RuneRollSystem.lua`
- `Systems/RuneSystems/RuneStatsSystem.lua`
- `Systems/RuneSystems/RuneInventorySystem.lua`
- `Systems/RuneSystems/RuneSessionSystem.lua`
- `Systems/RuneSystems/RuneActionSystem.lua`
- `Systems/RuneSystems/RuneLuckSystem.lua`
- `Systems/RuneSystems/RuneSpeedSystem.lua`
- `Systems/RuneSystems/RuneBulkSystem.lua`
- `Systems/RuneSystems/RuneIndexSystem.lua`
- `Systems/RuneSystems/RuneBlockCheckSystem.lua`
- `Systems/RuneSystems/RuneCurrencySystem.lua`
- `Systems/RuneSystems/RuneDenominatorSystem.lua`
- `Systems/RuneSystems/RuneNotifySystem.lua`
- `Systems/RuneSystems/RuneSetRuntimeSystem.lua`

### Server rune sets
- `Systems/Runes/BaseRuneSet.lua`
- `Systems/Runes/NatureRune.lua`
- `Systems/Runes/ForestRune.lua`
- `Systems/Runes/PaperRune.lua`
- `Systems/Runes/HayRune.lua`

### Server runtime loops
- `Systems/RuntimeLoops/CoinAnimationSystem.lua`
- `Systems/RuntimeLoops/PaperRuntimeSystem.lua`
- `Systems/RuntimeLoops/HayRuntimeSystem.lua`
- `Systems/RuntimeLoops/RuneRuntimeSystem.lua`

---

## 10) Already created modules (инвентаризация)
- Все перечисленные в разделе **Existing systems** модули считаются уже созданными и целевыми.
- Дальше работа ведётся только через их развитие/подключение к `MainServer`/`MainClient`.
- Новые модули допускаются только как естественное расширение домена, но не как временные migration-обёртки.

---

## 11) Неприкосновенные legacy-контракты
- Не переименовывать remotes:
  - `PurchaseUpgrade`, `PurchaseRebirth`, `AdminAction`, `Notify`, `WoodClick`, `FactoryAction`, `PassiveAction`, `RuneAction`, `XPAction`.
- Не переименовывать `PlayerData` folders/values, которые клиент ожидает через `WaitForChild`.
- Переносить только рабочую legacy-логику (без пустых/stub-систем).

---

## 12) Операционный режим после консолидации
- Этот файл — **единственный главный architecture-plan проекта**.
- Отдельные/дублирующие architecture-файлы удалены и больше не ведутся.
- Дальше: просто продолжаем реализацию систем/модулей по этому плану:
  1) берём старую игровую логику,
  2) переносим в existing systems,
  3) подключаем к `MainServer`/`MainClient`,
  4) тестируем,
  5) двигаемся к следующему пакету.
