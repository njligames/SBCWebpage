#!/usr/bin/haserl
<?
. "/usr/lib/webif/webif.sh"

load_settings system

###################################################################
# system configuration page
#
# Description:
#	Configures general system settings.
#

#####################################################################
# initialize forms
if empty "$FORM_submit"; then
	# initialize all defaults
	FORM_system_timezone="${zoneinfo:-"-"}"
	FORM_hostname=$hostname
else
#####################################################################
# save forms
	validate <<EOF
hostname|FORM_hostname|Hostname|nodots required max=63 cfg|$FORM_hostname
string|FORM_show_TZ|Zoneinfo String|cfg|$FORM_show_TZ
EOF
	if equal "$?" 0 ; then
		save_setting system hostname "$FORM_hostname"
		save_setting system zoneinfo "$FORM_show_TZ_zone"
		apply_saves
	fi
fi

#####################################################################
# initialize time zones

TIMEZONE_OPTS=$(
	awk -v timezoneinfo="$FORM_system_timezone" '
		BEGIN {
			FS="	"
			last_group=""
			defined = 0
		}
		/^(#.*)?$/ {next}
		$1 != last_group {
			last_group=$1
			print "optgroup|" $1
		}
		{
			list_timezone = $3
			if (list_timezone == timezoneinfo)
				defined = 1
			print "option|" list_timezone "|" $2
		}
		END {
			if (defined == 0) {
				split(timezoneinfo, oldtz, "@")
				print "optgroup|User Defined"
				if (oldtz[1] == "-") oldtz[1] = "User defined"
				print "option|" timezoneinfo "|" oldtz[1]
			}
		}' < /usr/lib/webif/timezones.csv 2>/dev/null

)

header_js()
{
	cat <<EOF
<script type="text/javascript" src="/js/webif.js"></script>
<script type="text/javascript">
/* <![CDATA[ */
function modechange()
{
	var tz_info = value('system_timezone');
	set_value('show_TZ_zone', tz_info);
}
window.onload = modechange;
/* ]]> */
</script>
EOF
}

header_inject_head=$( header_js )

#####################################################################

header "System" "General" "General System Settings" "$SCRIPT_NAME"

#####################################################################


#######################################################
# Show form
display_form <<EOF
onchange|modechange
start_form|System Settings
field|Hostname
text|hostname|$FORM_hostname
helpitem|Hostname
helptext|The system hostname. This is used for the system's mDNS hostname, as well as the Phidget Webservice default Server ID.
end_form
start_form|Time Settings
field|Timezone
select|system_timezone|$FORM_system_timezone
$TIMEZONE_OPTS
field|Zoneinfo String|view_tz_zone|
string|<input id="show_TZ_zone" type="text" style="width: 96%; height: 1.2em; " name="show_TZ_zone" value="" />
helpitem|Timezone
helptext|Set up your time zone according to the nearest city of your region from the predefined list, or enter your own time zone.
helpitem|Zoneinfo String
helptext|Standard zoneinfo names are defined for different areas of the world. Check <a href="http://en.wikipedia.org/wiki/List_of_zoneinfo_timezones">here</a> for a list of zones.
$NTP
end_form
EOF

footer ?>

<!--
##WEBIF:name:System:010:General
-->
