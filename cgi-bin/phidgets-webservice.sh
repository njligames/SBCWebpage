#!/usr/bin/haserl
<? 
. /usr/lib/webif/webif.sh

load_settings network
load_settings phidgetwebservice

hostname=$( hostname )

if empty "$FORM_submit"; then
	FORM_enabled="$pws_enabled"
	FORM_serverid="$pws_serverid"
	FORM_pass="$pws_password"
	FORM_port="$pws_port"
else

	if equal "$FORM_startstop" "Start"; then
		/etc/init.d/phidgetwebservice forcestart
		sleep 1
		
	elif equal "$FORM_startstop" "Stop"; then
		/etc/init.d/phidgetwebservice stop
		sleep 1
	else
		validate <<EOF
string|pws_serverid|Server ID|min=1 max=63 cfg|$FORM_serverid
int|FORM_port|Port|required min=1 max=65535 cfg|$FORM_port
password|pws_password|Password|min=1 max=63 cfg|$FORM_pass
EOF

		equal "$?" 0 && {
			save_setting phidgetwebservice pws_password "$FORM_pass"
			save_setting phidgetwebservice pws_enabled "$FORM_enabled"
			save_setting phidgetwebservice pws_port "$FORM_port"
			if [ "$FORM_serverid" != "$hostname" ]; then
				save_setting phidgetwebservice pws_serverid "$FORM_serverid"
			else
				save_setting phidgetwebservice pws_serverid ""
				FORM_serverid=
			fi
			apply_saves
		}
	fi
fi

header "Phidgets" "Webservice" "Phidget Webservice" "$SCRIPT_NAME"

?>
<script type="text/javascript">
/* <![CDATA[ */
function clearServerID()
{
  if(document.getElementById("serverid").value == "<? echo -n "$hostname" ?>")
  {
    document.getElementById("serverid").style.color = "black"
    document.getElementById("serverid").value = ""
  }
}

function resetServerID()
{
  if(document.getElementById("serverid").value == "")
  {
    document.getElementById("serverid").value = "<? echo -n "$hostname" ?>"
    document.getElementById("serverid").style.color = "gray"
  }
}
/* ]]> */
</script>
<?

if [ -z "$FORM_serverid" ]; then
	serverid_form="<input id=\"serverid\" type=\"text\" name=\"serverid\" value=\"$hostname\" style=\"color:gray\" onfocus=\"clearServerID()\" onclick=\"clearServerID()\" onblur=\"resetServerID()\"/>"
else
	serverid_form="<input id=\"serverid\" type=\"text\" name=\"serverid\" value=\"$FORM_serverid\" onfocus=\"clearServerID()\" onclick=\"clearServerID()\" onblur=\"resetServerID()\"/>"
fi


running="Stopped"
ps -Afww | grep -v grep | grep -q "phidgetwebservice21" && running="Running"

if equal "$running" "Stopped"; then
	startstop="Webservice is <span style=\"color:red\">stopped</span>... <input type=\"submit\" value=\"Start\" name=\"startstop\" />"
else
	startstop="Webservice is <span style=\"color:green\">running</span>... <input type=\"submit\" value=\"Stop\" name=\"startstop\" />"
fi

display_form <<EOF
start_form|Phidget Webservice
field|
radio|enabled|$FORM_enabled|true|Enabled
radio|enabled|$FORM_enabled|false|Disabled
field|<br />
field|Server ID
string|$serverid_form
field|Port
text|port|$FORM_port
field|Password
text|pass|$FORM_pass
field|<br />
field|
string|$startstop
helpitem|Server ID
helptext|The Server ID is used when connecting to the webservice using openRemote() (mDNS). By default this is the same as the machine hostname.
helpitem|Port
helptext|The port that the webservice will run on. Default value is 5001.
helpitem|Password
helptext|The password that the webservice will run with. By default this is blank, and no password will be required.
end_form
EOF

footer ?>

<!--
##WEBIF:name:Phidgets:200:Webservice
-->
