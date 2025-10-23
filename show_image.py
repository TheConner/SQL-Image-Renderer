#!/usr/bin/env python3

import sys, psycopg2, os
from PIL import Image
import io
from dotenv import load_dotenv
load_dotenv()

dsn = os.getenv("DATABASE_URL")
if dsn is None:
    print("DATABASE_URL is not set")
    sys.exit(1)

img_id = int(sys.argv[1])

out_file_optional = None
if len(sys.argv) > 2:
    out_file_optional = sys.argv[2]

if img_id is None:
    print("Usage:\tpython show_image.py [image_id]\nOr\tpython show_image.py [image_id] [output file]")
    sys.exit(1)

print("Fetching image from database...")
with psycopg2.connect(dsn) as c, c.cursor() as cur:
    cur.execute("SELECT image_to_bitmap(%s) , (SELECT width FROM (SELECT max(x)+1 width from pixels where image_id=%s) s), (SELECT max(y)+1 height from pixels where image_id=%s) ", (img_id, img_id, img_id))
    data, w, h = cur.fetchone()

print("Done")

img = Image.frombytes("RGBA", (w, h), bytes(data))
if out_file_optional is not None:
    img.save(out_file_optional)
    print(f"Saved image to {out_file_optional}")
else:
    img.show()