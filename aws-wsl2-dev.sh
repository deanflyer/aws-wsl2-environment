#Add shell variables and input code here
#Do not publish publicly until credentials are removed!
AWS_DEFAULTACCESSKEYID="AKIAUGWSEOMXAUNKDL42"
AWS_DEFAULTSECRETACCESSKEY="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"
AWS_DEFAULTREGION="eu-west-2"
AWS_DEFAULTOUTPUTFORMAT="yaml"

#Update to latest version of WSL2
sudo apt update
sudo apt upgrade

#Install and configure AWS cli. Config file default location is ~/.aws/config
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
		AWS_DEFAULTREGION=$AWS_INPUT_VARIABLE
		echo "AWS default output has been changed to:" $AWS_DEFAULTREGION
fi

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws configure set aws_access_key_id $AWS_DEFAULTACCESSKEYID
aws configure set aws_secret_access_key $AWS_DEFAULTSECRETACCESSKEY
aws configure set default.region $AWS_DEFAULTREGION


#Install JSON command line parser utility
sudo apt install jq

#Install Python - Check if really need to use deadsnakes ppa
sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.8

#Install Package Installer for Python (PIP)
sudo apt install python3-pip

#Install Git
sudo apt install git
sudo pip3 install pre-commit #required??

#setup SSH for Git
ssh-keygen -t ed25519 -C your_email@example.com
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
sudo apt install keychain
/usr/bin/keychain --nogui $HOME/.ssh/id_ed25519
source $HOME/.keychain/$HOSTNAME-sh

#create code to deploy SSH key to github
See https://gist.github.com/petersellars/c6fff3657d53d053a15e57862fc6f567

#change remote URL to SSH
git remote set-url origin git@github.com:USERNAME/REPOSITORY.git

#show remote repositories
git remote -v

#Clone GitHub repository
git clone git@github.com:deanflyer/aws-wordpress.git

#Install CloudFormation linter
pip3 install cfn-linter

#Install Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

#Install cfn-diagram
npm i -g @mhlabs/cfn-diagram

#Install AWS CDK
npm -g install typescript
npm install -g aws-cdk

code --install-extensions kddejong.vscode-cfn-lint
code --install-extensions redhat.vscode-yaml

