<%@ Page Language="C#" Debug="false" ResponseEncoding="utf-8" ContentType="text/html" Async="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Specialized" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Net.NetworkInformation" %>
<%@ Import Namespace="System.Security" %>
<%@ Import Namespace="System.Threading.Tasks" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="Microsoft.TerminalServices.Publishing.Portal" %>
<%@ Import Namespace="Microsoft.TerminalServices.Publishing.Portal.FormAuthentication" %>
<%@ Import Namespace="System.Web.Security.AntiXss" %>

<script runat="server">
    public string CompanyName = "Work Resources";
    public string EnvironmentName = "";
    public string ReturnUrl = "";
    public string WorkSpaceID = "";
    public string RDPCertificates = "";
    public string RedirectorName = "";
    public string ClaimsHint = "";
    public string EventLogUploadAddress = "";
    public string PrivateModeTimeout = "240";
    public string PublicModeTimeout = "20";

    protected void Page_PreInit(object sender, EventArgs e)
    {
        if (Request.PathInfo.Length != 0)
        {
            Response.StatusCode = 404;
            Response.End();
            return;
        }

        string domain = IPGlobalProperties.GetIPGlobalProperties().DomainName ?? "";
        if (domain.EndsWith(".local", StringComparison.OrdinalIgnoreCase))
            domain = domain.Substring(0, domain.Length - 6);

        if (!String.IsNullOrEmpty(domain))
        {
            EnvironmentName = Char.ToUpper(domain[0]) + domain.Substring(1);
            if (!EnvironmentName.StartsWith("Chs-", StringComparison.OrdinalIgnoreCase))
                EnvironmentName = "CHS-" + EnvironmentName;
        }

        string privateTimeout = ConfigurationManager.AppSettings["PrivateModeSessionTimeoutInMinutes"];
        string publicTimeout = ConfigurationManager.AppSettings["PublicModeSessionTimeoutInMinutes"];
        if (!String.IsNullOrEmpty(privateTimeout)) PrivateModeTimeout = privateTimeout;
        if (!String.IsNullOrEmpty(publicTimeout)) PublicModeTimeout = publicTimeout;
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        RegisterAsyncTask(new PageAsyncTask(LoadLoginAsync));
        ExecuteRegisteredAsyncTasks();
    }

    private async Task LoadLoginAsync()
    {
        string returnPage = Request.QueryString["ReturnUrl"];
        if (!String.IsNullOrEmpty(returnPage))
            ReturnUrl = "?ReturnUrl=" + AntiXssEncoder.UrlEncode(returnPage);

        if (HttpContext.Current.User.Identity.IsAuthenticated)
        {
            SafeRedirect(returnPage);
            return;
        }

        // The registered RDWAFormsAuthenticationModule processes the credentials
        // before this page executes. If a POST reaches the page unauthenticated,
        // authentication failed and we simply render the form again.

        WorkspaceInfo info = PageContentsHelper.GetWorkspaceInfo();
        if (info != null)
        {
            WorkSpaceID = info.WorkspaceId;
            RedirectorName = info.RedirectorName;
            if (!String.IsNullOrEmpty(info.WorkspaceName)) CompanyName = info.WorkspaceName;
            if (!String.IsNullOrEmpty(info.EventLogUploadAddress)) EventLogUploadAddress = info.EventLogUploadAddress;
        }

        RDPCertificates = PageContentsHelper.GetRdpSigningCertificateHash();
        ClaimsHint = PageContentsHelper.GetClaimsHint();
        await PageContentsHelper.GetPrivacyLinkAsync();

        Response.Cache.SetCacheability(HttpCacheability.NoCache);
    }

    private void SafeRedirect(string target)
    {
        string safe = null;
        if (!String.IsNullOrEmpty(target))
        {
            Uri original = RequestHelper.GetOriginalRequestUri(Request);
            Uri candidate = new Uri(new Uri(original, RequestHelper.GetRequestFilePath(Request)), target);
            if (candidate.Authority.Equals(original.Authority) && candidate.Scheme.Equals(original.Scheme))
                safe = candidate.AbsoluteUri;
        }
        Response.Redirect(safe ?? "Modern.aspx");
    }
</script>

<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title><%= HttpUtility.HtmlEncode(CompanyName) %> - Sign in</title>
    <link href="../css/bootstrap.min.css" rel="stylesheet" />
    <style>
        html,body { min-height:100%; }
        body {
            min-height:100vh;
            background:
                linear-gradient(rgba(0,0,0,.18),rgba(0,0,0,.18)),
                url('../images/EngOne.jpg') center center/cover fixed no-repeat;
        }
        .page-wrap { min-height:100vh; display:flex; align-items:center; }
        .brand-panel { color:#fff; text-align:center; text-shadow:0 1px 3px rgba(0,0,0,.35); }
        .brand-panel img { width:min(300px,75%); height:auto; }
        .login-panel {
            background:rgba(255,255,255,.88);
            backdrop-filter:blur(6px);
            border-radius:1rem;
            padding:2rem;
            box-shadow:0 .5rem 2rem rgba(0,0,0,.18);
        }
        .form-control { background:rgba(255,255,255,.72); }
    </style>
</head>
<body>
<div class="container page-wrap py-5">
    <div class="row g-5 align-items-center w-100">
        <div class="col-lg-6 brand-panel">
            <div class="h2 mb-4"><%= HttpUtility.HtmlEncode(EnvironmentName) %></div>
            <img src="../images/crownCopyTransparentW.png" alt="Rural Payments Agency" />
            <div class="h2 mt-3">Rural Payments Agency</div>
        </div>

        <div class="col-lg-6">
            <div class="login-panel mx-auto" style="max-width:520px">
                <h1 class="h2 text-center mb-4">Login</h1>

                <form autocomplete="off" id="FrmLogin" name="FrmLogin"
                      action="modernlogin.aspx<%= SecurityElement.Escape(ReturnUrl) %>" method="post"
                      onsubmit="return validateLogin();">

                    <input type="hidden" name="WorkSpaceID" value="<%= SecurityElement.Escape(WorkSpaceID) %>" />
                    <input type="hidden" name="RDPCertificates" value="<%= SecurityElement.Escape(RDPCertificates) %>" />
                    <input type="hidden" name="PublicModeTimeout" value="<%= SecurityElement.Escape(PublicModeTimeout) %>" />
                    <input type="hidden" name="PrivateModeTimeout" value="<%= SecurityElement.Escape(PrivateModeTimeout) %>" />
                    <input type="hidden" name="WorkspaceFriendlyName" value="<%= AntiXssEncoder.UrlEncode(CompanyName) %>" />
                    <input type="hidden" name="EventLogUploadAddress" value="<%= SecurityElement.Escape(EventLogUploadAddress) %>" />
                    <input type="hidden" name="RedirectorName" value="<%= SecurityElement.Escape(RedirectorName) %>" />
                    <input type="hidden" name="ClaimsHint" value="<%= SecurityElement.Escape(ClaimsHint) %>" />
                    <input type="hidden" name="ClaimsToken" value="" />
                    <input type="hidden" name="isUtf8" value="1" />
                    <input type="hidden" name="flags" value="0" />
                    <input type="hidden" name="MachineType" value="private" />

                    <div id="loginError" class="alert alert-danger d-none" role="alert">
                        Enter a valid domain user name and password.
                    </div>

                    <div class="mb-3">
                        <label class="form-label" for="DomainUserName">Domain\user name:</label>
                        <input class="form-control form-control-lg" id="DomainUserName"
                               name="DomainUserName" type="text" autocomplete="username" />
                    </div>

                    <div class="mb-3">
                        <label class="form-label" for="UserPass">Password:</label>
                        <input class="form-control form-control-lg" id="UserPass"
                               name="UserPass" type="password" autocomplete="current-password" />
                    </div>

                    <div class="mb-4">
                        <label class="form-label" for="SecurityCode">Security Code</label>
                        <input class="form-control form-control-lg" id="SecurityCode"
                               name="securitycode" type="text" inputmode="numeric" autocomplete="one-time-code" />
                    </div>

                    <input type="hidden" id="SymcUserName" name="SymcUserName" value="DomainUserName=" />

                    <div class="d-grid gap-2 d-sm-flex justify-content-sm-center">
                        <button type="submit" class="btn btn-secondary btn-lg px-4">Sign in</button>
                        <a class="btn btn-outline-secondary btn-lg px-4" href="rap-help.htm">Help</a>
                    </div>
                </form>

                <hr class="my-4" />
                <p class="small text-muted mb-0 text-center">
                    To protect against unauthorized access, your RD Web Access session will automatically time out after a period of inactivity.
                </p>
            </div>
        </div>
    </div>
</div>

<script>
function validateLogin() {
    var user = document.getElementById("DomainUserName").value;
    var pass = document.getElementById("UserPass").value;
    var validDomain = user.indexOf("\\") > 0 || user.indexOf("@") > 0;
    var ok = user.length > 0 && pass.length > 0 && validDomain;
    document.getElementById("loginError").classList.toggle("d-none", ok);
    return ok;
}
document.getElementById("DomainUserName").focus();
</script>
</body>
</html>
