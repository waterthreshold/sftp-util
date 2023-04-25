#!/bin/sh
die () {
	msg=$1
	echo $msg
	exit 127
}
get (){
	curl -k -u $username:$password sftp://$host:$port:~/$r_basepath/$tmpfile -o /tmp/$tmpfile
	package=$(cat /tmp/$tmpfile)
	[ -n  "$package" ] &&  curl -k -u $username:$password sftp://$host:$port:~/$r_basepath/$tmpfile -o $install_dir/$package
	rm /tmp/$tmpfile
}


RESULT=$(jq -V 2>&1 | grep "not found" )
[ -n "$result" ] && die "jq not found"
[ ! -e "sftp.config" ]  && die "cannot found config file"
username=$(jq -r .username sftp.config)
password=$(jq -r .password sftp.config)
host=$(jq -r .host sftp.config)
port=$(jq -r .port sftp.config)
r_basepath=$(jq -r .r_basepath sftp.config)
tmpfile=$(jq -r .tmpfile sftp.config)
install_dir= $(jq -r .dut_installdir sftp.config )
METHOD=$1
shift 
case $METHOD  in 
	get) 	
		get $@
		;;
	post)
		post $@
		;;
	# clear)
		# clear_server
		# ;;
	*) help
		;;
esac
	
