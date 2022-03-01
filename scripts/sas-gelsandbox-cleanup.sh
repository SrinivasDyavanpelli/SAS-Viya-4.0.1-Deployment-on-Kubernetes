# Parameters
EXCL_LIST="frarpo|canepg|cangxc"
OFFSET="6h"
CURRENTTIME=$(date)
UTIME=$(date -u)
DATENOW=$(date '+%Y-%m-%dT%H:%M:%SZ')
DATENOWUTC=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
# Show the Resource groups of interest
az group list --query "[?contains(name, 'viya4aks')].[name]" --output tsv | grep -Ev ${EXCL_LIST} | grep -v MC
# Check Activity
rgs=$(az group list --query "[?contains(name, 'viya4aks')].[name]" --output tsv | grep -Ev ${EXCL_LIST} | grep -v MC)
for rg in $rgs
do
  echo "time here : " $CURRENTTIME
  echo "Universal Time, now: " $UTIME
  echo -e "AKS Resource Group to consider: $rg"
  MostRecentActivity=$(az monitor activity-log list -g $rg --end-time ${DATENOWUTC}+0000 --offset ${OFFSET} --query "sort_by([].{op:operationName.value,ActTime:eventTimestamp}, &ActTime)" -o tsv | tail -n 1)
  MostRecentAKSActivity=$(az monitor activity-log list -g $rg --end-time ${DATENOWUTC}+0000 --offset ${OFFSET} --query "sort_by([].{op:operationName.value,ActTime:eventTimestamp}, &ActTime)" -o tsv | grep "managedClusters\/write" | tail -n 1)
  sasid=$(echo $rg | cut -c1-6)
  if [ -z "$MostRecentActivity" ]
  then
    mail -s "Your AKS cluster has been running for more than $OFFSET we will delete it now" $sasid  < /dev/null
    mail -s "WARNING DELETE : for USER: $sasid at ${UTIME}(UTC) - no activity detected in the last ${OFFSET}" frarpo@sas.com,canepg@sas.com < /dev/null
    echo "No activity detected in the last ${OFFSET}. We will delete the AKS cluster in $rg (user:$sasid)"
    az aks delete --name ${sasid}viya4aks-aks --resource-group $rg --yes
    echo "Now we delete the Resource Group..."
    az group delete --name $rg --yes
  else
      echo "Activity detected in the last ${OFFSET} for $rg (user:$sasid)"
      echo "Most Recent Activity: $MostRecentActivity"
      echo "Most Recent AKS Activity: $MostRecentAKSActivity"
      echo "USER: $sasid \n" > /tmp/nodelete.log
      echo "RG: $rg \n" >> /tmp/nodelete.log
      echo "UTC Time: ${UTIME} \n" >> /tmp/nodelete.log
      echo "latest detected activity in the last ${OFFSET} : $MostRecentActivity" >> /tmp/nodelete.log
      mail -s "INFO (NO DELETE): for USER: $sasid at ${UTIME}(UTC)" frarpo@sas.com,canepg@sas.com < /tmp/nodelete.log
  fi
done