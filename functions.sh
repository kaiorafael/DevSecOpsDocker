# additional functions

#####Variables
REGION="eu-north-1"
REGIONOPT="--region ${REGION}"
OUTFORMAT="--output json"
RESOURCES="resources"

####VPC
OUTVPC="${RESOURCES}/vpc.json"
# Subnets
OUTSUBNET1="${RESOURCES}/subnet1.json" #Public
OUTSUBNET2="${RESOURCES}/subnet2.json" #Private
OUTSUBNET3="${RESOURCES}/subnet3.json" #Public

# Internet GW
OUTINTERNETGW="${RESOURCES}/internetgw.json"
# Route table
OUTROUTETABLE="${RESOURCES}/routetable.json"
# SecurityGroups
OUTSECURITYGP="${RESOURCES}/securitygroup.json"
# SSH Key Pair
OUTSSHKEY="${RESOURCES}/sshkeypair.pem"
SSHKEYNAME="DevSecOps"
# EC2 instance
EC2ID="${RESOURCES}/ec2id.json"
# EIP allocation
EIPAlloc="${RESOURCES}/eipalloc.json"
# NAT GW
NATGW="${RESOURCES}/natgw.json"
# NAT GW Route table
OUTNATGWROUTETABLE="${RESOURCES}/natgwroutetable.json"
# NAT GW Route table association ID
OUTNATGWROUTETABLE_ASSOCIATIONID="${RESOURCES}/natgwroutetable_associationid.json"
# Load Balancer
OUTLOADBALANCER="${RESOURCES}/loadbalancer.json"
OUTTARGETGROUP="${RESOURCES}/targetgroup.json"
OUTREGISTERTARGETS="${RESOURCES}/registertargets.json"
OUTLBLISTENERS="${RESOURCES}/loadbalancer_listener.json"

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

# VPC information
get_VPCID(){
    echo $(cat $OUTVPC | jq ".Vpc.VpcId" | sed "s/\"//g")
}

# Subnet ID
get_SUBNETID() {
    subnet=${1}
    if [ -f $subnet ]; then
        RESULT=$(cat ${subnet} | jq ".Subnet.SubnetId" | sed "s/\"//g")
        echo $RESULT
    fi
}

# Internet Gateway
get_INTERNETGW() {
    echo $(cat $OUTINTERNETGW | jq ".InternetGateway.InternetGatewayId" | sed "s/\"//g")
}

# Get route table
get_ROUTETABLE() {
    echo $(cat $OUTROUTETABLE | jq ".RouteTable.RouteTableId" | sed "s/\"//g")
}

# get security groups
get_SECURITYGP() {
    echo $(cat $OUTSECURITYGP | jq ".GroupId" | sed "s/\"//g")
}

get_EC2ID() {
    echo $(cat ${EC2ID} | jq ".Reservations[].Instances[].InstanceId" | sed "s/\"//g")
}

get_EIPAlloc() {
    echo $(cat ${EIPAlloc} | jq ".AllocationId" | sed "s/\"//g")
}

# Get Nat GW route table
get_NATGW_ROUTETABLE() {
    # refact 
    echo $(cat $OUTNATGWROUTETABLE | jq ".RouteTable.RouteTableId" | sed "s/\"//g")
}

get_NATGW() {
    # refact 
    echo $(cat $NATGW | jq ".NatGateway.NatGatewayId" | sed "s/\"//g")
}

get_associate_NATGW_SUBNET() {
    # refact 
    echo $(cat $OUTNATGWROUTETABLE_ASSOCIATIONID | jq ".AssociationId" | sed "s/\"//g")
}

get_LoadBalancerArn() {
    echo $(cat $OUTLOADBALANCER | jq ".LoadBalancers[].LoadBalancerArn" | sed "s/\"//g")
}

get_TargetGroupArn() {
    echo $(cat $OUTTARGETGROUP | jq ".TargetGroups[].TargetGroupArn" | sed "s/\"//g")
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