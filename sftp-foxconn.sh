#!/bin/sh
prerequisite_check (){
	CONNAMD_LIST="jq expect"
	for c in $CONNAMD_LIST; do
		[ ! -x "`command -v $c`" ] && die $c
	done
	EXPECT_PATH="$(command -v expect)"
}
get_config (){

CONFIG_FILE="${HOME}/.config/sftp-foxconn/server.config"
 [ ! -e "$CONFIG_FILE" ]  && die2 "configure file ${CONFIG_FILE} not found !!"
HOST=$(jq -r .host ${CONFIG_FILE})
PORT=$(jq -r .port ${CONFIG_FILE})
PROTOCOL=$(jq -r .protocol ${CONFIG_FILE})
USERNAME=$(jq -r .username ${CONFIG_FILE})
PASSWORD=$(jq -r .password ${CONFIG_FILE})
REMOTEPATH=$(jq -r .r_basepath ${CONFIG_FILE})
TMP_FILE=$(jq -r .tmpfile ${CONFIG_FILE})
PLUGIN_PATH=$(jq -r .pluginPath ${CONFIG_FILE})
}
DEBUG=n
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
set protocol "${PROTOCOL}"
set file [lindex \$argv 0]

if { [string compare \$file ""] == 0 } {
spawn \$protocol -P \$port \$username@\$host:\$default_dir/\$config_file
sleep 2
expect {
	"yes/no" { send "yes\r"; expect "password:" { send "\$password\r" }; exp_continue }
	"password:" { send "\$password\n"; }
	"Password:" { send "\$password\r"; }
}
expect "\$protocol>"  

set f [open "\$config_file"]
set file [read \$f] 
close \$f
}
spawn \$protocol -P \$port \$username@\$host:\$default_dir/\$file
sleep 2
expect {
	"yes/no" { send "yes\r"; expect "password:" { send "\$password\r" }; exp_continue }
	"password:" { send "\$password\n"; }
	"Password:" { send "\$password\r"; }
}
expect "\$protocol>" 
DOC
#		echo $VARS >  sftp-get2.sh
		chmod +x sftp-get.sh
		[ -n "$1" ] && ./sftp-get.sh $1 ||  ./sftp-get.sh
		echo "$1 download done!"
		if [ "$1" != "${TMP_FILE}" ]; then
			rm ${TMP_FILE}
		fi
		[ "$DEBUG" = "n" ] && rm sftp-get.sh
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
set protocol "${PROTOCOL}"
set file [lindex \$argv 0]

spawn \$protocol -P \$port    \$username@\$host
expect {
	"yes/no" { send "yes\n";exp_continue }
	"password:" { send "\$password\n"; } 
	"Password:" { send "\$password\r"; }
}
sleep 2
expect "\$protocol>" 
send "cd \$default_dir\r" 
expect "\$protocol>" 
send "put \$config_file\r" 
expect "\$protocol>" 
send "put \$file\r" 
expect "\$protocol>" 
send "quit\r" 
DOC
	chmod +x sftp-post.sh
	./sftp-post.sh $1
	
	rm  ${TMP_FILE} 
	[ "$DEBUG" = "n" ] && rm sftp-post.sh
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
set protocol ${PROTOCOL}
spawn \$protocol -P \$port \$username@\$host
expect {
	"yes/no" { send "yes\n";exp_continue }
	"password:" { send "\$password\n"; }
	"Password:" { send "\$password\r"; }
}
sleep 2 
expect "\$protocol>"
send "cd \$r_path\r"
expect "\$protocol>"

if { [string compare \$protocol "ftp"] == 0 } {
	send "prompt\r"
	expect "\$protocol>"
	send "mdel *\r"
} else {
	send "rm *\r"
}
expect "\$protocol>"
send "quit\r"
EOF
chmod +x ./sftp_clear.sh
./sftp_clear.sh
echo "clear done !!"
[ "$DEBUG" = "n" ] && rm sftp_clear.sh
}
init (){
cat << EOF > sftp_init.sh
#!${EXPECT_PATH} 
set timeout 600
set host ${HOST}
set port ${PORT}
set username ${USERNAME}
set password ${PASSWORD}
set r_path ${REMOTEPATH}
set protocol ${PROTOCOL}
spawn \$protocol -P \$port \$username@\$host
expect {
	"yes/no" { send "yes\n";exp_continue }
	"password:" { send "\$password\n"; }
	"Password:" { send "\$password\r"; }
}
sleep 2 
expect "\$protocol>"
send "mkdir \$r_path\r"
expect "\$protocol>"
send "quit\r"
EOF
chmod +x sftp_init.sh
./sftp_init.sh
echo "initial done"
[ "$DEBUG" = "n" ] && rm sftp_init.sh
}

help () {
	echo "usage: ${0##*/} is an shell script transfer file to own sftp/ftp server connect with internl/external network tool"
	echo "symbol comment:"
	echo "	() -  for optional parameter"
	echo "	\"\" - must have this paramter"
	echo "suppport command:"
	echo "	get (filename)- fetch the config file and downaload file from sftp/ftp server"
	echo "	post \"file_path\" - update the config file and downaload the specific file from sftp/ftp server"
	echo "	clear - delete all file on remote specific path"
	echo "	init - initial the sftp/ftp base path"
	exit 127
}
plugin (){
	found=0
	echo "METHOD $1"
	[ -z "$1" ] && help
	PLUGIN_NAME=$1
	shift
	for file in "$PLUGIN_PATH"/*; do
		filename=$(basename "$file")
#		echo $filename
		if [ "$filename" = "${PLUGIN_NAME}" ]; then
			/${PLUGIN_PATH}/$filename $@
			found=1
			break
		fi
	done
	[ "$found" -eq 0 ] && help
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
	init)
		init
		;;
	version)
		version
		;;
	*) 
		plugin $METHOD $@
		#help
		;;
esac

