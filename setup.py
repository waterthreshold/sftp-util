#!/usr/bin/python3
import json
import shutil
import sys,getopt,os ,stat
long_optdions= [ "install_dir="]
def install_config (dest_path):
    shutil.copy("sftp.config", dest_path)

def install_script (dst):
    shutil.copy ("sftp-foxconn", dst )

def main ():
    with open ("sftp.config") as f:
        stream = f.read()
    j=json.loads(stream)
    dest_path=j["config_file"]
    dst=j["installdir"]
    # ugly way to replace string 
    with open ("sftp-foxconn.sh", "r") as file:
        filedata= file.read()
    filedata = filedata.replace("${HOME}/.config/sftp-foxconn/server.config",dest_path)
    with open("sftp-foxconn", "w") as file:
        file.write(filedata)
    os.chmod("sftp-foxconn",stat.S_IRWXU|stat.S_IRWXO|stat.S_IRWXG)
    try:
        options, arguments = getopt.getopt(sys.argv[1:], "" , long_optdions)
    except getopt.GetoptError:
        print("Error: Invalid command line operations")
        sys.exit(1)
    for option, value in options:
        if option == "--install_dir":
            dst=value
    print ("install script in {} ", dst)
    print ("install config in {} ", dest_path)

    if ( not  os.path.isdir(dst)):
        dst=default_path
    install_config(dest_path)
    install_script(dst)

if __name__ == "__main__":
    main()
