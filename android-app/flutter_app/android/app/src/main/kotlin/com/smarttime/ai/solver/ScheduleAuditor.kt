package com.smarttime.ai.solver

/**
 * ScheduleAuditor: Timefold-inspired post-solve scoring and validation engine.
 *
 * This module evaluates a completed [SmartCspSolver.SolveResult] and produces a
 * detailed [AuditReport] containing hard-constraint violations, soft-penalty
 * breakdowns, and improvement suggestions.
 *
 * Design rationale (Timefold/OptaPlanner inspired):
 *   - Hard constraints return negative infinity-scale penalties (each = -1_000_000_000)
 *   - Soft constraints return weighted penalties that degrade quality but don't
 *     invalidate the schedule
 *   - The final [HardSoftScore] is comparable: higher is always better
 *
 * This auditor catches issues the solver's `canPlace` may miss due to the
 * `shouldBypassRoomConflictForSoftSeed` optimization, and adds enterprise
 * constraints the solver doesn't yet enforce (room capacity, weekly spread, etc.).
 */
class ScheduleAuditor {

    // ─── Score Model ──────────────────────────────────────────────────

    data class HardSoftScore(
        val hardScore: Long,
        val softScore: Long,
    ) : Comparable<HardSoftScore> {
        val total: Long get() = hardScore + softScore
        val isFeasible: Boolean get() = hardScore == 0L

        override fun compareTo(other: HardSoftScore): Int {
            val h = hardScore.compareTo(other.hardScore)
            return if (h != 0) h else softScore.compareTo(other.softScore)
        }

        override fun toString(): String = "HardSoftScore(hard=$hardScore, soft=$softScore, feasible=$isFeasible)"
    }

    // ─── Violation & Penalty Types ────────────────────────────────────

    data class Violation(
        val constraintName: String,
        val severity: Severity,
        val affectedEntities: List<String>,
        val description: String,
        val penalty: Long,
    )

    enum class Severity { HARD, NEAR_HARD, SOFT }

    data class AuditReport(
        val score: HardSoftScore,
        val violations: List<Violation>,
        val suggestions: List<String>,
    ) {
        val hardViolations: List<Violation> get() = violations.filter { it.severity == Severity.HARD }
        val softViolations: List<Violation> get() = violations.filter { it.severity != Severity.HARD }
    }

    // ─── Room Capacity Extension ──────────────────────────────────────

    data class RoomCapacity(
        val roomId: String,
        val maxStudents: Int,
    )

    data class ClassSize(
        val classId: String,
        val studentCount: Int,
    )

    // ─── Main Audit Entry Point ───────────────────────────────────────

    fun audit(
        result: SmartCspSolver.SolveResult,
        rooms: List<SmartCspSolver.Room> = emptyList(),
        roomCapacities: Map<String, Int> = emptyMap(),
        classSizes: Map<String, Int> = emptyMap(),
        days: Int = 5,
        periodsPerDay: Int = 8,
        constraints: SmartCspSolver.ConstraintConfig = SmartCspSolver.ConstraintConfig(),
    ): AuditReport {
        val violations = mutableListOf<Violation>()
        val suggestions = mutableListOf<String>()

        // ── HARD CONSTRAINT CHECKS ──

        violations += checkTeacherClashes(result.assignments)
        violations += checkClassClashes(result.assignments)
        violations += checkRoomClashes(result.assignments)
        violations += checkRoomCapacity(result.assignments, roomCapacities, classSizes)
        violations += checkTeacherAvailability(result.assignments, constraints)
        violations += checkSubjectDailyLimit(result.assignments, constraints)

        // ── SOFT CONSTRAINT CHECKS ──

        violations += checkTeacherConsecutiveOverload(result.assignments, constraints, days, periodsPerDay)
        violations += checkClassConsecutiveOverload(result.assignments, constraints, days, periodsPerDay)
        violations += checkTeacherGaps(result.assignments, days, periodsPerDay, constraints)
        violations += checkClassGaps(result.assignments, days, periodsPerDay, constraints)
        violations += checkSubjectWeeklySpread(result.assignments, days)
        violations += checkTeacherRoomStability(result.assignments, constraints)
        violations += checkTeacherLastPeriodOverflow(result.assignments, constraints, periodsPerDay)
        violations += checkPeriodLoadBalance(result.assignments, days, periodsPerDay)

        // ── SUGGESTIONS ──

        if (violations.any { it.constraintName == "room_capacity_exceeded" }) {
            suggestions += "Some classes are assigned to rooms too small for them. Consider adding roomCapacities and classSizes to your solver input."
        }
        if (violations.any { it.constraintName == "subject_weekly_spread" }) {
            suggestions += "Some subjects are clustered on specific days. Add a subjectWeeklySpread constraint to distribute lessons across the week."
        }
        if (violations.count { it.severity == Severity.HARD } > 0) {
            suggestions += "Hard violations detected: the schedule is infeasible. Review teacher availability and room assignments."
        }

        val hardPenalty = violations.filter { it.severity == Severity.HARD }.sumOf { it.penalty }
        val softPenalty = violations.filter { it.severity != Severity.HARD }.sumOf { it.penalty }

        return AuditReport(
            score = HardSoftScore(hardScore = hardPenalty, softScore = softPenalty),
            violations = violations,
            suggestions = suggestions,
        )
    }

    // ─── HARD: Teacher Double-Booking ─────────────────────────────────

    private fun checkTeacherClashes(assignments: List<SmartCspSolver.Assignment>): List<Violation> {
        val violations = mutableListOf<Violation>()
        // Map: "teacherId|day|period" -> lessonId
        val seen = HashMap<String, String>()
        for (a in assignments) {
            for (teacherId in a.teacherIds) {
                val key = "$teacherId|${a.day}|${a.period}"
                val existing = seen[key]
                if (existing != null) {
                    violations += Violation(
                        constraintName = "teacher_clash",
                        severity = Severity.HARD,
                        affectedEntities = listOf(teacherId, a.lessonId, existing),
                        description = "Teacher $teacherId is double-booked at day=${a.day} period=${a.period} (lessons: $existing, ${a.lessonId})",
                        penalty = -1_000_000_000L,
                    )
                } else {
                    seen[key] = a.lessonId
                }
            }
        }
        return violations
    }

    // ─── HARD: Class Double-Booking ───────────────────────────────────

    private fun checkClassClashes(assignments: List<SmartCspSolver.Assignment>): List<Violation> {
        val violations = mutableListOf<Violation>()
        val seen = HashMap<String, String>()
        for (a in assignments) {
            for (classId in a.classIds) {
                val key = "$classId|${a.day}|${a.period}"
                val existing = seen[key]
                if (existing != null) {
                    violations += Violation(
                        constraintName = "class_clash",
                        severity = Severity.HARD,
                        affectedEntities = listOf(classId, a.lessonId, existing),
                        description = "Class $classId is double-booked at day=${a.day} period=${a.period} (lessons: $existing, ${a.lessonId})",
                        penalty = -1_000_000_000L,
                    )
                } else {
                    seen[key] = a.lessonId
                }
            }
        }
        return violations
    }

    // ─── HARD: Room Double-Booking ────────────────────────────────────

    private fun checkRoomClashes(assignments: List<SmartCspSolver.Assignment>): List<Violation> {
        val violations = mutableListOf<Violation>()
        val seen = HashMap<String, String>()
        for (a in assignments) {
            val key = "${a.roomId}|${a.day}|${a.period}"
            val existing = seen[key]
            if (existing != null) {
                violations += Violation(
                    constraintName = "room_clash",
                    severity = Severity.HARD,
                    affectedEntities = listOf(a.roomId, a.lessonId, existing),
                    description = "Room ${a.roomId} is double-booked at day=${a.day} period=${a.period} (lessons: $existing, ${a.lessonId})",
                    penalty = -1_000_000_000L,
                )
            } else {
                seen[key] = a.lessonId
            }
        }
        return violations
    }

    // ─── HARD: Room Capacity ──────────────────────────────────────────

    private fun checkRoomCapacity(
        assignments: List<SmartCspSolver.Assignment>,
        roomCapacities: Map<String, Int>,
        classSizes: Map<String, Int>,
    ): List<Violation> {
        if (roomCapacities.isEmpty() || classSizes.isEmpty()) return emptyList()
        val violations = mutableListOf<Violation>()
        for (a in assignments) {
            val roomCap = roomCapacities[a.roomId] ?: continue
            val totalStudents = a.classIds.sumOf { classSizes[it] ?: 0 }
            if (totalStudents > roomCap) {
                violations += Violation(
                    constraintName = "room_capacity_exceeded",
                    severity = Severity.HARD,
                    affectedEntities = listOf(a.roomId, a.lessonId) + a.classIds,
                    description = "Room ${a.roomId} (capacity=$roomCap) assigned ${totalStudents} students from classes ${a.classIds} at day=${a.day} period=${a.period}",
                    penalty = -1_000_000_000L,
                )
            }
        }
        return violations
    }

    // ─── HARD: Teacher Availability ───────────────────────────────────

    private fun checkTeacherAvailability(
        assignments: List<SmartCspSolver.Assignment>,
        constraints: SmartCspSolver.ConstraintConfig,
    ): List<Violation> {
        val violations = mutableListOf<Violation>()
        for (a in assignments) {
            for (teacherId in a.teacherIds) {
                val availableSlots = constraints.teacherAvailability[teacherId] ?: continue
                val slotKey = SmartCspSolver.SlotKey(a.day, a.period)
                if (slotKey !in availableSlots) {
                    violations += Violation(
                        constraintName = "teacher_unavailable",
                        severity = Severity.HARD,
                        affectedEntities = listOf(teacherId, a.lessonId),
                        description = "Teacher $teacherId assigned at day=${a.day} period=${a.period} but is not available",
                        penalty = -1_000_000_000L,
                    )
                }
            }
        }
        return violations
    }

    // ─── HARD: Subject Daily Limit ────────────────────────────────────

    private fun checkSubjectDailyLimit(
        assignments: List<SmartCspSolver.Assignment>,
        constraints: SmartCspSolver.ConstraintConfig,
    ): List<Violation> {
        val violations = mutableListOf<Violation>()
        // Count: "classId:subjectId" per day
        val counts = HashMap<String, Int>()
        for (a in assignments) {
            for (classId in a.classIds) {
                val key = "$classId|${a.subjectId}|${a.day}"
                counts[key] = (counts[key] ?: 0) + 1
            }
        }
        for ((key, count) in counts) {
            val parts = key.split("|")
            val classId = parts[0]
            val subjectId = parts[1]
            val day = parts[2]
            val limit = constraints.subjectDailyLimit["$classId:$subjectId"] ?: continue
            if (count > limit) {
                violations += Violation(
                    constraintName = "subject_daily_limit_exceeded",
                    severity = Severity.HARD,
                    affectedEntities = listOf(classId, subjectId),
                    description = "Class $classId has $count periods of $subjectId on day $day (limit=$limit)",
                    penalty = -1_000_000_000L,
                )
            }
        }
        return violations
    }

    // ─── SOFT: Teacher Consecutive Overload ───────────────────────────

    private fun checkTeacherConsecutiveOverload(
        assignments: List<SmartCspSolver.Assignment>,
        constraints: SmartCspSolver.ConstraintConfig,
        days: Int,
        periodsPerDay: Int,
    ): List<Violation> {
        val violations = mutableListOf<Violation>()
        val teacherDayPeriods = buildEntityDayPeriods(assignments, periodsPerDay) { a ->
            a.teacherIds.map { it to (a.day to a.period) }
        }
        for ((teacherId, dayPeriods) in teacherDayPeriods) {
            val maxConsecutive = constraints.teacherMaxConsecutivePeriods[teacherId] ?: continue
            for (day in 1..days) {
                val periods = dayPeriods[day] ?: continue
                val overload = maxConsecutiveRun(periods) - maxConsecutive
                if (overload > 0) {
                    val weight = constraints.softWeights["teacher_consecutive_overload"]
                        ?: SmartCspSolver.ConstraintWeight.NEAR_HARD.penalty
                    violations += Violation(
                        constraintName = "teacher_consecutive_overload",
                        severity = Severity.NEAR_HARD,
                        affectedEntities = listOf(teacherId),
                        description = "Teacher $teacherId has ${maxConsecutive + overload} consecutive periods on day $day (max=$maxConsecutive)",
                        penalty = overload.toLong() * weight,
                    )
                }
            }
        }
        return violations
    }

    // ─── SOFT: Class Consecutive Overload ─────────────────────────────

    private fun checkClassConsecutiveOverload(
        assignments: List<SmartCspSolver.Assignment>,
        constraints: SmartCspSolver.ConstraintConfig,
        days: Int,
        periodsPerDay: Int,
    ): List<Violation> {
        val violations = mutableListOf<Violation>()
        val classDayPeriods = buildEntityDayPeriods(assignments, periodsPerDay) { a ->
            a.classIds.map { it to (a.day to a.period) }
        }
        for ((classId, dayPeriods) in classDayPeriods) {
            val maxConsecutive = constraints.classMaxConsecutivePeriods[classId] ?: continue
            for (day in 1..days) {
                val periods = dayPeriods[day] ?: continue
                val overload = maxConsecutiveRun(periods) - maxConsecutive
                if (overload > 0) {
                    val weight = constraints.softWeights["class_consecutive_overload"]
                        ?: SmartCspSolver.ConstraintWeight.NEAR_HARD.penalty
                    violations += Violation(
                        constraintName = "class_consecutive_overload",
                        severity = Severity.NEAR_HARD,
                        affectedEntities = listOf(classId),
                        description = "Class $classId has ${maxConsecutive + overload} consecutive periods on day $day (max=$maxConsecutive)",
                        penalty = overload.toLong() * weight,
                    )
                }
            }
        }
        return violations
    }

    // ─── SOFT: Teacher Gaps ───────────────────────────────────────────

    private fun checkTeacherGaps(
        assignments: List<SmartCspSolver.Assignment>,
        days: Int,
        periodsPerDay: Int,
        constraints: SmartCspSolver.ConstraintConfig,
    ): List<Violation> {
        val violations = mutableListOf<Violation>()
        val teacherDayPeriods = buildEntityDayPeriods(assignments, periodsPerDay) { a ->
            a.teacherIds.map { it to (a.day to a.period) }
        }
        val weight = constraints.softWeights["teacher_gaps"]
            ?: SmartCspSolver.ConstraintWeight.LOW_SOFT.penalty
        for ((teacherId, dayPeriods) in teacherDayPeriods) {
            for (day in 1..days) {
                val periods = dayPeriods[day] ?: continue
                val gaps = countGaps(periods)
                if (gaps > 0) {
                    violations += Violation(
                        constraintName = "teacher_gaps",
                        severity = Severity.SOFT,
                        affectedEntities = listOf(teacherId),
                        description = "Teacher $teacherId has $gaps gap(s) on day $day",
                        penalty = gaps.toLong() * weight,
                    )
                }
            }
        }
        return violations
    }

    // ─── SOFT: Class Gaps ─────────────────────────────────────────────

    private fun checkClassGaps(
        assignments: List<SmartCspSolver.Assignment>,
        days: Int,
        periodsPerDay: Int,
        constraints: SmartCspSolver.ConstraintConfig,
    ): List<Violation> {
        val violations = mutableListOf<Violation>()
        val classDayPeriods = buildEntityDayPeriods(assignments, periodsPerDay) { a ->
            a.classIds.map { it to (a.day to a.period) }
        }
        val weight = constraints.softWeights["class_gaps"]
            ?: SmartCspSolver.ConstraintWeight.LOW_SOFT.penalty
        for ((classId, dayPeriods) in classDayPeriods) {
            for (day in 1..days) {
                val periods = dayPeriods[day] ?: continue
                val gaps = countGaps(periods)
                if (gaps > 0) {
                    violations += Violation(
                        constraintName = "class_gaps",
                        severity = Severity.SOFT,
                        affectedEntities = listOf(classId),
                        description = "Class $classId has $gaps gap(s) on day $day",
                        penalty = gaps.toLong() * weight,
                    )
                }
            }
        }
        return violations
    }

    // ─── SOFT: Subject Weekly Spread (NEW) ────────────────────────────
    //
    // Enterprise constraint missing from SmartCspSolver:
    // Penalizes when a subject's lessons are clustered on specific days
    // instead of being spread evenly across the week.
    // E.g., 4 Math lessons all on Mon+Tue = bad; 1 per day for 4 days = good.

    private fun checkSubjectWeeklySpread(
        assignments: List<SmartCspSolver.Assignment>,
        days: Int,
    ): List<Violation> {
        val violations = mutableListOf<Violation>()
        // Group by classId + subjectId, count per day
        val classSubjectDays = HashMap<String, HashMap<Int, Int>>()
        for (a in assignments) {
            for (classId in a.classIds) {
                val key = "$classId:${a.subjectId}"
                val dayCounts = classSubjectDays.getOrPut(key) { HashMap() }
                dayCounts[a.day] = (dayCounts[a.day] ?: 0) + 1
            }
        }

        for ((key, dayCounts) in classSubjectDays) {
            val totalLessons = dayCounts.values.sum()
            if (totalLessons <= 1) continue // single lesson needs no spreading
            val daysUsed = dayCounts.size
            val idealDaysUsed = minOf(totalLessons, days)
            val spreadDeficit = idealDaysUsed - daysUsed
            if (spreadDeficit > 0) {
                val parts = key.split(":")
                violations += Violation(
                    constraintName = "subject_weekly_spread",
                    severity = Severity.SOFT,
                    affectedEntities = listOf(parts[0], parts[1]),
                    description = "Class ${parts[0]} has $totalLessons ${parts[1]} lessons across only $daysUsed day(s), ideally $idealDaysUsed",
                    penalty = spreadDeficit.toLong() * SmartCspSolver.ConstraintWeight.MED_SOFT.penalty,
                )
            }
        }
        return violations
    }

    // ─── SOFT: Teacher Room Stability ─────────────────────────────────

    private fun checkTeacherRoomStability(
        assignments: List<SmartCspSolver.Assignment>,
        constraints: SmartCspSolver.ConstraintConfig,
    ): List<Violation> {
        val violations = mutableListOf<Violation>()
        val teacherRooms = HashMap<String, MutableSet<String>>()
        for (a in assignments) {
            for (teacherId in a.teacherIds) {
                teacherRooms.getOrPut(teacherId) { mutableSetOf() }.add(a.roomId)
            }
        }
        val weight = constraints.softWeights["teacher_room_stability"]
            ?: SmartCspSolver.ConstraintWeight.HINT.penalty
        for ((teacherId, rooms) in teacherRooms) {
            val excess = rooms.size - 1
            if (excess > 0) {
                violations += Violation(
                    constraintName = "teacher_room_stability",
                    severity = Severity.SOFT,
                    affectedEntities = listOf(teacherId) + rooms.toList(),
                    description = "Teacher $teacherId uses ${rooms.size} different rooms (ideally 1)",
                    penalty = excess.toLong() * weight,
                )
            }
        }
        return violations
    }

    // ─── SOFT: Teacher Last Period Overflow ────────────────────────────

    private fun checkTeacherLastPeriodOverflow(
        assignments: List<SmartCspSolver.Assignment>,
        constraints: SmartCspSolver.ConstraintConfig,
        periodsPerDay: Int,
    ): List<Violation> {
        val violations = mutableListOf<Violation>()
        val teacherLastCount = HashMap<String, Int>()
        for (a in assignments) {
            if (a.period == periodsPerDay) {
                for (teacherId in a.teacherIds) {
                    teacherLastCount[teacherId] = (teacherLastCount[teacherId] ?: 0) + 1
                }
            }
        }
        val weight = constraints.softWeights["teacher_last_period_overflow"]
            ?: SmartCspSolver.ConstraintWeight.HIGH_SOFT.penalty
        for ((teacherId, count) in teacherLastCount) {
            val cap = constraints.teacherNoLastPeriodMaxPerWeek[teacherId] ?: continue
            val overflow = count - cap
            if (overflow > 0) {
                violations += Violation(
                    constraintName = "teacher_last_period_overflow",
                    severity = Severity.SOFT,
                    affectedEntities = listOf(teacherId),
                    description = "Teacher $teacherId has $count last-period assignments (cap=$cap)",
                    penalty = overflow.toLong() * weight,
                )
            }
        }
        return violations
    }

    // ─── SOFT: Period Load Balance ────────────────────────────────────

    private fun checkPeriodLoadBalance(
        assignments: List<SmartCspSolver.Assignment>,
        days: Int,
        periodsPerDay: Int,
    ): List<Violation> {
        val violations = mutableListOf<Violation>()
        val slotCounts = HashMap<String, Int>()
        for (a in assignments) {
            val key = "${a.day}|${a.period}"
            slotCounts[key] = (slotCounts[key] ?: 0) + 1
        }
        val totalSlots = days * periodsPerDay
        val totalAssignments = assignments.size
        val avgPerSlot = if (totalSlots > 0) totalAssignments.toDouble() / totalSlots else 0.0

        var maxImbalance = 0
        for ((_, count) in slotCounts) {
            val deviation = count - avgPerSlot.toInt()
            if (deviation > maxImbalance) maxImbalance = deviation
        }

        if (maxImbalance > 3) {
            violations += Violation(
                constraintName = "period_load_imbalance",
                severity = Severity.SOFT,
                affectedEntities = emptyList(),
                description = "Period load is unbalanced: max deviation from average is $maxImbalance lessons",
                penalty = maxImbalance.toLong() * SmartCspSolver.ConstraintWeight.MED_SOFT.penalty,
            )
        }
        return violations
    }

    // ─── Helper: Build Entity-Day-Period Map ──────────────────────────

    private fun buildEntityDayPeriods(
        assignments: List<SmartCspSolver.Assignment>,
        periodsPerDay: Int,
        extractor: (SmartCspSolver.Assignment) -> List<Pair<String, Pair<Int, Int>>>,
    ): Map<String, Map<Int, List<Int>>> {
        val result = HashMap<String, HashMap<Int, MutableList<Int>>>()
        for (a in assignments) {
            for ((entityId, dayPeriod) in extractor(a)) {
                val dayMap = result.getOrPut(entityId) { HashMap() }
                dayMap.getOrPut(dayPeriod.first) { mutableListOf() }.add(dayPeriod.second)
            }
        }
        // Sort period lists for gap/consecutive calculations
        for (dayMap in result.values) {
            for (entry in dayMap) {
                entry.value.sort()
            }
        }
        return result
    }

    // ─── Helper: Count Gaps in Sorted Period List ─────────────────────

    private fun countGaps(sortedPeriods: List<Int>): Int {
        if (sortedPeriods.size <= 1) return 0
        val first = sortedPeriods.first()
        val last = sortedPeriods.last()
        val span = last - first + 1
        return span - sortedPeriods.size
    }

    // ─── Helper: Max Consecutive Run in Sorted Period List ────────────

    private fun maxConsecutiveRun(sortedPeriods: List<Int>): Int {
        if (sortedPeriods.isEmpty()) return 0
        var maxRun = 1
        var currentRun = 1
        for (i in 1 until sortedPeriods.size) {
            if (sortedPeriods[i] == sortedPeriods[i - 1] + 1) {
                currentRun++
                if (currentRun > maxRun) maxRun = currentRun
            } else {
                currentRun = 1
            }
        }
        return maxRun
    }
}
