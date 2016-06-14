#!/usr/bin/haserl
<? 
. /usr/lib/webif/webif.sh

[ -e /dev/video0 ] && webcam_present="true"


if [ "$webcam_present" = "true" ]; then

	webcam_has_mjpeg=$(uvcdynctrl -f | awk '/MJPG/ {print "true"}')
	webcam_has_yuyv=$(uvcdynctrl -f | awk '/YUYV/ {print "true"}')
	if [ "$webcam_has_mjpeg" = "true" -o "$webcam_has_yuyv" = "true" ]; then
		webcam_supported="true"
	fi

	if [ "$webcam_supported" = "true" ]; then

		if [ "$webcam_has_mjpeg" = "true" ]; then
			webcam_format="MJPG"
		else
			webcam_format="YUYV"
		fi


		. /lib/webif/config.sh
		. $SBC_CONFIGDIR/webcam.conf

		# get actual res from current config file
		height=${webcam_res#*x}
		width=${webcam_res%x*}

		empty height && height=240
		empty width && width=320

		# get the actual port
		webcam_real_port=$webcam_port

		#this may load an uncommited file
		load_settings webcam

		# Try to find addr that user has typed into brower, other wise fall back on eth0 addr, and finally on wlan0 addr
		webcam_host="${HTTP_REFERER#http://}"
		webcam_host="${webcam_host%%/*}"
		if empty $webcam_host; then
			for ipaddr in $(/sbin/ifconfig | sed -n '/inet addr:/s/ *inet addr:\([[:digit:].]*\) .*/\1/p'); do
				if ! empty "$ipaddr" && ! equal "$ipaddr" "127.0.0.1"; then
					webcam_host="$ipaddr"
					break
				fi
			done
		fi
	fi
fi


############################
# Save Settings
############################

if empty "$FORM_submit"; then
	FORM_resolution=$webcam_res
	FORM_framerate=$webcam_framerate
	FORM_enabled=$webcam_udevcontrol
	FORM_port=$webcam_port
	FORM_pass=$webcam_pass
else
	# Validate everything at once, or we run into problems!
	validate <<EOF
float|FORM_framerate|Framerate|cfg|$FORM_framerate
int|FORM_port|Port|required min=1 max=65535 cfg|$FORM_port
password|webcam_pass|Password|min=1 max=63 cfg|$webcam_pass
EOF

	if equal "$?" 0; then
		save_setting webcam webcam_res "$FORM_resolution"
		save_setting webcam webcam_framerate "$FORM_framerate"
		save_setting webcam webcam_udevcontrol "$FORM_enabled"
		save_setting webcam webcam_port "$FORM_port"
		save_setting webcam webcam_pass "$FORM_pass"
		apply_saves
	fi
fi

############################
# Functions
############################
header_js()
{
	cat <<EOF
<script type="text/javascript">
/* <![CDATA[ */
var res_to_fps = new Array();
EOF

uvcdynctrl -f | awk -v format=$webcam_format '
	BEGIN {start=0; count=0;}

	/Pixel format/ { if($3 == format) start=1; else start=0;}

	/Frame size/ {
		if (start) {
			if(count>0)
				printf("];\n");
			printf("res_to_fps[%d]=[",count); count++;
		}
	}

	/Frame rates/ {
		if (start)
			for (i=3; i<=NF; i++) {
				if(index($i,",")>0)
					framerate=substr($i, 0, length($i)-1);
				else
					framerate=$i;
				printf("\"%s\"",framerate); if(i<NF) printf(",");
			}
	}

	/Frame intervals/ {
		if (start)
			for (i=3; i<=NF; i++) {
				frametop=substr($i, 0, index($i, "/")-1);
				framebot=substr($i, index($i, "/")+1, length($i)-index($i, "/"));
				if(index($framebot,",")>0)
					framebot=substr($framebot, 0, length($framebot)-1);
				framerate=framebot/frametop;
				printf("\"%s\"",framerate); if(i<NF) printf(",");
			}
	}

	END { if(count>0) printf("];\n"); }'
	
	cat <<EOF
	
function update_fps(index)
{
	document.getElementById("framerate").options.length=0;
	for (i=0; i<res_to_fps[index].length; i++){
		var selectme=false;
		if(res_to_fps[index][i]==$FORM_framerate) selectme=true;
		document.getElementById("framerate").options[document.getElementById("framerate").options.length]=new Option(res_to_fps[index][i], res_to_fps[index][i], false, selectme);
	}
}
	
function popup(mylink, windowname, width, height)
{
	if (! window.focus)
		return true;
	window.open(mylink, windowname, "width=" + width + ",height=" + height + ",menubar=0,resizable=0,status=0,scrollbars=0,toolbar=0");
	return false;
}
/* ]]> */
</script>
EOF
}

create_res_list()
{
	echo -n '<select id="resolution" name="resolution" onchange="update_fps(this.selectedIndex)">'
	uvcdynctrl -f | awk -v currentres=$FORM_resolution -v format=$webcam_format '
	
	BEGIN {start=0; foundres=0;}

	/Pixel format/ { if($3 == format) start=1; else start=0;}

	/Frame size/ {
		if (start) {
			if(currentres == $3) {
				selected="selected=\"selected\"";
				foundres=1;
			}
			else
				selected="";
			printf("<option %s value=\"%s\">%s</option>", selected, $3, $3);
		}
	}

	END {
		if (foundres == 0)
			printf("<option  selected=\"selected\" style=\"background-color: Red;\" value=\"%s\">%s (Unsupported)</option>",currentres,currentres);
	}'
	echo '</select>'
}

############################
# header
############################

if [ "$webcam_present" = "true" -a "$webcam_supported" = "true" ]; then
	header_inject_head=$( header_js )
	header "Webcam" "Webcam" "Webcam" "$SCRIPT_NAME"
else
	header "Webcam" "Webcam" "Webcam"
fi

############################
# content
############################

if [ "$webcam_supported" = "true" ] ; then

if [ "$webcam_has_mjpeg" != "true" ]; then
	echo "Warning: This webcam does not support MJPG. YUYV will be used - but this is very resource-intensive and will slow down the SBC a lot.<br /><br />"
fi

ps | grep -v grep | grep -q mjpg_streamer && running=1

if ! empty $running; then
	webcam_view="<!--[if !IE]><!--> \
	<img src=\"http://$webcam_host:$webcam_real_port/?action=stream\" alt=\"Webcam MJPEG Stream\"/> \
	<!--<![endif]--> \
	<!--[if IE]> \
	<applet code=\"com.charliemouse.cambozola.Viewer\" archive=\"/webcam/cambozola.jar\" width=\"$width\" height=\"$height\"> \
		<param name=\"url\" value=\"http://$webcam_host:$webcam_real_port/?action=stream\"/> \
	</applet> \
	<![endif]-->"

	helptype=
	if [ $width -gt 512 ]; then
		helptype=2
	fi

	display_form <<EOF
start_form|Live Webcam Stream
#Webcam view!
field|
string|$webcam_view
helpitem$helptype|Notes
helptext$helptype|Live streaming should work properly in Firefox and Safari. Internet Explorer users will need to have Java installed. Other browsers may or may not be able to interpret the stream.
helptext$helptype|The live stream address is: <a href="http://$webcam_host:$webcam_real_port/?action=stream" onclick="return popup('http://$webcam_host:$webcam_real_port/?action=stream', 'live_webcam', $width, $height)">http://$webcam_host:$webcam_real_port/?action=stream</a>
helptext$helptype|This is an M-JPEG stream that can be viewed/saved by programs such as <a href="http://www.videolan.org/vlc/">VLC</a>.
helptext$helptype|Webcam video and control is exposed over the specified port ($FORM_real_port). Various stream formats are avialable at the webcam webpage at http:[phidget_sbc_ip]:[port] (<a href="http://$webcam_host:$webcam_real_port">http://$webcam_host:$webcam_real_port</a>).
helptext$helptype|If you are veiwing this page through a NAT router (ie. over the internet), the embedded video stream will not work. You will need to make sure that the webcam port is open, and that the router is forwarding it.
helpitem$helptype|Webcam Control
helptext$helptype|Click <a href="http://$webcam_host:$webcam_real_port/control.html" onclick="return popup('http://$webcam_host:$webcam_real_port/control.html', 'webcam_control', 420, 500)">here</a> to bring up the webcam control dialog.
helptext$helptype|This allows you to control pan and tilt on supported cameras, as well as various picture settings such as brightness and contrast.
helptext$helptype|If a command fails, this means that it is either not supported by your webcam, or that the setting has reached its minimum or maximum.
end_form
EOF

echo "<br />"

fi

resolutions=$( create_res_list )

display_form <<EOF
start_form|Webcam Settings
field|
radio|enabled|$FORM_enabled|true|Enabled
radio|enabled|$FORM_enabled|false|Disabled
field|Resolution
string|$resolutions
field|Framerate
select|framerate|$FORM_framerate
option|5|5
field|Port
text|port|$FORM_port
field|Password
text|pass|$FORM_pass
helpitem|Resolution
helptext|All resolutions supported by your Webcam are listed. Because the PhidgetSBC does not have high-speed USB ports, some higher resolutions supported by your webcam may not be shown.
helpitem|Framerate
helptext|Framerates of up to 30fps can be used with good results, depending on resolution and network bandwidth. Available framerates will depend on the selected resolution.
helpitem|Port
helptext|The port that the video stream is sent to.
helpitem|Password
helptext|Protect the webcam stream with a password. This will add a simple username/password prompt whenever you view the webcam stream - including on this page. The username is 'webcam'. Set to nothing to disable passwords.
end_form
EOF

cat <<EOF
<script type="text/javascript">
/* <![CDATA[ */
update_fps(document.getElementById("resolution").selectedIndex);
/* ]]> */
</script>
EOF

else

if [ "$webcam_present" = "true" ]; then
	cat <<EOF
Found a webcam - but it does not support MJPEG or YUYV, which are required for streaming. <br /><br />
EOF
else
	cat <<EOF
No webcams were found. <br /><br />
EOF
fi
	cat <<EOF
Please plug in your webcam to continue. PhidgetSBC supports UVC (USB Video Class) compatible webcams which support MJPEG. <br /><br />
For a list of compliant webcams see here: <a href="http://linux-uvc.berlios.de/#devices">http://linux-uvc.berlios.de/#devices</a><br /><br />
EOF

fi

footer

?>

<!--
##WEBIF:name:Webcam:10:Webcam
-->
