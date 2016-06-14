#!/usr/bin/haserl
<?
#
#credit goes to arantius and GasFed
#
. /usr/lib/webif/webif.sh
. /var/www/cgi-bin/graphs-subcategories.sh

header "Graphs" "CPU" "CPU Usage" "" ""
# This construction supports all recent browsers, degrades correctly, 
# see http://joliclic.free.fr/html/object-tag/en/object-svg.html
?>
<center>
	<object type="image/svg+xml" data="/cgi-bin/graph_cpu_svg.sh"
		width="500" height="250">
		<param name="src" value="/cgi-bin/graph_cpu_svg.sh" />
		<a href="http://www.adobe.com/svg/viewer/install/main.html">If the graph is not fuctioning download the viewer here.</a>
	</object>
</center>
<? footer ?>
<!--
##WEBIF:name:Graphs:1:CPU
-->
