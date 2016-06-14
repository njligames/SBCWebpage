#!/usr/bin/haserl
<?
. /usr/lib/webif/webif.sh

timeout=45
if empty "$FORM_reboot" && empty "$FORM_dontreboot"; then
	reboot_msg="Are you sure you want to reboot the system?<br /><br /><form method=\"post\" action=\"$SCRIPT_NAME\"><div><input type=\"submit\" value=\"Yes\" name=\"reboot\" /><input type=\"submit\" value=\"No\" name=\"dontreboot\" /></div></form>"
else
	if ! empty "$FORM_dontreboot"; then
		timeout=0
	fi
	referer_ip="${HTTP_REFERER#http://}"
	referer_ip="${referer_ip%%/*}"
	if empty "$referer_ip"; then
		if ! empty $( /sbin/ifconfig eth0 | grep UP ); then
			router_ip="$(/sbin/ifconfig eth0 | sed -n '/inet addr:/s/ *inet addr:\([[:digit:].]*\) .*/\1/p')"
		else
			router_ip="$(/sbin/ifconfig wlan0 | sed -n '/inet addr:/s/ *inet addr:\([[:digit:].]*\) .*/\1/p')"
		fi
	else
		router_ip="$referer_ip"
	fi
	if ! empty "$router_ip"; then
		header_inject_head="<meta http-equiv=\"refresh\" content=\"$timeout; url=http://$router_ip/\" />"
	fi
	if empty "$FORM_dontreboot"; then
		reboot_msg="Rebooting now...
<br/><br/>
Please wait about $timeout seconds. The PhidgetSBC configuration should automatically reload.
<br/><br/>
<center>
<script type=\"text/javascript\">
/* <![CDATA[ */
var bar1=createBar(350,15,'white',1,'black','blue',85,7,3,'');
/* ]]> */
</script>
</center>"
	fi
fi

header "System" "Reboot" "Reboot"
?>

	<script type="text/javascript" src="/js/progress.js"></script>
	<? echo -n "$reboot_msg" ?>

<? footer ?>
<?
! empty "$FORM_reboot" && {
	reboot &
	exit
}
?>
<!--
##WEBIF:name:System:910:Reboot
-->
