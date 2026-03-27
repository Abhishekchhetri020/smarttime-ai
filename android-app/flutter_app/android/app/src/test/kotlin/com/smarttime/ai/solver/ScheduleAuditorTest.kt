package com.smarttime.ai.solver

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ScheduleAuditorTest {

    private val auditor = ScheduleAuditor()
    private val solver = SmartCspSolver()

    // ─── HARD: Teacher Clash Detection ────────────────────────────────

    @Test
    fun `detects teacher double-booking`() {
        val assignments = listOf(
            SmartCspSolver.Assignment("L1", listOf("C1"), listOf("T1"), "MATH", 1, 1, "R1", false, false),
            SmartCspSolver.Assignment("L2", listOf("C2"), listOf("T1"), "SCI", 1, 1, "R2", false, false),
        )
        val result = SmartCspSolver.SolveResult("SEED_FOUND", assignments, emptyList(), emptyList(),
            SmartCspSolver.Diagnostics("test", emptyMap(), SmartCspSolver.Totals(2, 2, 0), SmartCspSolver.SearchStats(0, 0, 0)), 0L)

        val report = auditor.audit(result)

        assertTrue(report.violations.any { it.constraintName == "teacher_clash" })
        assertTrue(!report.score.isFeasible)
    }

    // ─── HARD: Class Clash Detection ──────────────────────────────────

    @Test
    fun `detects class double-booking`() {
        val assignments = listOf(
            SmartCspSolver.Assignment("L1", listOf("C1"), listOf("T1"), "MATH", 1, 1, "R1", false, false),
            SmartCspSolver.Assignment("L2", listOf("C1"), listOf("T2"), "SCI", 1, 1, "R2", false, false),
        )
        val result = SmartCspSolver.SolveResult("SEED_FOUND", assignments, emptyList(), emptyList(),
            SmartCspSolver.Diagnostics("test", emptyMap(), SmartCspSolver.Totals(2, 2, 0), SmartCspSolver.SearchStats(0, 0, 0)), 0L)

        val report = auditor.audit(result)

        assertTrue(report.violations.any { it.constraintName == "class_clash" })
    }

    // ─── HARD: Room Clash Detection ───────────────────────────────────

    @Test
    fun `detects room double-booking`() {
        val assignments = listOf(
            SmartCspSolver.Assignment("L1", listOf("C1"), listOf("T1"), "MATH", 1, 1, "R1", false, false),
            SmartCspSolver.Assignment("L2", listOf("C2"), listOf("T2"), "SCI", 1, 1, "R1", false, false),
        )
        val result = SmartCspSolver.SolveResult("SEED_FOUND", assignments, emptyList(), emptyList(),
            SmartCspSolver.Diagnostics("test", emptyMap(), SmartCspSolver.Totals(2, 2, 0), SmartCspSolver.SearchStats(0, 0, 0)), 0L)

        val report = auditor.audit(result)

        assertTrue(report.violations.any { it.constraintName == "room_clash" })
    }

    // ─── HARD: Room Capacity ──────────────────────────────────────────

    @Test
    fun `detects room capacity overflow`() {
        val assignments = listOf(
            SmartCspSolver.Assignment("L1", listOf("C1"), listOf("T1"), "MATH", 1, 1, "R1", false, false),
        )
        val result = SmartCspSolver.SolveResult("SEED_FOUND", assignments, emptyList(), emptyList(),
            SmartCspSolver.Diagnostics("test", emptyMap(), SmartCspSolver.Totals(1, 1, 0), SmartCspSolver.SearchStats(0, 0, 0)), 0L)

        val report = auditor.audit(
            result,
            roomCapacities = mapOf("R1" to 20),
            classSizes = mapOf("C1" to 35),
        )

        assertTrue(report.violations.any { it.constraintName == "room_capacity_exceeded" })
        assertTrue(!report.score.isFeasible)
    }

    @Test
    fun `passes when room capacity is sufficient`() {
        val assignments = listOf(
            SmartCspSolver.Assignment("L1", listOf("C1"), listOf("T1"), "MATH", 1, 1, "R1", false, false),
        )
        val result = SmartCspSolver.SolveResult("SEED_FOUND", assignments, emptyList(), emptyList(),
            SmartCspSolver.Diagnostics("test", emptyMap(), SmartCspSolver.Totals(1, 1, 0), SmartCspSolver.SearchStats(0, 0, 0)), 0L)

        val report = auditor.audit(
            result,
            roomCapacities = mapOf("R1" to 40),
            classSizes = mapOf("C1" to 35),
        )

        assertTrue(report.violations.none { it.constraintName == "room_capacity_exceeded" })
    }

    // ─── SOFT: Subject Weekly Spread ──────────────────────────────────

    @Test
    fun `penalizes subject clustering on single day`() {
        // 4 Math lessons all on day 1 instead of spread across the week
        val assignments = listOf(
            SmartCspSolver.Assignment("L1", listOf("C1"), listOf("T1"), "MATH", 1, 1, "R1", false, false),
            SmartCspSolver.Assignment("L2", listOf("C1"), listOf("T1"), "MATH", 1, 2, "R1", false, false),
            SmartCspSolver.Assignment("L3", listOf("C1"), listOf("T1"), "MATH", 1, 3, "R1", false, false),
            SmartCspSolver.Assignment("L4", listOf("C1"), listOf("T1"), "MATH", 1, 4, "R1", false, false),
        )
        val result = SmartCspSolver.SolveResult("SEED_FOUND", assignments, emptyList(), emptyList(),
            SmartCspSolver.Diagnostics("test", emptyMap(), SmartCspSolver.Totals(4, 4, 0), SmartCspSolver.SearchStats(0, 0, 0)), 0L)

        val report = auditor.audit(result)

        assertTrue(report.violations.any { it.constraintName == "subject_weekly_spread" })
    }

    @Test
    fun `no penalty when subject is well-spread`() {
        val assignments = listOf(
            SmartCspSolver.Assignment("L1", listOf("C1"), listOf("T1"), "MATH", 1, 1, "R1", false, false),
            SmartCspSolver.Assignment("L2", listOf("C1"), listOf("T1"), "MATH", 2, 1, "R1", false, false),
            SmartCspSolver.Assignment("L3", listOf("C1"), listOf("T1"), "MATH", 3, 1, "R1", false, false),
            SmartCspSolver.Assignment("L4", listOf("C1"), listOf("T1"), "MATH", 4, 1, "R1", false, false),
        )
        val result = SmartCspSolver.SolveResult("SEED_FOUND", assignments, emptyList(), emptyList(),
            SmartCspSolver.Diagnostics("test", emptyMap(), SmartCspSolver.Totals(4, 4, 0), SmartCspSolver.SearchStats(0, 0, 0)), 0L)

        val report = auditor.audit(result)

        assertTrue(report.violations.none { it.constraintName == "subject_weekly_spread" })
    }

    // ─── SOFT: Teacher Consecutive Overload ───────────────────────────

    @Test
    fun `detects teacher consecutive overload`() {
        val assignments = (1..5).map { period ->
            SmartCspSolver.Assignment("L$period", listOf("C$period"), listOf("T1"), "S$period", 1, period, "R1", false, false)
        }
        val constraints = SmartCspSolver.ConstraintConfig(
            teacherMaxConsecutivePeriods = mapOf("T1" to 3),
        )
        val result = SmartCspSolver.SolveResult("SEED_FOUND", assignments, emptyList(), emptyList(),
            SmartCspSolver.Diagnostics("test", emptyMap(), SmartCspSolver.Totals(5, 5, 0), SmartCspSolver.SearchStats(0, 0, 0)), 0L)

        val report = auditor.audit(result, constraints = constraints)

        assertTrue(report.violations.any { it.constraintName == "teacher_consecutive_overload" })
    }

    // ─── Integration: Auditor on Real Solver Output ───────────────────

    @Test
    fun `auditor validates clean solver output`() {
        val lessons = listOf(
            SmartCspSolver.Lesson("L1", "C1", "T1", "MATH"),
            SmartCspSolver.Lesson("L2", "C1", "T2", "SCI"),
            SmartCspSolver.Lesson("L3", "C2", "T1", "ENG"),
        )
        val result = solver.solve(lessons, rooms = emptyList(), days = 2, periodsPerDay = 3)
        val report = auditor.audit(result, days = 2, periodsPerDay = 3)

        // A clean solver output should have zero hard violations from the auditor
        assertEquals(0, report.hardViolations.size)
        assertTrue(report.score.isFeasible)
    }

    // ─── HardSoftScore Comparability ──────────────────────────────────

    @Test
    fun `HardSoftScore comparison prioritizes hard over soft`() {
        val feasible = ScheduleAuditor.HardSoftScore(hardScore = 0L, softScore = -500L)
        val infeasible = ScheduleAuditor.HardSoftScore(hardScore = -1_000_000_000L, softScore = 0L)

        assertTrue(feasible > infeasible)
        assertTrue(feasible.isFeasible)
        assertTrue(!infeasible.isFeasible)
    }
}
