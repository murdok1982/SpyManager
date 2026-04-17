import pytest
from app.core.exceptions import ABACDeniedError
from app.core.abac_engine import ABACEngine, ClassificationPolicy, CaseAssignmentPolicy, AccessContext


def make_engine():
    return ABACEngine([ClassificationPolicy(), CaseAssignmentPolicy()])


class MockUser:
    def __init__(self, role, level, cases):
        self.role = role
        self.classification_level = level
        self.assigned_cases = cases
        self.is_active = True
        self.user_id = "test-user"


class MockResource:
    def __init__(self, level, case_id):
        self.classification_level = level
        self.case_id = case_id
        self.resource_id = "test-resource"
        self.owner_id = "other-user"


def test_user_can_read_assigned_case():
    engine = make_engine()
    user = MockUser("ANALISTA_CAMPO", 2, ["CASO_ALPHA"])
    resource = MockResource(2, "CASO_ALPHA")
    ctx = AccessContext(user=user, resource=resource, action="read")
    assert engine.evaluate(ctx) is True


def test_user_blocked_unassigned_case():
    engine = make_engine()
    user = MockUser("ANALISTA_CAMPO", 2, ["CASO_ALPHA"])
    resource = MockResource(2, "CASO_OMEGA")
    ctx = AccessContext(user=user, resource=resource, action="read")
    assert engine.evaluate(ctx) is False


def test_director_can_read_any_case():
    engine = make_engine()
    user = MockUser("DIRECTOR", 3, [])
    resource = MockResource(2, "CASO_OMEGA")
    ctx = AccessContext(user=user, resource=resource, action="read")
    assert engine.evaluate(ctx) is True


def test_insufficient_clearance_blocked():
    engine = make_engine()
    user = MockUser("ANALISTA_CAMPO", 1, ["CASO_ALPHA"])
    resource = MockResource(3, "CASO_ALPHA")
    ctx = AccessContext(user=user, resource=resource, action="read")
    assert engine.evaluate(ctx) is False


def test_write_requires_case_assignment():
    engine = make_engine()
    user = MockUser("ANALISTA_CAMPO", 3, ["CASO_ALPHA"])
    resource = MockResource(1, "CASO_OMEGA")
    ctx = AccessContext(user=user, resource=resource, action="write")
    assert engine.evaluate(ctx) is False


def test_admin_bypasses_case_restriction():
    engine = make_engine()
    user = MockUser("ADMIN", 3, [])
    resource = MockResource(3, "ANY_CASE")
    ctx = AccessContext(user=user, resource=resource, action="read")
    assert engine.evaluate(ctx) is True
