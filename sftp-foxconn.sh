#!/bin/sh
prerequisite_check (){
	CONNAMD_LIST="jq expect"
	for c in $CONNAMD_LIST; do
		[ ! -x "`command -v $c`" ] && die $c
	done
	EXPECT_PATH="$(command -v expect)"
}
get_config (){

CONFIG_FILE="[REPLACE_CONFIG_IN_HERE]"
 [ ! -e "$CONFIG_FILE" ]  && die2 "configure file ${CONFIG_FILE} not found !!"
HOST=$(jq -r .host ${CONFIG_FILE})
PORT=$(jq -r .port ${CONFIG_FILE})
USERNAME=$(jq -r .username ${CONFIG_FILE})
PASSWORD=$(jq -r .password ${CONFIG_FILE})
REMOTEPATH=$(jq -r .r_basepath ${CONFIG_FILE})
TMP_FILE=$(jq -r .tmpfile ${CONFIG_FILE})
}
die2 (){
	msg=$1
	echo $msg
	exit 127
}
die (){
	echo "Program $1 does not exist or no execte privillege"
	exit 127
}


get (){
cat << DOC  > sftp-get.sh
#!${EXPECT_PATH}
set timeout 600
set host "${HOST}"
set port ${PORT}
set username "${USERNAME}"
set password "${PASSWORD}"
set default_dir "${REMOTEPATH}"
set config_file "${TMP_FILE}"
set file [lindex \$argv 0]

if { [string compare \$file ""] == 0 } {
spawn sftp -P \$port \$username@\$host:\$default_dir/\$config_file
expect {
	"yes/no" { send "yes\r"; expect "password:" { send "\$password\r" }; exp_continue }
	"password:" { send "\$password\r"; }
}

set f [open "\$config_file"]
set file [read \$f] 
close \$f
}
spawn sftp -P \$port \$username@\$host:\$default_dir/\$file
expect {
	"yes/no" { send "yes\r"; expect "password:" { send "\$password\r" }; exp_continue }
	"password:" { send "\$password\r"; }
}
DOC
#		echo $VARS >  sftp-get2.sh
		chmod +x sftp-get.sh
		[ -n "$1" ] && ./sftp-get.sh $1 ||  ./sftp-get.sh
		echo "$1 download done!"
		if [ "$1" != "${TMP_FILE}" ]; then
			rm ${TMP_FILE}
		fi
		rm  sftp-get.sh
}

post () {
	[ -z "$1" ] && help 
	echo -n ${1##*/} > ${TMP_FILE}
cat << DOC  > sftp-post.sh
#!${EXPECT_PATH}
set timeout 600
set username "${USERNAME}"
set password "${PASSWORD}"
set host "${HOST}"
set port ${PORT}
set default_dir "${REMOTEPATH}"
set config_file "${TMP_FILE}"
set file [lindex \$argv 0]

spawn sftp -P \$port    \$username@\$host
expect {
	"yes/no" { send "yes\n";exp_continue }
	"password:" { send "\$password\n"; } 
}
sleep 2
expect "sftp>" 
send "put \$config_file \$default_dir\r" 
expect "sftp>" 
send "put \$file \$default_dir\r" 
expect "sftp>" 
send "quit\r" 
DOC
	chmod +x sftp-post.sh
	./sftp-post.sh $1
	
	rm  ${TMP_FILE} sftp-post.sh
	echo "$1 upload done!"
}
clear_server (){
cat << EOF > sftp_clear.sh
#!${EXPECT_PATH} 
set timeout 600
set host ${HOST}
set port ${PORT}
set username ${USERNAME}
set password ${PASSWORD}
set r_path ${REMOTEPATH}
spawn sftp -P \$port \$username@\$host
expect {
	"yes/no" { send "yes\n";exp_continue }
	"password:" { send "\$password\n"; }
}
sleep 2 
expect "sftp>"
send "cd \$r_path\r"
expect "sftp>"
send "rm *\r"
expect "sftp>"
send "quit\r"
EOF
chmod +x ./sftp_clear.sh
./sftp_clear.sh
echo "clear done !!"
rm sftp_clear.sh
}

help () {
	echo "usage: ${0##*/} is an shell script transfer file to Foxconn sftp server connect with internl/external network tool"
	echo "symbol comment:"
	echo "	() -  for optional parameter"
	echo "	\"\" - must have this paramter"
	echo "suppport command:"
	echo "	get (filename)- fetch the config file and downaload file from sftp server"
	echo "	post \"file_path\" - update the config file and downaload the specific file from sftp server"
	echo "	clear - delete all file on remote specific path"
	exit 127
}
version (){

		echo "${PROGRAM_NAME} Version: $(jq -r .version ${CONFIG_FILE})"
}
prerequisite_check
get_config
PROGRAM_NAME=${0##*/}
METHOD=$1
shift 
case "$METHOD" in 
	get) 	
		get $@
		;;
	post)
		post $@
		;;
	clear)
		clear_server
		;;
	version)
		version
		;;
	*) help
		;;
esac

