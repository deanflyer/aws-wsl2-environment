# Shell script to setup development environment for AWS under WSL2 for Windows 10
# Installs the following utilities: -
# aws-cli, unzip, jq, pip, git, SSH for git, clone initial repo, cfn-lint, Node.js, cfn-diagram, AWS CDK
# As of date 15/06/2021 Python 3.9 is not recommend, use Python 3.8 which is default installed version on Ubuntu 20.04 
#
# Git personal access token: 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
# Thanks to Peter Sellars (github.com/petersellars) for the code to automate GitHub SSH key generation.
# https://gist.github.com/petersellars/c6fff3657d53d053a15e57862fc6f567

# Variables
# Do not publish publicly until credentials are removed!
AWS_DEFAULTACCESSKEYID="AKIAUGWSEOMXAUNKDL42"
AWS_DEFAULTSECRETACCESSKEY="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"
AWS_DEFAULTREGION="eu-west-2"
AWS_DEFAULTOUTPUTFORMAT="yaml"
GIT_TOKEN="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"

# Update to latest version of WSL2, install unzip and build tools
echo "Update/Upgrade Ubuntu..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install unzip -y

# Install and configure AWS CLI. Config file default location is ~/.aws/config
echo "Install and configure AWS CLI..."
echo -n "Enter default Access Key ID, or press enter for default value ["$AWS_DEFAULTACCESSKEYID"]:"
read AWS_INPUT_VARIABLE
if [ -n "$AWS_INPUT_VARIABLE" ]
	then
		AWS_DEFAULTACCESSKEYID=$AWS_INPUT_VARIABLE
		echo "AWS default Access Key ID has been changed to:" $AWS_DEFAULTACCESSKEYID
fi

echo -n "Enter default Secret Access Key, or press enter for default value ["$AWS_DEFAULTSECRETACCESSKEY"]:"
read AWS_INPUT_VARIABLE
if [ -n "$AWS_INPUT_VARIABLE" ]
	then
		AWS_DEFAULTSECRETACCESSKEY=$AWS_INPUT_VARIABLE
		echo "AWS Secret Access Key has been changed to:" $AWS_DEFAULTSECRETACCESSKEY
fi

echo -n "Enter default AWS region, or press enter for default region ["$AWS_DEFAULTREGION"]:"
read AWS_INPUT_VARIABLE
if [ -n "$AWS_INPUT_VARIABLE" ]
	then
		AWS_DEFAULTREGION=$AWS_INPUT_VARIABLE
		echo "AWS region has been changed to:" $AWS_DEFAULTREGION
fi

echo -n "Enter default output format or press enter for default output (json, yaml, yaml-stream, text, table) ["$AWS_DEFAULTOUTPUTFORMAT"]:"
read AWS_INPUT_VARIABLE
if [ -n "$AWS_INPUT_VARIABLE" ]
	then
		AWS_DEFAULTOUTPUTFORMAT=$AWS_INPUT_VARIABLE
		echo "AWS default output has been changed to:" $AWS_DEFAULTOUTPUTFORMAT
fi

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws configure set aws_access_key_id $AWS_DEFAULTACCESSKEYID
aws configure set aws_secret_access_key $AWS_DEFAULTSECRETACCESSKEY
aws configure set default.region $AWS_DEFAULTREGION

#Install JSON command line parser utility
echo "Installing jq JSON parser..."
sudo apt install jq -y

#Install Python - Check if really need to use deadsnakes ppa
# sudo apt install software-properties-common
# sudo add-apt-repository ppa:deadsnakes/ppa
# sudo apt update
# sudo apt install python3.8

# Install Package Installer for Python (PIP)
echo "Installing PIP..."
sudo apt install python3-pip -y

# Install latest stable version of Git. Git is included with Ubuntu 20.04 distro but not latest version of Git.
echo "Installing latest version of Git..."
sudo add-apt-repository ppa:git-core/ppa -y
sudo apt update
sudo apt install git -y

# Setup SSH for Git. ssh-keygen will handle empty email/empty password conditions
GIT_TOKEN="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"
echo "SSH setup for GitHub"
echo "Enter your email address (comment for SSH key)"
read -p 'Email Address:' SSH_EMAIL
echo "When prompted, enter your passphrase. This will be used to authenticate every time you start a new WSL2 session."
echo "Memorise your passphrase as this can not be recovered. Leave blank for no passphrase"

ssh-keygen -q -a 64 -b 4096 -t ed25519 -C $SSH_EMAIL -f ~/.ssh/github_ed25519

PUBKEY=`cat ~/.ssh/github_ed25519.pub`
TITLE=`hostname`-autogen
RESPONSE=`curl -s -H "Authorization: token ${GIT_TOKEN}" \
  -X POST --data-binary "{\"title\":\"${TITLE}\",\"key\":\"${PUBKEY}\"}" \
  https://api.github.com/user/keys`
KEYID=`echo $RESPONSE \
  | grep -o '\"id.*' \
  | grep -o "[0-9]*" \
  | grep -m 1 "[0-9]*"`
echo "SSH public key added succesfully to GitHub account. KeyID - " $KEYID

# Add key to ssh-agent, install keychain (manager for ssh-agent) and add startup to bash profile.
eval "$(ssh-agent -s)"
echo "Adding key to ssh-agent. Enter your passphrase."
ssh-add ~/.ssh/github_ed25519
echo "Installing keychain..."
sudo apt install keychain -y
echo "Adding keychain to .profile for session autostart"
echo '/usr/bin/keychain --nogui $HOME/.ssh/github_ed25519' >> ~/.profile
echo 'source $HOME/.keychain/$HOSTNAME-sh' >> ~/.profile

# Change remote URL to SSH
#git remote set-url origin git@github.com:USERNAME/REPOSITORY.git

# Show remote repositories
#git remote -v

# Clone GitHub repository
#git clone git@github.com:deanflyer/aws-wordpress.git

# Install CloudFormation linter via Brew instead of pip
# Issue using pip3 to install cfn-lint due to conflict with aws-sam
echo "Installing cfn-lint..."
#pip3 install cfn-linter
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install cfn-lint

#Install Node.js
echo "Installing Node.js..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install node --lts
nvm use node --lts

#Install cfn-diagram
echo "Installing cfn-diagram..."
npm i -g @mhlabs/cfn-diagram

#Install AWS CDK
echo "Installing AWS CDK..."
npm -g install typescript
npm install -g aws-cdk

#Install Visual Studio Code extensions
#code --install-extensions kddejong.vscode-cfn-lint
#code --install-extensions redhat.vscode-yaml

