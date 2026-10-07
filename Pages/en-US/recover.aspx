<%@ Page Language="C#" Debug="false" ResponseEncoding="utf-8" ContentType="text/html" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.DirectoryServices" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Xml.Linq" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Web" %>

<script runat="server">
    public string statusMessage = "";
    public string environmentName = "Work Resources";
    public string carouselColour = "#2d1450";
    public bool recoveryEnabled = false;
    public bool identityMatched = false;

    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
        LoadConfiguration();

        if (!recoveryEnabled)
        {
            statusMessage = "Password recovery is not currently available. Please contact your administrator.";
            return;
        }

        // Always start a fresh recovery attempt on a normal GET.
        // Recovery state must not survive returning to this page from an earlier test.
        if (Request.HttpMethod != "POST")
        {
            Session.Remove("RDWebRecoveryCandidateSam");
            Session.Remove("RDWebRecoveryCandidateEmail");
            Session.Remove("RDWebRecoveryCandidateExpires");
            identityMatched = false;
        }
        else
        {
            ValidateRegisteredRecoveryEmail();
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

            XElement colour = doc.Root.Element("colour");
            if (colour != null && !String.IsNullOrWhiteSpace(colour.Value))
                carouselColour = colour.Value.Trim();

            XElement recovery = doc.Root.Element("passwordRecovery");
            bool enabled;
            XElement e = recovery == null ? null : recovery.Element("enabled");
            if (e != null && Boolean.TryParse(e.Value, out enabled))
                recoveryEnabled = enabled;
        }
        catch { }
    }

    private static string EscapeLdap(string value)
    {
        return (value ?? "").Replace("\\", "\\5c").Replace("*", "\\2a")
            .Replace("(", "\\28").Replace(")", "\\29").Replace("\0", "\\00");
    }

    private void ValidateRegisteredRecoveryEmail()
    {
        // Deliberately return the same response for unknown users and mismatched addresses.
        const string genericResponse =
            "If the details match a registered Recovery E-Mail, you can continue with password recovery.";

        string username = (Request.Form["username"] ?? "").Trim();
        string email = (Request.Form["recoveryEmail"] ?? "").Trim();

        if (username.Length < 1 || username.Length > 256 || email.Length < 3 || email.Length > 254)
        {
            statusMessage = genericResponse;
            return;
        }

        try
        {
            string sam = username;
            int slash = sam.LastIndexOf('\\');
            if (slash >= 0 && slash < sam.Length - 1) sam = sam.Substring(slash + 1);
            int at = sam.IndexOf('@');
            if (at > 0) sam = sam.Substring(0, at);

            using (DirectoryEntry root = new DirectoryEntry("LDAP://RootDSE"))
            {
                string defaultNamingContext = Convert.ToString(root.Properties["defaultNamingContext"].Value);
                using (DirectoryEntry searchRoot = new DirectoryEntry("LDAP://" + defaultNamingContext))
                using (DirectorySearcher searcher = new DirectorySearcher(searchRoot))
                {
                    searcher.Filter = "(&(objectCategory=person)(objectClass=user)(sAMAccountName=" + EscapeLdap(sam) + "))";
                    searcher.SearchScope = SearchScope.Subtree;
                    searcher.PropertiesToLoad.Add("mail");
                    searcher.PropertiesToLoad.Add("adminCount");
                    SearchResult result = searcher.FindOne();

                    bool matched = result != null &&
                        result.Properties.Contains("mail") &&
                        result.Properties["mail"].Count > 0 &&
                        String.Equals(Convert.ToString(result.Properties["mail"][0]).Trim(),
                                      email, StringComparison.OrdinalIgnoreCase);

                    if (matched)
                    {
                        bool privilegedAccount =
                            result.Properties.Contains("adminCount") &&
                            result.Properties["adminCount"].Count > 0 &&
                            Convert.ToString(result.Properties["adminCount"][0]) == "1";

                        if (privilegedAccount)
                        {
                            Session.Remove("RDWebRecoveryCandidateSam");
                            Session.Remove("RDWebRecoveryCandidateEmail");
                            Session.Remove("RDWebRecoveryCandidateExpires");
                            statusMessage = "Password recovery cannot proceed for this privileged account. Please contact an administrator.";
                            return;
                        }

                        Session["RDWebRecoveryCandidateSam"] = sam;
                        Session["RDWebRecoveryCandidateEmail"] = email;
                        Session["RDWebRecoveryCandidateExpires"] = DateTime.UtcNow.AddMinutes(10);
                        // Hand off to the dedicated URL protected by the existing Symantec VIP IIS plugin.
                        Response.Redirect("recovervip.aspx", false);
                        Context.ApplicationInstance.CompleteRequest();
                        return;
                    }
                    else
                    {
                        Session.Remove("RDWebRecoveryCandidateSam");
                        Session.Remove("RDWebRecoveryCandidateEmail");
                        Session.Remove("RDWebRecoveryCandidateExpires");
                    }
                }
            }
        }
        catch
        {
            Session.Remove("RDWebRecoveryCandidateSam");
            Session.Remove("RDWebRecoveryCandidateEmail");
            Session.Remove("RDWebRecoveryCandidateExpires");
        }

        statusMessage = genericResponse;
    }
</script>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Password Recovery</title>
<link href="../css/bootstrap-5.3.8.min.css" rel="stylesheet" />
<style>
html,body{min-height:100%}
body{min-height:100vh;background:url('../images/EngOne.jpg') center/cover fixed no-repeat}
.page-wrap{min-height:100vh;display:flex;align-items:center}
.recovery-shell{background:rgba(255,255,255,.30);backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);border:1px solid rgba(255,255,255,.58);border-radius:1.25rem;box-shadow:0 .75rem 2rem rgba(0,0,0,.18);overflow:hidden}
.brand{color:#fff;text-align:center;padding:2.5rem;text-shadow:0 1px 3px rgba(0,0,0,.35);display:flex;flex-direction:column;justify-content:center;align-items:center;min-height:460px}
.brand img{width:300px;max-width:75%}
.recovery-side{border-left:1px solid rgba(255,255,255,.45);display:flex;align-items:center;padding:2rem;color:#fff;text-shadow:0 1px 3px rgba(0,0,0,.35)}
.recovery-panel{padding:1rem 2rem;max-width:520px;width:100%;margin:auto}
.recovery-panel .form-control{background:rgba(255,255,255,.90);border:1px solid rgba(255,255,255,.75)}
.recovery-panel label,.recovery-panel p,.recovery-panel h2{color:#fff}
@media(max-width:991.98px){.brand{min-height:auto;padding:2rem}.recovery-side{border-left:0;border-top:1px solid rgba(255,255,255,.45)}}
</style>
</head>
<body>
<div class="container page-wrap py-5">
<div class="row g-0 align-items-stretch w-100 recovery-shell">
<div class="col-lg-6 brand">
<div class="h2 mb-4"><%=HttpUtility.HtmlEncode(environmentName)%></div>
<img src="../images/crownCopyTransparentW.png" alt="Rural Payments Agency"/>
<div class="h2 mt-3">Rural Payments Agency</div>
</div>
<div class="col-lg-6 recovery-side"><div class="recovery-panel">
<h2 class="text-center mb-3">Forgotten or Expired Password</h2>
<p class="small">Enter your username and the Recovery E-Mail already registered against your account.</p>
<% if (!String.IsNullOrEmpty(statusMessage)) { %>
<div class="alert alert-info"><%=HttpUtility.HtmlEncode(statusMessage)%></div>
<% } %>
<% if (recoveryEnabled) { %>
<form method="post" action="recover.aspx" autocomplete="off">
<div class="mb-3"><label class="form-label" for="username">Username</label><input class="form-control form-control-lg" id="username" name="username" autocomplete="off" required maxlength="256"/></div>
<div class="mb-4"><label class="form-label" for="recoveryEmail">Recovery E-Mail</label><input class="form-control form-control-lg" type="email" id="recoveryEmail" name="recoveryEmail" autocomplete="off" required maxlength="254"/></div>
<button type="submit" class="btn btn-secondary btn-lg w-100">Continue</button>
</form>
<% } %><div class="text-center mt-3"><a class="small text-white" href="login.aspx">Back to login</a></div>
</div></div>
</div>
</div>
<script src="../js/bootstrap-5.3.8.bundle.min.js"></script>
</body>
</html>
