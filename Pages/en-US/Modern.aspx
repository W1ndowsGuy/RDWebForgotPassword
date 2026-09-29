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

    protected string RenderResources()
    {
        if (String.IsNullOrWhiteSpace(appFeed))
            return "<div class=\"alert alert-warning\">No RemoteApp resources were returned.</div>";

        try
        {
            string feedXml = appFeed.TrimStart('\uFEFF', ' ', '\t', '\r', '
');

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

                html.Append("<div class=\"col-12 col-sm-6 col-lg-4 col-xl-3\">");
                html.Append("<a class=\"resource-card text-decoration-none\" href=\"");
                html.Append(HttpUtility.HtmlAttributeEncode(launchUrl));
                html.Append("\">");
                html.Append("<div class=\"card h-100 shadow-sm\"><div class=\"card-body d-flex align-items-center gap-3\">");

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
    <link href="../css/bootstrap.min.css" rel="stylesheet" />
    <style>
        body { background:#f4f6f8; min-height:100vh; }
        .rdweb-header { background:#fff; border-bottom:1px solid #dee2e6; }
        .resource-card .card { border:0; transition:transform .12s ease, box-shadow .12s ease; }
        .resource-card:hover .card { transform:translateY(-2px); }
        .resource-icon { width:48px; height:48px; object-fit:contain; flex:0 0 48px; }
        .resource-icon-placeholder {
            width:48px; height:48px; flex:0 0 48px; border-radius:.5rem;
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
</head>
<body>
    <header class="rdweb-header">
        <div class="container py-3 d-flex flex-wrap align-items-center justify-content-between gap-3">
            <div>
                <div class="h4 mb-0"><%= HttpUtility.HtmlEncode(workspaceName) %></div>
                <div class="text-muted small"><%= HttpUtility.HtmlEncode(domainUserName) %></div>
            </div>
            <% if (authenticationMode == AuthenticationMode.Forms) { %>
                <a class="btn btn-outline-secondary" href="logoff.aspx">Sign out</a>
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

        <div class="row g-3">
            <%= RenderResources() %>
        </div>
    </main>
</body>
</html>
