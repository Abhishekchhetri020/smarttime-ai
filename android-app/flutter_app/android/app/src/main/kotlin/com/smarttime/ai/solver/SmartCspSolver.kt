package com.smarttime.ai.solver

import kotlin.math.max

/**
 * Deterministic offline CSP solver for school timetables.
 *
 * Search strategy:
 *  - Backtracking with forward checking
 *  - Variable ordering: MRV, tie-broken by Degree heuristic
 *  - Value ordering: deterministic (day, period, room)
 */
class SmartCspSolver {
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
        // Backward-compatible constructor for legacy 1:1 lesson payloads/tests.
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
        val id: String,
        val roomType: String? = null,
    )

    data class ConstraintConfig(
        val teacherAvailability: Map<String, Set<SlotKey>> = emptyMap(),
        val teacherMaxPeriodsPerDay: Map<String, Int> = emptyMap(),
        val classMaxPeriodsPerDay: Map<String, Int> = emptyMap(),
        val fixedPeriods: Map<String, SlotKey> = emptyMap(),
        val subjectDailyLimit: Map<String, Int> = emptyMap(), // classId:subjectId -> limit
        val teacherMaxConsecutivePeriods: Map<String, Int> = emptyMap(),
        val classMaxConsecutivePeriods: Map<String, Int> = emptyMap(),
        val teacherNoLastPeriodMaxPerWeek: Map<String, Int> = emptyMap(),
        val softWeights: Map<String, Int> = defaultSoftWeights,
    ) {
        companion object {
            val defaultSoftWeights: Map<String, Int> = mapOf(
                "teacher_gaps" to 5,
                "class_gaps" to 5,
                "subject_distribution" to 3,
                "teacher_room_stability" to 1,
                "teacher_consecutive_overload" to 4,
                "class_consecutive_overload" to 3,
                "teacher_last_period_overflow" to 2,
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

    private data class Candidate(val slot: Slot, val roomId: String)

    private data class MutableState(
        val teacherSlot: MutableSet<Triple<String, Int, Int>> = mutableSetOf(),
        val classSlot: MutableSet<Triple<String, Int, Int>> = mutableSetOf(),
        val roomSlot: MutableSet<Triple<String, Int, Int>> = mutableSetOf(),
        val teacherDayLoad: MutableMap<Pair<String, Int>, Int> = mutableMapOf(),
        val classDayLoad: MutableMap<Pair<String, Int>, Int> = mutableMapOf(),
        val classSubjectDayCount: MutableMap<Triple<String, String, Int>, Int> = mutableMapOf(),
        val teacherDayPeriods: MutableMap<Pair<String, Int>, MutableSet<Int>> = mutableMapOf(),
        val classDayPeriods: MutableMap<Pair<String, Int>, MutableSet<Int>> = mutableMapOf(),
        val teacherLastPeriodCount: MutableMap<String, Int> = mutableMapOf(),
        val teacherRooms: MutableMap<String, MutableSet<String>> = mutableMapOf(),
        val assignments: MutableList<Assignment> = mutableListOf(),
    )

    private data class SearchContext(
        val lessons: List<Lesson>,
        val rooms: List<Room>,
        val constraints: ConstraintConfig,
        val days: Int,
        val periodsPerDay: Int,
        val slotUniverse: List<Slot>,
        val lessonAdjacencyDegree: Map<String, Int>,
    )

    private data class SearchStatsMutable(
        var nodesVisited: Int = 0,
        var backtracks: Int = 0,
        var branchesPrunedByForwardCheck: Int = 0,
        var timedOut: Boolean = false,
    )

    private data class Best(
        var assignments: List<Assignment> = emptyList(),
        var hardViolations: List<HardViolation> = emptyList(),
        var softPenalties: List<SoftPenalty> = emptyList(),
        var score: Long = Long.MIN_VALUE,
    )

    fun solve(
        lessons: List<Lesson>,
        rooms: List<Room>,
        constraints: ConstraintConfig = ConstraintConfig(),
        days: Int = 5,
        periodsPerDay: Int = 8,
        pinned: List<Assignment> = emptyList(),
        progressCallback: ProgressCallback? = null,
        timeoutMs: Long = 15_000L,
    ): SolveResult {
        require(days > 0) { "days must be > 0" }
        require(periodsPerDay > 0) { "periodsPerDay must be > 0" }

        val preCheck = detectInfeasibleInput(lessons, constraints, days, periodsPerDay)
        if (preCheck != null) {
            return SolveResult(
                status = "SEED_INFEASIBLE_INPUT",
                assignments = emptyList(),
                hardViolations = emptyList(),
                softPenaltyBreakdown = emptyList(),
                diagnostics = Diagnostics(
                    solverVersion = VERSION,
                    unscheduledReasonCounts = mapOf(preCheck to 1),
                    totals = Totals(lessonsRequested = lessons.size, assignedEntries = 0, hardViolations = 0),
                    search = SearchStats(nodesVisited = 0, backtracks = 0, branchesPrunedByForwardCheck = 0),
                ),
                score = Long.MIN_VALUE,
            )
        }

        val deadlineNanos = System.nanoTime() + timeoutMs.coerceAtLeast(1L) * 1_000_000L

        val slotUniverse = buildList {
            for (d in 1..days) {
                for (p in 1..periodsPerDay) {
                    add(Slot(d, p))
                }
            }
        }

        val context = SearchContext(
            lessons = lessons.sortedBy { it.id },
            rooms = rooms.sortedBy { it.id },
            constraints = constraints,
            days = days,
            periodsPerDay = periodsPerDay,
            slotUniverse = slotUniverse,
            lessonAdjacencyDegree = buildLessonDegrees(lessons),
        )

        val state = MutableState()
        val initiallyAssignedLessonIds = mutableSetOf<String>()

        for (pin in pinned.sortedBy { it.lessonId }) {
            val lesson = context.lessons.firstOrNull { it.id == pin.lessonId } ?: continue
            placeSingle(
                lesson = lesson,
                slot = Slot(pin.day, pin.period),
                roomId = pin.roomId,
                state = state,
                periodsPerDay = periodsPerDay,
                pinned = true,
            )
            initiallyAssignedLessonIds.add(lesson.id)
        }

        val fixedAssignments = mutableMapOf<String, Candidate>()
        for (lesson in context.lessons) {
            val forced = constraints.fixedPeriods[lesson.id]
            val day = forced?.day ?: lesson.fixedDay
            val period = forced?.period ?: lesson.fixedPeriod
            if (day != null && period != null) {
                val room = resolveRoomCandidates(lesson, context.rooms).firstOrNull()
                if (room != null) {
                    fixedAssignments[lesson.id] = Candidate(Slot(day, period), room.id)
                }
            }
        }

        val unassigned = context.lessons.filterNot { initiallyAssignedLessonIds.contains(it.id) }.map { it.id }.toMutableSet()
        val hardViolations = mutableListOf<HardViolation>()
        val unscheduledReasons = mutableMapOf<String, Int>()
        val stats = SearchStatsMutable()

        val baseDomain = mutableMapOf<String, List<Candidate>>()
        for (lessonId in unassigned) {
            val lesson = context.lessons.first { it.id == lessonId }
            val candidates = buildDomainForLesson(lesson, context, fixedAssignments[lesson.id])
            baseDomain[lessonId] = candidates
            if (candidates.isEmpty()) {
                val reason = if (resolveRoomCandidates(lesson, context.rooms).isEmpty()) {
                    "no_matching_room_type"
                } else {
                    "no_feasible_slot"
                }
                hardViolations += HardViolation(
                    lessonId = lesson.id,
                    classId = lesson.primaryClassId,
                    teacherId = lesson.primaryTeacherId,
                    subjectId = lesson.subjectId,
                    reason = reason,
                    attemptedSlots = 0,
                )
                unscheduledReasons[reason] = (unscheduledReasons[reason] ?: 0) + 1
            }
        }
        unassigned.removeAll(hardViolations.map { it.lessonId }.toSet())

        val best = Best()

        backtrack(
            context = context,
            state = state,
            unassigned = unassigned,
            baseDomains = baseDomain,
            hardViolations = hardViolations,
            unscheduledReasons = unscheduledReasons,
            stats = stats,
            best = best,
            progressCallback = progressCallback,
            deadlineNanos = deadlineNanos,
        )

        val finalPenalties = evaluateSoftPenalties(best.assignments, constraints, periodsPerDay)
        val finalDiagnostics = Diagnostics(
            solverVersion = VERSION,
            unscheduledReasonCounts = unscheduledReasons.toSortedMap(),
            totals = Totals(
                lessonsRequested = lessons.size,
                assignedEntries = best.assignments.size,
                hardViolations = best.hardViolations.size,
            ),
            search = SearchStats(
                nodesVisited = stats.nodesVisited,
                backtracks = stats.backtracks,
                branchesPrunedByForwardCheck = stats.branchesPrunedByForwardCheck,
            ),
        )

        val status = when {
            stats.timedOut && best.assignments.isNotEmpty() -> "SEED_TIMEOUT"
            stats.timedOut -> "SEED_TIMEOUT"
            best.hardViolations.isEmpty() -> "SEED_FOUND"
            else -> "SEED_NOT_FOUND"
        }

        return SolveResult(
            status = status,
            assignments = best.assignments.sortedWith(compareBy({ it.day }, { it.period }, { it.lessonId })),
            hardViolations = best.hardViolations,
            softPenaltyBreakdown = finalPenalties,
            diagnostics = finalDiagnostics,
            score = scoreResult(best.hardViolations.size, finalPenalties),
        )
    }

    private fun backtrack(
        context: SearchContext,
        state: MutableState,
        unassigned: MutableSet<String>,
        baseDomains: Map<String, List<Candidate>>,
        hardViolations: MutableList<HardViolation>,
        unscheduledReasons: MutableMap<String, Int>,
        stats: SearchStatsMutable,
        best: Best,
        progressCallback: ProgressCallback?,
        deadlineNanos: Long,
    ) {
        if (stats.timedOut) return
        if (System.nanoTime() >= deadlineNanos) {
            stats.timedOut = true
            return
        }

        stats.nodesVisited += 1
        progressCallback?.onProgress(
            Progress(
                nodesVisited = stats.nodesVisited,
                assignedLessons = context.lessons.size - unassigned.size,
                totalLessons = context.lessons.size,
                backtracks = stats.backtracks,
            ),
        )

        if (unassigned.isEmpty()) {
            val penalties = evaluateSoftPenalties(state.assignments, context.constraints, context.periodsPerDay)
            val score = scoreResult(hardViolations.size, penalties)
            if (score > best.score) {
                best.assignments = state.assignments.toList()
                best.hardViolations = hardViolations.toList()
                best.softPenalties = penalties
                best.score = score
            }
            return
        }

        // Forward checking for current state.
        val computedDomains = mutableMapOf<String, List<Pair<Candidate, String>>>()
        for (lessonId in unassigned) {
            val lesson = context.lessons.first { it.id == lessonId }
            val candidates = baseDomains[lessonId].orEmpty().mapNotNull { c ->
                val reason = canPlace(lesson, c.slot, c.roomId, state, context)
                if (reason == null) c to "" else null
            }
            if (candidates.isEmpty()) {
                stats.branchesPrunedByForwardCheck += 1
                // treat this lesson as unscheduled in this branch and continue
                val reason = dominantFailureReason(lesson, baseDomains[lessonId].orEmpty(), state, context)
                unassigned.remove(lessonId)
                hardViolations += HardViolation(
                    lessonId = lesson.id,
                    classId = lesson.primaryClassId,
                    teacherId = lesson.primaryTeacherId,
                    subjectId = lesson.subjectId,
                    reason = reason,
                    attemptedSlots = baseDomains[lessonId].orEmpty().size,
                )
                unscheduledReasons[reason] = (unscheduledReasons[reason] ?: 0) + 1
                backtrack(context, state, unassigned, baseDomains, hardViolations, unscheduledReasons, stats, best, progressCallback, deadlineNanos)
                unscheduledReasons[reason] = max(0, (unscheduledReasons[reason] ?: 1) - 1)
                if ((unscheduledReasons[reason] ?: 0) == 0) {
                    unscheduledReasons.remove(reason)
                }
                hardViolations.removeLast()
                unassigned.add(lessonId)
                return
            }
            computedDomains[lessonId] = candidates
        }

        val selectedLessonId = selectByMrvDegree(unassigned, computedDomains, context.lessonAdjacencyDegree)
        val lesson = context.lessons.first { it.id == selectedLessonId }
        val candidates = computedDomains[selectedLessonId].orEmpty().map { it.first }

        if (candidates.isEmpty()) {
            stats.backtracks += 1
            return
        }

        unassigned.remove(selectedLessonId)
        for (candidate in candidates) {
            val placements = placeLesson(lesson, candidate.slot, candidate.roomId, state, context)
            if (placements.isEmpty()) {
                continue
            }

            backtrack(context, state, unassigned, baseDomains, hardViolations, unscheduledReasons, stats, best, progressCallback, deadlineNanos)
            removePlacements(placements, state, context.periodsPerDay)
            if (stats.timedOut) break
        }
        unassigned.add(selectedLessonId)
        stats.backtracks += 1
    }

    private fun buildDomainForLesson(
        lesson: Lesson,
        context: SearchContext,
        fixed: Candidate?,
    ): List<Candidate> {
        val roomCandidates = resolveRoomCandidates(lesson, context.rooms)
        if (roomCandidates.isEmpty()) return emptyList()

        val slotCandidates = if (fixed != null) {
            listOf(fixed.slot)
        } else {
            context.slotUniverse
        }

        return buildList {
            for (slot in slotCandidates.sortedWith(compareBy({ it.day }, { it.period }))) {
                if (lesson.isLabDouble && slot.period >= context.periodsPerDay) continue
                for (room in roomCandidates) {
                    add(Candidate(slot, room.id))
                }
            }
        }
    }

    private fun resolveRoomCandidates(lesson: Lesson, rooms: List<Room>): List<Room> {
        lesson.preferredRoomId?.let { pref ->
            val exact = rooms.firstOrNull { it.id == pref }
            return if (exact != null) listOf(exact) else listOf(Room(pref))
        }

        lesson.requiredRoomType?.let { reqType ->
            return rooms.filter { it.roomType == reqType }
        }

        return if (rooms.isEmpty()) {
            listOf(Room("room_${lesson.primaryClassId}"))
        } else {
            rooms
        }
    }

    private fun canPlace(
        lesson: Lesson,
        slot: Slot,
        roomId: String,
        state: MutableState,
        context: SearchContext,
    ): String? {
        val firstReason = canPlaceSingleSlot(lesson, slot, roomId, state, context)
        if (firstReason != null) return firstReason

        if (lesson.isLabDouble) {
            if (slot.period >= context.periodsPerDay) return "lab_double_out_of_bounds"
            val next = Slot(slot.day, slot.period + 1)
            val secondReason = canPlaceSingleSlot(lesson, next, roomId, state, context)
            if (secondReason != null) return "lab_double_$secondReason"
        }

        return null
    }

    private fun canPlaceSingleSlot(
        lesson: Lesson,
        slot: Slot,
        roomId: String,
        state: MutableState,
        context: SearchContext,
    ): String? {
        for (teacherId in lesson.teacherIds) {
            val tk = Triple(teacherId, slot.day, slot.period)
            if (state.teacherSlot.contains(tk)) return "teacher_conflict"

            val availability = context.constraints.teacherAvailability[teacherId]
            if (availability != null && !availability.contains(SlotKey(slot.day, slot.period))) {
                return "teacher_unavailable"
            }

            val tMax = context.constraints.teacherMaxPeriodsPerDay[teacherId]
            if (tMax != null && (state.teacherDayLoad[teacherId to slot.day] ?: 0) >= tMax) {
                return "teacher_max_periods_per_day"
            }
        }

        for (classId in lesson.classIds) {
            val ck = Triple(classId, slot.day, slot.period)
            if (state.classSlot.contains(ck)) return "class_conflict"

            val cMax = context.constraints.classMaxPeriodsPerDay[classId]
            if (cMax != null && (state.classDayLoad[classId to slot.day] ?: 0) >= cMax) {
                return "class_max_periods_per_day"
            }

            val subjKey = "${classId}:${lesson.subjectId}"
            val subjLimit = context.constraints.subjectDailyLimit[subjKey]
            if (subjLimit != null && (state.classSubjectDayCount[Triple(classId, lesson.subjectId, slot.day)] ?: 0) >= subjLimit) {
                return "subject_daily_limit"
            }
        }

        val rk = Triple(roomId, slot.day, slot.period)
        if (state.roomSlot.contains(rk)) return "room_conflict"

        return null
    }

    private fun placeLesson(
        lesson: Lesson,
        slot: Slot,
        roomId: String,
        state: MutableState,
        context: SearchContext,
    ): List<Assignment> {
        val placements = mutableListOf<Assignment>()
        val reason = canPlace(lesson, slot, roomId, state, context)
        if (reason != null) return emptyList()

        if (lesson.isLabDouble) {
            val second = Slot(slot.day, slot.period + 1)
            placements += placeSingle(lesson, slot, roomId, state, context.periodsPerDay, pinned = false)
            placements += placeSingle(lesson, second, roomId, state, context.periodsPerDay, pinned = false)
            return placements
        }

        placements += placeSingle(lesson, slot, roomId, state, context.periodsPerDay, pinned = false)
        return placements
    }

    private fun placeSingle(
        lesson: Lesson,
        slot: Slot,
        roomId: String,
        state: MutableState,
        periodsPerDay: Int,
        pinned: Boolean,
    ): Assignment {
        val a = Assignment(
            lessonId = lesson.id,
            classIds = lesson.classIds,
            teacherIds = lesson.teacherIds,
            subjectId = lesson.subjectId,
            day = slot.day,
            period = slot.period,
            roomId = roomId,
            pinned = pinned,
            isLabDouble = lesson.isLabDouble,
        )

        state.assignments += a
        for (teacherId in a.teacherIds) {
            state.teacherSlot += Triple(teacherId, a.day, a.period)
            state.teacherDayLoad[teacherId to a.day] = (state.teacherDayLoad[teacherId to a.day] ?: 0) + 1
            state.teacherDayPeriods.getOrPut(teacherId to a.day) { mutableSetOf() }.add(a.period)
            state.teacherRooms.getOrPut(teacherId) { mutableSetOf() }.add(a.roomId)
            if (a.period == periodsPerDay) {
                state.teacherLastPeriodCount[teacherId] = (state.teacherLastPeriodCount[teacherId] ?: 0) + 1
            }
        }

        for (classId in a.classIds) {
            state.classSlot += Triple(classId, a.day, a.period)
            state.classDayLoad[classId to a.day] = (state.classDayLoad[classId to a.day] ?: 0) + 1
            state.classSubjectDayCount[Triple(classId, a.subjectId, a.day)] =
                (state.classSubjectDayCount[Triple(classId, a.subjectId, a.day)] ?: 0) + 1
            state.classDayPeriods.getOrPut(classId to a.day) { mutableSetOf() }.add(a.period)
        }

        state.roomSlot += Triple(a.roomId, a.day, a.period)
        return a
    }

    private fun removePlacements(placements: List<Assignment>, state: MutableState, periodsPerDay: Int) {
        for (a in placements.asReversed()) {
            state.assignments.removeLast()
            state.roomSlot.remove(Triple(a.roomId, a.day, a.period))

            for (teacherId in a.teacherIds) {
                state.teacherSlot.remove(Triple(teacherId, a.day, a.period))
                decMap(state.teacherDayLoad, teacherId to a.day)
                state.teacherDayPeriods[teacherId to a.day]?.let {
                    it.remove(a.period)
                    if (it.isEmpty()) state.teacherDayPeriods.remove(teacherId to a.day)
                }
                if (a.period == periodsPerDay) {
                    decMap(state.teacherLastPeriodCount, teacherId)
                }

                val teacherRemainingRooms = state.assignments
                    .filter { it.teacherIds.contains(teacherId) }
                    .map { it.roomId }
                    .toSet()
                if (teacherRemainingRooms.isEmpty()) {
                    state.teacherRooms.remove(teacherId)
                } else {
                    state.teacherRooms[teacherId] = teacherRemainingRooms.toMutableSet()
                }
            }

            for (classId in a.classIds) {
                state.classSlot.remove(Triple(classId, a.day, a.period))
                decMap(state.classDayLoad, classId to a.day)
                decMap(state.classSubjectDayCount, Triple(classId, a.subjectId, a.day))
                state.classDayPeriods[classId to a.day]?.let {
                    it.remove(a.period)
                    if (it.isEmpty()) state.classDayPeriods.remove(classId to a.day)
                }
            }
        }
    }

    private fun dominantFailureReason(
        lesson: Lesson,
        domain: List<Candidate>,
        state: MutableState,
        context: SearchContext,
    ): String {
        if (domain.isEmpty()) return "no_feasible_slot"
        val counts = mutableMapOf<String, Int>()
        for (candidate in domain) {
            val reason = canPlace(lesson, candidate.slot, candidate.roomId, state, context) ?: continue
            counts[reason] = (counts[reason] ?: 0) + 1
        }
        return counts.maxByOrNull { it.value }?.key ?: "no_feasible_slot"
    }

    private fun selectByMrvDegree(
        unassigned: Set<String>,
        domains: Map<String, List<Pair<Candidate, String>>>,
        degree: Map<String, Int>,
    ): String {
        return unassigned.minWithOrNull(
            compareBy<String> { domains[it]?.size ?: Int.MAX_VALUE }
                .thenByDescending { degree[it] ?: 0 }
                .thenBy { it },
        ) ?: throw IllegalStateException("No unassigned lessons to select")
    }

    private fun buildLessonDegrees(lessons: List<Lesson>): Map<String, Int> {
        val result = mutableMapOf<String, Int>()
        for (lesson in lessons) {
            val d = lessons.count {
                it.id != lesson.id &&
                    (it.teacherIds.any { t -> lesson.teacherIds.contains(t) } ||
                        it.classIds.any { c -> lesson.classIds.contains(c) })
            }
            result[lesson.id] = d
        }
        return result
    }

    private fun evaluateSoftPenalties(
        assignments: List<Assignment>,
        constraints: ConstraintConfig,
        periodsPerDay: Int,
    ): List<SoftPenalty> {
        val byTeacherDay = mutableMapOf<Pair<String, Int>, MutableList<Int>>()
        val byClassDay = mutableMapOf<Pair<String, Int>, MutableList<Int>>()
        val byClassSubjectDay = mutableMapOf<Triple<String, String, Int>, Int>()
        val teacherRooms = mutableMapOf<String, MutableSet<String>>()
        val teacherLastPeriodCounts = mutableMapOf<String, Int>()

        for (a in assignments) {
            for (teacherId in a.teacherIds) {
                byTeacherDay.getOrPut(teacherId to a.day) { mutableListOf() }.add(a.period)
                teacherRooms.getOrPut(teacherId) { mutableSetOf() }.add(a.roomId)
                if (a.period == periodsPerDay) {
                    teacherLastPeriodCounts[teacherId] = (teacherLastPeriodCounts[teacherId] ?: 0) + 1
                }
            }
            for (classId in a.classIds) {
                byClassDay.getOrPut(classId to a.day) { mutableListOf() }.add(a.period)
                byClassSubjectDay[Triple(classId, a.subjectId, a.day)] =
                    (byClassSubjectDay[Triple(classId, a.subjectId, a.day)] ?: 0) + 1
            }
        }

        fun gapPenalty(groups: Map<*, MutableList<Int>>): Int {
            var p = 0
            for (periods in groups.values) {
                val sorted = periods.sorted()
                for (i in 0 until (sorted.size - 1)) {
                    p += max(0, sorted[i + 1] - sorted[i] - 1)
                }
            }
            return p
        }

        var subjectDistributionPenalty = 0
        for (count in byClassSubjectDay.values) {
            if (count > 2) subjectDistributionPenalty += (count - 2)
        }

        var teacherRoomPenalty = 0
        for (rooms in teacherRooms.values) {
            if (rooms.size > 1) teacherRoomPenalty += (rooms.size - 1)
        }

        var teacherConsecutivePenalty = 0
        for ((key, periods) in byTeacherDay) {
            val teacher = key.first
            val limit = constraints.teacherMaxConsecutivePeriods[teacher] ?: continue
            teacherConsecutivePenalty += overloadPenalty(periods, limit)
        }

        var classConsecutivePenalty = 0
        for ((key, periods) in byClassDay) {
            val classId = key.first
            val limit = constraints.classMaxConsecutivePeriods[classId] ?: continue
            classConsecutivePenalty += overloadPenalty(periods, limit)
        }

        var teacherLastPeriodPenalty = 0
        for ((teacher, count) in teacherLastPeriodCounts) {
            val cap = constraints.teacherNoLastPeriodMaxPerWeek[teacher] ?: continue
            if (count > cap) teacherLastPeriodPenalty += (count - cap)
        }

        fun w(type: String): Int = constraints.softWeights[type] ?: 1

        return listOf(
            SoftPenalty("teacher_gaps", gapPenalty(byTeacherDay), w("teacher_gaps")),
            SoftPenalty("class_gaps", gapPenalty(byClassDay), w("class_gaps")),
            SoftPenalty("subject_distribution", subjectDistributionPenalty, w("subject_distribution")),
            SoftPenalty("teacher_room_stability", teacherRoomPenalty, w("teacher_room_stability")),
            SoftPenalty("teacher_consecutive_overload", teacherConsecutivePenalty, w("teacher_consecutive_overload")),
            SoftPenalty("class_consecutive_overload", classConsecutivePenalty, w("class_consecutive_overload")),
            SoftPenalty("teacher_last_period_overflow", teacherLastPeriodPenalty, w("teacher_last_period_overflow")),
        )
    }

    private fun overloadPenalty(periods: List<Int>, limit: Int): Int {
        if (periods.isEmpty() || limit <= 0) return 0
        val sorted = periods.distinct().sorted()
        var penalty = 0
        var run = 1
        for (i in 1 until sorted.size) {
            if (sorted[i] == sorted[i - 1] + 1) {
                run += 1
            } else {
                if (run > limit) penalty += (run - limit)
                run = 1
            }
        }
        if (run > limit) penalty += (run - limit)
        return penalty
    }

    private fun scoreResult(hardViolations: Int, penalties: List<SoftPenalty>): Long {
        val soft = penalties.sumOf { it.penalty.toLong() * it.weight.toLong() }
        return -1_000_000_000L * hardViolations - soft
    }

    private fun <K> decMap(map: MutableMap<K, Int>, key: K) {
        val v = (map[key] ?: 0) - 1
        if (v <= 0) map.remove(key) else map[key] = v
    }

    private fun detectInfeasibleInput(
        lessons: List<Lesson>,
        constraints: ConstraintConfig,
        days: Int,
        periodsPerDay: Int,
    ): String? {
        val capacityPerClass = days * periodsPerDay
        val classDemand = mutableMapOf<String, Int>()
        for (lesson in lessons) {
            val demand = if (lesson.isLabDouble) 2 else 1
            for (classId in lesson.classIds) {
                classDemand[classId] = (classDemand[classId] ?: 0) + demand
            }
        }
        if (classDemand.any { it.value > capacityPerClass }) return "capacity_exceeded"

        for ((teacherId, slots) in constraints.teacherAvailability) {
            val teacherDemand = lessons
                .filter { it.teacherIds.contains(teacherId) }
                .sumOf { if (it.isLabDouble) 2 else 1 }
            if (teacherDemand > slots.size) return "teacher_availability_insufficient"
        }

        return null
    }

    companion object {
        const val VERSION = "kotlin-csp-1.1.0"
    }
}
