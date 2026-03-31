# Board Game Recommendation System

A production-grade Board Game Recommendation System built on **lsFusion** — a declarative platform for information systems development.

## Финальная инструкция по запуску и демонстрации

Подробный сценарий запуска, UX-проверки и проверки ролей находится в `docs/RUNBOOK.md`.
Примечание по версии платформы: в lsFusion 6.1 поле изображения хранится типом `IMAGEFILE`.

## Features

- **Database of board games** with full domain model
- **Filtering & search** by genre, players, duration, age, availability
- **Recommendation engine** with scoring-based similarity algorithm
- **Role-based access control** (Admin / User)
- **Clean architecture** with separated domain, logic, and UI layers
- **Extensible design** for easy modification of scoring rules

---

## 1. Data Model

### Entity Relationship Diagram

```
┌─────────────┐       ┌─────────────┐
│   Genre     │       │  Publisher  │
├─────────────┤       ├─────────────┤
│ name        │       │ name        │
└──────┬──────┘       │ website     │
       │ 1            │ country     │
       │              └──────┬──────┘
       │ *                   │ 1
       │              ┌──────┴──────┐
       │              │             │ *
       ▼              ▼             ▼
┌─────────────────────────────────────────┐
│              BoardGame                  │
├─────────────────────────────────────────┤
│ name, description, minPlayers,          │
│ maxPlayers, durationMinutes, minAge,     │
│ available, image                       │
└──────┬──────────────────────┬───────────┘
       │ *                    │ *
       │                      │
       │ M:N                  │ 1
       ▼                      ▼
┌─────────────┐       ┌─────────────┐
│  Mechanic   │       │   Owner     │
├─────────────┤       ├─────────────┤
│ name        │       │ name        │
└─────────────┘       │ contacts    │
                      └─────────────┘
```

### Entities

| Entity | Attributes | Relationships |
|--------|------------|---------------|
| **BoardGame** | name, description, genre, minPlayers, maxPlayers, durationMinutes, minAge, publisher, owner, available, image | Genre (M:1), Publisher (M:1), Owner (M:1), Mechanic (M:N) |
| **Genre** | name | BoardGame (1:M) |
| **Publisher** | name, website, country | BoardGame (1:M) |
| **Owner** | name, contacts | BoardGame (1:M) |
| **Mechanic** | name | BoardGame (M:N via hasMechanic) |

---

## 2. Recommendation Algorithm

### Scoring Rules

| Criterion | Points | Condition |
|-----------|--------|------------|
| Club manual «similar» | +5 | Admin-marked pair `manualSimilarTo` |
| Genre match | +3 | Same genre as source game |
| Player range overlap | +2 | minPlayers ≤ candidate.max AND candidate.min ≤ source.max |
| Age similarity | +1 | |minAge(source) - minAge(candidate)| ≤ 2 |

### Output

- **Top 3** most similar games sorted by score DESC
- **Explanation** for each recommendation (e.g., "Same genre; Similar player count")

### Extensibility

Modify constants in `BoardGameDomain.lsf`:

```lsf
SCORE_MANUAL_SIMILARITY = 5;
SCORE_GENRE_MATCH = 3;
SCORE_PLAYER_RANGE_OVERLAP = 2;
SCORE_AGE_DIFFERENCE_WITHIN_RANGE = 1;
RECOMMENDATION_TOP_COUNT = 3;
AGE_DIFFERENCE_THRESHOLD = 2;
```

---

## 3. API / Function Contracts

### getRecommendations(gameId)

**Input:** `BoardGame` object (opened via form)

**Output:** Form displaying top 3 recommended games with:
- Rank
- Game name
- Score
- Explanation

**Edge cases:**
- No matches: Empty rows or NULL in recommendation slots
- Multiple equal scores: Sorted by `id(candidate)` for determinism
- Empty database: No recommendations returned

### Filtering Properties

| Property | Input | Output | Edge Cases |
|---------|-------|--------|------------|
| `matchesGenre(g, genreFilter)` | BoardGame, Genre? | BOOLEAN | NULL genreFilter = show all |
| `matchesPlayerCount(g, players)` | BoardGame, INTEGER? | BOOLEAN | NULL = show all |
| `matchesDuration(g, maxDuration)` | BoardGame, INTEGER? | BOOLEAN | NULL = show all |
| `matchesMinAge(g, age)` | BoardGame, INTEGER? | BOOLEAN | NULL = show all |

---

## 4. Role-Based Access

| Role | Access |
|------|--------|
| **Admin** | Full CRUD on Games, Genres, Publishers, Owners, Mechanics |
| **User** | Read-only games list, game details, filtering, recommendations |

**Setup:** Configure Security permissions in lsFusion Administration:
- Grant `admin` role to admin users
- Set `Administration` folder permission to `forbid` for `default` role

---

## 5. Project Structure

```
BoardGame/
├── pom.xml
├── README.md
├── docs/
│   ├── API.md
│   └── DATA_MODEL.md
├── src/main/lsfusion/
│   ├── BoardGameDomain.lsf    # Domain entities
│   ├── BoardGameLogic.lsf     # Recommendation & filtering logic
│   ├── BoardGameSecurity.lsf  # Role checks
│   ├── BoardGameAuth.lsf      # Bootstrap admin email, участники
│   └── BoardGameUI.lsf        # Forms, actions, navigator
├── src/test/
│   └── ...                    # Test modules
└── data/
    └── example_data.lsf        # Example dataset loader
```

---

## Quick runbook (локальный старт)

Выполнять из корня репозитория (рядом с `pom.xml`).

```powershell
# 1) JAR сервера
.\download-server.ps1

# 2) БД (один раз)
psql -U postgres -f scripts/postgres-init.sql

# 3) Конфиг (один раз): скопировать пример и задать пароль PostgreSQL
copy lsfusion.properties.example lsfusion.properties
# отредактировать lsfusion.properties — заменить CHANGE_ME на реальный db.password

# 4) Запуск (сборка + java с -Ddb.*)
.\run.ps1
```

Проверка: в `logs/start.log` должны появиться строки `Logics instance has successfully started` и `Server has successfully started`.  
Не запускайте голый `java -cp ... BusinessLogicsBootstrap` без `-Ddb.*` — пароль из файла в каталоге проекта bootstrap не подхватит (см. шаг 4 в Installation ниже).

### Частые проблемы

| Симптом | Что сделать |
|--------|-------------|
| `psql` не найден | Добавьте в PATH каталог `bin` PostgreSQL (часто `C:\Program Files\PostgreSQL\<версия>\bin`) или вызывайте полный путь: `"C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -f scripts\postgres-init.sql` |
| `Port already in use: 7652` | Уже запущен другой экземпляр сервера. Закройте лишний `java.exe` (или второе окно `run.ps1`). В cmd/PowerShell: сначала `netstat -ano`, найдите строку с `:7652` и PID в последнем столбце, затем `taskkill /PID <номер> /F`. Либо в `lsfusion.properties`: `rmi.port=7653` |
| Ошибка при `download-server.ps1`: JAR занят другим процессом | Остановите запущенный lsFusion / закройте IDE, держащую `lib\lsfusion-server-6.1.jar`, затем снова `.\download-server.ps1` |
| Сразу экран логина вместо приветствия | В `lsfusion.properties` (локально) или на сервере логики должны быть `settings.enableUI=2` и `settings.enableAPI=1` (см. `lsfusion.properties.example` и `docker/logics/entrypoint.sh`). Перезапустите сервер логики. |
| `UnknownHostException: logics` у веб-клиента | Хост `logics` виден только внутри compose. См. раздел **«Веб-клиент: UnknownHostException: logics»** выше; для Tomcat на хосте используйте `127.0.0.1`. |

---

## Первый администратор по email

В `lsfusion.properties` (и при запуске через `run.ps1` / `run.sh`) задаётся `boardgame.initialAdminEmail` (в Docker: `BOARDGAME_INITIAL_ADMIN_EMAIL`, см. `.env.example`). Кратко, как это работает:

- **Совпадение email с конфигом** — логика в `BoardGameAuth.lsf` сравнивает email пользователя с этим значением (без учёта регистра в типичной настройке).
- **Регистрация** — при успешной регистрации пользователя с подходящим email роль `admin` выдаётся автоматически (если её ещё не было).
- **Вход** — при поддержке вашей версией lsFusion события входа в коде проекта роль сверяется и при каждом входе (удобно, если учётка появилась до настройки конфига). Если такого события в сборке нет, остаются регистрация и смена email.
- **Смена email** — при смене email на адрес из конфига роль `admin` может быть выдана так же.
- **Другие администраторы** — уже действующий администратор назначает коллег в форме **«Участники и роли»** в разделе администрирования.
- **Защита** — нельзя снять роль с себя и с единственного администратора в системе (сообщения в интерфейсе объясняют причину).

**Регистрация для участников:** опционально `boardgame.registrationUrl` — полный URL страницы регистрации в браузере; кнопка «Зарегистрироваться» на приветствии откроет его. Если URL не задан, показывается понятное сообщение участнику и подсказка администратору. В Docker: `BOARDGAME_REGISTRATION_URL`.

### Приветствие до логина (локальный сервер и Docker)

По умолчанию lsFusion открывает **экран логина** до навигатора (`settings.enableUI=1`). В проекте для сценария «сначала приветственная страница клуба» задано **`settings.enableUI=2`** (анонимный доступ к UI) и **`settings.enableAPI=1`** (без анонимного API).

- **Локально:** строки в `lsfusion.properties` (см. `lsfusion.properties.example`); `run.ps1` пробрасывает `settings.*` в JVM.
- **Docker:** те же значения добавлены в `docker/logics/entrypoint.sh` для сервиса **logics**.

Кнопка **«Войти»** на приветствии вызывает стандартный диалог авторизации. Полный сценарий «гость без авто-админа» проверяйте с **`LSFUSION_DEVMODE=false`** (см. ниже).

## Docker (веб-интерфейс на http://localhost:8080)

Нужны **Docker** и **Docker Compose v2** (`docker compose`). Поднимаются три сервиса: **PostgreSQL**, сервер логики lsFusion (**logics**), **Tomcat** с `lsfusion-client-6.1.war`.

1. Освободите порты **8080**, **7651**, **7652** (остановите локальный `.\run.ps1`, если он уже слушает эти порты).

2. (Необязательно) Создайте `.env` рядом с `docker-compose.yml` — скопируйте `.env.example` и задайте свой `POSTGRES_PASSWORD`.  
   Если `.env` нет, используется пароль по умолчанию **`boardgame_dev`** (только для локальной разработки).

3. Из корня репозитория:

```powershell
docker compose up --build
```

Первый запуск **logics** может занять 1–2 минуты (сборка образа + синхронизация БД).

4. Откройте в браузере: **http://localhost:8080/lsfusion**

### Логин / пароль в Docker

По умолчанию в `docker-compose.yml` включен **`LSFUSION_DEVMODE=true`** — это режим разработки lsFusion: веб-клиент пускает **анонимно** (как admin), чтобы можно было быстро посмотреть UI без настройки пользователей.

Если хотите нормальный логин:
- выставьте в `.env`: `LSFUSION_DEVMODE=false`
- (опционально) задайте `LSFUSION_INITIAL_ADMIN_PASSWORD=...`
- и **сбросьте volume БД**, чтобы параметр применился на “первом старте”:

```powershell
docker compose down -v
docker compose up --build
```

Остановка: `Ctrl+C` или `docker compose down`. Данные PostgreSQL сохраняются в volume `postgres_data`; полный сброс БД в Docker: `docker compose down -v`.

Структура: `docker-compose.yml`, `docker/logics/` (Dockerfile + entrypoint), `docker/web/` (Tomcat + WAR). Адрес RMI для веб-клиента задаётся при старте контейнера **web** переменными **`LSFUSION_LOGICS_HOST`** и **`LSFUSION_LOGICS_PORT`** (по умолчанию `logics` и `7652` внутри сети compose). Если Tomcat запущен **на вашей машине**, а сервер логики — тоже локально, в конфиге контекста нужен **`localhost`** / **`127.0.0.1`**, а не имя docker-сервиса.

### Веб-клиент: `UnknownHostException: logics`

Ошибка **`Application server [logics:7652] is not available`** возникает, когда процесс Tomcat (или другой веб-клиент) резолвит хост **`logics`**, доступный только **внутри** сети Docker Compose. Исправления:

- **Все в Docker:** оставьте `LSFUSION_LOGICS_HOST=logics` (по умолчанию в `.env.example` / compose).
- **Web в Docker, logics на хосте:** в `.env` задайте `LSFUSION_LOGICS_HOST=host.docker.internal` (Windows/macOS; на Linux может понадобиться `extra_hosts`).
- **Tomcat на хосте, logics на хосте:** host в дескрипторе контекста — **`127.0.0.1`** (порт тот же, что `rmi.port`, обычно 7652).

---

## 6. Setup Instructions

### Prerequisites

- **Java** 17 (как в `pom.xml`; lsFusion 6.1 на этой сборке проверялась с JDK 17)
- **PostgreSQL** 9.6+
- **Maven** 3.6+
- **IntelliJ IDEA** 2025.2+ with lsFusion plugin (recommended)

### Installation

1. **Download lsFusion server JAR** (обязательно при ошибке Maven dependency):
   ```powershell
   .\download-server.ps1
   ```
   Или вручную: скачайте [lsfusion-server-6.1.jar](https://download.lsfusion.org/java/lsfusion-server-6.1.jar) и поместите в папку `lib/`.

2. **Сборка проекта:**
   ```bash
   mvn clean compile
   ```

3. **PostgreSQL:** создайте БД (от пользователя с правами суперпользователя):
   ```bash
   psql -U postgres -f scripts/postgres-init.sql
   ```

4. **Database configuration:** скопируйте `lsfusion.properties.example` → `lsfusion.properties` в **корне проекта** и задайте `db.password`. Файл **в .gitignore** — не коммитьте.

   **Важно:** `BusinessLogicsBootstrap` ищет файл как `/lsfusion.properties` (на Windows это `C:\lsfusion.properties`), а не рядом с `pom.xml`. Поэтому для локального запуска **не вызывайте `java` вручную без `-D`**, иначе пароль БД будет пустым. Используйте скрипты ниже.

5. **Run server (рекомендуется):**
   - Windows: `.\run.ps1` или `run.bat`
   - Linux/macOS: `chmod +x run.sh && ./run.sh`

   Скрипт выполняет `mvn clean compile` и запускает `java` с `-Ddb.server`, `-Ddb.name`, `-Ddb.user`, `-Ddb.password`, прочитанными из **локального** `lsfusion.properties`.

6. **Клиент:** после строки `Server has successfully started` в `logs/start.log` используйте **десктоп-клиент** (JNLP / установщик — ссылки печатаются в лог) или поднимите **веб-клиент** через Tomcat + `lsfusion-client-*.war` ([документация](https://lsfusion.github.io/Development_manual/)). Встроенный bootstrap сам по себе не обязан отдавать UI на `http://localhost:8080`.

7. **Пример данных:** в навигаторе клиента — действие «Load example board games».

### Default Users

- **admin** / (set password) — Full access
- **default** role — Read-only + recommendations

---

## 7. Testing

See `docs/TESTING.md` for unit test documentation.

Run tests via lsFusion test framework or Maven.

---

## 8. License

MIT License
