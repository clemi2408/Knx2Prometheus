# knxpush.sh - knxd to prometheus push gateway

## Preconditions
This scipts needs some tools to run:
* `xxd` to convert values: [manpage](https://linux.die.net/man/1/xxd)
* `curl` to do http requests: [manpage](https://linux.die.net/man/1/curl)
* `knxtool` as part of eibd/knxd project to listen to knx bus: [git](https://github.com/knxd/knxd/wiki/KnxTool)
* `stdbuf` to capture the output of `knxtool` [manpage](https://linux.die.net/man/1/stdbuf)
* `awk` to do String transformations and float calculations [manpage](https://linux.die.net/man/1/awk)


## Environment variables & defaults

* `KNX_PUSH_DEBUG`
  * Enables/disables debug output to standard out.
  * Values: `true` or `false`
  * Defaults to: `false`


* `KNX_PUSH_EXPORT`
  * Enables/disables the export to prometheus push gateway.
  * Values: `true` or `false`
  * Defaults to: `true`

* `KNX_PUSH_DEP_INSTALL`
  * Enables/disables install of the required dependencies (xxd, curl), ubuntu only.
  * Values: `true` or `false`
  * Defaults to: `true`

* `KNX_PUSH_GATEWAY_HOST`
  * Sets the ip or hostname of the knx ip gateway.
  * Value: valid ip or hostname.
  * Defaults to: `knx01`

* `KNX_PUSH_KNXTOOL_PATH`
  * Sets the the path of the `knxtool` binary of the eibd.
  * Value: valid path to `knxtool` executable.
  * Defaults to: `/knx/bin/knxtool`

* `KNX_PUSH_PUSHGATEWAY_HOST`
  * Sets the the ip or hostname of the prometheus push gateway.
  * Value: valid ip or hostname.
  * Defaults to: `knxpushgateway01`

* `KNX_PUSH_PUSHGATEWAY_PORT`
  * Sets the the port of the prometheus push gateway host.
  * Value: valid port number.
  * Defaults to: `9091`

* `KNX_PUSH_PROMETHEUS_JOB`
  * Sets the the name of the prometheus job.
  * Value: alphanumeric without blanks and url characters.
  * Defaults to: `knxpushgateway`

* `KNX_PUSH_CONFIGFILE`
  * Sets the path of the KNX item CSV-File.
  * Value: valid path to configuration csv.
  * Defaults to: `/knx/config/knx.csv`

* `KNX_PUSH_UNCONFIGURED`
  * If enabled all messages will be pushed to prometheus push gateway, otherwise only items in `KNX_PUSH_CONFIGFILE` will processed.
  * Values: `true` or `false`
  * Defaults to: `false`
  
## Configuration file (knx.csv)
The configuration of the KNX items is based on csv.

In the file the following items are set:
* Group address (e.g `"1/0/40"`)
* KNX-DPT (e.g `1`, `5` or `9`)
* Description (e.g `"Kitchen light"`)

Note: During processing the `/` of a group address gets replaced with `_` to be compatible with URLs

Example:
```
"1/0/40",9,"Kitchen temperature"
"2/0/3",1,"Kitchen light"
"2/0/31",5,"Kitchen shutter"
```

## docker-compose examples
* [single](https://github.com/clemi2408/Knx2Prometheus/blob/master/docker-compose-single.yml)
* [full](https://github.com/clemi2408/Knx2Prometheus/blob/master/docker-compose-full.yml)

## Example Prometheus Queries (PromQL)
* `knx_state{}` or `knx_state{job="knxpushgateway"}` lists all states 
* `knx_state{groupaddress="0_0_14",job="knxpushgateway"}` lists the (last) state of the group address `0/0/14`

