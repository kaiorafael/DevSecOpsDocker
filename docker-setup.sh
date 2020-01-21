# generic functions / variables
. functions.sh

get_VPCID

OPTMIZEDEC2ID="ami-0eb986243d67b81fc"

create_instances() {
    aws ec2 run-instances \
        --image-id ${OPTMIZEDEC2ID} \
        --count 1 \
        --instance-type t3.micro \
        --key-name ${SSHKEYNAME} \
        --security-group-ids $(get_SECURITYGP) \
        --subnet-id $(get_SUBNETID $OUTSUBNET2) \
        --user-data file://userdata.sh \
        ${REGIONOPT} ${OUTFORMAT} > ${EC2ID}

}
update_instanceIDInfo() {
    InstaceID=$(cat ${EC2ID} | jq ".Instances[].InstanceId" | sed "s/\"//g")
    aws ec2 describe-instances --instance-id ${InstaceID} ${REGIONOPT} ${OUTFORMAT} > ${EC2ID}
}

create_resources() {
    echo "Creating Docker instances"
    create_instances
    update_instanceIDInfo
}

delete_resources() {
    echo "Deleting: $(get_EC2ID)"
    aws ec2 terminate-instances \
        --instance-id $(get_EC2ID) \
        ${REGIONOPT}
}

#### Main code
if [ $# -ne 1 ]; then usage_help; fi

if [ "x${1}" == "xcreate" ]; then
    echo "Creating Docker"
    create_resources
elif [ "x${1}" == "xdelete" ]; then
    echo "Cleaning Docker"
    delete_resources
else
    usage_help
fi