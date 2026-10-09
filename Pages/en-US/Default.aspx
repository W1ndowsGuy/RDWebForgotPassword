<%@ Page Language="C#" Debug="false" ResponseEncoding="utf-8" ContentType="text/html" Async="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Specialized" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Security.Principal" %>
<%@ Import Namespace="System.Threading.Tasks" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Web.Configuration" %>
<%@ Import Namespace="System.Xml.Linq" %>
<%@ Import Namespace="System.DirectoryServices" %>
<%@ Import Namespace="System.DirectoryServices.ActiveDirectory" %>
<%@ Import Namespace="System.Net.Mail" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.Pipes" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="Microsoft.TerminalServices.Publishing.Portal" %>
<%@ Import Namespace="Microsoft.TerminalServices.Publishing.Portal.FormAuthentication" %>

<script runat="server">
    public Uri baseUrl;
    public AuthenticationMode authenticationMode = AuthenticationMode.None;
    public string domainUserName = "";
    public string userIdentity = "";
    public string workspaceName = "Work Resources";
    public string appFeed = "";
    public int sessionTimeoutMinutes = 20;
    public string displayName = "";
    public string passwordExpiration = "";
    public int passwordDaysRemaining = -1;
    public string logonHeader = "";
    public bool isWebAdmin = false;
    public string carouselColour = "#2d1450";
    public string carouselTitle1 = "Maintenence Outage";
    public string carouselText1 = "Notifications for outages will also be here in future";
    public string carouselTitle2 = "HELP";
    public string carouselText2 = "If you having any issues with login please click 'Help'";
    public string carouselTitle3 = "Security";
    public string carouselText3 = "Warning: By logging in to this web page, you confirm that this computer complies with your organization's security policy.";
    public int daysToAdd = 30;
    public bool passwordRecoveryEnabled = false;
    public string recoverySmtpServer = "";
    public int recoverySmtpPort = 25;
    public string recoveryFromAddress = "";
    public int recoveryCodeExpiryMinutes = 10;
    public string recoveryEmail = "";
    public bool recoveryEmailVerified = false;
    public string recoveryStatus = "";
    const int PasswordExpiryThreshold = 10;

    protected void Page_PreInit(object sender, EventArgs e)
    {
        RegisterAsyncTask(new PageAsyncTask(LoadResourcesAsync));
        ExecuteRegisteredAsyncTasks();
    }

    protected void Page_Init(object sender, EventArgs e)
    {
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
    }

    private async Task LoadResourcesAsync()
    {
        baseUrl = new Uri(new Uri(RequestHelper.GetOriginalRequestUri(Request),
            RequestHelper.GetRequestFilePath(Request)), ".");

        AuthenticationSection auth = ConfigurationManager.GetSection("system.web/authentication") as AuthenticationSection;
        if (auth != null)
            authenticationMode = auth.Mode;

        if (authenticationMode == AuthenticationMode.Forms)
        {
            if (!HttpContext.Current.User.Identity.IsAuthenticated)
            {
                string returnUrl = RequestHelper.GetOriginalRequestUri(Request).AbsolutePath;
                Response.Redirect(new Uri(baseUrl,
                    "login.aspx?ReturnUrl=" + HttpUtility.UrlEncode(returnUrl)).AbsoluteUri, true);
                return;
            }

            TSFormAuthTicketInfo ticket = new TSFormAuthTicketInfo(HttpContext.Current);
            userIdentity = ticket.UserIdentity;
            domainUserName = ticket.DomainUserName;

            string timeoutKey = ticket.PrivateMode
                ? "PrivateModeSessionTimeoutInMinutes"
                : "PublicModeSessionTimeoutInMinutes";

            int parsedTimeout;
            if (Int32.TryParse(ConfigurationManager.AppSettings[timeoutKey], out parsedTimeout))
                sessionTimeoutMinutes = parsedTimeout;
        }
        else if (authenticationMode == AuthenticationMode.Windows)
        {
            WindowsIdentity identity = (WindowsIdentity)Context.User.Identity;
            userIdentity = identity.User.ToString();
            domainUserName = identity.Name;
        }

        // Load environment/runtime settings first so values such as
        // passwordExpiryDays are available before user expiry is calculated.
        LoadUserCustomizations();
        LoadCarouselConfiguration();
        LoadRecoveryEmail();
        if (Request.HttpMethod == "POST" && passwordRecoveryEnabled)
        {
            string recoveryAction = Request.Form["recoveryAction"] ?? "";
            if (recoveryAction == "send-code") SendRecoveryEmailVerificationCode();
            else if (recoveryAction == "verify-code") VerifyRecoveryEmailCode();
            else if (recoveryAction == "change-email") BeginRecoveryEmailChange();
        }
        isWebAdmin = IsMemberOfWebAdmins();

        try
        {
            WebFeed feed = new WebFeed(RdpType.Both, true);
            Tuple<string, int> result = await feed.GenerateFeedAsync(
                userIdentity,
                FeedXmlVersion.Win8,
                (Request.PathInfo.Length > 0) ? Request.PathInfo : "/",
                false);

            appFeed = result.Item1;

            WorkspaceInfo info = feed.GetFetchedWorkspaceInfo();
            if (info != null && !String.IsNullOrEmpty(info.WorkspaceName))
                workspaceName = info.WorkspaceName;
        }
        catch (WorkspaceUnknownFolderException)
        {
            Response.Redirect(Request.FilePath, true);
        }
        catch (InvalidTenantException)
        {
            Response.StatusCode = 404;
            Response.End();
        }
        catch (WorkspaceUnavailableException)
        {
            Response.StatusCode = 503;
            Response.End();
        }
    }

    private void LoadUserCustomizations()
    {
        try {
            string fqdn = Domain.GetCurrentDomain().Name;
            string ldapPath = "LDAP://" + fqdn;
            string shortDomain = fqdn.Split('.')[0].ToUpperInvariant();
            logonHeader = "You are logged on to " + shortDomain;
            string account = domainUserName;
            string username = account.Contains("@") ? account.Split('@')[0] : (account.Contains("\\") ? account.Split('\\')[1] : account);
            DirectoryEntry de = new DirectoryEntry(ldapPath);
            DirectorySearcher ds = new DirectorySearcher(de);
            ds.Filter = "(sAMAccountName=" + username + ")";
            ds.PropertiesToLoad.Add("Name"); ds.PropertiesToLoad.Add("pwdLastSet"); ds.PropertiesToLoad.Add("userAccountControl");
            SearchResult result = ds.FindOne();
            if (result != null) {
                if (result.Properties["Name"].Count > 0) displayName = result.Properties["Name"][0].ToString();
                long ticks, uac;
                if (result.Properties["pwdLastSet"].Count > 0 && result.Properties["userAccountControl"].Count > 0 &&
                    Int64.TryParse(result.Properties["pwdLastSet"][0].ToString(), out ticks) &&
                    Int64.TryParse(result.Properties["userAccountControl"][0].ToString(), out uac)) {
                    if ((uac & 0x10000) != 0) passwordExpiration = "Password does not expire.";
                    else {
                        int days = (int)Math.Ceiling((DateTime.FromFileTime(ticks).AddDays(daysToAdd) - DateTime.UtcNow).TotalDays);
                        passwordExpiration = days < PasswordExpiryThreshold ? "Password expires in " + days + " days. Click here to reset now." : "Password expires in " + days + " days.";
                    }
                }
            }
        } catch { }
        if (String.IsNullOrEmpty(displayName)) displayName = domainUserName;
    }

    private string GetSamAccountName()
    {
        string account = domainUserName ?? "";
        if (account.Contains("@")) return account.Split('@')[0];
        if (account.Contains("\\")) return account.Split('\\')[1];
        return account;
    }

    private bool IsMemberOfWebAdmins()
    {
        try
        {
            string fqdn = Domain.GetCurrentDomain().Name;
            using (DirectoryEntry root = new DirectoryEntry("LDAP://" + fqdn))
            using (DirectorySearcher ds = new DirectorySearcher(root))
            {
                ds.Filter = "(&(objectCategory=person)(objectClass=user)(sAMAccountName=" + GetSamAccountName().Replace("(", "\\28").Replace(")", "\\29") + "))";
                ds.PropertiesToLoad.Add("distinguishedName");
                SearchResult user = ds.FindOne();
                if (user == null || user.Properties["distinguishedName"].Count == 0) return false;
                string dn = user.Properties["distinguishedName"][0].ToString();
                using (DirectorySearcher gs = new DirectorySearcher(root))
                {
                    gs.Filter = "(&(objectCategory=group)(sAMAccountName=webadmins)(member:1.2.840.113556.1.4.1941:=" + dn.Replace("(", "\\28").Replace(")", "\\29") + "))";
                    return gs.FindOne() != null;
                }
            }
        }
        catch { return false; }
    }

    private void LoadCarouselConfiguration()
    {
        try
        {
            string path = Server.MapPath("../config/carousel.xml");
            if (!System.IO.File.Exists(path)) return;
            XDocument doc = XDocument.Load(path);
            XElement env = doc.Root.Element("environmentName");
            if (env != null && !String.IsNullOrWhiteSpace(env.Value)) logonHeader = "You are logged on to " + env.Value.Trim();
            XElement pwd = doc.Root.Element("passwordExpiryDays");
            int configuredDays;
            if (pwd != null && Int32.TryParse(pwd.Value, out configuredDays) && configuredDays > 0 && configuredDays <= 3650) daysToAdd = configuredDays;
            XElement recovery = doc.Root.Element("passwordRecovery");
            if (recovery != null)
            {
                bool enabled;
                XElement e = recovery.Element("enabled"); if (e != null && Boolean.TryParse(e.Value, out enabled)) passwordRecoveryEnabled = enabled;
                XElement smtp = recovery.Element("smtpServer"); if (smtp != null) recoverySmtpServer = smtp.Value.Trim();
                int port; XElement p = recovery.Element("smtpPort"); if (p != null && Int32.TryParse(p.Value, out port) && port > 0 && port <= 65535) recoverySmtpPort = port;
                XElement from = recovery.Element("fromAddress"); if (from != null) recoveryFromAddress = from.Value.Trim();
                int expiryMinutes; XElement expiry = recovery.Element("codeExpiryMinutes"); if (expiry != null && Int32.TryParse(expiry.Value, out expiryMinutes) && expiryMinutes >= 1 && expiryMinutes <= 60) recoveryCodeExpiryMinutes = expiryMinutes;
            }
            XElement colour = doc.Root.Element("colour");
            if (colour != null && !String.IsNullOrWhiteSpace(colour.Value))
                carouselColour = colour.Value.Trim();
            DateTime now = DateTime.Now;
            for (int i = 1; i <= 3; i++)
            {
                XElement slide = doc.Root.Elements("slide").FirstOrDefault(x => (string)x.Attribute("id") == i.ToString());
                if (slide == null) continue;
                DateTime expiry;
                string expires = (string)slide.Attribute("expires");
                bool active = String.IsNullOrWhiteSpace(expires) || (DateTime.TryParse(expires, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out expiry) && expiry > now);
                if (!active) continue;
                string title = (string)slide.Element("title");
                string text = (string)slide.Element("text");
                if (i == 1) { if (!String.IsNullOrEmpty(title)) carouselTitle1 = title; if (!String.IsNullOrEmpty(text)) carouselText1 = text; }
                if (i == 2) { if (!String.IsNullOrEmpty(title)) carouselTitle2 = title; if (!String.IsNullOrEmpty(text)) carouselText2 = text; }
                if (i == 3) { if (!String.IsNullOrEmpty(title)) carouselTitle3 = title; if (!String.IsNullOrEmpty(text)) carouselText3 = text; }
            }
        }
        catch { }
    }


    private SearchResult FindCurrentAdUser(params string[] properties)
    {
        string fqdn = Domain.GetCurrentDomain().Name;
        DirectoryEntry root = new DirectoryEntry("LDAP://" + fqdn);
        DirectorySearcher ds = new DirectorySearcher(root);
        ds.Filter = "(&(objectCategory=person)(objectClass=user)(sAMAccountName=" + GetSamAccountName().Replace("(", "\\28").Replace(")", "\\29") + "))";
        foreach (string property in properties) ds.PropertiesToLoad.Add(property);
        return ds.FindOne();
    }

    private void LoadRecoveryEmail()
    {
        if (!passwordRecoveryEnabled) return;
        try {
            SearchResult user = FindCurrentAdUser("mail");
            if (user == null) return;
            if (user.Properties["mail"].Count > 0) recoveryEmail = user.Properties["mail"][0].ToString();
            recoveryEmailVerified = !String.IsNullOrWhiteSpace(recoveryEmail);
        } catch { }
    }

    private void BeginRecoveryEmailChange()
    {
        Session.Remove("RDWebRecoveryPendingEmail");
        Session.Remove("RDWebRecoveryCode");
        Session.Remove("RDWebRecoveryCodeExpires");
        Session.Remove("RDWebRecoveryAttempts");
        recoveryEmail = "";
        recoveryEmailVerified = false;
        recoveryStatus = "Enter the new Recovery E-Mail address and verify it before it replaces your existing address.";
    }

    private void SendRecoveryEmailVerificationCode()
    {
        try {
            string address = (Request.Form["recoveryEmail"] ?? "").Trim();
            MailAddress parsed = new MailAddress(address);
            if (!parsed.Address.Equals(address, StringComparison.OrdinalIgnoreCase)) throw new Exception("Enter a valid email address.");
            if (String.IsNullOrWhiteSpace(recoverySmtpServer) || String.IsNullOrWhiteSpace(recoveryFromAddress)) throw new Exception("Password Recovery E-Mail has not been configured by an administrator.");

            byte[] bytes = new byte[4];
            using (System.Security.Cryptography.RandomNumberGenerator rng = System.Security.Cryptography.RandomNumberGenerator.Create()) rng.GetBytes(bytes);
            int number = (int)(BitConverter.ToUInt32(bytes, 0) % 1000000);
            string code = number.ToString("D6");

            Session["RDWebRecoveryPendingEmail"] = address;
            Session["RDWebRecoveryCode"] = code;
            Session["RDWebRecoveryCodeExpires"] = DateTime.UtcNow.AddMinutes(recoveryCodeExpiryMinutes);
            Session["RDWebRecoveryAttempts"] = 0;

            using (MailMessage message = new MailMessage()) {
                message.From = new MailAddress(recoveryFromAddress);
                message.To.Add(parsed);
                message.Subject = "RDWeb Recovery E-Mail verification";
                message.Body = "Your RDWeb Recovery E-Mail verification code is: " + code + "\r\n\r\nThis code expires in " + recoveryCodeExpiryMinutes + " minutes. If you did not request this code, you can ignore this email.";
                using (SmtpClient client = new SmtpClient(recoverySmtpServer, recoverySmtpPort)) {
                    client.DeliveryMethod = SmtpDeliveryMethod.Network;
                    client.UseDefaultCredentials = false;
                    client.Send(message);
                }
            }
            // The address is only pending until the emailed code is verified.
            // Keep the page in enrolment/change mode so the verification-code form is rendered.
            recoveryEmail = address;
            recoveryEmailVerified = false;
            recoveryStatus = "A verification code has been sent. Enter it below to verify this Recovery E-Mail.";
        } catch (Exception ex) { recoveryStatus = "Could not send verification email: " + ex.Message; }
    }

    private string SaveRecoveryEmailViaHelper(string samAccountName, string email)
    {
        using (NamedPipeClientStream pipe = new NamedPipeClientStream(
            ".", "RDWebRecoveryHelper", PipeDirection.InOut, PipeOptions.None))
        {
            pipe.Connect(3000);
            using (StreamWriter writer = new StreamWriter(pipe, new UTF8Encoding(false), 4096, true))
            using (StreamReader reader = new StreamReader(pipe, Encoding.UTF8, false, 4096, true))
            {
                writer.AutoFlush = true;
                writer.WriteLine("SETMAIL|" + samAccountName + "|" + email);
                string response = reader.ReadLine();
                if (String.IsNullOrEmpty(response))
                    throw new Exception("The password recovery helper returned no response.");
                if (!response.StartsWith("OK|", StringComparison.Ordinal))
                    throw new Exception(response.StartsWith("ERROR|", StringComparison.Ordinal)
                        ? response.Substring(6)
                        : "The password recovery helper returned an invalid response.");
                return response.Substring(3);
            }
        }
    }

    private void VerifyRecoveryEmailCode()
    {
        try {
            string supplied = (Request.Form["verificationCode"] ?? "").Trim();
            string pendingEmail = Session["RDWebRecoveryPendingEmail"] as string;
            string expected = Session["RDWebRecoveryCode"] as string;
            object expiryObject = Session["RDWebRecoveryCodeExpires"];
            int attempts = Session["RDWebRecoveryAttempts"] == null ? 0 : (int)Session["RDWebRecoveryAttempts"];
            if (String.IsNullOrEmpty(pendingEmail) || String.IsNullOrEmpty(expected) || expiryObject == null) throw new Exception("Request a new verification code.");
            if (DateTime.UtcNow > (DateTime)expiryObject) throw new Exception("The verification code has expired. Request a new code.");
            attempts++; Session["RDWebRecoveryAttempts"] = attempts;
            if (attempts > 5) throw new Exception("Too many incorrect attempts. Request a new code.");
            if (!String.Equals(supplied, expected, StringComparison.Ordinal)) throw new Exception("The verification code is incorrect.");

            SaveRecoveryEmailViaHelper(GetSamAccountName(), pendingEmail);

            Session.Remove("RDWebRecoveryPendingEmail");
            Session.Remove("RDWebRecoveryCode");
            Session.Remove("RDWebRecoveryCodeExpires");
            Session.Remove("RDWebRecoveryAttempts");
            recoveryEmail = pendingEmail;
            recoveryEmailVerified = true;
            recoveryStatus = "Recovery email verified and saved.";
        }
        catch (Exception ex) {
            recoveryStatus = "Verification failed: " + ex.Message;
        }
    }

    protected string RenderResources()
    {
        if (String.IsNullOrWhiteSpace(appFeed))
            return "<div class=\"alert alert-warning\">No RemoteApp resources were returned.</div>";

        try
        {
            string feedXml = appFeed.Trim();
            if (feedXml.Length > 0 && feedXml[0] == '\uFEFF')
                feedXml = feedXml.Substring(1).TrimStart();

            // GenerateFeedAsync returns an XML fragment for the RDWeb page, not necessarily
            // a standalone XML document. Remove any XML declaration and wrap the fragment.
            if (feedXml.StartsWith("<?xml", StringComparison.OrdinalIgnoreCase))
            {
                int declarationEnd = feedXml.IndexOf("?>", StringComparison.Ordinal);
                if (declarationEnd >= 0)
                    feedXml = feedXml.Substring(declarationEnd + 2);
            }

            XDocument doc = XDocument.Parse("<RDWebFeedRoot>" + feedXml + "</RDWebFeedRoot>");
            XNamespace ns = "http://schemas.microsoft.com/ts/2007/05/tswf";
            var resources = doc.Descendants(ns + "Resource").ToList();

            if (resources.Count == 0)
                return "<div class=\"alert alert-info\">No RemoteApps or desktops are currently assigned to this account.</div>";

            System.Text.StringBuilder html = new System.Text.StringBuilder();

            foreach (XElement resource in resources)
            {
                string title = (string)resource.Attribute("Title") ?? "Remote resource";

                XElement server = resource
                    .Descendants(ns + "HostingTerminalServer")
                    .FirstOrDefault();

                XElement resourceFile = server == null
                    ? null
                    : server.Element(ns + "ResourceFile");

                string launchUrl = resourceFile == null
                    ? ""
                    : ((string)resourceFile.Attribute("URL") ?? "");

                string fallbackContent = resourceFile == null
                    ? ""
                    : (resourceFile.Element(ns + "Content") == null
                        ? ""
                        : resourceFile.Element(ns + "Content").Value);

                XElement icon = resource
                    .Descendants(ns + "Icon32")
                    .FirstOrDefault(x =>
                        ((string)x.Attribute("Dimensions") ?? "") == "32x32" &&
                        ((string)x.Attribute("FileType") ?? "").Equals("Png", StringComparison.OrdinalIgnoreCase));

                string iconUrl = icon == null ? "" : ((string)icon.Attribute("FileURL") ?? "");

                if (String.IsNullOrEmpty(launchUrl) && !String.IsNullOrEmpty(fallbackContent))
                    launchUrl = Uri.UnescapeDataString(fallbackContent);

                html.Append("<div class=\"resource-item\">");
                html.Append("<a class=\"resource-card text-decoration-none\" href=\"");
                html.Append(HttpUtility.HtmlAttributeEncode(launchUrl));
                if (!String.IsNullOrEmpty(fallbackContent) && !String.IsNullOrEmpty(launchUrl))
                {
                    html.Append("\" onclick=\"return launchRdpResource('");
                    html.Append(HttpUtility.HtmlAttributeEncode(HttpUtility.JavaScriptStringEncode(fallbackContent)));
                    html.Append("', '");
                    html.Append(HttpUtility.HtmlAttributeEncode(HttpUtility.JavaScriptStringEncode(launchUrl)));
                    html.Append("');\">");
                }
                else
                {
                    html.Append("\">");
                }
                html.Append("<div class=\"card h-100\"><div class=\"card-body d-flex flex-column align-items-center justify-content-start text-center\">");

                if (!String.IsNullOrEmpty(iconUrl))
                {
                    html.Append("<img class=\"resource-icon\" src=\"");
                    html.Append(HttpUtility.HtmlAttributeEncode(iconUrl));
                    html.Append("\" alt=\"\" />");
                }
                else
                {
                    html.Append("<div class=\"resource-icon-placeholder\">RDP</div>");
                }

                html.Append("<div class=\"fw-semibold text-dark\">");
                html.Append(HttpUtility.HtmlEncode(title));
                html.Append("</div></div></div></a></div>");
            }

            return html.ToString();
        }
        catch (Exception ex)
        {
            return "<div class=\"alert alert-danger\">The RDWeb resource feed could not be rendered. " +
                HttpUtility.HtmlEncode(ex.Message) + "</div>";
        }
    }
</script>

<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title><%= HttpUtility.HtmlEncode(workspaceName) %></title>
    <link href="../css/bootstrap-5.3.8.min.css" rel="stylesheet" />
    <style>
        body { background:url('../images/EngOne.jpg') center center / cover fixed no-repeat; min-height:100vh; }
        .container.py-4 { background:rgba(255,255,255,.20); backdrop-filter:blur(8px); -webkit-backdrop-filter:blur(10px); border:1px solid rgba(255,255,255,.58); border-radius:1.15rem; margin-top:3.5rem; margin-bottom:2rem; padding:1.75rem 2rem !important; box-shadow:0 .5rem 1.5rem rgba(0,0,0,.12); }
        .resource-grid{display:grid!important;grid-template-columns:repeat(auto-fill,minmax(79px,1fr));gap:10.5px!important}.resource-item{min-width:0}.resource-card{display:block;height:100%}.resource-card .card { background:rgba(255,255,255,.10); backdrop-filter:blur(4px); -webkit-backdrop-filter:blur(5px); min-height:96px; border:1px solid rgba(255,255,255,.52)!important; border-radius:.75rem; box-shadow:none!important }.resource-card .card-body{padding:.675rem .4125rem!important;gap:.4125rem!important}.resource-card .fw-semibold{font-size:.72rem;line-height:1.15;word-break:break-word}
        .rdweb-header { margin:14px 18px 0; border:1px solid rgba(255,255,255,.65); border-radius:1rem; background:rgba(255,255,255,.62); color:#212529; backdrop-filter:blur(10px); -webkit-backdrop-filter:blur(10px); box-shadow:0 .35rem 1rem rgba(0,0,0,.12); }
        .rdweb-header .container { max-width:none; padding-left:1.5rem; padding-right:1.5rem; background:transparent; margin:0; border-radius:0; box-shadow:none; }
        .rdweb-brand-logo { width:56px; height:56px; object-fit:contain; filter:brightness(0); }
        .rdweb-brand-name { line-height:1.05; font-weight:600; }
        .rdweb-header a:not(.btn){color:#212529}.rdweb-header .btn { color:#343a40; border-color:rgba(52,58,64,.45); background:rgba(255,255,255,.18); }.rdweb-header .btn:hover{background:rgba(255,255,255,.38);color:#212529}
        .resource-card .card { border:0; transition:transform .12s ease, box-shadow .12s ease; }
         .resource-card:hover .card { transform:translateY(-3px); background:rgba(255,255,255,.40); box-shadow:0 .35rem .9rem/ rgba(0,0,0,.12)!important; }
        .resource-icon { width:39px; height:39px; object-fit:contain; flex:0 0 39px; }
        .rdweb-carousel { position:fixed; left:14px; right:14px; bottom:12px; z-index:1030; background:color-mix(in srgb, <%= HttpUtility.HtmlAttributeEncode(carouselColour) %> 45%, transparent); backdrop-filter:blur(10px); -webkit-backdrop-filter:blur(10px); border:1px solid rgba(255,255,255,.18); border-radius:1rem; color:#fff; overflow:hidden; box-shadow:0 -.25rem 1rem rgba(0,0,0,.12); }
        .rdweb-carousel .carousel-item { height:145px; }
        .rdweb-carousel .carousel-caption { position:static; padding:1.4rem 5rem 2rem; color:#fff; }
        main.container { margin-bottom:175px !important; }
        .resource-icon-placeholder {
            width:39px; height:39px; flex:0 0 39px; border-radius:.5rem;
            display:flex; align-items:center; justify-content:center;
            background:#e9ecef; color:#495057; font-size:.75rem; font-weight:700;
        }
    </style>
    <script src="../renderscripts.js"></script>
    <script>
        bFormAuthenticationMode = <%= authenticationMode == AuthenticationMode.Forms ? "true" : "false" %>;
        iSessionTimeout = <%= sessionTimeoutMinutes %>;
        strBaseUrl = "<%= HttpUtility.JavaScriptStringEncode(baseUrl == null ? "" : baseUrl.AbsoluteUri) %>";

        window.addEventListener("load", function () {
            if (typeof onAuthenticatedPageload === "function")
                onAuthenticatedPageload();
        });

        window.addEventListener("mousedown", function(e) {
            if (typeof onUserActivity === "function") onUserActivity(e);
        });
        window.addEventListener("keydown", function(e) {
            if (typeof onUserActivity === "function") onUserActivity(e);
        });
        window.addEventListener("scroll", function(e) {
            if (typeof onUserActivity === "function") onUserActivity(e);
        });
    </script>
<script type="text/javascript">
var rdwebRdpShell = null;
function initialiseRdpShell() {
    try {
        if (window.ActiveXObject) {
            try { rdwebRdpShell = new ActiveXObject("MsRdpWebAccess.MsRdpClientShell"); }
            catch (e) {
                try {
                    var legacy = new ActiveXObject("MsRdpClient.MsRdpClient");
                    if (legacy && legacy.MsRdpClientShell) rdwebRdpShell = legacy.MsRdpClientShell;
                } catch (ignored) { }
            }
        }
    } catch (ignored) { rdwebRdpShell = null; }
}
function launchRdpResource(rdpContents, url) {
    if (rdwebRdpShell) {
        try {
            var contents = unescape(rdpContents);
            if (typeof getUserNameRdpProperty === "function") contents += getUserNameRdpProperty();
            rdwebRdpShell.RdpFileContents = contents;
            rdwebRdpShell.Launch();
            return false;
        } catch (e) { }
    }
    window.location.href = url;
    return false;
}
</script>
</head>
<body onload="initialiseRdpShell();">
    <header class="rdweb-header">
        <div class="container py-3 d-flex flex-wrap align-items-center justify-content-between gap-3">
            <div class="d-flex align-items-center gap-3">
                <img class="rdweb-brand-logo" src="../images/crownCopyTransparentW.png" alt="Rural Payments Agency" />
                <div class="rdweb-brand-name">Rural Payments<br/>Agency</div>
                <div class="vr mx-2"></div>
                <div>
                <div class="h4 mb-0">Welcome <%= HttpUtility.HtmlEncode(displayName) %>, <%= HttpUtility.HtmlEncode(logonHeader.ToLowerInvariant()) %></div>
                <% if ((passwordRecoveryEnabled && recoveryEmailVerified) || !String.IsNullOrEmpty(passwordExpiration)) { %>
                <div class="small text-muted mt-2 d-flex flex-wrap gap-4">
                    <% if (passwordRecoveryEnabled && recoveryEmailVerified) { %>
                    <div>
                        <div>Recovery E-Mail, <%= HttpUtility.HtmlEncode(recoveryEmail) %></div>
                        <form method="post" action="default.aspx" class="d-block mt-1">
                            <input type="hidden" name="recoveryAction" value="change-email" />
                            <button type="submit" class="border-0 bg-transparent text-primary p-0" style="font-size:0.75rem; text-decoration:underline;">Change Recovery E-Mail</button>
                        </form>
                    </div>
                    <% } %>
                    <% if (!String.IsNullOrEmpty(passwordExpiration)) { %>
                    <div>
                        <div><%= HttpUtility.HtmlEncode(passwordExpiration.Replace(" Click here to reset now.", "")) %></div>
                        <a href="password.aspx" class="<%= passwordDaysRemaining >= 0 && passwordDaysRemaining < 5 ? "text-danger fw-bold" : "text-primary" %> d-block mt-1" style="font-size:0.75rem;">Change password</a>
                    </div>
                    <% } %>
                </div>
                <% } %>
                </div>
            </div>
            <% if (authenticationMode == AuthenticationMode.Forms) { %>
                <div class="d-flex align-items-center gap-2">
                    <% if (isWebAdmin) { %><a class="btn btn-outline-primary" href="customise.aspx">Customise</a><% } %>
                    <a class="btn btn-outline-secondary" href="rap-help.htm">Help</a>
                    <a class="btn btn-outline-secondary" href="logoff.aspx">Sign out</a>
                    <img class="rdweb-brand-logo ms-2" src="../images/crownCopyTransparentW.png" alt="Rural Payments Agency" />
                </div>
            <% } %>
        </div>
    </header>

    <main class="container py-4">
        <div class="d-flex align-items-center justify-content-between mb-4">
            <div>
                <h1 class="h3 mb-1">RemoteApp and Desktops</h1>
                <p class="text-muted mb-0">Select a resource to download and launch its RDP connection.</p>
            </div>
        </div>


        <% if (passwordRecoveryEnabled && (!recoveryEmailVerified || !String.IsNullOrEmpty(recoveryStatus))) { %>
        <div class="card mb-4">
            <div class="card-body">
                <h2 class="h5">Password Recovery E-Mail</h2>
                <% if (!String.IsNullOrEmpty(recoveryStatus)) { %><div class="alert alert-info"><%= HttpUtility.HtmlEncode(recoveryStatus) %></div><% } %>
                <% if (!recoveryEmailVerified) { %>
                    <p class="text-muted">Register an external email address that you can access if you forget your RDWeb password. The address is not saved until you verify the emailed code.</p>
                    <form method="post" action="default.aspx" class="row g-2 mb-3">
                        <input type="hidden" name="recoveryAction" value="send-code" />
                        <div class="col-md-8"><input class="form-control" type="email" name="recoveryEmail" value="<%= HttpUtility.HtmlAttributeEncode(recoveryEmail) %>" maxlength="254" placeholder="External recovery email" required /></div>
                        <div class="col-md-4"><button class="btn btn-outline-primary w-100" type="submit">Send verification code</button></div>
                    </form>
                    <% if (Session["RDWebRecoveryPendingEmail"] != null) { %>
                    <form method="post" action="default.aspx" class="row g-2">
                        <input type="hidden" name="recoveryAction" value="verify-code" />
                        <div class="col-md-8"><input class="form-control" name="verificationCode" inputmode="numeric" pattern="[0-9]{6}" maxlength="6" placeholder="6-digit verification code" required /></div>
                        <div class="col-md-4"><button class="btn btn-primary w-100" type="submit">Verify and save</button></div>
                    </form>
                    <% } %>
                <% } %>
            </div>
        </div>
        <% } %>

        <div class="resource-grid">
            <%= RenderResources() %>
        </div>
    </main>

    <div id="myCarousel" class="carousel slide rdweb-carousel" data-bs-ride="carousel">
        <div class="carousel-indicators">
            <button type="button" data-bs-target="#myCarousel" data-bs-slide-to="0" class="active" aria-current="true" aria-label="Slide 1"></button>
            <button type="button" data-bs-target="#myCarousel" data-bs-slide-to="1" aria-label="Slide 2"></button>
            <button type="button" data-bs-target="#myCarousel" data-bs-slide-to="2" aria-label="Slide 3"></button>
        </div>
        <div class="carousel-inner">
            <div class="carousel-item active">
                <div class="carousel-caption"><h2 class="h4"><%= HttpUtility.HtmlEncode(carouselTitle1) %></h2><p class="mb-0"><%= HttpUtility.HtmlEncode(carouselText1) %></p></div>
            </div>
            <div class="carousel-item">
                <div class="carousel-caption"><h2 class="h4"><%= HttpUtility.HtmlEncode(carouselTitle2) %></h2><p class="mb-0"><%= HttpUtility.HtmlEncode(carouselText2) %></p></div>
            </div>
            <div class="carousel-item">
                <div class="carousel-caption"><h2 class="h4"><%= HttpUtility.HtmlEncode(carouselTitle3) %></h2><p class="mb-0"><%= HttpUtility.HtmlEncode(carouselText3) %></p></div>
            </div>
        </div>
        <button class="carousel-control-prev" type="button" data-bs-target="#myCarousel" data-bs-slide="prev"><span class="carousel-control-prev-icon" aria-hidden="true"></span><span class="visually-hidden">Previous</span></button>
        <button class="carousel-control-next" type="button" data-bs-target="#myCarousel" data-bs-slide="next"><span class="carousel-control-next-icon" aria-hidden="true"></span><span class="visually-hidden">Next</span></button>
    </div>
    <script src="../js/bootstrap-5.3.8.bundle.min.js"></script>
</body>
</html>
