# generic functions / variables
. functions.sh

create_LOAD_BALANCER() {
    aws elbv2 create-load-balancer \
    --name LB-FrontEnd \
    --subnets $(get_SUBNETID $OUTSUBNET1) $(get_SUBNETID $OUTSUBNET2) $(get_SUBNETID $OUTSUBNET3) \
    --security-groups $(get_SECURITYGP) \
    ${REGIONOPT} ${OUTFORMAT} > ${OUTLOADBALANCER}
}

create_TARGET_GROUP() {
    aws elbv2 create-target-group \
        --name Docker-BackEnd \
        --protocol HTTP --port 80 \
        --vpc-id $(get_VPCID) \
        ${REGIONOPT} ${OUTFORMAT} > ${OUTTARGETGROUP}
}

register_TARGETS() {
    aws elbv2 register-targets \
        --target-group-arn $(get_TargetGroupArn) \
        --targets Id=$(get_EC2ID) \
        ${REGIONOPT} ${OUTFORMAT} > ${OUTREGISTERTARGETS}
}

create_LISTERNER() {
    aws elbv2 create-listener \
        --load-balancer-arn $(get_LoadBalancerArn) \
        --protocol HTTP --port 80  \
        --default-actions Type=forward,TargetGroupArn=$(get_TargetGroupArn) \
        ${REGIONOPT} ${OUTFORMAT} > ${OUTLBLISTENERS}
}

LoadBalancer_INFO() {
    #Hold Code - aka async :)
    NATGWM=$(cat ${NATGW})
    ELB_status="pending"

    while [ ${ELB_status} != "active" ]
    do
        echo "waiting for ELB provision..."
        sleep 5
        ELB_status=$(aws elbv2 describe-load-balancers \
            --load-balancer-arns $(get_LoadBalancerArn) \
            ${REGIONOPT} ${OUTFORMAT} \
            --query "LoadBalancers[].State[].Code" --output text
        )
    done

    DNS=$(aws elbv2 describe-load-balancers \
        --load-balancer-arns $(get_LoadBalancerArn) \
        ${REGIONOPT} ${OUTFORMAT} \
        --query "LoadBalancers[].DNSName" --output text
    )
    echo "Your domain is: ${DNS}"
}

#### delete phase

delete_LOAD_BALANCER() {
    aws elbv2 delete-load-balancer \
    --load-balancer-arn $(get_LoadBalancerArn) \
    ${REGIONOPT} ${OUTFORMAT}
}

delete_TARGET_GROUP() {
    aws elbv2 delete-target-group \
    --target-group-arn $(get_TargetGroupArn) \
    ${REGIONOPT} ${OUTFORMAT}
}

#### Main code

create_LB() {
    echo "Creating Load Balancer"
    create_LOAD_BALANCER
    create_TARGET_GROUP
    register_TARGETS
    create_LISTERNER
    LoadBalancer_INFO
}

delete_LB() {
    delete_LOAD_BALANCER
    sleep 15 #todo add holder
    delete_TARGET_GROUP
}

#create_LB
#delete_LB