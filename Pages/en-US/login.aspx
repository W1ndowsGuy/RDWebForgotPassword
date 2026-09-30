
<% @Page Language="C#" Debug="false" ResponseEncoding="utf-8" ContentType="text/html" Async="true" %>
<% @Import Namespace="System " %>
<% @Import Namespace="System.Security" %>
<% @Import Namespace="System.Threading.Tasks" %>
<% @Import Namespace="Microsoft.TerminalServices.Publishing.Portal.FormAuthentication" %>
<% @Import Namespace="Microsoft.TerminalServices.Publishing.Portal" %>
<% @Import Namespace="System.Web.Security.AntiXss" %>
<% @Import Namespace="System.Net" %>
<% @Import Namespace="System.Net.NetworkInformation" %>
<% @Import Namespace="System.Xml.Linq" %>
<% @Import Namespace="System.Linq" %>
<% @Import Namespace="System.Globalization" %>

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
    public string carouselTitle1 = "Maintenence Outage";
    public string carouselText1 = "Notifications for outages will also be here in future";
    public string carouselTitle2 = "HELP";
    public string carouselText2 = "If you having any issues with login please click 'Help'";
    public string carouselTitle3 = "Security";
    public string carouselText3 = "Warning: By logging in to this web page, you confirm that this computer complies with your organization's security policy.";
    public string carouselColour = "#2d1450";

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
        
        LoadCarouselConfiguration();
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
    }

    private void LoadCarouselConfiguration()
    {
        try {
            string path = Server.MapPath("../config/carousel.xml");
            if (!System.IO.File.Exists(path)) return;
            XDocument doc = XDocument.Load(path);
            XElement env = doc.Root.Element("environmentName");
            if (env != null && !String.IsNullOrWhiteSpace(env.Value)) domainNameC = env.Value.Trim();
            XElement colour = doc.Root.Element("colour");
            if (colour != null && !String.IsNullOrWhiteSpace(colour.Value)) carouselColour = colour.Value.Trim();
            DateTime now = DateTime.Now;
            for (int i = 1; i <= 3; i++) {
                XElement slide = doc.Root.Elements("slide").FirstOrDefault(x => (string)x.Attribute("id") == i.ToString());
                if (slide == null) continue;
                string expiry = (string)slide.Attribute("expires") ?? "";
                DateTime exp;
                bool active = String.IsNullOrWhiteSpace(expiry) || (DateTime.TryParse(expiry, null, DateTimeStyles.RoundtripKind, out exp) && exp > now);
                if (!active) continue;
                string title = (string)slide.Element("title");
                string text = (string)slide.Element("text");
                if (i == 1) { if (title != null) carouselTitle1 = title; if (text != null) carouselText1 = text; }
                if (i == 2) { if (title != null) carouselTitle2 = title; if (text != null) carouselText2 = text; }
                if (i == 3) { if (title != null) carouselTitle3 = title; if (text != null) carouselText3 = text; }
            }
        } catch { }
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
<title><%=AntiXssEncoder.HtmlEncode(L_CompanyName_Text, false)%> - Login</title>
<link href="../css/bootstrap.min.css" rel="stylesheet" />
<script src="../webscripts-domain.js"></script>
<style>
html,body{min-height:100%} body{min-height:100vh;background:url('../images/EngOne.jpg') center/cover fixed no-repeat}
.page-wrap{min-height:100vh;display:flex;align-items:center}.login-shell{background:rgba(255,255,255,.30);backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);border:1px solid rgba(255,255,255,.58);border-radius:1.25rem;box-shadow:0 .75rem 2rem rgba(0,0,0,.18);overflow:hidden}.brand{color:#fff;text-align:center;padding:2.5rem;text-shadow:0 1px 3px rgba(0,0,0,.35);display:flex;flex-direction:column;justify-content:center;align-items:center;min-height:500px}.brand img{width:300px;max-width:75%}
.login-side{border-left:1px solid rgba(255,255,255,.45);display:flex;align-items:center;padding:2rem}.login-panel{background:transparent;border:0;border-radius:0;padding:1rem 2rem;max-width:520px;width:100%;margin:auto;box-shadow:none}.wrng{color:#b02a37}
@media(max-width:991.98px){.brand{min-height:auto;padding:2rem}.login-side{border-left:0;border-top:1px solid rgba(255,255,255,.45);padding:1rem}.login-shell{margin-top:1rem;margin-bottom:1rem}}
.rdweb-carousel{position:fixed;left:14px;right:14px;bottom:12px;z-index:1030;background:color-mix(in srgb,<%=HttpUtility.HtmlAttributeEncode(carouselColour)%> 82%,transparent);backdrop-filter:blur(10px);-webkit-backdrop-filter:blur(10px);border:1px solid rgba(255,255,255,.18);border-radius:1rem;color:#fff;overflow:hidden;box-shadow:0 -.25rem 1rem rgba(0,0,0,.12)}.rdweb-carousel .carousel-item{height:145px}.rdweb-carousel .carousel-caption{position:static;padding:1.4rem 5rem 2rem;color:#fff}.page-wrap{padding-bottom:165px!important}
</style>
</head>
<body onload="onLoginPageLoad(event)" onunload="onPageUnload(event)">
<div class="container page-wrap py-5"><div class="row g-0 align-items-stretch w-100 login-shell">
<div class="col-lg-6 brand"><div class="h2 mb-4"><%=domainNameC%></div><img src="../images/crownCopyTransparentW.png" alt="Rural Payments Agency"/><div class="h2 mt-3">Rural Payments Agency</div></div>
<div class="col-lg-6 login-side"><div class="login-panel">
<form autocomplete="off" id="FrmLogin" name="FrmLogin" action="login.aspx<%=SecurityElement.Escape(strReturnUrl)%>" method="post" onsubmit="return onLoginFormSubmit()">
<input type="hidden" name="WorkSpaceID" value="<%=SecurityElement.Escape(strWorkSpaceID)%>"/>
<input type="hidden" name="RDPCertificates" value="<%=SecurityElement.Escape(strRDPCertificates)%>"/>
<input type="hidden" name="PublicModeTimeout" value="<%=SecurityElement.Escape(strPublicModeTimeout)%>"/>
<input type="hidden" name="PrivateModeTimeout" value="<%=SecurityElement.Escape(strPrivateModeTimeout)%>"/>
<input type="hidden" name="WorkspaceFriendlyName" value="<%=AntiXssEncoder.UrlEncode(L_CompanyName_Text)%>"/>
<input type="hidden" name="EventLogUploadAddress" value="<%=SecurityElement.Escape(strEventLogUploadAddress)%>"/>
<input type="hidden" name="RedirectorName" value="<%=SecurityElement.Escape(strRedirectorName)%>"/>
<input type="hidden" name="ClaimsHint" value="<%=SecurityElement.Escape(strClaimsHint)%>"/>
<input type="hidden" name="ClaimsToken" value=""/>
<input name="isUtf8" type="hidden" value="1"/><input type="hidden" name="flags" value="0"/>
<div id="tableLoginDisabled" style="display:none"><div id="trWrongAxVersion" style="display:none"><span class="wrng"><%=L_WrongAxVersionWarningLabel_Text%></span></div><div id="trUnsupportedBrowser" style="display:none"><span class="wrng"><%=L_UnsupportedBrowserWarningLabel_Text%></span></div><div id="trSupportedBrowserAxLoadError" style="display:none"><span class="wrng"><%=L_SupportedBrowserAxLoadErrorLabel_Text%></span></div><div id="trCookiesDisabled" style="display:none"><span class="wrng"><%=L_CookiesDisabledWarningLabel_Text%></span></div></div>
<div id="tableLoginForm"><h2 class="text-center mb-4">Login</h2>
<div class="mb-3"><label for="DomainUserName" class="form-label"><%=L_DomainUserNameLabel_Text%></label><input id="DomainUserName" name="DomainUserName" type="text" runat="server" autocomplete="off" class="form-control form-control-lg"/></div>
<div class="mb-3"><label for="UserPass" class="form-label"><%=L_PasswordLabel_Text%></label><input id="UserPass" name="UserPass" type="password" runat="server" autocomplete="off" class="form-control form-control-lg"/></div>
<div class="mb-4"><label for="SecurityCode" class="form-label">Security Code</label><input id="SecurityCode" name="securitycode" type="text" runat="server" autocomplete="off" class="form-control form-control-lg"/></div>
<input id="SymcUserName" value="DomainUserName=" runat="server" size="25" style="display:none;"/>
<div class="d-flex justify-content-center gap-3"><input type="submit" class="btn btn-secondary btn-lg" id="btnSignIn" value="Sign in"/><input type="button" class="btn btn-outline-secondary btn-lg" id="btnHelp" onclick="onClickHelp()" value="Help"/></div>
<% strErrorMessageRowStyle=bPasswordExpiredNoChange?"":"display:none"; %><div id="trPasswordExpiredNoChange" style="<%=strErrorMessageRowStyle%>" class="alert alert-warning mt-3"><%=L_PasswordExpiredNoChange_Text%></div>
<% strErrorMessageRowStyle=bPasswordExpired?"":"display:none"; %><div id="trPasswordExpired" style="<%=strErrorMessageRowStyle%>" class="alert alert-warning mt-3"><%=L_PasswordExpiredChangeBeginning_Text%><a id="passwordchangelink" href="password.aspx<%=strPasswordExpiredQueryString%>"><%=L_PasswordExpiredChangeLink_Text%></a><%=L_PasswordExpiredChangeEnding_Text%></div>
<% strErrorMessageRowStyle=bWorkspaceInUse?"":"display:none"; %><div id="trErrorWorkSpaceInUse" style="<%=strErrorMessageRowStyle%>" class="alert alert-warning mt-3"><%=L_ExistingWorkspaceLabel_Text%></div>
<% strErrorMessageRowStyle=bWorkspaceDisconnected?"":"display:none"; %><div id="trErrorWorkSpaceDisconnected" style="<%=strErrorMessageRowStyle%>" class="alert alert-warning mt-3"><%=L_DisconnectedWorkspaceLabel_Text%></div>
<% strErrorMessageRowStyle=bFailedLogon?"":"display:none"; %><div id="trErrorIncorrectCredentials" style="<%=strErrorMessageRowStyle%>" class="alert alert-danger mt-3"><%=L_LogonFailureLabel_Text%></div>
<div id="trErrorDomainNameMissing" style="display:none" class="alert alert-danger mt-3"><%=L_DomainNameMissingLabel_Text%></div>
<% strErrorMessageRowStyle=(bFailedAuthorization||bFailedAuthorizationOverride)?"":"display:none"; %><div id="trErrorUnauthorizedAccess" style="<%=strErrorMessageRowStyle%>" class="alert alert-danger mt-3"><%=L_AuthorizationFailureLabel_Text%></div>
<% strErrorMessageRowStyle=bServerConfigChanged?"":"display:none"; %><div id="trErrorServerConfigChanged" style="<%=strErrorMessageRowStyle%>" class="alert alert-warning mt-3"><%=L_ServerConfigChangedLabel_Text%></div>
<div id="trErrorGenericClaimsAuthFailure" style="display:none" class="alert alert-danger mt-3"><%=L_GenericClaimsAuthErrorLabel_Text%></div>
<div id="spanToggleSecExplanation" style="display:none"><a href="javascript:onclickExplanation('lnkShwSec')" id="lnkShwSec"><%=L_ShowExplanationLabel_Text%></a><a href="javascript:onclickExplanation('lnkHdSec')" id="lnkHdSec" style="display:none"><%=L_HideExplanationLabel_Text%></a></div>
<div id="tablePublicOption" style="display:none"><input id="rdoPblc" type="radio" name="MachineType" value="public" onclick="onClickSecurity()"/></div>
<div id="trPubExp" style="display:none"><%=L_PublicExplanationLabel_Text%></div>
<div id="tablePrivateOption" style="display:none"><input id="rdoPrvt" type="radio" name="MachineType" value="private" onclick="onClickSecurity()" checked="checked"/></div>
<div id="trPrvtExp" style="display:none"><%=L_PrivateExplanationLabel_Text%></div>
<div id="trPrvtWrn" style="display:none"><%=L_PrivateWarningLabel_Text%></div><div id="trPrvtWrnNoAx" style="display:none"><%=L_PrivateWarningLabelNoAx_Text%></div>
<hr/><p class="small text-muted mb-0"><%=L_TSWATimeoutLabel_Text%></p>
</div></form></div></div></div></div>
<div id="myCarousel" class="carousel slide rdweb-carousel" data-bs-ride="carousel">
<div class="carousel-indicators"><button type="button" data-bs-target="#myCarousel" data-bs-slide-to="0" class="active" aria-current="true" aria-label="Slide 1"></button><button type="button" data-bs-target="#myCarousel" data-bs-slide-to="1" aria-label="Slide 2"></button><button type="button" data-bs-target="#myCarousel" data-bs-slide-to="2" aria-label="Slide 3"></button></div>
<div class="carousel-inner"><div class="carousel-item active"><div class="carousel-caption"><h2 class="h4"><%=HttpUtility.HtmlEncode(carouselTitle1)%></h2><p class="mb-0"><%=HttpUtility.HtmlEncode(carouselText1)%></p></div></div><div class="carousel-item"><div class="carousel-caption"><h2 class="h4"><%=HttpUtility.HtmlEncode(carouselTitle2)%></h2><p class="mb-0"><%=HttpUtility.HtmlEncode(carouselText2)%></p></div></div><div class="carousel-item"><div class="carousel-caption"><h2 class="h4"><%=HttpUtility.HtmlEncode(carouselTitle3)%></h2><p class="mb-0"><%=HttpUtility.HtmlEncode(carouselText3)%></p></div></div></div>
<button class="carousel-control-prev" type="button" data-bs-target="#myCarousel" data-bs-slide="prev"><span class="carousel-control-prev-icon" aria-hidden="true"></span><span class="visually-hidden">Previous</span></button><button class="carousel-control-next" type="button" data-bs-target="#myCarousel" data-bs-slide="next"><span class="carousel-control-next-icon" aria-hidden="true"></span><span class="visually-hidden">Next</span></button></div>
<script src="../js/bootstrap.bundle.min.js"></script>
<script>var strBaseUrl="<%=HttpUtility.JavaScriptStringEncode(baseUrl.AbsoluteUri)%>"; var strPrivacyUrl="<%=HttpUtility.JavaScriptStringEncode(strPrivacyUrl)%>"; var strHelpUrl="<%=HttpUtility.JavaScriptStringEncode(sHelpSourceServer)%>";</script>
</body></html>