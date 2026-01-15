# Barnacle workflow commands
# Run `just` to list available commands

set shell := ["bash", "-eu", "-c"]

# Export these so recipes can read them as environment variables too.
set export

# Defaults (can be overridden when invoking `just`, e.g. `MODEL=... just ocr ...`)
MODEL := "models/McCATMuS_nfd_nofix_V1.mlmodel"
OUT := "out.jsonl"
LOG_LEVEL := "INFO"

# A convenient default manifest for smoke tests
FIGGY_MANIFEST := "https://figgy.princeton.edu/concern/scanned_resources/22a5dd98-7a15-4ed9-bdbc-16bb4ae785b6/manifest"


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


# ----------------------------
# OCR (parameterized)
# ----------------------------

# Usage:
#   just ocr <MANIFEST_OR_COLLECTION>
#   just ocr <MANIFEST_OR_COLLECTION> 10
#   MODEL=models/McCATMuS_nfd_nofix_V1.mlmodel OUT=out.jsonl just ocr <url> 5
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
profile-ocr MANIFEST_OR_COLLECTION MAX_PAGES="2" PROF="profile.prof":
    pdm run python -m cProfile -o "{{PROF}}" -m barnacle.cli ocr "{{MANIFEST_OR_COLLECTION}}" \
      --model "${MODEL}" \
      --out "${OUT}" \
      --max-pages "{{MAX_PAGES}}" \
      --log-level "${LOG_LEVEL}"


profile-open PROF="profile.prof":
    pdm run python -m snakeviz "{{PROF}}"

# ----------------------------
# Maintenance
# ----------------------------

clean-cache:
    rm -rf .barnacle-cache

clean:
    rm -rf .barnacle-cache out.jsonl

