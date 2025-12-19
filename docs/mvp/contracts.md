# Barnacle MVP Contracts

This document defines the stable “contracts”[^1] between the three MVP layers:

- **IIIF models** (`barnacle_iiif.v2`)
- **ATR engines** (`barnacle_atr`)
- **Pipeline** (`barnacle_pipeline`)

The goal is to let each layer evolve independently while keeping interfaces stable.

---

## 1. IIIF traversal contract (Presentation 2.1)

### 1.1 Inputs
- A IIIF Presentation 2.1 **Manifest URI** (HTTP(S)).
- Optional: a local manifest JSON file path.

### 1.2 Core data contract

#### `Manifest` must provide
- **Identity**
  - `id: str` (from `@id`)
  - `type: Literal["sc:Manifest"]`
- **Label**
  - `label: str | dict | list` (raw)
  - `best_label() -> str`
    - Returns a human-readable label suitable for filenames, logging, and reports.
    - Language selection and normalization are implementation-defined.
- **Metadata**
  - `metadata: list[MetadataEntry] | None`
- **Sequences**
  - `sequences: list[Sequence]`
- **Traversal helper**
  - `canvases() -> Iterable[Canvas]`
    - Yields canvases in reading order (sequence order, then canvas order).

#### `Canvas` must provide
- `id: str`
- `label: str | dict | list | None`
- `width: int | None`, `height: int | None`
- `images: list[Annotation]`
- Optional: `rendering`

#### `Annotation` must provide
- `resource: ImageResource`
- `on: str | None`

#### `ImageResource` must provide
- `service: ImageService | list[ImageService] | None`
- `width: int | None`, `height: int | None`
- `format: str | None`

#### `ImageService` must provide
- `id: str`
- `profile`
- `context`

### 1.3 Image URL resolution

- `Canvas.primary_image_service() -> ImageService | None`
- `Canvas.image_request_url(...) -> str`

Default request:
```
{service_id}/full/full/0/default.jpg
```

### 1.4 I/O

- `load_manifest(uri: str) -> Manifest`
- `dump_manifest(manifest: Manifest, path: Path) -> None`

---

## 2. ATR engine contract

### 2.1 `ATREngine`

```
recognize(image: ImageInput, *, context: ATRContext | None) -> ATRResult
```

### 2.2 `ImageInput`
- `Path`
- `URL`
- `bytes`
- `BinaryIO`

### 2.3 `ATRContext`
Optional metadata:
- manifest URI
- canvas ID
- page index
- cache key
- language hint

### 2.4 `ATRResult`
Required:
- `text: str`
- `engine: str`
- `engine_config: str`
  - Deterministic fingerprint of the engine configuration, suitable for cache keys and provenance tracking.

Optional:
- `engine_version`
- `model_id`
- `models`
- `elapsed_ms`
- `warnings`
- `data` (structured OCR output)

---

## 3. Kraken engine contract

### 3.1 ModelRef

A recognition model may be specified by:
- DOI (Zenodo)
- installed model name
- filesystem path

Exactly one concrete model resolution must be possible before recognition begins.

### 3.2 `KrakenConfig`
- `model: ModelRef | None`
- `models: dict[str, ModelRef] | None`
- `multi_model: bool`
- `model_auto_install: bool = True`
- `cache_dir: Path | None`
- `return_structure: bool = False`

Exactly one of `model` or `models` must be set.

### 3.3 Model resolution
If a DOI is supplied and the model is not installed:
- run `kraken get <doi>`
- resolve installed model name/path
- record DOI + resolved name for reproducibility

---

## 4. Pipeline contract

### 4.1 Input
CSV rows with:
- `source_metadata_id`
- `ark`
- `manifest_url`

### 4.2 Per-page workflow
1. Resolve image URL from canvas
2. Run `ATREngine.recognize`
3. Append output record immediately

### 4.3 Output (JSONL)
Each line represents one page:

Required:
- manifest_url
- ark
- source_metadata_id
- canvas_id
- page_index
- image_url
- engine
- engine_config
- text

Optional:
- page_label
- elapsed_ms
- warnings
- errors
- data

### 4.4 Resume behavior
A page is “done” if:
- a record exists for `(manifest_url, canvas_id, engine_config)`

---

## 5. MVP invariants

- Stable IIIF traversal helpers
- Stable ATR engine interface
- Explicit, reproducible engine configuration
- Corpus-friendly outputs

---

## 6. Non-goals (MVP)

The following are explicitly out of scope for the MVP:
- Full IIIF Presentation 2.1 or 3.0 coverage
- TEI or scholarly text normalization
- Automatic typographic modernization (e.g., long-s normalization)
- Web Annotation serialization (planned future milestone)

---

*This document defines the MVP contracts and may evolve through deliberate design discussion.*

[^1]: In this document, a *contract* describes the required behavior
and guarantees of a component at its boundaries—what it must accept,
what it must provide, and what other components may rely on—without
prescribing how it is implemented.  Contracts are used here to allow
independent evolution of IIIF models, ATR engines, and the pipeline,
while maintaining interoperability and reproducibility.

[^2]: *Traversal helpers* are convenience methods that abstract over
the structural complexity and variability of IIIF manifests to provide
a stable, predictable way to navigate resources (e.g., from a Manifest
to its Canvases).  They do not expose the full IIIF data model;
instead, they provide a minimal, task-oriented view that enables
common operations (such as iterating pages in reading order) without
requiring callers to understand all IIIF structural details.
Traversal helpers exist because IIIF allows multiple valid structural
representations for the same conceptual content; these helpers
normalize that variability for downstream processing.

