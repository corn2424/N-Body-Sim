reset

set terminal pngcairo size 1920,1080 enhanced font 'Verdana,10'

set border 0
unset tics
range=1.3e+9
set xrange [-range:range]
set yrange [-range:range]
set zrange [-range:range]
system('mkdir -p ../data/png/slingshoot')


n=0
num_big_steps = 401;
do for [ii=1:num_big_steps] {
    n=n+1
    set output sprintf('../data/png/slingshoot/nBody%03.0f.png',n)
    splot '../data/raw/slingshoot/N_Body_Particle_00000.txt' u 2:3:4 every ::1::ii w l ls 1 lc 1 title "Earth", \
          '../data/raw/slingshoot/N_Body_Particle_00000.txt' u 2:3:4 every ::ii::ii  w p ls 1 lc 1 notitle, \
          '../data/raw/slingshoot/N_Body_Particle_00001.txt' u 2:3:4 every ::1::ii  w l ls 1 lc 2 title "Moon", \
          '../data/raw/slingshoot/N_Body_Particle_00001.txt' u 2:3:4 every ::ii::ii  w p ls 1 lc 2 notitle, \
}
