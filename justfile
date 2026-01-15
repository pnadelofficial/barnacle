# Barnacle workflow commands
# Run `just` (or `just --list`) to see available commands.

set shell := ["bash", "-eu", "-c"]

# Export these so recipes can read them as environment variables too.
set export

# ----------------------------
# Defaults (override like: MODEL=... OUT=... LOG_LEVEL=DEBUG just ocr <url> 5)
# ----------------------------

MODEL := "models/McCATMuS_nfd_nofix_V1.mlmodel"
OUT := "out.jsonl"
LOG_LEVEL := "INFO"

# Convenient default manifest for smoke tests
FIGGY_MANIFEST := "https://figgy.princeton.edu/concern/scanned_resources/22a5dd98-7a15-4ed9-bdbc-16bb4ae785b6/manifest"

# Default recipe: list commands
default:
    @just --list


#-----------------------------
# Environment
#-----------------------------

install:
    pdm install

python:
    pdm run python

shell:
    source .venv/bin/activate && exec bash


#-----------------------------
# Quality & tests
#-----------------------------

lint:
    pdm run ruff check src

format:
    pdm run ruff format src

test:
    pdm run pytest

check:
    just lint
    just test


# ----------------------------
# OCR (parameterized)
# ----------------------------

# Usage:
#   just ocr <MANIFEST_OR_COLLECTION>
#   just ocr <MANIFEST_OR_COLLECTION> 10
#   OUT=out10.jsonl just ocr <MANIFEST_OR_COLLECTION> 10
#   MODEL=models/Whatever.mlmodel LOG_LEVEL=DEBUG just ocr <MANIFEST_OR_COLLECTION> 5
ocr MANIFEST_OR_COLLECTION MAX_PAGES="2":
    pdm run barnacle ocr "{{MANIFEST_OR_COLLECTION}}" \
      --model "${MODEL}" \
      --out "${OUT}" \
      --max-pages "{{MAX_PAGES}}" \
      --log-level "${LOG_LEVEL}"

ocr-smoke:
    just ocr "${FIGGY_MANIFEST}" 2

ocr-10:
    just ocr "${FIGGY_MANIFEST}" 10


# ----------------------------
# Profiling / timing
# ----------------------------

# Usage:
#   just time-ocr <url> 5
time-ocr MANIFEST_OR_COLLECTION MAX_PAGES="2":
    /usr/bin/time -lp pdm run barnacle ocr "{{MANIFEST_OR_COLLECTION}}" \
      --model "${MODEL}" \
      --out "${OUT}" \
      --max-pages "{{MAX_PAGES}}" \
      --log-level "${LOG_LEVEL}"

# Usage:
#   just profile-ocr <url> 5
#
# This profiles the CLI entrypoint as executed by pdm.
# (We avoid assuming `python -m barnacle.cli` or `python -m barnacle` exists.)
profile-ocr MANIFEST_OR_COLLECTION MAX_PAGES="2" PROF="profile.prof":
    pdm run python -m cProfile -o "{{PROF}}" "$(pdm run which barnacle)" ocr "{{MANIFEST_OR_COLLECTION}}" \
      --model "${MODEL}" \
      --out "${OUT}" \
      --max-pages "{{MAX_PAGES}}" \
      --log-level "${LOG_LEVEL}"

profile-open PROF="profile.prof":
    pdm run python -m snakeviz "{{PROF}}"


# ----------------------------
# Release
# ----------------------------

build:
    pdm build

release-check:
    just lint
    just test
    just build

release:
    rm -rf dist
    pdm build
    ls -lah dist


# ----------------------------
# Docs
# ----------------------------

docs-list:
    find docs -maxdepth 3 -type f -name "*.md" -print

docs-serve PORT="8008":
    cd docs && python -m http.server "{{PORT}}"

docs-open:
    open docs/overview.md
    open docs/roadmap.md
    open docs/mvp/contracts.md


# ----------------------------
# Maintenance
# ----------------------------

clean-cache:
    rm -rf .barnacle-cache

clean:
    rm -rf .barnacle-cache out.jsonl

clean-all:
    rm -rf .barnacle-cache out.jsonl dist
