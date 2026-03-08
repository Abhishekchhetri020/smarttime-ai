package com.smarttime.ai

import com.smarttime.ai.solver.SmartCspSolver
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : io.flutter.embedding.android.FlutterActivity() {
    // Scope tied to Activity lifecycle; uses SupervisorJob so one failure
    // does not cancel other channel calls.
    private val solverScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.smarttime.ai/engine")
            .setMethodCallHandler { call, result ->
                if (call.method != "solve_timetable") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                val lessonsCount = (args["lessons"] as? List<*>)?.size ?: 0
                val teachersCount = (args["teachers"] as? List<*>)?.size ?: 0
                result.success("Engine received $lessonsCount lessons and $teachersCount teachers.")
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smarttime/offline_solver")
            .setMethodCallHandler { call, result ->
                if (call.method != "solveTimetable") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                // Parse arguments on the main thread (fast) so that any
                // casting errors are caught synchronously.
                val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                val solver = SmartCspSolver()

                val days = (args["days"] as? Number)?.toInt() ?: 5
                val periodsPerDay = (args["periodsPerDay"] as? Number)?.toInt() ?: 8

                val timeoutMs = (args["timeoutMs"] as? Number)?.toLong() ?: 15_000L

                val lessons = parseLessons(args["lessons"] as? List<*>)
                val rooms = parseRooms(args["rooms"] as? List<*>)
                val constraints = parseConstraints(args["constraints"] as? Map<*, *>)

                // Launch coroutine so the UI thread is NOT blocked while
                // the solver runs on Dispatchers.Default.
                solverScope.launch {
                    try {
                    val solveResult = withContext(Dispatchers.Default) {
                        solver.solve(
                            lessons = lessons,
                            rooms = rooms,
                            constraints = constraints,
                            days = days,
                            periodsPerDay = periodsPerDay,
                            timeoutMs = timeoutMs,
                        )
                    }

                    result.success(
                        mapOf(
                            "status" to solveResult.status,
                            "assignments" to solveResult.assignments.map {
                                mapOf(
                                    "lessonId" to it.lessonId,
                                    "classIds" to it.classIds,
                                    "teacherIds" to it.teacherIds,
                                    "classId" to it.classId,
                                    "teacherId" to it.teacherId,
                                    "subjectId" to it.subjectId,
                                    "day" to it.day,
                                    "period" to it.period,
                                    "roomId" to it.roomId,
                                    "pinned" to it.pinned,
                                    "isLabDouble" to it.isLabDouble,
                                )
                            },
                            "hardViolations" to solveResult.hardViolations.map {
                                mapOf(
                                    "type" to it.type,
                                    "lessonId" to it.lessonId,
                                    "classId" to it.classId,
                                    "teacherId" to it.teacherId,
                                    "subjectId" to it.subjectId,
                                    "reason" to it.reason,
                                    "attemptedSlots" to it.attemptedSlots,
                                )
                            },
                            "diagnostics" to mapOf(
                                "solverVersion" to solveResult.diagnostics.solverVersion,
                                "unscheduledReasonCounts" to solveResult.diagnostics.unscheduledReasonCounts,
                                "totals" to mapOf(
                                    "lessonsRequested" to solveResult.diagnostics.totals.lessonsRequested,
                                    "assignedEntries" to solveResult.diagnostics.totals.assignedEntries,
                                    "hardViolations" to solveResult.diagnostics.totals.hardViolations,
                                ),
                                "search" to mapOf(
                                    "nodesVisited" to solveResult.diagnostics.search.nodesVisited,
                                    "backtracks" to solveResult.diagnostics.search.backtracks,
                                    "branchesPrunedByForwardCheck" to solveResult.diagnostics.search.branchesPrunedByForwardCheck,
                                ),
                            ),
                            "score" to solveResult.score,
                        ),
                    )
                    } catch (e: Exception) {
                        result.error("offline_solver_error", e.message, null)
                    }
                }
            }
    }

    private fun parseLessons(raw: List<*>?): List<SmartCspSolver.Lesson> {
        return raw.orEmpty().mapNotNull { item ->
            val map = item as? Map<*, *> ?: return@mapNotNull null
            val id = map["id"]?.toString() ?: return@mapNotNull null
            val subjectId = map["subjectId"]?.toString() ?: return@mapNotNull null

            val classIds = parseStringList(map["classIds"]).ifEmpty {
                listOfNotNull(map["classId"]?.toString())
            }
            val teacherIds = parseStringList(map["teacherIds"]).ifEmpty {
                listOfNotNull(map["teacherId"]?.toString())
            }
            if (classIds.isEmpty() || teacherIds.isEmpty()) return@mapNotNull null

            SmartCspSolver.Lesson(
                id = id,
                classIds = classIds,
                teacherIds = teacherIds,
                subjectId = subjectId,
                preferredRoomId = map["preferredRoomId"]?.toString(),
                requiredRoomType = map["requiredRoomType"]?.toString(),
                fixedDay = (map["fixedDay"] as? Number)?.toInt(),
                fixedPeriod = (map["fixedPeriod"] as? Number)?.toInt(),
                isLabDouble = map["isLabDouble"] as? Boolean ?: false,
            )
        }
    }

    private fun parseRooms(raw: List<*>?): List<SmartCspSolver.Room> {
        return raw.orEmpty().mapNotNull { item ->
            val map = item as? Map<*, *> ?: return@mapNotNull null
            val id = map["id"]?.toString() ?: return@mapNotNull null
            SmartCspSolver.Room(
                id = id,
                roomType = map["roomType"]?.toString(),
            )
        }
    }

    private fun parseConstraints(raw: Map<*, *>?): SmartCspSolver.ConstraintConfig {
        if (raw == null) return SmartCspSolver.ConstraintConfig()

        val teacherMaxPeriodsPerDay = intMap(raw["teacherMaxPeriodsPerDay"] as? Map<*, *>)
        val classMaxPeriodsPerDay = intMap(raw["classMaxPeriodsPerDay"] as? Map<*, *>)
        val subjectDailyLimit = intMap(raw["subjectDailyLimit"] as? Map<*, *>)
        val teacherMaxConsecutivePeriods = intMap(raw["teacherMaxConsecutivePeriods"] as? Map<*, *>)
        val classMaxConsecutivePeriods = intMap(raw["classMaxConsecutivePeriods"] as? Map<*, *>)
        val teacherNoLastPeriodMaxPerWeek = intMap(raw["teacherNoLastPeriodMaxPerWeek"] as? Map<*, *>)
        val softWeights = intMap(raw["softWeights"] as? Map<*, *>)

        return SmartCspSolver.ConstraintConfig(
            teacherMaxPeriodsPerDay = teacherMaxPeriodsPerDay,
            classMaxPeriodsPerDay = classMaxPeriodsPerDay,
            subjectDailyLimit = subjectDailyLimit,
            teacherMaxConsecutivePeriods = teacherMaxConsecutivePeriods,
            classMaxConsecutivePeriods = classMaxConsecutivePeriods,
            teacherNoLastPeriodMaxPerWeek = teacherNoLastPeriodMaxPerWeek,
            softWeights = if (softWeights.isEmpty()) SmartCspSolver.ConstraintConfig.defaultSoftWeights else softWeights,
        )
    }

    private fun intMap(raw: Map<*, *>?): Map<String, Int> {
        return raw.orEmpty().entries.associateNotNull { (k, v) ->
            val key = k?.toString() ?: return@associateNotNull null
            val value = (v as? Number)?.toInt() ?: return@associateNotNull null
            key to value
        }
    }

    private fun parseStringList(raw: Any?): List<String> {
        return (raw as? List<*>)
            ?.mapNotNull { it?.toString() }
            ?.filter { it.isNotBlank() }
            ?: emptyList()
    }
}

private inline fun <T, K, V> Iterable<T>.associateNotNull(transform: (T) -> Pair<K, V>?): Map<K, V> {
    val result = LinkedHashMap<K, V>()
    for (element in this) {
        val pair = transform(element) ?: continue
        result[pair.first] = pair.second
    }
    return result
}
