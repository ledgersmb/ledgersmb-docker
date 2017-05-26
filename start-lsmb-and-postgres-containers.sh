#!/bin/bash

clear

PGuser='postgres'
PGpass='password'

PGcontainerName='lsmb-postgres'
LSMBcontainerName='myledger'


export POSTGRES_HOST='postgres'
export POSTGRES_PORT='5432'
export DEFAULT_DB='lsmb'

CheckWhatIsRunning() {
    isrunning_pg=false;
    isrunning_lsmb=false;
    while read -t10 line || { echo; false; } do
        if [[ $line =~ $PGcontainerName ]]; then isrunning_pg=true; fi
        if [[ $line =~ $LSMBcontainerName ]]; then isrunning_lsmb=true; fi
    done < <( docker ps )
}

StartPostgres() {
    if $isrunning_pg; then
        echo "Postgres container $PGcontainerName is already running";
    else
        echo "Starting Postgres container $PGcontainerName"
        if docker inspect $PGcontainerName &>/dev/null; then # container exists so start it
            docker start $PGcontainerName
        else # container doesn't exist so run it
            docker run --name $PGcontainerName -e POSTGRES_PASSWORD="$PGpass" -d postgres
        fi
    fi
}

StartLedgerSMB() {
    if $isrunning_lsmb; then
        echo "LedgerSMB container $LSMBcontainerName is already running";
    else
        echo "Starting LedgerSMB container $LSMBcontainerName"
        if docker inspect $LSMBcontainerName &>/dev/null; then # container exists so start it
            docker start $LSMBcontainerName >/dev/null
        else # container doesn't exist so run it
            docker run --name $LSMBcontainerName --link lsmb-postgres:postgres -d ledgersmb/ledgersmb
        fi
    fi
}

GetIPs() {
    containerIPlsmbPostgres=`docker inspect  -f '{{ .NetworkSettings.IPAddress }}' lsmb-postgres`
    containerIPlsmb=`docker inspect  -f '{{ .NetworkSettings.IPAddress }}' myledger`
}

PrintInfo() {
    printf " %32s: IP %s\n" "$PGcontainerName" "$containerIPlsmbPostgres"
    printf " %32s: IP %s\n" "$LSMBcontainerName" "$containerIPlsmb"

    echo
}

TestLSMB() { # If any arg is passed then don't echo anything
    if wget --tries=1 --timeout=2 -O /dev/null -q http://$containerIPlsmb:5762/setup.pl; then
        [[ -z $1 ]] && echo "LSMB server accessible"
        return 0
    else
        [[ -z $1 ]] && echo "Failed to connect to LSMB server"
        return 1
    fi
}

timestamp() {
    date "+%s"
}

WaitForContainers() {
    timer=60
    read -st10 timeoutAt < <( timestamp )
    (( timeoutAt = timeoutAt + timer ))
    (( now = `timestamp` ))
    (( lasttimestamp = now ))
    echo
    echo "wait at least $timer seconds for containers to start"
    echo -en "\r$(( timeoutAt - now ))  "
    while { now=`timestamp`; (( now < timeoutAt )); } do
        echo -en "\r$(( timeoutAt - now ))  "
        if (( now <= lasttimestamp )); then continue; fi
        (( lasttimestamp = now ))
        if [[ -z $containerIPlsmb ]]; then GetIPs &>/dev/null; fi
        echo -en "\r$(( timeoutAt - now ))  "
        TestLSMB -s
        if (( $? == 0 )); then echo; break; fi
        echo -en "\r$(( timeoutAt - now ))  "
    done
    echo
}

CheckWhatIsRunning
StartPostgres
StartLedgerSMB
WaitForContainers
TestLSMB

PrintInfo
