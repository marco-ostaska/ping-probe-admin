#!/bin/ksh

#-----------------------------------------------------------------------------
# Load variables from props file properties file
#-----------------------------------------------------------------------------

# grabing path where the script is running
BASEDIR=$(dirname $0)

if [[ $BASEDIR == '.' ]]
then
  BASEDIR = $(pwd)
fi

# Loading properties variables
. $BASEDIR/../config/pingprobeadmin.properties

# Loading user provide arguments
OPT=$1 #ADD / REMOVE / search /reorgPP
REQ=$2 # REQUEST NUMBER
Server=$3 # FQDN/
Ciclo=$4 # ping probe cicle in seconds
Location=$5 #Location, took to var, because it can be ASIA NORTH, for instance
Location2=$6 # Need in case Location is ASIA NORTH or ASIA SOUTH
check_count=0 #check lock

#-----------------------------------------------------------------------------
# Check if all required arguments are present for its option
#-----------------------------------------------------------------------------
check_opt() {
  if [[ $OPT == "add" ]] && [[ -z $REQ || -z $Server || -z $Ciclo || -z $Location ]]
  then
    echo "One or more parameters are missing. Please check all parameters"
    remove_lock
    exit 1
  fi

  if [[ $OPT == "remove" ]] && [[ -z $REQ || -z $Server ]]
  then
    echo "One or more parameters are missing. Please check all parameters"
    remove_lock
    exit 1
  fi

  if [[ $OPT == "search" ]]
  then
    Server=$REQ
    if [[ -z $Server ]]
    then
      echo "One or more parameters are missing. Please check all parameters"
      remove_lock
      exit 1
    fi
  fi

  if ! [[ -z $Location2 ]]
  then
    Location="$Location $Location2"
  fi
}

#-----------------------------------------------------------------------------
# Validate if it is locked before doing things
#-----------------------------------------------------------------------------
validate_lock() {
  if ! [[ -f $SeedDir/ping.file.lock ]]
  then
    echo "Pingprobe files are not lock, Risk to corrupt files, aborting"
    exit 2
  fi
}

#-----------------------------------------------------------------------------
# Remove lock
#-----------------------------------------------------------------------------
remove_lock() {
  if [[ -f $SeedDir/ping.file.lock ]]
  then
    rm -rf $SeedDir/ping.file.lock
  else
    echo "Unable to remove lock file $SeedDir/ping.file.lock, please check and try again"
  fi
}

#-----------------------------------------------------------------------------
# Option to start PP processes
#-----------------------------------------------------------------------------
start_PP_all()
{
  WhoAmI=$(whoami)

  if [[ $WhoAmI != "root" ]]
  then
    echo "must be executed as root"
    remove_lock
    exit 1
  fi

  if [[ -f /tmp/temp_startPP.sh ]]
  then
    rm -rf /tmp/temp_startPP.sh
  fi

  for SplitFile in $(ls $SeedDir | grep -i $SliptfileStd)
  do
    PIDPingProbe=$(ps -ef | grep -i $SplitFile | grep -v grep)

    if ! [[ -z $PIDPingProbe ]]
    then
      echo "process $PIDPingProbe is already running"
      remove_lock
      exit 1
    else
      echo "starting process for $SplitFile"
      echo "$PPBin -server $ObServerName -propsfile $PPProps -pingfile $SeedDir/$SplitFile &" >> /tmp/temp_startPP.sh
    fi
  done

  echo "exit 0" >> /tmp/temp_startPP.sh
  echo "/tmp/temp_startPP.sh" > /tmp/startPP.sh
  chmod 775 /tmp/temp_startPP.sh /tmp/startPP.sh
  /bin/ksh -c '/tmp/startPP.sh > /dev/null 2>&1'
}

#-----------------------------------------------------------------------------
# Option to stop PP processes
#-----------------------------------------------------------------------------
stop_PP_all()
{
  for PID in $(ps -ef | grep $SliptfileStd | grep -v grep | grep -v watchdog | awk '{print $2}')
  do
    if ! [[ -z $PID ]]
    then
      echo " killing $PID"
      kill -9 $PID
    fi
  done
}

#-----------------------------------------------------------------------------
# Reorg (defrag)
#-----------------------------------------------------------------------------
reorg()
{
  validate_lock;

  DATE=$(date +"%b-%d-%Y_%Hh%Mm")

  if [[ -f $SeedDir/$SeedFile ]]
  then
    cp -p $SeedDir/$SeedFile $BkpDir/$SeedFile.$DATE
  fi

  #kill processes
  for PID in $(ps -ef | grep $SliptfileStd | grep -v grep | awk '{print $2}')
  do
    kill -9 $PID 2>&1
  done

  #backup files and delete
  for Bkp in $(ls $SeedDir | grep -i split)
  do
    cp -p $SeedDir/$Bkp $BkpDir/$Bkp.$DATE
    rm -rf $SeedDir/$Bkp
  done

  split -l $MaxServerSplit -a 1 $SeedDir/$SeedFile $SeedDir/$SliptfileStd.

  start_PP_all;
}

#-----------------------------------------------------------------------------
# Create or append log for the day
#-----------------------------------------------------------------------------
write_log()
{
  DATE=$(date | awk '{print $2$3$6}')
  if ! [[ -f  $AuditDir/pingprobeadmin_audit.$DATE ]]
  then
    echo "-------------------------------------------------------" > $AuditDir/pingprobeadmin_audit.$DATE
  else
    echo "-------------------------------------------------------" >> $AuditDir/pingprobeadmin_audit.$DATE
  fi
}

#-----------------------------------------------------------------------------
# Func to search server in ping probe
#-----------------------------------------------------------------------------
search()
{
  check_opt;
  ShortName=$(echo $Server | awk -F"." '{print $1}')

  echo "\n---------------------Searching $Server ---------------------"

  #Check split files
  isSplit=$(grep -iw $ShortName $SeedDir/$SliptfileStd*)

  if ! [[ -z $isSplit ]]
  then
    SplitFile=$(echo $isSplit | awk -F":" '{print $1}')
    SplitHost=$(echo $isSplit | awk -F":" '{print $2}' | awk '{print $1}')
    echo "Found\nServer:\t $SplitHost\nSplit File:\t $SplitFile\nVerbose:\t $isSplit"
  else
    echo "NOT FOUND\n $Server NOT FOUND in Ping Probe Monitoring"
  fi

  #Check location table
  isLocTable=$(grep -iw $ShortName $LocationTable)
  if ! [[ -z $isLocTable ]]
  then
    echo "\nFOUND in Location Table\n$isLocTable"
  else
    echo "\nNOT FOUND in Location Table\n$Server was using default location (NAR)"
  fi

  echo "----------------------------------------------------------"
}


#-----------------------------------------------------------------------------
# Func to add to ping probe
#-----------------------------------------------------------------------------
add()
{
  check_opt;
  write_log;

  upper_Server=$(echo $Server | tr '[:lower:]' '[:upper:]')
  upper_loc=$(echo $Location | tr '[:lower:]' '[:upper:]')

  CurrentDate=$(date)
  echo "Date:\t $CurrentDate " >> $AuditDir/pingprobeadmin_audit.$DATE
  echo "Opt:\t Add " >> $AuditDir/pingprobeadmin_audit.$DATE
  echo "REQ:\t $REQ" >> $AuditDir/pingprobeadmin_audit.$DATE
  echo "Server:\t $Server\t Ciclo:\t $Ciclo\t Location:\t $Location" >> $AuditDir/pingprobeadmin_audit.$DATE

  lower_Server=$(echo $Server | tr '[:upper:]' '[:lower:]')
  ShortName=$(echo $Server | awk -F"." '{print $1}')
  HOSTNAME=$(hostname)
  DATE=$(date +"%b-%d-%Y_%Hh%Mm")

  #Check already exists split
  IsThere=$(grep -iw $ShortName $SeedDir/$SliptfileStd*)

  if ! [[ -z $IsThere ]]
  then
    IsWhere=$(echo $IsThere |  awk -F":" '{print $1}')
    echo "$Server is already into $IsWhere"
    remove_lock
    exit 1
  fi

  #Check Location already exists
  IsLocation=$(grep -iw $ShortName $LocationTable)
  if ! [[ -z $IsLocation ]]
  then
    echo "$Server is already into $LocationTable . Please remove it and try again"
    remove_lock
    exit 1
  fi

  #Check ping
  PING=$($PingBin -c 1 $Server)
  rc=$?

  if [[ $rc -ne 0 ]]
  then
    echo "Unable to ping $server, please check with system admin"
    remove_lock
    exit 1
  fi

  if [[ -z $Location ]]
  then
    echo "Region can not be blank"
    remove_lock
    exit 1
  else
    cp -p $LocationTable $BkpDir/location.table.$DATE
    echo "$lower_Server\t$Location" >> $LocationTable
  fi

  ##adding
  echo "$upper_Server\t$Ciclo" >> $SeedDir/$SeedFile

  reorg;
  search;
}

#-----------------------------------------------------------------------------
# Func to remove from ping probe
#-----------------------------------------------------------------------------
remove()
{
  check_opt;
  write_log;

  ShortName=$(echo $Server | awk -F"." '{print $1}')
  CurrentDate=$(date)

  echo "Date:\t $CurrentDate " >> $AuditDir/pingprobeadmin_audit.$DATE
  echo "Opt:\t Remove " >> $AuditDir/pingprobeadmin_audit.$DATE
  echo "REQ:\t $REQ" >> $AuditDir/pingprobeadmin_audit.$DATE
  echo "Server:\t $Server" >> $AuditDir/pingprobeadmin_audit.$DATE

  ShortName=$(echo $Server | awk -F"." '{print $1}')
  DATE=$(date +"%b-%d-%Y_%Hh%Mm")

  echo "\n---------------------Removing $Server ---------------------"

  #Check split file
  isSplit=$(grep -iw $ShortName $SeedDir/$SliptfileStd*)

  if ! [[ -z $isSplit ]]
  then
    SplitFile=$(echo $isSplit | awk -F":" '{print $1}')
    SplitHost=$(echo $isSplit | awk -F":" '{print $2}' | awk '{print $1}')
    echo "Removed\nServer:\t $SplitHost\nFrom File:\t $SplitFile"
    BKPFile=$(echo $SplitFile | awk -F"/" '{print $8}')
    cp -p $SplitFile $BkpDir/$BKPFile$DATE
    cp -p $SeedDir/$SeedFile $BkpDir/$SeedFile$DATE
    grep -v $SplitHost $BkpDir/$SeedFile$DATE > $SeedDir/$SeedFile
  else
    echo "NOT FOUND\n $Server NOT FOUND in Ping Probe Monitoring"
  fi

  #Check location table
  isLocTable=$(grep -iw $ShortName $LocationTable)

  if ! [[ -z $isLocTable ]]
  then
    echo "\nRemoved from Location Table\n$isLocTable"
    cp -p $LocationTable $BkpDir/location.table.$DATE
    LocServer=$(echo $isLocTable | awk '{print $1}')
    grep -v $LocServer $BkpDir/location.table.$DATE > $LocationTable
  else
    echo "\nNOT FOUND in Location Table\n$Server was using default location (NAR)"
  fi

  echo "----------------------------------------------------------"
  echo
  echo
  echo "Double Checking"

  reorg;
  search;
}


#-----------------------------------------------------------------------------
# Search for lock file to avoid corruption
#-----------------------------------------------------------------------------
check_lock()
{
  while [[ $check_count -lt 3 ]]
  do
    check_count=$((check_count+1))
    if [[ -f $SeedDir/ping.file.lock ]]
    then
      echo "There is a process already using pingprobe files, will sleep 10 seconds. Try $check_count of 3"
      isLocked=1
      sleep 10
    else
      check_count=4
      isLocked=0
    fi
  done
}


#-----------------------------------------------------------------------------
# watchdogPP
#-----------------------------------------------------------------------------
watchdog()
{
  Alive=1
  HOSTNAME=$(hostname)
  remove_lock;

  while [[ $Alive -ne 0 ]]
  do
    for i in $(ls $SeedDir| grep -i $SliptfileStd)
    do
      PS=$(ps -ef | grep -i $i | grep -v grep)

      if [[ -z $PS ]]
      then
        DATE=$(date)
        echo "$DATE - Process $i was down, staring process $i" >> $AuditDir/watchdogPP.log
        stop_PP_all
        start_PP_all
        echo "Process $i was down on $HOSTNAME" > $SeedDir/watchdogmessage.txt
        echo "whatch dog tried to start it, and the processes running now are: " >> $SeedDir/watchdogmessage.txt
        echo >> $SeedDir/watchdogmessage.txt
        ps -ef | grep -i $SliptfileStd >> $SeedDir/watchdogmessage.txt
        echo >> $SeedDir/watchdogmessage.txt
        echo "please check" >> $SeedDir/watchdogmessage.txt
        mail -s "$HOSTNAME PingProbe Down - instance $i" $watchdogMailLit < $SeedDir/watchdogmessage.txt
      fi
    done

    sleep 600
  done
}

#-----------------------------------------------------------------------------
# watchdog start
#-----------------------------------------------------------------------------
watchdog_start()
{
  QUEM=$(whoami)

  if [[ $QUEM != "root" ]]
  then
    echo "must be executed as root"
    exit 1
  fi

  WatchUP=$(ps -ef | grep watchdog | grep -v grep | grep -v watchdog_start)
  if ! [[ -z $WatchUP ]]
  then
    echo "watchdogPP is already running"
    ps -ef | grep watchdog | grep -v grep | grep -v watchdog_start
    remove_lock
    exit 1
  else
    echo "watchdogPP started"
    nohup $PPScripts/pingprobeadmin.sh watchdog > /dev/null 2>&1 &
    ps -ef | grep watchdog | grep -v grep | grep -v watchdog_start
  fi
}

#-----------------------------------------------------------------------------
# Main
#-----------------------------------------------------------------------------

if [[ -z $OPT ]]
then
  echo "Invalid Option"
  remove_lock
  exit 1
fi

check_lock; #Check for lock file
if [[ $isLocked -eq 1 ]]
then
  echo "There is already on process using ping probe files, please try again later"
  exit 22
else
  echo "Locked for $$" >> $SeedDir/ping.file.lock
  echo "Calling $OPT function"
  $OPT && remove_lock;
fi
