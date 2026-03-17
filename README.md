# Board Game Recommendation System

A production-grade Board Game Recommendation System built on **lsFusion** — a declarative platform for information systems development.

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
| Genre match | +3 | Same genre as source game |
| Player range overlap | +2 | minPlayers ≤ candidate.max AND candidate.min ≤ source.max |
| Age similarity | +1 | |minAge(source) - minAge(candidate)| ≤ 2 |

### Output

- **Top 3** most similar games sorted by score DESC
- **Explanation** for each recommendation (e.g., "Same genre; Similar player count")

### Extensibility

Modify constants in `BoardGameDomain.lsf`:

```lsf
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
│   └── BoardGameUI.lsf        # Forms, actions, navigator
├── src/test/
│   └── ...                    # Test modules
└── data/
    └── example_data.lsf        # Example dataset loader
```

---

## 6. Setup Instructions

### Prerequisites

- **Java** 8 or later
- **PostgreSQL** 9.6+
- **Maven** 3.6+
- **IntelliJ IDEA** 2025.2+ with lsFusion plugin (recommended)

### Installation

1. **Recommended: Use lsFusion IDE**
   - Install IntelliJ IDEA 2025.2+ with lsFusion plugin
   - Create new lsFusion project, then copy `src/main/lsfusion/*.lsf` files
   - Download lsFusion server via IDE (Download button)

2. **Alternative: Maven build**
   ```bash
   cd BoardGame
   mvn clean install
   ```

3. **Database configuration:** Create `lsfusion.properties` in project root:
   ```properties
   db.connect=postgresql://localhost:5432/boardgame
   db.user=postgres
   db.password=yourpassword
   ```

4. **Run server:** Use lsFusion IDE run configuration (recommended) or start the server JAR

5. **Access:** Web client at `http://localhost:8080/lsfusion`

6. **Load example data:** Click "Load example board games" in the Board Games navigator folder

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
