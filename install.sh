#!/usr/bin/bash
#check for arch flag
if [ "$1" == "arm64" ]; then
    sonixd_arch="arm64"
else
    sonixd_arch="x64"
fi

sonixd_latest_version=$(wget github.com/jeffvli/sonixd/releases/latest -q -O - | grep "<title>" | grep -o '[0-9]*[.][0-9]*[.]*[0-9]*\+')
install_dir=$HOME/.local/share/sonixd

cd /tmp
rm -Rf Sonixd* icon.png
wget https://github.com/jeffvli/sonixd/releases/download/v${sonixd_latest_version}/Sonixd-${sonixd_latest_version}-linux-${sonixd_arch}.tar.xz
wget https://github.com/jeffvli/sonixd/raw/main/assets/icon.png
mkdir -p ${install_dir}

if [ -f Sonixd-${sonixd_latest_version}-linux-${sonixd_arch}.tar.xz ];then
    rm -Rf ${install_dir}/*
    tar -xf Sonixd-${sonixd_latest_version}-linux-${sonixd_arch}.tar.xz
    mv Sonixd-${sonixd_latest_version}-linux-${sonixd_arch}/* ${install_dir}/
    mv icon.png ${install_dir}/
    rm -Rf Sonixd*
else
    echo "erro download"
    exit 2
fi

echo ${sonixd_latest_version} > ${install_dir}/version
echo ${sonixd_arch} > ${install_dir}/arch

#Create update.sh
cat > ${install_dir}/update.sh <<UPDATESH
#!/bin/bash
install_dir=\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
current_version=\$(wget github.com/jeffvli/sonixd/releases/latest -q -O - | grep "<title>" | grep -o '[0-9]*[.][0-9]*[.]*[0-9]*\+')
local_version=\$(cat \${install_dir}/version)
local_arch=\$(cat \${install_dir}/arch)
if [ \${current_version} == \${local_version} ] || [ \${current_version} == \"\" ]; then
    notify-send -a sonixd -i \${install_dir}/icon.png -t 1 "Latest version installed!"
else
    notify-send -a sonixd -i \${install_dir}/icon.png -t 1 "Download new version...!"
    curl https://raw.githubusercontent.com/zicstardust/sonixd-linux-installer/main/install.sh | bash -s \${local_arch}
    if [ \$? == "0" ]; then
        notify-send -a sonixd -i \${install_dir}/icon.png -t 1 "New version installed!"
    else
        notify-send -a sonixd -i \${install_dir}/icon.png -t 1 "error, new version not instaled!"
    fi
fi
exit 2

UPDATESH
chmod +x ${install_dir}/update.sh

#Create uninstall.sh
cat > ${install_dir}/uninstall.sh <<UNINSTALLSH
#!/usr/bin/env bash
install_dir=\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
rm -Rf \${install_dir}
rm -f \${HOME}/.local/share/applications/sonixd.desktop
notify-send -a sonixd -t 1 "sonixd removed!"
exit 2

UNINSTALLSH
chmod +x ${install_dir}/uninstall.sh

#Create sonixd.desktop
cat > ${HOME}/.local/share/applications/sonixd.desktop <<DESKTOPENTRY
[Desktop Entry]
version=${sonixd_latest_version}
Name=Sonixd
Comment=A full-featured Subsonic/Jellyfin compatible desktop music player.
Type=Application
Terminal=false
Exec=${install_dir}/sonixd
StartupNotify=true
Icon=${install_dir}/icon.png
Categories=Media;Music;Media;Player;
Keywords=music;player;media;sonixd;jellyfin;subsonic;
StartupWMClass=Sonixd
Actions=Update;Uninstall;
[Desktop Action Update]
Name=Check Update
Exec=${install_dir}/update.sh
[Desktop Action Uninstall]
Name=Uninstall
Exec=${install_dir}/uninstall.sh
DESKTOPENTRY
chmod +x ${HOME}/.local/share/applications/sonixd.desktop

echo ""
echo "sonixd ${sonixd_latest_version} ${sonixd_arch} installed!"
