#!/usr/bin/haserl
<? 
. /usr/lib/webif/webif.sh

empty "$FORM_password_set" || {
	validate <<EOF
password|FORM_pw1|Password|required min=1 max=63|$FORM_pw1
EOF
	equal "$FORM_pw1" "$FORM_pw2" || {
		ERROR="$ERROR Passwords do not match<br />"
	}
	empty "$ERROR" && {
		RES=$(
			(
				echo "$FORM_pw1"
				sleep 1
				echo "$FORM_pw2"
			) | passwd root 2>&1
		)
		if ! equal "$?" 0; then
			ERROR="<pre>$RES</pre>"
		else
			MESSAGE="Password has been successfully changed."
		fi
	}
}

header "System" "Password Change" "Password Change"

	echo "<form method=\"post\" action=\"$SCRIPT_NAME\">"

display_form <<EOF
start_form|Password Change
field|New Password:
password|pw1
field|Confirm Password:
password|pw2
field|<br />
field|
string|<input type="submit" name="password_set" value="Set Password" />
helpitem|Password
helptext|The system password is the 'root' user password, used for logging into this web interface, as well as logging in as root via SSH. Minimum length is 1 character. Password will be applied immediately.
end_form
EOF

	echo "</form>"

footer ?>

<!--
##WEBIF:name:System:100:Password Change
-->
