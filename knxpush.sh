
#!/bin/bash

#### Defaults if not set as environment variable
defaultDebug=false
defaultExport=true
defaultInstallDependencies=true
defaultKnxGatewayIp="172.29.1.120"
defaultKnxtoolLocation="/knx/bin/knxtool"
defaultPushGatewayHost="172.29.4.162"
defaultPushGatewayPort=9091
defaultPrometheusJob="knxpushgateway"
defaultConfigFile="/knx/config/knx.csv"
defaultSendUnconfigured=false

#################################################
declare -A configMap


readEnvVariables () {

	if [ -z "$KNX_PUSH_DEBUG" ]; then
		debug=$defaultDebug
		echo "Configuration: Defaulting KNX_PUSH_DEBUG to '${defaultDebug}'"

	else 
		debug=$KNX_PUSH_DEBUG
		echo "Configuration: Setting KNX_PUSH_DEBUG to '${KNX_PUSH_DEBUG}'"
	fi  


	if [ -z "$KNX_PUSH_EXPORT" ]; then
		export=$defaultExport
		echo "Configuration: Defaulting KNX_PUSH_EXPORT to '${defaultExport}'"
	else 
		export=$KNX_PUSH_EXPORT
		echo "Configuration: Setting KNX_PUSH_EXPORT to '${KNX_PUSH_EXPORT}'"
	fi 


	if [ -z "$KNX_PUSH_DEP_INSTALL" ]; then
		installDependencies=$defaultInstallDependencies
		echo "Configuration: Defaulting KNX_PUSH_DEP_INSTALL to '${defaultInstallDependencies}'"
	else 
		installDependencies=$KNX_PUSH_DEP_INSTALL
		echo "Configuration: Setting KNX_PUSH_DEP_INSTALL to '${KNX_PUSH_DEP_INSTALL}'"
	fi  


	if [ -z "$KNX_PUSH_GATEWAY_IP" ]; then
		knxGatewayIp=$defaultKnxGatewayIp
		echo "Configuration: Defaulting KNX_PUSH_GATEWAY_IP to '${defaultKnxGatewayIp}'"
	else 
		knxGatewayIp=$KNX_PUSH_GATEWAY_IP
		echo "Configuration: Setting KNX_PUSH_GATEWAY_IP to '${KNX_PUSH_GATEWAY_IP}'"
	fi  


	if [ -z "$KNX_PUSH_KNXTOOL_PATH" ]; then
		knxtoolPath=$defaultKnxtoolLocation
		echo "Configuration: Defaulting KNX_PUSH_KNXTOOL_PATH to '${defaultKnxtoolLocation}'"
	else 
		knxtoolPath=$KNX_PUSH_KNXTOOL_PATH
		echo "Configuration: Setting KNX_PUSH_KNXTOOL_PATH to '${KNX_PUSH_KNXTOOL_PATH}'"
	fi  


	if [ -z "$KNX_PUSH_PUSHGATEWAY_HOST" ]; then
		pushGatewayHost=$defaultPushGatewayHost
		echo "Configuration: Defaulting KNX_PUSH_PUSHGATEWAY_HOST to '${defaultPushGatewayHost}'"
	else 
		pushGatewayHost=$KNX_PUSH_PUSHGATEWAY_HOST
		echo "Configuration: Setting KNX_PUSH_PUSHGATEWAY_HOST to '${KNX_PUSH_PUSHGATEWAY_HOST}'"
	fi  


	if [ -z "$KNX_PUSH_PUSHGATEWAY_PORT" ]; then
		pushGatewayPort=$defaultPushGatewayPort
		echo "Configuration: Defaulting KNX_PUSH_PUSHGATEWAY_PORT to '${defaultPushGatewayHost}'"
	else 
		pushGatewayPort=$KNX_PUSH_PUSHGATEWAY_PORT
		echo "Configuration: Setting KNX_PUSH_PUSHGATEWAY_PORT to '${KNX_PUSH_PUSHGATEWAY_PORT}'"
	fi  


	if [ -z "$KNX_PUSH_PROMETHEUS_JOB" ]; then
		prometheusJob=$defaultPrometheusJob
		echo "Configuration: Defaulting KNX_PUSH_PROMETHEUS_JOB to '${defaultPrometheusJob}'"
	else 
		prometheusJob=$KNX_PUSH_PROMETHEUS_JOB
		echo "Configuration: Setting KNX_PUSH_PROMETHEUS_JOB to '${KNX_PUSH_PROMETHEUS_JOB}'"
	fi  


	if [ -z "$KNX_PUSH_CONFIGFILE" ]; then
		configFile=$defaultConfigFile
		echo "Configuration: Defaulting KNX_PUSH_CONFIGFILE to '${defaultConfigFile}'"
	else 
		configFile=$KNX_PUSH_CONFIGFILE
		echo "Configuration: Setting KNX_PUSH_CONFIGFILE to '${KNX_PUSH_CONFIGFILE}'"
	fi  


	if [ -z "$KNX_PUSH_UNCONFIGURED" ]; then
		sendUnconfigured=$defaultConfigFile
		echo "Configuration: Defaulting KNX_PUSH_UNCONFIGURED to '${defaultSendUnconfigured}'"
	else 
		sendUnconfigured=$KNX_PUSH_UNCONFIGURED
		echo "Configuration: Setting KNX_PUSH_UNCONFIGURED to '${KNX_PUSH_UNCONFIGURED}'"
	fi  

}

installDependencies () {

	if $installDependencies ; then
		
		echo "Installing dependencies (curl, xxd)"
		apt-get update
		apt-get --assume-yes install curl xxd

	fi

}

readConfig () {



	if [ -f "$configFile" ]; then
	    echo "Reading config from file '${configFile}'"

		while read -r configLine
		do
		    local groupaddressConfig=$(echo $configLine | awk -F',' '{printf "%s", $1}' | tr -d '"')
		    local dptConfig=$(echo $configLine | awk -F',' '{printf "%s", $2}' | tr -d '"')
		    local nameConfig=$(echo $configLine | awk -F',' '{printf "%s", $3}' | tr -d '"')

			echo "Loading: '${nameConfig}' group: '${groupaddressConfig}' dpt: '${dptConfig}'"

		    configMap[${groupaddressConfig}]="${nameConfig}"
			configMap[${groupaddressConfig}_dpt]=${dptConfig}


		done < $configFile

		local itemSize=$((${#configMap[@]}/2))

		echo "Loaded '${itemSize}' config entries"

	else
		echo "Config file $configFile does not exist"
		exit 1
	fi

}

convertDpt1() {

	# Convert the HEX String to decimal value
	echo $((16#$1))

}

convertDpt5() {

	# Convert the HEX String to decimal value and convert to percentage
	echo $(($((16#$1))*100/255))
	
}

convertDpt9() {

	# convert the HEX String to binary format, extract exponent and mantissa and calculate float result
	binOctets=$(echo $1 | xxd -r -p | xxd -b)

	#00000000: 00000101 01101110 .n
	bin=${binOctets:10:8}${binOctets:19:8}

	# MEEEEMMMMMMMMMMM 
	manDec=$((2#${bin:0:1}${bin:5:11}))
	expDec=$((2#${bin:1:4}))

	# Result = 0,01 * M * 2^E
	result=$(awk -v mult=0.01 -v temp=$((manDec*2**expDec)) 'BEGIN{result=(mult * temp); print result;}')

	echo $result

}

pushToPrometheus () {

	escapedTarget=${1//\//_}

	prometheusTarget="http://${pushGatewayHost}:${defaultPushGatewayPort}/metrics/job/${prometheusJob}/groupaddress/${escapedTarget}"

	if $debug ; then
		echo "Sending: Value '${2}' for '${3}' with address '${1}' (${escapedTarget}) to '${prometheusTarget}'"
	fi 
   
	echo "knx_state $2" | curl -s --data-binary @- $prometheusTarget

}

process() {

	command="stdbuf -i0 -o0 -e0 ${knxtoolPath} groupsocketlisten ip:${knxGatewayIp}"
	capturePattern='^(.+) from (.+) to (.+): (\w.*)\s*$'


	$command |
	  while IFS= read -r line
	  do

		if [[ "$line" =~ $capturePattern ]]; then

			action="${BASH_REMATCH[1]}"
			source="${BASH_REMATCH[2]}"
			destination="${BASH_REMATCH[3]}"
			hexValue=$( set -f; printf "%s" ${BASH_REMATCH[4]} )

			if [[ -n ${configMap[$destination]} ]] || $sendUnconfigured ]]; then

				if [ -z "${configMap[$destination]}" ]; then

					name="unconfigured"				

				else

					name="${configMap[$destination]}"

				fi
				

				if $debug ; then
					echo "Processing: Action '${action}' from '${source}' to '${name}' (${destination})' hexValue '${hexValue}'"
				fi 

				case "${configMap[${destination}_dpt]}" in

				        1)
							value=$(convertDpt1 "${hexValue}")
				            ;;
				         
				        5)
				            value=$(convertDpt5 "${hexValue}")
				            ;;
				         
				        9)
				            value=$(convertDpt9 "${hexValue}")
				            ;;
				
				        *)
				            echo "Invalid DPT: Action '${action}' from '${source}' to '${name}' (${destination})' hexValue '${hexValue}'"
				            value=${hexValue}
				esac

				if $export ; then
					pushToPrometheus "${destination}" "${value}" "${name}" &
				fi 

			else
				if $debug ; then
					echo "Ignoring: Action '${action}' from '${source}' to '${destination}' hexValue '${hexValue}'"
				fi 

			fi

		fi

	  done

}

readEnvVariables
installDependencies
readConfig
process


