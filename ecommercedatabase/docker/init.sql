-- สร้างฐานข้อมูล
CREATE DATABASE music_store;

-- ใช้งานฐานข้อมูลที่สร้าง
\c music_store;

-- สร้าง Extension สำหรับ UUID (เฉพาะ PostgreSQL)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- สร้าง ENUM สำหรับ status และ product_type
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'product_status') THEN
        CREATE TYPE product_status AS ENUM ('active', 'inactive');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'product_type') THEN
        CREATE TYPE product_type AS ENUM ('vinyl', 'instrument', 'equipment');
    END IF;
END$$;

-- เริ่มต้น Transaction
BEGIN;

-- สร้างตาราง categories
CREATE TABLE IF NOT EXISTS categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    parent_category_id INTEGER,
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL
);

-- สร้างตาราง sellers
CREATE TABLE IF NOT EXISTS sellers (
    seller_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    contact_info VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- สร้างตาราง products
CREATE TABLE IF NOT EXISTS products (
    product_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    brand VARCHAR(255),
    model_number VARCHAR(100),
    sku VARCHAR(100) UNIQUE NOT NULL,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    status product_status NOT NULL,
    seller_id UUID NOT NULL,
    category_id INTEGER NOT NULL,
    product_type product_type NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);

-- สร้างตาราง vinyls
CREATE TABLE IF NOT EXISTS vinyls (
    vinyl_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL UNIQUE,
    artist VARCHAR(255) NOT NULL,
    release_year INTEGER NOT NULL,
    genre VARCHAR(255) NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- สร้างตาราง instruments
CREATE TABLE IF NOT EXISTS instruments (
    instrument_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL UNIQUE,
    instrument_type VARCHAR(100),
    warranty_period VARCHAR(50),
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- สร้างตาราง equipments
CREATE TABLE IF NOT EXISTS equipments (
    equipments_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL UNIQUE,
    equipment_type VARCHAR(100) NOT NULL,
    dimensions VARCHAR(100) NOT NULL,
    warranty_period VARCHAR(50),
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- สร้างตาราง product_images
CREATE TABLE IF NOT EXISTS product_images (
    image_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    alt_text VARCHAR(255),
    is_primary BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- สร้างตาราง product_options
CREATE TABLE IF NOT EXISTS product_options (
    option_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    values JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- สร้างตาราง inventory
CREATE TABLE IF NOT EXISTS inventory (
    product_id UUID PRIMARY KEY,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- สร้างฟังก์ชันสำหรับอัปเดตฟิลด์ updated_at อัตโนมัติ
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
   RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- สร้าง Trigger สำหรับตารางที่มีฟิลด์ updated_at
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_sellers_updated_at BEFORE UPDATE ON sellers
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_product_images_updated_at BEFORE UPDATE ON product_images
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_product_options_updated_at BEFORE UPDATE ON product_options
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON inventory
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- เพิ่มข้อมูลตาราง categories
INSERT INTO categories (name, description, parent_category_id) VALUES
('แผ่นเสียง', 'แผ่นเสียงทุกประเภท', NULL),
('อุปกรณ์ดนตรี', 'เครื่องดนตรีประเภทต่างๆ', NULL),
('อุปกรณ์เครื่องเสียง', 'อุปกรณ์เกี่ยวกับระบบเสียง', NULL),
('กีต้าร์', 'กีตาร์ไฟฟ้าและอคูสติก', 2),
('เบส', 'เบสไฟฟ้าและอคูสติก', 2),
('กลอง', 'กลองชุดและอุปกรณ์', 2),
('ไมโครโฟน', 'ไมโครโฟนทุกประเภท', 3),
('ลำโพง', 'ลำโพงและตู้แอมป์', 3);

-- เพิ่มข้อมูลตาราง sellers
INSERT INTO sellers (seller_id, name, description, contact_info) 
VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Vinyl Paradise', 'ร้านแผ่นเสียงและอุปกรณ์ดนตรีคุณภาพ นำเข้าจากต่างประเทศ', 'vinylparadise@gmail.com'),
('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'Melody Master', 'ศูนย์รวมเครื่องดนตรีคุณภาพ', 'melodymaster@gmail.com'),
('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'Vintage Vinyl', 'ร้านแผ่นเสียงมือสองคุณภาพเยี่ยม', 'vintagevinyl@gmail.com'),
('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Sound Studio', 'ศูนย์รวมอุปกรณ์สตูดิโอ', 'soundstudio@gmail.com'),
('e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a55', 'Harmony Hub', 'ร้านเครื่องดนตรีครบวงจร', 'harmonyhub@gmail.com');

-- ตัวอย่างการเพิ่มข้อมูล
-- **ข้อมูลเพิ่มเติมที่นี่ตามโค้ดที่ให้ไว้ด้านบน**
COMMIT;




-- ข้อมูลผลิตภัณฑ์และตารางที่เกี่ยวข้อง
-- vinyls 1 ร้าน3
INSERT INTO products (name, description, brand, model_number, sku, price, status, seller_id, category_id, product_type)
VALUES ( 
        'Abbey Road', 
        'แผ่นเสียง The Beatles รีมาสเตอร์', 
        'The Beatles', 
        'VN01', 
        'VN01-001', 
        1790.00, 
        'active', 
        'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 
        1, 
        'vinyl');
INSERT INTO vinyls (product_id, artist, release_year, genre)
VALUES ((SELECT product_id FROM products WHERE sku = 'VN01-001'),
        'The Beatles', 
        1969 , 
        'Rock');
INSERT INTO inventory (product_id, quantity)
VALUES ((SELECT product_id FROM products WHERE sku = 'VN01-001'), 150);
--('V02', 'Pink Floyd - Dark Side of The Moon', 'แผ่นเสียง Pink Floyd คลาสสิก', 'Pink Floyd', 'VP-VIN-002', 2500.00, 'active', 'S01', 3, 'vinyl_record'),
--('V03', 'Miles Davis - Kind of Blue', 'แผ่นเสียงแจ๊สคลาสสิก', 'Columbia', 'VV-VIN-001', 15000.00, 'active', 'S03', 3, 'vinyl_record'),
--('V04', 'John Coltrane - A Love Supreme', 'แผ่นเสียงแจ๊สหายาก', 'Impulse!', 'VV-VIN-002', 18000.00, 'active', 'S03', 3, 'vinyl_record');

-- instruments
INSERT INTO products ( name, description, brand, model_number, sku, price, status, seller_id, category_id, product_type)
VALUES (
        'Fender Stratocaster', 
        'กีตาร์ไฟฟ้า Fender รุ่น Classic', 
        'Fender', 
        'GU01', 
        'GU01-001', 
        24999.00, 
        'active', 
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 
        4, 
        'instrument');
INSERT INTO instruments (product_id, instrument_type,warranty_period)
VALUES ((SELECT product_id FROM products WHERE sku = 'GU01-001'),
        'กีตาร์ไฟฟ้า', 
        '3 ปี');
INSERT INTO inventory (product_id, quantity)
VALUES ((SELECT product_id FROM products WHERE sku = 'GU01-001'), 15);

-- equipments
INSERT INTO products ( name, description, brand, model_number, sku, price, status, seller_id, category_id, product_type)
VALUES (
        'Shure SM58', 
        'ไมโครโฟนระดับมืออาชีพ', 
        'Shure', 
        'MI01', 
        'MI01-001', 
        1290.00, 
        'active', 
        'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 
        7, 
        'equipment');
INSERT INTO equipments (product_id,equipment_type ,dimensions,warranty_period)
VALUES ((SELECT product_id FROM products WHERE sku = 'MI01-001'),
        'ไมโครโฟนสตูดิโอ',
        '162x51mm', 
        '2 ปี');
INSERT INTO inventory (product_id, quantity)
VALUES ((SELECT product_id FROM products WHERE sku = 'MI01-001'), 50);

-- เพิ่มข้อมูลตาราง product_images
INSERT INTO product_images (product_id, image_url, alt_text, is_primary, sort_order)
VALUES 
((SELECT product_id FROM products WHERE sku = 'VN01-001'), 'https://example.com/images/Abbey-Road-1.jpg', 'Abbey Road หน้า', TRUE, 1),
((SELECT product_id FROM products WHERE sku = 'VN01-001'), 'https://example.com/images/Abbey-Road-2.jpg', 'Abbey Road หลัง', FALSE, 2);

-- เพิ่มข้อมูล product_options
INSERT INTO product_options (product_id, name, values, created_at, updated_at)
VALUES 
((SELECT product_id FROM products WHERE sku = 'GU01-001'), 'สี', '["ดำ", "ขาว", "ฟ้า"]'::jsonb, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
((SELECT product_id FROM products WHERE sku = 'VN01-001'), 'ประเภท', '["มือ1", ",มือ2"]'::jsonb, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- เพิ่มข้อมูลหนังสือใหม่
INSERT INTO products (
    name, 
    description, 
    brand, 
    model_number, 
    sku, 
    price, 
    status, 
    seller_id, 
    category_id, 
    product_type)
VALUES (
    'Fender Precision Bass', 
    'เบสไฟฟ้า Fender รุ่นคลาสสิก ', 
    'Fender', 
    'BA01', 
    'BA01-001', 
    15990.00, 
    'active', 
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 
    5, 
    'instrument'
);

INSERT INTO instruments (
    product_id, 
    instrument_type,
    warranty_period)
VALUES (
    (SELECT product_id FROM products WHERE sku = 'BA01-001'), 
    'เบสไฟฟ้า', 
    '2 ปี');
INSERT INTO inventory (product_id, quantity)
VALUES ((SELECT product_id FROM products WHERE sku = 'BA01-001'), 15);

INSERT INTO product_images (product_id, image_url, alt_text, is_primary, sort_order)
VALUES 
((SELECT product_id FROM products WHERE sku = 'BA01-001'), 'https://example.com/images/Fender-Precision-Bass-front.jpg', 'ตัวเบสด้านหน้า', TRUE, 1),
((SELECT product_id FROM products WHERE sku = 'BA01-001'), 'https://example.com/images/Fender-Precision-Bass-back.jpg', 'ตัวเบสด้านหลัง', FALSE, 2);

INSERT INTO product_options (product_id, name, values, created_at, updated_at)
VALUES 
((SELECT product_id FROM products WHERE sku = 'BA01-001'), 'สี', '["ดำ", "ขาว", "แดง"]'::jsonb, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
COMMIT;