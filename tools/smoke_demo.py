"""Local demo-only runtime checks. Credentials/tokens are never printed."""

import json
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent.parent
BASE = "http://127.0.0.1:3001/api/v1"


def run():
    credentials = json.loads((ROOT / "artifacts/demo-accounts.json").read_text())
    operators = json.loads((ROOT / "admin/operators.json").read_text(encoding="utf-8"))[
        "demo"
    ]
    credentials["reviewer"] = {
        "email": "fooda",
        "password": operators["fooda"]["password"],
    }
    scenario = json.loads((ROOT / "artifacts/demo-scenario-results.json").read_text())
    sessions = {}

    def request(method, path, actor=None, body=None, expected=200):
        headers = {
            "Content-Type": "application/json",
            "User-Agent": "MyHome-runtime-check/1.0",
        }
        if actor:
            headers["Authorization"] = "Bearer " + sessions[actor]
        req = Request(
            BASE + path,
            method=method,
            headers=headers,
            data=json.dumps(body).encode() if body is not None else None,
        )
        try:
            with urlopen(req, timeout=15) as response:
                status, data = response.status, response.read()
        except HTTPError as error:
            status, data = error.code, error.read()
        assert status == expected, (
            f"{method} {path}: expected {expected}, received {status}"
        )
        return json.loads(data) if data else None

    request("GET", "/health")
    try:
        for actor in (
            "owner_all",
            "viewer",
            "student",
            "outsider",
            "reviewer",
            "field_agent",
            "document_reviewer",
        ):
            login = request("POST", "/auth/login", body=credentials[actor])
            sessions[actor] = login["accessToken"]
            if actor in ("field_agent", "document_reviewer"):
                assert login["user"]["staffRole"] == actor
        page = request("GET", "/properties/mine/page?group=sale", "owner_all")
        assert len(page["items"]) == 3 and page["next_cursor"]
        next_page = request(
            "GET",
            "/properties/mine/page?group=sale&cursor=" + page["next_cursor"],
            "owner_all",
        )
        assert len(next_page["items"]) == 2
        assert {
            p["availability"] for p in request("GET", "/favorites", "viewer")["items"]
        } == {
            "active",
            "paused",
            "sold",
            "rented",
        }
        staff = request("GET", "/admin/staff", "reviewer")["items"]
        assert sum(row["specialty"] == "admin" for row in staff) == 2
        assert any(row["specialty"] == "field_agent" for row in staff)
        assert any(row["specialty"] == "document_reviewer" for row in staff)
        trade = scenario["messaging"]["trade_conversation"]
        group = scenario["messaging"]["group_conversation"]
        for cid, actor in ((trade, "viewer"), (group, "student")):
            path = f"/conversations/{cid}/messages"
            text = (
                "DEMO runtime: supervised coordination stays inside this application."
            )
            messages = request("GET", path, actor)["items"]
            if not any(m["text"] == text for m in messages):
                request("POST", path, actor, {"text": text}, expected=201)
            request("POST", path, actor, {"text": "01012345678"}, expected=422)
            request("GET", path, "outsider", expected=404)
        deals = request("GET", "/deals", "viewer")["items"]
        detail = request("GET", f"/deals/{deals[0]['id']}", "viewer")
        assert (
            detail["buyer_fee"] == "5000.00" and detail["buyer_total"] == "1005000.00"
        )
        assert detail["seller_net"] == "995000.00" and detail["fee_total"] == "10000.00"
        assert detail["financial"]["no_additional_platform_fee"] is True
        request("GET", f"/deals/{detail['id']}/payment-qr", "viewer", expected=409)
        report = {
            "status": "pass",
            "api": BASE,
            "checks": [
                "restricted-role message insert/read",
                "server contact rejection",
                "group/deal isolation",
                "staff login",
                "3+2 portfolio pages",
                "favorite tombstones",
                "all-in fee shares",
                "unconfigured payment blocked",
            ],
        }
        (ROOT / "artifacts/all-in-demo-runtime.json").write_text(
            json.dumps(report, indent=2), encoding="utf-8"
        )
    finally:
        for actor in sessions:
            request("POST", "/auth/logout", actor, expected=204)
    print(json.dumps(report))


if __name__ == "__main__":
    run()
