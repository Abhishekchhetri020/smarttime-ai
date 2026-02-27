import os, sys
from fastapi.testclient import TestClient

sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from main import app

client = TestClient(app)

def test_health():
    r = client.get('/health')
    assert r.status_code == 200
    assert r.json()['ok'] is True

def test_solve_basic():
    payload = {
        'schoolId': 'demo',
        'days': 5,
        'periodsPerDay': 8,
        'lessons': [
            {'id':'L1','classId':'VIII-A','teacherId':'T1','subjectId':'ENG'},
            {'id':'L2','classId':'VIII-A','teacherId':'T1','subjectId':'ENG'}
        ]
    }
    r = client.post('/solve', json=payload)
    assert r.status_code == 200
    data = r.json()
    assert 'assignments' in data
    assert data['schoolId'] == 'demo'
