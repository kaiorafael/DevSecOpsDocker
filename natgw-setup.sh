# generic functions / variables
. functions.sh

##### creation phase
allocate_IPAddress() {
    aws ec2 allocate-address \
    --domain vpc \
    ${REGIONOPT} ${OUTFORMAT} > ${EIPAlloc}
}

create_NATGW() {
    # it will create NTGW in Subnt 1
    #TODO Refact
    aws ec2 create-nat-gateway \
        --subnet-id $(get_SUBNETID $OUTSUBNET1) \
        --allocation-id $(get_EIPAlloc) \
        ${REGIONOPT} ${OUTFORMAT} > ${NATGW}

    #Hold Code - aka async :)
    NATGWM=$(cat ${NATGW})
    NATGW_status="pending"

    while [ ${NATGW_status} == "pending" ]
    do
        sleep 10
        NATGW_status=$(aws ec2 describe-nat-gateways \
            --nat-gateway-ids $(get_NATGW) \
            ${REGIONOPT} ${OUTFORMAT} \
            --query "NatGateways[].State[]" --output text
        )
        echo "waiting for NATGW....$(get_NATGW)"
    done
    #updating NATGW
    echo "NATGW: $(get_NATGW) is ready"
}

create_NATGW_ROUTETABLE() {
    aws ec2 create-route-table --vpc-id $(get_VPCID) ${REGIONOPT} ${OUTFORMAT} > ${OUTNATGWROUTETABLE}
}

create_NATGW_ROUTE() {
    aws ec2 create-route \
        --route-table-id $(get_NATGW_ROUTETABLE) \
        --destination-cidr-block 0.0.0.0/0 \
        --gateway-id $(get_NATGW) \
        ${REGIONOPT}
}

associate_NATGW_SUBNET() {
    #TODO refact
    aws ec2 associate-route-table  \
        --subnet-id $(get_SUBNETID $OUTSUBNET2) \
        --route-table-id $(get_NATGW_ROUTETABLE) \
        ${REGIONOPT} ${OUTFORMAT} > ${OUTNATGWROUTETABLE_ASSOCIATIONID}
}

##### Delete phase
disassociate_NATGW_SUBNET() {
    #TODO refact
    aws ec2 disassociate-route-table \
        --association-id $(get_associate_NATGW_SUBNET)\
        ${REGIONOPT} ${OUTFORMAT}
}

delete_NATGW_ROUTETABLE() {
    aws ec2 delete-route-table \
        --route-table-id $(get_NATGW_ROUTETABLE) \
        ${REGIONOPT} ${OUTFORMAT}
}

delete_NATGW() {
    aws ec2 delete-nat-gateway \
        --nat-gateway-id $(get_NATGW) \
        ${REGIONOPT} ${OUTFORMAT}

    # wait NAT to be deleted
    NATGW_status="deleting"
    while [ ${NATGW_status} != "deleted" ]
    do
        sleep 10
        NATGW_status=$(aws ec2 describe-nat-gateways \
            --nat-gateway-ids $(get_NATGW) \
            ${REGIONOPT} ${OUTFORMAT} \
            --query "NatGateways[].State[]" --output text
        )
        echo "waiting for NATGW....$(get_NATGW) deletion"
    done
    #updating NATGW
    echo "NATGW: $(get_NATGW) is deleted"
}

release_IPAdress() {
    aws ec2 release-address \
        --allocation-id $(get_EIPAlloc) \
        ${REGIONOPT} ${OUTFORMAT}
}

### Main code
create_NAT() {
    echo "Creating NAT"
    allocate_IPAddress
    create_NATGW
    create_NATGW_ROUTETABLE
    create_NATGW_ROUTE
    associate_NATGW_SUBNET
}

delete_NAT() {

    disassociate_NATGW_SUBNET
    delete_NATGW_ROUTETABLE
    delete_NATGW
    release_IPAdress
}

### Test
#create_NAT
#delete_NAT


