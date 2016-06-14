#!/usr/bin/haserl
<?
. "/usr/lib/webif/webif.sh"

load_settings packages

aptclean() {
DEBIAN_FRONTEND=noninteractive apt-get --force-yes -fuy clean 2>&1 1>/dev/null
DEBIAN_FRONTEND=noninteractive apt-get --force-yes -fuy autoclean 2>&1 1>/dev/null
DEBIAN_FRONTEND=noninteractive apt-get --force-yes -fuy autoremove 2>&1 1>/dev/null
}

aptupdate() {
apt-get update | awk '{ print $0 "<br />"; fflush()}'
}

savesettings() {
if [ "$FORM_incldebian" = "" ]; then
FORM_incldebian="false"
else
FORM_incldebian="true"
fi
save_setting packages incldebian "$FORM_incldebian"
apply_saves
}

# Refresh list - apt-get update
if ! empty "$FORM_refresh"; then
header_inject_head="<meta http-equiv=\"refresh\" content=\"1; url=$SCRIPT_NAME\" />"
header "System" "Packages" "<img src=\"/images/upd.jpg\" style=\"vertical-align: middle\" alt=\"blocks\" />&nbsp;Package Management"
savesettings 2>&1 1>/dev/null
echo "Refreshing...<br /><br />"
aptupdate
echo "<br />Done."

# Upgrade selected packages
elif ! empty "$FORM_upgrade"; then
#header_inject_head="<meta http-equiv=\"refresh\" content=\"1; url=$SCRIPT_NAME\" />"
header "System" "Packages" "<img src=\"/images/upd.jpg\" style=\"vertical-align: middle\" alt=\"blocks\" />&nbsp;Package Management"
echo "Upgrading...<br /><br />"
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade | awk '{ print $0 "<br />"; fflush()}'
aptclean
cat <<EOF
<br />Done.<br /><br />
<form method="post" action="$SCRIPT_NAME">
<input type="submit" value="Back" name="back" />
</form>
EOF

# Install Java support
elif ! empty "$FORM_instjava"; then
#header_inject_head="<meta http-equiv=\"refresh\" content=\"1; url=$SCRIPT_NAME\" />"
header "System" "Packages" "<img src=\"/images/upd.jpg\" style=\"vertical-align: middle\" alt=\"blocks\" />&nbsp;Package Management"
if ! apt-cache search default-jre-headless | grep default-jre-headless 2>&1 1>/dev/null; then
save_setting packages incldebian "true" 2>&1 1>/dev/null
apply_saves 2>&1 1>/dev/null
echo "Refreshing...<br /><br />"
aptupdate
echo "<br />"
fi
echo "Installing...<br /><br />"
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy install default-jre-headless libphidget21-java | awk '{ print $0 "<br />"; fflush()}'
aptclean
cat <<EOF
<br />Done.<br /><br />
<form method="post" action="$SCRIPT_NAME">
<input type="submit" value="Back" name="back" />
</form>
EOF

# Install Java support
elif ! empty "$FORM_instc"; then

#header_inject_head="<meta http-equiv=\"refresh\" content=\"1; url=$SCRIPT_NAME\" />"
header "System" "Packages" "<img src=\"/images/upd.jpg\" style=\"vertical-align: middle\" alt=\"blocks\" />&nbsp;Package Management"
if ! apt-cache search build-essential | grep build-essential 2>&1 1>/dev/null; then
save_setting packages incldebian "true" 2>&1 1>/dev/null
apply_saves 2>&1 1>/dev/null
echo "Refreshing...<br /><br />"
aptupdate
echo "<br />"
fi
echo "Installing...<br /><br />"
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy install build-essential libphidget21-dev | awk '{ print $0 "<br />"; fflush()}'
aptclean
cat <<EOF
<br />Done.<br /><br />
<form method="post" action="$SCRIPT_NAME">
<input type="submit" value="Back" name="back" />
</form>
EOF
else

# Regular 'Save Changes'
if empty "$FORM_submit"; then
FORM_incldebian=$incldebian
else
savesettings
fi

if host www.phidgets.com 2>&1 1>/dev/null; then
internet_connection="true"
header "System" "Packages" "<img src=\"/images/upd.jpg\" style=\"vertical-align: middle\" alt=\"blocks\" />&nbsp;Package Management" "$SCRIPT_NAME"
else
internet_connection="false"
header "System" "Packages" "<img src=\"/images/upd.jpg\" style=\"vertical-align: middle\" alt=\"blocks\" />&nbsp;Package Management"
fi

if [ "$internet_connection" = "true" ]; then

?>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td class="listtopic">Upgradable Packages</td>
</tr>
<tr>
<td>
<?

apt-get --simulate dist-upgrade 2>&1 | grep Inst | sort | awk '
function getdesc(name) {
if (("/usr/bin/dpkg -s " name " 2>/dev/null | grep \"^Description: \" | sed -n \"s/^Description: \\(.*\\)/\\1/p\"" | getline) > 0) return $0
else return ""
}
{
if(NR == 1) {
print "	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">"
print "	  <tr>"
print "		<td class=\"listhdrlr\">Package</td>"
print "		<td class=\"listhdrr\">Description</td>"
print "		<td class=\"listhdrr\">Installed Version</td>"
print "		<td class=\"listhdrr\">New Version</td>"
print "		<td class=\"listhdrr\">Source</td>"
print "	  </tr>"
}

if (index($3, "[") == 1)
installed = "true"
else
installed = "false"

for (i=1; i<=NF; i++) {
gsub(/^\[/, "", $i)
gsub(/\]$/, "", $i)
gsub(/\]\)$/, "", $i)
gsub(/^\(/, "", $i)
gsub(/\)$/, "", $i)
}

name = $2
if (installed = "true")
{
instver = $3
newver = $4
source = $5
}
else
{
instver = "None"
newver = $3
source = $4
}
desc = getdesc(name)

print "              <tr>"
print "                <td class=\"listlr\">" name "</td>"
print "                <td class=\"listr\">" desc "</td>"
print "                <td class=\"listr\">" instver "</td>"
print "                <td class=\"listr\">" newver "</td>"
print "                <td class=\"listr\">" source "</td>"
print "              </tr>"
fflush()
}
END {
if ( NR > 0 ) {
print "            </table>"
}
else {
print "All packages are up to date."
}

print "          </td>"
print "        </tr>"
print "	</table>"
print "	<br />"

if ( NR > 0 ) {
print "	<input type=\"submit\" value=\"Upgrade All Packages\" name=\"upgrade\" />"
print "	<input type=\"submit\" value=\"Refresh Available Packages\" name=\"refresh\" />"
}
else {
print "	<input type=\"submit\" value=\"Refresh Available Packages\" name=\"refresh\" />"
}
}'

if dpkg -l libphidget21-java | grep ^ii 2>&1 1>/dev/null && dpkg -l default-jre-headless | grep ^ii 2>&1 1>/dev/null; then
javabtn="value=\"Installed\" disabled=\"disabled\""
else
javabtn="value=\"Install\""
fi
if dpkg -l build-essential | grep ^ii 2>&1 1>/dev/null && dpkg -l libphidget21-dev | grep ^ii 2>&1 1>/dev/null; then
cbtn="value=\"Installed\" disabled=\"disabled\""
else
cbtn="value=\"Install\""
fi

cat <<EOF
<br />
<br />

<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td colspan="2" class="listtopic">Installable Packages</td>
</tr>
<tr>
<td class="settings-content" valign="top">
<br />
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td style="width:1px"><input type="submit" $javabtn name="instjava" /></td>
<td>&nbsp;&nbsp;Java Support</td>
</tr><tr>
<td style="width:1px"><input type="submit" $cbtn name="instc" /></td>
<td>&nbsp;&nbsp;C/C++ Development Tools/Headers</td>
</tr>
</table>
</td>
<td class="settings-help" valign="top"><h4>Notes:</h4>
<p>Some common package sets can be installed from this page. Full access to all packages is only available via SSH.</p>
</td>
</tr>
</table>

<br />
<br />
EOF

display_form <<EOF
start_form|Settings
field|
checkbox|incldebian|true|$FORM_incldebian|Include full Debian Package Repository
helpitem|Notes
helptext|Packages from Phidgets Inc. will always be shown. Access to the full Debian repository can be enabled. This will slow down refresh/upgrade operations, but allows full system upgrades and the ability to install new Debian packages.
end_form
EOF

else

cat <<EOF
<span style="color:red">NOTE:</span> Upgrading/Installing packages requires that the SBC have an active internet connection, which is not available.
Please connect your SBC to the internet.
EOF

fi

fi

footer ?>
<!--
##WEBIF:name:System:900:Packages
-->