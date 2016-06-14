#!/usr/bin/haserl
Content-Type: image/svg+xml 
Content-Disposition: inline
Pragma: no-cache

<?
echo -e "\r"`date`
if [ "$FORM_if" ]; then
	grep "${FORM_if}:" /proc/net/dev
else
	head -n 1 /proc/stat
fi
?>