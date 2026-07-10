#!/bin/bash
####################################
#
# OpenVINO Installation Debug Script
# Ubuntu 26.04 - Dell Latitude 7340
#
####################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}OpenVINO Installation Debug Script${NC}"
echo -e "${BLUE}Ubuntu 26.04 - Dell Latitude 7340${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
info() { echo -e "${BLUE}=>${NC} $1"; }

# ─── 1. OS / System ───────────────────────────────────────────────────────────
echo -e "${YELLOW}[1] System Information${NC}"
echo "  OS:       $(lsb_release -d 2>/dev/null | cut -d: -f2 | sed 's/^ *//' || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo "  Kernel:   $(uname -r)"
echo "  Arch:     $(uname -m)"
echo ""

# ─── 2. APT Repository ────────────────────────────────────────────────────────
echo -e "${YELLOW}[2] OpenVINO APT Repository${NC}"
INTEL_LIST="/etc/apt/sources.list.d/intel-openvino.list"
if [ -f "$INTEL_LIST" ]; then
    pass "Intel APT repo file found: $INTEL_LIST"
    echo "  Contents: $(cat $INTEL_LIST)"
else
    warn "Intel APT repo file not found ($INTEL_LIST). May be using Ubuntu native archive."
fi

KEYRING="/usr/share/keyrings/intel-openvino-archive-keyring.gpg"
if [ -f "$KEYRING" ]; then
    pass "Intel GPG keyring found: $KEYRING"
else
    warn "Intel GPG keyring not found ($KEYRING). May be using Ubuntu native archive."
fi
echo ""

# ─── 3. Installed Packages ───────────────────────────────────────────────────
echo -e "${YELLOW}[3] Installed OpenVINO APT Packages${NC}"
OV_PACKAGES=$(dpkg -l | grep -i openvino 2>/dev/null)
if [ -n "$OV_PACKAGES" ]; then
    pass "OpenVINO packages installed:"
    echo "$OV_PACKAGES" | awk '{printf "  %-40s %s\n", $2, $3}'
else
    fail "No OpenVINO APT packages found (dpkg -l | grep openvino returned nothing)"
fi
echo ""

# ─── 4. Shared Libraries ─────────────────────────────────────────────────────
echo -e "${YELLOW}[4] OpenVINO Shared Libraries${NC}"
OV_LIBS=$(ldconfig -p 2>/dev/null | grep -i "openvino\|inference_engine" || true)
if [ -n "$OV_LIBS" ]; then
    pass "OpenVINO libraries found in ldconfig cache:"
    echo "$OV_LIBS" | sed 's/^/  /'
else
    fail "No OpenVINO shared libraries found via ldconfig"
    info "Try: sudo ldconfig && ldconfig -p | grep openvino"
fi
echo ""

# ─── 5. Python Environments ──────────────────────────────────────────────────
# Resolve .venv relative to the script's repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
VENV_PY="$REPO_ROOT/.venv/bin/python"

echo -e "${YELLOW}[5] Python Environments${NC}"
if [ -x "$VENV_PY" ]; then
    pass ".venv found: $VENV_PY  ($($VENV_PY --version 2>&1))  [default]"
else
    warn ".venv not found at $REPO_ROOT/.venv (create with: python3 -m venv .venv)"
fi
for PY in python3 python; do
    if command -v "$PY" >/dev/null 2>&1; then
        PY_PATH=$(command -v "$PY")
        PY_VER=$("$PY" --version 2>&1)
        echo "  System: $PY_PATH  ($PY_VER)"
    fi
done
echo ""

# ─── 6. Python openvino Module ───────────────────────────────────────────────
echo -e "${YELLOW}[6] Python openvino Module${NC}"
# Prefer .venv, fall back to system python
if [ -x "$VENV_PY" ]; then
    PY_BIN="$VENV_PY"
else
    PY_BIN=$(command -v python3 || command -v python || echo "")
fi
if [ -z "$PY_BIN" ]; then
    fail "No Python interpreter found"
else
    if "$PY_BIN" -c "import openvino" 2>/dev/null; then
        OV_VER=$("$PY_BIN" -c "import openvino; print(openvino.__version__)" 2>/dev/null)
        pass "openvino importable — version: ${OV_VER:-unknown}"
    else
        fail "Cannot import openvino in Python ($PY_BIN)"
        OV_IMPORT_ERR=$("$PY_BIN" -c "import openvino" 2>&1)
        echo "  Error: $OV_IMPORT_ERR"
        info "Install with: pip install openvino  OR  sudo apt install python3-openvino"
    fi
fi
echo ""

# ─── 7. Available Compute Devices ────────────────────────────────────────────
echo -e "${YELLOW}[7] OpenVINO Available Compute Devices${NC}"
if [ -n "$PY_BIN" ] && "$PY_BIN" -c "import openvino" 2>/dev/null; then
    DEVICES=$("$PY_BIN" - <<'EOF'
import openvino as ov
core = ov.Core()
devices = core.available_devices
if devices:
    for d in devices:
        full = core.get_property(d, "FULL_DEVICE_NAME")
        print(f"  {d}: {full}")
else:
    print("  (none found)")
EOF
)
    pass "Device enumeration succeeded:"
    echo "$DEVICES"
else
    warn "Skipping device check — openvino not importable"
fi
echo ""

# ─── 8. Key Python Dependencies ──────────────────────────────────────────────
echo -e "${YELLOW}[8] Key Python Dependencies${NC}"
DEPS=(numpy tensorflow openvino_dev openvino_telemetry)
if [ -n "$PY_BIN" ]; then
    for DEP in "${DEPS[@]}"; do
        VER=$("$PY_BIN" -c "import importlib.metadata; print(importlib.metadata.version('$DEP'))" 2>/dev/null \
              || "$PY_BIN" -c "import $DEP; print(getattr($DEP, '__version__', 'installed'))" 2>/dev/null \
              || echo "")
        if [ -n "$VER" ]; then
            pass "$DEP == $VER"
        else
            warn "$DEP not found"
        fi
    done
else
    warn "Skipping — no Python interpreter found"
fi
echo ""

# ─── 9. ovc / mo Conversion Tools ───────────────────────────────────────────
echo -e "${YELLOW}[9] OpenVINO Model Conversion Tools${NC}"
for TOOL in ovc mo mo.py; do
    if command -v "$TOOL" >/dev/null 2>&1; then
        pass "$TOOL found: $(command -v $TOOL)"
    else
        warn "$TOOL not found in PATH"
    fi
done
echo ""

# ─── 10. benchmark_app ────────────────────────────────────────────────────────
echo -e "${YELLOW}[10] benchmark_app${NC}"
VENV_BENCH="$REPO_ROOT/.venv/bin/benchmark_app"
if [ -x "$VENV_BENCH" ]; then
    pass "benchmark_app found in .venv: $VENV_BENCH  [default]"
elif command -v benchmark_app >/dev/null 2>&1; then
    warn "benchmark_app found at $(command -v benchmark_app) but NOT in .venv"
    warn "System benchmark_app uses Python 3.14 + broken python3-openvino APT package — will crash"
    info "Fix: pip install openvino-dev inside .venv"
else
    warn "benchmark_app not found (checked .venv and PATH)"
fi
echo "" ""

# ─── 11. Functional Smoke Test ───────────────────────────────────────────────
echo -e "${YELLOW}[11] Functional Smoke Test (CPU inference)${NC}"
if [ -n "$PY_BIN" ] && "$PY_BIN" -c "import openvino" 2>/dev/null; then
    SMOKE_RESULT=$("$PY_BIN" - <<'EOF' 2>&1
import numpy as np
import openvino as ov

core = ov.Core()
# Build a trivial single-relu model and run inference on CPU
from openvino.runtime import opset13 as ops
from openvino.runtime import Model, Type, Shape

param = ops.parameter(Shape([1, 3]), dtype=Type.f32, name="input")
relu  = ops.relu(param)
model = Model([relu], [param], "smoke_test")

compiled = core.compile_model(model, "CPU")
infer_req = compiled.create_infer_request()
result = infer_req.infer({"input": np.array([[-1.0, 0.0, 1.0]], dtype=np.float32)})
output = list(result.values())[0]
assert output.tolist() == [[0.0, 0.0, 1.0]], f"Unexpected output: {output}"
print("PASS")
EOF
)
    if echo "$SMOKE_RESULT" | grep -q "PASS"; then
        pass "CPU inference smoke test passed"
    else
        fail "CPU inference smoke test failed"
        echo "$SMOKE_RESULT" | sed 's/^/  /'
    fi
else
    warn "Skipping smoke test — openvino not importable"
fi
echo ""

# ─── 12. Environment Variables ────────────────────────────────────────────────
echo -e "${YELLOW}[12] Relevant Environment Variables${NC}"
for VAR in PYTHONPATH LD_LIBRARY_PATH INTEL_OPENVINO_DIR OpenVINO_DIR; do
    VAL="${!VAR:-}"
    if [ -n "$VAL" ]; then
        pass "$VAR=$VAL"
    else
        info "$VAR is not set"
    fi
done
echo ""

# ─── Summary ──────────────────────────────────────────────────────────────────
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Debug complete.${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${YELLOW}Useful remediation commands:${NC}"
echo "  sudo apt install python3-openvino               # system Python package"
echo "  pip install openvino openvino-dev               # pip package"
echo "  sudo apt install intel-opencl-icd clinfo        # OpenCL runtime"
echo "  sudo ldconfig                                    # refresh library cache"
echo "  sudo usermod -a -G render,video \$USER           # GPU device access"
echo ""

exit 0
