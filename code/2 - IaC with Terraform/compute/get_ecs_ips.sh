TASKS=`aws ecs list-tasks --cluster ecs-f5-demo --output json \
| jq -r '.taskArns[]'`
IPS=`aws ecs describe-tasks --cluster ecs-f5-demo --tasks \
$TASKS | \
jq -r '[ .tasks[].containers[].networkInterfaces[].privateIpv4Address | .] | join(",")' `

jq -n --arg ips "$IPS" '{"ips": $ips}'