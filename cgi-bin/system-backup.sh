#!/usr/bin/haserl --upload-limit=5530
<?
. /usr/lib/webif/webif.sh
. /lib/webif/config.sh

board_name="$([ -e /proc/device-tree/model ] && (cat /proc/device-tree/model; echo '';) || (cat /proc/cpuinfo | awk '/^Hardware/ {print $3}'))"
board_string="$board_name $(awk '/^Revision/ {print $3}' < /proc/cpuinfo)"
board_name_lower="$(echo $board_name | tr '[:upper:]' '[:lower:]')"

system_hostname=$(hostname)
		
# Boot into the restore system
timeout=25
if ! equal $FORM_upgrade "" ; then
	if empty $( /sbin/ifconfig eth0 | grep UP ); then
		ERROR="Recovery system must be entered from a wired connection"
	else
		
		# wait, then redirect
		referer_ip="${HTTP_REFERER#http://}"
		referer_ip="${referer_ip%%/*}"
		if empty "$referer_ip"; then
			router_ip="$(/sbin/ifconfig eth0 | sed -n '/inet addr:/s/ *inet addr:\([[:digit:].]*\) .*/\1/p')"
		else
			router_ip="$referer_ip"
		fi
		header_inject_head="<meta http-equiv=\"refresh\" content=\"$timeout; url=http://$router_ip/cgi-bin/system-restore.sh\" />"
		
		
		header "System" "Backup &amp; Restore" "<img src=\"/images/bkup.jpg\" alt=\"Backup and Restore\" />&nbsp;Backup and Restore"

		cat <<EOF
	<script type="text/javascript" src="/js/progress.js"></script>
		Booting into recovery/upgrade system, plese wait ...
<br/>
EOF

		ipaddr="$(/sbin/ifconfig eth0 | sed -n '/inet addr:/s/ *inet addr:\([[:digit:].]*\) .*/\1/p')"
		gateway="$(route -n | grep "^0.0.0.0.*UG.*eth0" | awk {'print $2'})"
		subnetmask="$(/sbin/ifconfig eth0 | grep "Mask:" | cut -d: -f4)"
		console="$(cat /proc/cmdline | awk '{for(i=1; i<=NF; i++) {if ($i ~ /^console/) print $i}}')"

		if equal $board_name_lower "phidgetsbc3" ; then
			set_mtd recovery_system
			nanddump $mtd -q > /tmp/uImage.recovery
			kexec -l /tmp/uImage.recovery -t uImage --command-line="$console root= ip=$ipaddr::$gateway:$subnetmask:$system_hostname:eth0" 2>&1 >/dev/null
		fi

		if equal $board_name_lower "phidgetsbc2" ; then
			mtdparts="$(cat /proc/cmdline | awk '{for(i=1; i<=NF; i++) {if ($i ~ /^mtdparts/) print $i}}')"
			dm9000addr="$(cat /proc/cmdline | awk '{for(i=1; i<=NF; i++) {if ($i ~ /^dm9000\.addr/) print $i}}')"
			set_mtdblock flashfs
			mkdir -p /tmp/flashfs
			mount -t jffs2 -o ro $mtd /tmp/flashfs 2>&1
			kexec -l /tmp/flashfs/boot/zImage -t zImage --atags --append="$console rootfstype=jffs2 root=$mtd ro $mtdparts $dm9000addr ip=$ipaddr::$gateway:$subnetmask:$system_hostname:eth0" 2>&1
		fi

		cat <<EOF
<br/><br/>
<center>
<script type="text/javascript">
/* <![CDATA[ */
var bar1=createBar(350,15,'white',1,'black','blue',85,7,3,'');
/* ]]> */
</script>
</center>
EOF
		footer
		
		#reboot has a kexec action which boots into the new kernel if one has been loaded
		reboot &
		exit
	fi
fi

header "System" "Backup &amp; Restore" "<img src=\"/images/bkup.jpg\" alt=\"Backup and Restore\" />&nbsp;Backup and Restore"

DOWNLOAD()
{
cat <<EOF
&nbsp;&nbsp;&nbsp;If downloading does not start automatically, click here ... <a href="/$1">$2</a><br /><br />
<script type="text/javascript">
/* <![CDATA[ */
setTimeout('top.location.href=\"/$1\"',"300")
/* ]]> */
</script>
EOF
}

# Create a new backup for the user
if ! equal $FORM_download "" ; then
	
	
	tmp=/tmp/config.$$
	tgz=/tmp/${board_name_lower}_backup.tgz
	rm -rf $tmp 2>/dev/null
	mkdir -p $tmp 2>/dev/null
	date > $tmp/config.date
	echo "$FORM_name" > $tmp/config.name

	echo $board_string > $tmp/config.boardtype
	
	# backup webif config
	[ -e $SBC_CONFIGDIR ] && {
		mkdir -p $tmp$SBC_CONFIGDIR
		cp -a $SBC_CONFIGDIR/* $tmp$SBC_CONFIGDIR/ 2>/dev/null
	}
	# wireless config
	[ -e /etc/wpa_supplicant/wpa_supplicant.conf ] && {
		mkdir -p $tmp/etc/wpa_supplicant
		cp /etc/wpa_supplicant/wpa_supplicant.conf $tmp/etc/wpa_supplicant/ 2>/dev/null
	}
	
	(cd $tmp; tar czf $tgz *)
	rm -rf $tmp 2>/dev/null
	DOWNLOAD "cgi-bin/download?script=$SCRIPT_NAME&path=/tmp&savefile=${board_name_lower}_backup.tgz" ${board_name_lower}_backup.tgz
	sleep 25 ; rm $tgz
	

# Restore a config
elif ! equal $FORM_instconfig "" ; then

	dir=$FORM_dir
	display_form <<EOF
start_form|Restore Configuration
EOF
	if [ -n "$dir" ] && [ -d "$dir" ] && [ -e "$dir/config.name" ] && [ -e "$dir/config.boardtype" ]; then
			echo "<tr><td colspan=\"2\">Restoring configuration.<br /><pre>"
			cd $dir
			
			find etc/ | while read -r file
			do
			#for file in $(find $COPY_DIR); do
				if [ -d "$file" ]; then
					[ -d /"$file" ] || mkdir /"$file"
				else
					[ -e /"$file" ] && rm /"$file"
					cp "$file" /"$file"
					echo "restoring $file"
				fi
			done

		echo "<br />Rebooting now...<meta http-equiv=\"refresh\" content=\"1;url=system-reboot.sh?reboot=1\">"
		echo "</pre></td></tr>"
	else
		echo "<p>bad dir: $dir</p>"
	fi

	display_form <<EOF
end_form
EOF

# Check a config
elif ! equal $FORM_chkconfig "" ; then

	if [ -n "$FORM_configfile" ] && [ -e "$FORM_configfile" ]; then
			
		echo "<form method=\"get\" action=\"$SCRIPT_NAME\">"
		display_form <<EOF
start_form|Restore Configuration
EOF
		rm -rf /tmp/config.* 2>/dev/null
		tmp=/tmp/config.$$
		mkdir $tmp
		(cd $tmp; tar xzf $FORM_configfile)
		rm $FORM_configfile

		if [ ! -e "$tmp/config.name" ] || [ ! -e "$tmp/config.boardtype" ]; then
			echo "<tr><td colspan=\"2\">Invalid file: phidgetsbc_backup.tgz!</td></tr>"
		else
			nm=$(cat $tmp/config.name)
			bd=$(cat $tmp/config.boardtype)
			dt=$(cat $tmp/config.date)

			CFGGOOD="<tr><td colspan=\"2\">The configuration looks good!<br /><br /></td></tr>"

			if [ "$bd" != "$board_string" ]; then
				echo "<tr><td colspan=\"2\"><span style=\"color:red\">WARNING</span>: different board type (ours: $board_string, file: $bd)!</td></tr>"
			else
				echo $CFGGOOD
			fi
			display_form <<EOF
field|Config Name
string|$nm
field|Board Type
string|$bd
field|Generated
string|$dt
field
EOF
			echo "</td></tr>"
		fi

		cat <<EOF
<tr><td>&nbsp;</td></tr>
<tr><td><input type='hidden' name='dir' value="$tmp" />
<input type="submit" name="instconfig" value="Restore" /></td></tr>
<tr><td>&nbsp;</td></tr>
EOF

		display_form <<EOF
end_form
EOF
		echo "</form>"
	fi

# system reset
elif ! equal $FORM_reset "" ; then

	cat <<EOF
	<form method="post" action="$SCRIPT_NAME">
		Confirm: Really reset the system now?
		<input type="submit" name="reset_confirmed" value="Reset" />
	</form>
EOF

# system reset confirmed
elif ! equal $FORM_reset_confirmed "" ; then
	echo "Resetting config files ... <br /><br />"
	
	[ -e $SBC_CONFIGDIR ] && {
		rm -f $SBC_CONFIGDIR/*
	}
	[ -e /etc/wpa_supplicant/wpa_supplicant.conf ] && {
		echo "ctrl_interface=/var/run/wpa_supplicant" > /etc/wpa_supplicant/wpa_supplicant.conf
		echo "update_config=1" >> /etc/wpa_supplicant/wpa_supplicant.conf
	}
				
	echo "<br />Rebooting now...<meta http-equiv=\"refresh\" content=\"1;url=system-reboot.sh?reboot=1\">"
	
# Main page
else
	cat <<EOF
	<form method="post" action="$SCRIPT_NAME" enctype="multipart/form-data">
EOF

	display_form <<EOF
start_form|Backup Configuration
field|Name this configuration:
text|name|${FORM_name:-$system_hostname}
field|<br />
field|
string|<input type="submit" name="download" value="Backup" />
helpitem|Notes
helptext|Backup includes all settings maintained wby the web interface, excluding the password. This does not backup user project files, or any additional user configuration settings or files.
helpitem|Name
helptext|You can give the backup file an arbitrary name. This will be shown during restore.
end_form
EOF

	echo "<div><br /></div>"

	display_form <<EOF
start_form|Restore Configuration
field|Saved backup file:
upload|configfile
field|<br />
field|
string|<input type="submit" name="chkconfig" value="Restore" />
helpitem|Notes
helptext|Choose a backup file for this machine type. The restore system will check the file and ask for confirmation before running the restore.
end_form
EOF

	echo "<div><br /></div>"

	display_form <<EOF
start_form|Reset Configuration
field|
string|<input type="submit" name="reset" value="Reset" />
helpitem|Notes
helptext|This will set the system configuration to its default state. This includes only the configuration maintained by the web interface. This will not reset the password.
end_form
EOF

	echo "<div><br /></div>"
	
	display_form <<EOF
start_form|Upgrade / Factory Reset
field|
string|<input type="submit" name="upgrade" value="Go" />
helpitem|Notes
helptext|This reboots the system into the Recovery system, where a full factory reset or system upgrade can be performed.
helptext|Upgrade/Factory Reset must be done over the wired ethernet interface. Upgrades must be done from a USB Flash drive.
end_form
EOF

	echo "</form>"
fi

footer
?>
<!--
##WEBIF:name:System:450:Backup &amp; Restore
-->
