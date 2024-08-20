curl -o $PREFIX/bin/koland https://raw.githubusercontent.com/Kolandone1/workercreator/main/kol.py

# Make the script executable
chmod +x $PREFIX/bin/koland
echo "alias koland='$PREFIX/bin/koland'" >> ~/.bashrc
# Or if you use zsh
# echo "alias koland='$PREFIX/bin/koland'" >> ~/.zshrc
source ~/.bashrc
# Or if you use zsh
# source ~/.zshrc
