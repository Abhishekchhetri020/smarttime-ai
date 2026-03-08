package com.smarttime.ai.solver

import java.io.File
import kotlin.random.Random
import org.junit.Test

class SolverSwarmFuzzer {

    private val rng = Random(42)

    @Test
    fun fuzzBatch() {
        val solver = SmartCspSolver()
        repeat(500) { seed ->
            val data = generateMutated(seed)
            try {
                val start = System.nanoTime()
                val result = solver.solve(
                    lessons = data.lessons,
                    rooms = data.rooms,
                    constraints = data.constraints,
                    days = data.days,
                    periodsPerDay = data.periodsPerDay,
                    timeoutMs = 30_000L,
                )
                val elapsedMs = (System.nanoTime() - start) / 1_000_000
                if (elapsedMs > 30_000 || result.status.isBlank()) {
                    dumpAnomaly(seed, data, "timeout_or_invalid_status", elapsedMs)
                }
            } catch (t: Throwable) {
                dumpAnomaly(seed, data, "exception:${t::class.simpleName}:${t.message}", -1)
            }
        }
    }

    private fun dumpAnomaly(seed: Int, data: FuzzData, reason: String, elapsedMs: Long) {
        val root = File(System.getProperty("user.dir"))
        val out = File(root, "swarm_anomalies.log")
        out.appendText(
            "seed=$seed reason=$reason elapsedMs=$elapsedMs payload=${data.toCompactString()}\n"
        )
    }

    private data class FuzzData(
        val lessons: List<SmartCspSolver.Lesson>,
        val rooms: List<SmartCspSolver.Room>,
        val constraints: SmartCspSolver.ConstraintConfig,
        val days: Int,
        val periodsPerDay: Int,
    ) {
        fun toCompactString(): String {
            return "{days:$days,periods:$periodsPerDay,lessons:${lessons.size},rooms:${rooms.size}}"
        }
    }

    private fun generateMutated(seed: Int): FuzzData {
        val teachers = rng.nextInt(50, 251)
        val classes = rng.nextInt(20, 121)
        val subjects = rng.nextInt(10, 81)
        val days = 5
        val periods = 8

        val rooms = List(rng.nextInt(20, 120)) { i -> SmartCspSolver.Room("R$i") }

        val lessons = buildList {
            repeat(rng.nextInt(200, 1200)) { i ->
                val classA = rng.nextInt(classes)
                val classB = rng.nextInt(classes)
                val teacherA = rng.nextInt(teachers)
                val teacherB = rng.nextInt(teachers)
                add(
                    SmartCspSolver.Lesson(
                        id = "L$i",
                        classIds = listOf("C$classA", "C$classB"),
                        teacherIds = listOf("T$teacherA", "T$teacherB"),
                        subjectId = "S${rng.nextInt(subjects)}",
                        fixedDay = if (rng.nextInt(100) < 15) rng.nextInt(1, days + 1) else null,
                        fixedPeriod = if (rng.nextInt(100) < 15) rng.nextInt(1, periods + 1) else null,
                        isLabDouble = rng.nextBoolean(),
                    )
                )
            }
        }

        val teacherAvailability = mutableMapOf<String, Set<SmartCspSolver.SlotKey>>()
        repeat(teachers) { t ->
            val blockedHeavy = t < 10 // tight-knot overlap on first 10 teachers
            val allowed = mutableSetOf<SmartCspSolver.SlotKey>()
            for (d in 1..days) {
                for (p in 1..periods) {
                    val allow = if (blockedHeavy) rng.nextInt(100) < 10 else rng.nextInt(100) < 70
                    if (allow) allowed.add(SmartCspSolver.SlotKey(d, p))
                }
            }
            teacherAvailability["T$t"] = allowed
        }

        val constraints = SmartCspSolver.ConstraintConfig(
            teacherAvailability = teacherAvailability,
        )

        return FuzzData(
            lessons = lessons,
            rooms = rooms,
            constraints = constraints,
            days = days,
            periodsPerDay = periods,
        )
    }
}
