#!/usr/bin/env python3

import sys, psycopg2, os
from PIL import Image
from psycopg2 import Binary
from dotenv import load_dotenv
load_dotenv()

p = sys.argv[1]
if p is None:
    print("Usage: python load_bitmap.py [path to image]")
    sys.exit(1)

img = Image.open(p).convert("RGBA")
w, h = img.size
bits = img.tobytes()
dsn = os.getenv("DATABASE_URL")
if dsn is None:
    print("DATABASE_URL is not set")
    sys.exit(1)

print("Writing to database...")
with psycopg2.connect(dsn) as c, c.cursor() as cur:
    cur.execute("SELECT bitmap_to_image(%s,%s,%s,%s)", (p, Binary(bits), w, h))
    print(cur.fetchone()[0])
print("Done")