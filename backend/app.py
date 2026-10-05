"""API do Ali: Flask + SQLite (arquivo local)."""

import os
import sqlite3

from flask import Flask, g, jsonify, request

HERE = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.environ.get("DB_PATH", os.path.join(HERE, "ali.db"))

app = Flask(__name__)
app.json.ensure_ascii = False  # acentos legíveis no JSON (ex.: "Hortaliças" em vez de "Hortaliças")


def init_db():
    """Cria o banco a partir do schema.sql se o arquivo ainda não existir."""
    if os.path.exists(DB_PATH):
        return
    conn = sqlite3.connect(DB_PATH)
    with open(os.path.join(HERE, "schema.sql"), encoding="utf-8") as f:
        conn.executescript(f.read())
    conn.close()


def db():
    """Uma conexão por requisição, fechada no teardown."""
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
        g.db.execute("PRAGMA foreign_keys = ON")
    return g.db


@app.teardown_appcontext
def close_db(_exc):
    conn = g.pop("db", None)
    if conn is not None:
        conn.close()


@app.after_request
def cors(resp):
    # O app web roda em outra porta, então o navegador exige CORS.
    resp.headers["Access-Control-Allow-Origin"] = "*"
    resp.headers["Access-Control-Allow-Headers"] = "Content-Type"
    return resp


def query(sql, *args):
    return [dict(r) for r in db().execute(sql, args)]


@app.get("/")
def index():
    return jsonify(api="Ali", rotas=["GET /categories", "GET /producers", "GET /products",
                                     "GET /orders", "POST /orders"])


@app.get("/categories")
def list_categories():
    return jsonify(query("SELECT id, label, emoji FROM categories ORDER BY rowid"))


@app.get("/producers")
def list_producers():
    return jsonify(query("SELECT id, name, specialty, avatar, rating FROM producers ORDER BY id"))


@app.get("/products")
def list_products():
    return jsonify(query("""
        SELECT p.id, p.name, pr.name AS producer, p.price, p.unit,
               p.category_id AS category, p.image, p.tag, p.tag_color
        FROM products p
        JOIN producers pr ON pr.id = p.producer_id
        ORDER BY p.id
    """))


@app.post("/orders")
def create_order():
    items = (request.get_json(silent=True) or {}).get("items")
    if not isinstance(items, list) or not items:
        return jsonify(error="Envie {items: [{product_id, qty}]}"), 400
    try:
        qtys = {}
        for item in items:
            pid, qty = int(item["product_id"]), int(item["qty"])
            qtys[pid] = qtys.get(pid, 0) + qty
    except (KeyError, TypeError, ValueError):
        return jsonify(error="Item inválido"), 400
    if any(q <= 0 for q in qtys.values()):
        return jsonify(error="Quantidade deve ser maior que zero"), 400

    # Preço vem do banco, nunca do cliente.
    conn = db()
    marks = ",".join("?" * len(qtys))
    prices = {r["id"]: r["price"] for r in
              conn.execute(f"SELECT id, price FROM products WHERE id IN ({marks})", list(qtys))}
    if len(prices) != len(qtys):
        return jsonify(error="Produto inexistente"), 400

    total = round(sum(prices[pid] * q for pid, q in qtys.items()), 2)
    with conn:  # transação: grava tudo ou nada
        order_id = conn.execute("INSERT INTO orders (total) VALUES (?)", (total,)).lastrowid
        conn.executemany(
            "INSERT INTO order_items (order_id, product_id, qty, unit_price) VALUES (?, ?, ?, ?)",
            [(order_id, pid, q, prices[pid]) for pid, q in qtys.items()],
        )
    return jsonify(id=order_id, total=total), 201


@app.get("/orders")
def list_orders():
    orders = query("SELECT id, created_at, total FROM orders ORDER BY id DESC")
    # ponytail: uma consulta por pedido (N+1); trocar por um JOIN se o histórico crescer.
    for o in orders:
        o["items"] = query("""
            SELECT oi.product_id, p.name, oi.qty, oi.unit_price
            FROM order_items oi JOIN products p ON p.id = oi.product_id
            WHERE oi.order_id = ?
        """, o["id"])
    return jsonify(orders)


init_db()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
