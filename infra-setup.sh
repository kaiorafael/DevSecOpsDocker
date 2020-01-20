# generic functions / variables
. functions.sh

create_VPC() {
    ### VPC Setup
    echo "Creating VPC"
    aws ec2 create-vpc --cidr-block 10.0.0.0/16 ${REGIONOPT} ${OUTFORMAT} > $OUTVPC
}

create_SUBNETS() {
    # Subnet 1 and 2
    echo "Creating subnets"
    get_VPCID
    aws ec2 create-subnet --vpc-id $(get_VPCID) \
        --cidr-block 10.0.1.0/24 \
        --availability-zone ${REGION}a \
        ${REGIONOPT} ${OUTFORMAT} > ${OUTSUBNET1}

    aws ec2 create-subnet --vpc-id $(get_VPCID) \
        --cidr-block 10.0.2.0/24 \
        --availability-zone ${REGION}b \
        ${REGIONOPT} ${OUTFORMAT} > ${OUTSUBNET2}
}

create_INTERNETGW() {
    aws ec2 create-internet-gateway ${REGIONOPT} ${OUTFORMAT} > ${OUTINTERNETGW}
}

attach_INTERNETGW() {
    aws ec2 attach-internet-gateway \
        --vpc-id $(get_VPCID) \
        --internet-gateway-id $(get_INTERNETGW) \
        ${REGIONOPT}
}

create_ROUTETABLE() {
    aws ec2 create-route-table --vpc-id $(get_VPCID) ${REGIONOPT} ${OUTFORMAT} > ${OUTROUTETABLE}
}

create_ROUTE() {
    aws ec2 create-route \
        --route-table-id $(get_ROUTETABLE) \
        --destination-cidr-block 0.0.0.0/0 \
        --gateway-id $(get_INTERNETGW) \
        ${REGIONOPT}
}

associate_SUBNET() {
    aws ec2 associate-route-table  \
        --subnet-id $(get_SUBNETID $OUTSUBNET1) \
        --route-table-id $(get_ROUTETABLE) \
        ${REGIONOPT}
}

associate_PUBLICIP() {
    aws ec2 modify-subnet-attribute \
        --subnet-id $(get_SUBNETID $OUTSUBNET1) \
        --map-public-ip-on-launch \
        ${REGIONOPT}
}

create_SECURITYGP() {
    aws ec2 create-security-group \
        --group-name SSHADMIN \
        --description "To manage SSH connection" \
        --vpc-id $(get_VPCID) ${REGIONOPT} \
        ${OUTFORMAT} > ${OUTSECURITYGP}
}

allow_INGRESSSGP() {
    for port in 80 22 443
    do
        aws ec2 authorize-security-group-ingress \
            --group-id $(get_SECURITYGP) \
            --protocol tcp \
            --port ${port} \
            --cidr 0.0.0.0/0 \
            ${REGIONOPT}
    done
}

create_SSHKey() {

    # avoid errors when running multiple times
    if [ -f ${OUTSSHKEY} ]; then rm -f ${OUTSSHKEY}; fi

    aws ec2 create-key-pair \
        --key-name DevSecOps \
        --query 'KeyMaterial' \
        --output text > ${OUTSSHKEY} \
        ${REGIONOPT}
    # permissions to use the key
    chmod 400 ${OUTSSHKEY}
}

create_resources() {
    echo "Creating resources"

    create_VPC
    create_SUBNETS
    create_INTERNETGW
    attach_INTERNETGW
    create_ROUTETABLE
    create_ROUTE
    associate_SUBNET
    associate_PUBLICIP
    create_SECURITYGP
    allow_INGRESSSGP
    create_SSHKey
}

delete_resources() {
    echo "Deleting resources"
    aws ec2 delete-security-group --group-id $(get_SECURITYGP) ${REGIONOPT}

    echo "Deleting Subnets"
    aws ec2 delete-subnet --subnet-id $(get_SUBNETID $OUTSUBNET1) ${REGIONOPT}
    aws ec2 delete-subnet --subnet-id $(get_SUBNETID $OUTSUBNET2) ${REGIONOPT}

    echo "Deleting SSH Key"
    aws ec2 delete-key-pair --key-name DevSecOps ${REGIONOPT}

    echo "Deleting routing tables"
    aws ec2 delete-route-table --route-table-id $(get_ROUTETABLE) ${REGIONOPT}
    aws ec2 detach-internet-gateway --internet-gateway-id $(get_INTERNETGW) --vpc-id $(get_VPCID) ${REGIONOPT}
    aws ec2 delete-internet-gateway --internet-gateway-id $(get_INTERNETGW) ${REGIONOPT}

    echo "Deleting VPC"
    aws ec2 delete-vpc --vpc-id $(get_VPCID) ${REGIONOPT}

}

usage_help() {
    echo -e "\n"
    echo "./$0"
    echo -e "\nOptions:"
    echo -e "\tcreate"
    echo -e "\tdelete"
    echo -e "\n"
    exit -1
}

#### Main code
if [ $# -ne 1 ]; then usage_help; fi

if [ "x${1}" == "xcreate" ]; then
    echo "Creating Resources"
    create_resources
elif [ "x${1}" == "xdelete" ]; then
    echo "Cleaning Infra"
    delete_resources
else
    usage_help
fi