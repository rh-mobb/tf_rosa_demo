#!/bin/bash

# Create a ROSA cluster using STS

# Authentication
#rosa login --token $ROSA_OFFLINE_ACCESS_TOKEN
# rosa whoami
# Validation of inputs
# Assignment of defaults? Use 'auto' flag?
# User linkage? This should only be for STS right?
#  rosa link user-role --role-arn arn:aws:iam::660250927410:user/thatcher-mobb

rosa create cluster \
--color never \
--cluster-name=$ROSA_CLUSTER_NAME \
--sts \
--role-arn arn:aws:iam::660250927410:role/ManagedOpenShift-Installer-Role \
--support-role-arn arn:aws:iam::660250927410:role/ManagedOpenShift-Support-Role \
--controlplane-iam-role arn:aws:iam::660250927410:role/ManagedOpenShift-ControlPlane-Role \
--worker-iam-role arn:aws:iam::660250927410:role/ManagedOpenShift-Worker-Role \
--external-id $ROSA_CLUSTER_NAME \
--multi-az \
--region $ROSA_REGION \
--version $ROSA_VERSION \
--compute-nodes $ROSA_COMPUTE_NODE_COUNT \
--compute-machine-type $ROSA_COMPUTE_NODE_INSTANCE_TYPE \
--machine-cidr $ROSA_MACHINE_CIDR \
--service-cidr 172.30.0.0/16 \
--pod-cidr 10.128.0.0/14 \
--host-prefix $ROSA_HOST_PREFIX \
--subnet-ids $ROSA_SUBNET_IDS \
--yes

if [ $? -eq 0 ]; then
    echo "Creating operator roles..."
    rosa create operator-roles --mode auto --yes --cluster $ROSA_CLUSTER_NAME
    echo "Creating OIDC provider..."
    rosa create oidc-provider --mode auto --yes --cluster $ROSA_CLUSTER_NAME
    echo "Monitoring logs until cluster provisioning is complete..."
    rosa logs install --cluster $ROSA_CLUSTER_NAME --watch
    echo "Getting final state for storage as TF state..."
    rosa describe cluster --cluster $ROSA_CLUSTER_NAME --output json
else
    echo "Initial cluster creation command failed and returned $?"
fi