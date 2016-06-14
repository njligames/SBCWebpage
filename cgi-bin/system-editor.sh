#!/usr/bin/haserl --upload-limit=5120
<?
. /usr/lib/webif/webif.sh
. /lib/webif/config.sh

###################################################################
# userspace-editor
#
# Description:
#	Filesystem browser/File editor.
#       This file is compatible with both branches and
#       should be synchronized between branches
#
# Author(s) [in order of work date]:
#       unknown
#       Lubos Stanek <lubek@users.berlios.de>
#       Patrick McNeil - Phidgets Inc.
#
# Required components:
#       /usr/lib/webif/common.awk
#       /usr/lib/webif/browser.awk
#       /usr/lib/webif/editor.awk
#

. /usr/lib/webif/browser-common.inc

############################
# Header
############################
header "System" "File Editor" "File Editor"

############################
# main view
############################
if empty "$FORM_edit"; then

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
	<div class="settings-help">
		<h4>Notes:</h4>
		<p>Upload file size limit is 5 MB.</p>
	</div>
	<div style="clear: both">&nbsp;</div></div>
EOF

else
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
fi

footer ?>
<!--
##WEBIF:name:System:200:File Editor
-->
