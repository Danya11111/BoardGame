# Testing Documentation

## Test Module: BoardGameTest

The `BoardGameTest.lsf` module contains unit tests for the recommendation algorithm and filtering logic.

### Running Tests

1. **Via lsFusion IDE:** Add `runAllTests` action to a form or run it from the console.
2. **Manual verification:** Run `createTestData()` first, then individual test actions.

### Test Cases

#### Recommendation Algorithm

| Test | Description | Expected |
|------|-------------|----------|
| `testRecommendationScoreSameGenre` | Catan vs Carcassonne (same genre, overlapping players, age ±2) | Score = 6 |
| `testRecommendationScoreDifferentGenre` | Catan vs Codenames (different genre) | Score = 3 |
| `testTopRecommendation` | Top recommendation for Catan | Carcassonne |
| `testRecommendationSameGame` | Source = candidate | Score = 0 |
| `testMultipleEqualScores` | Deterministic ordering | Valid BoardGame objects |

#### Filtering Logic

| Test | Description | Expected |
|------|-------------|----------|
| `testMatchesGenreNullFilter` | NULL genre filter | All games match |
| `testMatchesPlayerCount` | 4 players filter | 2 games (Catan, Codenames) |
| `testMatchesDuration` | 30 min max | 1 game (Codenames) |

### Edge Cases Covered

- **No matches:** `topRecommendedGame` returns NULL when no candidates exist
- **Multiple equal scores:** Sorted by `id(candidate)` for determinism
- **Empty database:** Tests create their own data via `createTestData()`
- **Same game:** `recommendationScore(g, g) = 0` (excluded in logic)
