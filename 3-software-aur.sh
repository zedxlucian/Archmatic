#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Post Install Setup and Config
#-------------------------------------------------------------------------

echo -e "\nINSTALLING AUR SOFTWARE\n"
# You can solve users running this script as root with this and then doing the same for the next for statement. However I will leave this up to you.

echo "CLONING: YAY"
cd ~
git clone "https://aur.archlinux.org/yay.git"
cd "${HOME}/yay"
makepkg -si --noconfirm
cd ~

PKGS=(
'brave-bin' # Brave Browser
'dxvk-bin' # DXVK DirectX to Vulcan
'lightlyshaders-git'
'mangohud' # Gaming FPS Counter
'mangohud-common'
'ocs-url' # install packages from websites
'timeshift'
'nerd-fonts-ubuntu-mono' # Nerdfont package
'autojump'
)


for PKG in "${PKGS[@]}"; do
    yay -S --noconfirm $PKG --needed
done

echo -e "\nDone!\n"
echo "--------------------------------------"
echo "--  SYSTEM READY FOR 9-post-setup   --"
echo "--------------------------------------"
exit
