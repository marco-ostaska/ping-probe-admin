#!/bin/ksh
#-------------------------------------------------------------------------------
#       DESCRIPTION:
#       Automenu script to admin PingProbe tasks remotely
#
#       USAGE:
#       <script> <opt> <Req Number> <Server FQN> <Cycle> <Location>
#
#       Example:
#       ./htem_pingprobeadmin.sh ADD REQ00XXXXXX SERVE.COM 300 "ASIA NORTH"
#-------------------------------------------------------------------------------

OPT=$1
REQ=$2
Server=$3
Ciclo=$4
Location="$5 $6"

RemoteScript="/opt/IBM/probe/PING/scripts/pingprobeadmin.sh" # change it as suits you
AG="xxxxxxx:KUX" # change for your pingprobe server OS agent

list() {
  Server=$REQ
  tacmd executecommand -m $AG -c "$RemoteScript search $Server" -o -v | grep -v KUIEXC001I | grep -v KUIEXC000I
}

add() {
  tacmd executecommand -m $AG -c "$RemoteScript add $REQ $Server $Ciclo $Location" -o -v | grep -v KUIEXC001I | grep -v KUIEXC000I
}

remove() {
  tacmd executecommand -m $AG -c "$RemoteScript remove $REQ $Server" -o -v | grep -v KUIEXC001I | grep -v KUIEXC000I
}

# Option call
$OPT;
