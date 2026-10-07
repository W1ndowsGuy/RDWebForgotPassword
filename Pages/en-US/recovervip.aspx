<%@ Page Language="C#" Debug="false" ResponseEncoding="utf-8" ContentType="text/html" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Xml.Linq" %>

<script runat="server">
    public string environmentName = "Work Resources";
    public string statusMessage = "";
    public bool validRecoveryState = false;

    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
        LoadConfiguration();

        if (!IsPostBack && Session["RDWebRecoveryCandidateSam"] != null)
        {
            DomainUserName.Value = Convert.ToString(Session["RDWebRecoveryCandidateSam"]);
            SymcUserName.Value = "DomainUserName=";
        }

        object expiry = Session["RDWebRecoveryCandidateExpires"];
        validRecoveryState =
            Session["RDWebRecoveryCandidateSam"] != null &&
            Session["RDWebRecoveryCandidateEmail"] != null &&
            expiry is DateTime &&
            DateTime.UtcNow <= (DateTime)expiry;

        if (!validRecoveryState)
        {
            Session.Remove("RDWebRecoveryCandidateSam");
            Session.Remove("RDWebRecoveryCandidateEmail");
            Session.Remove("RDWebRecoveryCandidateExpires");
            statusMessage = "Your password recovery request has expired. Please start again.";
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
            if (env != null && !String.IsNullOrWhiteSpace(env.Value))
                environmentName = env.Value.Trim();
        }
        catch { }
    }
</script>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>VIP Verification</title>
<link href="../css/bootstrap-5.3.8.min.css" rel="stylesheet" />
<style>
html,body{min-height:100%}body{min-height:100vh;background:url('../images/EngOne.jpg') center/cover fixed no-repeat}
.page-wrap{min-height:100vh;display:flex;align-items:center}.recovery-shell{background:rgba(255,255,255,.30);backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);border:1px solid rgba(255,255,255,.58);border-radius:1.25rem;box-shadow:0 .75rem 2rem rgba(0,0,0,.18);overflow:hidden}
.brand{color:#fff;text-align:center;padding:2.5rem;text-shadow:0 1px 3px rgba(0,0,0,.35);display:flex;flex-direction:column;justify-content:center;align-items:center;min-height:460px}.brand img{width:300px;max-width:75%}
.recovery-side{border-left:1px solid rgba(255,255,255,.45);display:flex;align-items:center;padding:2rem;color:#fff;text-shadow:0 1px 3px rgba(0,0,0,.35)}.recovery-panel{padding:1rem 2rem;max-width:520px;width:100%;margin:auto}.recovery-panel .form-control{background:rgba(255,255,255,.90);border:1px solid rgba(255,255,255,.75)}
@media(max-width:991.98px){.brand{min-height:auto;padding:2rem}.recovery-side{border-left:0;border-top:1px solid rgba(255,255,255,.45)}}
</style>
</head>
<body>
<div class="container page-wrap py-5"><div class="row g-0 align-items-stretch w-100 recovery-shell">
<div class="col-lg-6 brand"><div class="h2 mb-4"><%=HttpUtility.HtmlEncode(environmentName)%></div><img src="../images/crownCopyTransparentW.png" alt="Rural Payments Agency"/><div class="h2 mt-3">Rural Payments Agency</div></div>
<div class="col-lg-6 recovery-side"><div class="recovery-panel">
<h2 class="text-center mb-3">VIP Verification</h2>
<% if (!String.IsNullOrEmpty(statusMessage)) { %><div class="alert alert-warning"><%=HttpUtility.HtmlEncode(statusMessage)%></div><div class="text-center"><a class="text-white" href="recover.aspx">Start again</a></div>
<% } else { %>
<p>Verify your identity with your VIP Security Code to continue password recovery.</p>
<form id="FrmLogin" name="FrmLogin" method="post" action="recovervip.aspx" autocomplete="off">
<input type="hidden" id="DomainUserName" name="DomainUserName" runat="server" />
<input type="hidden" id="SymcUserName" value="DomainUserName=" runat="server" />
<div class="mb-3"><label class="form-label" for="SecurityCode">Security Code</label><input class="form-control form-control-lg" id="SecurityCode" name="securitycode" type="text" runat="server" inputmode="numeric" autocomplete="off" required /></div>
<button type="submit" class="btn btn-secondary btn-lg w-100">Verify Security Code</button>
</form>
<p class="small mt-3 mb-0">Test mode: this posts the validated recovery username and Security Code through the existing Symantec VIP IIS plugin. No AD password is supplied and no password reset or e-mail OTP is triggered yet.</p>
<% } %>
</div></div></div></div>
<script src="../js/bootstrap-5.3.8.bundle.min.js"></script>
</body></html>