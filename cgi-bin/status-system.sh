#!/usr/bin/haserl
<? 
. /usr/lib/webif/webif.sh

#_subtitle=$( echo -n "<pre>"; cat /etc/issue.net; echo "</pre><br />" )

header "Status" "System" "System Status"

_phidget21version="$(phidget21version)"
_kversion="$( cat /proc/version )"
_distro="$( cat /etc/issue.net )"
_date="$(date)"
_mac="$(/sbin/ifconfig eth0 | grep HWaddr | awk '{print $5}')"
_board_name="$([ -e /proc/device-tree/model ] && (cat /proc/device-tree/model; echo '';) || (cat /proc/cpuinfo | awk '/^Hardware/ {print $3}'))"
_firmware_board=$( grep "board" /etc/phidgetsbc_version | awk '{print $2}' )
_firmware_date=$( grep "date" /etc/phidgetsbc_version )
_firmware_date=${_firmware_date#date }
_webifversion=$(dpkg -s phidgetsbcwebif | grep "^Version:" | awk '{print $2}')

cat <<EOF
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
  <td colspan="2" class="listtopic">System information</td>
</tr>
<tr>
  <td class="vncellt" style="width:25%">Board Name</td>
  <td class="listr" style="width:75%">$_board_name</td>
</tr>
<tr>
  <td class="vncellt" style="width:25%">Board Revision</td>
  <td class="listr" style="width:75%">$_board_version</td>
</tr>
<tr>
  <td class="vncellt" style="width:25%">Webif Version</td>
  <td class="listr" style="width:75%">$_webifversion</td>
</tr>
<tr>
  <td class="vncellt" style="width:25%">Firmware Version</td>
  <td class="listr" style="width:75%">$_firmware_board - Version $_version - Built $_firmware_date</td>
</tr>
<tr>
  <td class="vncellt" style="width:25%">Kernel Version</td>
  <td class="listr" style="width:75%">$_kversion</td>
</tr>
<tr>
  <td class="vncellt" style="width:25%">Distribution</td>
  <td class="listr" style="width:75%">$_distro</td>
</tr>
<tr>
  <td class="vncellt" style="width:25%">Phidget Library</td>
  <td class="listr" style="width:75%">$_phidget21version</td>
</tr>
<tr>
  <td class="vncellt" style="width:25%">Current Date/Time</td>
  <td class="listr" style="width:75%">$_date</td>
</tr>
<tr>
  <td class="vncellt" style="width:25%">MAC Address</td>
  <td class="listr" style="width:75%">$_mac</td>
</tr>
<tr>
  <td colspan="2" class="list" style="height:12px">&nbsp;</td>
</tr>
<tr>
  <td colspan="2">
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
	  <tr>
		<td colspan="5" class="listtopic">Filesystem</td>
	  </tr>
	  <tr>
		<td class="listhdrlr" style="width:20%">Mountpoint</td>
		<td class="listhdrr" style="width:20%">Size</td>
		<td class="listhdrr" style="width:20%">Used</td>
		<td class="listhdrr" style="width:20%">Available</td>
		<td class="listhdrr" style="width:20%">Usage</td>
	  </tr>
EOF
					
df -h | awk '/(rootfs)|(media\/usb)/ {
		usepercent = substr($5, 1, length($5)-1);
		freepercent = 100 - int($5);
		print "              <tr>"
		print "                <td class=\"listlr\" style=\"width:20%\">" $6 "</td>"
		print "                <td class=\"listr\" style=\"width:20%\">" $2 "</td>"
		print "                <td class=\"listr\" style=\"width:20%\">" $3 "</td>"
		print "                <td class=\"listr\" style=\"width:20%\">" $4 "</td>"
		print "                <td class=\"listr\" style=\"width:20%\">"
		print "                  <img src=\"../images/bar_left.gif\" class=\"progbarl\" alt=\"\" />" \
								"<img src=\"../images/bar_green.gif\" class=\"progbarcf\" width=\"" usepercent "\" alt=\"\" />" \
								"<img src=\"../images/bar_gray.gif\" class=\"progbarc\" width=\"" freepercent "\" alt=\"\" />" \
								"<img src=\"../images/bar_right.gif\" class=\"progbarr\" alt=\"\" /> " $5
		print "                </td>"
		print "              </tr>"
	}'

cat <<EOF
	</table>
  </td>
</tr>
<tr>
  <td colspan="2" class="list" style="height:12px">&nbsp;</td>
</tr>
<tr>
  <td colspan="2" class="listtopic">Memory</td>
</tr>
EOF

free -o | awk '/Mem:/ {
		memtotal = $2;
		memtotalMiB = int($2) / 1024;
		memfreepercent = int($4) * 100 / int(memtotal);
		memtotalusedpercent = int($3) * 100 / int(memtotal);
		memchachebufferpercent = (int($6) + int($7)) * 100 / int(memtotal);
		memusedpercent = memtotalusedpercent - memchachebufferpercent;
	}
	END {
		print "        <tr>"
		print "          <td class=\"vncellt\" style=\"width:25%\">Memory usage</td>"
		print "          <td class=\"listr\" style=\"width:75%\">"
		print "            <img src=\"../images/bar_left.gif\" class=\"progbarl\" alt=\"\" />" \
						  "<img src=\"../images/bar_red.gif\" width=\"" int(memusedpercent) "\" class=\"progbarcf\" alt=\"\" />" \
						  "<img src=\"../images/bar_blue.gif\" width=\"" int(memchachebufferpercent) "\" class=\"progbarcf\" alt=\"\" />" \
						  "<img src=\"../images/bar_gray.gif\" width=\"" int(memfreepercent) "\" class=\"progbarc\" alt=\"\" />" \
						  "<img src=\"../images/bar_right.gif\" class=\"progbarr\" alt=\"\" />"
		printf("            &nbsp;%d&#37; of %.1fMiB\n", memtotalusedpercent, memtotalMiB);
		print "          </td>"
		print "        </tr>"
	}'

echo "</table>"

footer
?>
<!--
##WEBIF:name:Status:100:System
-->
