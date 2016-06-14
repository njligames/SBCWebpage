#!/usr/bin/haserl
<?
. /usr/lib/webif/webif.sh
###################################################################
# status-processes.sh

header_inject_head=$(cat <<EOF

<style type="text/css">
<!--
#proctable table {
	margin-left: 1em;
	margin-right: 1em;
	margin-bottom: 1.5em;
	text-align: left;
	font-size: 0.8em;
	border-style: none;
	border-spacing: 0;
	border: thin solid black;
}
#proctable td, th {
	padding-left: 0.5em;
	padding-right: 1.0em;
}
-->
</style>

EOF

)

header "Status" "Processes" "Running Processes"

?>

	<table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td colspan="2" class="listtopic">Process List</td>
        </tr>
        <tr>
          <td colspan="2">
            <table width="100%" border="0" cellspacing="0" cellpadding="0">

<?

proclist=$(echo -n "";ps ww -eo pid,user,state,nlwp,pcpu,pmem,rssize,args --sort pid)
echo "$proclist" | grep -v "[p]s " | awk '
function readcmdline(pid) {
	if (("/bin/cat /proc/" pid "/cmdline 2>/dev/null | tr \"\\0\" \" \"" | getline) > 0) return $0
	else return ""
}
{
	for (i=1; i<=NF; i++) {
		gsub(/^ */, "", $i)
		gsub(/ *$/, "", $i)
		gsub(/&/, "\\&amp;", $i)
		gsub(/</, "\\&lt;", $i)
		gsub(/>/, "\\&gt;", $i)
	}
	if ($1 == "PID") {
		print "              <tr>"
		print "                <td class=\"listhdrlr\">"$1"</td>"
		print "                <td class=\"listhdrr\">"$2"</td>"
		print "                <td class=\"listhdrr\">STATE</td>"
		print "                <td class=\"listhdrr\">THREADS</td>"
		print "                <td class=\"listhdrr\">CPU</td>"
		print "                <td class=\"listhdrr\">MEMORY</td>"
		print "                <td class=\"listhdrr\">"$8"</td>"
		print "              </tr>"
	} else {
		print "              <tr>"
		print "                <td class=\"listlr\">"$1"</td>"
		print "                <td class=\"listr\">"$2"</td>"
		print "                <td class=\"listr\">"$3"</td>"
		print "                <td class=\"listr\">"$4"</td>"
		print "                <td class=\"listr\">"$5"</td>"
		print "                <td class=\"listr\">"$7"</td>"

		pid = $1
		lcol = $8
		for (i=9; i<=NF; i++) lcol = lcol " " $i
		if (length(lcol) >= 50) {
			fulcmd = readcmdline($1)
			if (fulcmd) lcol = fulcmd
		}
		
		print "                <td class=\"listr\">"lcol"</td>"
		print "              </tr>"
	}
}'

	cat <<EOF
            </table>
          </td>
        </tr>
	</table>
		
<a name="pslegend"></a>
<h4>Legend:</h4>

Memory sizes are in KiB.<br />
<ul>
<li>States:</li>
<li>&nbsp;&nbsp;D - Uninterruptible sleep (usually IO)</li>
<li>&nbsp;&nbsp;R - Running or runnable (on run queue)</li>
<li>&nbsp;&nbsp;S - Interruptible sleep (waiting for an event to complete)</li>
<li>&nbsp;&nbsp;T - Stopped, either by a job control signal or because it is being traced.</li>
<li>&nbsp;&nbsp;Z - Defunct ("zombie") process, terminated but not reaped by its parent.</li>
</ul><br />
Commands enclosed in &quot;[...]&quot; are kernel threads.<br />

EOF

footer ?>
<!--
##WEBIF:name:Status:300:Processes
-->
