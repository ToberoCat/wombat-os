cd /home/kipr/wombat-os || echo "Failed to cd to wombat-os"
git reset HEAD --hard || echo "Failed to reset git"
git pull || echo "Failed to pull git"
sudo chmod u+x wombat_update.sh && sudo ./wombat_update.sh && echo "Update Complete" || echo "Update Failed"
