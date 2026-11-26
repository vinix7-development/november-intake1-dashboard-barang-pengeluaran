-- Dashboard Barang Masuk, Keluar, dan Pengeluaran: skema awal PostgreSQL (nominal rupiah, BIGINT)
CREATE TABLE users (
    id             BIGSERIAL PRIMARY KEY,
    name           TEXT NOT NULL,
    email          TEXT NOT NULL UNIQUE,
    password_hash  TEXT NOT NULL,
    role           TEXT NOT NULL CHECK (role IN ('pemilik', 'staf')),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE categories (
    id    BIGSERIAL PRIMARY KEY,
    name  TEXT NOT NULL UNIQUE
);

CREATE TABLE suppliers (
    id     BIGSERIAL PRIMARY KEY,
    name   TEXT NOT NULL,
    phone  TEXT
);

CREATE TABLE products (
    id           BIGSERIAL PRIMARY KEY,
    category_id  BIGINT REFERENCES categories(id),
    sku          TEXT NOT NULL UNIQUE,
    name         TEXT NOT NULL,
    unit         TEXT NOT NULL DEFAULT 'pcs',
    buy_price    BIGINT NOT NULL DEFAULT 0 CHECK (buy_price >= 0),
    stock        INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    min_stock    INTEGER NOT NULL DEFAULT 0 CHECK (min_stock >= 0),
    archived_at  TIMESTAMPTZ
);

CREATE TABLE stock_movements (
    id           BIGSERIAL PRIMARY KEY,
    product_id   BIGINT NOT NULL REFERENCES products(id),
    user_id      BIGINT NOT NULL REFERENCES users(id),
    supplier_id  BIGINT REFERENCES suppliers(id),
    direction    TEXT NOT NULL CHECK (direction IN ('masuk', 'keluar')),
    reason       TEXT CHECK (reason IN ('terjual', 'rusak', 'retur')),
    qty          INTEGER NOT NULL CHECK (qty > 0),
    unit_price   BIGINT CHECK (unit_price >= 0),   -- harga beli saat barang masuk
    moved_on     DATE NOT NULL DEFAULT CURRENT_DATE,
    note         TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (
        (direction = 'masuk'  AND unit_price IS NOT NULL AND reason IS NULL) OR
        (direction = 'keluar' AND reason IS NOT NULL AND supplier_id IS NULL)
    )
);

CREATE TABLE expense_categories (
    id    BIGSERIAL PRIMARY KEY,
    name  TEXT NOT NULL UNIQUE
);

CREATE TABLE expenses (          -- hanya biaya operasional, bukan pembelian barang
    id           BIGSERIAL PRIMARY KEY,
    category_id  BIGINT NOT NULL REFERENCES expense_categories(id),
    user_id      BIGINT NOT NULL REFERENCES users(id),
    amount       BIGINT NOT NULL CHECK (amount > 0),
    spent_on     DATE NOT NULL DEFAULT CURRENT_DATE,
    note         TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_mov_product_date ON stock_movements (product_id, moved_on DESC);
CREATE INDEX idx_mov_date ON stock_movements (moved_on);
CREATE INDEX idx_expenses_date ON expenses (spent_on);

-- Pengeluaran total = pembelian barang + operasional
CREATE VIEW v_pengeluaran AS
SELECT moved_on AS tanggal, 'pembelian_barang' AS jenis, qty * unit_price AS nominal
FROM stock_movements WHERE direction = 'masuk'
UNION ALL
SELECT spent_on, 'operasional', amount FROM expenses;
