CREATE TABLE images (
    image_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE pixels (
    image_id INTEGER NOT NULL REFERENCES images(image_id) ON DELETE CASCADE,
    x INTEGER NOT NULL,
    y INTEGER NOT NULL,
    r SMALLINT NOT NULL CHECK (r BETWEEN 0 AND 255),
    g SMALLINT NOT NULL CHECK (g BETWEEN 0 AND 255),
    b SMALLINT NOT NULL CHECK (b BETWEEN 0 AND 255),
    a SMALLINT NOT NULL CHECK (a BETWEEN 0 AND 255),
    PRIMARY KEY (image_id, x, y)
);

CREATE INDEX idx_pixels_image ON pixels (image_id);

-- Functions for converting between images and bitmaps
CREATE OR REPLACE FUNCTION image_to_bitmap(p_image_id INT)
RETURNS bytea
LANGUAGE plpgsql
AS $$
DECLARE
    result bytea := ''::bytea;
    px RECORD;
BEGIN
    FOR px IN
        SELECT r, g, b, a
        FROM pixels
        WHERE image_id = p_image_id
        ORDER BY y, x
    LOOP
        result := result
                 || decode(lpad(to_hex(px.r::int), 2, '0'), 'hex')
                 || decode(lpad(to_hex(px.g::int), 2, '0'), 'hex')
                 || decode(lpad(to_hex(px.b::int), 2, '0'), 'hex')
                 || decode(lpad(to_hex(px.a::int), 2, '0'), 'hex');
    END LOOP;

    RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION bitmap_to_image(
    p_name   TEXT,
    p_bitmap BYTEA,
    p_width  INT,
    p_height INT
) RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    img_id INT;
    byte_offset INT := 0;
    x INT;
    y INT;
    r INT;
    g INT;
    b INT;
    a INT;
    expected_size INT := p_width * p_height * 4;
BEGIN
    IF octet_length(p_bitmap) <> expected_size THEN
        RAISE EXCEPTION 'Bitmap length % does not match expected size % for %x% image',
            octet_length(p_bitmap), expected_size, p_width, p_height;
    END IF;

    INSERT INTO images(name) VALUES (p_name) RETURNING image_id INTO img_id;

    FOR y IN 0..p_height - 1 LOOP
        FOR x IN 0..p_width - 1 LOOP
            r := get_byte(p_bitmap, byte_offset);
            g := get_byte(p_bitmap, byte_offset + 1);
            b := get_byte(p_bitmap, byte_offset + 2);
            a := get_byte(p_bitmap, byte_offset + 3);

            INSERT INTO pixels(image_id, x, y, r, g, b, a)
            VALUES (img_id, x, y, r, g, b, a);

            byte_offset := byte_offset + 4;
        END LOOP;
    END LOOP;

    RETURN img_id;
END;
$$;
