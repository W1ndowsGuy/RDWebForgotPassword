
<% @Page Language="C#" Debug="false" ResponseEncoding="utf-8" ContentType="text/html" Async="true" %>
<% @Import Namespace="System " %>
<% @Import Namespace="System.Security" %>
<% @Import Namespace="System.Threading.Tasks" %>
<% @Import Namespace="Microsoft.TerminalServices.Publishing.Portal.FormAuthentication" %>
<% @Import Namespace="Microsoft.TerminalServices.Publishing.Portal" %>
<% @Import Namespace="System.Web.Security.AntiXss" %>
<% @Import Namespace="System.Net" %>
<% @Import Namespace="System.Net.NetworkInformation" %>

<script language="C#" runat=server>

    //
    // Customizable Text
    //
    string L_CompanyName_Text = "Work Resources";

    //
    // Localizable Text
    //
    const string L_ClaimsDomainUserNameLabel_Text_Custom = "username@capdelivery.gov.uk";

    const string L_DomainUserNameLabel_Text = "Domain\\user name:";
    const string L_PasswordLabel_Text = "Password:";
    const string L_PasswordExpiredChangeBeginning_Text = "Your password is expired. Click ";
    const string L_PasswordExpiredChangeLink_Text = "here";
    const string L_PasswordExpiredChangeEnding_Text = " to change it.";
    const string L_PasswordExpiredNoChange_Text = "Your password is expired. Please contact your administrator for assistance.";
    const string L_ExistingWorkspaceLabel_Text = "Another user of your computer is currently using this connection.  This user must disconnect before you can log on.";
    const string L_DisconnectedWorkspaceLabel_Text = "Another user of your computer has disconnected from this connection.  Please type your user name and password again.";
    const string L_LogonFailureLabel_Text = "The user name or password that you entered is not valid. Try typing it again.";
    const string L_DomainNameMissingLabel_Text = "You must enter a valid domain name.";
    const string L_AuthorizationFailureLabel_Text = "You aren’t authorized to log on to this connection.  Contact your system administrator for authorization.";
    const string L_ServerConfigChangedLabel_Text = "Your RD Web Access session expired due to configuration changes on the remote computer.  Please sign in again.";
    const string L_SecurityLabel_Text = "Security";
    const string L_ShowExplanationLabel_Text = "show explanation";
    const string L_HideExplanationLabel_Text = "hide explanation";
    const string L_PublicLabel_Text = "This is a public or shared computer";
    const string L_PublicExplanationLabel_Text = "Select this option if you use RD Web Access on a public computer.  Be sure to log off when you have finished using RD Web Access and close all windows to end your session.";
    const string L_PrivateLabel_Text = "This is a private computer";
    const string L_PrivateExplanationLabel_Text = "Select this option if you are the only person who uses this computer.  Your server will allow a longer period of inactivity before logging you off.";
    const string L_PrivateWarningLabel_Text = "Warning:  By selecting this option, you confirm that this computer complies with your organization's security policy.";
    const string L_PrivateWarningLabelNoAx_Text = "Warning:  By logging in to this web page, you confirm that this computer complies with your organization's security policy.";
    const string L_SignInLabel_Text = "Submit";
    const string L_TSWATimeoutLabel_Text = "To protect against unauthorized access, your RD Web Access session will automatically time out after a period of inactivity.  If your session ends, refresh your browser and sign in again.";
    const string L_RenderFailTitle_Text = "Error: Unable to display RD Web Access";
    const string L_RenderFailP1_Text = "An unexpected error has occurred that is preventing this page from being displayed correctly.";
    const string L_RenderFailP2_Text = "Viewing this page in Internet Explorer with the Enhanced Security Configuration enabled can cause such an error.";
    const string L_RenderFailP3_Text = "Please try loading this page without the Enhanced Security Configuration enabled. If this error continues to be displayed, please contact your administrator."; 
    const string L_GenericClaimsAuthErrorLabel_Text = "We can't sign you in right now. Please try again later.";
    const string L_WrongAxVersionWarningLabel_Text = "You don't have the right version of Remote Desktop Connection to use RD Web Access.";
    const string L_UnsupportedBrowserWarningLabel_Text = "Your web browser isn't supported by Microsoft RemoteApp Service. Please use a supported browser.";
    const string L_SupportedBrowserAxLoadErrorLabel_Text = "Your browser has ActiveX controls turned off. Go to your browser's settings to turn on ActiveX controls.";
    const string L_ClaimsDomainUserNameLabel_Text = "Username@domain:";
    const string L_CookiesDisabledWarningLabel_Text = "Your browser has cookies disabled. Go to your browser's settings to enable cookies.";

    //
    // Page Variables
    //
    public string strErrorMessageRowStyle;
    public bool bFailedLogon = false, bFailedAuthorization = false, bFailedAuthorizationOverride = false, bServerConfigChanged = false, bWorkspaceInUse = false, bWorkspaceDisconnected = false, bPasswordExpired =  false, bPasswordExpiredNoChange = false;
    public string strWorkSpaceID = "";
    public string strRDPCertificates = "";
    public string strRedirectorName = "";
    public string strClaimsHint = "";
    public string strReturnUrl = "";
    public string strReturnUrlPage = "";
    public string strPasswordExpiredQueryString = "";
    public string strEventLogUploadAddress = "";
    public string sHelpSourceServer, sLocalHelp;
    public Uri baseUrl;
    public string strPrivacyUrl = "";
    public string myString ="login";

    public string strPrivateModeTimeout = "240";
    public string strPublicModeTimeout = "20";


    public WorkspaceInfo objWorkspaceInfo = null;

    private string strLDAPPath = "";
    private string domainName = "";
    private string domainNameC = "";
    string capitalizeFirstLetter(string input)
    {
        if (!string.IsNullOrEmpty(input))
        {
            return char.ToUpper(input[0]) + input.Substring(1);
        }
        else
        {
            return input;
        }
    }


    void Page_PreInit(object sender, EventArgs e)
    {

         IPGlobalProperties properties = IPGlobalProperties.GetIPGlobalProperties();
        string domainNameA = properties.DomainName;

        // Prepend "LDAP://" to the domain name
        strLDAPPath = "LDAP://" + domainNameA;

        // Remove ".local" suffix from the domain name
        int lastIndex = domainNameA.LastIndexOf(".local");
        if (lastIndex != -1)
        {
            domainName = domainNameA.Substring(0, lastIndex);
        }
        else
        {
            // If ".local" suffix is not found, use the original domain name
            domainName = domainNameA;
        }
        if (!string.IsNullOrEmpty(domainName))
        {
            domainNameC = char.ToUpper(domainName[0]) + domainName.Substring(1);
        }
        if (!string.IsNullOrEmpty(domainName))
        {
            domainNameC = capitalizeFirstLetter(domainName);
            // Add 'CHS-' prefix if it's not present
            if (!domainNameC.StartsWith("Chs-"))
            {
                domainNameC = "CHS-" + domainNameC;
            }
        }





        // Deny requests with "additional path information"
        if (Request.PathInfo.Length != 0)
        {
            Response.StatusCode = 404;
            Response.End();
        }

        // gives us https://<hostname>[:port]/rdweb/pages/<lang>/
        baseUrl = new Uri(new Uri(RequestHelper.GetOriginalRequestUri(Request), RequestHelper.GetRequestFilePath(Request)), ".");

        sLocalHelp = ConfigurationManager.AppSettings["LocalHelp"];
        if ((sLocalHelp != null) && (sLocalHelp == "true"))
        {
            sHelpSourceServer = "./rap-help.htm";
        }
        else
        {
            sHelpSourceServer = "http://go.microsoft.com/fwlink/?LinkId=141038";
        }
        
        try
        {
            strPrivateModeTimeout = ConfigurationManager.AppSettings["PrivateModeSessionTimeoutInMinutes"].ToString();
            strPublicModeTimeout = ConfigurationManager.AppSettings["PublicModeSessionTimeoutInMinutes"].ToString();
        }
        catch (Exception objException)
        {
        }
    }
    
    protected void Page_Load(object sender, EventArgs e)
    {
        
        RegisterAsyncTask(new PageAsyncTask(LoginPageLoadAsync));
        ExecuteRegisteredAsyncTasks();
        //if (!IsPostBack)
        //{
        //DomainUserName.Attributes["placeholder"] = L_ClaimsDomainUserNameLabel_Text_Custom;
        //}


     
    }
    
    private async Task LoginPageLoadAsync()
    {
        if ( Request.QueryString != null )
        {
            NameValueCollection objQueryString = Request.QueryString;
            if ( objQueryString["ReturnUrl"] != null )
            {
                strReturnUrlPage = objQueryString["ReturnUrl"];
                strReturnUrl = "?ReturnUrl=" + AntiXssEncoder.UrlEncode(strReturnUrlPage);
            }
            if ( objQueryString["Error"] != null )
            {
                if ( objQueryString["Error"].Equals("WkSInUse", StringComparison.CurrentCultureIgnoreCase) )
                {
                    bWorkspaceInUse = true;
                }
                else if ( objQueryString["Error"].Equals("WkSDisconnected", StringComparison.CurrentCultureIgnoreCase) )
                {
                    bWorkspaceDisconnected = true;
                }
                else if ( objQueryString["Error"].Equals("UnauthorizedAccess", StringComparison.CurrentCultureIgnoreCase) )
                {
                    bFailedAuthorization = true;
                }
                else if ( objQueryString["Error"].Equals("UnauthorizedAccessOverride", StringComparison.CurrentCultureIgnoreCase) )
                {
                    bFailedAuthorization = true;
                    bFailedAuthorizationOverride = true;
                }
                else if ( objQueryString["Error"].Equals("ServerConfigChanged", StringComparison.CurrentCultureIgnoreCase) )
                {
                    bServerConfigChanged = true;
                }
                else if ( objQueryString["Error"].Equals("PasswordExpired", StringComparison.CurrentCultureIgnoreCase) )
                {
                    string strPasswordChangeEnabled = ConfigurationManager.AppSettings["PasswordChangeEnabled"];

                    if (strPasswordChangeEnabled != null && strPasswordChangeEnabled.Equals("true", StringComparison.CurrentCultureIgnoreCase))
                    {
                        bPasswordExpired = true;
                        if (objQueryString["UserName"] != null)
                        {
                            strPasswordExpiredQueryString = "?UserName=" + Uri.EscapeDataString(objQueryString["UserName"]);
                        }
                    }
                    else
                    {
                        bPasswordExpiredNoChange = true;
                    }
                }
            }
        }

        //
        // Special case to handle 'ServerConfigChanged' error from Response's Location header.
        //
        try
        {
            if ( Response.Headers != null )
            {
                NameValueCollection objResponseHeader = Response.Headers;
                if ( !String.IsNullOrEmpty( objResponseHeader["Location"] ) )
                {
                    Uri objLocationUri = new Uri( objResponseHeader["Location"] );
                    if ( objLocationUri.Query.IndexOf("ServerConfigChanged") != -1 )
                    {
                        if ( !bFailedAuthorization )
                        {
                            bServerConfigChanged = true;
                        }
                    }
                }
            }
        }
        catch (Exception objException)
        {
        }

        if ( HttpContext.Current.User.Identity.IsAuthenticated != true )
        {
            // Only do this if we are actually rendering the login page, if we are just redirecting there is no need for these potentially expensive calls
            objWorkspaceInfo = PageContentsHelper.GetWorkspaceInfo();
            if ( objWorkspaceInfo != null )
            {
                strWorkSpaceID = objWorkspaceInfo.WorkspaceId;
                strRedirectorName = objWorkspaceInfo.RedirectorName;
                string strWorkspaceName = objWorkspaceInfo.WorkspaceName;
                if ( String.IsNullOrEmpty(strWorkspaceName ) == false )
                {
                    L_CompanyName_Text = strWorkspaceName;
                }
                if (!String.IsNullOrEmpty(objWorkspaceInfo.EventLogUploadAddress))
                {
                    strEventLogUploadAddress = objWorkspaceInfo.EventLogUploadAddress;
                }
            }
            strRDPCertificates = PageContentsHelper.GetRdpSigningCertificateHash();
            strClaimsHint = PageContentsHelper.GetClaimsHint();

            strPrivacyUrl = await PageContentsHelper.GetPrivacyLinkAsync();
        }

        if ( HttpContext.Current.User.Identity.IsAuthenticated == true )
        {
            SafeRedirect(strReturnUrlPage);
        }
        else if ( HttpContext.Current.Request.HttpMethod.Equals("POST", StringComparison.CurrentCultureIgnoreCase) == true )
        {
            bFailedLogon = true;
            if ( bFailedAuthorization )
            {
                bFailedAuthorization = false; // Make sure to show one message.
            }
        }

        if (bPasswordExpired)
        {
            bFailedLogon = false;
        }

        if (bFailedAuthorizationOverride)
        {
            bFailedLogon = false;
        }
        
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
    }
    
    private void SafeRedirect(string strRedirectUrl)
    {
        string strRedirectSafeUrl = null;

        if (!String.IsNullOrEmpty(strRedirectUrl))
        {
            Uri baseUrl = RequestHelper.GetOriginalRequestUri(Request);
            Uri redirectUri = new Uri(new Uri(baseUrl, RequestHelper.GetRequestFilePath(Request)), strRedirectUrl);

            if (
                redirectUri.Authority.Equals(baseUrl.Authority) &&
                redirectUri.Scheme.Equals(baseUrl.Scheme)
               )
            {
                strRedirectSafeUrl = redirectUri.AbsoluteUri;   
            }

        }

        if (strRedirectSafeUrl == null)
        {
            strRedirectSafeUrl = "default.aspx";
        }

        Response.Redirect(strRedirectSafeUrl);       
    }
    

</script>

<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title><%= AntiXssEncoder.HtmlEncode(L_CompanyName_Text, false) %> - Sign in</title>
    <link href="../css/bootstrap.min.css" rel="stylesheet" />
    <style>
        html, body { min-height:100%; }
        body {
            min-height:100vh;
            background:
                linear-gradient(rgba(0,0,0,.18),rgba(0,0,0,.18)),
                url('../images/EnglandBigV2.jpg') center center/cover fixed no-repeat;
        }
        .page-wrap { min-height:100vh; display:flex; align-items:center; }
        .brand-panel { color:#fff; text-align:center; text-shadow:0 1px 3px rgba(0,0,0,.35); }
        .brand-panel img { width:min(300px,75%); height:auto; }
        .login-panel {
            background:rgba(255,255,255,.88);
            border-radius:1rem;
            padding:2rem;
            box-shadow:0 .5rem 2rem rgba(0,0,0,.18);
        }
        .form-control { background:rgba(255,255,255,.8); }
    </style>
</head>
<body>
<div class="container page-wrap py-5">
    <div class="row g-5 align-items-center w-100">
        <div class="col-lg-6 brand-panel">
            <div class="h2 mb-4"><%= AntiXssEncoder.HtmlEncode(domainNameC, false) %></div>
            <img src="../images/crownCopyTransparentW.png" alt="Rural Payments Agency" />
            <div class="h2 mt-3">Rural Payments Agency</div>
        </div>

        <div class="col-lg-6">
            <div class="login-panel mx-auto" style="max-width:520px">
                <h1 class="h2 text-center mb-4">Login</h1>

                <% if (bFailedLogon) { %>
                    <div class="alert alert-danger"><%= L_LogonFailureLabel_Text %></div>
                <% } %>
                <% if (bFailedAuthorization || bFailedAuthorizationOverride) { %>
                    <div class="alert alert-danger"><%= L_AuthorizationFailureLabel_Text %></div>
                <% } %>
                <% if (bServerConfigChanged) { %>
                    <div class="alert alert-warning"><%= L_ServerConfigChangedLabel_Text %></div>
                <% } %>
                <% if (bWorkspaceInUse) { %>
                    <div class="alert alert-warning"><%= L_ExistingWorkspaceLabel_Text %></div>
                <% } %>
                <% if (bWorkspaceDisconnected) { %>
                    <div class="alert alert-warning"><%= L_DisconnectedWorkspaceLabel_Text %></div>
                <% } %>
                <% if (bPasswordExpired) { %>
                    <div class="alert alert-warning">
                        <%= L_PasswordExpiredChangeBeginning_Text %><a href="password.aspx<%= SecurityElement.Escape(strPasswordExpiredQueryString) %>"><%= L_PasswordExpiredChangeLink_Text %></a><%= L_PasswordExpiredChangeEnding_Text %>
                    </div>
                <% } %>
                <% if (bPasswordExpiredNoChange) { %>
                    <div class="alert alert-warning"><%= L_PasswordExpiredNoChange_Text %></div>
                <% } %>

                <form autocomplete="off" id="FrmLogin" name="FrmLogin"
                      action="login.aspx<%= SecurityElement.Escape(strReturnUrl) %>"
                      method="post" onsubmit="return validateLogin();">

                    <input type="hidden" name="WorkSpaceID" value="<%= SecurityElement.Escape(strWorkSpaceID) %>" />
                    <input type="hidden" name="RDPCertificates" value="<%= SecurityElement.Escape(strRDPCertificates) %>" />
                    <input type="hidden" name="PublicModeTimeout" value="<%= SecurityElement.Escape(strPublicModeTimeout) %>" />
                    <input type="hidden" name="PrivateModeTimeout" value="<%= SecurityElement.Escape(strPrivateModeTimeout) %>" />
                    <input type="hidden" name="WorkspaceFriendlyName" value="<%= AntiXssEncoder.UrlEncode(L_CompanyName_Text) %>" />
                    <input type="hidden" name="EventLogUploadAddress" value="<%= SecurityElement.Escape(strEventLogUploadAddress) %>" />
                    <input type="hidden" name="RedirectorName" value="<%= SecurityElement.Escape(strRedirectorName) %>" />
                    <input type="hidden" name="ClaimsHint" value="<%= SecurityElement.Escape(strClaimsHint) %>" />
                    <input type="hidden" name="ClaimsToken" value="" />
                    <input type="hidden" name="isUtf8" value="1" />
                    <input type="hidden" name="flags" value="0" />
                    <input type="hidden" name="MachineType" value="private" />

                    <div id="clientError" class="alert alert-danger d-none">
                        Enter a valid domain user name and password.
                    </div>

                    <div class="mb-3">
                        <label class="form-label" for="DomainUserName"><%= L_DomainUserNameLabel_Text %></label>
                        <input class="form-control form-control-lg" id="DomainUserName"
                               name="DomainUserName" type="text" autocomplete="username" />
                    </div>

                    <div class="mb-3">
                        <label class="form-label" for="UserPass"><%= L_PasswordLabel_Text %></label>
                        <input class="form-control form-control-lg" id="UserPass"
                               name="UserPass" type="password" autocomplete="current-password" />
                    </div>

                    <div class="mb-4">
                        <label class="form-label" for="SecurityCode">Security Code</label>
                        <input class="form-control form-control-lg" id="SecurityCode"
                               name="securitycode" type="text" inputmode="numeric"
                               autocomplete="one-time-code" />
                    </div>

                    <input type="hidden" id="SymcUserName" value="DomainUserName=" />

                    <div class="d-grid gap-2 d-sm-flex justify-content-sm-center">
                        <button type="submit" class="btn btn-secondary btn-lg px-4">Sign in</button>
                        <a class="btn btn-outline-secondary btn-lg px-4" href="rap-help.htm">Help</a>
                    </div>
                </form>

                <hr class="my-4" />
                <p class="small text-muted text-center mb-0"><%= L_TSWATimeoutLabel_Text %></p>
            </div>
        </div>
    </div>
</div>

<script>
function validateLogin() {
    var user = document.getElementById("DomainUserName").value;
    var pass = document.getElementById("UserPass").value;
    var hasDomain = user.indexOf("\\") > 0 || user.indexOf("@") > 0;
    var ok = user.length > 0 && pass.length > 0 && hasDomain;
    document.getElementById("clientError").classList.toggle("d-none", ok);
    return ok;
}
document.getElementById("DomainUserName").focus();
</script>
</body>
</html>
