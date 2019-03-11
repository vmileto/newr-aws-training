#!/bin/bash
#
# AUTHOR: Paulo Monteiro @ New Relic - 2019-03
#
# - THESE ARE GUIDELINES ONLY. DON'T EXECUTE IT DIRECTLY BUT BLOCK BY BLOCK
#

#
# PART 1 - CONFIGURE, LAUNCH, AND MONITOR AN EC2 INSTANCE / EKS CLUSTER
#

# first things first

sudo yum update -y

# setup some variables

echo "\
export YOUR_GITHUB_USER='thywoof'

export YOUR_NAME='Winston Wolfe'
export YOUR_COMPANY_NAME='Marsellus Wallace Inc.'

export YOUR_LICENSE_KEY=cec283018fe0214f68b46ecc1223ffc43818d5ca

export YOUR_AWS_REGION='us-west-2'
export YOUR_CLUSTER_NAME='winston-wolf'
export YOUR_PASSPHRASE='I-Am-Get-Medieval-On-Your-SaaS'

export YOUR_USERS_SERVICE_URL=http://localhost:3002
export YOUR_MOVIES_SERVICE_URL=http://localhost:3004
" > ~/.globals
. ~/.globals && env | grep YOUR

# install NR Infra agent

echo "\
license_key: ${YOUR_LICENSE_KEY}
custom_attributes:
    student: ${YOUR_NAME}
    company: ${YOUR_COMPANY_NAME}
" | sudo tee -a /etc/newrelic-infra.yml
sudo curl -sLo /etc/yum.repos.d/newrelic-infra.repo \
  https://download.newrelic.com/infrastructure_agent/linux/yum/el/6/x86_64/newrelic-infra.repo
sudo yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'
sudo yum install newrelic-infra -y

# install kubectl

curl -sLO https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin

# install heptio-authenticator-aws

curl -sLo heptio-authenticator-aws https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.3.0/heptio-authenticator-aws_0.3.0_linux_amd64
chmod +x heptio-authenticator-aws
sudo mv heptio-authenticator-aws /usr/local/bin

# install docker-compose

curl -sLo docker-compose "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)"
chmod +x docker-compose
sudo mv docker-compose /usr/local/bin

# install git / docker

sudo yum install git docker-io -y
sudo service docker start
sudo usermod -aG docker ec2-user

# LOGOUT/LOGIN FOR GROUP CHANGE TO TAKE EFFECT

. ~/.globals && env | grep YOUR
sudo docker login

# create an SSH key

rm -f /home/ec2-user/.ssh/id_rsa
ssh-keygen -q -t rsa -N "${YOUR_PASSPHRASE}" -f /home/ec2-user/.ssh/id_rsa

# configure AWS cli

mkdir ~/.aws
printf "[default]\noutput = json\nregion = us-west-2\n" > .aws/config
aws configure

# install eksctl

curl -sL "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# create the basic EKS cluster (when done consider saving ~/.kube/config to a safe place)

eksctl create cluster --region=${YOUR_AWS_REGION} --name=${YOUR_CLUSTER_NAME}

# install kube state metrics (new relic K8 integration dependency)

curl -sLo /tmp/kube-state-metrics-1.4.zip https://codeload.github.com/kubernetes/kube-state-metrics/zip/release-1.4
unzip /tmp/kube-state-metrics-1.4.zip -d /tmp
kubectl apply -f /tmp/kube-state-metrics-release-1.4/kubernetes

# install NR K8 integration

curl -sLO https://download.newrelic.com/infrastructure_agent/integrations/kubernetes/newrelic-infrastructure-k8s-latest.yaml
sed -i -e "s/<YOUR_CLUSTER_NAME>/${YOUR_CLUSTER_NAME}/g" newrelic-infrastructure-k8s-latest.yaml
sed -i -e "s/<YOUR_LICENSE_KEY>/${YOUR_LICENSE_KEY}/g" newrelic-infrastructure-k8s-latest.yaml
kubectl create -f newrelic-infrastructure-k8s-latest.yaml

# check if everything is sound

kubectl get pods --all-namespaces --no-headers -o custom-columns=":metadata.name,:metadata.namespace"

#
# PART 2 - DEPLOY A MICROSERVICES APP USING DOCKER
#

# clone the repository

cd ~ && git clone "https://github.com/${YOUR_GITHUB_USER}/newr-aws-training"

# set our variables before building

. ~/.globals
export YOUR_WEB_SERVICE_URL="http://$(curl -s http://169.254.169.254/latest/meta-data/public-hostname):4000"
export YOUR_USERS_SERVICE_URL="http://$(curl -s http://169.254.169.254/latest/meta-data/public-hostname):3002"
export YOUR_MOVIES_SERVICE_URL="http://$(curl -s http://169.254.169.254/latest/meta-data/public-hostname):3004"
env | grep YOUR

# build the app

cd ~/newr-aws-training
docker-compose build

# bring the services up

printf "\n\n\nWEB SERVICE URL:\n\n\n${YOUR_WEB_SERVICE_URL}\n\n\n"
docker-compose up

#
# PART 3 - APM INSTRUMENTATION - OPEN PROJECT ON ATOM EDITOR
#
#  - ONLY CONTINUE AFTER CHANGES IN ATOM ARE COMMITED
#

# bring our local EC2 services down and reclaim back some disk space

docker-compose down
docker volumes prune

# pull repository changes, build and push image to DockerHub

cd ~/newr-aws-training && git pull
docker-compose build
docker-compose push

#
# PART 4 - DEPLOY A MICROSERVICES APP ON EKS
#

# deploy both databases

kubectl apply -f manifests/users-db-deployment.yaml
kubectl apply -f manifests/users-db-service.yaml
kubectl apply -f manifests/movies-db-deployment.yaml
kubectl apply -f manifests/movies-db-service.yaml

# deploy users service and update users-service endpoint to LB public DNS

kubectl apply -f manifests/users-service-deployment.yaml
kubectl apply -f manifests/users-service-service.yaml

export YOUR_USERS_SERVICE_URL="http://$(
aws elb describe-load-balancers --output=text \
  --query 'LoadBalancerDescriptions[?ListenerDescriptions[0].Listener.LoadBalancerPort == `3002`].DNSName'
):3002"

# update the movies-service deployment manifest user endpoint

sed -i -e "s/localhost:3002/${YOUR_USERS_SERVICE_URL}/g" manifests/movies-service-deployment.yaml

# deploy movies service and update users-service endpoint to LB public DNS

kubectl apply -f manifests/movies-service-deployment.yaml
kubectl apply -f manifests/movies-service-service.yaml

export YOUR_MOVIES_SERVICE_URL="http://$(
aws elb describe-load-balancers --output=text \
  --query 'LoadBalancerDescriptions[?ListenerDescriptions[0].Listener.LoadBalancerPort == `3004`].DNSName'
):3004"

# update the web-service deployment manifest users and movies endpoints

sed -i -e "s/localhost:3002/${YOUR_USERS_SERVICE_URL}/g" manifests/web-service-deployment.yaml
sed -i -e "s/localhost:3004/${YOUR_MOVIES_SERVICE_URL}/g" manifests/web-service-deployment.yaml

# deploy web service - SHOULD CREATE A LB automatically on AWS

kubectl apply -f manifests/web-service-deployment.yaml
kubectl apply -f manifests/web-service-service.yaml

export YOUR_MOVIES_SERVICE_URL="http://$(
aws elb describe-load-balancers --output=text \
  --query 'LoadBalancerDescriptions[?ListenerDescriptions[0].Listener.LoadBalancerPort == `4000`].DNSName'
):4000"

# print our application entrypoint URL

printf "\n\n\nOUR WEB URL:\n\n\n${YOUR_MOVIES_SERVICE_URL}\n\n\n"

#
# EPILOGUE - BRING DOWN YOUR CLUSTER AT SOME MOMENT
#

# don't forget to delete your cluster at the end of the training

eksctl delete cluster --region=${YOUR_AWS_REGION} --name=${YOUR_CLUSTER_NAME}
