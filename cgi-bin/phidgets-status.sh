#!/usr/bin/haserl
<? 
. /usr/lib/webif/webif.sh

_subtitle="$( phidget21version )<br /><br />"

header "Phidgets" "Status" "Phidget Status"

?>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td class="listtopic">List of attached Phidgets</td>
  </tr>
  <tr>
    <td>
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
<?

			phidgetlist | awk '
	BEGIN {
		FS="	";
		print "        <tr>"
		print "          <td class=\"listhdrlr\">Name</td>"
		print "          <td align=\"right\" class=\"listhdrr\">Version</td>"
		print "          <td align=\"right\" class=\"listhdrr\">Serial Number</td>"
		print "        </tr>"
	}
	{
		print "        <tr>"
		print "          <td class=\"listlr\">" $1 "</td>"
		print "          <td align=\"right\" class=\"listr\">" $3 "</td>"
		print "          <td align=\"right\" class=\"listr\">" $2 "</td>"
		print "        </tr>"
	}
'

?>
      </table>
    </td>
  </tr>
</table>
<? footer ?>
<!--
##WEBIF:name:Phidgets:100:Status
##WEBIF:name:Status:500:Phidgets
-->
