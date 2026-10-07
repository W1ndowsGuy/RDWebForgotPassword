<%@ Page Language="C#" Debug="false" ResponseEncoding="utf-8" ContentType="text/html" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Xml.Linq" %>

<script runat="server">
public string environmentName = "Work Resources";
public string statusMessage = "";
public bool verified = false;

protected void Page_Load(object sender, EventArgs e)
{
    Response.Cache.SetCacheability(HttpCacheability.NoCache);
    LoadConfiguration();

    object candidateExpiry = Session["RDWebRecoveryCandidateExpires"];
    bool validState =
        Session["RDWebRecoveryVipVerified"] is bool && (bool)Session["RDWebRecoveryVipVerified"] &&
        Session["RDWebRecoveryCandidateSam"] != null &&
        Session["RDWebRecoveryCandidateEmail"] != null &&
        candidateExpiry is DateTime && DateTime.UtcNow <= (DateTime)candidateExpiry;

    if (!validState)
    {
        statusMessage = "Your password recovery request has expired. Please start again.";
        return;
    }

    if (String.Equals(Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase)) VerifyCode();
}

private void VerifyCode()
{
    try
    {
        string supplied = (Request.Form["verificationCode"] ?? "").Trim();
        string expected = Session["RDWebPasswordResetEmailCode"] as string;
        object expiry = Session["RDWebPasswordResetEmailCodeExpires"];
        int attempts = Session["RDWebPasswordResetEmailAttempts"] is int ? (int)Session["RDWebPasswordResetEmailAttempts"] : 0;

        if (String.IsNullOrEmpty(expected) || !(expiry is DateTime))
            throw new Exception("The verification request is no longer valid.");
        if (DateTime.UtcNow > (DateTime)expiry)
            throw new Exception("The verification code has expired.");
        if (attempts >= 5)
            throw new Exception("Too many incorrect attempts. Please start again.");

        if (!String.Equals(supplied, expected, StringComparison.Ordinal))
        {
            Session["RDWebPasswordResetEmailAttempts"] = attempts + 1;
            throw new Exception("The verification code is incorrect.");
        }

        Session.Remove("RDWebPasswordResetEmailCode");
        Session.Remove("RDWebPasswordResetEmailCodeExpires");
        Session.Remove("RDWebPasswordResetEmailAttempts");
        Session["RDWebRecoveryEmailOtpVerified"] = true;
        verified = true;
        statusMessage = "Recovery E-Mail verified. Identity checks are complete.";
    }
    catch (Exception ex)
    {
        statusMessage = ex.Message;
    }
}

private void LoadConfiguration()
{
    try
    {
        string path = Server.MapPath("../config/carousel.xml");
        if (!System.IO.File.Exists(path)) return;
        XDocument doc = XDocument.Load(path);
        XElement env = doc.Root.Element("environmentName");
        if (env != null && !String.IsNullOrWhiteSpace(env.Value)) environmentName = env.Value.Trim();
    }
    catch { }
}
</script>
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Recovery E-Mail Verification</title>
<link href="../css/bootstrap-5.3.8.min.css" rel="stylesheet" />
<style>
html,body{min-height:100%}body{min-height:100vh;background:url('../images/EngOne.jpg') center/cover fixed no-repeat}
.page-wrap{min-height:100vh;display:flex;align-items:center}.recovery-shell{background:rgba(255,255,255,.30);backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);border:1px solid rgba(255,255,255,.58);border-radius:1.25rem;box-shadow:0 .75rem 2rem rgba(0,0,0,.18);overflow:hidden}
.brand{color:#fff;text-align:center;padding:2.5rem;text-shadow:0 1px 3px rgba(0,0,0,.35);display:flex;flex-direction:column;justify-content:center;align-items:center;min-height:460px}.brand img{width:300px;max-width:75%}
.recovery-side{border-left:1px solid rgba(255,255,255,.45);display:flex;align-items:center;padding:2rem;color:#fff;text-shadow:0 1px 3px rgba(0,0,0,.35)}.recovery-panel{padding:1rem 2rem;max-width:520px;width:100%;margin:auto}.recovery-panel .form-control{background:rgba(255,255,255,.90);border:1px solid rgba(255,255,255,.75)}
@media(max-width:991.98px){.brand{min-height:auto;padding:2rem}.recovery-side{border-left:0;border-top:1px solid rgba(255,255,255,.45)}}
</style></head><body>
<div class="container page-wrap py-5"><div class="row g-0 align-items-stretch w-100 recovery-shell">
<div class="col-lg-6 brand"><div class="h2 mb-4"><%=HttpUtility.HtmlEncode(environmentName)%></div><img src="../images/crownCopyTransparentW.png" alt="Rural Payments Agency"/><div class="h2 mt-3">Rural Payments Agency</div></div>
<div class="col-lg-6 recovery-side"><div class="recovery-panel">
<h2 class="text-center mb-3">Recovery E-Mail Verification</h2>
<% if (!String.IsNullOrEmpty(statusMessage)) { %><div class="alert <%=verified ? "alert-success" : "alert-warning"%>"><%=HttpUtility.HtmlEncode(statusMessage)%></div><% } %>
<% if (verified) { %>
<p>Username, registered Recovery E-Mail, Symantec VIP and E-Mail OTP have now been verified.</p>
<p class="small mb-0">Password reset is not enabled yet. This test stops here intentionally.</p>
<% } else if (Session["RDWebRecoveryVipVerified"] is bool && (bool)Session["RDWebRecoveryVipVerified"]) { %>
<p>A 6-digit verification code has been sent to your registered Recovery E-Mail.</p>
<form method="post" action="recoveremail.aspx" autocomplete="off">
<div class="mb-3"><label class="form-label" for="verificationCode">Verification Code</label><input class="form-control form-control-lg" id="verificationCode" name="verificationCode" type="text" inputmode="numeric" pattern="[0-9]{6}" maxlength="6" autocomplete="one-time-code" required /></div>
<button type="submit" class="btn btn-secondary btn-lg w-100">Verify E-Mail Code</button>
</form>
<% } else { %><div class="text-center"><a class="text-white" href="recover.aspx">Start again</a></div><% } %>
</div></div></div></div>
<script src="../js/bootstrap-5.3.8.bundle.min.js"></script>
</body></html>