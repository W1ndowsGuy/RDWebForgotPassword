<% @Page Language="C#" Debug="false" ResponseEncoding="utf-8" ContentType="text/html" %>
<% @Import Namespace="System " %>
<% @Import Namespace="System.Security" %>
<% @Import Namespace="Microsoft.TerminalServices.Publishing.Portal.FormAuthentication" %>
<% @Import Namespace="Microsoft.TerminalServices.Publishing.Portal" %>
<% @Import Namespace="System.Web.Security.AntiXss" %>
<script language="C#" runat=server>

    //
    // Customizable Text
    //
    string L_CompanyName_Text = "Work Resources";

    //
    // Localizable Text
    //
    const string L_DomainUserNameLabel_Text = "Domain\\user name:";
    const string L_OldPasswordLabel_Text = "Current password:";
    const string L_NewPasswordLabel_Text = "New password:";
    const string L_ConfirmNewPasswordLabel_Text = "Confirm new password:";
    const string L_PasswordChangedLabel_Text = "Your password has been successfully changed.";
    const string L_OKButton_Text = "OK";
    const string L_ComplexityFailureLabel_Text = "Your new password does not meet the length, complexity, or history requirements of your domain. Try choosing a different new password.";
    const string L_NewPasswordsDontMatchLabel_Text = "The entered passwords do not match.";
    const string L_BlankPasswordFailureLabel_Text = "Please enter a new password.";
    const string L_PasswordChangeGenericFailure_Text = "Your password cannot be changed. Please contact your administrator for assistance.";
    const string L_LogonFailureLabel_Text = "The user name or password that you entered is not valid. Try typing it again.";
    const string L_SubmitLabel_Text = "Submit";
    const string L_CancelLabel_Text = "Cancel";
    const string L_RenderFailTitle_Text = "Error: Unable to display RD Web Access";
    const string L_RenderFailP1_Text = "An unexpected error has occurred that is preventing this page from being displayed correctly.";
    const string L_RenderFailP2_Text = "Viewing this page in Internet Explorer with the Enhanced Security Configuration enabled can cause such an error.";
    const string L_RenderFailP3_Text = "Please try loading this page without the Enhanced Security Configuration enabled. If this error continues to be displayed, please contact your administrator.";
    
    //
    // Page Variables
    //
    public string strErrorMessageRowStyle;
    public string strButtonsRowStyle;
    public bool bFailedLogon = false, bPasswordMismatchFailure = false, bPasswordBlankFailure = false, bComplexityFailure = false, bGenericFailure = false, bSuccess = false;
    public string sHelpSourceServer, sLocalHelp;
    public Uri baseUrl;



    void Page_PreInit(object sender, EventArgs e)
    {

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
    }

    void Page_Load(object sender, EventArgs e)
    {
        string strPasswordChangeEnabled = ConfigurationManager.AppSettings["PasswordChangeEnabled"];

        if (strPasswordChangeEnabled == null || !(strPasswordChangeEnabled.Equals("true", StringComparison.CurrentCultureIgnoreCase)))
        {
            SafeRedirect(null);
        }
        
        if ( Request.QueryString != null )
        {
            NameValueCollection objQueryString = Request.QueryString;
            if ( objQueryString["Error"] != null )
            {
                if ( objQueryString["Error"].Equals("FailedLogon", StringComparison.CurrentCultureIgnoreCase) )
                {
                    bFailedLogon = true;
                }
                else if ( objQueryString["Error"].Equals("ComplexityFailed", StringComparison.CurrentCultureIgnoreCase) )
                {
                    bComplexityFailure = true;
                }
                else if (objQueryString["Error"].Equals("FailedBlankPassword", StringComparison.CurrentCultureIgnoreCase))
                {
                    bPasswordBlankFailure = true;
                }
                else if (objQueryString["Error"].Equals("FailedPasswordMatch", StringComparison.CurrentCultureIgnoreCase))
                {
                    bPasswordMismatchFailure = true;
                }
                else if (objQueryString["Error"].Equals("FailedGeneric", StringComparison.CurrentCultureIgnoreCase))
                {
                    bGenericFailure = true;
                }
                else if (objQueryString["Error"].Equals("PasswordSuccess", StringComparison.CurrentCultureIgnoreCase))
                {
                    bSuccess = true;
                }
            }
            if ( objQueryString["UserName"] != null )
            {
                DomainUserName.Value = SecurityElement.Escape(objQueryString["UserName"]); 
            }
            
            
        }
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
<!doctype html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Change password - <%=HttpUtility.HtmlEncode(L_CompanyName_Text)%></title><link href="../css/bootstrap-5.3.8.min.css" rel="stylesheet"/>
<style>body{min-height:100vh;background:url('../images/EngOne.jpg') center/cover fixed no-repeat}.panel{background:rgba(255,255,255,.88);border-radius:1rem;padding:2rem}.wrng{color:#b02a37}</style></head>
<body><div class="container py-5"><div class="panel mx-auto" style="max-width:900px"><h1 class="h2 mb-4">Change password</h1>
<form id="FrmLogin" name="FrmLogin" action="password.aspx" method="post">
<div class="mb-3"><label class="form-label"><%=L_DomainUserNameLabel_Text%></label><input id="DomainUserName" name="DomainUserName" type="text" runat="server" autocomplete="off" class="form-control"/></div>
<div class="mb-3"><label class="form-label"><%=L_OldPasswordLabel_Text%></label><input id="UserPass" name="UserPass" type="password" runat="server" autocomplete="off" class="form-control"/></div>
<div class="mb-3"><label class="form-label"><%=L_NewPasswordLabel_Text%></label><input id="NewUserPass" name="NewUserPass" type="password" runat="server" autocomplete="off" class="form-control"/></div>
<div class="mb-3"><label class="form-label"><%=L_ConfirmNewPasswordLabel_Text%></label><input id="ConfirmNewUserPass" name="ConfirmNewUserPass" type="password" runat="server" autocomplete="off" class="form-control"/></div>
<% if(bGenericFailure){%><div class="alert alert-danger"><%=L_PasswordChangeGenericFailure_Text%></div><%}%>
<% if(bPasswordBlankFailure){%><div class="alert alert-danger"><%=L_BlankPasswordFailureLabel_Text%></div><%}%>
<% if(bComplexityFailure){%><div class="alert alert-danger"><%=L_ComplexityFailureLabel_Text%></div><%}%>
<% if(bPasswordMismatchFailure){%><div class="alert alert-danger"><%=L_NewPasswordsDontMatchLabel_Text%></div><%}%>
<% if(bFailedLogon){%><div class="alert alert-danger"><%=L_LogonFailureLabel_Text%></div><%}%>
<% if(bSuccess){%><div class="alert alert-success"><%=L_PasswordChangedLabel_Text%></div><a class="btn btn-secondary" href="login.aspx"><%=L_OKButton_Text%></a><%}else{%>
<button type="submit" class="btn btn-secondary"><%=L_SubmitLabel_Text%></button><a class="btn btn-outline-secondary ms-2" href="login.aspx"><%=L_CancelLabel_Text%></a><%}%>
</form><hr class="my-4"/><h2 class="h4">Password Requirements</h2>
<p>When creating a new password, it must be at least 12 characters and include at least three of the following four character types:</p>
<ul><li>Uppercase letters (A-Z)</li><li>Lowercase letters (a-z)</li><li>Numbers (0-9)</li><li>Special characters (for example !, @, #, $, %)</li></ul>
<p class="mb-0">Avoid easily guessable information and common words. Use a unique password that you can remember securely.</p>
</div></div></body></html>