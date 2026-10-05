"""Teste rápido da API, roda com: python test_app.py"""

import os
import tempfile

os.environ["DB_PATH"] = os.path.join(tempfile.mkdtemp(), "test.db")

from app import app  # noqa: E402 (DB_PATH precisa existir antes do import)

c = app.test_client()

assert c.get("/").status_code == 200

assert len(c.get("/categories").json) == 5
assert c.get("/products").json[0]["producer"] == "Márcia Oliveira"

# Total calculado no servidor: 2 x 4.5 + 1 x 28.0 = 37.0
r = c.post("/orders", json={"items": [{"product_id": 1, "qty": 2}, {"product_id": 2, "qty": 1}]})
assert r.status_code == 201 and r.json["total"] == 37.0, r.json

assert c.post("/orders", json={"items": [{"product_id": 999, "qty": 1}]}).status_code == 400
assert c.post("/orders", json={"items": [{"product_id": 1, "qty": 0}]}).status_code == 400
assert c.post("/orders", json={}).status_code == 400

orders = c.get("/orders").json
assert len(orders) == 1 and len(orders[0]["items"]) == 2

print("ok")
