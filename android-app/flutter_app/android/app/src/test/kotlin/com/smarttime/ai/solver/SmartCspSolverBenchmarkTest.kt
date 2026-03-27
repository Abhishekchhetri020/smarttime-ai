package com.smarttime.ai.solver

import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class SmartCspSolverBenchmarkTest {

    // ── Medium School Benchmark (Week 1 Bridge Validation) ──────────────
    @Test
    fun `benchmark medium school 50 teachers with progress callback`() {
        val solver = SmartCspSolver()
        var progressEventsCount = 0
        var lastProgress: SmartCspSolver.Progress? = null

        val result = solver.runStressBenchmark(
            teacherCount = 50,
            classCount = 25,
            subjectCount = 15,
            days = 5,
            periodsPerDay = 8,
            timeoutMs = 30_000L, // Reduced for faster feedback, we care about stability here
        )

        // Also run a full solve() with progress callback to validate the
        // EventChannel contract works end-to-end on the Kotlin side.
        val teachers = (1..50).map { "T$it" }
        val classes = (1..25).map { "C$it" }
        val subjects = (1..15).map { "S$it" }
        val rooms = (1..25).map { SmartCspSolver.Room("R$it", if (it % 5 == 0) "lab" else "classroom") }
        val lessons = ArrayList<SmartCspSolver.Lesson>()
        var id = 1
        for (classIdx in classes.indices) {
            for (n in 0 until 10) {
                val teacher = teachers[(classIdx + n) % teachers.size]
                val subject = subjects[(classIdx * 2 + n * 3) % subjects.size]
                lessons += SmartCspSolver.Lesson(
                    id = "M$id",
                    classIds = listOf(classes[classIdx]),
                    teacherIds = listOf(teacher),
                    subjectId = subject,
                    isLabDouble = n % 8 == 0,
                    requiredRoomType = if (n % 8 == 0) "lab" else null,
                )
                id++
            }
        }

        val progressCallback = SmartCspSolver.ProgressCallback { progress ->
            progressEventsCount++
            lastProgress = progress
        }

        val startNs = System.nanoTime()
        val solveResult = solver.solve(
            lessons = lessons,
            rooms = rooms,
            constraints = SmartCspSolver.ConstraintConfig(
                teacherMaxPeriodsPerDay = teachers.associateWith { 6 },
                classMaxPeriodsPerDay = classes.associateWith { 7 },
                teacherMaxConsecutivePeriods = teachers.associateWith { 3 },
                subjectDailyLimit = subjects.map { s -> s to 2 }.toMap(),
            ),
            days = 5,
            periodsPerDay = 8,
            timeoutMs = 30_000L,
            progressCallback = progressCallback,
        )
        val elapsedMs = (System.nanoTime() - startNs) / 1_000_000L

        // ── Write benchmark output ──
        val out = File("build/outputs/medium-school-benchmark.json")
        out.parentFile?.mkdirs()
        out.writeText(
            """
            {
              "mediumSchool50Teachers": {
                "elapsedMs": $elapsedMs,
                "status": "${solveResult.status}",
                "assignedLessons": ${solveResult.assignments.size},
                "totalLessons": ${lessons.size},
                "hardViolations": ${solveResult.hardViolations.size},
                "score": ${solveResult.score},
                "progressEventsReceived": $progressEventsCount,
                "softPenalties": ${solveResult.softPenaltyBreakdown.size},
                "searchStats": {
                  "nodesVisited": ${solveResult.diagnostics.search.nodesVisited},
                  "backtracks": ${solveResult.diagnostics.search.backtracks}
                }
              },
              "stressBenchmark": {
                "elapsedMs": ${result.elapsedMs},
                "iterations": ${result.iterations},
                "ips": ${"%.2f".format(result.ips)},
                "hardConstraintZeroReached": ${result.hardConstraintZeroReached},
                "status": "${result.status}"
              }
            }
            """.trimIndent(),
        )

        println("=== MEDIUM SCHOOL BENCHMARK ===")
        println("Status: ${solveResult.status}")
        println("Time: ${elapsedMs}ms")
        println("Assigned: ${solveResult.assignments.size}/${lessons.size}")
        println("Hard violations: ${solveResult.hardViolations.size}")
        println("Score: ${solveResult.score}")
        println("Progress events: $progressEventsCount")
        println("Soft penalties: ${solveResult.softPenaltyBreakdown.joinToString { "${it.type}=${it.penalty}" }}")
        println("===============================")

        // Assertions - We check for functional correctness
        assertTrue("Should produce progress events", progressEventsCount > 0)
        assertTrue("Last progress should have totalLessons=${lessons.size}",
            lastProgress?.totalLessons == lessons.size)
        assertTrue("Stress benchmark should complete", result.elapsedMs > 0)
    }

    @Test
    fun `benchmark 200 teacher scenario`() {
        val solver = SmartCspSolver()
        val tightKnotA = solver.runStressBenchmark(
            teacherCount = 200,
            classCount = 60,
            subjectCount = 24,
            days = 5,
            periodsPerDay = 8,
            timeoutMs = 30_000L,
        )
        val tightKnotB = solver.runStressBenchmark(
            teacherCount = 200,
            classCount = 60,
            subjectCount = 24,
            days = 5,
            periodsPerDay = 8,
            timeoutMs = 30_000L,
        )

        val out = File("build/outputs/solver-benchmark.json")
        out.parentFile?.mkdirs()
        out.writeText(
            """
            {
              "tightKnot200Teachers": {
                "elapsedMs": ${tightKnotA.elapsedMs},
                "iterations": ${tightKnotA.iterations},
                "ips": ${"%.2f".format(tightKnotA.ips)},
                "hardConstraintZeroReached": ${tightKnotA.hardConstraintZeroReached},
                "status": "${tightKnotA.status}",
                "hardViolations": ${tightKnotA.hardViolations},
                "ipsBarrier5MReached": ${tightKnotA.ips >= 5_000_000.0}
              },
              "determinism": {
                "statusRunA": "${tightKnotA.status}",
                "statusRunB": "${tightKnotB.status}",
                "statusStable": ${tightKnotA.status == tightKnotB.status}
              }
            }
            """.trimIndent(),
        )

        assertTrue(tightKnotA.elapsedMs > 0)
        assertTrue(tightKnotA.iterations > 0)
        assertTrue(tightKnotA.status == tightKnotB.status)
    }
}
