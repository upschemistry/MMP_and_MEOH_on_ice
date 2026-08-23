#!/bin/bash
set -e

# ============================================================
# Build MMP + MEOH + Na + annealed ice system
#
# Starting files required:
#   SOL_annealed.gro
#   MMP.gro
#   MEOH.gro
#   NA.gro
#
# Box:
#   4.49070 x 4.66690 x 10.00000 nm
#
# Final molecule order:
#   MEOH  1
#   MMP   1
#   NA    1
#   SOL   2880
# ============================================================

BOX="4.49070 4.66690 10.00000"

echo "=========================================="
echo " Building MMP + MEOH + Na + ice system"
echo "=========================================="

# ------------------------------------------------------------
# 1. Position MMP above the upper ice surface
# ------------------------------------------------------------

echo
echo "Positioning MMP..."

gmx editconf \
    -f MMP_corrected.gro \
    -o MMP_positioned.gro \
    -translate 0.00 0.83 0 \
    -box $BOX \
    -noc

# ------------------------------------------------------------
# 2. Position MEOH beside MMP at the same height
# ------------------------------------------------------------

echo
echo "Positioning MEOH..."

gmx editconf \
    -f MEOH.gro \
    -o MEOH_positioned.gro \
    -translate 1.50 0.83 3.75 \
    -box $BOX \
    -noc

# ------------------------------------------------------------
# 3. Position Na+ at the bottom of the ice slab
# ------------------------------------------------------------

echo
echo "Positioning Na+ at the bottom of the slab..."

gmx editconf \
    -f NA.gro \
    -o NA_positioned.gro \
    -translate -1.202 -1.868 -0.005 \
    -box $BOX \
    -noc

# The translation above moves the Na atom from:
#   (2.017, 2.034, 0.005)
# to:
#   (0.815, 0.166, 0.000)

# ------------------------------------------------------------
# 4. Assemble the coordinate files
#
# We concatenate the coordinate records while retaining the
# original SOL_annealed.gro water coordinates.
#
# Final order:
#   MEOH
#   MMP
#   NA
#   SOL
# ------------------------------------------------------------

echo
echo "Assembling final coordinate file..."

python3 <<'PY'
from pathlib import Path

def read_gro(path):
    lines = Path(path).read_text().splitlines()
    natoms = int(lines[1].strip())
    atoms = lines[2:2+natoms]
    box = lines[2+natoms]
    return atoms, box

MEOH, box = read_gro("MEOH_positioned.gro")
mmp, _ = read_gro("MMP_positioned.gro")
na, _ = read_gro("NA_positioned.gro")
sol, sol_box = read_gro("SOL_annealed.gro")

if len(sol) != 2880 * 4:
    raise RuntimeError(
        f"Expected 11520 SOL atoms, found {len(sol)}"
    )

atoms = MEOH + mmp + na + sol

# Renumber atoms sequentially and preserve residue/molecule names.
new_atoms = []
for i, line in enumerate(atoms, start=1):
    # GRO atom number occupies columns 16-20 (1-indexed).
    # Keep all other fields exactly as supplied.
    new_atoms.append(line[:15] + f"{i:5d}" + line[20:])

# Renumber residues sequentially by molecule while preserving
# the residue names already present in each component.
#
# The existing component residue numbers are not important for
# GROMACS molecule counting, but making them sequential gives
# a clean final coordinate file.
#
# MEOH residue = 1
# MMP  residue = 2
# NA   residue = 3
# SOL residues = 4 ... 2883
out = []
for idx, line in enumerate(new_atoms):
    if idx < len(MEOH):
        resnr = 1
    elif idx < len(MEOH) + len(mmp):
        resnr = 2
    elif idx < len(MEOH) + len(mmp) + len(na):
        resnr = 3
    else:
        water_atom_index = idx - len(MEOH) - len(mmp) - len(na)
        resnr = 4 + water_atom_index // 4

    # residue number occupies columns 1-5
    out.append(f"{resnr:5d}" + line[5:])

with open("System0.gro", "w") as f:
    f.write("MMP + MEOH + Na + annealed ice\n")
    f.write(f"{len(out):5d}\n")
    f.write("\n".join(out) + "\n")
    f.write(sol_box + "\n")

print(f"Final atom count: {len(out)}")
print(f"Expected: {6 + 10 + 1 + 11520}")
print("Final file: System0.gro")
PY

echo
echo "=========================================="
echo "Finished."
echo
echo "Created:"
echo "  MMP_positioned.gro"
echo "  MEOH_positioned.gro"
echo "  NA_positioned.gro"
echo "  System0.gro"
echo
echo "Expected final atom count:"
echo "  MEOH = 6"
echo "  MMP  = 10"
echo "  NA   = 1"
echo "  SOL  = 11520"
echo "  TOTAL = 11537"
echo
echo "Final Na+ position:"
echo "  x = 0.815 nm"
echo "  y = 0.166 nm"
echo "  z = 0.000 nm"
echo "=========================================="
