begindatagenerate=$(date +%s%N)
#   for x in `seq 1 10000`
    for x in `seq 1 2000000`
   do
   cat heartratedatapoint_1.txt >> weatherdata.txt
    done
enddatagenerate=$(date +%s%N)
    datagenerateelapsed=`echo "($enddatagenerate - $begindatagenerate) / 1000000" | bc` 
    datagenerateelapsedSec=`echo "scale=6;$datagenerateelapsed / 1000" | bc | awk '{printf "%.6f", $1}'` 
    echo data generation time: $datagenerateelapsedSec sec


