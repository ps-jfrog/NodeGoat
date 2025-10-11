export JF_HOST="psazuse.jfrog.io"  JFROG_CLI_LOG_LEVEL="DEBUG" RT_REPO="cg-lab-npm" # "curation-blocked-npm-virtual"  # "curation-blocked-npm-remote" # "curation-blocked-npm-local"

# Curation Policy Name: cg-lab-npm

export JF_RT_URL="https://${JF_HOST}" BUILD_NAME="nodegoat" BUILD_ID="cmd.$(date '+%Y-%m-%d-%H-%M')" 

echo " JF_RT_URL: $JF_RT_URL \n JFROG_CLI_LOG_LEVEL: $JFROG_CLI_LOG_LEVEL \n "
echo " BUILD_NAME: $BUILD_NAME \n BUILD_ID: $BUILD_ID \n RT_REPO: $RT_REPO"

rm -rf node_modules package-lock.json
echo "NPM ver $(npm -v)"
echo "Node ver $(node -v) \n\n"

jf npmc --repo-resolve=${RT_REPO} --repo-deploy=${RT_REPO}

jf ca --format=table --threads=100 

CURL_URL="${JF_RT_URL}/xray/ui/curation/waiver_requests?pkg_type=PyPI&status=pending&num_of_rows=10"
RESP_JSON="WAIVER_PENDING_RESP-${BUILD_ID}.json"

WAIVER_PENDING_RESP=$(curl "${CURL_URL}" -H "Authorization: Bearer ${JF_ACCESS_TOKEN}")
echo $WAIVER_PENDING_RESP > ${RESP_JSON}

# items=$(echo "$WAIVER_PENDING_RESP" | jq -c -r '.data[]')

echo " | Waiver ID | Package Name | Package version | "
echo " | :--- | :--- | :--- | "

JSON_FILE="${RESP_JSON}"
jq -c '.data[] | {id, pkg_name, pkg_version}' "$JSON_FILE" | while read -r item; do
    waiver_id=$(echo "$item" | jq -r '.id')
    pkg_name=$(echo "$item" | jq -r '.pkg_name')
    pkg_version=$(echo "$item" | jq -r '.pkg_version')

    echo " | ${waiver_id} | ${pkg_name} | ${pkg_version} | "
done
rm -rf WAIVER_PENDING_RESP-*.json

# jf npm install --build-name=$BUILD_NAME --build-number=$BUILD_ID