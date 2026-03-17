# Data Model Documentation

## Entity Relationship Explanation

### One-to-Many Relationships

1. **Genre → BoardGame**
   - One genre has many games (e.g., "Strategy" has Catan, Carcassonne, etc.)
   - Implemented via `genre` property on BoardGame

2. **Publisher → BoardGame**
   - One publisher publishes many games
   - Implemented via `publisher` property on BoardGame

3. **Owner → BoardGame**
   - One owner can own many game copies
   - Implemented via `owner` property on BoardGame

### Many-to-Many Relationship

4. **BoardGame ↔ Mechanic**
   - A game can have multiple mechanics (e.g., Dice Rolling, Tile Placement)
   - A mechanic can apply to many games
   - Implemented via link table `boardGameMechanic(BoardGame, Mechanic)` with `hasMechanic` property

---

## Attribute Specifications

### BoardGame

| Attribute | Type | Constraints |
|----------|------|-------------|
| name | ISTRING[100] | Required for display |
| description | TEXT | Optional |
| genre | Genre | FK to Genre |
| minPlayers | INTEGER | ≥ 1 |
| maxPlayers | INTEGER | ≥ minPlayers |
| durationMinutes | INTEGER | Game length in minutes |
| minAge | INTEGER | Minimum recommended age |
| publisher | Publisher | FK to Publisher |
| owner | Owner | FK to Owner |
| available | BOOLEAN | Availability flag |
| image | IMAGEFILE | Game cover image |

### Genre

| Attribute | Type |
|----------|------|
| name | ISTRING[50] |

### Publisher

| Attribute | Type |
|----------|------|
| name | ISTRING[100] |
| website | TEXT |
| country | ISTRING[50] |

### Owner

| Attribute | Type |
|----------|------|
| name | ISTRING[100] |
| contacts | STRING[255] |

### Mechanic

| Attribute | Type |
|----------|------|
| name | ISTRING[50] |

---

## Physical Model (Tables)

- `genre` — Genre
- `publisher` — Publisher
- `owner` — Owner
- `mechanic` — Mechanic
- `boardGame` — BoardGame
- `boardGameMechanic` — (BoardGame, Mechanic) link table
