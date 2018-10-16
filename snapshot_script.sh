#!/bin/bash

# Specifying the region of AWS
REGION="us-east-1"

# Specifying the location of aws binary
AWS="aws"

DATE=$(date +%Y-%m-%d-%H:%M)

# Getting all volumes with tag Production
vol_id=$( aws ec2 describe-volumes --filters "Name=attachment.status, Values=attached" "Name=tag:Environment,Values=Production" --query 'Volumes[].Attachments[].VolumeId' --output text --region $REGION )

##Checking if volume list is empty
if [ -z "$vol_id" ]
then
   echo "There is no volume with such tag"
   exit 1
fi


# Iterating each volume
        for i in $vol_id
        do
           #Getting each instance id associated with that volume
           inst_id=$(aws ec2 describe-volumes --volume-ids $i --query 'Volumes[].Attachments[].InstanceId' --output text --region $REGION )

           #Checking the state of the above instance
           state=$(aws ec2 describe-instances --instance-ids $inst_id  --query 'Reservations[].Instances[].State[].Name' --output text --region $REGION )

           if [ $state = 'running' ]
           then
                #Getting Instance Name
                inst_name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$inst_id" "Name=key,Values=Name" --query 'Tags[].Value' --output text --region $REGION )
                echo "$inst_name"
                                #Getting volume block
                block=$(aws ec2 describe-volumes --volume-ids $i --query 'Volumes[].Attachments[].Device'  --output text --region $REGION )
                echo "$block"
                                #Creating snapshot
                snapid=$(aws ec2 create-snapshot --volume-id $i --query 'SnapshotId' --description  "New Automated-SnapShot-$inst_name-$block-$DATE" --output text --region $REGION )
                                echo "$snapid"
                if [ $? == 0 ]
                then
                    echo $block | grep sda1
                    if [ $? == 0 ]
                    then
                    aws ec2 create-tags --resources $snapid --tags Key=Name,Value="$inst_name-root-disk" --output text --region $REGION
                    else
                    aws ec2 create-tags --resources $snapid --tags Key=Name,Value="$inst_name-secondary-disk" --output text --region $REGION
                    fi

                else

                    echo "Snapshots creation error !! ....Please Check and Resolve"
                              fi

            else
                echo "stopped instance $inst_id"
        fi
        done

  echo "====================================Created Snapshots Successfully================================"

retention_days="0"
region="us-east-1"
retention_date_in_seconds=$(date +%s --date "$retention_days days ago")

                snapshot_list=$(aws ec2 describe-snapshots --filters "Name=tag:Name,Values=Production"  --region $region --query Snapshots[].SnapshotId --output text)
                for snapshot in $snapshot_list; do
                        echo "Checking $snapshot..."
                        # Check age of snapshot
                        snapshot_date=$(aws ec2 describe-snapshots --region $region --output=text --snapshot-ids $snapshot --query Snapshots[].StartTime | awk -F "T" '{printf "%s\n", $1}')
                        snapshot_date_in_seconds=$(date "--date=$snapshot_date" +%s)
                        snapshot_description=$(aws ec2 describe-snapshots --snapshot-id $snapshot --region $region --query Snapshots[].Description)

                        if (( $snapshot_date_in_seconds >= $retention_date_in_seconds )); then
                                echo "DELETING snapshot $snapshot. Description: $snapshot_description ..."
                                aws ec2 delete-snapshot --region $region --snapshot-id $snapshot
                        else
                                echo "Not deleting snapshot $snapshot. Description: $snapshot_description ..."
                        fi
                done
   echo "=======================================Deleted Snapshots Successfully==============================="
