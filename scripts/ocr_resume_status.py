import glob, json, os
from pathlib import Path

out_dir = os.environ.get("OUT_DIR", "runs/ocr")
files = sorted(glob.glob(str(Path(out_dir) / "*.jsonl")))

print(f"OUT_DIR={out_dir}")
print(f"files={len(files)}")

total = empty = ms_sum = 0

for f in files:
    n = e = ms = 0
    with open(f, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except Exception:
                continue
            n += 1
            txt = rec.get("text", "")
            if not txt or not txt.strip():
                e += 1
            ems = rec.get("elapsed_ms")
            if isinstance(ems, int):
                ms += ems

    total += n
    empty += e
    ms_sum += ms
    print(f"{Path(f).name}: pages={n} empty={e} time_s={ms/1000:.1f}")

print("-----")
print(f"TOTAL pages={total} empty={empty} time_s={ms_sum/1000:.1f}")
if total:
    print(f"avg_ms_per_page={ms_sum/total:.1f}")
