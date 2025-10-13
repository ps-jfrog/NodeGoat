export JF_HOST="psazuse.jfrog.io"  JFROG_CLI_LOG_LEVEL="DEBUG" RT_VIRTUAL="cg-lab-npm"  RT_REMOTE="cg-lab-npm-remote"

# Curation Policy Name: cg-lab-npm

export JF_RT_URL="https://${JF_HOST}" BUILD_NAME="nodegoat" BUILD_ID="cmd.$(date '+%Y-%m-%d-%H-%M')" 

echo " JF_RT_URL: $JF_RT_URL \n JFROG_CLI_LOG_LEVEL: $JFROG_CLI_LOG_LEVEL \n "
echo " BUILD_NAME: $BUILD_NAME \n BUILD_ID: $BUILD_ID \n RT_REPO: $RT_VIRTUAL"

rm -rf node_modules package-lock.json
echo "NPM ver $(npm -v)"
echo "Node ver $(node -v) \n\n"

jf npmc --repo-resolve=${RT_VIRTUAL} --repo-deploy=${RT_VIRTUAL}

jf ca --format=table --threads=100 

CURL_URL="${JF_RT_URL}/xray/ui/curation/waiver_requests?pkg_type=npm&status=pending&num_of_rows=10"
RESP_JSON="WAIVER_PENDING_RESP-${BUILD_ID}.json"

WAIVER_PENDING_RESP=$(curl "${CURL_URL}" -H "Authorization: Bearer ${JF_ACCESS_TOKEN}")
echo $WAIVER_PENDING_RESP > ${RESP_JSON}

# items=$(echo "$WAIVER_PENDING_RESP" | jq -c -r '.data[]')

echo " | Waiver ID | Package Name | Package version | Requested on | Justification | Decision Owners | "
echo " | :--- | :--- | :--- | :--- | :--- | :--- | "

JSON_FILE="${RESP_JSON}"
# jq -c '.data[] | {id, pkg_name, pkg_version}' "$JSON_FILE" | while read -r item; do

jq -c '.data[]' "$JSON_FILE" | while read -r item; do
  waiver_id=$(echo "$item" | jq -r '.id')
  repo_key=$(echo "$item" | jq -r '.repo_key')
  pkg_name=$(echo "$item" | jq -r '.pkg_name')
  pkg_version=$(echo "$item" | jq -r '.pkg_version')

  repo_match=$(echo "$item" | jq -r --arg repo "${RT_REMOTE}" '.policies[] | select(.repo_include | index($repo))')
  echo $repo_match
  if [[ -z "$repo_match" ]]; then
    continue  # skip this item if repo not included
  fi

  decision_owners=$(echo "$item" | jq -r '.decision_owners | join(", ")')

  latest_request=$(echo "$item" | jq -r '.requesters | sort_by(.requested_at) | last')
  requested_at=$(echo "$latest_request" | jq -r '.requested_at')
  justification=$(echo "$latest_request" | jq -r '.justification')

  # echo "REPO_REMOTE: ${RT_REPO_REMOTE}    repo_key: ${repo_key} "
  if [[ ("${RT_REMOTE}" == "${repo_key}") ]] ; then
    echo " |  ${waiver_id} | ${pkg_name} | ${pkg_version} | ${requested_at} | ${justification} | ${decision_owners} | "
  fi
done



  

  # Extract the most recent requester (sorted by requested_at)
  


rm -rf WAIVER_PENDING_RESP-*.json

# jf npm install --build-name=$BUILD_NAME --build-number=$BUILD_ID