for X-MLC
"DADCSWAN" for SWAN Coupling.
(edit cmplrflags.mk)
 DPRE          :=  -DREAL8 -DLINUX -DADCSWAN

make padcirc  
make clean
make clobber
make config
make punswan
make adcswan (without MPI)
make padcswan
 

![Figure](https://github.com/subhadeep-maishal/ADCIRC-SWAN-CPL/blob/main/git-x.PNG) 
