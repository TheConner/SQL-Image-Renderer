#!/usr/bin/env bash
set -euo pipefail

psql "postgresql://postgres:password@localhost:5432/postgres" -f sql/00-schema.sql
