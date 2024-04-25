#!/usr/bin/env sh
#set -x

# ./datastream.sh --select "Id,DOI" --filter "" --api-key ""
# columns="Id,DOI"
# echo ${columns} > output.csv
# ./datastream.sh --select "${columns}" --filter "" --api-key "" | while read line; do; echo $line | jq -r '. | [.Id, .DOI] | @csv' >> output.csv ; done
# OS Requirements
if ! type "curl" > /dev/null; then
  echo "curl is required, see https://curl.se/download.html"
  REQUIRED=FAIL
fi

if ! type "jq" > /dev/null; then
  echo "jq is required, see https://stedolan.github.io/jq/download/"
  REQUIRED=FAIL
fi

if [ -n "${REQUIRED}" ]; then
  exit 1
fi

# TODO add in version control

# Defaults
FORMAT=JSONSTREAM
DOMAIN=api.datastream.org
APIKEY_PATH=~/.datastream

# Arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
	case ${1} in
		--select)
		SELECT="${2}"
		shift # past argument
		shift # past value
		;;
		--filter)
		FILTER="${2}"
		shift # past argument
		shift # past value
		;;
		--top)
		TOP="${2}"
		shift # past argument
		shift # past value
		;;
		--domain)
		DOMAIN="${2}"
		shift # past argument
		shift # past value
		;;
		--format)
		FORMAT="${2}"
		shift # past argument
		shift # past value
		;;
		--help)
		echo "https://github.com/datastreamapp/datastreamsh"
		shift # past argument
		;;
		*)    # unknown option
		POSITIONAL+=("$1") # save it in an array for later
		shift # past argument
		;;
	esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# Arg requirements


if [ "${FORMAT}" == "CSV" ] && [ -z "${SELECT}" ]; then
  echo "--select is required when using --csv"
  exit 1
elif [ "${FORMAT}" == "CSV" ] && [ -n "${SELECT}" ]; then
  CSV_SELECT=".${SELECT//,/, .}"
fi

APIKEY=$(cat ~/.datastream 2> /dev/null)
if [ -z "${APIKEY}" ]; then
  read -sp "x-api-key: " APIKEY
fi

if [ "${1}" == "setup" ]; then
  echo "${APIKEY}" > ~/.datastream
  exit 0
fi
#

# Functions
function request {
	if [ -z "${1}" ]; then
	  echo "Error: No URL"
	  exit 1
	fi
 	# TODO upgrade to ---http3, --http3-only when built into Mac/Win
	# TODO upgrade to ---tlsv1.3 when built into Mac/Win
	# echo curl --http2 --tlsv1.2 -sG ${1} -H "Accept: application/vnd.api+json" -H "x-api-key: *****"
	res=$(curl --http2 --tlsv1.2 -sG ${1} -H "Accept: application/vnd.api+json" -H "x-api-key: ${APIKEY}")
	
	err=$(echo ${res} | jq -c '.errors')
	if [ "${err}" != "null" ]; then
	  echo "${err}"
	  exit 1
	fi
	if [ "${FORMAT}" == "CSV" ]; then
	  echo ${res} | jq -rc ".value[] | [${CSV_SELECT}] | @csv"
	else
	  echo ${res} | jq -c '.value[]'
	fi
	
	# recursive
	url=$(echo ${res} | jq -r '."@odata.nextLink"')
	if [ "${url}" != "null" ]; then
	  request ${url}
	fi
}

function urlconcat {
	queryTop="\$top="$(urlencode "${TOP}")
	querySelect=
	if [ "${2}" != "" ]; then
		querySelect="&\$select="$(urlencode "${2}")
	fi
	queryFilter=
	if [ "${3}" != "" ]; then
		queryFilter="&\$filter="$(urlencode "${3}")
	fi
	echo "https://${DOMAIN}${1}?${queryTop}${querySelect}${queryFilter}"
}

function urlencode {
	# source: https://github.com/SixArm/urlencode.sh/blob/main/urlencode.sh

	old_lang=$LANG
	LANG=C
	
	old_lc_collate=$LC_COLLATE
	LC_COLLATE=C

	local length="${#1}"
	for (( i = 0; i < length; i++ )); do
		local c="${1:i:1}"
		case $c in
			[a-zA-Z0-9.~_-]) printf "$c" ;;
			*) printf '%%%02X' "'$c" ;;
		esac
	done

	LANG=$old_lang
	LC_COLLATE=$old_lc_collate
}
matchPartitionedRegExp='(^Id| Id|^LocationId| LocationId)'
function partitionRequest {
	if [[ ${3} =~ ${matchPartitionedRegExp} ]]; then
	  url=$(urlconcat "${1}" "${2}" "${3}")
	  request ${url}
	  return 
	fi
	OUTPUT_CSV="${CSV}"
	CSV=FALSE
	locations "Id" "${3/LocationId/Id}" | while read line; do
	  CSV="${OUTPUT_CSV}"
	  locationId=$(echo $line | jq '.Id')
	  filter="LocationId eq ${locationId}"
	  if [ "${3}" != "" ]; then
		  filter+=" and ${3}"
	  fi
	  url=$(urlconcat "${1}" "${2}" "${filter}")
	  request ${url}
	done
}

# Commands
function metadata {
	TOP=${TOP:=100}
	url=$(urlconcat /v1/odata/v4/Metadata "${1}" "${2}")
	request ${url}
}

function locations {
	TOP=${TOP:=10000}
	url=$(urlconcat /v1/odata/v4/Locations "${1}" "${2}")
	request ${url}
}

function observations {
	TOP=${TOP:=10000}
	partitionRequest /v1/odata/v4/Observations "${1}" "${2}"
}

function records {
	TOP=${TOP:=10000}
	partitionRequest /v1/odata/v4/Records "${1}" "${2}"
}

if [ "${FORMAT}" == "CSV" ]; then
  echo "${SELECT}"
fi
${1} "${SELECT}" "${FILTER}"
