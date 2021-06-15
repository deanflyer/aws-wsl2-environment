#setup SSH for Git
GIT_TOKEN="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"
ssh-keygen -q -b 4096 -t rsa -N "" -f ~/.ssh/github_rsa
PUBKEY=`cat ~/.ssh/github_rsa.pub`
TITLE=`hostname`

RESPONSE=`curl -s -H "Authorization: token ${GIT_TOKEN}" \
  -X POST --data-binary "{\"title\":\"${TITLE}\",\"key\":\"${PUBKEY}\"}" \
  https://api.github.com/user/keys`

echo "RESPONSE:"
echo $RESPONSE

KEYID=`echo $RESPONSE \
| grep -o '\"id.*' \
| grep -o "[0-9]*" \
| grep -m 1 "[0-9]*"`

echo "KEYID:"
echo $KEYID

