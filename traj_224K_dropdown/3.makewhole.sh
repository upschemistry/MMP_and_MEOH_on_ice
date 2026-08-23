#echo 0 | gmx trjconv -f traj.trr -s topol.tpr -pbc whole -o traj_whole_1ns.xtc -dt 1000
echo 0 | gmx trjconv -f traj.trr -s topol.tpr -pbc whole -o traj_whole.xtc
echo 0 | gmx trjconv -f confout.gro -o confout.pdb