#!/usr/bin/haserl
<?
. /usr/lib/webif/webif.sh

# functions
show_messages() {
awk -v "filtmode=$1" -v "filtext=$2" '
BEGIN {
	msgcntr = 0
}
function print_sanitize(msg) {
	gsub(/&/, "\\&amp;", msg)
	gsub(/</, "\\&lt;", msg)
	gsub(/>/, "\\&gt;", msg)
	print msg
}
{
	if (filtmode == "include") {
		if ($0 ~ filtext) {
			print_sanitize($0)
			msgcntr++
		}
	} else {
		if ($0 !~ filtext) {
			print_sanitize($0)
			msgcntr++
		}
	}
}
END {
	if (msgcntr == 0) {
		print "There are no kernel messages."
	}
}'
}

# dmesg filtering
filter_temp_dmesg="/tmp/.webif.log-dmesg.tmp"

if [ -n "$FORM_clearfilter_dmesg" ]; then
	rm -f "$filter_temp_dmesg" 2>/dev/null
	unset FORM_filtext_dmesg FORM_filtmode_dmesg
fi

if [ -n "$FORM_newfilter_dmesg" ]; then
	echo "# this file is automatically generated by the webif logs page" > "$filter_temp_dmesg" 2>/dev/null
	echo "# for temporary processing; you are free to delete it" >> "$filter_temp_dmesg" 2>/dev/null
	echo "filtext=$FORM_filtext_dmesg" >> "$filter_temp_dmesg" 2>/dev/null
	echo "filtmode=$FORM_filtmode_dmesg" >> "$filter_temp_dmesg" 2>/dev/null
else 
	if [ -e "$filter_temp_dmesg" ]; then
		FORM_filtext_dmesg=$(sed '/^filtext=/!d; s/^filtext=//' "$filter_temp_dmesg" 2>/dev/null)
		FORM_filtmode_dmesg=$(sed '/^filtmode=/!d; s/^filtmode=//' "$filter_temp_dmesg" 2>/dev/null)
	fi
fi

if [ "$FORM_filtmode_dmesg" != "include" -a "$FORM_filtmode_dmesg" != "exclude" ]; then
	FORM_filtmode_dmesg="include"
fi

[ -n "$FORM_filtext_dmesg" ] && filtered_title_dmesg=" (filtered)"

# syslog filtering
filter_temp_syslog="/tmp/.webif.log-syslog.tmp"

if [ -n "$FORM_clearfilter_syslog" ]; then
	rm -f "$filter_temp_syslog" 2>/dev/null
	unset FORM_filtext_syslog FORM_filtmode_syslog
fi

if [ -n "$FORM_newfilter_syslog" ]; then
	echo "# this file is automatically generated by the webif logs page" > "$filter_temp_syslog" 2>/dev/null
	echo "# for temporary processing; you are free to delete it" >> "$filter_temp_syslog" 2>/dev/null
	echo "filtext=$FORM_filtext_syslog" >> "$filter_temp_syslog" 2>/dev/null
	echo "filtmode=$FORM_filtmode_syslog" >> "$filter_temp_syslog" 2>/dev/null
else 
	if [ -e "$filter_temp_syslog" ]; then
		FORM_filtext_syslog=$(sed '/^filtext=/!d; s/^filtext=//' "$filter_temp_syslog" 2>/dev/null)
		FORM_filtmode_syslog=$(sed '/^filtmode=/!d; s/^filtmode=//' "$filter_temp_syslog" 2>/dev/null)
	fi
fi

if [ "$FORM_filtmode_syslog" != "include" -a "$FORM_filtmode_syslog" != "exclude" ]; then
	FORM_filtmode_syslog="include"
fi

[ -n "$FORM_filtext_syslog" ] && filtered_title_syslog=" (filtered)"

# Header

header "System" "Logs" "Logs"

# Page
cat <<EOF
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
  <td class="listtopic">Kernel Ring Buffer $filtered_title_dmesg</td>
</tr>
<tr>
  <td class="logarea" valign="top">
    <pre>
EOF

dmesg 2>/dev/null | show_messages $FORM_filtmode_dmesg $FORM_filtext_dmesg

cat <<EOF
    </pre>
  </td>
</tr>
<tr>
  <td class="list" style="height:12px">&nbsp;</td>
</tr>
<tr>
  <td class="listtopic">Syslog Messages $filtered_title_syslog</td>
</tr>
<tr>
  <td class="logarea" valign="top">
    <pre>
EOF

cat /var/log/syslog | show_messages $FORM_filtmode_syslog $FORM_filtext_syslog

cat <<EOF
    </pre>
  </td>
</tr>
</table>
<br />
EOF

FORM_filtext_dmesg=$(echo "$FORM_filtext_dmesg" | sed 's/&/\&amp;/; s/"/\&#34;/; s/'\''/\&#39;/; s/\$/\&#36;/; s/</\&lt;/; s/>/\&gt;/; s/\\/\&#92;/; s/|/\&#124;/;')
FORM_filtext_syslog=$(echo "$FORM_filtext_syslog" | sed 's/&/\&amp;/; s/"/\&#34;/; s/'\''/\&#39;/; s/\$/\&#36;/; s/</\&lt;/; s/>/\&gt;/; s/\\/\&#92;/; s/|/\&#124;/;')

display_form <<EOF
formtag_begin|filterform|$SCRIPT_NAME
start_form|Text Filter
field|<h4>Kernel Ring Buffer Filtering</h4>
field|Text to Filter
text|filtext_dmesg|$FORM_filtext_dmesg
field|Filter Mode
select|filtmode_dmesg|$FORM_filtmode_dmesg
option|include|Include
option|exclude|Exclude
string|</td></tr><tr><td>
submit|clearfilter_dmesg|Remove Filter
string|</td><td>
submit|newfilter_dmesg|Filter Messages
field|<h4>Syslog Filtering</h4>
field|
field|Text to Filter
text|filtext_syslog|$FORM_filtext_syslog
field|Filter Mode
select|filtmode_syslog|$FORM_filtmode_syslog
option|include|Include
option|exclude|Exclude
string|</td></tr><tr><td>
submit|clearfilter_syslog|Remove Filter
string|</td><td>
submit|newfilter_syslog|Filter Messages
helpitem|Text to Filter
helptext|Insert a string that covers what you would like to see or exclude. In fact you can use the reqular expression constants like: <code>00:[[:digit:]]{2}:[[:digit:]]{2}</code> or <code>.debug&#124;.err</code>.
helpitem|Filter Mode
helptext|You will see only messages containing the text in the Include mode while you will not see them in the Exclude mode.
end_form
formtag_end
EOF

footer ?>
<!--
##WEBIF:name:System:011:Logs
-->
