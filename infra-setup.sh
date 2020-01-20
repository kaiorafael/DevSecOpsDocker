
#####Variables
REGION="eu-north-1"
REGIONOPT="--region ${REGION}"
OUTFORMAT="--output json"
RESOURCES="resources"

####VPC
OUTVPC="${RESOURCES}/vpc.json"
# Subnets
OUTSUBNET1="${RESOURCES}/subnet1.json"
OUTSUBNET2="${RESOURCES}/subnet2.json"
# Internet GW
OUTINTERNETGW="${RESOURCES}/internetgw.json"
# Route table
OUTROUTETABLE="${RESOURCES}/routetable.json"
# SecurityGroups
OUTSECURITYGP="${RESOURCES}/securitygroup.json"
# SSH Key Pair
OUTSSHKEY="${RESOURCES}/sshkeypair.pem"

JQ=$(which jq)
if [ -z $JQ ]; then
    echo "I need JQ to run: https://stedolan.github.io/jq/"
    exit -1
fi

if [ ! -d ${RESOURCES} ]; then
    echo "You should create ${RESOURCES}"
    echo "mkdir ${RESOURCES}"
    exit -1
fi

create_VPC() {
    ### VPC Setup
    echo "Creating VPC"
    aws ec2 create-vpc --cidr-block 10.0.0.0/16 ${REGIONOPT} ${OUTFORMAT} > $OUTVPC
}

get_VPCID(){
    echo $(cat $OUTVPC | jq ".Vpc.VpcId" | sed "s/\"//g")
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

get_SUBNETID() {
    subnet=${1}
    if [ -f $subnet ]; then
        RESULT=$(cat ${subnet} | jq ".Subnet.SubnetId" | sed "s/\"//g")
        echo $RESULT
    fi
}

create_INTERNETGW() {
    aws ec2 create-internet-gateway ${REGIONOPT} ${OUTFORMAT} > ${OUTINTERNETGW}
}

get_INTERNETGW() {
    echo $(cat $OUTINTERNETGW | jq ".InternetGateway.InternetGatewayId" | sed "s/\"//g")
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

get_ROUTETABLE() {
    echo $(cat $OUTROUTETABLE | jq ".RouteTable.RouteTableId" | sed "s/\"//g")
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

get_SECURITYGP() {
    echo $(cat $OUTSECURITYGP | jq ".GroupId" | sed "s/\"//g")
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

    aws ec2 delete-route-table --route-table-id $(get_ROUTETABLE) ${REGIONOPT}
    aws ec2 detach-internet-gateway --internet-gateway-id $(get_INTERNETGW) --vpc-id $(get_VPCID) ${REGIONOPT}
    aws ec2 delete-internet-gateway --internet-gateway-id $(get_INTERNETGW) ${REGIONOPT}
    aws ec2 delete-vpc --vpc-id $(get_VPCID) ${REGIONOPT}

}

create_resources
#sleep 30
#delete_resources