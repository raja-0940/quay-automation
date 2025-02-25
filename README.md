# quay-automation
quay automation repository helps to automate RedHat Quay registry deployment in ppc64le environment

# Jenkins installation in ppc64le architecture based RHEL 8 machine
Install prerequisities:
```
yum update -y && yum install -y wget tar vim tree git python3.11 podman skopeo postgresql-server jq fontconfig java-17-openjdk
update-alternatives --config java
java --version
```
Download and add jenkins repository:
```
wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum repolist
yum upgrade
```
Install jenkins:
```
yum install -y jenkins
```
Enable and start the jenkins service:
```
system status jenkins
system enable jenkins
system start jenkins
system status jenkins
```
