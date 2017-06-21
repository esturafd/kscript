## Release Checklist

# 1. Increment version in `kscript`
# 2. Make sure that support api version is up to date and available from jcenter
# 3. Push and create github release tag

export KSCRIPT_HOME="/Users/brandl/projects/kotlin/kscript";
export PATH=${KSCRIPT_HOME}:${PATH}
export PATH=~/go/bin/:$PATH

KSCRIPT_ARCHIVE=~/Dropbox/archive/kscript_versions/


kscript_version=$(grep '^KSCRIPT_VERSION' ${KSCRIPT_HOME}/kscript | cut -f2 -d'=')
echo "new version is $kscript_version" 
## see https://github.com/aktau/github-release


########################################################################
### Build the binary release


## create and upload deployment file for sdkman

mkdir -p $KSCRIPT_ARCHIVE/kscript-${kscript_version}/bin
cp ${KSCRIPT_HOME}/kscript ${KSCRIPT_ARCHIVE}/kscript-${kscript_version}/bin

cd ${KSCRIPT_ARCHIVE}
zip  -r ${KSCRIPT_ARCHIVE}/kscript-${kscript_version}.zip kscript-${kscript_version}
open ${KSCRIPT_ARCHIVE}


########################################################################
### Do the github release

## create tag on github 
#github-release --help

source /Users/brandl/Dropbox/archive/gh_token.sh
export GITHUB_TOKEN=${GH_TOKEN}
#echo $GITHUB_TOKEN

# make your tag and upload
cd ${KSCRIPT_HOME}

#git tag v${kscript_version} && git push --tags
(git diff --exit-code && git tag v${kscript_version})  || echo "could not tag current branch"
git push --tags

# check the current tags and existing releases of the repo
github-release info -u holgerbrandl -r kscript

# create a formal release
github-release release \
    --user holgerbrandl \
    --repo kscript \
    --tag "v${kscript_version}" \
    --name "v${kscript_version}" \
    --description "See [NEWS.md](https://github.com/holgerbrandl/kscript/blob/master/NEWS.md) for changes." 
#    \
#    --pre-release


## upload sdk-man binary set
github-release upload \
    --user holgerbrandl \
    --repo kscript \
    --tag "v${kscript_version}" \
    --name "kscript-${kscript_version}-bin.zip" \
    --file ${KSCRIPT_ARCHIVE}/kscript-${kscript_version}.zip


########################################################################
### Update release branch

#http://stackoverflow.com/questions/13969050/how-to-create-a-new-empty-branch-for-a-new-project
git clone git@github.com:holgerbrandl/kscript.git kscript_releases
cd kscript_releases
#git checkout --orphan releases
#git reset --hard
#git rm --cached -r .

git checkout releases
#cp ~/projects/kotlin/kscript/resdeps.kts ~/projects/kotlin/kscript/kscript .
cp ~/projects/kotlin/kscript/kscript .
git add -A 
git status
git commit -m "v${kscript_version} release"

git push origin releases


########################################################################
### release on sdkman

## see docs http://sdkman.io/vendors.html
# Summary: sequence of calls is as above, first **releasing** , then making it **default** , and finally **announce** it to the world.

## from .bash_profile
source /Users/brandl/Dropbox/archive/kscript_sdkman_json.sh
echo ${SDKMAN_CONSUMER_KEY} ${SDKMAN_CONSUMER_TOKEN} ${kscript_version}
#echo ${SDKMAN_CONSUMER_KEY} | cut -c-5
#echo ${SDKMAN_CONSUMER_TOKEN} | cut -c-5


## test the binary download
#cd ~/Desktop
#wget https://github.com/holgerbrandl/kscript/releases/download/v${kscript_version}/kscript-${kscript_version}-bin.zip
#unzip kscript-${kscript_version}-bin.zip

#kscript_version=1.5.1

curl -X POST \
    -H "'Consumer-Key: ${SDKMAN_CONSUMER_KEY}" \
    -H "Consumer-Token: ${SDKMAN_CONSUMER_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"candidate": "kscript", "version": "'${kscript_version}'", "url": "https://github.com/holgerbrandl/kscript/releases/download/v'${kscript_version}'/kscript-'${kscript_version}'-bin.zip"}' \
    https://vendors.sdkman.io/release


## Set existing Version as Default for Candidate

curl -X PUT \
    -H "Consumer-Key: ${SDKMAN_CONSUMER_KEY}" \
    -H "Consumer-Token: ${SDKMAN_CONSUMER_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"candidate": "kscript", "version": "'${kscript_version}'"}' \
    https://vendors.sdkman.io/default

## Broadcast a Structured Message
curl -X POST \
    -H "Consumer-Key: ${SDKMAN_CONSUMER_KEY}" \
    -H "Consumer-Token: ${SDKMAN_CONSUMER_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"candidate": "kscript", "version": "'${kscript_version}'", "hashtag": "kscript"}' \
    https://vendors.sdkman.io/announce/struct
