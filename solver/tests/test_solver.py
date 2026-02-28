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
