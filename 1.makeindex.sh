#created July 3, 2024 by Nesh & Derek
#pipes instructions from index_groups.txt into the make_ndx command. Currently creates one extra group with frozen water molecules and several groups for atoms we want to track.
cat index_groups.txt | gmx make_ndx -f System0.gro
