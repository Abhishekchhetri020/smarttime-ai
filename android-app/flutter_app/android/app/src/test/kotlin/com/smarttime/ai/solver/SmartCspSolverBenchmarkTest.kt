package com.smarttime.ai.solver

import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class SmartCspSolverBenchmarkTest {
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
