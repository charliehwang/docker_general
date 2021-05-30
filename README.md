# Docker for NodeJS Development for VSCode Remote SSH

## Currently has the following built in: 
- Node 14
- Gatsby CLI
- MongoDB

## To build the image and startup the container: 
```
./run.sh 
```
or 
```
docker-compose --project-name web -f ./docker-compose.yml up --build
```
# Environment Variables Setup
In the `.env` file you can:
- Set `SSH_PUB_KEY` to your `id_rsa.pub` key file. Currently it's defaulted to `~/.ssh/id_rsa.pub`. There is no password set for the docker user created, so the only way to login is through the SSH public key. 
- Set the `LOCAL_WORKSPACE_DIR` to desired. This dir on your machine will be mapped to the `/workspace` directory on the container. Currently, it's set to the directory above the docker-general repo dir. 
- Set the user desired in docker to be created. Currently it's set to `admin`. This will be the only user able to login to the docker through ssh.
- `NODE_VARIANT` can be set to the desired Node version install. Currently set to `14.x`

# Setup VSCode Remote SSH
1. Startup the container through the above commands.
2. Download VSCode Remote SSH.
3.  Click on the "Remote Explorer Extension" in the Activity Bar
  - Click on the `+` icon to add a new SSH host.
  - Type `ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" admin@localhost -p 2222` and press `Enter`
	  - The reason for the arguments is because everytime the container is created a new key is created for the container. So we can tell SSH to not worry about adding the container into the known_hosts. 
		
- Select the SSH config you want to update. 
4. Now `localhost` should be in the list of SSH Targets. From here you can hover over the hostname and to the right there is a "Connect to host in new window" icon. 
5. Click on "Open folder..." and navigate to the folder you want in the `/workspace` directory and select the project folder you are working on.
6. This folder in the future will show up in the Remote Explorer and you can just navigate directly to the project folders you have setup under the SSH Target. 

### Note
The image was setup with Node on Ubuntu because VSCode Remote Extension currently does not support Alpine Linux arm64, so M1 Macs are not currently supported. 