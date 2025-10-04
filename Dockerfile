FROM ubuntu:22.04

# File created by EFXTv
# Contact t.me/errorfix_tv
# Thanks to entire team

# Use noninteractive frontend for package installation
ENV DEBIAN_FRONTEND=noninteractive \
    USER=root \
    HOME=/root

# Install dependencies, **including a browser (firefox)** and the **default terminal (xfce4-terminal)**
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    curl wget git python3 python3-pip zip unzip sudo \
    openssh-server nano xfce4 xfce4-goodies tightvncserver \
    novnc websockify dbus-x11 x11-xserver-utils **firefox xfce4-terminal** && \
    rm -rf /var/lib/apt/lists/*

# ---
# Setup SSH
RUN mkdir /var/run/sshd && \
    echo 'root:root' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# ---
# Setup VNC
RUN mkdir -p /root/.vnc && \
    echo "rootvnc" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd && \
    # The VNC xstartup only needs to launch the window manager
    echo "xrdb $HOME/.Xresources\nstartxfce4 &" > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# ---
# Configure XFCE Desktop to show Terminal and Browser
# XFCE stores its config in XML files. This command ensures the panel has some basic launchers.
# This is a common way to ensure a working panel config on first startup.
RUN mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml && \
    cat <<EOF > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels">
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-non-desktop" type="string" value="p=6;x=0;y=0"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
      </property>
      <property name="size" type="uint" value="30"/>
    </property>
  </property>
  <property name="plugins">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-2" type="string" value="separator"/>
    <property name="plugin-3" type="string" value="tasklist"/>
    <property name="plugin-4" type="string" value="separator"/>
    <property name="plugin-5" type="string" value="systray"/>
    <property name="plugin-6" type="string" value="clock"/>
  </property>
</channel>
EOF

# ---
# Dummy readme
RUN echo "vncserver :1 -geometry 1920x940 -depth 24 #start server\nvncserver -kill :1 #stop server\nAccess localhost:6080" > /readme.txt

# ---
# Startup script
RUN echo '#!/bin/bash\n' \
    'export USER=root\n' \
    'service ssh start\n' \
    # Remove lock file if VNC was not stopped cleanly
    'rm -f /tmp/.X1-lock\n' \
    'vncserver :1 -geometry 1920x940 -depth 24\n' \
    'websockify --web=/usr/share/novnc/ 6080 localhost:5901 &\n' \
    'tail -f /dev/null\n' \
    > /startup.sh && chmod +x /startup.sh

EXPOSE 6080

CMD ["/startup.sh"]
