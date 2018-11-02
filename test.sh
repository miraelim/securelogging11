FILENAME="weatherdata.txt"
exec {FD}<${FILENAME}     # open file for read, assign descriptor
echo "Opened ${FILENAME} for read using descriptor ${FD}"
while read -u ${FD} LINE
do
    # do something with ${LINE}
    echo ${LINE}
    done
#    exec {FD}<&-
