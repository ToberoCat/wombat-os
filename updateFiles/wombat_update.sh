#!/bin/bash

HOME=/home/kipr
FW_VERSION=$(cat "$HOME/wombat-os/configFiles/board_fw_version.txt")

echo "   "
echo "Starting Wombat Update #$FW_VERSION"
echo "..."

###############################
#
# Check for Current FW Version
#
###############################

# Check if board_fw_version.txt exists
if [ ! -f /usr/share/kipr/board_fw_version.txt ]; then
    echo "Your version is too old to update. Please reflash your SD card."
    exit 1
fi

###############################
#
# Move update files
#
###############################

# Change to updateFiles directory and copy updateMe.sh to home directory
cd $HOME/wombat-os/updateFiles
cp files/updateMe.sh $HOME
sudo chmod u+x $HOME/updateMe.sh

# Copy .debs to /home/kipr/wombat-os/updateFiles/pkgs
if [ ! -d $HOME/wombat-os/updateFiles/pkgs ]; then
    echo "/home/kipr/wombat-os/updateFiles/pkgs does not exist. Please swap the SD card."
    exit 1
else
    echo "Copying library .debs to /home/kipr/wombat-os/updateFiles/pkgs..."
    cp pkgs/* $HOME/wombat-os/updateFiles/pkgs
fi



# Change to configFiles directory and copy board_fw_version.txt to kipr share directory
cd $HOME/wombat-os/configFiles
if [ ! -d /usr/share/kipr ]; then
    sudo mkdir /usr/share/kipr
fi

sudo scp board_fw_version.txt /usr/share/kipr/
sudo scp journald.conf /etc/systemd/journald.conf
sudo cat interfaces_wifi.txt > /etc/network/interfaces


# Copy new Wombat picture over old one
sudo scp $HOME/wombat-os/wombat.jpg /usr/share/rpd-wallpaper/wombat.jpg

###############################
#
# update boot files
#
###############################

#remount root filesystem as read write
mount -o remount,rw /


###############################
#
# update packages
#
###############################

# harrogate
echo "Updating harrogate..."
cd $HOME/wombat-os/updateFiles
sudo rm -r $HOME/harrogate
sudo tar -C $HOME -zxvf pkgs/harrogate.tar.gz
sudo chmod -R 777 /home/kipr/harrogate
echo "Installing harrogate dependencies..."
cd $HOME/harrogate
npm install browserfy
npm install
sudo npm install -g gulp@4 gulp-cli
echo "Killing any running harrogate processes..."
sudo killall node
echo "Starting harrogate..."
sudo gulp &
cd $HOME/wombat-os/updateFiles

# libkar
echo "Updating libkar..."
sudo dpkg -i pkgs/libkar.deb

# pcompiler
echo "Updating pcompiler..."
sudo dpkg -i pkgs/pcompiler.deb

# libwallaby
echo "Updating libwallaby..."
sudo dpkg -i pkgs/kipr.deb

# botui
echo "Updating botui..."
sudo rm -r /usr/local/bin/botui
sudo dpkg -i pkgs/botui.deb

cd $HOME

###############################
#
# edit misc files
#
###############################

#Remove Create 3 Capn'Proto files from /
echo "Removing Create 3 Capn'Proto files if present..."
capnProtoFiles=$(find / -type f -iname "*capn*" 2>/dev/null)
if [ -n "$capnProtoFiles" ]; then
  echo "Found files to delete:"
  echo "$capnProtoFiles"
  find / -type f -iname "*capn*" -exec rm -f {} \; 2>/dev/null
  echo "Files deleted."
else
  echo "No files matching '*capn*' were found."
fi

#Remove Create 3 deb file if present
echo "Removing Create 3 .deb file if present..."
create3Deb=$(find /home/kipr -type f -iname "create3-0.1.0-Linux.deb" 2>/dev/null)
if [ -n "$create3Deb"  ]; then
  echo "Removing Create 3 deb file"
  sudo rm /home/kipr/create3-0.1.0-Linux.deb
fi

# Copy Wombat Launcher to home directory
TARGET=wombat-os/configFiles/wombat_launcher.sh
echo "Copying the launcher"
sudo cp "$TARGET" "$HOME"
sudo chmod 777 "$HOME/wombat_launcher.sh"

#Adding Default Programs
echo "Checking for Default User"
TARGET="/home/kipr/wombat-os/updateFiles/files/Wombat Factory Test"
CP_TARGET="/home/kipr/Documents/KISS/Default User/"
if [ ! -d "$CP_TARGET" ]; then
    mkdir "$CP_TARGET" || echo "Failed to make Default User"
else 
    echo "Default User already exists"
fi
echo "Adding Default Programs"
sudo cp -R "$TARGET" "$CP_TARGET" || echo "Failed to copy Default Programs"
sudo chmod -R 777 "$CP_TARGET" || echo "Failed to chmod Default Programs"

echo "Flashing the Processor"
cd /home/kipr/wombat-os/flashFiles
sudo chmod +x wallaby_flash wallaby_get_id.sh wallaby_set_serial.sh
sudo ./wallaby_flash

echo "Letting harrogate finish gulping"
sleep 70


###############################
#
# sync and reboot
#
###############################
echo "Finished Wombat Update #$FW_VERSION"

# Remove old wombat-os if it exists
cd /home/kipr
if [ -d "wombat-os-old" ]; then
  sudo rm -R wombat-os-old || { echo "Failed to remove old wombat-os"; exit 1; }
fi

echo "Rebooting..."

echo "Update Complete" && sudo reboot || { echo "Could not reboot"; exit 1; }
