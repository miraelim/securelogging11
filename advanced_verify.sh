#add HMAC of previous log entry in current log entry and generate new key after finish logger in log block
#add flock
#add groupingsize
GROUPINGSIZE=100;
SHUTDOWN=0;
KEYINDEX=0;
function makeRootkey(){
    beginrootkey=$(date +%s%N)
	KEY=$(openssl rand 64)
	echo $KEY |tee key.txt
	cp key.txt rootkey.txt
	cp key.txt keylist.txt
	endrootkey=$(date +%s%N)
	rootkeyelapsed=`echo "($endrootkey - $beginrootkey) / 1000000" | bc`
	rootkeyelapsedSec=`echo "scale=6;$rootkeyelapsed / 1000" | bc | awk '{printf "%.6f", $1}'`
	echo Make Rootkey time: $rootkeyelapsedSec sec
}

function getCounter(){
    begingetCounter=$(date +%s%N)
	tpm2_dump_capability -c properties-fixed | grep COUNTERS | sudo tee counter.txt
	while read -r r1 COUNTER1; do
	    COUNTER=$(printf "%x\n" $COUNTER1)
		echo counter $COUNTER
		done < counter.txt
		rm counter.txt
		echo $COUNTER | tee counter.txt
		tpm2_nvdefine -x 0x1500018 -a 0x40000001 -s 64 -t 0x2000A
		tpm2_nvwrite -x 0x1500018 -a 0x40000001 -f counter.txt
		endgetCounter=$(date +%s%N)
		getCounterelapsed=`echo "($endgetCounter - $begingetCounter) / 1000000" | bc`
		getCounterelapsedSec=`echo "scale=6;$getCounterelapsed / 1000" | bc | awk '{printf "%.6f", $1}'`
		echo get Counter time: $getCounterelapsedSec sec
}

function getflock(){
    begingetCounter=$(date +%s%N);
    FILENAME="weatherdata.txt";
    exec {FD}<${FILENAME};     # open file for read, assign descriptor;
    echo "Opened ${FILENAME} for read using descriptor ${FD}";
    flock -x -s ${FD};
    endgetCounter=$(date +%s%N);
    getCounterelapsed=`echo "($endgetCounter - $begingetCounter) / 1000000" | bc`;
    getCounterelapsedSec=`echo "scale=6;$getCounterelapsed / 1000" | bc | awk '{printf "%.6f", $1}'`;
    echo get flock time: $getCounterelapsedSec sec;
}

function saveCounter(){
    beginsaveCounter=$(date +%s%N)
	echo SAVE COUNTER
	tpm2_nvlist|grep -i 0x1500018
	if [ $? == 0 ];then
     echo "please release the nv index $nv_test_index first!"
	    tpm2_nvrelease  -x 0x1500018 -a 0x40000001;
    fi

	    tpm2_nvdefine -x 0x1500018 -a 0x40000001 -s 64 -t 0x2000A
	    tpm2_nvwrite -x 0x1500018 -a 0x40000001 -f counter.txt

	    endsaveCounter=$(date +%s%N)
	    saveCounterelapsed=`echo "($endsaveCounter - $beginsaveCounter) / 1000000" | bc`
	    saveCounterelapsedSec=`echo "scale=6;$saveCounterelapsed / 1000" | bc | awk '{printf "%.6f", $1}'`
	    echo save Counter time: $saveCounterelapsedSec sec


}

#function readCounter(){
#    tpm2_nvread -x 0x1500018 -a 0x40000001 -s 64 -o 0 | tee readoutput.txt
#}

function seal1(){
    beginseal1=$(date +%s%N)
	echo counter in seal $COUNTER;
    rm -rf primary.txt public.txt private.txt unsealctx.txt loadname.txt;
    tpm2_takeownership -c;
    tpm2_createprimary -A p -g 0x000B -G 0x0023 -C primary.txt;
    tpm2_create -g 0x000B -G 0x0008 -p $COUNTER -o public.txt -O private.txt -I key.txt -c primary.txt;
    tpm2_load  -c primary.txt -p $COUNTER -u public.txt -r private.txt -n loadname.txt -C unsealctx.txt;
    endseal1=$(date +%s%N)
	seal1elapsed=`echo "($endseal1 - $beginseal1) / 1000000" | bc`
	seal1elapsedSec=`echo "scale=6;$seal1elapsed / 1000" | bc | awk '{printf "%.6f", $1}'`
	echo seal1 time: $seal1elapsedSec sec

}

function seal2(){
    beginseal2=$(date +%s%N)
	echo seal2
	COUNTER=`expr $COUNTER + 1`;
    sudo rm counter.txt
	echo $COUNTER | tee counter.txt
	rm -rf public.txt private.txt unsealctx.txt loadname.txt
	tpm2_create -g 0x000B -G 0x0008 -p $COUNTER -o public.txt -O private.txt -I key.txt -c primary.txt;
    tpm2_load  -c primary.txt -p $COUNTER -u public.txt -r private.txt -n loadname.txt -C unsealctx.txt;
    endseal2=$(date +%s%N)
	seal2elapsed=`echo "($endseal2 - $beginseal2) / 1000000" | bc`
	seal2elapsedSec=`echo "scale=6;$seal2elapsed / 1000" | bc | awk '{printf "%.6f", $1}'`
	echo seal2 time: $seal2elapsedSec sec

}

function unseal(){
    beginunseal=$(date +%s%N)
	ls unsealouput.txt;
    if [ $? != 0 ]
	then
	    rm unsealoutput.txt;
    fi
	tpm2_unseal -c unsealctx.txt -p $COUNTER -o unsealoutput.txt;
    if [ $? -eq 0 ];
    then
	echo Unseal success;
    else
	exit 1;
    fi
	endunseal=$(date +%s%N)
	unsealelapsed=`echo "($endunseal - $beginunseal) / 1000000" | bc`
	unsealelapsedSec=`echo "scale=6;$unsealelapsed / 1000" | bc | awk '{printf "%.6f", $1}'`
	echo unseal time: $unsealelapsedSec sec
}

function hmac(){
    beginhmac=$(date +%s%N)
#	echo hmac shutdown $SHUTDOWN
#	if [ $SHUTDOWN != 1 ]
#	    then
#		LOG=$(cat hmactemp1.txt);
#   if [ $KEYINDEX == 1 ];
#   then
#	LOG=$(echo $LOG FIRST);
#    else
#	LOG=$(echo $LOG $PREVIOUS);
#   fi
#	elif [ $SHUTDOWN == 1 ] 
#	then 
#	LOG=$(cat finaldata.txt);
#   fi
#	echo $LOG | tee hmactemp.txt;
    hmac256 $KEY weatherdata.txt | tee hmacdata.txt;
    while read -r s1 s2; do
	PREVIOUS=$(echo $s1)
	    echo $s1 >> hmac_new.txt;
    done < hmacdata.txt
	endhmac=$(date +%s%N)
	hmacelapsed=`echo "($endhmac - $beginhmac) / 1000000" | bc`
	hmacelapsedSec=`echo "scale=6;$hmacelapsed / 1000" | bc | awk '{printf "%.6f", $1}'`
	echo hmac time: $hmacelapsedSec sec

}

function generate_newkey(){
    echo generate newkey;
    sha256sum key.txt | tee keyobject.txt;
    while read -r k1 k2; do
	echo $k1 | tee key.txt;
    done < keyobject.txt;
    echo $(cat key.txt) >> keylist.txt;
    KEY=$(cat key.txt);
#    COUNTER=`expr $COUNTER + 1`;
    echo $COUNTER | tee counter.txt
}

function phase1(){
    makeRootkey;
    getCounter;
    getflock;
}

function phase2(){
    if [ $COUNTER == 8 ];
    then
	seal1;
    else
	seal2;
    fi
	beginTime=$(date +%s%N)
	saveCounter;
    endTime=$(date +%s%N) elapsed=`echo "($endTime - $beginTime) / 1000000" | bc`;
    elapsedSec=`echo "scale=6;$elapsed / 1000" | bc | awk '{printf "%.6f", $1}'`;
    echo SAVE TIME $elapsedSec sec

}

function phase3(){
    unseal;
#    if [ $SHUTDOWN  != 1 ]
#	then 
#	    while read STRING; do
#		INT1=`expr $KEYINDEX % $GROUPINGSIZE`
#		    INT2=`expr $GROUPINGSIZE - 1`
#		    echo $STRING | tee hmactemp1.txt;
    hmac;
#    if [ $GROUPINGSIZE == 1 ]
#	then
	    generate_newkey;
#   phase2;

#   elif [ $INT1 == $INT2 ]
#	then
#	generate_newkey;
#   phase2;
#   fi
    KEYINDEX=`expr $KEYINDEX + 1`;
#   INT1=`expr $KEYINDEX % $GROUPINGSIZE`
#	if [ $INT1 == 0 ]
#	    then
#		KEYINDEX=0;
#   fi

#   done < weatherdata.txt;
#   elif [ $SHUTDOWN == 1 ]
#	then
#	hmac ;
#   fi

}

function phase4(){
#   SHUTDOWN=1;
#   echo $KEY shutdown | tee finaltemp.txt;
#   sha256sum finaltemp.txt | tee final.txt;
#
#   while read -r f1 f2; do
#	echo $f1 | tee finaldata.txt;
#   done < final.txt;
#   phase3 $f1
#	echo $(cat finaldata.txt) | tee key.txt
#	echo $(cat key.txt) >> keylist.txt;
    seal2;
    saveCounter;
}
begintotalTime=$(date +%s.%N)
    phase1
    phase2
    phase3
    phase4;
    endtotalTime=$(date +%s.%N);
    elapsedtotal=`echo "($endtotalTime - $begintotalTime)" | bc`;
    htime=`echo "$elapsedtotal/3600" | bc`
    mtime=`echo "($elapsedtotal/60) - ($htime*60)" | bc`
    stime=`echo "$elapsedtotal - (($elapsedtotal/60)*60)" | bc`
    echo first Total : $htime H $mtime M $stime S

#elapsedtotal=`echo "($endtotalTime - $begintotalTime) / 1000000" | bc`;
   elapsedtotalSec=`echo "scale=6;$elapsedtotal / 1000" | bc | awk '{printf "%.6f", $1}'` ;
   echo first TOTAL: $elapsedtotalSec sec
