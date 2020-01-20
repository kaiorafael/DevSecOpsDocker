# additional functions

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