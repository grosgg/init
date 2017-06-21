# init :rocket:
Initial setup script for dev machine.

## Initial Server Setup
Run as root
`bash <(wget -qO- https://raw.githubusercontent.com/grosgg/init/master/init_root.sh) 2>&1 | tee ~/init.log`

## Dev Environement Setup
Run as sudoer user
`bash <(wget -qO- https://raw.githubusercontent.com/grosgg/init/master/init_user.sh) 2>&1 | tee ~/init.log`