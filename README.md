## sftp-foxconn

---

## Description
	this tools just test in the linux (Ubuntu 22.04) system, make transfer file easily

	trasnfer agent via ftp or sftp server in specific root directory on server.
	
	for example. <sftp-host>:/my_dir in basic 

upload local file here or download file in /my_dir
	
## Prerequisite tools
	* jq 
	* expect
	* ftp / sftp 
	* python3 (for install script)

## How to install 
	* please change the sftp.config JSON file `config_file` item to specific path and also change the sftp information 
	* setup.py --install-dir=<PATH> # to install program in specific
	* Following the below install procedure
 
	```bash
	cp sample.config sftp.config # fork a config file for 
	sudo ./setup.py
	```

## Configuration file item explain
	
	```
	"version": "1.2"  # this program version 
	"protocol": "sftp/ftp" # this program using which protocol
	"installdir" : "/usr/sbin" # install sftp-foxonn.sh script to this path
	"config_file" : "/home/xxxx/sftp.config" # copy fork sample.config named sftp.config on 
	"host" : "sftp-v.xxxxxx.com" # ftp/sftp host url
	"port" : xxx # sftp ftp target port
	"username" : "xxxx" # login username
	"password" : "xxxxx" # login password
	"r_basepath" : "/temp/jeff"  # your root directory
	"tmpfile" : "ftpget" # cached content for the latest put file filename's filename.
	```
	
## how to use 
	sftp-foxconn
		help, show all available command.
		init, create root directory if the root directory not exist.
		get, download remote file on root directory on remote.
		post, upload local file to remote.
		clear, remove all remoted root directory on remote
		
## some of fluke with expect script 
	On Version 1.2 could available ftp command but not tested on the sftp command. it expected not effect for sftp command. 

P.S. Make sure don't push private sensitive config in git repository 
