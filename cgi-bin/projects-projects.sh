#!/usr/bin/haserl --upload-limit=15530
<?
. /usr/lib/webif/webif.sh
. /lib/webif/config.sh

############################
# user app functions
############################

cp="/usr/share/java/phidget21.jar:."

# $1 == app name
ua_make_config_file() {
	cat > $SBC_CONFIGDIR/ua_$1.conf << EOF
app_name="$1"
app_priority="20"
app_enabled="false"
app_daemonize="true"
app_cmd=""
app_args=""
EOF
}

# $1 == app name
ua_make_startup_file() {
	. $SBC_CONFIGDIR/ua_$1.conf
	mkdir -p $SBC_CONFIGDIR/init.d
	cat > $SBC_CONFIGDIR/init.d/S$app_priority$1 << EOF
#!/bin/sh
#
# Start Custom app "$1"
#

# load config
. /lib/webif/config.sh
. \$SBC_CONFIGDIR/ua_$1.conf

app_file="\$SBC_USERAPPS/\$app_name/\$app_cmd"
cp="$cp"

if [ "\${app_cmd##*\.}" = "class" ]; then
	run_app="java -cp \${cp} \${app_cmd%\\.class}"
elif [ "\${app_cmd##*\.}" = "jar" ]; then
	run_app="java -cp \${cp} -jar \$app_cmd"
else
	run_app="\$app_file"
fi

if [ "\$app_args" != "" ]; then
	run_app="\$run_app \$app_args"
fi

if [ "\$app_daemonize" = "true" ]; then
	daemon="&"
fi

start()
{
	echo -n "Starting \$app_name: "

	mkdir -p /tmp/\$app_name;

	if [ "\$app_daemonize" = "true" ]; then
	    (
		cd \$SBC_USERAPPS/\$app_name; 
		exec > /tmp/\$app_name/stdout; 
		exec 2> /tmp/\$app_name/stderr;
		exec <&-
		\$run_app &
	    ) &
		wait
	else
	    (
		exec > /tmp/\$app_name/stdout; 
		exec 2> /tmp/\$app_name/stderr; 
		exec <&-
		cd \$SBC_USERAPPS/\$app_name; 
		\$run_app
	    )
	fi
	echo "OK"
}

stop()
{
	echo -n "Stopping \$app_name: "
	pid=\$( ps -Afww | grep -v grep | grep "\$run_app" | awk '{print \$2}' )
	if [ "\$pid" != "" ]; then
		kill -KILL \$pid
		echo "OK"
	else
		echo "Not running"
	fi
}

case "\$1" in
  forcestart)
	start
	;;
  start)
	if [ "\$app_enabled" = "true" ]; then
		start
	fi
	;;
  stop)
	stop
	;;
  restart)
	stop
	sleep 1
	start
	;;
  *) echo "Usage: \$SCRIPTNAME {start|stop|restart}" >&2
	exit 1
	;;
esac

exit 0
EOF
chmod 755 $SBC_CONFIGDIR/init.d/S$app_priority$1
}

###################################################################
# user applications
#

. /usr/lib/webif/browser-common.inc

###################################
# an application page - pre header
###################################
empty "$FORM_app" && {
	FORM_app=${FORM_path#$SBC_USERAPPS/}
	FORM_app=${FORM_app%%/*}
}

if ! empty "$FORM_app" && empty "$FORM_edit" && empty "$FORM_view"; then

	if ! exists $SBC_CONFIGDIR/ua_$FORM_app.conf; then
		MESSAGE="Warning - config file missing, recreating..."
		ua_make_config_file $FORM_app
	fi

	load_settings ua_$FORM_app

	if ! exists $SBC_CONFIGDIR/init.d/S$app_priority$app_name; then
		MESSAGE="Warning - startup file missing, recreating..."
		ua_make_startup_file $FORM_app
	fi

	if equal "$FORM_startstop" "Start"; then
		$SBC_CONFIGDIR/init.d/S$app_priority$app_name forcestart
		sleep 2
	elif equal "$FORM_startstop" "Stop"; then
		$SBC_CONFIGDIR/init.d/S$app_priority$app_name stop
		sleep 2
	fi

	# config changes
	if ! equal $FORM_config_change ""; then
		validate <<EOF
	int|FORM_priority|Startup order|required min=10 max=99 cfg|$FORM_priority
	string|FORM_args|Command Line Arguments|cfg|$FORM_args
EOF

		equal "$?" 0 && {

			save_setting ua_$FORM_app app_enabled "$FORM_enabled"
			save_setting ua_$FORM_app app_priority "$FORM_priority"
			save_setting ua_$FORM_app app_daemonize "$FORM_daemonize"
			save_setting ua_$FORM_app app_cmd "$FORM_command"
			save_setting ua_$FORM_app app_args "$FORM_args"
			mv $SBC_CONFIGDIR/init.d/S$FORM_old_priority$FORM_app $SBC_CONFIGDIR/init.d/S$FORM_priority$FORM_app
			
			if [ -f $SBC_USERAPPS/$app_name/$FORM_command ]; then
				chmod 755 $SBC_USERAPPS/$app_name/$FORM_command
			fi
			apply_saves
		}
	else
		FORM_enabled=$app_enabled
		FORM_priority=$app_priority
		FORM_daemonize=$app_daemonize
		FORM_command=$app_cmd
		FORM_args=$app_args
	fi
fi


############################
# new app was created
############################
if ! empty "$FORM_newapp"; then
	validate <<EOF
hostname|FORM_newapp|Application Name|required min=1 max=63|$FORM_newapp
EOF
	if equal "$?" 0 ; then
		if [ -e $SBC_USERAPPS/$FORM_newapp ]; then
			ERROR="Error creating application: $FORM_newapp - an application of the same name already exists."
		else
			mkdir -p $SBC_USERAPPS/$FORM_newapp
			ua_make_config_file $FORM_newapp
			ua_make_startup_file $FORM_newapp
			MESSAGE="Created new application: $FORM_newapp"
		fi
	fi

fi

############################
# header
############################
	header "Projects" "Projects" "User Projects"

############################
# File viewer page
############################
if ! empty "$FORM_view" ;then
	cat "$FORM_view" 2>/dev/null | awk \
		-v url="$SCRIPT_NAME" \
		-v path="$FORM_path" \
		-v file="${FORM_view##*/}" \
		-f /usr/lib/webif/common.awk \
		-f /usr/lib/webif/viewer.awk

############################
# File editor page
############################
elif ! empty "$FORM_edit" ;then
	exists "$saved_filename" && {
		edit_filename="$saved_filename"
	} || {
		edit_filename="$edit_pathname"
	}
	cat "$edit_filename" 2>/dev/null | awk \
		-v url="$SCRIPT_NAME" \
		-v path="$FORM_path" \
		-v file="$FORM_edit" \
		-f /usr/lib/webif/common.awk \
		-f /usr/lib/webif/editor.awk
		
############################
# an application page
############################
elif ! empty "$FORM_app"; then

	cat <<EOF
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
  <td class="listtopic">'$FORM_app' Project page</td>
</tr>
<tr>
  <td class="settings-content" valign="top"><br />
EOF
	#start/stop controls
	app_file="$SBC_USERAPPS/$app_name/$app_cmd"
	
	if ! empty "$app_cmd"; then
		if [ "${app_cmd##*\.}" = "class" ]; then
			run_app="java -cp ${cp} ${app_cmd%\.class}"
		elif [ "${app_cmd##*\.}" = "jar" ]; then
			run_app="java -cp ${cp} -jar ${app_cmd%\.jar}"
		else
			run_app="$app_file"
		fi
		if [ "$app_args" != "" ]; then
			run_app="$run_app $app_args"
		fi

		running="Stopped"
		
		ps -Afww | grep -v grep | grep -q "$run_app" && running="Running"
		
		if equal "$running" "Stopped"; then
			echo "<form method=\"post\" action=\"$SCRIPT_NAME\">Application is <span style=\"color:red\">stopped</span>... <input type=\"submit\" value=\"Start\" name=startstop />"
		else
			echo "<form method=\"post\" action=\"$SCRIPT_NAME\">Application is <span style=\"color:green\">running</span>... <input type=\"submit\" value=\"Stop\" name=startstop />"
		fi
		cat <<EOF
<input type="hidden" value="$FORM_path" name=path />
<input type="hidden" value="$FORM_app" name=app />
</form>
EOF
	else
		cat <<EOF
		Application is not setup for running.<br />
EOF
	fi
	
	#stdout/stderr
	if exists /tmp/$app_name/stdout; then
		cat <<EOF
view <a href="$SCRIPT_NAME?path=$FORM_path&amp;view=/tmp/$app_name/stdout">stdout</a>,
<a href="$SCRIPT_NAME?path=$FORM_path&amp;view=/tmp/$app_name/stderr">stderr</a><br />
EOF
	fi
		cat <<EOF
  </td>
</tr>
</table>
EOF
	echo "<br />"

############################
# File listing
############################

	app=${FORM_path#$SBC_USERAPPS/}

	(ls -alL --time-style=+%c "$FORM_path" 2>/dev/null | sed '/^[^d]/d';
		ls -alL --time-style=+%c "$FORM_path" 2>/dev/null | sed '/^[d]/d') 2>/dev/null | awk \
		-v url="$SCRIPT_NAME" \
		-v path="$FORM_path" \
		-f /usr/lib/webif/common.awk \
		-f /usr/lib/webif/browser.awk


	
	cat <<EOF
	<br />
	<div class="settings">
	<div class="settings-content">
	<table width="100%" summary="Settings">
	<tr>
	<td>
		<form method="post" action="$SCRIPT_NAME" enctype="multipart/form-data" onsubmit="statusupdate()">
		<table width="100%">
		<tr>
			<td style="width:20%">Upload a file:</td>
			<td>
				<input type="file" name="file" />
			</td>
		</tr>
		<tr>
			<td />
			<td>
				<input id="form_submit" type="submit" name="submit" value="Upload" />
				<input type="hidden" name="path" value="$FORM_path" />
				<br />
				<br />
			</td>
		</tr>
		</table>
		</form>
	</td></tr><tr><td>
		<form method="post" action="$SCRIPT_NAME">
		<table width="100%">
		<tr>
			<td style="width:20%">Create a directory:</td>
			<td>
				<input type="hidden" name="path" value="$FORM_path" />
				<input type="text" name="dirname" />
			</td>
		</tr>
		<tr>
			<td />
			<td>
				<input id="form_submit2" type="submit" name="submit2" value="Create" />
				<br />
				<br />
			</td>
		</tr>
		<tr>
			<td colspan="2">Free space remaining: $freespace</td>
		</tr>
		</table>
		</form>
	</td></tr>
	</table>
	</div>
		<h4>Notes:</h4>
		<p>Upload your compiled application files along with any required resources. 
		Supported program types are: ARM Binary and Java (class files or jar archive). Maximum file size is 5 MB.</p>
		<p>Java .class files that are part of a package must be uploaded into appropriate 
		package directories, which may be created from this interface. Java classes that
		are not part of a package and .jar files must be uploaded into the base directory.</p>
		<p>Java support requires manual installation of JamVM and GNU Classpath.</p>
		<p>ARM binary files must be uploaded into the base directory.</p>
EOF

############################
# app settings
############################

command_list_create()
{
	echo -n '<select id="command" name="command">'
	for file in $( find $SBC_USERAPPS/$app_name -type f ); do
		file=${file#$SBC_USERAPPS/$app_name/}
		extenstion=${file#*\.}
		if [ "$extenstion" = "class" ]; then
			if ! echo "$file" | grep '\$[0-9]' >&- 2>&-; then
				name=${file%\.class}
				name=$( echo "$name" | sed 's|/|.|' )
				file="$name.class"
				if [ "$file" = "$FORM_command" ]; then
					echo -n "<option selected=\"selected\" value=\"$file\">$name</option>"
				else
					echo -n "<option value=\"$file\">$name</option>"
				fi
			fi
		else
			if ! echo "$file" | grep "/" >&- 2>&-; then
				name=$file
				if [ "$file" = "$FORM_command" ]; then
					echo -n "<option selected=\"selected\" value=\"$file\">$name</option>"
				else
					echo -n "<option value=\"$file\">$name</option>"
				fi
			fi
		fi
	done
	echo '</select>'
}

command_list=$( command_list_create )

echo "<form enctype=\"multipart/form-data\" action=\"$SCRIPT_NAME\" method=\"post\"><div><input type=\"hidden\" name=\"submit\" value=\"1\" /></div>"
_savebutton="<div class=\"page-save\"><input type=\"submit\" name=\"action\" value=\"Save Changes\" /></div></form>"

display_form <<EOF
start_form|Startup Settings
field|
radio|enabled|$FORM_enabled|true|Enabled
radio|enabled|$FORM_enabled|false|Disabled
field|Startup order
text|priority|$FORM_priority
field|Run as daemon
checkbox|daemonize|$FORM_daemonize|true|Enabled
field|Executable/Class name
string|$command_list
field|Arguments
text|args|$FORM_args
hidden|path|$FORM_path
hidden|app|$FORM_app
hidden|config_change|true
hidden|old_priority|$FORM_priority
helpitem|Enabled
helptext|Enabled applications will start automatically when the SBC is booted. Disabled applications can be started manually by the user.
helpitem|Startup Order
helptext|Use to set the startup order when multiple applications are defined. Lower numbers get started first.
helpitem|Run as daemon
helptext|Runs the application as a daemon. This should only be disabled if the application daemonizes itself, or exits right away - otherwise the SBC startup proccess will hang.
helpitem|Executable/Class Name
helptext|Name of the program file or class to execute. All uploaded files are listed - .class/.jar files will be run using the Java VM, all other files are executed directly. .class files are listed by package name.
helpitem|Arguments
helptext|Argument list to pass to the program.
end_form
EOF
	echo "</div>"

############################
# root apps
############################
else

	if [ "$( ls $SBC_USERAPPS/ | awk 'END {print NR}' )" = "0" ]; then
		echo "No projects have been created.<br /><br />"
	else
	
		cat <<EOF
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
  <td class="listtopic">List of Projects:</td>
</tr>
<tr>
<td>
<table class="filebrowser" width="100%" border="0" cellspacing="0" cellpadding="0">
EOF

		for app in $( ls $SBC_USERAPPS/ ) ; do
			app_path=$SBC_USERAPPS/$app
			size=$( du -sh $app_path | awk '{print $1}' )

			load_settings ua_$app
			equal "$app_enabled" "true" && enabled="<span style=\"color:green\">Enabled</span>"
			equal "$app_enabled" "false" && enabled="<span style=\"color:red\">Disabled</span>"
		
			app_file="$SBC_USERAPPS/$app_name/$app_cmd"

			if [ "${app_cmd##*\.}" = "class" ]; then
				run_app="java -cp ${cp} ${app_cmd%\.class}"
			elif [ "${app_cmd##*\.}" = "jar" ]; then
				run_app="java -cp ${cp} -jar ${app_cmd%\.jar}"
			else
				run_app="$app_file"
			fi
			if [ "$app_args" != "" ]; then
				run_app="$run_app $app_args"
			fi

			running="<span style=\"color:red\">Stopped</span>"
			ps -Afww | grep -v grep | grep -q "$run_app" && running="<span style=\"color:green\">Running</span>"
			
			echo "<tr>"

			cat <<EOF
<td class="listl" style="width:27px; vertical-align:middle"><a href="$SCRIPT_NAME?app=$app&amp;path=$app_path"><img src="/images/dir.gif" alt="" /></a></td>
<td class="listn"><a href="$SCRIPT_NAME?app=$app&amp;path=$app_path">$app</a></td>
<td class="listn" style="width:60px; text-align:right">$size</td>
<td class="listn" style="width:60px; text-align:right">$enabled</td>
<td class="listn" style="width:60px; text-align:right">$running</td>
<td class="listr" style="width:40px; text-align:right"><a href="javascript:confirm_delapp('${app_path%/$app}','$app_path','$app')"><img src="/images/action_x.gif" alt="Delete" /></a>&nbsp;</td>
</tr>

EOF
		done

		cat <<EOF
</table>
</td>
</tr>
</table>
<br />
EOF
	# end of app list
	fi

	cat <<EOF
<form action="$SCRIPT_NAME">
<div>
<input id="newapp" type="text" name="newapp" />
<input type="submit" value="Create new project" />
</div>
</form>	
<br />
		
Free space remaining: $freespace

<h4>Notes:</h4>
EOF

	if [ -e /usr/share/java/phidget21.jar ]; then
		cat <<EOF
		<p>
Use this phidget21.jar for building Java applications, to ensure that your application is compatible with the installed library version: 
<a href="/cgi-bin/download?script=$SCRIPT_NAME&amp;path=/usr/share/java&amp;savefile=phidget21.jar">phidget21.jar</a></p>
EOF
	else
		cat <<EOF
		<p>In order to support Java Applications for Phidgets, you must install Java support from the <a href="/cgi-bin/system-packages.sh">Packages</a> page, or via SSH.</p>
EOF
	fi
fi

footer ?>
<!--
##WEBIF:name:Projects:200:Projects
-->
