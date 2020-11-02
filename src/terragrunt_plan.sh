#!/bin/bash

function terragruntPlan {
  # Gather the output of `terragrunt plan`.
  echo "plan: info: planning Terragrunt configuration in ${tfWorkingDir}"
  planOutput=$(${tfBinary} plan-all -input=false ${*} 2>&1)
  planExitCode=${?}
  planCommentStatus="Failed"

  # Exit code of !0 indicates failure.
  if [ ${planExitCode} -ne 0 ]; then
    echo "plan: error: failed to plan Terragrunt configuration in ${tfWorkingDir}"
    echo "${planOutput}"
    echo
  fi

  planCommentWrapper="#### \`${tfBinary} plan\` ${planCommentStatus}
  <details><summary>Show Output</summary>

  \`\`\`
  ${planOutput}
  \`\`\`

  </details>

  *Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Working Directory: \`${tfWorkingDir}\`, Workspace: \`${tfWorkspace}\`*"

  planCommentWrapper=$(stripColors "${planCommentWrapper}")
  echo "plan: info: creating JSON"
  planPayload=$(echo "${planCommentWrapper}" | jq -R --slurp '{body: .}')
  planCommentsURL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
  echo "plan: info: commenting on the pull request"
  echo "${planPayload}" | curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data @- "${planCommentsURL}" > /dev/null

  echo ::set-output name=tf_actions_plan_has_changes::${planHasChanges}

  # https://github.community/t5/GitHub-Actions/set-output-Truncates-Multiline-Strings/m-p/38372/highlight/true#M3322
  planOutput="${planOutput//'%'/'%25'}"
  planOutput="${planOutput//$'\n'/'%0A'}"
  planOutput="${planOutput//$'\r'/'%0D'}"

  echo "::set-output name=tf_actions_plan_output::${planOutput}"
  exit ${planExitCode}
}