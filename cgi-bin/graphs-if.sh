#!/usr/bin/haserl
<?
#
#credit goes to arantius and GasFed
#
. /usr/lib/webif/webif.sh
. /var/www/cgi-bin/graphs-subcategories.sh

header "Graphs" "Traffic $FORM_if" "Traffic of Interface $FORM_if" "" ""
# This construction supports all recent browsers, degrades correctly, 
# see http://joliclic.free.fr/html/object-tag/en/object-svg.html
?>
<center>
<? if [ -n "$FORM_if" ]; then ?>
	<object type="image/svg+xml" data="/cgi-bin/graph_if_svg.sh?if=<? echo -n ${FORM_if} ?>"
		width="500" height="250">
		<param name="src" value="/cgi-bin/graph_if_svg.sh?if=<? echo -n ${FORM_if} ?>" />
		<a href="http://www.adobe.com/svg/viewer/install/main.html">If the graph is not fuctioning download the viewer here.</a>
	</object>
<? fi ?>
</center>
<? footer ?>
