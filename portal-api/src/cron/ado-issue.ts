import { logger } from "../utils/logger";

const ADO_ORG = process.env.ADO_ORG || "EasyWayData";
const ADO_PROJECT = process.env.ADO_PROJECT || "EasyWay-DataPortal";
const ADO_API_VERSION = "7.0";

/**
 * Create a work item (Bug) in Azure DevOps.
 * Requires AZURE_DEVOPS_EXT_PAT env var with Code R/W + Work Items Read & Write scope.
 */
export async function createAdoIssue(title: string, body: string): Promise<string | null> {
  const pat = process.env.AZURE_DEVOPS_EXT_PAT;
  if (!pat) {
    logger.warn("[ado-issue] AZURE_DEVOPS_EXT_PAT not set — skipping ADO issue creation");
    return null;
  }

  const b64 = Buffer.from(`:${pat}`).toString("base64");
  const url = `https://dev.azure.com/${encodeURIComponent(ADO_ORG)}/${encodeURIComponent(ADO_PROJECT)}/_apis/wit/workitems/$Bug?api-version=${ADO_API_VERSION}`;

  const payload = [
    { op: "add", path: "/fields/System.Title",       value: title },
    { op: "add", path: "/fields/System.Description", value: `<pre>${body}</pre>` },
    { op: "add", path: "/fields/System.Tags",        value: "autonomous-ops;cron" },
  ];

  try {
    const resp = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json-patch+json",
        "Authorization": `Basic ${b64}`,
      },
      body: JSON.stringify(payload),
    });

    if (!resp.ok) {
      const text = await resp.text();
      logger.error(`[ado-issue] ADO API error ${resp.status}: ${text.substring(0, 200)}`);
      return null;
    }

    const data: any = await resp.json();
    const issueId: string = data.id?.toString() ?? "?";
    logger.info(`[ado-issue] Created Bug #${issueId}: ${title}`);
    return issueId;
  } catch (err: any) {
    logger.error(`[ado-issue] Fetch failed: ${err.message}`);
    return null;
  }
}
