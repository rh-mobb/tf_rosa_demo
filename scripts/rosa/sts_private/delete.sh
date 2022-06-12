#!/bin/bash

IN=$(cat)
echo "Input to destroy script: $IN"

CLUSTER_ID=$(echo $IN | jq -r .id)

rosa delete cluster --cluster $ROSA_CLUSTER_NAME --yes
if [ $? -eq 0 ]; then
    rosa logs uninstall --cluster $ROSA_CLUSTER_NAME --watch
    rm state.json
    #rosa delete operator-roles --cluster $CLUSTER_ID --yes --mode auto
    #rosa delete oidc-provider --cluster $CLUSTER_ID --yes --mode auto
fi

