#!/usr/bin/env bash
# This script acts as a wrapper to Terraform.
#
# Ensure you have aws cli installed:
#
#   sudo apt-get install awscli
#
# $CONFIG_LOCATION/.aws.$ENVIRONMENT needs to contain the following:
#
#   export AWS_ACCESS_KEY_ID=AKEY
#   export AWS_SECRET_ACCESS_KEY=ASECRET
#   REGION=aws-region
#   BUCKET=s3-bucket-name

CONFIG_FILE=".terraform.cfg"
ENVIRONMENTS=(dc0 dc2)
APP_NAME=small
HELPARGS=("help" "-help" "--help" "-h" "-?")

ACTION=$1
ENVIRONMENT=$2

function help {
  echo "USAGE: ${0} setup <config-location>"
  echo "USAGE: ${0} <action> <environment>"
  echo ""
  echo -n "Valid environments are: "
  local i
  for i in "${ENVIRONMENTS[@]}"; do
    echo -n "$i "
  done
  echo ""
  exit 1
}

function contains_element () {
  local i
  for i in "${@:2}"; do
    [[ "$i" == "$1" ]] && return 0
  done
  return 1
}

function check_config_file() {
  if [ ! -f $CONFIG_FILE ]; then
    return 1
  fi
  return 0
}

function check_setup() {
  if [ -z $CONFIG_LOCATION ]; then
    return 1
  fi
  if [ ! -d $CONFIG_LOCATION ]; then
    return 1
  fi
  return 0
}

# Is terraform in PATH?  If not, it should be.
if which terraform > /dev/null;then
  PATH=$PATH:/usr/local/bin/terraform
fi

# Is this a cry for help?
contains_element "$1" "${HELPARGS[@]}"
if [ "${1}x" == "x" ]; then
  help
fi

# All of the args are mandatory.
if [ $# != 2 ]; then
  help
fi

# Do we need to setup
if [ "$1" == "setup" ]; then
  echo "CONFIG_LOCATION=${2}" > $CONFIG_FILE
  exit 0
fi

# Validate the desired role.
contains_element "$2" "${ENVIRONMENTS[@]}"
if [ $? -ne 0 ]; then
  echo "ERROR: $3 is not a valid environment"
  exit 1
fi

# check we have been setup
check_config_file
if [ $? -ne 0 ]; then
  echo "ERROR: Please run setup with a config location"
  help
fi

source .terraform.cfg

check_setup
if [ $? -ne 0 ]; then
  echo "ERROR: Please make sure the config directory is set and exists, run setup with a config location"
  echo ""
  help
fi

source $CONFIG_LOCATION/.aws.$ENVIRONMENT

# Pre-flight check is good, let's continue.

BUCKET_KEY="${APP_NAME}/tfstate/${ENVIRONMENT}.tfstate"
TFVARS="${CONFIG_LOCATION}/${APP_NAME}/${ENVIRONMENT}.tfvars"

echo ""
echo "Using variables: $TFVARS"
echo ""

# Bail on errors.
set -e

# Nab the latest tfstate.
aws s3 sync --region=$REGION --exclude="*" --include="terraform.tfstate" "s3://${BUCKET}/${BUCKET_KEY}" ./

TERRAFORM_COMMAND="terraform $ACTION -var-file ${TFVARS}"

# Run TF; if this errors out we need to keep going.
set +e

echo $TERRAFORM_COMMAND
echo ""

$TERRAFORM_COMMAND
EXIT_CODE=$?

set -e

# Upload tfstate to S3.
aws s3 sync --region=$REGION --exclude="*" --include="terraform.tfstate" ./ "s3://${BUCKET}/${BUCKET_KEY}"

exit $EXIT_CODE
