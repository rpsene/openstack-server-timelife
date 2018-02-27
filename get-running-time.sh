#!/bin/bash

set +e
: '
Copyright (C) 2018 Rafael Peria de Sene
Licensed under the Apache License, Version 2.0 (the “License”);
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an “AS IS” BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Contributors:
        * Rafael Sene <rpsene@gmail.com>
'

trap ctrl_c INT

function ctrl_c() {
        echo "Cancelling the execution..."
        exit 1
}

# Check if openstack-cli is installed
if ! [ -x "$(command -v openstack)" ]; then
   echo 'Error: openstack is not installed.' >&2
   exit 1
fi

# Collect all the running servers. $1 is the pattern for filtering
# if nothing is set, it gets all servers running.
SERVERS=($(openstack server list -c ID -c Name -f value  | \
grep "$1" | sed 's/ / /' | awk '{print $1}'))

# If we do not have any services, exit.
if [ ${#SERVERS[@]} -eq 0 ]; then
	echo "ERROR: there are no VMs with $1"
    exit 1
else
    for server in ${SERVERS[@]}; do
        # Get raw information about the server
        RAW_DATA=$(openstack server show -f=shell $server)
        ARR=($RAW_DATA)

        # Get information about when the server was created
        SERVER_CREATION=$(printf "%s\n" "${ARR[@]}" | \
grep created | awk -F "=" '{print $2}' | tr -d '\"' | tr -d 'Z')

        # Get the date server was created.
        DATE_CREATION=$(date -u --date "$SERVER_CREATION" +%s)

        # Get the current date
        CURRENT=$(date -u --iso-8601=ns | cut -d',' -f1)
        DATE_CURRENT=$(date -u --date "$CURRENT" +%s)

        # Calculate the time difference in seconds
        SECONDS=$((DATE_CURRENT - DATE_CREATION))

        # Get the name of the server
        NAME=$(printf "%s\n" "${ARR[@]}" | grep -w -m 1 name | \
awk -F "=" '{print $2}' | tr -d '\"')

        # Format the time, from seconds to hours, minutes and seconds.
        TIME=$(printf '%dh:%dm:%ds\n' $(($SECONDS/3600)) \
$(($SECONDS%3600/60)) $(($SECONDS%60)))

        # Pretty print.
        echo "The server $NAME ($server) is running for $TIME"
        let i+=1
    done
fi
