#!/usr/bin/haserl
<?
. /usr/lib/webif/webif.sh

timeout=0
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
	header_inject_head="<meta http-equiv=\"refresh\" content=\"$timeout; url=http://$router_ip/cgi-bin/status-system.sh\" />"
fi

MESSAGE="Logging out..."

header "Logout" "Logout" "Logout"
footer

#delete this session
sessionid="${HTTP_COOKIE#session=}"
sessionid="${sessionid%%;*}"
if [ "$sessionid" != "" ]; then
	sed "/$sessionid/d" /tmp/thttpd_sessions > /tmp/thttpd_sessions_tmp
	mv /tmp/thttpd_sessions_tmp /tmp/thttpd_sessions
fi

?>
<!--
##WEBIF:name:Logout:100:Logout
-->
