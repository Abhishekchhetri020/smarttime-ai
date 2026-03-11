package com.smarttime.ai.solver

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.runBlocking
import kotlin.math.max

/**
 * Deterministic offline CSP solver for school timetables.
 *
 * Internals are optimized for scale:
 *  - Occupancy uses LongArray bitmasks with bitwise checks
 *  - Lesson and candidate metadata are stored in flat IntArray layouts
 *  - Root search executes 4 deterministic shuffled branches in parallel
 *  - Soft scoring is maintained incrementally (delta updates on touched entities)
 */
class SmartCspSolver {
    enum class ConstraintWeight(val penalty: Int) {
        HARD(Int.MAX_VALUE),
        NEAR_HARD(50),
        HIGH_SOFT(25),
        MED_SOFT(20),
        LOW_SOFT(10),
        HINT(5),
    }

    interface SchedulableResource {
        val id: String
        val availabilityMask: Long
    }

    data class SchoolClass(
        override val id: String,
        override val availabilityMask: Long = Long.MAX_VALUE,
    ) : SchedulableResource

    data class SlotRecord(
        val lessonIdx: Int = Int.MAX_VALUE,
        val roomIdx: Int = Int.MAX_VALUE,
        val classIdx: Int = Int.MAX_VALUE,
        val teacherIdx: Int = Int.MAX_VALUE,
        val lockFlags: Byte = 0,
    ) {
        companion object {
            const val LOCK_TIME: Byte = 0x01
            const val LOCK_CLASS: Byte = 0x02
            const val LOCK_ROOM: Byte = 0x04
        }
    }

    data class Lesson(
        val id: String,
        val classIds: List<String>,
        val teacherIds: List<String>,
        val subjectId: String,
        val preferredRoomId: String? = null,
        val requiredRoomType: String? = null,
        val fixedDay: Int? = null,
        val fixedPeriod: Int? = null,
        val isLabDouble: Boolean = false,
    ) {
        constructor(
            id: String,
            classId: String,
            teacherId: String,
            subjectId: String,
            preferredRoomId: String? = null,
            requiredRoomType: String? = null,
            fixedDay: Int? = null,
            fixedPeriod: Int? = null,
            isLabDouble: Boolean = false,
        ) : this(
            id = id,
            classIds = listOf(classId),
            teacherIds = listOf(teacherId),
            subjectId = subjectId,
            preferredRoomId = preferredRoomId,
            requiredRoomType = requiredRoomType,
            fixedDay = fixedDay,
            fixedPeriod = fixedPeriod,
            isLabDouble = isLabDouble,
        )

        val primaryClassId: String get() = classIds.firstOrNull() ?: ""
        val primaryTeacherId: String get() = teacherIds.firstOrNull() ?: ""
    }

    data class Room(
        override val id: String,
        val roomType: String? = null,
        override val availabilityMask: Long = Long.MAX_VALUE,
    ) : SchedulableResource

    data class ConstraintConfig(
        val teacherAvailability: Map<String, Set<SlotKey>> = emptyMap(),
        val teacherMaxPeriodsPerDay: Map<String, Int> = emptyMap(),
        val classMaxPeriodsPerDay: Map<String, Int> = emptyMap(),
        val fixedPeriods: Map<String, SlotKey> = emptyMap(),
        val subjectDailyLimit: Map<String, Int> = emptyMap(),
        val teacherMaxConsecutivePeriods: Map<String, Int> = emptyMap(),
        val classMaxConsecutivePeriods: Map<String, Int> = emptyMap(),
        val teacherNoLastPeriodMaxPerWeek: Map<String, Int> = emptyMap(),
        val softWeights: Map<String, Int> = defaultSoftWeights,
    ) {
        companion object {
            val defaultSoftWeights: Map<String, Int> = mapOf(
                "teacher_gaps" to ConstraintWeight.LOW_SOFT.penalty,
                "class_gaps" to ConstraintWeight.LOW_SOFT.penalty,
                "subject_distribution" to ConstraintWeight.MED_SOFT.penalty,
                "teacher_room_stability" to ConstraintWeight.HINT.penalty,
                "teacher_consecutive_overload" to ConstraintWeight.NEAR_HARD.penalty,
                "class_consecutive_overload" to ConstraintWeight.NEAR_HARD.penalty,
                "teacher_last_period_overflow" to ConstraintWeight.HIGH_SOFT.penalty,
                "period_load_balance" to ConstraintWeight.MED_SOFT.penalty,
            )
        }
    }

    data class Slot(val day: Int, val period: Int)
    data class SlotKey(val day: Int, val period: Int)

    data class Assignment(
        val lessonId: String,
        val classIds: List<String>,
        val teacherIds: List<String>,
        val subjectId: String,
        val day: Int,
        val period: Int,
        val roomId: String,
        val pinned: Boolean,
        val isLabDouble: Boolean,
    ) {
        val classId: String get() = classIds.firstOrNull() ?: ""
        val teacherId: String get() = teacherIds.firstOrNull() ?: ""
    }

    data class HardViolation(
        val type: String = "unscheduled_lesson",
        val lessonId: String,
        val classId: String,
        val teacherId: String,
        val subjectId: String,
        val reason: String,
        val attemptedSlots: Int,
    )

    data class SoftPenalty(val type: String, val penalty: Int, val weight: Int)

    data class Diagnostics(
        val solverVersion: String,
        val unscheduledReasonCounts: Map<String, Int>,
        val totals: Totals,
        val search: SearchStats,
    )

    data class Totals(
        val lessonsRequested: Int,
        val assignedEntries: Int,
        val hardViolations: Int,
    )

    data class SearchStats(
        val nodesVisited: Int,
        val backtracks: Int,
        val branchesPrunedByForwardCheck: Int,
    )

    data class SolveResult(
        val status: String,
        val assignments: List<Assignment>,
        val hardViolations: List<HardViolation>,
        val softPenaltyBreakdown: List<SoftPenalty>,
        val diagnostics: Diagnostics,
        val score: Long,
    )

    data class Progress(
        val nodesVisited: Int,
        val assignedLessons: Int,
        val totalLessons: Int,
        val backtracks: Int,
    )

    fun interface ProgressCallback {
        fun onProgress(progress: Progress)
    }

    data class BenchmarkResult(
        val elapsedMs: Long,
        val iterations: Int,
        val ips: Double,
        val hardConstraintZeroReached: Boolean,
    )

    data class StressBenchmarkResult(
        val elapsedMs: Long,
        val iterations: Int,
        val ips: Double,
        val hardConstraintZeroReached: Boolean,
        val status: String,
        val hardViolations: Int,
    )

    private data class SolverModel(
        val lessons: List<Lesson>,
        val rooms: List<Room>,
        val constraints: ConstraintConfig,
        val days: Int,
        val periodsPerDay: Int,
        val lessonCount: Int,
        val teacherCount: Int,
        val classCount: Int,
        val roomCount: Int,
        val subjectCount: Int,
        val teacherIds: List<String>,
        val classIds: List<String>,
        val roomIds: List<String>,
        val subjectIds: List<String>,
        val lessonClassStart: IntArray,
        val lessonClassCount: IntArray,
        val lessonTeacherStart: IntArray,
        val lessonTeacherCount: IntArray,
        val lessonClassFlat: IntArray,
        val lessonTeacherFlat: IntArray,
        val lessonSubject: IntArray,
        val lessonLabDouble: IntArray,
        val lessonAttemptSlots: IntArray,
        val lessonPinned: BooleanArray,
        val fixedSlot: IntArray,
        val lessonCandidateStart: IntArray,
        val lessonCandidateCount: IntArray,
        val candidateSlot: IntArray,
        val candidateRoom: IntArray,
        val teacherAvailabilityMask: LongArray,
        val classAvailabilityMask: LongArray,
        val roomAvailabilityMask: LongArray,
        val teacherMaxPeriodsPerDay: IntArray,
        val classMaxPeriodsPerDay: IntArray,
        val subjectDailyLimit: IntArray,
        val teacherMaxConsecutive: IntArray,
        val classMaxConsecutive: IntArray,
        val teacherNoLastPeriodCap: IntArray,
        val lessonAdjacencyDegree: IntArray,
        val slotDay: IntArray,
        val slotPeriod: IntArray,
        val periodPreferenceScores: IntArray,
        val weights: IntArray,
        val lessonIdToIndex: Map<String, Int>,
        val occStride: Int,
        val maxCandidatesPerLesson: Int,
    )

    private data class SearchStatsMutable(
        var nodesVisited: Int = 0,
        var backtracks: Int = 0,
        var branchesPrunedByForwardCheck: Int = 0,
        var timedOut: Boolean = false,
    ) {
        fun merge(other: SearchStatsMutable) {
            nodesVisited += other.nodesVisited
            backtracks += other.backtracks
            branchesPrunedByForwardCheck += other.branchesPrunedByForwardCheck
            timedOut = timedOut || other.timedOut
        }
    }

    private data class BranchResult(
        val state: MutableState,
        val hardViolations: List<HardViolation>,
        val unscheduledReasons: Map<String, Int>,
        val stats: SearchStatsMutable,
    )

    private data class MutableState(
        val teacherOcc: LongArray,
        val classOcc: LongArray,
        val roomOcc: LongArray,
        val teacherSlotLesson: IntArray,
        val classSlotLesson: IntArray,
        val roomSlotLesson: IntArray,
        val teacherDayLoad: IntArray,
        val classDayLoad: IntArray,
        val classSubjectDayCount: IntArray,
        val teacherLastPeriodCount: IntArray,
        val teacherRoomUsage: IntArray,
        val teacherDistinctRooms: IntArray,
        val lessonAssignedDepth: IntArray,
        val conflictCauseDepth: IntArray,
        val failureReasonScratch: IntArray,
        val lessonAssignedSlot: IntArray,
        val lessonAssignedRoom: IntArray,
        val lessonAssignedPinned: BooleanArray,
        val lessonAssigned: BooleanArray,
        val candidateScratch: IntArray,
        val sparseSlotState: HashMap<Long, SlotRecord>,
        val slotLoad: IntArray,
        val bestLessonAssignedSlot: IntArray,
        val bestLessonAssignedRoom: IntArray,
        val bestLessonAssignedPinned: BooleanArray,
        val bestLessonAssigned: BooleanArray,
        var assignedLessonCount: Int,
        val scorer: IncrementalScorer,
        var bestScore: Long = Long.MIN_VALUE,
        var bestHardCount: Int = Int.MAX_VALUE,
        var bestAssignedEntries: Int = 0,
        var bestHardViolations: List<HardViolation> = emptyList(),
        var bestUnscheduledReasons: Map<String, Int> = emptyMap(),
    ) {
        fun copyDeep(model: SolverModel): MutableState {
            return MutableState(
                teacherOcc = teacherOcc.copyOf(),
                classOcc = classOcc.copyOf(),
                roomOcc = roomOcc.copyOf(),
                teacherSlotLesson = teacherSlotLesson.copyOf(),
                classSlotLesson = classSlotLesson.copyOf(),
                roomSlotLesson = roomSlotLesson.copyOf(),
                teacherDayLoad = teacherDayLoad.copyOf(),
                classDayLoad = classDayLoad.copyOf(),
                classSubjectDayCount = classSubjectDayCount.copyOf(),
                teacherLastPeriodCount = teacherLastPeriodCount.copyOf(),
                teacherRoomUsage = teacherRoomUsage.copyOf(),
                teacherDistinctRooms = teacherDistinctRooms.copyOf(),
                lessonAssignedDepth = lessonAssignedDepth.copyOf(),
                conflictCauseDepth = conflictCauseDepth.copyOf(),
                failureReasonScratch = failureReasonScratch.copyOf(),
                lessonAssignedSlot = lessonAssignedSlot.copyOf(),
                lessonAssignedRoom = lessonAssignedRoom.copyOf(),
                lessonAssignedPinned = lessonAssignedPinned.copyOf(),
                lessonAssigned = lessonAssigned.copyOf(),
                candidateScratch = candidateScratch.copyOf(),
                sparseSlotState = HashMap(sparseSlotState),
                slotLoad = slotLoad.copyOf(),
                bestLessonAssignedSlot = bestLessonAssignedSlot.copyOf(),
                bestLessonAssignedRoom = bestLessonAssignedRoom.copyOf(),
                bestLessonAssignedPinned = bestLessonAssignedPinned.copyOf(),
                bestLessonAssigned = bestLessonAssigned.copyOf(),
                assignedLessonCount = assignedLessonCount,
                scorer = scorer.copyDeep(model),
                bestScore = bestScore,
                bestHardCount = bestHardCount,
                bestAssignedEntries = bestAssignedEntries,
                bestHardViolations = bestHardViolations.toList(),
                bestUnscheduledReasons = bestUnscheduledReasons.toMap(),
            )
        }
    }

    private class IncrementalScorer private constructor(
        private val model: SolverModel,
        private val teacherDayGap: IntArray,
        private val classDayGap: IntArray,
        private val teacherDayOverload: IntArray,
        private val classDayOverload: IntArray,
        private val subjectDayOverflow: IntArray,
        private val teacherRoomPenalty: IntArray,
        private val teacherLastOverflow: IntArray,
        var totalTeacherGap: Int,
        var totalClassGap: Int,
        var totalSubjectDistribution: Int,
        var totalTeacherRoomStability: Int,
        var totalTeacherConsecutiveOverload: Int,
        var totalClassConsecutiveOverload: Int,
        var totalTeacherLastPeriodOverflow: Int,
        var totalPeriodLoadBalance: Int,
    ) {
        companion object {
            fun initial(model: SolverModel): IncrementalScorer {
                return IncrementalScorer(
                    model = model,
                    teacherDayGap = IntArray(model.teacherCount * model.days),
                    classDayGap = IntArray(model.classCount * model.days),
                    teacherDayOverload = IntArray(model.teacherCount * model.days),
                    classDayOverload = IntArray(model.classCount * model.days),
                    subjectDayOverflow = IntArray(model.classCount * model.subjectCount * model.days),
                    teacherRoomPenalty = IntArray(model.teacherCount),
                    teacherLastOverflow = IntArray(model.teacherCount),
                    totalTeacherGap = 0,
                    totalClassGap = 0,
                    totalSubjectDistribution = 0,
                    totalTeacherRoomStability = 0,
                    totalTeacherConsecutiveOverload = 0,
                    totalClassConsecutiveOverload = 0,
                    totalTeacherLastPeriodOverflow = 0,
                    totalPeriodLoadBalance = 0,
                )
            }
        }

        fun copyDeep(model: SolverModel): IncrementalScorer {
            return IncrementalScorer(
                model = model,
                teacherDayGap = teacherDayGap.copyOf(),
                classDayGap = classDayGap.copyOf(),
                teacherDayOverload = teacherDayOverload.copyOf(),
                classDayOverload = classDayOverload.copyOf(),
                subjectDayOverflow = subjectDayOverflow.copyOf(),
                teacherRoomPenalty = teacherRoomPenalty.copyOf(),
                teacherLastOverflow = teacherLastOverflow.copyOf(),
                totalTeacherGap = totalTeacherGap,
                totalClassGap = totalClassGap,
                totalSubjectDistribution = totalSubjectDistribution,
                totalTeacherRoomStability = totalTeacherRoomStability,
                totalTeacherConsecutiveOverload = totalTeacherConsecutiveOverload,
                totalClassConsecutiveOverload = totalClassConsecutiveOverload,
                totalTeacherLastPeriodOverflow = totalTeacherLastPeriodOverflow,
                totalPeriodLoadBalance = totalPeriodLoadBalance,
            )
        }

        fun refreshTeacherDay(state: MutableState, teacher: Int, dayIdx: Int) {
            val key = td(teacher, dayIdx)
            totalTeacherGap -= teacherDayGap[key]
            totalTeacherConsecutiveOverload -= teacherDayOverload[key]
            val mask = state.teacherOcc[occ(teacher, dayIdx)]
            teacherDayGap[key] = gapPenalty(mask)
            teacherDayOverload[key] = overloadPenalty(mask, model.teacherMaxConsecutive[teacher])
            totalTeacherGap += teacherDayGap[key]
            totalTeacherConsecutiveOverload += teacherDayOverload[key]
        }

        fun refreshClassDay(state: MutableState, classId: Int, dayIdx: Int) {
            val key = cd(classId, dayIdx)
            totalClassGap -= classDayGap[key]
            totalClassConsecutiveOverload -= classDayOverload[key]
            val mask = state.classOcc[occ(classId, dayIdx)]
            classDayGap[key] = gapPenalty(mask)
            classDayOverload[key] = overloadPenalty(mask, model.classMaxConsecutive[classId])
            totalClassGap += classDayGap[key]
            totalClassConsecutiveOverload += classDayOverload[key]
        }

        fun refreshSubjectCell(state: MutableState, classId: Int, subjectId: Int, dayIdx: Int) {
            val key = csd(classId, subjectId, dayIdx)
            totalSubjectDistribution -= subjectDayOverflow[key]
            val count = state.classSubjectDayCount[key]
            subjectDayOverflow[key] = max(0, count - 2)
            totalSubjectDistribution += subjectDayOverflow[key]
        }

        fun refreshTeacherRoom(state: MutableState, teacher: Int) {
            totalTeacherRoomStability -= teacherRoomPenalty[teacher]
            teacherRoomPenalty[teacher] = max(0, state.teacherDistinctRooms[teacher] - 1)
            totalTeacherRoomStability += teacherRoomPenalty[teacher]
        }

        fun refreshTeacherLast(state: MutableState, teacher: Int) {
            totalTeacherLastPeriodOverflow -= teacherLastOverflow[teacher]
            val cap = model.teacherNoLastPeriodCap[teacher]
            teacherLastOverflow[teacher] = if (cap >= 0) max(0, state.teacherLastPeriodCount[teacher] - cap) else 0
            totalTeacherLastPeriodOverflow += teacherLastOverflow[teacher]
        }

        fun refreshPeriodLoad(state: MutableState) {
            var total = 0
            for (slot in state.slotLoad.indices) {
                val pref = model.periodPreferenceScores[slot % model.periodPreferenceScores.size]
                total += state.slotLoad[slot] * pref
            }
            totalPeriodLoadBalance = total
        }

        fun scoreWithHard(hardViolations: Int): Long {
            var softWeighted = 0L
            softWeighted += totalTeacherGap.toLong() * model.weights[W_TEACHER_GAPS]
            softWeighted += totalClassGap.toLong() * model.weights[W_CLASS_GAPS]
            softWeighted += totalSubjectDistribution.toLong() * model.weights[W_SUBJECT_DISTRIBUTION]
            softWeighted += totalTeacherRoomStability.toLong() * model.weights[W_TEACHER_ROOM]
            softWeighted += totalTeacherConsecutiveOverload.toLong() * model.weights[W_TEACHER_CONSEC]
            softWeighted += totalClassConsecutiveOverload.toLong() * model.weights[W_CLASS_CONSEC]
            softWeighted += totalTeacherLastPeriodOverflow.toLong() * model.weights[W_TEACHER_LAST]
            softWeighted += totalPeriodLoadBalance.toLong() * model.weights[W_PERIOD_LOAD]
            return -1_000_000_000L * hardViolations - softWeighted
        }

        fun toBreakdown(): List<SoftPenalty> {
            return listOf(
                SoftPenalty("teacher_gaps", totalTeacherGap, model.weights[W_TEACHER_GAPS]),
                SoftPenalty("class_gaps", totalClassGap, model.weights[W_CLASS_GAPS]),
                SoftPenalty("subject_distribution", totalSubjectDistribution, model.weights[W_SUBJECT_DISTRIBUTION]),
                SoftPenalty("teacher_room_stability", totalTeacherRoomStability, model.weights[W_TEACHER_ROOM]),
                SoftPenalty("teacher_consecutive_overload", totalTeacherConsecutiveOverload, model.weights[W_TEACHER_CONSEC]),
                SoftPenalty("class_consecutive_overload", totalClassConsecutiveOverload, model.weights[W_CLASS_CONSEC]),
                SoftPenalty("teacher_last_period_overflow", totalTeacherLastPeriodOverflow, model.weights[W_TEACHER_LAST]),
                SoftPenalty("period_load_balance", totalPeriodLoadBalance, model.weights[W_PERIOD_LOAD]),
            )
        }

        private fun td(teacher: Int, dayIdx: Int) = teacher * model.days + dayIdx
        private fun cd(classId: Int, dayIdx: Int) = classId * model.days + dayIdx
        private fun occ(entity: Int, dayIdx: Int) = entity * model.occStride + dayIdx
        private fun csd(classId: Int, subjectId: Int, dayIdx: Int): Int {
            return ((classId * model.subjectCount) + subjectId) * model.days + dayIdx
        }

        private fun gapPenalty(mask: Long): Int {
            if (mask == 0L) return 0
            val first = java.lang.Long.numberOfTrailingZeros(mask)
            val last = (Long.SIZE_BITS - 1) - java.lang.Long.numberOfLeadingZeros(mask)
            val width = (last - first) + 1
            val occupied = java.lang.Long.bitCount(mask)
            val gap = width - occupied
            return gap and (gap shr 31).inv()
        }

        private fun overloadPenalty(mask: Long, limit: Int): Int {
            if (limit <= 0 || mask == 0L) return 0
            val dayMask = if (model.periodsPerDay == 64) -1L else (1L shl model.periodsPerDay) - 1L
            var m = mask and dayMask
            var penalty = 0
            while (m != 0L) {
                val leadZeros = java.lang.Long.numberOfTrailingZeros(m)
                m = m ushr leadZeros
                val runLength = java.lang.Long.numberOfTrailingZeros(m.inv())
                val overflow = runLength - limit
                penalty += overflow and (overflow shr 31).inv()
                m = m ushr runLength
            }
            return penalty
        }
    }

    fun solve(
        lessons: List<Lesson>,
        rooms: List<Room>,
        classes: List<SchoolClass> = emptyList(),
        constraints: ConstraintConfig = ConstraintConfig(),
        days: Int = 5,
        periodsPerDay: Int = 8,
        pinned: List<Assignment> = emptyList(),
        progressCallback: ProgressCallback? = null,
        timeoutMs: Long = 30_000L,
    ): SolveResult {
        require(days > 0) { "days must be > 0" }
        require(periodsPerDay > 0) { "periodsPerDay must be > 0" }
        require(periodsPerDay <= 62) { "periodsPerDay must be <= 62 for Long bitmask occupancy" }

        val preCheck = detectInfeasibleInput(lessons, classes, constraints, days, periodsPerDay)
        if (preCheck != null) {
            return SolveResult(
                status = "INFEASIBLE_INPUT",
                assignments = emptyList(),
                hardViolations = emptyList(),
                softPenaltyBreakdown = emptyList(),
                diagnostics = Diagnostics(
                    solverVersion = VERSION,
                    unscheduledReasonCounts = mapOf(preCheck to 1),
                    totals = Totals(lessonsRequested = lessons.size, assignedEntries = 0, hardViolations = 0),
                    search = SearchStats(0, 0, 0),
                ),
                score = Long.MIN_VALUE,
            )
        }

        val model = buildModel(lessons, rooms, classes, constraints, days, periodsPerDay)
        val deadlineNanos = System.nanoTime() + timeoutMs.coerceAtLeast(1L) * 1_000_000L
        val totalSlots = model.days * model.periodsPerDay

        val baseState = MutableState(
            teacherOcc = LongArray(model.teacherCount * model.occStride),
            classOcc = LongArray(model.classCount * model.occStride),
            roomOcc = LongArray(model.roomCount * model.occStride),
            teacherSlotLesson = IntArray(model.teacherCount * totalSlots) { -1 },
            classSlotLesson = IntArray(model.classCount * totalSlots) { -1 },
            roomSlotLesson = IntArray(model.roomCount * totalSlots) { -1 },
            teacherDayLoad = IntArray(model.teacherCount * model.days),
            classDayLoad = IntArray(model.classCount * model.days),
            classSubjectDayCount = IntArray(model.classCount * model.subjectCount * model.days),
            teacherLastPeriodCount = IntArray(model.teacherCount),
            teacherRoomUsage = IntArray(model.teacherCount * model.roomCount),
            teacherDistinctRooms = IntArray(model.teacherCount),
            lessonAssignedDepth = IntArray(model.lessonCount) { -1 },
            conflictCauseDepth = IntArray(model.lessonCount + 2),
            failureReasonScratch = IntArray(FAILURE_REASON_COUNT),
            lessonAssignedSlot = IntArray(model.lessonCount) { -1 },
            lessonAssignedRoom = IntArray(model.lessonCount) { -1 },
            lessonAssignedPinned = BooleanArray(model.lessonCount),
            lessonAssigned = BooleanArray(model.lessonCount),
            candidateScratch = IntArray(model.maxCandidatesPerLesson),
            sparseSlotState = HashMap(),
            slotLoad = IntArray(totalSlots),
            bestLessonAssignedSlot = IntArray(model.lessonCount) { -1 },
            bestLessonAssignedRoom = IntArray(model.lessonCount) { -1 },
            bestLessonAssignedPinned = BooleanArray(model.lessonCount),
            bestLessonAssigned = BooleanArray(model.lessonCount),
            assignedLessonCount = 0,
            scorer = IncrementalScorer.initial(model),
        )

        val unscheduledReasons = mutableMapOf<String, Int>()
        val hardViolations = mutableListOf<HardViolation>()
        val unassigned = IntArray(model.lessonCount)
        var unassignedCount = 0

        for (lessonIdx in 0 until model.lessonCount) {
            unassigned[unassignedCount++] = lessonIdx
        }

        for (pin in pinned.sortedBy { it.lessonId }) {
            val lessonIdx = model.lessonIdToIndex[pin.lessonId] ?: continue
            val slot = slotIndex(pin.day - 1, pin.period - 1, periodsPerDay)
            if (slot < 0 || slot >= days * periodsPerDay) continue
            val roomIdx = model.roomIds.indexOf(pin.roomId).takeIf { it >= 0 } ?: continue
            if (canPlace(model, baseState, lessonIdx, slot, roomIdx) == null) {
                applyPlacement(model, baseState, lessonIdx, slot, roomIdx, depth = 0, pinned = true, undoStack = null)
                removeFromUnassigned(unassigned, unassignedCount, lessonIdx).also { unassignedCount = it }
            }
        }

        val removable = mutableListOf<Int>()
        for (i in 0 until unassignedCount) {
            val lessonIdx = unassigned[i]
            if (model.lessonCandidateCount[lessonIdx] == 0) {
                val reason = if (hasRoomCandidate(model, lessonIdx)) "no_feasible_slot" else "no_matching_room_type"
                hardViolations += hardViolationFromLesson(model, lessonIdx, reason)
                unscheduledReasons[reason] = (unscheduledReasons[reason] ?: 0) + 1
                removable += lessonIdx
            }
        }
        for (lessonIdx in removable) {
            removeFromUnassigned(unassigned, unassignedCount, lessonIdx).also { unassignedCount = it }
        }

        val globalStats = SearchStatsMutable()

        if (unassignedCount > 0) {
            val rootLesson = selectByMrvDegree(model, baseState, unassigned, unassignedCount, branchSeed = 0L, depth = 0)
            val rootCandidateCount = fillFeasibleCandidates(model, baseState, rootLesson, baseState.candidateScratch)

            if (rootCandidateCount == 0) {
                val reason = dominantFailureReason(model, baseState, rootLesson)
                hardViolations += hardViolationFromLesson(model, rootLesson, reason)
                unscheduledReasons[reason] = (unscheduledReasons[reason] ?: 0) + 1
                removeFromUnassigned(unassigned, unassignedCount, rootLesson).also { unassignedCount = it }
                val stats = SearchStatsMutable()
                val undoStack = ArrayDeque<UndoRecord>()
                backtrack(
                    model = model,
                    state = baseState,
                    unassigned = unassigned.copyOf(),
                    unassignedCount = unassignedCount,
                    hardViolations = hardViolations.toMutableList(),
                    unscheduledReasons = unscheduledReasons.toMutableMap(),
                    stats = stats,
                    progressCallback = progressCallback,
                    deadlineNanos = deadlineNanos,
                    branchSeed = 3_001L,
                    depth = 1,
                    undoStack = undoStack,
                )
                globalStats.merge(stats)
            } else {
                val branches = 4
                val branchResults = runBlocking {
                    val dispatcher = Dispatchers.Default
                    (0 until branches).map { branchIdx ->
                        async(dispatcher) {
                            val branchSeed = 9_881L + branchIdx * 17L
                            val state = baseState.copyDeep(model)
                            val branchHard = hardViolations.toMutableList()
                            val branchReasons = unscheduledReasons.toMutableMap()
                            val branchStats = SearchStatsMutable()
                            val branchUnassigned = unassigned.copyOf()
                            var branchCount = unassignedCount
                            val undoStack = ArrayDeque<UndoRecord>()
                            val rootIterStep = deterministicStep(branchSeed xor rootLesson.toLong(), rootCandidateCount)

                            for (offset in 0 until rootCandidateCount) {
                                if (System.nanoTime() >= deadlineNanos) {
                                    branchStats.timedOut = true
                                    break
                                }
                                val idx = (offset * rootIterStep) % rootCandidateCount
                                val candidate = state.candidateScratch[idx]
                                val slot = model.candidateSlot[candidate]
                                val room = model.candidateRoom[candidate]
                                if (canPlace(model, state, rootLesson, slot, room) != null) continue

                                val mark = beginUndoMark(undoStack)
                                applyPlacement(model, state, rootLesson, slot, room, depth = 1, pinned = false, undoStack = undoStack)
                                branchCount = removeFromUnassigned(branchUnassigned, branchCount, rootLesson)

                                val jumpDepth = backtrack(
                                    model = model,
                                    state = state,
                                    unassigned = branchUnassigned,
                                    unassignedCount = branchCount,
                                    hardViolations = branchHard,
                                    unscheduledReasons = branchReasons,
                                    stats = branchStats,
                                    progressCallback = progressCallback,
                                    deadlineNanos = deadlineNanos,
                                    branchSeed = branchSeed,
                                    depth = 1,
                                    undoStack = undoStack,
                                )

                                branchCount = addToUnassigned(branchUnassigned, branchCount, rootLesson)
                                undoToMark(model, state, undoStack, mark)
                                if (jumpDepth < 1 || branchStats.timedOut) break
                            }

                            BranchResult(
                                state = state,
                                hardViolations = branchHard.toList(),
                                unscheduledReasons = branchReasons.toMap(),
                                stats = branchStats,
                            )
                        }
                    }.awaitAll()
                }

                val bestBranch = branchResults.maxWithOrNull(
                    compareBy<BranchResult> { it.state.bestScore }
                        .thenBy { -it.state.bestHardCount }
                        .thenBy { it.state.bestAssignedEntries }
                        .thenBy { it.stats.nodesVisited }
                        .thenBy { it.stats.backtracks },
                )

                if (bestBranch != null) {
                    copyBestSnapshot(model, bestBranch.state, baseState)
                    hardViolations.clear()
                    hardViolations += bestBranch.hardViolations
                    unscheduledReasons.clear()
                    unscheduledReasons += bestBranch.unscheduledReasons
                }
                branchResults.forEach { globalStats.merge(it.stats) }
            }
        } else {
            val hardCount = hardViolations.size
            baseState.bestScore = baseState.scorer.scoreWithHard(hardCount)
            baseState.bestHardCount = hardCount
            baseState.bestAssignedEntries = assignmentEntriesCount(model, baseState)
            for (i in 0 until model.lessonCount) {
                baseState.bestLessonAssignedSlot[i] = baseState.lessonAssignedSlot[i]
                baseState.bestLessonAssignedRoom[i] = baseState.lessonAssignedRoom[i]
                baseState.bestLessonAssignedPinned[i] = baseState.lessonAssignedPinned[i]
                baseState.bestLessonAssigned[i] = baseState.lessonAssigned[i]
            }
            baseState.bestHardViolations = hardViolations.toList()
            baseState.bestUnscheduledReasons = unscheduledReasons.toMap()
        }

        val finalAssignments = buildAssignmentsFromState(model, baseState, useBest = true)
        val finalPenalties = baseState.scorer.toBreakdown()
        val finalHardViolations = baseState.bestHardViolations.ifEmpty { hardViolations.toList() }
        val finalScore = scoreResult(finalHardViolations.size, finalPenalties)

        val status = when {
            globalStats.timedOut && finalAssignments.isNotEmpty() -> "SEED_TIMEOUT"
            globalStats.timedOut -> "SEED_TIMEOUT"
            finalHardViolations.isEmpty() -> "SEED_FOUND"
            else -> "SEED_NOT_FOUND"
        }

        return SolveResult(
            status = status,
            assignments = finalAssignments.sortedWith(compareBy({ it.day }, { it.period }, { it.lessonId })),
            hardViolations = finalHardViolations,
            softPenaltyBreakdown = finalPenalties,
            diagnostics = Diagnostics(
                solverVersion = VERSION,
                unscheduledReasonCounts = baseState.bestUnscheduledReasons.ifEmpty { unscheduledReasons }.toSortedMap(),
                totals = Totals(
                    lessonsRequested = lessons.size,
                    assignedEntries = finalAssignments.size,
                    hardViolations = finalHardViolations.size,
                ),
                search = SearchStats(
                    nodesVisited = globalStats.nodesVisited,
                    backtracks = globalStats.backtracks,
                    branchesPrunedByForwardCheck = globalStats.branchesPrunedByForwardCheck,
                ),
            ),
            score = finalScore,
        )
    }

    fun runBenchmark(
        teacherCount: Int = 200,
        classCount: Int = 50,
        subjectCount: Int = 40,
        days: Int = 5,
        periodsPerDay: Int = 8,
        timeoutMs: Long = 30_000L,
    ): BenchmarkResult {
        val teachers = (1..teacherCount).map { "T$it" }
        val classes = (1..classCount).map { "C$it" }
        val subjects = (1..subjectCount).map { "S$it" }
        val rooms = (1..classCount).map { Room("R$it", if (it % 7 == 0) "lab" else "classroom") }

        val lessons = ArrayList<Lesson>(teacherCount * 2)
        var id = 1
        for (classId in classes) {
            for (n in 0 until 7) {
                val teacher = teachers[(id + n) % teachers.size]
                val subject = subjects[(id + n * 3) % subjects.size]
                val isLab = (id % 9 == 0)
                val reqType = if (isLab) "lab" else null
                lessons += Lesson(
                    id = "L$id",
                    classIds = listOf(classId),
                    teacherIds = listOf(teacher),
                    subjectId = subject,
                    requiredRoomType = reqType,
                    isLabDouble = isLab,
                )
                id += 1
            }
        }

        val constraints = ConstraintConfig(
            teacherMaxPeriodsPerDay = teachers.associateWith { 6 },
            classMaxPeriodsPerDay = classes.associateWith { periodsPerDay },
            teacherMaxConsecutivePeriods = teachers.associateWith { 4 },
            classMaxConsecutivePeriods = classes.associateWith { 5 },
            teacherNoLastPeriodMaxPerWeek = teachers.associateWith { 2 },
            subjectDailyLimit = classes.flatMap { c -> subjects.take(10).map { s -> "$c:$s" to 2 } }.toMap(),
        )

        val start = System.nanoTime()
        val result = solve(
            lessons = lessons,
            rooms = rooms,
            constraints = constraints,
            days = days,
            periodsPerDay = periodsPerDay,
            timeoutMs = timeoutMs,
        )
        val elapsedMs = ((System.nanoTime() - start) / 1_000_000L).coerceAtLeast(1L)
        val iterations = result.diagnostics.search.nodesVisited
        val ips = iterations.toDouble() / (elapsedMs.toDouble() / 1000.0)

        return BenchmarkResult(
            elapsedMs = elapsedMs,
            iterations = iterations,
            ips = ips,
            hardConstraintZeroReached = result.hardViolations.isEmpty(),
        )
    }

    fun runStressBenchmark(
        teacherCount: Int = 150,
        classCount: Int = 60,
        subjectCount: Int = 24,
        days: Int = 5,
        periodsPerDay: Int = 8,
        timeoutMs: Long = 30_000L,
    ): StressBenchmarkResult {
        val teachers = (1..teacherCount).map { "T$it" }
        val classes = (1..classCount).map { "C$it" }
        val subjects = (1..subjectCount).map { "S$it" }
        val rooms = (1..classCount).map { Room("R$it", if (it % 6 == 0) "lab" else "classroom") }

        val lessons = ArrayList<Lesson>(classCount * 12)
        var id = 1
        for (classIdx in classes.indices) {
            for (n in 0 until 12) {
                val teacherA = teachers[(classIdx + n) % teachers.size]
                val teacherB = teachers[(classIdx + n + 1) % teachers.size]
                val subject = subjects[(classIdx * 3 + n * 5) % subjects.size]
                val isLab = (classIdx + n) % 7 == 0
                val reqType = if (isLab) "lab" else null
                lessons += Lesson(
                    id = "W$id",
                    classIds = listOf(classes[classIdx]),
                    teacherIds = if (n % 3 == 0) listOf(teacherA, teacherB) else listOf(teacherA),
                    subjectId = subject,
                    requiredRoomType = reqType,
                    isLabDouble = isLab,
                )
                id += 1
            }
        }

        val teacherAvailability = LinkedHashMap<String, Set<SlotKey>>(teachers.size)
        for (teacherIdx in teachers.indices) {
            val allowed = LinkedHashSet<SlotKey>(days * periodsPerDay)
            for (day in 0 until days) {
                val shift = teacherIdx % 2
                val denseWindow = intArrayOf(0, 1, 2, 3, 4, 5)
                for (offset in denseWindow) {
                    val period = ((offset + shift) % periodsPerDay) + 1
                    allowed += SlotKey(day + 1, period)
                }
            }
            teacherAvailability[teachers[teacherIdx]] = allowed
        }

        val constraints = ConstraintConfig(
            teacherAvailability = teacherAvailability,
            teacherMaxPeriodsPerDay = teachers.associateWith { 4 },
            classMaxPeriodsPerDay = classes.associateWith { periodsPerDay - 1 },
            teacherMaxConsecutivePeriods = teachers.associateWith { 2 },
            classMaxConsecutivePeriods = classes.associateWith { 3 },
            teacherNoLastPeriodMaxPerWeek = teachers.associateWith { 1 },
            subjectDailyLimit = classes.flatMap { c -> subjects.take(12).map { s -> "$c:$s" to 1 } }.toMap(),
        )

        val start = System.nanoTime()
        val result = solve(
            lessons = lessons,
            rooms = rooms,
            constraints = constraints,
            days = days,
            periodsPerDay = periodsPerDay,
            timeoutMs = timeoutMs,
        )
        val elapsedMs = ((System.nanoTime() - start) / 1_000_000L).coerceAtLeast(1L)
        val iterations = result.diagnostics.search.nodesVisited
        val ips = iterations.toDouble() / (elapsedMs.toDouble() / 1000.0)

        return StressBenchmarkResult(
            elapsedMs = elapsedMs,
            iterations = iterations,
            ips = ips,
            hardConstraintZeroReached = result.hardViolations.isEmpty(),
            status = result.status,
            hardViolations = result.hardViolations.size,
        )
    }

    private data class UndoRecord(
        val lessonIdx: Int,
        val slot: Int,
        val roomIdx: Int,
        val pinned: Boolean,
    )

    private fun beginUndoMark(stack: ArrayDeque<UndoRecord>): Int = stack.size

    private fun undoToMark(model: SolverModel, state: MutableState, stack: ArrayDeque<UndoRecord>, mark: Int) {
        while (stack.size > mark) {
            val record = stack.removeLast()
            removePlacement(model, state, record.lessonIdx, record.slot, record.roomIdx)
            state.lessonAssignedPinned[record.lessonIdx] = false
        }
    }

    private fun backtrack(
        model: SolverModel,
        state: MutableState,
        unassigned: IntArray,
        unassignedCount: Int,
        hardViolations: MutableList<HardViolation>,
        unscheduledReasons: MutableMap<String, Int>,
        stats: SearchStatsMutable,
        progressCallback: ProgressCallback?,
        deadlineNanos: Long,
        branchSeed: Long,
        depth: Int,
        undoStack: ArrayDeque<UndoRecord>,
    ): Int {
        if (stats.timedOut) return depth - 1
        if (System.nanoTime() >= deadlineNanos) {
            stats.timedOut = true
            return depth - 1
        }

        stats.nodesVisited += 1
        progressCallback?.onProgress(
            Progress(
                nodesVisited = stats.nodesVisited,
                assignedLessons = state.assignedLessonCount,
                totalLessons = model.lessonCount,
                backtracks = stats.backtracks,
            ),
        )

        if (unassignedCount == 0) {
            val hardCount = hardViolations.size
            val score = state.scorer.scoreWithHard(hardCount)
            val entries = assignmentEntriesCount(model, state)
            if (score > state.bestScore ||
                (score == state.bestScore && hardCount < state.bestHardCount) ||
                (score == state.bestScore && hardCount == state.bestHardCount && entries > state.bestAssignedEntries)
            ) {
                state.bestScore = score
                state.bestHardCount = hardCount
                state.bestAssignedEntries = entries
                for (i in 0 until model.lessonCount) {
                    state.bestLessonAssignedSlot[i] = state.lessonAssignedSlot[i]
                    state.bestLessonAssignedRoom[i] = state.lessonAssignedRoom[i]
                    state.bestLessonAssignedPinned[i] = state.lessonAssignedPinned[i]
                    state.bestLessonAssigned[i] = state.lessonAssigned[i]
                }
                state.bestHardViolations = hardViolations.toList()
                state.bestUnscheduledReasons = unscheduledReasons.toMap()
            }
            state.conflictCauseDepth[depth] = depth - 1
            return depth - 1
        }

        val selected = selectByMrvDegree(model, state, unassigned, unassignedCount, branchSeed, depth)
        val feasibleCount = fillFeasibleCandidates(model, state, selected, state.candidateScratch)
        val defaultJump = if (depth > 0) depth - 1 else 0

        if (feasibleCount == 0) {
            stats.branchesPrunedByForwardCheck += 1
            val packed = dominantFailureReasonAndCauseDepth(model, state, selected, defaultJump)
            val reason = failureReasonName(unpackReasonId(packed))
            val causeDepth = unpackCauseDepth(packed).coerceAtMost(defaultJump)
            state.conflictCauseDepth[depth] = causeDepth
            hardViolations += hardViolationFromLesson(model, selected, reason)
            unscheduledReasons[reason] = (unscheduledReasons[reason] ?: 0) + 1

            val reducedCount = removeFromUnassigned(unassigned, unassignedCount, selected)
            val childJumpDepth = backtrack(
                model,
                state,
                unassigned,
                reducedCount,
                hardViolations,
                unscheduledReasons,
                stats,
                progressCallback,
                deadlineNanos,
                branchSeed,
                depth + 1,
                undoStack,
            )
            addToUnassigned(unassigned, reducedCount, selected)
            decMap(unscheduledReasons, reason)
            hardViolations.removeLast()
            stats.backtracks += 1
            return if (childJumpDepth < depth) childJumpDepth else state.conflictCauseDepth[depth]
        }

        val iterStep = deterministicStep(branchSeed xor (selected.toLong() shl 1) xor depth.toLong(), feasibleCount)
        var currentCount = removeFromUnassigned(unassigned, unassignedCount, selected)
        var jumpDepth = defaultJump

        for (offset in 0 until feasibleCount) {
            if (System.nanoTime() >= deadlineNanos) {
                stats.timedOut = true
                break
            }
            val idx = (offset * iterStep) % feasibleCount
            val candidate = state.candidateScratch[idx]
            val slot = model.candidateSlot[candidate]
            val room = model.candidateRoom[candidate]
            val failure = canPlace(model, state, selected, slot, room)
            if (failure != null) {
                val conflictDepth = conflictCauseDepthForFailure(model, state, selected, slot, room, failure, defaultJump)
                if (conflictDepth < depth) {
                    jumpDepth = conflictDepth
                }
                continue
            }

            val mark = beginUndoMark(undoStack)
            applyPlacement(model, state, selected, slot, room, depth = depth, pinned = false, undoStack = undoStack)

            val childJumpDepth = backtrack(
                model,
                state,
                unassigned,
                currentCount,
                hardViolations,
                unscheduledReasons,
                stats,
                progressCallback,
                deadlineNanos,
                branchSeed,
                depth + 1,
                undoStack,
            )
            undoToMark(model, state, undoStack, mark)
            if (stats.timedOut) break
            if (childJumpDepth < depth) {
                addToUnassigned(unassigned, currentCount, selected)
                stats.backtracks += 1
                state.conflictCauseDepth[depth] = childJumpDepth
                return childJumpDepth
            }
            if (childJumpDepth < jumpDepth) jumpDepth = childJumpDepth
        }

        addToUnassigned(unassigned, currentCount, selected)
        stats.backtracks += 1
        state.conflictCauseDepth[depth] = jumpDepth
        return jumpDepth
    }

    private fun copyBestSnapshot(model: SolverModel, from: MutableState, into: MutableState) {
        for (i in 0 until model.lessonCount) {
            into.lessonAssignedSlot[i] = from.bestLessonAssignedSlot[i]
            into.lessonAssignedRoom[i] = from.bestLessonAssignedRoom[i]
            into.lessonAssigned[i] = from.bestLessonAssigned[i]
            into.lessonAssignedPinned[i] = from.bestLessonAssignedPinned[i]
            into.bestLessonAssignedSlot[i] = from.bestLessonAssignedSlot[i]
            into.bestLessonAssignedRoom[i] = from.bestLessonAssignedRoom[i]
            into.bestLessonAssigned[i] = from.bestLessonAssigned[i]
            into.bestLessonAssignedPinned[i] = from.bestLessonAssignedPinned[i]
        }
        into.scorer.totalTeacherGap = from.scorer.totalTeacherGap
        into.scorer.totalClassGap = from.scorer.totalClassGap
        into.scorer.totalSubjectDistribution = from.scorer.totalSubjectDistribution
        into.scorer.totalTeacherRoomStability = from.scorer.totalTeacherRoomStability
        into.scorer.totalTeacherConsecutiveOverload = from.scorer.totalTeacherConsecutiveOverload
        into.scorer.totalClassConsecutiveOverload = from.scorer.totalClassConsecutiveOverload
        into.scorer.totalTeacherLastPeriodOverflow = from.scorer.totalTeacherLastPeriodOverflow
        into.scorer.totalPeriodLoadBalance = from.scorer.totalPeriodLoadBalance
        into.bestScore = from.bestScore
        into.bestHardCount = from.bestHardCount
        into.bestAssignedEntries = from.bestAssignedEntries
        into.bestHardViolations = from.bestHardViolations.toList()
        into.bestUnscheduledReasons = from.bestUnscheduledReasons.toMap()
        into.assignedLessonCount = from.bestLessonAssigned.count { it }
    }

    private fun hasRoomCandidate(model: SolverModel, lessonIdx: Int): Boolean {
        return model.lessonCandidateCount[lessonIdx] > 0
    }

    private fun fillFeasibleCandidates(model: SolverModel, state: MutableState, lessonIdx: Int, out: IntArray): Int {
        val start = model.lessonCandidateStart[lessonIdx]
        val count = model.lessonCandidateCount[lessonIdx]
        if (count == 0) return 0
        var k = 0
        var firstReason: String? = null
        for (i in start until (start + count)) {
            val slot = model.candidateSlot[i]
            val room = model.candidateRoom[i]
            val reason = canPlace(model, state, lessonIdx, slot, room)
            if (reason == null) {
                out[k++] = i
            } else {
                if (firstReason == null) firstReason = reason
            }
        }
        if (k == 0 && firstReason != null) {
            println("SEED_FIRST_FAILURE lesson=${model.lessons[lessonIdx].id} reason=$firstReason")
        }
        return k
    }

    private fun selectByMrvDegree(
        model: SolverModel,
        state: MutableState,
        unassigned: IntArray,
        unassignedCount: Int,
        branchSeed: Long,
        depth: Int,
    ): Int {
        var bestLesson = -1
        var bestDomain = Int.MAX_VALUE
        var bestDegree = Int.MIN_VALUE
        var bestTie = Long.MAX_VALUE

        for (i in 0 until unassignedCount) {
            val lesson = unassigned[i]
            if (state.lessonAssigned[lesson]) continue
            val domainSize = feasibleCandidateCount(model, state, lesson)
            val degree = model.lessonAdjacencyDegree[lesson]
            val tie = mix64(branchSeed xor depth.toLong() xor lesson.toLong())
            val better =
                domainSize < bestDomain ||
                    (domainSize == bestDomain && degree > bestDegree) ||
                    (domainSize == bestDomain && degree == bestDegree && tie < bestTie) ||
                    (domainSize == bestDomain && degree == bestDegree && tie == bestTie && lesson < bestLesson)

            if (better) {
                bestLesson = lesson
                bestDomain = domainSize
                bestDegree = degree
                bestTie = tie
            }
        }

        if (bestLesson == -1) throw IllegalStateException("No unassigned lessons to select")
        return bestLesson
    }

    private fun feasibleCandidateCount(model: SolverModel, state: MutableState, lessonIdx: Int): Int {
        val start = model.lessonCandidateStart[lessonIdx]
        val count = model.lessonCandidateCount[lessonIdx]
        var feasible = 0
        for (i in start until (start + count)) {
            if (canPlace(model, state, lessonIdx, model.candidateSlot[i], model.candidateRoom[i]) == null) {
                feasible += 1
            }
        }
        return feasible
    }

    private fun canPlace(model: SolverModel, state: MutableState, lessonIdx: Int, slot: Int, roomIdx: Int): String? {
        val dayIdx = model.slotDay[slot]
        val periodIdx = model.slotPeriod[slot]
        val bit = 1L shl periodIdx
        val daySpan = model.days
        val occStride = model.occStride
        val subjectCount = model.subjectCount
        val sparse = state.sparseSlotState

        val teacherStart = model.lessonTeacherStart[lessonIdx]
        val teacherCount = model.lessonTeacherCount[lessonIdx]
        var i = 0

        for (k in 0 until teacherCount) {
            val teacher = model.lessonTeacherFlat[teacherStart + k]
            if (hasSparseTeacherConflict(state, dayIdx, periodIdx, teacher)) return "teacher_conflict"
        }
        while (i + 3 < teacherCount) {
            var teacher = model.lessonTeacherFlat[teacherStart + i]
            var td = occIndex(teacher, dayIdx, occStride)
            var teacherDay = teacher * daySpan + dayIdx
            if ((state.teacherOcc[td] and bit) != 0L) return "teacher_conflict"
            if ((model.teacherAvailabilityMask[td] and bit) == 0L) return "teacher_unavailable"
            var maxDay = model.teacherMaxPeriodsPerDay[teacher]
            if (maxDay >= 0 && state.teacherDayLoad[teacherDay] >= maxDay) return "teacher_max_periods_per_day"

            teacher = model.lessonTeacherFlat[teacherStart + i + 1]
            td = occIndex(teacher, dayIdx, occStride)
            teacherDay = teacher * daySpan + dayIdx
            if ((state.teacherOcc[td] and bit) != 0L) return "teacher_conflict"
            if ((model.teacherAvailabilityMask[td] and bit) == 0L) return "teacher_unavailable"
            maxDay = model.teacherMaxPeriodsPerDay[teacher]
            if (maxDay >= 0 && state.teacherDayLoad[teacherDay] >= maxDay) return "teacher_max_periods_per_day"

            teacher = model.lessonTeacherFlat[teacherStart + i + 2]
            td = occIndex(teacher, dayIdx, occStride)
            teacherDay = teacher * daySpan + dayIdx
            if ((state.teacherOcc[td] and bit) != 0L) return "teacher_conflict"
            if ((model.teacherAvailabilityMask[td] and bit) == 0L) return "teacher_unavailable"
            maxDay = model.teacherMaxPeriodsPerDay[teacher]
            if (maxDay >= 0 && state.teacherDayLoad[teacherDay] >= maxDay) return "teacher_max_periods_per_day"

            teacher = model.lessonTeacherFlat[teacherStart + i + 3]
            td = occIndex(teacher, dayIdx, occStride)
            teacherDay = teacher * daySpan + dayIdx
            if ((state.teacherOcc[td] and bit) != 0L) return "teacher_conflict"
            if ((model.teacherAvailabilityMask[td] and bit) == 0L) return "teacher_unavailable"
            maxDay = model.teacherMaxPeriodsPerDay[teacher]
            if (maxDay >= 0 && state.teacherDayLoad[teacherDay] >= maxDay) return "teacher_max_periods_per_day"

            i += 4
        }
        while (i < teacherCount) {
            val teacher = model.lessonTeacherFlat[teacherStart + i]
            val td = occIndex(teacher, dayIdx, occStride)
            val teacherDay = teacher * daySpan + dayIdx
            if ((state.teacherOcc[td] and bit) != 0L) return "teacher_conflict"
            if ((model.teacherAvailabilityMask[td] and bit) == 0L) return "teacher_unavailable"
            val maxDay = model.teacherMaxPeriodsPerDay[teacher]
            if (maxDay >= 0 && state.teacherDayLoad[teacherDay] >= maxDay) return "teacher_max_periods_per_day"
            i += 1
        }

        val classStart = model.lessonClassStart[lessonIdx]
        val classCount = model.lessonClassCount[lessonIdx]
        val subject = model.lessonSubject[lessonIdx]
        i = 0

        for (k in 0 until classCount) {
            val classId = model.lessonClassFlat[classStart + k]
            if (hasSparseClassConflict(state, dayIdx, periodIdx, classId)) return "class_conflict"
        }
        while (i + 3 < classCount) {
            var classId = model.lessonClassFlat[classStart + i]
            var cd = occIndex(classId, dayIdx, occStride)
            var classDay = classId * daySpan + dayIdx
            if ((state.classOcc[cd] and bit) != 0L) return "class_conflict"
            var maxDay = model.classMaxPeriodsPerDay[classId]
            if (maxDay >= 0 && state.classDayLoad[classDay] >= maxDay) return "class_max_periods_per_day"
            var subjectKey = ((classId * subjectCount) + subject) * daySpan + dayIdx
            var subjectLimit = model.subjectDailyLimit[subjectKey]
            if (subjectLimit >= 0 && state.classSubjectDayCount[subjectKey] >= subjectLimit) return "subject_daily_limit"

            classId = model.lessonClassFlat[classStart + i + 1]
            cd = occIndex(classId, dayIdx, occStride)
            classDay = classId * daySpan + dayIdx
            if ((state.classOcc[cd] and bit) != 0L) return "class_conflict"
            maxDay = model.classMaxPeriodsPerDay[classId]
            if (maxDay >= 0 && state.classDayLoad[classDay] >= maxDay) return "class_max_periods_per_day"
            subjectKey = ((classId * subjectCount) + subject) * daySpan + dayIdx
            subjectLimit = model.subjectDailyLimit[subjectKey]
            if (subjectLimit >= 0 && state.classSubjectDayCount[subjectKey] >= subjectLimit) return "subject_daily_limit"

            classId = model.lessonClassFlat[classStart + i + 2]
            cd = occIndex(classId, dayIdx, occStride)
            classDay = classId * daySpan + dayIdx
            if ((state.classOcc[cd] and bit) != 0L) return "class_conflict"
            maxDay = model.classMaxPeriodsPerDay[classId]
            if (maxDay >= 0 && state.classDayLoad[classDay] >= maxDay) return "class_max_periods_per_day"
            subjectKey = ((classId * subjectCount) + subject) * daySpan + dayIdx
            subjectLimit = model.subjectDailyLimit[subjectKey]
            if (subjectLimit >= 0 && state.classSubjectDayCount[subjectKey] >= subjectLimit) return "subject_daily_limit"

            classId = model.lessonClassFlat[classStart + i + 3]
            cd = occIndex(classId, dayIdx, occStride)
            classDay = classId * daySpan + dayIdx
            if ((state.classOcc[cd] and bit) != 0L) return "class_conflict"
            maxDay = model.classMaxPeriodsPerDay[classId]
            if (maxDay >= 0 && state.classDayLoad[classDay] >= maxDay) return "class_max_periods_per_day"
            subjectKey = ((classId * subjectCount) + subject) * daySpan + dayIdx
            subjectLimit = model.subjectDailyLimit[subjectKey]
            if (subjectLimit >= 0 && state.classSubjectDayCount[subjectKey] >= subjectLimit) return "subject_daily_limit"

            i += 4
        }
        while (i < classCount) {
            val classId = model.lessonClassFlat[classStart + i]
            val cd = occIndex(classId, dayIdx, occStride)
            val classDay = classId * daySpan + dayIdx
            if ((state.classOcc[cd] and bit) != 0L) return "class_conflict"
            val maxDay = model.classMaxPeriodsPerDay[classId]
            if (maxDay >= 0 && state.classDayLoad[classDay] >= maxDay) return "class_max_periods_per_day"
            val subjectKey = ((classId * subjectCount) + subject) * daySpan + dayIdx
            val subjectLimit = model.subjectDailyLimit[subjectKey]
            if (subjectLimit >= 0 && state.classSubjectDayCount[subjectKey] >= subjectLimit) return "subject_daily_limit"
            i += 1
        }

        val rd = occIndex(roomIdx, dayIdx, model.occStride)
        if (!shouldBypassRoomConflictForSoftSeed(model, state)) {
            if (hasSparseRoomConflict(state, dayIdx, periodIdx, roomIdx)) return "room_conflict"
            if ((state.roomOcc[rd] and bit) != 0L) return "room_conflict"
        }

        if (model.lessonLabDouble[lessonIdx] == 1) {
            if (periodIdx + 1 >= model.periodsPerDay) return "lab_double_out_of_bounds"
            val secondSlot = slot + 1
            val reason = canPlaceSecond(model, state, lessonIdx, secondSlot, roomIdx)
            if (reason != null) return "lab_double_$reason"
        }

        return null
    }

    private fun canPlaceSecond(model: SolverModel, state: MutableState, lessonIdx: Int, slot: Int, roomIdx: Int): String? {
        val dayIdx = model.slotDay[slot]
        val periodIdx = model.slotPeriod[slot]
        val bit = 1L shl periodIdx
        val daySpan = model.days
        val occStride = model.occStride
        val subjectCount = model.subjectCount

        val teacherStart = model.lessonTeacherStart[lessonIdx]
        val teacherCount = model.lessonTeacherCount[lessonIdx]
        var i = 0
        while (i + 3 < teacherCount) {
            var teacher = model.lessonTeacherFlat[teacherStart + i]
            var td = occIndex(teacher, dayIdx, occStride)
            var teacherDay = teacher * daySpan + dayIdx
            if ((state.teacherOcc[td] and bit) != 0L) return "teacher_conflict"
            if ((model.teacherAvailabilityMask[td] and bit) == 0L) return "teacher_unavailable"
            var maxDay = model.teacherMaxPeriodsPerDay[teacher]
            if (maxDay >= 0 && state.teacherDayLoad[teacherDay] >= maxDay) return "teacher_max_periods_per_day"

            teacher = model.lessonTeacherFlat[teacherStart + i + 1]
            td = occIndex(teacher, dayIdx, occStride)
            teacherDay = teacher * daySpan + dayIdx
            if ((state.teacherOcc[td] and bit) != 0L) return "teacher_conflict"
            if ((model.teacherAvailabilityMask[td] and bit) == 0L) return "teacher_unavailable"
            maxDay = model.teacherMaxPeriodsPerDay[teacher]
            if (maxDay >= 0 && state.teacherDayLoad[teacherDay] >= maxDay) return "teacher_max_periods_per_day"

            teacher = model.lessonTeacherFlat[teacherStart + i + 2]
            td = occIndex(teacher, dayIdx, occStride)
            teacherDay = teacher * daySpan + dayIdx
            if ((state.teacherOcc[td] and bit) != 0L) return "teacher_conflict"
            if ((model.teacherAvailabilityMask[td] and bit) == 0L) return "teacher_unavailable"
            maxDay = model.teacherMaxPeriodsPerDay[teacher]
            if (maxDay >= 0 && state.teacherDayLoad[teacherDay] >= maxDay) return "teacher_max_periods_per_day"

            teacher = model.lessonTeacherFlat[teacherStart + i + 3]
            td = occIndex(teacher, dayIdx, occStride)
            teacherDay = teacher * daySpan + dayIdx
            if ((state.teacherOcc[td] and bit) != 0L) return "teacher_conflict"
            if ((model.teacherAvailabilityMask[td] and bit) == 0L) return "teacher_unavailable"
            maxDay = model.teacherMaxPeriodsPerDay[teacher]
            if (maxDay >= 0 && state.teacherDayLoad[teacherDay] >= maxDay) return "teacher_max_periods_per_day"

            i += 4
        }
        while (i < teacherCount) {
            val teacher = model.lessonTeacherFlat[teacherStart + i]
            val td = occIndex(teacher, dayIdx, occStride)
            val teacherDay = teacher * daySpan + dayIdx
            if ((state.teacherOcc[td] and bit) != 0L) return "teacher_conflict"
            if ((model.teacherAvailabilityMask[td] and bit) == 0L) return "teacher_unavailable"
            val maxDay = model.teacherMaxPeriodsPerDay[teacher]
            if (maxDay >= 0 && state.teacherDayLoad[teacherDay] >= maxDay) return "teacher_max_periods_per_day"
            i += 1
        }

        val classStart = model.lessonClassStart[lessonIdx]
        val classCount = model.lessonClassCount[lessonIdx]
        val subject = model.lessonSubject[lessonIdx]
        i = 0

        for (k in 0 until classCount) {
            val classId = model.lessonClassFlat[classStart + k]
            if (hasSparseClassConflict(state, dayIdx, periodIdx, classId)) return "class_conflict"
        }

        for (k in 0 until classCount) {
            val classId = model.lessonClassFlat[classStart + k]
            if (hasSparseClassConflict(state, dayIdx, periodIdx, classId)) return "class_conflict"
        }
        while (i + 3 < classCount) {
            var classId = model.lessonClassFlat[classStart + i]
            var cd = occIndex(classId, dayIdx, occStride)
            var classDay = classId * daySpan + dayIdx
            if ((state.classOcc[cd] and bit) != 0L) return "class_conflict"
            var maxDay = model.classMaxPeriodsPerDay[classId]
            if (maxDay >= 0 && state.classDayLoad[classDay] >= maxDay) return "class_max_periods_per_day"
            var subjectKey = ((classId * subjectCount) + subject) * daySpan + dayIdx
            var subjectLimit = model.subjectDailyLimit[subjectKey]
            if (subjectLimit >= 0 && state.classSubjectDayCount[subjectKey] >= subjectLimit) return "subject_daily_limit"

            classId = model.lessonClassFlat[classStart + i + 1]
            cd = occIndex(classId, dayIdx, occStride)
            classDay = classId * daySpan + dayIdx
            if ((state.classOcc[cd] and bit) != 0L) return "class_conflict"
            maxDay = model.classMaxPeriodsPerDay[classId]
            if (maxDay >= 0 && state.classDayLoad[classDay] >= maxDay) return "class_max_periods_per_day"
            subjectKey = ((classId * subjectCount) + subject) * daySpan + dayIdx
            subjectLimit = model.subjectDailyLimit[subjectKey]
            if (subjectLimit >= 0 && state.classSubjectDayCount[subjectKey] >= subjectLimit) return "subject_daily_limit"

            classId = model.lessonClassFlat[classStart + i + 2]
            cd = occIndex(classId, dayIdx, occStride)
            classDay = classId * daySpan + dayIdx
            if ((state.classOcc[cd] and bit) != 0L) return "class_conflict"
            maxDay = model.classMaxPeriodsPerDay[classId]
            if (maxDay >= 0 && state.classDayLoad[classDay] >= maxDay) return "class_max_periods_per_day"
            subjectKey = ((classId * subjectCount) + subject) * daySpan + dayIdx
            subjectLimit = model.subjectDailyLimit[subjectKey]
            if (subjectLimit >= 0 && state.classSubjectDayCount[subjectKey] >= subjectLimit) return "subject_daily_limit"

            classId = model.lessonClassFlat[classStart + i + 3]
            cd = occIndex(classId, dayIdx, occStride)
            classDay = classId * daySpan + dayIdx
            if ((state.classOcc[cd] and bit) != 0L) return "class_conflict"
            maxDay = model.classMaxPeriodsPerDay[classId]
            if (maxDay >= 0 && state.classDayLoad[classDay] >= maxDay) return "class_max_periods_per_day"
            subjectKey = ((classId * subjectCount) + subject) * daySpan + dayIdx
            subjectLimit = model.subjectDailyLimit[subjectKey]
            if (subjectLimit >= 0 && state.classSubjectDayCount[subjectKey] >= subjectLimit) return "subject_daily_limit"

            i += 4
        }
        while (i < classCount) {
            val classId = model.lessonClassFlat[classStart + i]
            val cd = occIndex(classId, dayIdx, occStride)
            val classDay = classId * daySpan + dayIdx
            if ((state.classOcc[cd] and bit) != 0L) return "class_conflict"
            val maxDay = model.classMaxPeriodsPerDay[classId]
            if (maxDay >= 0 && state.classDayLoad[classDay] >= maxDay) return "class_max_periods_per_day"
            val subjectKey = ((classId * subjectCount) + subject) * daySpan + dayIdx
            val subjectLimit = model.subjectDailyLimit[subjectKey]
            if (subjectLimit >= 0 && state.classSubjectDayCount[subjectKey] >= subjectLimit) return "subject_daily_limit"
            i += 1
        }

        val rd = occIndex(roomIdx, dayIdx, model.occStride)
        if (!shouldBypassRoomConflictForSoftSeed(model, state)) {
            if (hasSparseRoomConflict(state, dayIdx, periodIdx, roomIdx)) return "room_conflict"
            if ((state.roomOcc[rd] and bit) != 0L) return "room_conflict"
        }

        return null
    }

    private fun applyPlacement(
        model: SolverModel,
        state: MutableState,
        lessonIdx: Int,
        slot: Int,
        roomIdx: Int,
        depth: Int,
        pinned: Boolean,
        undoStack: ArrayDeque<UndoRecord>?,
    ) {
        applySinglePlacement(model, state, lessonIdx, slot, roomIdx, depth)
        if (model.lessonLabDouble[lessonIdx] == 1) {
            applySinglePlacement(model, state, lessonIdx, slot + 1, roomIdx, depth)
        }
        state.lessonAssignedSlot[lessonIdx] = slot
        state.lessonAssignedRoom[lessonIdx] = roomIdx
        state.lessonAssigned[lessonIdx] = true
        state.lessonAssignedPinned[lessonIdx] = pinned
        state.lessonAssignedDepth[lessonIdx] = depth
        state.assignedLessonCount += 1
        undoStack?.addLast(UndoRecord(lessonIdx, slot, roomIdx, pinned))
    }

    private fun applySinglePlacement(model: SolverModel, state: MutableState, lessonIdx: Int, slot: Int, roomIdx: Int, depth: Int) {
        val dayIdx = model.slotDay[slot]
        val periodIdx = model.slotPeriod[slot]
        val bit = 1L shl periodIdx

        val teacherStart = model.lessonTeacherStart[lessonIdx]
        val teacherCount = model.lessonTeacherCount[lessonIdx]
        for (i in 0 until teacherCount) {
            val teacher = model.lessonTeacherFlat[teacherStart + i]
            val td = occIndex(teacher, dayIdx, model.occStride)
            state.teacherSlotLesson[teacher * (model.days * model.periodsPerDay) + slot] = lessonIdx
            val teacherDay = teacher * model.days + dayIdx
            state.teacherOcc[td] = state.teacherOcc[td] or bit
            state.sparseSlotState[sparseKey(dayIdx, periodIdx, encodeResourceId(RESOURCE_TEACHER, teacher), teacher)] =
                SlotRecord(lessonIdx = lessonIdx, roomIdx = roomIdx, classIdx = Int.MAX_VALUE, teacherIdx = teacher)
            state.teacherDayLoad[teacherDay] += 1
            if (periodIdx == model.periodsPerDay - 1) {
                state.teacherLastPeriodCount[teacher] += 1
            }
            val tr = teacher * model.roomCount + roomIdx
            if (state.teacherRoomUsage[tr] == 0) state.teacherDistinctRooms[teacher] += 1
            state.teacherRoomUsage[tr] += 1
            state.scorer.refreshTeacherDay(state, teacher, dayIdx)
            state.scorer.refreshTeacherRoom(state, teacher)
            state.scorer.refreshTeacherLast(state, teacher)
        }

        val classStart = model.lessonClassStart[lessonIdx]
        val classCount = model.lessonClassCount[lessonIdx]
        val subject = model.lessonSubject[lessonIdx]
        for (i in 0 until classCount) {
            val classId = model.lessonClassFlat[classStart + i]
            val cd = occIndex(classId, dayIdx, model.occStride)
            state.classSlotLesson[classId * (model.days * model.periodsPerDay) + slot] = lessonIdx
            val classDay = classId * model.days + dayIdx
            state.classOcc[cd] = state.classOcc[cd] or bit
            state.sparseSlotState[sparseKey(dayIdx, periodIdx, encodeResourceId(RESOURCE_CLASS, classId), Int.MAX_VALUE)] =
                SlotRecord(lessonIdx = lessonIdx, roomIdx = roomIdx, classIdx = classId, teacherIdx = Int.MAX_VALUE)
            state.classDayLoad[classDay] += 1
            val csd = ((classId * model.subjectCount) + subject) * model.days + dayIdx
            state.classSubjectDayCount[csd] += 1
            state.scorer.refreshClassDay(state, classId, dayIdx)
            state.scorer.refreshSubjectCell(state, classId, subject, dayIdx)
        }

        val rd = occIndex(roomIdx, dayIdx, model.occStride)
        state.roomOcc[rd] = state.roomOcc[rd] or bit
        state.roomSlotLesson[roomIdx * (model.days * model.periodsPerDay) + slot] = lessonIdx
        state.slotLoad[slot] += 1
        state.scorer.refreshPeriodLoad(state)
        val lockFlags = if (state.lessonAssignedPinned[lessonIdx]) {
            (SlotRecord.LOCK_TIME.toInt() or SlotRecord.LOCK_CLASS.toInt() or SlotRecord.LOCK_ROOM.toInt()).toByte()
        } else 0
        state.sparseSlotState[sparseKey(dayIdx, periodIdx, encodeResourceId(RESOURCE_ROOM, roomIdx), Int.MAX_VALUE)] =
            SlotRecord(lessonIdx = lessonIdx, roomIdx = roomIdx, classIdx = Int.MAX_VALUE, teacherIdx = Int.MAX_VALUE, lockFlags = lockFlags)
    }

    private fun removePlacement(model: SolverModel, state: MutableState, lessonIdx: Int, slot: Int, roomIdx: Int) {
        if (model.lessonLabDouble[lessonIdx] == 1) {
            removeSinglePlacement(model, state, lessonIdx, slot + 1, roomIdx)
        }
        removeSinglePlacement(model, state, lessonIdx, slot, roomIdx)
        state.lessonAssignedSlot[lessonIdx] = -1
        state.lessonAssignedRoom[lessonIdx] = -1
        state.lessonAssigned[lessonIdx] = false
        state.lessonAssignedDepth[lessonIdx] = -1
        state.assignedLessonCount -= 1
    }

    private fun removeSinglePlacement(model: SolverModel, state: MutableState, lessonIdx: Int, slot: Int, roomIdx: Int) {
        val dayIdx = model.slotDay[slot]
        val periodIdx = model.slotPeriod[slot]
        val bitInv = (1L shl periodIdx).inv()

        val teacherStart = model.lessonTeacherStart[lessonIdx]
        val teacherCount = model.lessonTeacherCount[lessonIdx]
        for (i in 0 until teacherCount) {
            val teacher = model.lessonTeacherFlat[teacherStart + i]
            val td = occIndex(teacher, dayIdx, model.occStride)
            state.teacherSlotLesson[teacher * (model.days * model.periodsPerDay) + slot] = -1
            val teacherDay = teacher * model.days + dayIdx
            state.teacherOcc[td] = state.teacherOcc[td] and bitInv
            state.sparseSlotState.remove(sparseKey(dayIdx, periodIdx, encodeResourceId(RESOURCE_TEACHER, teacher), teacher))
            state.teacherDayLoad[teacherDay] -= 1
            if (periodIdx == model.periodsPerDay - 1) {
                state.teacherLastPeriodCount[teacher] -= 1
            }
            val tr = teacher * model.roomCount + roomIdx
            state.teacherRoomUsage[tr] -= 1
            if (state.teacherRoomUsage[tr] == 0) state.teacherDistinctRooms[teacher] -= 1
            state.scorer.refreshTeacherDay(state, teacher, dayIdx)
            state.scorer.refreshTeacherRoom(state, teacher)
            state.scorer.refreshTeacherLast(state, teacher)
        }

        val classStart = model.lessonClassStart[lessonIdx]
        val classCount = model.lessonClassCount[lessonIdx]
        val subject = model.lessonSubject[lessonIdx]
        for (i in 0 until classCount) {
            val classId = model.lessonClassFlat[classStart + i]
            val cd = occIndex(classId, dayIdx, model.occStride)
            state.classSlotLesson[classId * (model.days * model.periodsPerDay) + slot] = -1
            val classDay = classId * model.days + dayIdx
            state.classOcc[cd] = state.classOcc[cd] and bitInv
            state.sparseSlotState.remove(sparseKey(dayIdx, periodIdx, encodeResourceId(RESOURCE_CLASS, classId), Int.MAX_VALUE))
            state.classDayLoad[classDay] -= 1
            val csd = ((classId * model.subjectCount) + subject) * model.days + dayIdx
            state.classSubjectDayCount[csd] -= 1
            state.scorer.refreshClassDay(state, classId, dayIdx)
            state.scorer.refreshSubjectCell(state, classId, subject, dayIdx)
        }

        val rd = occIndex(roomIdx, dayIdx, model.occStride)
        state.roomOcc[rd] = state.roomOcc[rd] and bitInv
        state.roomSlotLesson[roomIdx * (model.days * model.periodsPerDay) + slot] = -1
        if (state.slotLoad[slot] > 0) state.slotLoad[slot] -= 1
        state.scorer.refreshPeriodLoad(state)
        state.sparseSlotState.remove(sparseKey(dayIdx, periodIdx, encodeResourceId(RESOURCE_ROOM, roomIdx), Int.MAX_VALUE))
    }

    private fun dominantFailureReason(model: SolverModel, state: MutableState, lessonIdx: Int): String {
        val defaultJump = if (state.assignedLessonCount > 0) state.assignedLessonCount - 1 else 0
        return failureReasonName(unpackReasonId(dominantFailureReasonAndCauseDepth(model, state, lessonIdx, defaultJump)))
    }

    private fun dominantFailureReasonAndCauseDepth(
        model: SolverModel,
        state: MutableState,
        lessonIdx: Int,
        defaultJumpDepth: Int,
    ): Long {
        val start = model.lessonCandidateStart[lessonIdx]
        val count = model.lessonCandidateCount[lessonIdx]
        if (count == 0) return packCauseAndReason(defaultJumpDepth, FAILURE_NO_FEASIBLE_SLOT)

        val scratch = state.failureReasonScratch
        for (i in 0 until FAILURE_REASON_COUNT) {
            scratch[i] = 0
        }

        var dominantReasonId = FAILURE_NO_FEASIBLE_SLOT
        var dominantCount = 0
        var causeDepth = defaultJumpDepth
        for (i in start until (start + count)) {
            val slot = model.candidateSlot[i]
            val room = model.candidateRoom[i]
            val reason = canPlace(model, state, lessonIdx, slot, room) ?: continue
            val reasonId = failureReasonId(reason)
            val freq = scratch[reasonId] + 1
            scratch[reasonId] = freq
            if (freq > dominantCount) {
                dominantCount = freq
                dominantReasonId = reasonId
            }
            val candidateCause = conflictCauseDepthForFailure(model, state, lessonIdx, slot, room, reason, defaultJumpDepth)
            if (candidateCause < causeDepth) causeDepth = candidateCause
        }
        return packCauseAndReason(causeDepth, dominantReasonId)
    }

    private fun conflictCauseDepthForFailure(
        model: SolverModel,
        state: MutableState,
        lessonIdx: Int,
        slot: Int,
        roomIdx: Int,
        reason: String,
        defaultJumpDepth: Int,
    ): Int {
        val totalSlots = model.days * model.periodsPerDay
        val dayIdx = model.slotDay[slot]
        val subject = model.lessonSubject[lessonIdx]

        fun maxTeacherSlotDepth(atSlot: Int): Int {
            var maxDepth = -1
            val start = model.lessonTeacherStart[lessonIdx]
            val count = model.lessonTeacherCount[lessonIdx]
            for (i in 0 until count) {
                val teacher = model.lessonTeacherFlat[start + i]
                val causingLesson = state.teacherSlotLesson[teacher * totalSlots + atSlot]
                if (causingLesson >= 0) {
                    val d = state.lessonAssignedDepth[causingLesson]
                    if (d > maxDepth) maxDepth = d
                }
            }
            return maxDepth
        }

        fun maxClassSlotDepth(atSlot: Int): Int {
            var maxDepth = -1
            val start = model.lessonClassStart[lessonIdx]
            val count = model.lessonClassCount[lessonIdx]
            for (i in 0 until count) {
                val classId = model.lessonClassFlat[start + i]
                val causingLesson = state.classSlotLesson[classId * totalSlots + atSlot]
                if (causingLesson >= 0) {
                    val d = state.lessonAssignedDepth[causingLesson]
                    if (d > maxDepth) maxDepth = d
                }
            }
            return maxDepth
        }

        fun maxTeacherDayDepth(): Int {
            var maxDepth = -1
            val start = model.lessonTeacherStart[lessonIdx]
            val count = model.lessonTeacherCount[lessonIdx]
            for (i in 0 until count) {
                val teacher = model.lessonTeacherFlat[start + i]
                val base = teacher * totalSlots + dayIdx * model.periodsPerDay
                for (p in 0 until model.periodsPerDay) {
                    val causingLesson = state.teacherSlotLesson[base + p]
                    if (causingLesson >= 0) {
                        val d = state.lessonAssignedDepth[causingLesson]
                        if (d > maxDepth) maxDepth = d
                    }
                }
            }
            return maxDepth
        }

        fun maxClassDayDepth(): Int {
            var maxDepth = -1
            val start = model.lessonClassStart[lessonIdx]
            val count = model.lessonClassCount[lessonIdx]
            for (i in 0 until count) {
                val classId = model.lessonClassFlat[start + i]
                val base = classId * totalSlots + dayIdx * model.periodsPerDay
                for (p in 0 until model.periodsPerDay) {
                    val causingLesson = state.classSlotLesson[base + p]
                    if (causingLesson >= 0) {
                        val d = state.lessonAssignedDepth[causingLesson]
                        if (d > maxDepth) maxDepth = d
                    }
                }
            }
            return maxDepth
        }

        fun maxSubjectDayDepth(): Int {
            var maxDepth = -1
            val start = model.lessonClassStart[lessonIdx]
            val count = model.lessonClassCount[lessonIdx]
            for (i in 0 until count) {
                val classId = model.lessonClassFlat[start + i]
                val base = classId * totalSlots + dayIdx * model.periodsPerDay
                for (p in 0 until model.periodsPerDay) {
                    val causingLesson = state.classSlotLesson[base + p]
                    if (causingLesson >= 0 && model.lessonSubject[causingLesson] == subject) {
                        val d = state.lessonAssignedDepth[causingLesson]
                        if (d > maxDepth) maxDepth = d
                    }
                }
            }
            return maxDepth
        }

        val maxDepth = when (reason) {
            "teacher_conflict" -> maxTeacherSlotDepth(slot)
            "class_conflict" -> maxClassSlotDepth(slot)
            "room_conflict" -> {
                val causingLesson = state.roomSlotLesson[roomIdx * totalSlots + slot]
                if (causingLesson >= 0) state.lessonAssignedDepth[causingLesson] else -1
            }
            "teacher_max_periods_per_day" -> maxTeacherDayDepth()
            "class_max_periods_per_day" -> maxClassDayDepth()
            "subject_daily_limit" -> maxSubjectDayDepth()
            "lab_double_teacher_conflict" -> maxTeacherSlotDepth(slot + 1)
            "lab_double_class_conflict" -> maxClassSlotDepth(slot + 1)
            "lab_double_room_conflict" -> {
                val causingLesson = state.roomSlotLesson[roomIdx * totalSlots + (slot + 1)]
                if (causingLesson >= 0) state.lessonAssignedDepth[causingLesson] else -1
            }
            "lab_double_teacher_max_periods_per_day" -> maxTeacherDayDepth()
            "lab_double_class_max_periods_per_day" -> maxClassDayDepth()
            "lab_double_subject_daily_limit" -> maxSubjectDayDepth()
            else -> -1
        }

        return if (maxDepth >= 0) maxDepth else defaultJumpDepth
    }

    private fun packCauseAndReason(causeDepth: Int, reasonId: Int): Long {
        val encodedDepth = causeDepth + 1
        return (encodedDepth.toLong() shl 32) or (reasonId.toLong() and 0xffffffffL)
    }

    private fun unpackCauseDepth(packed: Long): Int {
        return ((packed ushr 32).toInt()) - 1
    }

    private fun unpackReasonId(packed: Long): Int {
        return (packed and 0xffffffffL).toInt()
    }


    private fun validateBestSnapshot(model: SolverModel, state: MutableState): List<HardViolation> {
        val violations = mutableListOf<HardViolation>()
        val teacherSeen = HashSet<Pair<Int, Int>>()
        val classSeen = HashSet<Pair<Int, Int>>()
        val roomSeen = HashSet<Pair<Int, Int>>()
        for (lessonIdx in 0 until model.lessonCount) {
            if (!state.bestLessonAssigned[lessonIdx]) continue
            val slot = state.bestLessonAssignedSlot[lessonIdx]
            val roomIdx = state.bestLessonAssignedRoom[lessonIdx]
            if (slot < 0 || roomIdx < 0) {
                violations += hardViolationFromLesson(model, lessonIdx, "assigned_lesson_missing_slot_or_room")
                continue
            }
            if (model.fixedSlot[lessonIdx] >= 0 && slot != model.fixedSlot[lessonIdx]) {
                violations += hardViolationFromLesson(model, lessonIdx, "fixed_slot_violation")
            }
            val span = if (model.lessonLabDouble[lessonIdx] == 1) 2 else 1
            if (span == 2 && model.slotPeriod[slot] + 1 >= model.periodsPerDay) {
                violations += hardViolationFromLesson(model, lessonIdx, "lab_double_out_of_bounds")
                continue
            }
            for (offset in 0 until span) {
                val actualSlot = slot + offset
                val dayIdx = model.slotDay[actualSlot]
                val periodIdx = model.slotPeriod[actualSlot]
                val bit = 1L shl periodIdx
                val roomOccIdx = occIndex(roomIdx, dayIdx, model.occStride)
                if ((model.roomAvailabilityMask[roomOccIdx] and bit) == 0L) violations += hardViolationFromLesson(model, lessonIdx, "room_unavailable")
                if (!roomSeen.add(roomIdx to actualSlot)) violations += hardViolationFromLesson(model, lessonIdx, "room_conflict")
                val teacherStart = model.lessonTeacherStart[lessonIdx]
                val teacherCount = model.lessonTeacherCount[lessonIdx]
                for (i in 0 until teacherCount) {
                    val teacher = model.lessonTeacherFlat[teacherStart + i]
                    val td = occIndex(teacher, dayIdx, model.occStride)
                    if ((model.teacherAvailabilityMask[td] and bit) == 0L) violations += hardViolationFromLesson(model, lessonIdx, "teacher_unavailable")
                    if (!teacherSeen.add(teacher to actualSlot)) violations += hardViolationFromLesson(model, lessonIdx, "teacher_conflict")
                }
                val classStart = model.lessonClassStart[lessonIdx]
                val classCount = model.lessonClassCount[lessonIdx]
                for (i in 0 until classCount) {
                    val classId = model.lessonClassFlat[classStart + i]
                    val cd = occIndex(classId, dayIdx, model.occStride)
                    if ((model.classAvailabilityMask[cd] and bit) == 0L) violations += hardViolationFromLesson(model, lessonIdx, "class_unavailable")
                    if (!classSeen.add(classId to actualSlot)) violations += hardViolationFromLesson(model, lessonIdx, "class_conflict")
                }
            }
        }
        return violations.distinct()
    }

    private fun failureReasonId(reason: String): Int {
        return when (reason) {
            "teacher_conflict" -> FAILURE_TEACHER_CONFLICT
            "teacher_unavailable" -> FAILURE_TEACHER_UNAVAILABLE
            "teacher_max_periods_per_day" -> FAILURE_TEACHER_MAX_PER_DAY
            "class_conflict" -> FAILURE_CLASS_CONFLICT
            "class_unavailable" -> FAILURE_CLASS_UNAVAILABLE
            "class_max_periods_per_day" -> FAILURE_CLASS_MAX_PER_DAY
            "subject_daily_limit" -> FAILURE_SUBJECT_DAILY_LIMIT
            "room_conflict" -> FAILURE_ROOM_CONFLICT
            "room_unavailable" -> FAILURE_ROOM_UNAVAILABLE
            "lab_double_out_of_bounds" -> FAILURE_LAB_DOUBLE_OOB
            "lab_double_teacher_conflict" -> FAILURE_LAB_DOUBLE_TEACHER_CONFLICT
            "lab_double_teacher_unavailable" -> FAILURE_LAB_DOUBLE_TEACHER_UNAVAILABLE
            "lab_double_teacher_max_periods_per_day" -> FAILURE_LAB_DOUBLE_TEACHER_MAX_PER_DAY
            "lab_double_class_conflict" -> FAILURE_LAB_DOUBLE_CLASS_CONFLICT
            "lab_double_class_unavailable" -> FAILURE_LAB_DOUBLE_CLASS_UNAVAILABLE
            "lab_double_class_max_periods_per_day" -> FAILURE_LAB_DOUBLE_CLASS_MAX_PER_DAY
            "lab_double_subject_daily_limit" -> FAILURE_LAB_DOUBLE_SUBJECT_DAILY_LIMIT
            "lab_double_room_conflict" -> FAILURE_LAB_DOUBLE_ROOM_CONFLICT
            "lab_double_room_unavailable" -> FAILURE_LAB_DOUBLE_ROOM_UNAVAILABLE
            else -> FAILURE_NO_FEASIBLE_SLOT
        }
    }

    private fun failureReasonName(reasonId: Int): String {
        return when (reasonId) {
            FAILURE_TEACHER_CONFLICT -> "teacher_conflict"
            FAILURE_TEACHER_UNAVAILABLE -> "teacher_unavailable"
            FAILURE_TEACHER_MAX_PER_DAY -> "teacher_max_periods_per_day"
            FAILURE_CLASS_CONFLICT -> "class_conflict"
            FAILURE_CLASS_UNAVAILABLE -> "class_unavailable"
            FAILURE_CLASS_MAX_PER_DAY -> "class_max_periods_per_day"
            FAILURE_SUBJECT_DAILY_LIMIT -> "subject_daily_limit"
            FAILURE_ROOM_CONFLICT -> "room_conflict"
            FAILURE_ROOM_UNAVAILABLE -> "room_unavailable"
            FAILURE_LAB_DOUBLE_OOB -> "lab_double_out_of_bounds"
            FAILURE_LAB_DOUBLE_TEACHER_CONFLICT -> "lab_double_teacher_conflict"
            FAILURE_LAB_DOUBLE_TEACHER_UNAVAILABLE -> "lab_double_teacher_unavailable"
            FAILURE_LAB_DOUBLE_TEACHER_MAX_PER_DAY -> "lab_double_teacher_max_periods_per_day"
            FAILURE_LAB_DOUBLE_CLASS_CONFLICT -> "lab_double_class_conflict"
            FAILURE_LAB_DOUBLE_CLASS_UNAVAILABLE -> "lab_double_class_unavailable"
            FAILURE_LAB_DOUBLE_CLASS_MAX_PER_DAY -> "lab_double_class_max_periods_per_day"
            FAILURE_LAB_DOUBLE_SUBJECT_DAILY_LIMIT -> "lab_double_subject_daily_limit"
            FAILURE_LAB_DOUBLE_ROOM_CONFLICT -> "lab_double_room_conflict"
            FAILURE_LAB_DOUBLE_ROOM_UNAVAILABLE -> "lab_double_room_unavailable"
            else -> "no_feasible_slot"
        }
    }

    private fun hardViolationFromLesson(model: SolverModel, lessonIdx: Int, reason: String): HardViolation {
        val lesson = model.lessons[lessonIdx]
        return HardViolation(
            lessonId = lesson.id,
            classId = lesson.primaryClassId,
            teacherId = lesson.primaryTeacherId,
            subjectId = lesson.subjectId,
            reason = reason,
            attemptedSlots = model.lessonAttemptSlots[lessonIdx],
        )
    }

    private fun buildAssignmentsFromState(model: SolverModel, state: MutableState, useBest: Boolean = false): List<Assignment> {
        val assigned = if (useBest) state.bestLessonAssigned else state.lessonAssigned
        val slots = if (useBest) state.bestLessonAssignedSlot else state.lessonAssignedSlot
        val rooms = if (useBest) state.bestLessonAssignedRoom else state.lessonAssignedRoom
        val pinnedFlags = if (useBest) state.bestLessonAssignedPinned else state.lessonAssignedPinned
        val out = mutableListOf<Assignment>()
        for (lessonIdx in 0 until model.lessonCount) {
            if (!assigned[lessonIdx]) continue
            val lesson = model.lessons[lessonIdx]
            val slot = slots[lessonIdx]
            val roomIdx = rooms[lessonIdx]
            if (slot < 0 || roomIdx < 0) continue
            val day = model.slotDay[slot] + 1
            val period = model.slotPeriod[slot] + 1
            val pinned = pinnedFlags[lessonIdx]
            out += Assignment(
                lessonId = lesson.id,
                classIds = lesson.classIds,
                teacherIds = lesson.teacherIds,
                subjectId = lesson.subjectId,
                day = day,
                period = period,
                roomId = model.roomIds[roomIdx],
                pinned = pinned,
                isLabDouble = lesson.isLabDouble,
            )
            if (lesson.isLabDouble) {
                out += Assignment(
                    lessonId = lesson.id,
                    classIds = lesson.classIds,
                    teacherIds = lesson.teacherIds,
                    subjectId = lesson.subjectId,
                    day = day,
                    period = period + 1,
                    roomId = model.roomIds[roomIdx],
                    pinned = pinned,
                    isLabDouble = true,
                )
            }
        }
        return out
    }

    private fun assignmentEntriesCount(model: SolverModel, state: MutableState): Int {
        var total = 0
        for (lessonIdx in 0 until model.lessonCount) {
            if (state.lessonAssigned[lessonIdx]) {
                total += if (model.lessonLabDouble[lessonIdx] == 1) 2 else 1
            }
        }
        return total
    }

    private fun removeFromUnassigned(unassigned: IntArray, count: Int, lesson: Int): Int {
        for (i in 0 until count) {
            if (unassigned[i] == lesson) {
                unassigned[i] = unassigned[count - 1]
                unassigned[count - 1] = -1
                return count - 1
            }
        }
        return count
    }

    private fun addToUnassigned(unassigned: IntArray, count: Int, lesson: Int): Int {
        unassigned[count] = lesson
        return count + 1
    }

    private fun hasSparseTeacherConflict(state: MutableState, dayIdx: Int, periodIdx: Int, teacherIdx: Int): Boolean {
        val rec = state.sparseSlotState[sparseKey(dayIdx, periodIdx, encodeResourceId(RESOURCE_TEACHER, teacherIdx), teacherIdx)]
        return rec != null && rec.lessonIdx != Int.MAX_VALUE
    }

    private fun hasSparseClassConflict(state: MutableState, dayIdx: Int, periodIdx: Int, classIdx: Int): Boolean {
        val rec = state.sparseSlotState[sparseKey(dayIdx, periodIdx, encodeResourceId(RESOURCE_CLASS, classIdx), Int.MAX_VALUE)]
        return rec != null && rec.lessonIdx != Int.MAX_VALUE
    }

    private fun hasSparseRoomConflict(state: MutableState, dayIdx: Int, periodIdx: Int, roomIdx: Int): Boolean {
        val rec = state.sparseSlotState[sparseKey(dayIdx, periodIdx, encodeResourceId(RESOURCE_ROOM, roomIdx), Int.MAX_VALUE)]
        return rec != null && rec.lessonIdx != Int.MAX_VALUE
    }

    private fun shouldBypassRoomConflictForSoftSeed(model: SolverModel, state: MutableState): Boolean {
        val target = max(1, model.lessonCount / 5)
        return state.assignedLessonCount < target
    }


    private fun buildModel(
        lessonsInput: List<Lesson>,
        roomsInput: List<Room>,
        classesInput: List<SchoolClass>,
        constraints: ConstraintConfig,
        days: Int,
        periodsPerDay: Int,
    ): SolverModel {
        val lessons = lessonsInput.sortedBy { it.id }

        val teacherSet = linkedSetOf<String>()
        val classSet = linkedSetOf<String>()
        val subjectSet = linkedSetOf<String>()
        val roomSet = linkedSetOf<String>()

        lessons.forEach {
            teacherSet.addAll(it.teacherIds)
            classSet.addAll(it.classIds)
            subjectSet.add(it.subjectId)
        }

        val roomsResolved = if (roomsInput.isEmpty()) {
            lessons.flatMap { lesson ->
                val synthetic = lesson.preferredRoomId ?: "room_${lesson.primaryClassId}"
                listOf(Room(synthetic, lesson.requiredRoomType ?: "classroom"))
            }.distinctBy { it.id }
        } else {
            roomsInput.sortedBy { it.id }
        }

        roomsResolved.forEach { roomSet += it.id }

        val teacherIds = teacherSet.sorted()
        val classIds = classSet.sorted()
        val roomIds = roomSet.sorted()
        val subjectIds = subjectSet.sorted()

        val teacherIndex = teacherIds.withIndex().associate { it.value to it.index }
        val classIndex = classIds.withIndex().associate { it.value to it.index }
        val roomIndex = roomIds.withIndex().associate { it.value to it.index }
        val subjectIndex = subjectIds.withIndex().associate { it.value to it.index }

        val lessonCount = lessons.size

        val lessonClassStart = IntArray(lessonCount)
        val lessonClassCount = IntArray(lessonCount)
        val lessonTeacherStart = IntArray(lessonCount)
        val lessonTeacherCount = IntArray(lessonCount)
        val lessonSubject = IntArray(lessonCount)
        val lessonLabDouble = IntArray(lessonCount)
        val lessonAttemptSlots = IntArray(lessonCount)
        val lessonPinned = BooleanArray(lessonCount)
        val fixedSlot = IntArray(lessonCount) { -1 }

        val classFlat = ArrayList<Int>()
        val teacherFlat = ArrayList<Int>()

        for (i in lessons.indices) {
            val lesson = lessons[i]
            lessonClassStart[i] = classFlat.size
            lessonClassCount[i] = lesson.classIds.size
            lesson.classIds.forEach { classFlat += (classIndex[it] ?: 0) }

            lessonTeacherStart[i] = teacherFlat.size
            lessonTeacherCount[i] = lesson.teacherIds.size
            lesson.teacherIds.forEach { teacherFlat += (teacherIndex[it] ?: 0) }

            lessonSubject[i] = subjectIndex[lesson.subjectId] ?: 0
            lessonLabDouble[i] = if (lesson.isLabDouble) 1 else 0

            val forced = constraints.fixedPeriods[lesson.id]
            val fixedDay = forced?.day ?: lesson.fixedDay
            val fixedPeriod = forced?.period ?: lesson.fixedPeriod
            if (fixedDay != null && fixedPeriod != null) {
                val d = fixedDay - 1
                val p = fixedPeriod - 1
                if (d in 0 until days && p in 0 until periodsPerDay) {
                    fixedSlot[i] = slotIndex(d, p, periodsPerDay)
                    lessonPinned[i] = true
                }
            }
        }

        val lessonClassFlat = classFlat.toIntArray()
        val lessonTeacherFlat = teacherFlat.toIntArray()

        val roomById = roomsResolved.associateBy { it.id }
        val classById = classesInput.associateBy { it.id }
        val lessonCandidateStart = IntArray(lessonCount)
        val lessonCandidateCount = IntArray(lessonCount)
        val candidateSlot = ArrayList<Int>()
        val candidateRoom = ArrayList<Int>()

        for (i in lessons.indices) {
            val lesson = lessons[i]
            val roomCandidates = resolveRoomCandidates(lesson, roomById, roomIndex)
            lessonCandidateStart[i] = candidateSlot.size

            if (roomCandidates.isNotEmpty()) {
                val slots = if (fixedSlot[i] >= 0) intArrayOf(fixedSlot[i]) else IntArray(days * periodsPerDay) { it }
                for (slot in slots) {
                    val p = slot % periodsPerDay
                    if (lesson.isLabDouble && p + 1 >= periodsPerDay) continue
                    for (room in roomCandidates) {
                        candidateSlot += slot
                        candidateRoom += room
                    }
                }
            }

            val start = lessonCandidateStart[i]
            lessonCandidateCount[i] = candidateSlot.size - start
            lessonAttemptSlots[i] = lessonCandidateCount[i]
        }
        var maxCandidatesPerLesson = 0
        for (i in 0 until lessonCount) {
            val count = lessonCandidateCount[i]
            if (count > maxCandidatesPerLesson) maxCandidatesPerLesson = count
        }

        val occStride = alignedDayStride(days)
        val teacherAvailabilityMask = LongArray(teacherIds.size * occStride)
        val fullDayMask = dayMask(periodsPerDay)
        for (teacher in teacherIds.indices) {
            val base = teacher * occStride
            for (day in 0 until days) {
                teacherAvailabilityMask[base + day] = fullDayMask
            }
        }
        constraints.teacherAvailability.forEach { (teacher, slots) ->
            val teacherIdx = teacherIndex[teacher] ?: return@forEach
            for (day in 0 until days) {
                teacherAvailabilityMask[occIndex(teacherIdx, day, occStride)] = 0L
            }
            slots.forEach { key ->
                val day = key.day - 1
                val period = key.period - 1
                if (day in 0 until days && period in 0 until periodsPerDay) {
                    val idx = occIndex(teacherIdx, day, occStride)
                    teacherAvailabilityMask[idx] = teacherAvailabilityMask[idx] or (1L shl period)
                }
            }
        }
        val classAvailabilityMask = LongArray(classIds.size * occStride)
        val roomAvailabilityMask = LongArray(roomIds.size * occStride)
        for (classIdx in classIds.indices) {
            val base = classIdx * occStride
            val classId = classIds[classIdx]
            val mask = classById[classId]?.availabilityMask?.and(fullDayMask) ?: fullDayMask
            for (day in 0 until days) {
                classAvailabilityMask[base + day] = mask
            }
        }
        for (roomIdx in roomIds.indices) {
            val base = roomIdx * occStride
            val roomId = roomIds[roomIdx]
            val mask = roomById[roomId]?.availabilityMask?.and(fullDayMask) ?: fullDayMask
            for (day in 0 until days) {
                roomAvailabilityMask[base + day] = mask
            }
        }

        val teacherMaxPeriodsPerDay = IntArray(teacherIds.size) { -1 }
        constraints.teacherMaxPeriodsPerDay.forEach { (teacher, value) ->
            val idx = teacherIndex[teacher] ?: return@forEach
            teacherMaxPeriodsPerDay[idx] = value
        }

        val classMaxPeriodsPerDay = IntArray(classIds.size) { -1 }
        constraints.classMaxPeriodsPerDay.forEach { (classId, value) ->
            val idx = classIndex[classId] ?: return@forEach
            classMaxPeriodsPerDay[idx] = value
        }

        val subjectDailyLimit = IntArray(classIds.size * subjectIds.size * days) { -1 }
        constraints.subjectDailyLimit.forEach { (key, value) ->
            val parts = key.split(":")
            if (parts.size != 2) return@forEach
            val classIdx = classIndex[parts[0]] ?: return@forEach
            val subjectIdx = subjectIndex[parts[1]] ?: return@forEach
            for (day in 0 until days) {
                subjectDailyLimit[((classIdx * subjectIds.size) + subjectIdx) * days + day] = value
            }
        }

        val teacherMaxConsecutive = IntArray(teacherIds.size) { -1 }
        constraints.teacherMaxConsecutivePeriods.forEach { (teacher, value) ->
            val idx = teacherIndex[teacher] ?: return@forEach
            teacherMaxConsecutive[idx] = value
        }

        val classMaxConsecutive = IntArray(classIds.size) { -1 }
        constraints.classMaxConsecutivePeriods.forEach { (classId, value) ->
            val idx = classIndex[classId] ?: return@forEach
            classMaxConsecutive[idx] = value
        }

        val teacherNoLastPeriodCap = IntArray(teacherIds.size) { -1 }
        constraints.teacherNoLastPeriodMaxPerWeek.forEach { (teacher, value) ->
            val idx = teacherIndex[teacher] ?: return@forEach
            teacherNoLastPeriodCap[idx] = value
        }

        val lessonAdjacencyDegree = IntArray(lessonCount)
        for (i in 0 until lessonCount) {
            var d = 0
            for (j in 0 until lessonCount) {
                if (i == j) continue
                if (overlapsTeachers(i, j, lessonTeacherStart, lessonTeacherCount, lessonTeacherFlat) ||
                    overlapsClasses(i, j, lessonClassStart, lessonClassCount, lessonClassFlat)
                ) {
                    d += 1
                }
            }
            lessonAdjacencyDegree[i] = d
        }

        val slotDay = IntArray(days * periodsPerDay)
        val slotPeriod = IntArray(days * periodsPerDay)
        for (d in 0 until days) {
            for (p in 0 until periodsPerDay) {
                val s = slotIndex(d, p, periodsPerDay)
                slotDay[s] = d
                slotPeriod[s] = p
            }
        }

        val weights = intArrayOf(
            constraints.softWeights["teacher_gaps"] ?: 1,
            constraints.softWeights["class_gaps"] ?: 1,
            constraints.softWeights["subject_distribution"] ?: 1,
            constraints.softWeights["teacher_room_stability"] ?: 1,
            constraints.softWeights["teacher_consecutive_overload"] ?: 1,
            constraints.softWeights["class_consecutive_overload"] ?: 1,
            constraints.softWeights["teacher_last_period_overflow"] ?: 1,
            constraints.softWeights["period_load_balance"] ?: ConstraintWeight.MED_SOFT.penalty,
        )

        return SolverModel(
            lessons = lessons,
            rooms = roomsResolved,
            constraints = constraints,
            days = days,
            periodsPerDay = periodsPerDay,
            lessonCount = lessonCount,
            teacherCount = teacherIds.size,
            classCount = classIds.size,
            roomCount = roomIds.size,
            subjectCount = subjectIds.size,
            teacherIds = teacherIds,
            classIds = classIds,
            roomIds = roomIds,
            subjectIds = subjectIds,
            lessonClassStart = lessonClassStart,
            lessonClassCount = lessonClassCount,
            lessonTeacherStart = lessonTeacherStart,
            lessonTeacherCount = lessonTeacherCount,
            lessonClassFlat = lessonClassFlat,
            lessonTeacherFlat = lessonTeacherFlat,
            lessonSubject = lessonSubject,
            lessonLabDouble = lessonLabDouble,
            lessonAttemptSlots = lessonAttemptSlots,
            lessonPinned = lessonPinned,
            fixedSlot = fixedSlot,
            lessonCandidateStart = lessonCandidateStart,
            lessonCandidateCount = lessonCandidateCount,
            candidateSlot = candidateSlot.toIntArray(),
            candidateRoom = candidateRoom.toIntArray(),
            teacherAvailabilityMask = teacherAvailabilityMask,
            classAvailabilityMask = classAvailabilityMask,
            roomAvailabilityMask = roomAvailabilityMask,
            teacherMaxPeriodsPerDay = teacherMaxPeriodsPerDay,
            classMaxPeriodsPerDay = classMaxPeriodsPerDay,
            subjectDailyLimit = subjectDailyLimit,
            teacherMaxConsecutive = teacherMaxConsecutive,
            classMaxConsecutive = classMaxConsecutive,
            teacherNoLastPeriodCap = teacherNoLastPeriodCap,
            lessonAdjacencyDegree = lessonAdjacencyDegree,
            slotDay = slotDay,
            slotPeriod = slotPeriod,
            periodPreferenceScores = PERIOD_PREFERENCE_SCORES,
            weights = weights,
            lessonIdToIndex = lessons.withIndex().associate { it.value.id to it.index },
            occStride = occStride,
            maxCandidatesPerLesson = maxCandidatesPerLesson,
        )
    }

    private fun resolveRoomCandidates(
        lesson: Lesson,
        roomById: Map<String, Room>,
        roomIndex: Map<String, Int>,
    ): IntArray {
        lesson.preferredRoomId?.let { preferred ->
            return roomIndex[preferred]?.let { intArrayOf(it) } ?: IntArray(0)
        }

        lesson.requiredRoomType?.let { req ->
            val matches = roomById.values.filter { it.roomType == req }.mapNotNull { roomIndex[it.id] }
            return matches.sorted().toIntArray()
        }

        return roomById.keys.mapNotNull { roomIndex[it] }.sorted().toIntArray()
    }

    private fun detectInfeasibleInput(
        lessons: List<Lesson>,
        classes: List<SchoolClass>,
        constraints: ConstraintConfig,
        days: Int,
        periodsPerDay: Int,
    ): String? {
        val defaultCapacityPerClass = days * periodsPerDay
        val classDemand = mutableMapOf<String, Int>()
        for (lesson in lessons) {
            val demand = if (lesson.isLabDouble) 2 else 1
            for (classId in lesson.classIds) {
                classDemand[classId] = (classDemand[classId] ?: 0) + demand
            }
        }
        val classAvailabilityById = classes.associateBy { it.id }
        for ((classId, demand) in classDemand) {
            val mask = classAvailabilityById[classId]?.availabilityMask
            val capacity = if (mask != null) java.lang.Long.bitCount(mask) * days else defaultCapacityPerClass
            if (demand > capacity) return "capacity_exceeded"
        }

        for ((teacherId, slots) in constraints.teacherAvailability) {
            val teacherDemand = lessons.filter { it.teacherIds.contains(teacherId) }.sumOf { if (it.isLabDouble) 2 else 1 }
            if (teacherDemand > slots.size) return "teacher_availability_insufficient"
        }
        return null
    }

    private fun scoreResult(hardViolations: Int, penalties: List<SoftPenalty>): Long {
        var soft = 0L
        for (i in penalties.indices) {
            val penalty = penalties[i]
            soft += penalty.penalty.toLong() * penalty.weight.toLong()
        }
        return -1_000_000_000L * hardViolations - soft
    }

    /**
     * Day-aligned occupancy index used by teacher/class/room `LongArray` masks:
     *   rowBase = entityIndex * stride
     *   idx = rowBase + dayIdx
     * `stride` may include cache-line padding (`alignedDayStride`) so each
     * entity-day segment maps to machine-word aligned storage.
     */
    private fun occIndex(entityIndex: Int, dayIdx: Int, stride: Int): Int {
        return entityIndex * stride + dayIdx
    }

    /**
     * Cache-line aligned stride: 8 Longs = 64 bytes per row chunk.
     * Padding reduces cache-line splits during day-level occupancy reads.
     */
    private fun alignedDayStride(days: Int): Int {
        val wordsPerCacheLine = 8
        val remainder = days % wordsPerCacheLine
        return if (remainder == 0) days else days + (wordsPerCacheLine - remainder)
    }

    private fun dayMask(periodsPerDay: Int): Long {
        return if (periodsPerDay == 64) -1L else (1L shl periodsPerDay) - 1L
    }

    private fun slotIndex(dayIdx: Int, periodIdx: Int, periodsPerDay: Int): Int {
        return dayIdx * periodsPerDay + periodIdx
    }

    private fun encodeResourceId(kind: Int, id: Int): Int {
        return (kind shl 24) or (id and 0x00FFFFFF)
    }

    private fun sparseKey(dayIdx: Int, periodIdx: Int, resourceId: Int, teacherId: Int): Long {
        val rid = resourceId.toLong() and 0xFFFF_FFFFL
        val tid = teacherId.toLong() and 0xFFFFL
        return (dayIdx.toLong() shl 40) or (periodIdx.toLong() shl 32) or (rid shl 16) or tid
    }

    private fun overlapsTeachers(
        i: Int,
        j: Int,
        lessonTeacherStart: IntArray,
        lessonTeacherCount: IntArray,
        lessonTeacherFlat: IntArray,
    ): Boolean {
        val si = lessonTeacherStart[i]
        val ci = lessonTeacherCount[i]
        val sj = lessonTeacherStart[j]
        val cj = lessonTeacherCount[j]
        for (a in 0 until ci) {
            val t = lessonTeacherFlat[si + a]
            for (b in 0 until cj) {
                if (lessonTeacherFlat[sj + b] == t) return true
            }
        }
        return false
    }

    private fun overlapsClasses(
        i: Int,
        j: Int,
        lessonClassStart: IntArray,
        lessonClassCount: IntArray,
        lessonClassFlat: IntArray,
    ): Boolean {
        val si = lessonClassStart[i]
        val ci = lessonClassCount[i]
        val sj = lessonClassStart[j]
        val cj = lessonClassCount[j]
        for (a in 0 until ci) {
            val c = lessonClassFlat[si + a]
            for (b in 0 until cj) {
                if (lessonClassFlat[sj + b] == c) return true
            }
        }
        return false
    }

    private fun decMap(map: MutableMap<String, Int>, key: String) {
        val v = (map[key] ?: 0) - 1
        if (v <= 0) map.remove(key) else map[key] = v
    }

    private fun mix64(z0: Long): Long {
        var z = z0 + 0x9E3779B97F4A7C15UL.toLong()
        z = (z xor (z ushr 30)) * 0xBF58476D1CE4E5B9UL.toLong()
        z = (z xor (z ushr 27)) * 0x94D049BB133111EBUL.toLong()
        return z xor (z ushr 31)
    }

    private fun deterministicStep(seed: Long, size: Int): Int {
        if (size <= 1) return 1
        var step = (mix64(seed).toInt() and Int.MAX_VALUE) % size
        if (step == 0) step = 1
        while (gcd(step, size) != 1) {
            step += 1
            if (step >= size) step = 1
        }
        return step
    }

    private fun gcd(a0: Int, b0: Int): Int {
        var a = a0
        var b = b0
        while (b != 0) {
            val t = a % b
            a = b
            b = t
        }
        return if (a >= 0) a else -a
    }

    companion object {
        const val VERSION = "kotlin-csp-2.1.0"
        private const val RESOURCE_TEACHER = 1
        private const val RESOURCE_CLASS = 2
        private const val RESOURCE_ROOM = 3

        private const val FAILURE_NO_FEASIBLE_SLOT = 0
        private const val FAILURE_TEACHER_CONFLICT = 1
        private const val FAILURE_TEACHER_UNAVAILABLE = 2
        private const val FAILURE_TEACHER_MAX_PER_DAY = 3
        private const val FAILURE_CLASS_CONFLICT = 4
        private const val FAILURE_CLASS_UNAVAILABLE = 5
        private const val FAILURE_CLASS_MAX_PER_DAY = 6
        private const val FAILURE_SUBJECT_DAILY_LIMIT = 7
        private const val FAILURE_ROOM_CONFLICT = 8
        private const val FAILURE_ROOM_UNAVAILABLE = 9
        private const val FAILURE_LAB_DOUBLE_OOB = 10
        private const val FAILURE_LAB_DOUBLE_TEACHER_CONFLICT = 11
        private const val FAILURE_LAB_DOUBLE_TEACHER_UNAVAILABLE = 12
        private const val FAILURE_LAB_DOUBLE_TEACHER_MAX_PER_DAY = 13
        private const val FAILURE_LAB_DOUBLE_CLASS_CONFLICT = 14
        private const val FAILURE_LAB_DOUBLE_CLASS_UNAVAILABLE = 15
        private const val FAILURE_LAB_DOUBLE_CLASS_MAX_PER_DAY = 16
        private const val FAILURE_LAB_DOUBLE_SUBJECT_DAILY_LIMIT = 17
        private const val FAILURE_LAB_DOUBLE_ROOM_CONFLICT = 18
        private const val FAILURE_LAB_DOUBLE_ROOM_UNAVAILABLE = 19
        private const val FAILURE_REASON_COUNT = 20
        private const val W_TEACHER_GAPS = 0
        private const val W_CLASS_GAPS = 1
        private const val W_SUBJECT_DISTRIBUTION = 2
        private const val W_TEACHER_ROOM = 3
        private const val W_TEACHER_CONSEC = 4
        private const val W_CLASS_CONSEC = 5
        private const val W_TEACHER_LAST = 6
        private const val W_PERIOD_LOAD = 7


        private val PERIOD_PREFERENCE_SCORES = intArrayOf(
            10, 15, 20, 25, 15, 49, 47, 7, 25, 5, 15, 38, 2, 9, 13, 10, 8, 11, 12, 59,
            10, 15, 20, 25, 15, 49, 47, 7, 25, 5, 15, 38, 2, 9, 13, 10, 8
        )
    }
}
