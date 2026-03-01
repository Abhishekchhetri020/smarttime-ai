package com.smarttime.ai.solver

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SmartCspSolverTest {
    private val solver = SmartCspSolver()

    @Test
    fun `deterministic assignments for same input`() {
        val lessons = listOf(
            SmartCspSolver.Lesson("L1", "VII-A", "T1", "MATH"),
            SmartCspSolver.Lesson("L2", "VII-A", "T1", "SCI"),
            SmartCspSolver.Lesson("L3", "VII-B", "T2", "ENG"),
        )

        val constraints = SmartCspSolver.ConstraintConfig(
            teacherAvailability = mapOf(
                "T1" to setOf(
                    SmartCspSolver.SlotKey(1, 1),
                    SmartCspSolver.SlotKey(1, 2),
                    SmartCspSolver.SlotKey(2, 1),
                ),
            ),
            teacherMaxPeriodsPerDay = mapOf("T1" to 2),
            classMaxPeriodsPerDay = mapOf("VII-A" to 3),
        )

        val r1 = solver.solve(lessons, rooms = emptyList(), constraints = constraints, days = 2, periodsPerDay = 3)
        val r2 = solver.solve(lessons, rooms = emptyList(), constraints = constraints, days = 2, periodsPerDay = 3)

        assertEquals(r1.status, r2.status)
        assertEquals(r1.assignments, r2.assignments)
        assertEquals(r1.hardViolations, r2.hardViolations)
    }

    @Test
    fun `unscheduled conflict diagnostics present`() {
        val lessons = listOf(
            SmartCspSolver.Lesson("L1", "VII-A", "T1", "SCI"),
            SmartCspSolver.Lesson("L2", "VII-B", "T1", "SCI"),
        )

        val constraints = SmartCspSolver.ConstraintConfig(
            teacherMaxPeriodsPerDay = mapOf("T1" to 1),
        )

        val result = solver.solve(lessons, rooms = emptyList(), constraints = constraints, days = 1, periodsPerDay = 1)

        assertEquals("partial", result.status)
        assertTrue(result.hardViolations.isNotEmpty())
        assertEquals("unscheduled_lesson", result.hardViolations.first().type)
        assertTrue(result.hardViolations.first().reason.isNotBlank())
    }

    @Test
    fun `lab double scheduled in consecutive periods`() {
        val lessons = listOf(
            SmartCspSolver.Lesson("LAB1", "VII-A", "T2", "LAB", isLabDouble = true),
        )

        val result = solver.solve(lessons, rooms = emptyList(), days = 1, periodsPerDay = 2)

        assertEquals("success", result.status)
        assertEquals(2, result.assignments.size)
        val periods = result.assignments.map { it.period }.sorted()
        assertEquals(listOf(1, 2), periods)
    }

    @Test
    fun `required room type enforced`() {
        val lessons = listOf(
            SmartCspSolver.Lesson("LAB1", "VII-A", "T2", "LAB", requiredRoomType = "lab"),
        )
        val rooms = listOf(
            SmartCspSolver.Room("R1", "classroom"),
        )

        val result = solver.solve(lessons, rooms = rooms, days = 1, periodsPerDay = 2)

        assertEquals("partial", result.status)
        assertEquals("no_matching_room_type", result.hardViolations.first().reason)
    }

    @Test
    fun `subject daily limit as hard constraint`() {
        val lessons = listOf(
            SmartCspSolver.Lesson("L1", "VII-A", "T1", "MATH"),
            SmartCspSolver.Lesson("L2", "VII-A", "T2", "MATH"),
        )

        val constraints = SmartCspSolver.ConstraintConfig(
            subjectDailyLimit = mapOf("VII-A:MATH" to 1),
        )

        val result = solver.solve(lessons, rooms = emptyList(), constraints = constraints, days = 1, periodsPerDay = 3)

        assertEquals("partial", result.status)
        assertTrue(result.hardViolations.any { it.reason == "subject_daily_limit" })
    }

    @Test
    fun `progress callback receives updates`() {
        val lessons = (1..6).map {
            SmartCspSolver.Lesson("L$it", "VII-A", "T$it", "S$it")
        }

        val events = mutableListOf<SmartCspSolver.Progress>()

        solver.solve(
            lessons = lessons,
            rooms = emptyList(),
            days = 2,
            periodsPerDay = 4,
            progressCallback = SmartCspSolver.ProgressCallback { progress ->
                events += progress
            },
        )

        assertTrue(events.isNotEmpty())
        assertTrue(events.last().nodesVisited >= events.first().nodesVisited)
    }

    @Test
    fun `mrv and degree diagnostics populated`() {
        val lessons = listOf(
            SmartCspSolver.Lesson("L1", "A", "T1", "S1"),
            SmartCspSolver.Lesson("L2", "A", "T2", "S2"),
            SmartCspSolver.Lesson("L3", "B", "T1", "S3"),
            SmartCspSolver.Lesson("L4", "B", "T2", "S4"),
        )

        val result = solver.solve(lessons, rooms = emptyList(), days = 2, periodsPerDay = 2)

        assertTrue(result.diagnostics.search.nodesVisited > 0)
        assertTrue(result.diagnostics.search.backtracks >= 0)
        assertTrue(result.diagnostics.search.branchesPrunedByForwardCheck >= 0)
    }
}
