# RT-архитектур-план (актуальный)

## Главный принцип
- Игра **не переписывается с нуля**.
- `IncrementalServer`/`IncrementalClient` остаются источником legacy-логики.
- Переносим рабочие блоки в модули, сохраняя совместимость имён `RemoteEvent`, `PlayerData` и текущих gameplay-формул.
- `MainServer.lua` — только bootstrap/controller (инициализация и wiring).

---

## Актуальная структура (server)

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
    ├── UpgradeBoards                     # server/upgrade systems
    │   ├── CoinUpgradeBoard.lua
    │   ├── WoodUpgradeBoard.lua
    │   ├── PaperUpgradeBoard.lua
    │   ├── XPUpgradeBoard.lua
    │   ├── HayUpgradeBoard.lua
    │   ├── UpgradePurchaseSystem.lua     # shared purchase pipeline
    │   ├── UpgradeActiveFlagsSystem.lua  # shared active-flag updates
    │   ├── UpgradeCostSystem.lua         # shared cost progression
    │   ├── UpgradeEligibilitySystem.lua  # shared lock checks
    │   └── UpgradeNotifySystem.lua       # shared notify helper
    ├── RuneSystems                       # server/rune systems
    │   ├── RuneRollSystem.lua            # main rune runtime/controller
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
    └── RuntimeLoops                      # runtime-only helper loops
        ├── CoinAnimationSystem.lua
        ├── PaperRuntimeSystem.lua
        ├── HayRuntimeSystem.lua
        └── RuneRuntimeSystem.lua
```

---

## Роли файлов

### Bootstrap-only
- `ServerScriptService/MainServer.lua`
  - Подключает системы.
  - Вызывает `Init()` в порядке зависимостей.
  - Не хранит gameplay-формулы и тяжёлые runtime-блоки.

### Runtime-only helper modules
- `Systems/RuntimeLoops/*`
  - Только циклы/heartbeat и периодические вызовы переданных callback.

### Server gameplay systems
- `CoinSystem`, `WoodSystem`, `PaperFactorySystem`, `HaySystem`, `XPSystem`, `PassiveSystem`.
  - Рабочая логика валют/апгрейдов/пассивов/выплат.

### Server upgrade board systems
- `UpgradeBoards/*UpgradeBoard.lua`
  - Endpoint обработки `PurchaseUpgrade` по семействам (`Coin/Wood/Paper/XP/Hay`).
- Shared внутри `UpgradeBoards`:
  - `UpgradePurchaseSystem` — единый пайплайн покупки уровня.
  - `UpgradeActiveFlagsSystem` — синхронизация active-флагов.
  - `UpgradeCostSystem` — стоимость следующего уровня.
  - `UpgradeEligibilitySystem` — проверки unlock/required rebirth.
  - `UpgradeNotifySystem` — отправка `Notify` сообщений.

### Server rune systems
- `RuneRollSystem` — orchestrator/runtime-controller рун.
- `RuneActionSystem` — маршрутизация `RuneAction`.
- `RuneLuck/Speed/BulkSystem` — апгрейды рун.
- `RuneStatsSystem` — итоговые множители/эффективные статы.
- `RuneInventorySystem` — состояние рун в данных игрока.
- `RuneSessionSystem` — активные roll-сессии.
- `RuneIndexSystem` — payload состояния index/discovered.
- `RuneBlockCheckSystem` — проверка нахождения игрока на rune-block.
- `RuneCurrencySystem` — выбор валюты набора/списание цены открытия.
- `RuneDenominatorSystem` — effective denominators/шансы.
- `RuneNotifySystem` — уведомления по rune-событиям.
- `RuneSetRuntimeSystem` — правила остановки/продолжения roll runtime.

### Rune set modules
- `Systems/Runes/*`
  - Конфиги наборов, порядок рун, unlock/cost/denominator профиль.

### Core systems
- `RemoteRegistry` — создание/получение remotes (имена неизменны).
- `PlayerDataSystem` — инициализация/доступ/мутаторы PlayerData.
- `GamepassSystem` — проверка gamepass и мультипликаторы.

---

## Неприкосновенные контракты совместимости
- Не переименовывать remotes:
  - `PurchaseUpgrade`, `PurchaseRebirth`, `AdminAction`, `Notify`, `WoodClick`, `FactoryAction`, `PassiveAction`, `RuneAction`, `XPAction`.
- Не переименовывать `PlayerData` folders/values, которые клиент ждёт через `WaitForChild`.
- Переносить только рабочую legacy-логику (без пустых/stub систем).

---

## Правило этапа
- Делаем по **5 систем** за этап.
- После каждого этапа обязательно обновляем этот файл (`RT-архитектур-план.md`), чтобы он оставался единственным актуальным источником структуры.
