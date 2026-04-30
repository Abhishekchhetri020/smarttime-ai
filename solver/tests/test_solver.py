import os
import sys
from fastapi.testclient import TestClient

sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from main import app

client = TestClient(app)


def test_health():
    r = client.get('/health')
    assert r.status_code == 200
    assert r.json()['ok'] is True


def test_solve_basic_reproducible():
    payload = {
        'schoolId': 'demo',
        'days': 5,
        'periodsPerDay': 8,
        'seed': 11,
        'constraints': {
            'teacherAvailability': {
                'T1': [{'day': 1, 'period': 1}, {'day': 1, 'period': 2}, {'day': 2, 'period': 1}],
            },
            'teacherMaxPeriodsPerDay': {'T1': 2},
            'classMaxPeriodsPerDay': {'VII-A': 4},
        },
        'lessons': [
            {'id': 'L1', 'classId': 'VII-A', 'teacherId': 'T1', 'subjectId': 'MATH'},
            {'id': 'L2', 'classId': 'VII-A', 'teacherId': 'T1', 'subjectId': 'MATH'},
            {'id': 'L3', 'classId': 'VII-A', 'teacherId': 'T1', 'subjectId': 'MATH'},
        ],
    }
    r1 = client.post('/solve', json=payload)
    r2 = client.post('/solve', json=payload)
    assert r1.status_code == 200
    assert r2.status_code == 200
    assert r1.json()['assignments'] == r2.json()['assignments']


def test_unscheduled_conflict_diagnostics_present():
    payload = {
        'schoolId': 'demo',
        'days': 1,
        'periodsPerDay': 1,
        'constraints': {
            'teacherMaxPeriodsPerDay': {'T1': 1},
        },
        'lessons': [
            {'id': 'L1', 'classId': 'VII-A', 'teacherId': 'T1', 'subjectId': 'SCI'},
            {'id': 'L2', 'classId': 'VII-B', 'teacherId': 'T1', 'subjectId': 'SCI'},
        ],
    }
    r = client.post('/solve', json=payload)
    assert r.status_code == 200
    data = r.json()
    assert data['status'] == 'partial'
    assert len(data['hardViolations']) >= 1
    assert data['hardViolations'][0]['type'] == 'unscheduled_lesson'
    assert 'reason' in data['hardViolations'][0]


def test_lab_double_period_respected():
    payload = {
        'schoolId': 'demo',
        'days': 1,
        'periodsPerDay': 2,
        'lessons': [
            {'id': 'LAB1', 'classId': 'VII-A', 'teacherId': 'T2', 'subjectId': 'LAB', 'isLabDouble': True}
        ],
    }
    r = client.post('/solve', json=payload)
    assert r.status_code == 200
    data = r.json()
    assert data['status'] == 'success'
    assert len(data['assignments']) == 2
    periods = sorted([a['period'] for a in data['assignments']])
    assert periods == [1, 2]


def test_required_room_type_enforced():
    payload = {
        'schoolId': 'demo',
        'days': 1,
        'periodsPerDay': 2,
        'rooms': [{'id': 'R1', 'roomType': 'classroom'}],
        'lessons': [
            {'id': 'LAB1', 'classId': 'VII-A', 'teacherId': 'T2', 'subjectId': 'LAB', 'requiredRoomType': 'lab'}
        ],
    }
    r = client.post('/solve', json=payload)
    assert r.status_code == 200
    data = r.json()
    assert data['status'] == 'partial'
    assert data['hardViolations'][0]['reason'] == 'no_matching_room_type'


def test_subject_daily_limit_hard_constraint():
    payload = {
        'schoolId': 'demo',
        'days': 1,
        'periodsPerDay': 3,
        'constraints': {'subjectDailyLimit': {'VII-A:MATH': 1}},
        'lessons': [
            {'id': 'L1', 'classId': 'VII-A', 'teacherId': 'T1', 'subjectId': 'MATH'},
            {'id': 'L2', 'classId': 'VII-A', 'teacherId': 'T2', 'subjectId': 'MATH'},
        ],
    }
    r = client.post('/solve', json=payload)
    assert r.status_code == 200
    data = r.json()
    assert data['status'] == 'partial'
    assert any(v['reason'] == 'subject_daily_limit' for v in data['hardViolations'])


def test_diagnostics_present_with_optimization_summary():
    payload = {
        'schoolId': 'demo',
        'days': 2,
        'periodsPerDay': 3,
        'constraints': {'teacherNoLastPeriodMaxPerWeek': {'T1': 0}},
        'lessons': [
            {'id': 'L1', 'classId': 'VII-A', 'teacherId': 'T1', 'subjectId': 'MATH'},
            {'id': 'L2', 'classId': 'VII-B', 'teacherId': 'T1', 'subjectId': 'SCI'},
        ],
    }
    r = client.post('/solve', json=payload)
    assert r.status_code == 200
    data = r.json()
    assert 'diagnostics' in data
    assert 'optimization' in data['diagnostics']
    assert 'unscheduledReasonCounts' in data['diagnostics']


def test_consecutive_overflow_counts_each_run_once():
    # 4-period run with limit=2 should contribute (4-2)=2, not 8.
    payload = {
        'schoolId': 'demo',
        'days': 1,
        'periodsPerDay': 4,
        'constraints': {
            'teacherMaxConsecutivePeriods': {'T1': 2},
        },
        'lessons': [
            {'id': 'L1', 'classId': 'VII-A', 'teacherId': 'T1', 'subjectId': 'MATH'},
            {'id': 'L2', 'classId': 'VII-B', 'teacherId': 'T1', 'subjectId': 'MATH'},
            {'id': 'L3', 'classId': 'VII-C', 'teacherId': 'T1', 'subjectId': 'MATH'},
            {'id': 'L4', 'classId': 'VII-D', 'teacherId': 'T1', 'subjectId': 'MATH'},
        ],
    }
    r = client.post('/solve', json=payload)
    data = r.json()
    overload = next(p for p in data['softPenaltyBreakdown'] if p['type'] == 'teacher_consecutive_overload')
    assert overload['penalty'] == 2


def test_fixed_periods_via_constraints_are_prioritized():
    # constraints.fixedPeriods entries must win their slot even when other
    # lessons would otherwise be placed there first.
    payload = {
        'schoolId': 'demo',
        'days': 1,
        'periodsPerDay': 1,
        'seed': 0,
        'constraints': {
            'fixedPeriods': {'L_FIXED': {'day': 1, 'period': 1}},
        },
        'lessons': [
            {'id': 'L_OTHER', 'classId': 'VII-A', 'teacherId': 'T1', 'subjectId': 'MATH'},
            {'id': 'L_FIXED', 'classId': 'VII-A', 'teacherId': 'T2', 'subjectId': 'SCI'},
        ],
    }
    r = client.post('/solve', json=payload)
    data = r.json()
    placed = {a['lessonId']: a for a in data['assignments']}
    assert 'L_FIXED' in placed
    assert placed['L_FIXED']['day'] == 1 and placed['L_FIXED']['period'] == 1


def test_invalid_days_returns_400():
    payload = {'schoolId': 'demo', 'days': 0, 'periodsPerDay': 1, 'lessons': []}
    r = client.post('/solve', json=payload)
    assert r.status_code == 400


def test_pin_out_of_range_reported_as_invalid_pin():
    payload = {
        'schoolId': 'demo',
        'days': 1,
        'periodsPerDay': 2,
        'lessons': [],
        'pinned': [
            {'lessonId': 'P1', 'classId': 'VII-A', 'teacherId': 'T1', 'subjectId': 'MATH', 'day': 1, 'period': 5},
        ],
    }
    r = client.post('/solve', json=payload)
    data = r.json()
    assert data['status'] == 'partial'
    assert any(v['type'] == 'invalid_pin' and v['reason'] == 'pin_out_of_range' for v in data['hardViolations'])


def test_pinned_lab_double_reserves_both_slots():
    # A pinned lab-double at (1,1) must protect both period 1 and period 2;
    # a subsequent lesson on the same teacher/class cannot land at (1,2).
    payload = {
        'schoolId': 'demo',
        'days': 1,
        'periodsPerDay': 2,
        'lessons': [
            {'id': 'L_OTHER', 'classId': 'VII-A', 'teacherId': 'T1', 'subjectId': 'MATH'},
        ],
        'pinned': [
            {
                'lessonId': 'P_LAB',
                'classId': 'VII-A',
                'teacherId': 'T1',
                'subjectId': 'LAB',
                'day': 1,
                'period': 1,
                'isLabDouble': True,
            },
        ],
    }
    r = client.post('/solve', json=payload)
    data = r.json()
    pin_slots = sorted(
        (a['day'], a['period']) for a in data['assignments'] if a.get('lessonId') == 'P_LAB'
    )
    assert pin_slots == [(1, 1), (1, 2)]
    other_slots = [(a['day'], a['period']) for a in data['assignments'] if a.get('lessonId') == 'L_OTHER']
    assert (1, 2) not in other_slots
    assert any(v.get('lessonId') == 'L_OTHER' for v in data['hardViolations'])
