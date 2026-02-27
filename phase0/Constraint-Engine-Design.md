# SmartTime AI — Constraint Engine Design

## Problem Type
School Timetabling = Constraint Satisfaction + Optimization.

## Model
- Decision variable: assignment of lesson instance -> (day, period, room)
- Entities: teacher, class-section, subject, room, group, period

## Hard Constraints (must satisfy)
1. Teacher cannot teach two lessons in same slot.
2. Class-section cannot have two lessons in same slot.
3. Room cannot host two lessons in same slot.
4. Teacher availability respected.
5. Required lesson counts per subject/section must be satisfied.
6. Room type/capacity compatibility.

## Soft Constraints (scored)
- Minimize teacher gaps.
- Minimize class gaps.
- Prefer subject spread across week.
- Avoid too many consecutive periods.
- Balance teacher load distribution.
- Preferences: preferred slots/rooms.

## Scoring
`totalScore = hardViolations * -1e9 + softWeightedPenalty`
- hardViolations must be 0 for publish.
- soft penalties weighted (configurable per school).

## Solver Strategy (V1)
1. Pre-check feasibility (data sanity, obvious impossible configs).
2. Constructive phase: greedy placement for hard-feasible baseline.
3. Improvement phase: local search (swap/move, simulated annealing/tabu-lite style).
4. Conflict diagnostics generation (unscheduled items + violated rules).

## Re-run with Manual Overrides
- Pinned lessons are frozen constraints.
- Solver optimizes only remaining slots.
- If infeasible with pins, show blocking pin diagnostics.

## Output Contract
- Timetable assignments
- hardViolations[]
- softPenaltyBreakdown[]
- unscheduledLessons[]
- score metadata + runtime

## Test Strategy for Engine
- Unit tests per constraint rule.
- Synthetic benchmark datasets (small/medium/large).
- Regression snapshots for deterministic seeds.
