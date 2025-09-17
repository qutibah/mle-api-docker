#!/usr/bin/env bash
set -euo pipefail

# --- Ensure nbcommands/nbgrep is available ---
if ! command -v nbgrep >/dev/null 2>&1; then
  echo "nbcommands is not installed. Installing..."
  pip install nbcommands
fi

# --- Paths ---
OUT_DIR="./.github/workflows/testing"
PYTHON_FILE="${OUT_DIR}/test_import_libraries.py"
mkdir -p "${OUT_DIR}"
rm -f "${PYTHON_FILE}"

# --- One regex for BOTH notebooks and .py files ---
# - Multiline, handles parenthesized lists (optional trailing comma), aliases, relative imports
# - Inline comments stripped safely via #[^\n]*
NB_REGEX='(?m)^\s*(?:from\s+\.*(?:[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)?\s+import\s+\(?\s*(\*|[A-Za-z_]\w*(?:\s+as\s+[A-Za-z_]\w*)?(?:\s*,\s*[A-Za-z_]\w*(?:\s+as\s+[A-Za-z_]\w*)?)*\s*,?)\s*\)?|import\s+[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*(?:\s+as\s+[A-Za-z_]\w*)?(?:\s*,\s*[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*(?:\s+as\s+[A-Za-z_]\w*)?)*)\s*(?:#[^\n]*)?$'

# --- Search for *.ipynb and *.py, skipping common virtual-env folders ---
find . \
  -type d \( -name '.venv' -o -name 'venv' -o -name 'env' -o -name '.env' \) -prune -false \
  -o -type f \( -name '*.ipynb' -o -name '*.py' \) -print0 |
while IFS= read -r -d '' file; do
  if [[ "$file" == *.ipynb ]]; then
    # Use nbgrep; tolerate "no matches"
    nbgrep "$NB_REGEX" "$file" \
      | grep -v 'nbgrep:' \
      | awk -F ':' '{sub(/^[^:]*:[^:]*:line [0-9]+:/, " ", $0)}1' \
      | sed -E 's/^[[:space:]]+//' \
      | sed -E 's/[[:space:]]*#[^\n]*$//' \
      | grep -E '^(from|import)[[:space:]]' || true
  else
    # Same regex on .py via Python re (supports multiline)
    python - "$file" "$NB_REGEX" <<'PY'
import re, sys, pathlib
path = pathlib.Path(sys.argv[1])
pattern = sys.argv[2]
try:
    text = path.read_text(encoding="utf-8", errors="ignore")
except Exception:
    sys.exit(0)
rx = re.compile(pattern, re.MULTILINE | re.DOTALL)
for m in rx.finditer(text):
    line = m.group(0).strip()
    line = re.sub(r"[ \t]*\n[ \t]*", " ", line)  # flatten (...) blocks
    line = re.sub(r"\s+#.*$", "", line)          # strip inline comment
    if line.startswith(("import ", "from ")):
        print(line)
PY
  fi
done |
# Squeeze spaces/tabs only; keep newlines
sed -E 's/[[:blank:]]+/ /g' |
# Drop comment-only and empty lines
sed -E '/^[[:space:]]*#/d' |
sed -E '/^[[:space:]]*$/d' |
sort -u > "$PYTHON_FILE"

echo "<<<<<<< All extracted import statements from notebooks and Python scripts >>>>>>"
cat "$PYTHON_FILE"

# --- Build the pytest file (prepend repo root for 'src/' imports) ---
{
  echo
  echo "import os, sys"
  echo "import importlib"
  echo "THIS_DIR = os.path.dirname(__file__)"
  echo "REPO_ROOT = os.path.abspath(os.path.join(THIS_DIR, os.pardir, os.pardir, os.pardir))"
  echo "if REPO_ROOT not in sys.path: sys.path.insert(0, REPO_ROOT)"
  echo "SRC_DIR = os.path.join(REPO_ROOT, 'src')"
  echo "if os.path.isdir(SRC_DIR) and SRC_DIR not in sys.path: sys.path.insert(0, SRC_DIR)"
  echo
  echo "def _import_local_if_present(modname: str) -> None:"
  echo "    \"\"\"Try to import a local module in src-layout."
  echo "    Attempts both 'src.X' and 'X'. If neither exists under SRC_DIR, do nothing."
  echo "    If import exists but fails, propagate the exception to fail the test.\"\"\""
  echo "    candidates = [modname]"
  echo "    if modname.startswith('src.'):"
  echo "        candidates.append(modname[4:])"
  echo "    else:"
  echo "        candidates.append(f'src.{modname}')"
  echo "    for m in candidates:"
  echo "        # Map candidate to filesystem under SRC_DIR to see if it exists"
  echo "        if m.startswith('src.'):"
  echo "            rel = m[4:]"
  echo "        else:"
  echo "            rel = m"
  echo "        rel_path = os.path.join(*rel.split('.')) if rel else ''"
  echo "        pkg_dir = os.path.join(SRC_DIR, rel_path)"
  echo "        py_file = pkg_dir + '.py'"
  echo "        exists = (os.path.isfile(py_file) or"
  echo "                  os.path.isdir(pkg_dir) or"
  echo "                  os.path.isfile(os.path.join(pkg_dir, '__init__.py')))"
  echo "        if exists:"
  echo "            # If present locally, import (let any exception bubble up)"
  echo "            importlib.import_module(m)"
  echo "            return"
  echo "    # Not present in this repo; skip silently."
  echo
  echo "def test_import_libraries():"
  echo "    try:"
  echo "        pass"  # keeps the try-block valid even if no imports found
  # Emit imports; rewrite only star-imports to a best-effort local import
  grep -E '^(from|import)[[:space:]]' "$PYTHON_FILE" \
    | sed -E 's/^from[[:space:]]+([A-Za-z_][A-Za-z0-9_\.]*)[[:space:]]+import[[:space:]]+\*$/_import_local_if_present("\1")/' \
    | sed 's/^/        /' || true
  echo "    except Exception as e:"
  echo '        assert False, f"Failed to import library: {e}"'
  echo
  echo "    assert True"
} > "${PYTHON_FILE}.tmp"

mv "${PYTHON_FILE}.tmp" "${PYTHON_FILE}"
echo
echo "Generated ${PYTHON_FILE}:"
echo "----------------------------------------"
cat "${PYTHON_FILE}"
echo "----------------------------------------"
