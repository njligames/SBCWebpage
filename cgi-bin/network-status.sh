#!/usr/bin/haserl
<? 
. /usr/lib/webif/webif.sh

load_settings wireless_network
wifi_lanconfig=$lanconfig
load_settings network

header "Network" "Status" "Network status"

cat <<EOF
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td colspan="2" class="listtopic">Network</td>
        </tr>
EOF

for iface in $( /sbin/ifconfig -a|grep -E "eth|wlan" |cut -d" " -f1 ); do

curr_ipaddr="$(/sbin/ifconfig $iface | sed -n '/inet addr:/s/ *inet addr:\([[:digit:].]*\) .*/\1/p')"
curr_gateway="$(route -n | grep "^0.0.0.0.*UG.*$iface" | awk {'print $2'})"
curr_subnetmask="$(/sbin/ifconfig $iface | grep "Mask:" | cut -d: -f4)"
macaddr="$(/sbin/ifconfig $iface | grep HWaddr | cut -b39-)"

if [ -z "$( /sbin/ifconfig $iface | grep UP )" ]; then
	updown=DOWN
else
	updown=UP
fi

if [ "$iface" = "eth0" ]; then
	mode=$lanconfig
else
	mode=$wifi_lanconfig
fi

if [ ! -z $( echo $iface | grep wlan ) ]; then
	lantype=wireless
	if [ "$updown" = "UP" ]; then
		# can be ASSOCIATING, SCANNING, COMPLETED, ASSOCIATED, 4WAY_HANDSHAKE
		wifi_state=$( wpa_cli -i$iface status | grep "^wpa_state=" | cut -d= -f2 )
		[ "$wifi_state" = "" ] && wifi_state=ERROR

		if [ "$wifi_state" = "COMPLETED" ]; then
			wifi_ssid=$( wpa_cli -i$iface status | grep "^ssid=" | cut -d= -f2 )
			wifi_seq=$( wpa_cli -i$iface status | grep "^key_mgmt=" | cut -d= -f2 )
			wifi_eap_state=$( wpa_cli -i$iface status | grep "^EAP state=" | cut -d= -f2 )
			equal "$wifi_seq" "NONE" && {
				wifi_cipher=$( wpa_cli -i$iface status | grep "^group_cipher=" | cut -d= -f2 )
				! empty "$wifi_cipher" && wifi_seq=$wifi_cipher
			}
		fi
	else
		wifi_state=DOWN
	fi
else
	lantype=wired
fi

cat <<EOF
        <tr>
          <td class="vncellt" style="width:25%">Adapter</td>
          <td class="listr" style="width:75%">$iface ($updown)</td>
        </tr>
        <tr>
          <td class="vncellt" style="width:25%">Type</td>
          <td class="listr" style="width:75%">$lantype</td>
        </tr>
        <tr>
          <td class="vncellt" style="width:25%">Mode</td>
          <td class="listr" style="width:75%">$mode</td>
        </tr>
        <tr>
          <td class="vncellt" style="width:25%">IP Address</td>
          <td class="listr" style="width:75%">$curr_ipaddr</td>
        </tr>
        <tr>
          <td class="vncellt" style="width:25%">Subnet Mask</td>
          <td class="listr" style="width:75%">$curr_subnetmask</td>
        </tr>
        <tr>
          <td class="vncellt" style="width:25%">Gateway</td>
          <td class="listr" style="width:75%">$curr_gateway</td>
        </tr>
        <tr>
          <td class="vncellt" style="width:25%">MAC Address</td>
          <td class="listr" style="width:75%">$macaddr</td>
        </tr>
EOF

if [ "$lantype" = "wireless" ]; then
cat <<EOF
        <tr>
          <td class="vncellt" style="width:25%">Wireless State</td>
          <td class="listr" style="width:75%">$wifi_state</td>
        </tr>
EOF
	if [ "$wifi_eap_state" != "" ]; then

	cat <<EOF
        <tr>
          <td class="vncellt" style="width:25%">EAP State</td>
          <td class="listr" style="width:75%">$wifi_eap_state</td>
        </tr>
EOF
	fi
	
	if [ "$wifi_state" = "COMPLETED" ]; then
	cat <<EOF
        <tr>
          <td class="vncellt" style="width:25%">Wireless SSID</td>
          <td class="listr" style="width:75%">$wifi_ssid</td>
        </tr>
        <tr>
          <td class="vncellt" style="width:25%">Wireless Security</td>
          <td class="listr" style="width:75%">$wifi_seq</td>
        </tr>
EOF
	fi

fi

cat <<EOF
        <tr>
          <td colspan="2" class="listb" style="height:12px">&nbsp;</td>
        </tr>
EOF

done

cat <<EOF
        <tr>
          <td class="vncellt" style="width:25%">DNS Server(s)</td>
          <td class="listr" style="width:75%">$(cat /etc/resolv.conf | grep "nameserver" | awk {'printf("%s<br />", $2)'})</td>
        </tr>
</table>
EOF

footer 
?>


<!--
##WEBIF:name:Network:100:Status
##WEBIF:name:Status:200:Network
-->
