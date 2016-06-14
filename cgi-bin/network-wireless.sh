#!/usr/bin/haserl
<? 
. /usr/lib/webif/webif.sh

load_settings wireless_network

wireless_interfaces=$( ifconfig -a|grep -E "wlan" |cut -d" " -f1 )

############################
# Functions
############################
header_js()
{
	cat <<EOF
<style type="text/css">
<!--
#mytable table {
	margin-left: 1em;
	margin-right: 1em;
	margin-bottom: 1.5em;
	text-align: left;
	font-size: 0.8em;
	border-style: none;
	border-spacing: 0;
	border: thin solid black;
}
#mytable td {
	padding-left: 0.5em;
	padding-right: 1.0em;
}
-->
</style>
EOF
	# creates a Javascirpt 2-D array of wireless networks
	cat <<EOF
<script type="text/javascript">
/* <![CDATA[ */
var wifi_networks = new Array();
var current_network=-1;
EOF

	wpa_cli scan_results | awk -F\	 '
	BEGIN {
		i=0;
	}
	/^[0-9a-fA-F][0-9a-fA-F]:/ {
		printf("wifi_networks[%d]=[\"%s\",\"%d\",\"%d\",\"%s\",\"%s\"];\n",i,$1,(($2 - 2407) / 5),$3,$4,$5);
		i++;
	}'

	cat <<EOF
function update_fields(i)
{
	document.getElementById("ssid").value = wifi_networks[i][4];
	document.getElementById("security").value = get_security(wifi_networks[i][3],true);
	do_security();

	//Also, mode
	if(get_mode(wifi_networks[i][3]) == "AP")
		document.getElementById("new_network_mode").value = "0"
	else
		document.getElementById("new_network_mode").value = "1"
}

function saved_ssids_selected(i)
{
	if(current_network!=i)
		document.getElementById("joinnetwork").disabled = false;
	else
		document.getElementById("joinnetwork").disabled = true;
			
	document.getElementById("deletenetwork").disabled = false;
	document.getElementById("enablenetwork").disabled = false;
	document.getElementById("disablenetwork").disabled = false;
}

function get_security(flags, short)
{
	var security;

	if(flags.search("WPA2")!=-1)
	{
		if(flags.search("EAP")!=-1)
			if(short)
				security ="WPA2E";
			else
				security ="WPA2 Enterprise";
		else if(flags.search("PSK")!=-1)
			if(short)
				security ="WPA2";
			else
				security ="WPA2 Personal";
		else
			security ="Unsupported";
	}
	else if(flags.search("WPA")!=-1)
	{
		if(flags.search("EAP")!=-1)
			if(short)
				security ="WPAE";
			else
				security ="WPA Enterprise";
		else if(flags.search("PSK")!=-1)
			if(short)
				security ="WPA";
			else
				security ="WPA Personal";
		else
			security ="Unsupported";
	}
	else if(flags.search("WEP")!=-1)
	{
		security ="WEP";
	}
	else
		security ="open";

	return security;
}

function get_mode(flags)
{
	if(flags.search("IBSS")!=-1)
		return "Ad-Hoc"
	else
		return "AP"
}

function do_security()
{
	if(document.getElementById("security").value == "open")
	{
		document.getElementById("wep_key_type_field").style.display = "none";
		document.getElementById("wep_key_field").style.display = "none";
		document.getElementById("wpa_login_field").style.display = "none";
		document.getElementById("wpa_key_field").style.display = "none";
	}
	else if(document.getElementById("security").value == "WPA" || document.getElementById("security").value == "WPA2")
	{
		document.getElementById("wep_key_type_field").style.display = "none";
		document.getElementById("wep_key_field").style.display = "none";
		document.getElementById("wpa_login_field").style.display = "none";
		document.getElementById("wpa_key_field").style.display = "";
	}
	else if(document.getElementById("security").value == "WPAE" || document.getElementById("security").value == "WPA2E")
	{
		document.getElementById("wep_key_type_field").style.display = "none";
		document.getElementById("wep_key_field").style.display = "none";
		document.getElementById("wpa_login_field").style.display = "";
		document.getElementById("wpa_key_field").style.display = "";
	}
	else if(document.getElementById("security").value == "WEP")
	{
		document.getElementById("wep_key_type_field").style.display = "";
		document.getElementById("wep_key_field").style.display = "";
		document.getElementById("wpa_login_field").style.display = "none";
		document.getElementById("wpa_key_field").style.display = "none";
	}
}

function wifi_list_radio()
{
	if(wifi_networks.length > 0)
	{
		var odd=true;
		var disabled="";
		var signal="";
		document.write('<div id="mytable"><table>');
		document.write('<tr><td></td><td align="left">SSID</td><td align="right">BSSID</td>'+
				'<td align="right">Channel</td><td align="right">Signal</td><td align="right">Security</td><td align="right">Mode</td></tr>');
		for (i=0;i< wifi_networks.length;i++)
		{
			if(odd)
			{
				odd=false;
				document.write('<tr class="odd">');
			}
			else
			{
				odd=true;
				document.write('<tr>');
			}

			//Wifi signal pictures
			// o 40dB+ SNR = Excellent signal
			// o 25dB to 40dB SNR = Very good signal
			// o 15dB to 25dB SNR = Low signal
			// o 10dB to 15dB SNR = Very low signal
			// o 5dB to 10dB SNR = Very Very low signal
			// o 0dB to 5dB SNR = No signal
			if(wifi_networks[i][2] <= 5)
				signal="<img src=\"/images/wifi0.gif\" title=\"Signal: " + wifi_networks[i][2] + "\" />"
			else if(wifi_networks[i][2] <= 10)
				signal="<img src=\"/images/wifi1.gif\" title=\"Signal: " + wifi_networks[i][2] + "\" />"
			else if(wifi_networks[i][2] <= 15)
				signal="<img src=\"/images/wifi2.gif\" title=\"Signal: " + wifi_networks[i][2] + "\" />"
			else if(wifi_networks[i][2] <= 25)
				signal="<img src=\"/images/wifi3.gif\" title=\"Signal: " + wifi_networks[i][2] + "\" />"
			else if(wifi_networks[i][2] <= 40)
				signal="<img src=\"/images/wifi4.gif\" title=\"Signal: " + wifi_networks[i][2] + "\" />"
			else
				signal="<img src=\"/images/wifi5.gif\" title=\"Signal: " + wifi_networks[i][2] + "\" />"


			//For now, we can't support joining Ad-Hoc networks
			if(get_mode(wifi_networks[i][3]) == "Ad-Hoc")
				disabled=' disabled="disabled"';
			else
				disabled="";

			document.write('<td><input type="radio" name="ssids_select" value="' + i +
					'" onclick="update_fields('+i+')"'+disabled+'/><br /></td>');
			document.write('<td align="left">'+wifi_networks[i][4] +'</td><td align="right">'+ wifi_networks[i][0] +
					'</td><td align="right">'+ wifi_networks[i][1] +'</td><td align="right">'+ 
					signal +'</td><td align="right">'+ get_security(wifi_networks[i][3],false) +
					'</td><td align="right">'+ get_mode(wifi_networks[i][3]) +'</td></tr>');
		}
		document.write("</table></div>");
	}
	else
	{
		document.write("(No wireless networks were detected.)");
	}

}

function showStatic()
{
	document.getElementById("ipaddr_field").style.display = ""
	document.getElementById("subnetmask_field").style.display = ""
	document.getElementById("gateway_field").style.display = ""
	document.getElementById("dnsconfig_auto").disabled = true;
	document.getElementById("dnsconfig_manual").checked = "checked"
	showDNS();
}

function hideStatic()
{
	document.getElementById("ipaddr_field").style.display = "none"
	document.getElementById("subnetmask_field").style.display = "none"
	document.getElementById("gateway_field").style.display = "none"
	document.getElementById("dnsconfig_auto").disabled = false;
}

function showDNS()
{
	document.getElementById("primarydns").style.display = ""
	document.getElementById("secondarydns").style.display = ""
}

function hideDNS()
{
	document.getElementById("primarydns").style.display = "none"
	document.getElementById("secondarydns").style.display = "none"
}
EOF

	if [ "$wireless_interfaces" ]; then
		cat <<EOF
function onPageLoad()
{
	do_security();
EOF
		if [ "$FORM_lanconfig" = "dhcp" ]; then
			echo "	hideStatic();"
		else
			echo "	showStatic();"
		fi
		if [ "$FORM_dnsconfig" = "auto" ]; then
			echo "	hideDNS();"
		else
			echo "	showDNS();"
		fi
		cat <<EOF
}
window.onload = onPageLoad;
EOF
	fi

	cat <<EOF
/* ]]> */
</script>
EOF
}

############################
# Action handlers (pre-header, can't echo)
############################


if ! empty "$FORM_submit"; then

	# re-scan
	if ! empty "$FORM_newscan"; then
		wpa_cli scan >/dev/null 2>/dev/null
		sleep 5

	# joining a network
	elif ! empty "$FORM_joinnetwork"; then

		wpa_cli select_network $FORM_saved_ssids_select >/dev/null 2>/dev/null

		MESSAGE="Network selected for joining. Other networks are disabled until next reboot."

	# enabling a network
	elif ! empty "$FORM_enablenetwork"; then

		wpa_cli enable_network $FORM_saved_ssids_select >/dev/null 2>/dev/null
		wpa_cli save_config >/dev/null 2>/dev/null
		wpa_cli reconfigure

		MESSAGE="Network enabled."

	# disabling a network
	elif ! empty "$FORM_disablenetwork"; then

		wpa_cli disable_network $FORM_saved_ssids_select >/dev/null 2>/dev/null
		wpa_cli save_config >/dev/null 2>/dev/null
		wpa_cli reconfigure

		MESSAGE="Network disabled. This network will not be joined."

	# deleting a network
	elif ! empty "$FORM_deletenetwork"; then
	
		wpa_cli remove_network $FORM_saved_ssids_select >/dev/null 2>/dev/null
		wpa_cli save_config >/dev/null 2>/dev/null
		wpa_cli reconfigure

		MESSAGE="Network deleted."

	# adding a network
	elif ! empty "$FORM_addnetwork"; then

		# Add a new network
		ssid_validate_flags="required"
		case "$FORM_security" in
			open)
				;;
			WEP)
				wep_key_validate_flags="required"
				if equal "$FORM_wep_key_type" "hex"; then
					wep_key_validate_type="wep"
				else
					wep_key_validate_type="wepascii"
				fi
				;;
			WPA|WPA2)
				wpa_key_validate_flags="required"
				wpa_key_validate_type="wpapsk"
				;;
			WPAE|WPA2E)
				wpa_key_validate_flags="required"
				wpa_login_validate_flags="required"
				wpa_key_validate_type="string"
				;;
		esac

		validate <<EOF
ssid|FORM_ssid|SSID|$ssid_validate_flags|$FORM_ssid
$wep_key_validate_type|FORM_wep_key|WEP Key|$wep_key_validate_flags|$FORM_wep_key
string|FORM_wpa_login|WPA Username|$wpa_login_validate_flags|$FORM_wpa_login
$wpa_key_validate_type|FORM_wpa_key|WPA Password|$wpa_key_validate_flags|$FORM_wpa_key
EOF
		# everything validated?
		if equal "$?" 0; then

			# Adding a new network

			# Re-read the config - any networks that were previously joined and not remembered are lost
			wpa_cli reconfigure

			# Removes any networks with the same SSID - maybe change this in the future
			for network_number in $(wpa_cli list_networks | awk "/^[0-9].*$FORM_ssid/ {print \$1}")
			do
				wpa_cli remove_network $network_number >/dev/null 2>/dev/null
			done

			network_number=$( wpa_cli add_network | grep "^[0-9]*$" )
			! empty "$network_number" && {
				wpa_cli set_network $network_number ssid "\"$FORM_ssid\"" >/dev/null 2>/dev/null

				case "$FORM_security" in
					open)
						wpa_cli set_network $network_number key_mgmt NONE >/dev/null 2>/dev/null
						;;
					WEP)
						wpa_cli set_network $network_number key_mgmt NONE >/dev/null 2>/dev/null
						wpa_cli set_network $network_number auth_alg "SHARED OPEN" >/dev/null 2>/dev/null
							
						if equal "$FORM_wep_key_type" "hex"; then
							wpa_cli set_network $network_number wep_key0 $FORM_wep_key >/dev/null 2>/dev/null
						else
							wpa_cli set_network $network_number wep_key0 "\"$FORM_wep_key\"" >/dev/null 2>/dev/null
						fi
						;;
					WPA)
						wpa_cli set_network $network_number proto WPA >/dev/null 2>/dev/null
						wpa_cli set_network $network_number key_mgmt WPA-PSK >/dev/null 2>/dev/null
						wpa_cli set_network $network_number psk "\"$FORM_wpa_key\"" >/dev/null 2>/dev/null
						;;
					WPA2)
						wpa_cli set_network $network_number proto RSN >/dev/null 2>/dev/null
						wpa_cli set_network $network_number key_mgmt WPA-PSK >/dev/null 2>/dev/null
						wpa_cli set_network $network_number psk "\"$FORM_wpa_key\"" >/dev/null 2>/dev/null
						;;
					WPAE)
						wpa_cli set_network $network_number proto WPA >/dev/null 2>/dev/null
						wpa_cli set_network $network_number key_mgmt WPA-EAP >/dev/null 2>/dev/null
						wpa_cli set_network $network_number identity "\"$FORM_wpa_login\"" >/dev/null 2>/dev/null
						wpa_cli set_network $network_number password "\"$FORM_wpa_key\"" >/dev/null 2>/dev/null
						;;
					WPA2E)
						wpa_cli set_network $network_number proto RSN >/dev/null 2>/dev/null
						wpa_cli set_network $network_number key_mgmt WPA-EAP >/dev/null 2>/dev/null
						wpa_cli set_network $network_number identity "\"$FORM_wpa_login\"" >/dev/null 2>/dev/null
						wpa_cli set_network $network_number password "\"$FORM_wpa_key\"" >/dev/null 2>/dev/null
						;;
				esac

				# IBSS
				equal "$FORM_mode" "1" && wpa_cli set_network $network_number mode 1 >/dev/null 2>/dev/null

				# just enables
				wpa_cli enable_network $network_number

				equal "$FORM_remember" "true" && {
					wpa_cli save_config
				}
			}
			
			MESSAGE="New network \"$FORM_ssid\" added."

			# now zero-out the new ssid values
			FORM_ssid=
			FORM_security=open
			FORM_wep_key_type=hex
			FORM_wep_key=
			FORM_wpa_login=
			FORM_wpa_key=
			FORM_remember=true

		fi # everything validated

	# Network settings
	else
		if [ "$FORM_lanconfig" = "static" ]; then
			lan_validate_flags=required
		fi

		if [ $FORM_dnsconfig = "manual" ]; then
			dns_validate_flags=required
		fi

		# Validate everything at once, or we run into problems!
		validate <<EOF
ip|FORM_ipaddr|IP Address|$lan_validate_flags cfg|$FORM_ipaddr
ip|FORM_subnetmask|Subnet Mask|$lan_validate_flags cfg|$FORM_subnetmask
ip|FORM_gateway|Gateway|$lan_validate_flags cfg|$FORM_gateway
ip|FORM_dnsserver1|Primary DNS|$dns_validate_flags cfg|$FORM_dnsserver1
ip|FORM_dnsserver2|Secondary DNS|cfg|$FORM_dnsserver2
EOF

		if equal "$?" 0; then
			save_setting wireless_network lanconfig "$FORM_lanconfig"
			if [ $FORM_lanconfig = "static" ]; then
				save_setting wireless_network ipaddr "$FORM_ipaddr"
				save_setting wireless_network subnetmask "$FORM_subnetmask"
				save_setting wireless_network gateway "$FORM_gateway"
			else
				save_setting wireless_network ipaddr ""
				save_setting wireless_network subnetmask ""
				save_setting wireless_network gateway ""
			fi
			save_setting wireless_network dnsconfig "$FORM_dnsconfig"
			if [ $FORM_dnsconfig = "manual" ]; then
				save_setting wireless_network dnsserver1 "$FORM_dnsserver1"
				save_setting wireless_network dnsserver2 "$FORM_dnsserver2"
			else
				save_setting wireless_network dnsserver1 ""
				save_setting wireless_network dnsserver2 ""
			fi
			apply_saves
		fi
	fi # saved settings
	
	#sync the filesystem so any changes are actually saved
	sync

# Nothing submitted
else
	# set defaults for form

	# Wireless add
	FORM_ssid=
	FORM_security=open
	FORM_wep_key_type=hex
	FORM_wep_key=
	FORM_wpa_login=
	FORM_wpa_key=
	FORM_remember=true

	# Network config
	FORM_lanconfig=$lanconfig
	empty $FORM_lanconfig && FORM_lanconfig=dhcp
	FORM_ipaddr=$ipaddr
	FORM_subnetmask=$subnetmask
	FORM_gateway=$gateway
	FORM_dnsconfig=$dnsconfig
	FORM_dnsserver1=$dnsserver1
	FORM_dnsserver2=$dnsserver2
fi

############################
# header
############################
if [ "$wireless_interfaces" ]; then
	header_inject_head=$( header_js )

	header "Network" "Wireless" "<img src=\"/images/wscan.jpg\" style=\"vertical-align: middle\" alt=\"WiFi\" />&nbsp;Wireless Network Settings" "$SCRIPT_NAME"
else
	header "Network" "Wireless" "<img src=\"/images/wscan.jpg\" style=\"vertical-align: middle\" alt=\"WiFi\" />&nbsp;Wireless Network Settings"
fi

############################
# content
############################
# At least one wireless interface found - at the very least we have wlan0
if [ "$wireless_interfaces" ]; then

	detected_networks="<script type=\"text/javascript\">/* <![CDATA[ */wifi_list_radio()/* ]]> */</script>"
	rescan_networks="<input type=\"submit\" name=\"newscan\" value=\"Re-Scan\" />"

	display_form <<EOF
start_form|Add a Wireless Network
field|
string|Choose a detected network, or enter details manually.<br /><br />
field|
string|$detected_networks
string|$rescan_networks
field|<br />
field|SSID
text|ssid|$FORM_ssid
field|Security
onchange|do_security
select|security|$FORM_security
option|open|Open
option|WEP|WEP
option|WPA|WPA Personal
option|WPAE|WPA Enterprise
option|WPA2|WPA2 Personal
option|WPA2E|WPA2 Enterprise
onchange|
field|Wep Key Type|wep_key_type_field|hidden
radio|wep_key_type|$FORM_wep_key_type|hex|Hexadecimal
radio|wep_key_type|$FORM_wep_key_type|ascii|Ascii
field|Wep Key|wep_key_field|hidden
password|wep_key
field|WPA Username|wpa_login_field|hidden
text|wpa_login|$FORM_wpa_login
field|WPA Password|wpa_key_field|hidden
password|wpa_key
field|Remember this network
checkbox|remember|true|$FORM_remember|Enabled
string|<input type="hidden" name="mode" id="new_network_mode" value="0" />
field|<br />
field|
string|<input type="submit" name="addnetwork" value="Add This Network" />
helpitem|SSID
helptext|The SSID of the access point that you wish to add. This is the plaintext name of the access point.
helpitem|Security
helptext|The security system used by this access point. Allowed security protocols are: Open, WEP, and WPA(1/2) Personal and Enterprise.
helptext|WEP security requires a WEP key. This can either be specified in ASCII (5 or 13 characters), or more commonly in HEX (10 or 26 characters).
helptext|WPA Personal security requires a Pre-Shared Key as a Password (8-63 characters) or as a 64 character HEX key.
helptext|WPA Enterprise requires a username and password.
helpitem|Remember this network
helptext|If enabled, this network will be added to the list of saved network permanently, and will be available to be joined in the future. Otherwise, this network will remain in the list of saved networks until the board is reset, or another network is added.
end_form
EOF

! empty $( wpa_cli list_networks | grep "^[0-9]" ) && {

	cat <<EOF
<br />
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
  <td colspan="2" class="listtopic">Manage Saved Networks</td>
</tr>
<tr>
  <td valign="top" class="settings-content" id="mytable">
<h4>Saved Networks:</h4><br />
EOF

	echo '<table>'
	echo '<tr><td></td><td align="left">SSID</td><td align="right">Security</td><td align="right">Status</td><td align="right"></td></tr>'
	current_network=$( wpa_cli list_networks | awk '/CURRENT/ {print $1}' )
	odd=true

	for network_number in $(wpa_cli list_networks | awk "/^[0-9].*/ {print \$1}")
	do
		status="<span style=\"color:green\">enabled</span>"
		equal "$( wpa_cli get_network $network_number disabled | awk 'NR == 2' )" "1" && status="<span style=\"red\">disabled</span>"

		ssid=$( wpa_cli get_network $network_number ssid | awk 'NR == 2' )
		key_mgmt=$( wpa_cli get_network $network_number key_mgmt | awk 'NR == 2' )

		ssid=${ssid#[\"]}
		ssid=${ssid%[\"]}

		case "$key_mgmt" in
			WPA-PSK)
				security="WPA Personal"
				equal "$( wpa_cli get_network $network_number proto | awk 'NR == 2' )" "RSN" && security="WPA2 Personal"
				;;
			WPA-EAP)
				security="WPA Enterprise"
				equal "$( wpa_cli get_network $network_number proto | awk 'NR == 2' )" "RSN" && security="WPA2 Enterprise"
				;;
			NONE)
				security="open"
				equal "$( wpa_cli get_network $network_number wep_key0 | awk 'NR == 2' )" "*" && security="WEP"
				;;
		esac

		if equal "$current_network" "$network_number"; then
			if [ "$( wpa_cli status | grep "^wpa_state=" | cut -d= -f2 )" = "COMPLETED" ]; then
				current_column="<span style=\"color:green\">connected</span>"
			else
				current_column="<span style=\"color:GoldenRod\">trying to connect...</span>"
			fi
		else
			current_column=
		fi

		if equal "$odd" "true"; then
			tr_class="class=\"odd\""
			odd=false
		else
			tr_class=
			odd=true
		fi

		cat <<EOF
<tr $tr_class><td><input type="radio" name="saved_ssids_select" value="$network_number" onclick="saved_ssids_selected($network_number)" /><br /></td>
<td align="left">$ssid</td>
<td align="right">$security</td>
<td align="right">$status</td>
<td align="right">$current_column</td></tr>
EOF
	done

	echo "</table>"

	! empty "$current_network" && echo "<script type=\"text/javascript\">/* <![CDATA[ */current_network=$current_network/* ]]> */</script>"

	cat <<EOF
<input id="joinnetwork" type="submit" name="joinnetwork" value="Join This Network" disabled="disabled" />
<input id="deletenetwork" type="submit" name="deletenetwork" value="Delete This Network" disabled="disabled" />
<input id="enablenetwork" type="submit" name="enablenetwork" value="Enable" disabled="disabled" />
<input id="disablenetwork" type="submit" name="disablenetwork" value="Disable" disabled="disabled" />
  </td>

<td class="settings-help" valign="top">
<h4>Notes:</h4><p>Saved networks will be joined automatically - first based on best security, and secondly on best signal strength.</p>
		<h4>Joining:</h4><p>Joining a specific network will temporarily disable all other saved networks, 
		so that the specific network will be joined, if it is available. The other networks will remain disabled until the board is 
		reset, or another network is added.</p>
		<h4>Deleting:</h4><p>Delete a saved network. There is no confirmation and this cannot be undone.</p>
		<h4>Enable / Disable:</h4><p>Networks that are enabled will be joined automatically. Disabled networks will never be joined.</p>
  </td>
</tr>
</table>
EOF

} || { echo "<br />"; }

	display_form <<EOF
start_form|Wireless Network Settings
field|<h4>TCP/IP settings</h4>
field|
onclick|hideStatic
radio|lanconfig|$FORM_lanconfig|dhcp|DHCP
onclick|showStatic
radio|lanconfig|$FORM_lanconfig|static|Static
onclick
field|IP Address|ipaddr_field|hidden
text|ipaddr|$FORM_ipaddr
field|Subnet Mask|subnetmask_field|hidden
text|subnetmask|$FORM_subnetmask
field|Gateway|gateway_field|hidden
text|gateway|$FORM_gateway
field|<h4>DNS settings</h4>
field|
onclick|hideDNS
radio|dnsconfig|$FORM_dnsconfig|auto|Automatic
onclick|showDNS
radio|dnsconfig|$FORM_dnsconfig|manual|Manual
onclick
field|Primary DNS|primarydns|hidden
text|dnsserver1|$FORM_dnsserver1
field|Secondary DNS|secondarydns|hidden
text|dnsserver2|$FORM_dnsserver2
helpitem|TCP/IP Settings
helptext|TCP/IP can be set up using either DHCP or a static IP.
helptext|DHCP will set the system IP Address, Subnet Mask, and Gateway automatically. In the absence of a DHCP server, a link local address will be set - in this case, static should be used, or the SBC will not be able to access the internet.
helptext|Note that the same TCP/IP settings will be used for all access points.
helpitem|DNS Settings
helptext|DNS can be set up automatically if DHCP is enabled. Otherwise, up to two DNS servers should be specified. Note that DNS settings and system-wide and will apply to all interfaces.
end_form
EOF

# No wireless interfaces found
else
	cat <<EOF
No wireless adapters were found. <br />
Please plug in your adapter, or see the PhidgetSBC documentation for information about supported adapters. <br /><br />
EOF

fi

footer 


?>

<!--
##WEBIF:name:Network:300:Wireless
-->
