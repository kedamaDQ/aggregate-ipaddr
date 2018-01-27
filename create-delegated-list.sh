#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
FILES_DIR=$(echo ${2:-'/tmp/aggregate-ipaddr'} | sed -e "s|/$||");

MKDIR_BIN='/sbin/mkdir'
PERL_BIN='/sbin/perl'

CURL_BIN='/sbin/curl'
CURL_CONF="${SCRIPT_DIR}/.curl.conf"

AGGREGATE_IPADDR_BIN="${SCRIPT_DIR}/aggregate-ipaddr.pl"
AGGREGATE_IPADDR_OUT="${FILES_DIR}/aggregated-ipaddrs.txt"

##
# main
#


# create directory
${MKDIR_BIN} -p ${FILES_DIR}
if [ $? -ne 0 ]; then
  echo "Cannot create directory: $!"
  exit 3
fi

# fetch latest delegated lists.
${CURL_BIN} -K ${CURL_CONF} > ${FILES_DIR}/delegated-all-extended-latest
if [ $? -ne 0 ]; then
  echo "Failed to fetch some delegated lists: $!"
  exit 4
fi

# aggregate delegated lists.
${PERL_BIN} ${AGGREGATE_IPADDR_BIN} "${FILES_DIR}" > "${AGGREGATE_IPADDR_OUT}"
if [ $? -ne 0 ]; then
  echo "Failed to aggregate lists: $!"
  exit 5
fi

exit 0
