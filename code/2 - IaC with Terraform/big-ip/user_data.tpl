#!/bin/bash

# Script must be non-blocking or run in the background.

mkdir -p /config/cloud

cat << 'EOF' > /config/cloud/startup-script.sh


#!/bin/bash

## BIG-IP ONBOARD SCRIPT

LOG_FILE=/var/log/startup-script.log
if [ ! -e $LOG_FILE ]
then
     touch $LOG_FILE
     exec &>>$LOG_FILE
     # nohup $0 0<&- &>/dev/null &
else
    #if file exists, exit as only want to run once
    exit
fi


### ONBOARD INPUT PARAMS 

adminUsername='${admin_username}'
adminPassword='${admin_password}'
CREDS=$adminUsername":"$adminPassword
doUrl='${do_rpm_url}'
doFn=$(basename "$doUrl")
as3Url='${as3_rpm_url}'
as3Fn=$(basename "$as3Url")

### DOWNLOAD ONBOARDING LIBS
# Could be pre-packaged or hosted internally
libs_dir="/config/cloud/aws/node_modules"
mkdir -p $libs_dir
curl -o /config/cloud/f5-cloud-libs.tar.gz --silent --fail --retry 60 -L https://raw.githubusercontent.com/F5Networks/f5-cloud-libs/v3.1.1/dist/f5-cloud-libs.tar.gz
curl -o /config/cloud/f5-cloud-libs-aws.tar.gz --silent --fail --retry 60 -L https://raw.githubusercontent.com/F5Networks/f5-cloud-libs-aws/v1.3.0/dist/f5-cloud-libs-aws.tar.gz
tar xvfz /config/cloud/f5-cloud-libs.tar.gz -C $libs_dir
tar xvfz /config/cloud/f5-cloud-libs-aws.tar.gz -C $libs_dir/f5-cloud-libs/node_modules

### BEGIN BASIC ONBOARDING 

# WAIT FOR MCPD (DATABASE) TO BE UP TO BEGIN F5 CONFIG

. $libs_dir/f5-cloud-libs/scripts/util.sh
wait_for_bigip

# PASSWORD     
# Use Password Provided as Input Param
echo "SET TEMP PASSWORD"
tmsh modify auth user $${adminUsername} password $${adminPassword}
tmsh save /sys config

# Download and Install DO and AS3
echo "DOWNLOAD AND INSTALL DO AND AS3"
curl -o /config/cloud/$${doFn} --silent --fail --retry 10 -L $${doUrl}
curl -o /config/cloud/$${as3Fn} --silent --fail --retry 10 -L $${as3Url}
cp /config/cloud/*.rpm /var/config/rest/downloads/
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$doFn\"}"
curl -u $CREDS -X POST http://localhost/mgmt/shared/iapp/package-management-tasks -d $DATA
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$as3Fn\"}"
curl -u $CREDS -X POST http://localhost/mgmt/shared/iapp/package-management-tasks -d $DATA

date
echo "FINISHED STARTUP SCRIPT"

EOF


# Now run in the background to not block startup
chmod 755 /config/cloud/startup-script.sh 
nohup /config/cloud/startup-script.sh &

