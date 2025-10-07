export JF_HOST="psazuse.jfrog.io"  JFROG_CLI_LOG_LEVEL="DEBUG" RT_REPO="curation-blocked-npm-virtual"  # "curation-blocked-npm-remote" # "curation-blocked-npm-local"

# Curation Policy Name: Curation-blocked-remote

export JF_RT_URL="https://${JF_HOST}" BUILD_NAME="nodegoat" BUILD_ID="cmd.$(date '+%Y-%m-%d-%H-%M')" 

echo " JF_RT_URL: $JF_RT_URL \n JFROG_CLI_LOG_LEVEL: $JFROG_CLI_LOG_LEVEL \n "
echo " BUILD_NAME: $BUILD_NAME \n BUILD_ID: $BUILD_ID \n RT_REPO: $RT_REPO"

rm -rf node_modules package-lock.json
echo "NPM ver $(npm -v)"
echo "Node ver $(node -v) \n\n"

jf npmc --repo-resolve=${RT_REPO} --repo-deploy=${RT_REPO}

jf ca --format=table --threads=100 

jf npm install --build-name=$BUILD_NAME --build-number=$BUILD_ID