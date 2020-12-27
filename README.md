# openvpn-obfsproxy-docker
Open VPN server with obfuscation.

## Creating infrastructure
* Open the following file *create-infrastructure/docker-infrastructure.sh*.
* Updated variables using your values. Pay attention to the path variables.
* Run the deployment script:
``bash
./docker-infrastructure.sh
```
* During deployment ssh key will be created for accessing the virtual machine.
* You can run the following command to connect to the server:
```bash
ssh -i {PATH TO PRIVATE SSH KEY} openvpn@{SERVER PUBLIC IP}
```

## Configuring environment variables
* Open the following files *docker-compose/openvpn-docker/openvpn.env*, *docker-compose/obfsproxy-docker/obfsproxy.env*.
* Set environment variables using your own values (admin username is *openvpn*).
* Password for *obfsproxy* should be base32 encoded.

## Running Open VPN server
* Copy the content of *docker-compose* folder to the server using the following command:
```bash
scp -i {PATH TO PRIVATE SSH KEY} -r {PATH TO ROOT FOLDER}/docker-compose openvpn@{SERVER PUBLIC IP}:/tmp
```
* Connect to the server using SSH and move to the */tmp/docker-compose* folder.
* Pull images from the *Docker HUB* using the following command:
```bash
./docker-compose pull
```
* Run docker containers in detached mode:
```bash
./docker-compose up --detach
```

## Updating Open VPN profiles
* Go to the Open VPN client page *https://{SERVER PUBLIC IP}:943*.
* Enter Open VPN client credentials from the *docker-compose/openvpn-docker/openvpn.env* file.
* Download the client and then install it on your local machine.
* Then in the same page navigate to *Available Connection Profiles* section and click on the link for starting downloading the profile.
* Open profile with any text editor and replace local IP address with the server's public IP.
* This profile can be used for connecting to Open VPN without obfuscation.
* To create profile that is used for establishing connection with obfuscation you should copy the original profile.
* Then open it with any text editor and replace server's public IP with localhost IP address (127.0.0.1).
* Then change 443 port to 21194 port.

## Installing obfsproxy
* Install *python version 2.7* on your local machine.
* Run the following commands:
```bash
pip install --upgrade pip setuptools wheel
pip install obfsproxy
```
* Check that path *c:\Python27\Scripts* added to the *PATH* environment variable.

## Running Open VPN with obfuscation
* Run *obfsproxy* using the following command:
```bash
obfsproxy --log-file {PATH TO LOG FOLDER}/obfsproxy.log --log-min-severity debug scramblesuit --password {PASSWORD} --dest {SERVER PUBLIC IP}:21194 client 127.0.0.1:10194
```
Password should be obtained from the *docker-compose/obfsproxy-docker/obfsproxy.env* file.
You can check log file in case any errors occurred.
* Then run the Open VPN client using the profile with obfuscation.
