# Shell script to setup development environment for AWS under WSL2 for Windows 10
# Installs the following utilities: -
# aws-cli, unzip, jq, pip, git, SSH for git, clone initial repo, cfn-lint, Node.js, cfn-diagram, AWS CDK
# As of date 15/06/2021 Python 3.9 is not recommend, use Python 3.8 which is default installed version on Ubuntu 20.04 
#
# You will need a GitHub Access Token with admin:public_key permissions
# Thanks to Peter Sellars (github.com/petersellars) for the code to automate GitHub SSH key generation.
# https://gist.github.com/petersellars/c6fff3657d53d053a15e57862fc6f567
#
# Usage:
# Enter on command line as below or when prompted
# ./aws-wsl2-dev.sh <aws-access-key-id> <aws-secret-access-key> <aws-default-region> <aws-default-output-format> <github-access-token>
#
# <aws-access-key-id> - Your AWS Access key ID.
# <aws-secret-access-key> - Your AWS Secret access key.
# <aws-default-region> - AWS region you wish to set as default. i.e. us-east-1 (see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-regions for full list).
# <aws-default-output-format> - Default cli output format. Valid values are json, yaml, yaml-stream, text, table (see https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-output-format.html for more details).
# <github-access-token> - Token to allow creation of SSH key in GitHub. You can create this at https://github.com/settings/tokens
#
# Variables for AWS and Github credentials
AWS_DEFAULTACCESSKEYID=$1
AWS_DEFAULTSECRETACCESSKEY=$2
AWS_DEFAULTREGION=$3
AWS_DEFAULTOUTPUTFORMAT=$4
GIT_TOKEN=$5

#Terminal Colours
BLUE_TEXT='\033[0;34m'
GREEN_TEXT='\033[0;32m'
RED_TEXT='\033[0;31m'

# Update to latest version of Ubuntu/install unzip.
echo -e "${BLUE_TEXT}Update/Upgrade Ubuntu...${GREEN_TEXT}"
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install unzip -y

# Install and configure AWS CLI. Config file default location is ~/.aws/config
echo -e "${BLUE_TEXT}Install and configure AWS CLI...${GREEN_TEXT}"
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

echo -n "Enter Git Personal Access Token to allow SSH key creation ["$GIT_TOKEN"]:"
read AWS_INPUT_VARIABLE
if [ -n "$AWS_INPUT_VARIABLE" ]
	then
		GIT_TOKEN=$AWS_INPUT_VARIABLE
		echo "Git Token has been set to:" $GIT_TOKEN
fi

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws configure set aws_access_key_id $AWS_DEFAULTACCESSKEYID
aws configure set aws_secret_access_key $AWS_DEFAULTSECRETACCESSKEY
aws configure set default.region $AWS_DEFAULTREGION

#Install JSON command line parser utility
echo -e "${BLUE_TEXT}Installing jq JSON parser...${GREEN_TEXT}"
sudo apt install jq -y

# Install Package Installer for Python (PIP)
echo -e "${BLUE_TEXT}Installing Package Installer for Python(PIP)...${GREEN_TEXT}"
sudo apt install python3-pip -y

# Install latest stable version of Git. Git is included with Ubuntu 20.04 distro but not latest version of Git.
echo -e "${BLUE_TEXT}Installing latest version of Git...${GREEN_TEXT}"
sudo add-apt-repository ppa:git-core/ppa -y
sudo apt update
sudo apt install git -y

# Setup SSH for Git. ssh-keygen will handle empty email/empty password conditions
echo -e "${BLUE_TEXT}Install and configure SSH for GitHub${GREEN_TEXT}"
read -p "Enter your Email Address: " SSH_EMAIL
echo "When prompted, enter your passphrase. This will be used to authenticate every time you start a new WSL2 session."
echo "Memorise your passphrase as this can not be recovered. Leave blank for no passphrase"

ssh-keygen -q -a 64 -b 4096 -t ed25519 -C $SSH_EMAIL -f ~/.ssh/github_ed25519

PUBKEY=`cat ~/.ssh/github_ed25519.pub`
TITLE=`hostname`-autogen
RESPONSE=`curl -s -H "Authorization: token ${GIT_TOKEN}" \
  -X POST --data-binary "{\"title\":\"${TITLE}\",\"key\":\"${PUBKEY}\"}" \
  https://api.github.com/user/keys`
  
CURL_RESULT=$?
if test "$CURL_RESULT" != "0"; then
	echo -e"${RED_TEXT}curl command failed. Exit code: $CURL_RESULT. Script aborted."
	exit 1
fi
KEYID=`echo $RESPONSE \
  | grep -o '\"id.*' \
  | grep -o "[0-9]*" \
  | grep -m 1 "[0-9]*"`
echo -e "${BLUE_TEXT}SSH public key added succesfully to GitHub account. KeyID: $KEYID ${GREEN_TEXT}"

# Add key to ssh-agent, install keychain (manager for ssh-agent) and add startup to bash profile.
eval "$(ssh-agent -s)"
echo -e "${BLUE_TEXT}Adding ssh-key to ssh-agent.${GREEN_TEXT}" 
echo "Enter your secret passphrase to authenticate."
ssh-add ~/.ssh/github_ed25519
echo "Installing keychain..."
sudo apt install keychain -y
echo "Adding keychain to .profile for session autostart"
echo '/usr/bin/keychain --nogui $HOME/.ssh/github_ed25519' >> ~/.profile
echo 'source $HOME/.keychain/$HOSTNAME-sh' >> ~/.profile

# Install CloudFormation linter via Brew instead of pip
# pip3 install conflicts with AWS SAM, get following error
# ERROR: aws-sam-translator 1.36.0 has requirement six~=1.15, but you'll have six 1.14.0 which is incompatible.
echo -e "${BLUE_TEXT}Installing cfn-lint...${GREEN_TEXT}"
#pip3 install cfn-linter
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install cfn-lint

#Install Node.js
echo -e "${BLUE_TEXT}Installing Node.js...${GREEN_TEXT}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install node --lts
nvm use node --lts

#Install cfn-diagram
echo -e "${BLUE_TEXT}Installing cfn-diagram...${GREEN_TEXT}"
npm i -g @mhlabs/cfn-diagram

#Install AWS CDK
echo -e "${BLUE_TEXT}Installing AWS CDK...${GREEN_TEXT}"
npm -g install typescript
npm install -g aws-cdk

echo -e "${BLUE_TEXT}Install complete. Please exit and restart shell to complete changes.${GREEN_TEXT}"
exit 0


