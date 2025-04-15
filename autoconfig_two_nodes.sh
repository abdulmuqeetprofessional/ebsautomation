#!/bin/bash
#Author : Abdul Muqeet
# Define nodes and file systems
NODES=("node1" "node2")
FILESYSTEMS=("run" "patch")

# AutoConfig script path
AUTOCONFIG_SCRIPT="adautocfg.sh"

# Function to run AutoConfig on a given node and file system
run_autoconfig() {
  local NODE=$1
  local FS=$2

  echo "Connecting to $NODE and sourcing $FS file system..."
  ssh oracle@$NODE "
    source /path/to/EBSapps.env $FS &&
    cd /path/to/autoconfig/location &&
    ./$AUTOCONFIG_SCRIPT
  "

  if [ $? -eq 0 ]; then
    echo "AutoConfig completed successfully on $NODE for $FS."
  else
    echo "AutoConfig failed on $NODE for $FS. Exiting."
    exit 1
  fi
}

# Main logic
for NODE in "${NODES[@]}"; do
  for FS in "${FILESYSTEMS[@]}"; do
    run_autoconfig $NODE $FS
  done
done

# Repeat AutoConfig on the run file system of node1
echo "Re-running AutoConfig on node1 for run file system..."
run_autoconfig "node1" "run"

echo "AutoConfig process completed successfully!"
