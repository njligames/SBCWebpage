#!/usr/bin/haserl
<?
. /usr/lib/webif/webif.sh

if ! empty "$FORM_umount"; then
	if ! empty "$FORM_mountdev"; then
		err_umount=$(umount $FORM_mountdev 2>&1)
		! equal "$?" "0" && {
			ERROR="Error in $err_umount"
		}
	fi
fi

header "Status" "USB" "USB Devices"

?>
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td class="listtopic">All connected devices</td>
        </tr>
        <tr>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
<?

if [ -f /proc/bus/usb/devices ]; then
	grep -e "^[TDPS]:" /proc/bus/usb/devices | sed 's/[[:space:]]*=[[:space:]]*/=/g' | sed 's/[[:space:]]\([^ |=]*\)=/|\1=/g' | sed 's/^/|/' | awk '
	BEGIN {
		i=0; RS="|"; FS="=";
		print "              <tr>"
		print "                <td class=\"listhdrlr\">Bus</td>"
		print "                <td class=\"listhdrr\">Device</td>"
		print "                <td class=\"listhdrr\">Product</td>"
		print "                <td class=\"listhdrr\">Manufacturer</td>"
		print "                <td class=\"listhdrr\">VendorID:ProdID</td>"
		print "                <td class=\"listhdrr\">USB version</td>"
		print "                <td class=\"listhdrr\">Speed</td>"
		print "              </tr>"
	}
	$1 ~ /^T: / { i++; }
	$1 ~ /^Bus/ { bus[i]=$2; }
	$1 ~ /^Dev#/ { device[i]=$2; }
	$1 ~ /^Ver/ { usbversion[i]=$2; }
	$1 ~ /^Vendor/ { vendorID[i]=$2; }
	$1 ~ /^ProdID/ { productID[i]=$2; }
	$1 ~ /^Manufacturer/ { manufacturer[i]=$2; }
	$1 ~ /^Product/ { product[i]=$2; }
	$1 ~ /^Spd/ { speed[i]=$2; gsub(/[[:space:]]*$/, "", speed[i]); }
	END {
		for ( j=1; j<=i; ++j ) {
			vpID=vendorID[j]":"productID[j];
			if ( length(product[j])<1 && vpID != "0000:0000" ) {
				"/usr/sbin/lsusb -d " vpID " | sed \"s/^.*" vpID " //\"" | getline product[j];
			}
			if ( length(manufacturer[j])<1 && productID[j]!="0000" ) {
				pid=vendorID[j];
				"[ -f /usr/share/misc/usb.ids ] && grep -e \"^" pid "\" /usr/share/misc/usb.ids | sed \"s/^" pid " *//\"" | getline manufacturer[j];
			}
			if ( vpID != "0000:0000" ) {
				print "              <tr>"
				print "                <td class=\"listlr\">" bus[j] "</td>"
				print "                <td class=\"listr\">" device[j] "</td>"
				print "                <td class=\"listr\">" product[j] "</td>"
				print "                <td class=\"listr\">" manufacturer[j] "</td>"
				print "                <td class=\"listr\">" vpID "</td>"
				print "                <td class=\"listr\">" usbversion[j] "</td>"
				print "                <td class=\"listr\">" speed[j] "</td>"
				print "              </tr>"
			}
		}
	}
'
else
	lsusbinfo=$(lsusb -t 2>/dev/null; lsusb -v;)
	echo "$lsusbinfo" | awk '
	BEGIN {
		i=-1;
		print "              <tr>"
		print "                <td class=\"listhdrlr\">Tree</td>"
		print "                <td class=\"listhdrr\">Manufacturer</td>"
		print "                <td class=\"listhdrr\">Product</td>"
		print "                <td class=\"listhdrr\">VendorID:ProdID</td>"
		print "                <td class=\"listhdrr\">USB version</td>"
		print "                <td class=\"listhdrr\">Speed</td>"
		print "                <td class=\"listhdrr\">Kernel Driver(s)</td>"
		print "              </tr>"
	}

	function filldriver() {
		driverarg=NF-1;
		drv=substr($driverarg, 8, length($driverarg)-8);
		if(drv != "" && index(driver[i], drv) == 0)
		{
			if(driver[i] != "")
				driver[i]=driver[i]", ";
			driver[i]=driver[i] drv;
		}
	}

	$1 ~ /^\/\:/ && $2 ~ /^Bus/ {
		i++;
		curbus=substr($3,0,index($3,".")-1) + 0;

		devtype[i]="Root Hub";
		bus[i]=curbus;
		device[i]=substr($6, 0, length($6)-1) + 0;
		speed[i]=$NF;
		filldriver();
	}

	$1 ~ /^\|__/ && $2 ~ /^Port/ {
		intf=substr($7, 0, length($7)-1) + 0;
		if(intf == "0") {
			i++;
			filldriver();

			spacestring=substr($0,0,index($0,"|")-1);
			nbspstr="";
			for(k=0;k<length(spacestring);k++)
				nbspstr=nbspstr"&nbsp;";

			if ($8 == "Class=hub,") {
				ports=substr(driver[i],index(driver[i],"/")+1,length(driver[i])-1-index(driver[i],"/"));
				devtype[i]=nbspstr"↳ Hub ("ports" Port)";
			}
			else {
				devtype[i]=nbspstr"↳ Device";
			}
			bus[i]=curbus;
			device[i]=substr($5, 0, length($5)-1) + 0;
			speed[i]=$NF;
		}
		else
			filldriver();

	}

	$1 ~ /^Bus/ {
		curbus=$2+0;
		curdev=substr($4,0,length($4)-1)+0;

		for(j=0;j<=i;j++) {
			if(curbus == bus[j] && curdev == device[j])
				break;
		}

		vpID[j]=$6;
	}
	$1 ~ /^bcdUSB/ { usbversion[j]=$2; }
	$1 ~ /^idProduct/ {
		product[j]=$3;
		for(k=4;k<=NF;k++) {
			product[j] = product[j]" "$k;
		}
	}
	$1 ~ /^idVendor/ { 
		manufacturer[j]=$3;
		for(k=4;k<=NF;k++) {
			manufacturer[j] = manufacturer[j]" "$k;
		}
	}
	$1 ~ /^iProduct/ {
		if(NF>2) {
			product[j]=$3;
			for(k=4;k<=NF;k++) {
				product[j] = product[j]" "$k;
			}
		}
	}
	$1 ~ /^iManufacturer/ { 
		if(NF>2) {
			manufacturer[j]=$3;
			for(k=4;k<=NF;k++) {
				manufacturer[j] = manufacturer[j]" "$k;
			}
		}
	}

	END {
		for ( j=0; j<=i; ++j ) {
			if ( vpID[j] != "0000:0000" ) {
				print "              <tr>"
				print "                <td class=\"listlr\">" devtype[j] "</td>"
				print "                <td class=\"listr\">" manufacturer[j] "</td>"
				print "                <td class=\"listr\">" product[j] "</td>"
				print "                <td class=\"listr\">" vpID[j] "</td>"
				print "                <td class=\"listr\">" usbversion[j] "</td>"
				print "                <td class=\"listr\">" speed[j] "</td>"
				print "                <td class=\"listr\">" driver[j] "</td>"
				print "              </tr>"
			}
		}
	}
'
fi

?>
            </table>
          </td>
        </tr>
<?

mounted_devices="$(cat /proc/mounts | grep -e "^/dev/sd[a-p]\{0,2\}" -e "^/dev/scsi/.*")"
! equal "$mounted_devices" "" && {
	cat << EOF
		<tr>
          <td class="list" height="12">&nbsp;</td>
        </tr>
        <tr>
          <td class="listtopic">Mounted USB Drives</td>
        </tr>
        <tr>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
EOF
	echo "$mounted_devices" | awk -v url="$SCRIPT_NAME" '
	BEGIN {
		print "              <tr>"
		print "                <td class=\"listhdrlr\">Device Path</td>"
		print "                <td class=\"listhdrr\">Mount Point</td>"
		print "                <td class=\"listhdrr\">File System</td>"
		print "                <td class=\"listhdrr\">Read/Write</td>"
		print "                <td class=\"listhdrr\">Action</td>"
		print "              </tr>"
	}
	{
		print "              <tr>"
		print "                <td class=\"listlr\">" $1 "</td>"
		print "                <td class=\"listr\">" $2 "</td>"
		print "                <td class=\"listr\">" $3 "</td>"
		$4 = "," $4 ","
		if ($4 ~ /,ro,/)
			print "                <td class=\"listr\">Read only</td>"
		else if ($4 ~ /,rw,/)
			print "                <td class=\"listr\">Read/Write</td>"
		else
			print "                <td class=\"listr\">&nbsp;</td>"
		print "                <td class=\"listr\"><form method=\"post\" action=\"" url "\">" \
								"<input type=\"submit\" value=\"Unmount\" name=\"umount\" />" \
								"<input type=\"hidden\" value=\"" $1 "\" name=\"mountdev\" /></form></td>"
		print "              </tr>"
	}'
	cat << EOF
            </table>
          </td>
        </tr>
EOF
}

?>

</table>

<? footer ?>
<!--
##WEBIF:name:Status:400:USB
-->
