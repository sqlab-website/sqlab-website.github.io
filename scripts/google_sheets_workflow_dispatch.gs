const GITHUB_OWNER = "sqlab-website";
const GITHUB_REPO = "sqlab-website.github.io";
const GITHUB_WORKFLOW = "pages.yml";
const GITHUB_REF = "main";
const DISPATCH_DELAY_MINUTES = 2;
const MIN_INTERVAL_MINUTES = 5;
const DELAYED_DISPATCH_HANDLER = "runScheduledWebsiteWorkflowDispatch";

function onSheetEdit(e) {
  scheduleWebsiteWorkflowDispatch_("sheet edit");
}

function onSheetChange(e) {
  scheduleWebsiteWorkflowDispatch_("sheet change");
}

function testWebsiteWorkflowDispatch() {
  dispatchWebsiteWorkflow_("manual test", true);
}

function runScheduledWebsiteWorkflowDispatch() {
  const properties = PropertiesService.getScriptProperties();
  const reason = properties.getProperty("PENDING_DISPATCH_REASON") || "scheduled sheet update";

  deleteDelayedDispatchTriggers_();
  properties.deleteProperty("PENDING_DISPATCH_REASON");
  properties.deleteProperty("PENDING_DISPATCH_MS");

  dispatchWebsiteWorkflow_(reason);
}

function scheduleWebsiteWorkflowDispatch_(reason) {
  const lock = LockService.getScriptLock();
  lock.waitLock(10000);

  try {
    const properties = PropertiesService.getScriptProperties();
    properties.setProperty("PENDING_DISPATCH_REASON", reason);
    properties.setProperty("PENDING_DISPATCH_MS", String(Date.now()));

    deleteDelayedDispatchTriggers_();
    ScriptApp.newTrigger(DELAYED_DISPATCH_HANDLER)
      .timeBased()
      .after(DISPATCH_DELAY_MINUTES * 60 * 1000)
      .create();

    console.log(`Scheduled website workflow dispatch in ${DISPATCH_DELAY_MINUTES} minutes: ${reason}`);
  } finally {
    lock.releaseLock();
  }
}

function deleteDelayedDispatchTriggers_() {
  ScriptApp.getProjectTriggers().forEach((trigger) => {
    if (trigger.getHandlerFunction() === DELAYED_DISPATCH_HANDLER) {
      ScriptApp.deleteTrigger(trigger);
    }
  });
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
