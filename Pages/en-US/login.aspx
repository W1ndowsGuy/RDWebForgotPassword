<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="../Site.xsl"?>
<?xml-stylesheet type="text/css" href="../RenderFail.css"?>

<% @Page Language="C#" Debug="false" ResponseEncoding="utf-8" ContentType="text/xml" Async="true" %>
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
<RDWAPage 
    helpurl="<%=sHelpSourceServer%>" 
    workspacename="<%=AntiXssEncoder.XmlAttributeEncode(L_CompanyName_Text)%>" 
    baseurl="<%=SecurityElement.Escape(baseUrl.AbsoluteUri)%>"
    privacyurl="<%=AntiXssEncoder.XmlAttributeEncode(strPrivacyUrl)%>"
    myString="<%=myString%>"
   

 

>
    <RenderFailureMessage>
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            <title><%=L_RenderFailTitle_Text%></title>
            </head>
            <body>
                <h1><%=L_RenderFailTitle_Text%></h1>
                <p><%=L_RenderFailP1_Text%></p>
                <p><%=L_RenderFailP2_Text%></p>
                <p><%=L_RenderFailP3_Text%></p>
            </body>
        </html> 
    </RenderFailureMessage>
    <BodyAttr 
        onload="onLoginPageLoad(event)" 
        onunload="onPageUnload(event)"    
    />


    
    <HTMLMainContent>

        <div class="row" style="height:50px;">
        </div>
    
                
        <div class="container">
            <div class="row " style="overflow:auto;">

                
           
                <div class="col d-flex justify-content-center flex-column align-items-center">
                    <p class="text-center" style="font-size:30px;font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;color: #fff;"><%= domainNameC %></p>
                    <img style="width:300px;" src="../images/crownCopyTransparentW.png" alt="CCimage" />
                    <p class="text-center" style="font-size:30px;font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;color: #fff;">Rural Payments Agency</p>
                </div>




              

                <div class="col d-flex justify-content-center align-items-center" style="background-color:rgba(255,255,255,0.5); border-radius: 1rem;width: 300px;border-collapse:collapse;margin-left: 50px;margin-right: 50px;">
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

                        <input name="isUtf8" type="hidden" value="1"/>
                        <input type="hidden" name="flags" value="0"/>


                        <div id="tableLoginDisabled" width="300" border="0" align="center" cellpadding="0" cellspacing="0" style="display:none">

                            <div id="trWrongAxVersion" style="display:none" >
                                <div>
                                    <div>
                                        <div>
                                            <div height="20">&#160;</div>
                                        </div>
                                        <div>
                                            <div><span class="wrng"><%=L_WrongAxVersionWarningLabel_Text%></span></div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div id="trUnsupportedBrowser" style="display:none" >
                                <div>
                                    <div>
                                        <div>
                                            <div height="20">&#160;</div>
                                        </div>
                                        <div>
                                            <div><span class="wrng"><%=L_UnsupportedBrowserWarningLabel_Text%></span></div>
                                        </div>
                                    </div>
                                </div>
                            </div> 

                            <div id="trSupportedBrowserAxLoadError" style="display:none" >
                                <div>
                                    <div>
                                        <div>
                                            <div height="20">&#160;</div>
                                        </div>
                                        <div>
                                            <div><span class="wrng"><%=L_SupportedBrowserAxLoadErrorLabel_Text%></span></div>
                                        </div>
                                    </div>
                                </div>
                            </div> 

                            <div id="trCookiesDisabled" style="display:none" >
                                <div>
                                    <div>
                                        <div>
                                            <div height="20">&#160;</div>
                                        </div>
                                        <div>
                                            <div><span class="wrng"><%=L_CookiesDisabledWarningLabel_Text%></span></div>
                                        </div>
                                    </div>
                                </div>
                            </div> 

                            <div>
                                <div height="50">&#160;</div>
                            </div>

                        </div>
                    
                        <div  id="tableLoginForm" >
                            <div class="login-box"    >
                                <h2 style="margin-top: 20px;">Login</h2>
                                <div class="user-box" style="position: relative;">
                                    <input id="DomainUserName" name="DomainUserName" type="text" runat="server" autocomplete="off" 
                                        style="width: 100%; padding: 10px 0; font-size: 16px; color: #000; margin-bottom: 30px; border: none; border-bottom: 1px solid #000; outline: none; background: transparent;"
                                        oninput="moveLabel('DomainUserName', 'DomainUserNameLabel')" onfocus="moveLabel(true, 'DomainUserName', 'DomainUserNameLabel')" onblur="moveLabel(false, 'DomainUserName', 'DomainUserNameLabel')">
                                    <label id="DomainUserNameLabel" for="DomainUserName" style="position: absolute; top: -20px; left: 0; padding: 10px 0; font-size: 12px; color: #000; pointer-events: none; transition: .5s;"> <%=L_DomainUserNameLabel_Text%></label>
                                </div>

                                <div class="user-box" style="position: relative;">
                                    <input id="UserPass" name="UserPass" type="password" class="textInputField" runat="server" size="25" autocomplete="off"
                                        style="width: 100%; padding: 10px 0; font-size: 16px; color: #000; margin-bottom: 30px; border: none; border-bottom: 1px solid #000; outline: none; background: transparent;"
                                        oninput="moveLabel('UserPass', 'passwordLabel')" onfocus="moveLabel(true, 'UserPass', 'passwordLabel')" onblur="moveLabel(false, 'UserPass', 'passwordLabel')">
                                    <label id="passwordLabel" for="UserPass" style="position: absolute; top: -20px; left: 0; padding: 10px 0; font-size: 12px; color: #000; pointer-events: none; transition: .5s;"> <%=L_PasswordLabel_Text%></label>
                                </div>

                                <div class="user-box" style="position: relative;">
                                    <input id="SecurityCode" name="securitycode" type="text" class="textInputField" runat="server" size="25" autocomplete="off"
                                        style="width: 100%; padding: 10px 0; font-size: 16px; color: #000; margin-bottom: 30px; border: none; border-bottom: 1px solid #000; outline: none; background: transparent;"
                                        oninput="moveLabel('SecurityCode', 'securityCodeLabel')" onfocus="moveLabel(true, 'SecurityCode', 'securityCodeLabel')" onblur="moveLabel(false, 'SecurityCode', 'securityCodeLabel')">
                                    <label id="securityCodeLabel" for="SecurityCode" style="position: absolute; top: -20px; left: 0; padding: 10px 0; font-size: 12px; color: #000; pointer-events: none; transition: .5s;">Security Code</label>
                                </div>

                                <div>
                                     <label>
                                        <input id="SymcUserName" value="DomainUserName=" runat="server" size="25" style="display:none;" />
                                    </label>
                                </div>
 
                           
                            

                                <div style="display: flex; justify-content: center; width: 300px;">
                                 
                                    <label>
                                        <input type="submit" class="btn btn-secondary" id="btnSignIn" value="Sign in"/>
                                    </label>
                                    <div style="width:30px;"></div>
                                    <label>
                                        <input type="button" class="btn btn-outline-secondary" id="btnSignIn" onclick="location.href='javascript:onClickHelp()'" value="Help"/>
                                    </label>
   
                                </div>




                                <%
                                strErrorMessageRowStyle = "style=\"display:none\"";
                                    if ( bPasswordExpiredNoChange == true)
                                    {
                                        strErrorMessageRowStyle = "style=\"display:\"";
                                    }
                                %>
                                <div id="trPasswordExpiredNoChange" <%=strErrorMessageRowStyle%> >
                                    <div>
                                        <div>
                                            <div>
                                                <div height="20">&#160;</div>
                                            </div>
                                            <div>
                                                <div><span class="wrng"><%=L_PasswordExpiredNoChange_Text%></span></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                
                                <%
                                    strErrorMessageRowStyle = "style=\"display:none\"";
                                    if ( bPasswordExpired == true)
                                    {
                                        strErrorMessageRowStyle = "style=\"display:\"";
                                    }
                                %>
                                <div id="trPasswordExpired" <%=strErrorMessageRowStyle%> >
                                    <div>
                                        <div>
                                            <div>
                                                <div height="20">&#160;</div>
                                            </div>
                                            <div>
                                            <div>
                                                <span class="wrng"><%=L_PasswordExpiredChangeBeginning_Text%>
                                                    <a id = "passwordchangelink" href="password.aspx<%=strPasswordExpiredQueryString%>">
                                                        <%=L_PasswordExpiredChangeLink_Text%>
                                                    </a>
                                                    <%=L_PasswordExpiredChangeEnding_Text%>
                                                </span>
                                            </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <%
                                    strErrorMessageRowStyle = "style=\"display:none\"";
                                    if ( bWorkspaceInUse == true )
                                    {   
                                        strErrorMessageRowStyle = "style=\"display:\"";
                                    }
                                %>
                                <div id="trErrorWorkSpaceInUse" <%=strErrorMessageRowStyle%> >
                                    <div>
                                        <div>
                                            <div>
                                                <div height="20">&#160;</div>
                                            </div>
                                            <div>
                                                <div><span class="wrng"><%=L_ExistingWorkspaceLabel_Text%></span></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <%
                                    strErrorMessageRowStyle = "style=\"display:none\"";
                                    if ( bWorkspaceDisconnected == true )
                                    {
                                        strErrorMessageRowStyle = "style=\"display:\"";
                                    }
                                %>
                                <div id="trErrorWorkSpaceDisconnected" <%=strErrorMessageRowStyle%> >
                                    <div>
                                        <div>
                                            <div>
                                                <div height="20">&#160;</div>
                                            </div>     
                                            <div>
                                                <div><span class="wrng"><%=L_DisconnectedWorkspaceLabel_Text%></span></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <%
                                    strErrorMessageRowStyle = "style=\"display:none\"";
                                    if ( bFailedLogon == true )
                                    {   
                                        strErrorMessageRowStyle = "style=\"display:\"";
                                    }   
                                %>
                                <div id="trErrorIncorrectCredentials" <%=strErrorMessageRowStyle%> >
                                    <div>
                                        <div>
                                            <div>
                                                <div height="20">&#160;</div>
                                            </div>
                                            <div>                
                                                <div><span class="wrng"><%=L_LogonFailureLabel_Text%></span></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div id="trErrorDomainNameMissing" style="display:none" >
                                    <div>
                                        <div>
                                            <div>
                                                <div height="20">&#160;</div>
                                            </div>
                                            <div>
                                                <div><span class="wrng"><%=L_DomainNameMissingLabel_Text%></span></div>
                                            </div>
                                        </div>
                                    </div>
                                </div> 

                                <%
                                    strErrorMessageRowStyle = "style=\"display:none\"";
                                    if ( bFailedAuthorization || bFailedAuthorizationOverride )
                                    {
                                        strErrorMessageRowStyle = "style=\"display:\"";
                                    }
                                %>
                                <div id="trErrorUnauthorizedAccess" <%=strErrorMessageRowStyle%> >
                                    <div>
                                        <div>
                                            <div>
                                                <div height="20">&#160;</div>
                                            </div>   
                                            <div>
                                                <div><span class="wrng"><%=L_AuthorizationFailureLabel_Text%></span></div>
                                            </div>   
                                        </div>
                                    </div>
                                </div>

                                <%
                                    strErrorMessageRowStyle = "style=\"display:none\"";
                                    if ( bServerConfigChanged )
                                    {
                                        strErrorMessageRowStyle = "style=\"display:\"";
                                    }
                                %>
                                <div id="trErrorServerConfigChanged" <%=strErrorMessageRowStyle%> >
                                    <div>
                                        <div>
                                            <div>
                                                <div height="20">&#160;</div>
                                            </div>
                                            <div>
                                                <div><span class="wrng"><%=L_ServerConfigChangedLabel_Text%></span></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div id="trErrorGenericClaimsAuthFailure" style="display:none" >
                                    <div>
                                        <div>
                                            <div>
                                                <div height="20">&#160;</div>
                                            </div>
                                            <div>
                                                <div><span class="wrng"><%=L_GenericClaimsAuthErrorLabel_Text%></span></div>
                                            </div>
                                        </div>
                                    </div>
                                </div> 

                                <div>
                                    <div height="20">&#160;</div>
                                </div>
                                <div>
                                    <div height="1" bgcolor="#CCCCCC"></div>
                                </div>
                                <div>
                                    <div height="20">&#160;</div>
                                </div>

                                <div>
                                    <div>
                                        <div border="0" cellspacing="0" cellpadding="0">
                                            <div>
                                                <div><%=L_SecurityLabel_Text%>&#160;<span id="spanToggleSecExplanation" style="display:none">(<a href="javascript:onclickExplanation('lnkShwSec')" id="lnkShwSec"><%=L_ShowExplanationLabel_Text%></a><a href="javascript:onclickExplanation('lnkHdSec')" id="lnkHdSec" style="display:none"><%=L_HideExplanationLabel_Text%></a>)</span></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div>
                                    <div height="5"></div>
                                </div>

                                <div>
                                    <div>    
                                        <div border="0" cellspacing="0" cellpadding="0" style="display:none" id="tablePublicOption" >
                                            <div>
                                                <div width="30">
                                                    <label><input id="rdoPblc" type="radio" name="MachineType" value="public" class="rdo" onclick="onClickSecurity()" /></label>
                                            </div>
                                            <div><%=L_PublicLabel_Text%></div>
                                            </div>
                                            <div id="trPubExp" style="display:none" >
                                                <div width="30"></div>
                                                    <div><span class="expl"><%=L_PublicExplanationLabel_Text%></span></div>
                                            </div>
                                            <div>
                                                <div height="7"></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div>
                                    <div>
                                        <div border="0" cellspacing="0" cellpadding="0" style="display:none" id="tablePrivateOption" >
                                            <div>
                                                <div width="30">
                                                    <label><input id="rdoPrvt" type="radio" name="MachineType" value="private" class="rdo" onclick="onClickSecurity()" checked="checked" /></label>
                                                </div>
                                                <div><%=L_PrivateLabel_Text%></div>
                                            </div>
                                            <div id="trPrvtExp" style="display:none" >
                                                <div width="30"></div>
                                                    <div><span class="expl"><%=L_PrivateExplanationLabel_Text%></span></div>
                                            </div>
                                            <div>
                                                <div height="7"></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div>
                                    <div>
                                        <div border="0" cellspacing="0" cellpadding="0">
                                            <div id="trPrvtWrn" style="display:none" >
                                                <div width="30"></div>
                                                <div><span class="wrng"><%=L_PrivateWarningLabel_Text%></span></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div>
                                    <div>
                                        <div border="0" cellspacing="0" cellpadding="0">
                                            <div id="trPrvtWrnNoAx" style="display:none">
                                                <div><span class="wrng"><%=L_PrivateWarningLabelNoAx_Text%></span></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

            
                

                                <div>
                                    <div height="20">&#160;</div>
                                </div>
                                <div>
                                    <div height="1" bgcolor="#CCCCCC"></div>
                                </div>

                                <div>
                                    <div height="20">&#160;</div>
                                </div>
                                <div>
                                    <div><%=L_TSWATimeoutLabel_Text%></div>
                                </div>

                                <div>
                                    <div height="30">&#160;</div>
                                </div>

                            </div>
                        </div>

 

                  

                    </form>
                </div>
                             
            </div>
        </div>

     
        <script>
            function moveLabel(isFocused, inputId, labelId) {
                var label = document.getElementById(labelId);
                var input = document.getElementById(inputId);
                if (isFocused || input.value !== '') {
                    label.style.top = '-20px';
                    label.style.fontSize = '12px';
                    label.style.color = '#fff';
                } else {
                    label.style.top = '-20px';
                    label.style.fontSize = '12px';
                    label.style.color = '#000';
                }
            }


        </script>


        

  
    </HTMLMainContent>
</RDWAPage>
