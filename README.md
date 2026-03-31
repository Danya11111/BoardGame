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

---

## Первый администратор по email

В `lsfusion.properties` (и при запуске через `run.ps1` / `run.sh`) можно задать `boardgame.initialAdminEmail`. Пользователь с таким email получит роль `admin` при регистрации или при смене email. В Docker: переменная окружения `BOARDGAME_INITIAL_ADMIN_EMAIL` (см. `.env.example`).

Опционально: `boardgame.registrationUrl` — полный URL страницы регистрации в браузере; кнопка «Зарегистрироваться» на приветствии откроет его. В Docker: `BOARDGAME_REGISTRATION_URL`.

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

Структура: `docker-compose.yml`, `docker/logics/` (Dockerfile + entrypoint), `docker/web/` (Tomcat + WAR + `lsfusion-context.xml` с `host=logics` для RMI внутри сети compose).

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
