#!/bin/bash 

curdir=$PWD


protnam=1ZGG
vtfnam=${protnam}-485
nres=150




echo "Residue number of $vtfnam is $nres."
if [ -f ${curdir}/ss/${vtfnam}-ss-1.dat ]
then 
  rm ${curdir}/ss/${vtfnam}-ss-1.dat
fi
for i in `seq 1 ${nres}`
do
  echo "${i} 1 C" >> ${curdir}/ss/${vtfnam}-ss-1.dat

done

echo "0. Converting VTF to PDB ..."

${curdir}/vtf2pdb ${curdir}/vtf/${vtfnam}.vtf ${curdir}/pdb

nframe=10


echo "1. Generating figures for the PDB file ..."
# Here is for Midway useage
# module load pymol
for i in `seq 1 ${nframe}`
do
    pymol ${curdir}/pdb/${vtfnam}_${i}.pdb -cd 'hide all; show cartoon; spectrum count, rainbow; select loops, resi 760-790; center loops; set depth_cue, 0; set opaque_background, off; ray 600, 600; png '${curdir}'/fig-pdb/'${vtfnam}'_'${i}'.png;'

done

echo "1. Preparing data for contact and 2nd structure ..."
# Native contact
${curdir}/sibe -d ${curdir}/cm/ -p ${curdir}/native/${protnam}.pdb -c 7.5 > sibe.log
for i in `seq 1 ${nframe}`
do
#    echo "@ frame $i"
    ${curdir}/sibe -d ${curdir}/cm/ -p ${curdir}/pdb/${vtfnam}_${i}.pdb -c 7.5 > sibe.log
#    mv /home2/ngaam/nifops/Outputs/${vtfnam}_${i}* /home2/ngaam/nifops/Inputs/vtf/cm_hm/
#    if [ -f ${curdir}/ss/${vtfnam}-ss-$i.dat ]
#    then
#        rm ${curdir}/ss/${vtfnam}-ss-$i.dat
#    fi
#    if [ $i -eq 1 ]
#    then
#        cp ${curdir}/ss/${vtfnam}-ss-$i.dat ${curdir}/ss/${vtfnam}-ss-$i.dat
#    else
#        k=`expr $i - 1`
#        cp ${curdir}/ss/${vtfnam}-ss-$k.dat ${curdir}/ss/${vtfnam}-ss-$i.dat
        ss=`${curdir}/stride ${curdir}/pdb/${vtfnam}_${i}.pdb | grep ASG | awk '{printf "%i %i %s\n", NR, '$i', $6}'`
        echo "$ss" >> ${curdir}/ss/${vtfnam}-ss-$i.dat
#    fi
    sed -i 's/C/0/g' ${curdir}/ss/${vtfnam}-ss-$i.dat
    sed -i 's/T/1/g' ${curdir}/ss/${vtfnam}-ss-$i.dat
    sed -i 's/H/2/g' ${curdir}/ss/${vtfnam}-ss-$i.dat
    sed -i 's/G/3/g' ${curdir}/ss/${vtfnam}-ss-$i.dat
    sed -i 's/E/4/g' ${curdir}/ss/${vtfnam}-ss-$i.dat

done



echo "2. Generating figures for the 2nd structure ..."
# Plot 2nd structure
sspath=$curdir/ss
for i in `seq 1 ${nframe}`
do
  #echo $i

gnuplot << EOF
      set term png transparent enhanced size 800,800 font "Vera,18"
      #set term png enhanced size 800,800 font "Vera,16"
      set size square
      # set size ratio 0.5
      # set grid      
      # set palette defined ( 0 '#F7FCFD',\
      #                       1 '#E0ECF4',\
      #                       2 '#BFD3E6',\
      #                       3 '#9EBCDA',\
      #                       4 '#8C96C6',\
      #                       5 '#8C6BB1',\
      #                       6 '#88419D',\
      #                       7 '#6E016B')
      # set palette defined ( 0 '#6E016B',\
      #                       1 '#88419D',\
      #                       2 '#8C6BB1',\
      #                       3 '#8C96C6',\
      #                       4 '#9EBCDA',\
      #                       5 '#BFD3E6',\
      #                       6 '#E0ECF4',\
      #                       7 '#F7FCFD')
      
      set view map
      unset key
      unset border
      set cbrange [-0.:4.]
      set palette defined (0 "green", 1 "yellow", 2 "red", 3 "magenta", 4 "blue")
      set cbtics ("Coil" 0, "Turn" 1, "Helix" 2, "3_{10} Helix" 3, "Strand" 4)
      unset xtics
      unset ytics
      set xrange [0:$nres+0.5]
      set yrange [-2:1002]
      
      set output '$curdir/fig-ss/$vtfnam-ss-$i.png'
      plot '${sspath}/${vtfnam}-ss-$i.dat' u 1:2:3 pt 5 ps 0.5 lt palette  

EOF
done

echo "3. Generating figures for the contact map ..."
# Plot contact map
cmpath=$curdir/cm
for i in `seq 1 ${nframe}`
do

gnuplot << EOF
      set term png transparent enhanced size 800,800 font "Vera,42"
      #set term png enhanced size 800,800 font "Vera,18"
      set size square
      set grid      
      
      # set palette defined ( 0 '#F7FCFD',\
      #                       1 '#E0ECF4',\
      #                       2 '#BFD3E6',\
      #                       3 '#9EBCDA',\
      #                       4 '#8C96C6',\
      #                       5 '#8C6BB1',\
      #                       6 '#88419D',\
      #                       7 '#6E016B')
      set palette defined ( 0 '#6E016B',\
                            1 '#88419D',\
                            2 '#8C6BB1',\
                            3 '#8C96C6',\
                            4 '#9EBCDA',\
                            5 '#BFD3E6',\
                            6 '#E0ECF4',\
                            7 '#F7FCFD')
      set view map
      unset key
      unset xtics
      unset ytics
      
      set output '$curdir/fig-cm/$vtfnam-CM-$i.png'
      plot '${curdir}/cm/${vtfnam:0:4}-CM.par' u 1:2:3 w p pt 13 ps 1 lt rgb '#BDBDBD' t '',\
           '${curdir}/cm/${vtfnam}_$i-CM.par'u (\$1+1):(\$2+1):3 w p pt 13 ps 1 lt rgb '#0000FF' t ''
EOF
done

gap=3

for i in `seq 1 ${nframe}`
do
  montage  ${curdir}/fig-pdb/${vtfnam}_${i}.png \
           ${curdir}/fig-cm/${vtfnam}-CM-${i}.png \
           ${curdir}/fig-ss/${vtfnam}-ss-${i}.png \
           -geometry 800x800+0+0 \
           -background none \
           ${curdir}/montage/${vtfnam}-pdb-cm-ss-${i}.png
done


#convert -delay 2 -loop 0 ${out}/${protnam}-pdb-cm-ss-*.png ${curdir}/${protnam}-pdb-cm-ss.gif
#for j in `seq 1 ${gap}` `seq ${gap} ${gap} ${num}` ${num}; do printf " ${out}/${protnam}-pdb-cm-ss-%i.png" $j; done
convert -delay 1 \
        -loop 0 \
        -dispose 2 \
        $(for j in  `seq 1 ${gap} ${nframe}`; do printf " ${curdir}/montage/${vtfnam}-pdb-cm-ss-%i.png" $j; done;) \
        ${curdir}/movie/${vtfnam}-pdb-cm-ss.gif


echo "Here we are done."
