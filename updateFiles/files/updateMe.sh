#! /bin/bash

echo "Starting Wombat Update"


# Change to home directory
cd /home/kipr || { echo "Failed to cd to /home/kipr"; exit 1; }

# Remove old wombat-os if it exists
if [ -d "wombat-os-old" ]; then
  sudo rm -R wombat-os-old || { echo "Failed to remove old wombat-os"; exit 1; }
fi

# Remove directory if it exists
WOMBAT_OS="wombat-os"
if [ -d $WOMBAT_OS ]; then
  sudo mv wombat-os wombat-os-old || { echo "Failed to rename wombat-os"; exit 1; }
fi

# Clone the repo
echo "Cloning wombat-os"
git clone https://github.com/kipr/wombat-os.git || { 
  echo "Failed to clone wombat-os, restoring old version";
  sudo rm -R wombat-os;
  sudo mv wombat-os-old wombat-os;
  echo "Old version restored";
  exit 1; 
}

# Change permissions of wombat-os
sudo chmod -R 777 /home/kipr/wombat-os || { echo "Failed to chmod wombat-os"; exit 1; }

# Change to updateFiles directory
cd /home/kipr/wombat-os/updateFiles || { echo "Failed to cd to updateFiles"; exit 1; }

echo "Update downloaded, running update script"

# Run update script
sudo chmod u+x wombat_update.sh && sudo ./wombat_update.sh || { echo "Update Failed"; exit 1; }