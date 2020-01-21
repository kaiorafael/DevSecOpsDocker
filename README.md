# DevSecOpsDocker
A PoC on how to create DevSecOps for Docker. 

This is an example on how to apply DevSecOps using AWS. Please note that the code provided here might generate additional charges under your AWS billing. Use at your own risk.

In summary, the scripts will

1. Create basic infrastructure such as VPC, Subnets, SSH keys, NAT Gateway, Load Balancer
2. Launch optimized Docker image 
3. Hardening the OS and Docker application.

# How to use?

### Setting Up AWS Infrastructure

```sh
git clone https://github.com/kaiorafael/DevSecOpsDocker.git
cd DevSecOpsDocker/
```

*Make* sure to chage the region the region where you want to create all the resource. You can change the variable `REGION` from file `functions.sh`

```sh
cat functions.sh 
#####Variables
REGION="eu-north-1"
REGIONOPT="--region ${REGION}"
OUTFORMAT="--output json"
RESOURCES="resources"
```

After the region was defined, you need to create the `resources` directory. If you want to use a different name, please update the variable `RESOURCES` and create the path you need.

```sh
mkdir resources
```

This directory is used to save all information from resources created during the script usage. You will find the following content after using these scripts. I would strongly recommend to not remove those files. In case you need better resource managment, please use AWS CloudFormation.

```sh
ls resources/
ec2id.json         routetable.json    sshkeypair.pem     subnet2.json
internetgw.json    securitygroup.json subnet1.json       vpc.json
```

To create your infrastructure, please run:

```sh
bash infra-setup.sh create
```

### Preparing Docker

To create your Docker web application, please run:

```sh
bash docker-setup.sh create
```

Docker is running in Private Subnet (subnet 2), therfore there is a NAT Gateway in Subnet 1 and Route in Subnet 2. To have access to Docker App, you should use Load Balancer as described below:

```sh
bash load-balancer.sh create
```

### Cleaning the resources 

In case the resources are not necessary anymore, you can clean it

```sh
bash load-balancer.sh delete
bash docker-setup.sh delete
bash infra-setup.sh delete
```