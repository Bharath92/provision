#!/bin/bash -e

export PROV_CONTEXT=$1
export PROV_ENV=$2
export TF_FOLDER="$PROV_CONTEXT-$PROV_ENV"
export RES_STATE=$PROV_CONTEXT"_"$PROV_ENV"_state"

export RES_AWS_CREDS=$PROV_CONTEXT"_aws_key"
export RES_AWS_PEM=$PROV_CONTEXT"_aws_pem"

export KEY_FILE_NAME=$PROV_CONTEXT"-us-east-1.pem"


export RES_AWS_PEM_UP=$(echo $RES_AWS_PEM | awk '{print toupper($0)}')
export RES_AWS_PEM_META=$(eval echo "$"$RES_AWS_PEM_UP"_META")

export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')
export RES_AWS_CREDS_META=$(eval echo "$"$RES_AWS_CREDS_UP"_META")

test_context() {
  echo "PROV_CONTEXT=$PROV_CONTEXT"
  echo "PROV_ENV=$PROV_ENV"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_AWS_PEM=$RES_AWS_PEM"
  echo "KEY_FILE_NAME=$KEY_FILE_NAME"
  echo "TF_FOLDER=$TF_FOLDER"
  echo "RES_STATE=$RES_STATE"

  echo "RES_AWS_PEM_UP=$RES_AWS_PEM_UP"
  echo "RES_AWS_PEM_META=$RES_AWS_PEM_META"
  echo "RES_AWS_CREDS_UP=$RES_AWS_CREDS_UP"
  echo "RES_AWS_CREDS_META=$RES_AWS_CREDS_META"
}

restore_state(){
  echo "Copying previous state file"
  echo "-----------------------------------"

  pushd "$TF_FOLDER"
    shipctl copy_file_from_resource_state $RES_STATE terraform.tfstate .
    if [ -f "terraform.tfstate" ]; then
      echo "Copied prior state file"
      echo "-----------------------------------"
    else
      echo "No previous state file exists, skipping"
      echo "-----------------------------------"
    fi
  popd
}

create_pemfile() {
 pushd "$TF_FOLDER"
 echo "Extracting AWS PEM"
 echo "-----------------------------------"
 cat "$RES_AWS_PEM_META/integration.json"  | jq -r '.key' > $KEY_FILE_NAME
 chmod 600 $KEY_FILE_NAME
 ls -al $KEY_FILE_NAME
 echo "Completed Extracting AWS PEM"
 echo "-----------------------------------"
 popd
}

destroy_changes() {
  pushd "$TF_FOLDER"
  echo "-----------------------------------"
  echo "destroy changes"
  echo "-----------------------------------"
  terraform destroy -force -var-file="$RES_AWS_CREDS_META/integration.env"
  popd
}

apply_changes() {
  pushd "$TF_FOLDER"
  echo "-----------------------------------"
  which ssh-agent
  terraform --version
  echo "initializing terraform"
  echo "-----------------------------------"
  terraform init
  echo "planning changes"
  echo "-----------------------------------"
  terraform plan -var-file="$RES_AWS_CREDS_META/integration.env"
#  echo "apply changes"
#  echo "-----------------------------------"
#  terraform apply -auto-approve -var-file="$RES_AWS_CREDS_META/integration.env"
  popd
}


main() {
  eval `ssh-agent -s`
  test_context
  restore_state
  create_pemfile
  #destroy_changes
  apply_changes
}

main