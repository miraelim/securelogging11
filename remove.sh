#sudo rm hmac.txt key.txt keyobject.txt 
#weatherdata.txt 
sudo rm key.txt counter.txt loadname.txt  unsealctx.txt finaldata.txt private.txt primary.txt rootkey.txt hmac.txt keyobject.txt newkey.txt public.txt temp1.txt unsealoutput.txt finaltemp.txt final.txt hmactemp.txt hmactemp1.txt hmac_new.txt hmacdata.txt keylist.txt  indexloadname.txt indexprimary.txt indexprivate.txt indexpublic.txt index.txt indexunsealctx.txt keyunsealoutput.txt readoutput.txt 
tpm2_nvrelease -x 0x1500018 -a 0x40000001


#FILENAME="weatherdata.txt"
#exec {FD}<${FILENAME}     # open file for read, assign descriptor
#echo "Opened ${FILENAME} for read using descriptor ${FD}"
flock -u  ${FD};
	      
