begintotalTime=$(date +%s.%N)
    ./advanced_verify.sh
    ./advanced_verify1.sh
    ./advanced_verify1.sh
    ./advanced_verify1.sh
    ./advanced_verify1.sh
    ./advanced_verify1.sh
    ./advanced_verify1.sh
    ./advanced_verify1.sh
    endtotalTime=$(date +%s.%N);
    elapsedtotal=`echo "($endtotalTime - $begintotalTime)" | bc`;
    htime=`echo "$elapsedtotal/3600" | bc`
    mtime=`echo "($elapsedtotal/60) - ($htime*60)" | bc`
    stime=`echo "$elapsedtotal - (($elapsedtotal/60)*60)" | bc`
    echo TOTAL: $htime H $mtime M $stime S

#   elapsedtotal=`echo "($endtotalTime - $begintotalTime) / 1000000" | bc`;
   elapsedtotalSec=`echo "scale=6;$elapsedtotal / 1000" | bc | awk '{printf "%.6f", $1}'` ;
   echo TOTAL: $elapsedtotalSec sec
