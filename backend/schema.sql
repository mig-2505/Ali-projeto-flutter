-- Esquema do banco + dados iniciais (os mesmos que antes ficavam fixos no app).
-- Executado automaticamente pelo app.py quando o arquivo do banco ainda não existe.

PRAGMA foreign_keys = ON;

CREATE TABLE categories (
  id    TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  emoji TEXT NOT NULL
);

CREATE TABLE producers (
  id        INTEGER PRIMARY KEY,
  name      TEXT NOT NULL,
  specialty TEXT NOT NULL,
  avatar    TEXT NOT NULL,
  rating    REAL NOT NULL CHECK (rating BETWEEN 0 AND 5)
);

CREATE TABLE products (
  id          INTEGER PRIMARY KEY,
  name        TEXT NOT NULL,
  price       REAL NOT NULL CHECK (price >= 0),
  unit        TEXT NOT NULL,
  image       TEXT NOT NULL,
  tag         TEXT NOT NULL,
  tag_color   TEXT NOT NULL CHECK (tag_color IN ('primary', 'accent')),
  category_id TEXT NOT NULL REFERENCES categories (id),
  producer_id INTEGER NOT NULL REFERENCES producers (id)
);

CREATE TABLE orders (
  id         INTEGER PRIMARY KEY,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  total      REAL NOT NULL
);

CREATE TABLE order_items (
  order_id   INTEGER NOT NULL REFERENCES orders (id),
  product_id INTEGER NOT NULL REFERENCES products (id),
  qty        INTEGER NOT NULL CHECK (qty > 0),
  unit_price REAL NOT NULL,
  PRIMARY KEY (order_id, product_id)
);

INSERT INTO categories (id, label, emoji) VALUES
  ('hortalicas', 'Hortaliças', '🥬'),
  ('frutas', 'Frutas', '🍊'),
  ('laticinios', 'Laticínios', '🧀'),
  ('paes', 'Pães', '🍞'),
  ('mel', 'Mel & Geleias', '🍯');

INSERT INTO producers (id, name, specialty, avatar, rating) VALUES
  (1, 'Márcia Oliveira', 'Hortas Orgânicas', 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=80&h=80&fit=crop&auto=format', 4.9),
  (2, 'João Ferreira', 'Pães Artesanais', 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=80&h=80&fit=crop&auto=format', 5.0),
  (3, 'Família Tanaka', 'Frutas e Legumes', 'https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=80&h=80&fit=crop&auto=format', 4.8),
  (4, 'Luísa Mendes', 'Laticínios & Ovos', 'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=80&h=80&fit=crop&auto=format', 4.7);

INSERT INTO products (id, name, price, unit, image, tag, tag_color, category_id, producer_id) VALUES
  (1, 'Alface Crespa Orgânica', 4.5, 'pé', 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop&auto=format', 'Colhida hoje', 'primary', 'hortalicas', 1),
  (2, 'Pão de Fermentação Natural', 28.0, 'unid', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&h=300&fit=crop&auto=format', 'Mais vendido', 'accent', 'paes', 2),
  (3, 'Tangerina Ponkan', 9.9, 'kg', 'https://images.unsplash.com/photo-1557800636-894a64c1696f?w=400&h=300&fit=crop&auto=format', 'Temporada', 'primary', 'frutas', 3),
  (4, 'Queijo Minas Frescal', 18.5, '500g', 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=400&h=300&fit=crop&auto=format', 'Artesanal', 'accent', 'laticinios', 4),
  (5, 'Mel de Eucalipto Puro', 35.0, '500g', 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400&h=300&fit=crop&auto=format', 'Orgânico', 'primary', 'mel', 1),
  (6, 'Mix de Folhas Verdes', 7.0, 'bandeja', 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400&h=300&fit=crop&auto=format', 'S/ agrotóxico', 'primary', 'hortalicas', 3),
  (7, 'Goiaba Vermelha', 6.5, 'kg', 'https://images.unsplash.com/photo-1536511132770-e5058c7e8c46?w=400&h=300&fit=crop&auto=format', 'Novo', 'accent', 'frutas', 3),
  (8, 'Iogurte Natural Integral', 12.0, '500g', 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400&h=300&fit=crop&auto=format', 'Sem aditivos', 'primary', 'laticinios', 4);
