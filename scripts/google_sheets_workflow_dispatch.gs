const GITHUB_OWNER = "sqlab-website";
const GITHUB_REPO = "sqlab-website.github.io";
const GITHUB_WORKFLOW = "pages.yml";
const GITHUB_REF = "main";
const MIN_INTERVAL_MINUTES = 5;

function onSheetEdit(e) {
  dispatchWebsiteWorkflow_("sheet edit");
}

function onSheetChange(e) {
  dispatchWebsiteWorkflow_("sheet change");
}

function testWebsiteWorkflowDispatch() {
  dispatchWebsiteWorkflow_("manual test", true);
}

function dispatchWebsiteWorkflow_(reason, force) {
  const properties = PropertiesService.getScriptProperties();
  const token = properties.getProperty("GITHUB_TOKEN");
  if (!token) {
    throw new Error("Set GITHUB_TOKEN in Apps Script project properties.");
  }

  const now = Date.now();
  const lastDispatch = Number(properties.getProperty("LAST_DISPATCH_MS") || "0");
  const minIntervalMs = MIN_INTERVAL_MINUTES * 60 * 1000;
  if (!force && now - lastDispatch < minIntervalMs) {
    console.log("Skipped dispatch because the previous dispatch was recent.");
    return;
  }

  const url = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/workflows/${GITHUB_WORKFLOW}/dispatches`;
  const response = UrlFetchApp.fetch(url, {
    method: "post",
    contentType: "application/json",
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28"
    },
    payload: JSON.stringify({
      ref: GITHUB_REF
    }),
    muteHttpExceptions: true
  });

  const status = response.getResponseCode();
  if (status < 200 || status >= 300) {
    throw new Error(`GitHub workflow dispatch failed: ${status} ${response.getContentText()}`);
  }

  properties.setProperty("LAST_DISPATCH_MS", String(now));
  console.log(`Dispatched website workflow: ${reason}`);
}
