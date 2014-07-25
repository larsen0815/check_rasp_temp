# check\_rasp\_temp

Nagios-Plugin to check the CPU temperature of a Raspberry Pi


## Installation
This example uses a Raspberry Pi with Raspbian Wheezy and a Nagios server running Debian Wheezy.
You might want to use other thresholds, e.g. the Raspberry in our server room is normally running at ~43°C so I have set the threshold to 45°C.

#### Download Plugin
```
cd /usr/lib/nagios/plugins/ && \
wget https://raw.githubusercontent.com/larsen0815/check_rasp_temp/master/check_rasp_temp && \
chmod +x check_rasp_temp
```

#### Plugin needs to be run as root
```
cat <<EOF > /etc/sudoers.d/nagios_rasp_temp
nagios ALL=(root) NOPASSWD: /usr/lib/nagios/plugins/check_rasp_temp
EOF
```

#### Define NRPE command with thresholds
```
cat <<EOF > /etc/nagios/nrpe.d/rasp_temp.cfg
command[check_rasp_temp]=sudo -u root /usr/lib/nagios/plugins/check_rasp_temp -w 60 -c 70
EOF
```

#### Reload NRPE server
```
service nagios-nrpe-server reload
```

#### Define service on your Nagios host
```
define service{
        use                     generic-service
        hostgroup_name          raspberry-devices
        service_description     Temperature
        check_command           check_nrpe!check_rasp_temp
}
```

#### Reload Nagios server
```
service nagios3 reload
```

#### Test your new check on your Nagios server
```
/usr/lib/nagios/plugins/check_nrpe -H #Raspberry_IP# -c check_rasp_temp
```
