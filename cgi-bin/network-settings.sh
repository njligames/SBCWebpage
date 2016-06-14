#!/usr/bin/haserl
<? 
. /usr/lib/webif/webif.sh

load_settings network

if empty "$FORM_submit"; then
	FORM_lanconfig=$lanconfig
	FORM_ipaddr=$ipaddr
	FORM_subnetmask=$subnetmask
	FORM_gateway=$gateway
	FORM_dnsconfig=$dnsconfig
	FORM_dnsserver1=$dnsserver1
	FORM_dnsserver2=$dnsserver2
	FORM_sshstart=$sshstart
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
		save_setting network lanconfig "$FORM_lanconfig"
		if [ $FORM_lanconfig = "static" ]; then
			save_setting network ipaddr "$FORM_ipaddr"
			save_setting network subnetmask "$FORM_subnetmask"
			save_setting network gateway "$FORM_gateway"
		else
			save_setting network ipaddr ""
			save_setting network subnetmask ""
			save_setting network gateway ""
		fi
		save_setting network dnsconfig "$FORM_dnsconfig"
		if [ $FORM_dnsconfig = "manual" ]; then
			save_setting network dnsserver1 "$FORM_dnsserver1"
			save_setting network dnsserver2 "$FORM_dnsserver2"
		else
			save_setting network dnsserver1 ""
			save_setting network dnsserver2 ""
		fi
		save_setting network sshstart "$FORM_sshstart"
		apply_saves
	fi
fi

header_js()
{
	cat <<EOF
<script type="text/javascript">
/* <![CDATA[ */
function showStatic()
{
	document.getElementById("ipaddr_field").style.display = "";
	document.getElementById("subnetmask_field").style.display = "";
	document.getElementById("gateway_field").style.display = "";
	document.getElementById("dnsconfig_auto").disabled = true;
	document.getElementById("dnsconfig_manual").checked = "checked";
	showDNS();
}
function hideStatic()
{
	document.getElementById("ipaddr_field").style.display = "none";
	document.getElementById("subnetmask_field").style.display = "none";
	document.getElementById("gateway_field").style.display = "none";
	document.getElementById("dnsconfig_auto").disabled = false;
}
function showDNS()
{
	document.getElementById("primarydns").style.display = "";
	document.getElementById("secondarydns").style.display = "";
}
function hideDNS()
{
	document.getElementById("primarydns").style.display = "none";
	document.getElementById("secondarydns").style.display = "none";
}
function onPageLoad()
{
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
/* ]]> */
</script>
EOF
}

header_inject_head=$( header_js )

header "Network" "Settings" "Network Settings" "$SCRIPT_NAME"

display_form <<EOF
start_form|Network Settings
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
field|<h4>SSH Server</h4>
field|
radio|sshstart|$FORM_sshstart|true|Enabled
radio|sshstart|$FORM_sshstart|false|Disabled
helpitem|TCP/IP Settings
helptext|TCP/IP can be set up using either DHCP or a static IP.
helptext|DHCP will set the system IP Address, Subnet Mask, and Gateway automatically. In the absence of a DHCP server, a link local address will be set - in this case, static should be used, or the SBC will not be able to access the internet.
helpitem|DNS Settings
helptext|DNS can be set up automatically if DHCP is enabled. Otherwise, up to two DNS servers should be specified.
helpitem|SSH Server
helptext|An SSH server can be set up to run at boot. Log in to SSH as 'root' with the same password as the web config. Enabling SSH for the first time can take several minutes as the keys are generated.
end_form
EOF

footer ?>

<!--
##WEBIF:name:Network:200:Settings
-->
