# Barnacle workflow commands
# Run `just` to list available commands

set shell := ["bash", "-eu"]

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


# ----------------------------
# OCR workflows
# ----------------------------


ocr-smoke:
    pdm run barnacle ocr \
      https://figgy.princeton.edu/concern/scanned_resources/22a5dd98-7a15-4ed9-bdbc-16bb4ae785b6/manifest \
      --model models/McCATMuS_nfd_nofix_V1.mlmodel \
      --out out.jsonl \
      --max-pages 2 \
      --log-level INFO

ocr-10:
    pdm run barnacle ocr \
      https://figgy.princeton.edu/concern/scanned_resources/22a5dd98-7a15-4ed9-bdbc-16bb4ae785b6/manifest \
      --model models/McCATMuS_nfd_nofix_V1.mlmodel \
      --out out.jsonl \
      --max-pages 10 \
      --log-level INFO



# ----------------------------
# Maintenance
# ----------------------------

clean-cache:
    rm -rf .barnacle-cache

clean:
    rm -rf .barnacle-cache out.jsonl