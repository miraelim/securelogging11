begindatagenerate=$(date +%s%N)
   for x in `seq 1 `
   do
   cat heartrate_mirae.json >> heartratedatapoint_1.txt
    done
enddatagenerate=$(date +%s%N)
    datagenerateelapsed=`echo "($enddatagenerate - $begindatagenerate) / 1000000" | bc` 
    datagenerateelapsedSec=`echo "scale=6;$datagenerateelapsed / 1000" | bc | awk '{printf "%.6f", $1}'` 
    echo data generation time: $datagenerateelapsedSec sec


