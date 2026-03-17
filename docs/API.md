# API Documentation

## Recommendation System

### recommendationScore(source, candidate)

**Signature:** `INTEGER (BoardGame source, BoardGame candidate)`

**Description:** Computes similarity score between two games.

**Input:**
- `source`: The game for which we seek recommendations
- `candidate`: A potential recommendation

**Output:** Integer score (0–6 typically)

**Example:**
```
source: Catan (Genre: Strategy, 3-4 players, age 10)
candidate: Carcassonne (Genre: Strategy, 2-5 players, age 8)
→ score: 3 (genre) + 2 (player overlap) + 1 (age ±2) = 6
```

---

### topRecommendedGame(source, rank)

**Signature:** `BoardGame (BoardGame source, INTEGER rank)`

**Description:** Returns the N-th most similar game (1 = best).

**Input:**
- `source`: Source game
- `rank`: 1, 2, or 3 (RECOMMENDATION_TOP_COUNT)

**Output:** BoardGame or NULL if no match

**Edge cases:**
- rank > available recommendations: NULL
- Empty database: NULL
- Equal scores: Deterministic by id(candidate)

---

### recommendationExplanationTrimmed(source, candidate)

**Signature:** `TEXT (BoardGame source, BoardGame candidate)`

**Description:** Human-readable explanation of why a game was recommended.

**Output:** e.g., "Same genre; Similar player count; Similar age rating"

---

## Filtering Properties

### matchesGenre(g, genreFilter)

**Signature:** `BOOLEAN (BoardGame g, Genre genreFilter)`

**Behavior:** TRUE when genre(g) = genreFilter OR genreFilter IS NULL.

---

### matchesPlayerCount(g, players)

**Signature:** `BOOLEAN (BoardGame g, INTEGER players)`

**Behavior:** TRUE when minPlayers(g) ≤ players ≤ maxPlayers(g) OR players IS NULL.

---

### matchesDuration(g, maxDuration)

**Signature:** `BOOLEAN (BoardGame g, INTEGER maxDuration)`

**Behavior:** TRUE when durationMinutes(g) ≤ maxDuration OR maxDuration IS NULL.

---

### matchesMinAge(g, age)

**Signature:** `BOOLEAN (BoardGame g, INTEGER age)`

**Behavior:** TRUE when minAge(g) ≤ age OR age IS NULL.

---

### matchesAvailable(g, availableOnly)

**Signature:** `BOOLEAN (BoardGame g, BOOLEAN availableOnly)`

**Behavior:** TRUE when available(g) = TRUE OR availableOnly = FALSE.

---

## Actions

### getRecommendations(g)

**Signature:** `ACTION (BoardGame g)`

**Description:** Opens recommendations form for the given game.

**Usage:** Called from game list or game detail form.
