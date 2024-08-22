
pkg update && pkg upgrade
pkg install proot-distro
proot-distro install ubuntu
proot-distro login ubuntu
apt update
apt install nodejs
npm install -g wrangler
exit
bash <(curl -fsSL https://raw.githubusercontent.com/Kolandone/Selector/main/Sel.sh)
