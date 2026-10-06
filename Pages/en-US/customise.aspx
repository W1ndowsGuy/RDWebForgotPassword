<%@ Page Language="C#" Debug="false" ResponseEncoding="utf-8" ContentType="text/html" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Xml.Linq" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.DirectoryServices" %>
<%@ Import Namespace="System.DirectoryServices.ActiveDirectory" %>
<%@ Import Namespace="Microsoft.TerminalServices.Publishing.Portal.FormAuthentication" %>
<script runat="server">
    public string[] Titles = { "", "Maintenence Outage", "HELP", "Security" };
    public string[] Texts = { "", "Notifications for outages will also be here in future", "If you having any issues with login please click 'Help'", "Warning: By logging in to this web page, you confirm that this computer complies with your organization's security policy." };
    public string[] Expires = { "", "", "", "" };
    public string Status = "";
    public string CarouselColour = "#2d1450";
    public string EnvironmentName = "";
    public int PasswordExpiryDays = 30;
    public bool PasswordRecoveryEnabled = false;
    public string SmtpServer = "";
    public int SmtpPort = 25;
    public string FromAddress = "";
    public int RecoveryCodeExpiryMinutes = 10;
    public string[] States = { "", "NO EXPIRY", "NO EXPIRY", "NO EXPIRY" };

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!HttpContext.Current.User.Identity.IsAuthenticated) { Response.Redirect("login.aspx?ReturnUrl=" + HttpUtility.UrlEncode(Request.Path)); return; }
        if (!IsWebAdmin()) { Response.StatusCode = 403; Response.End(); return; }
        if (Request.HttpMethod == "POST") {
            string action=Request.Form["action"]??"save";
            if(action.StartsWith("reset-")) ResetOne(action.Substring(6));
            else Save();
        }
        LoadConfig();
    }

    string UserName()
    {
        try { TSFormAuthTicketInfo t = new TSFormAuthTicketInfo(HttpContext.Current); string a=t.DomainUserName??""; return a.Contains("@")?a.Split('@')[0]:(a.Contains("\\")?a.Split('\\')[1]:a); }
        catch { string a=HttpContext.Current.User.Identity.Name??""; return a.Contains("\\")?a.Split('\\')[1]:a; }
    }

    bool IsWebAdmin()
    {
        try {
            string fqdn=Domain.GetCurrentDomain().Name;
            using(DirectoryEntry root=new DirectoryEntry("LDAP://"+fqdn))
            using(DirectorySearcher ds=new DirectorySearcher(root)) {
                ds.Filter="(&(objectCategory=person)(objectClass=user)(sAMAccountName="+UserName().Replace("(","\\28").Replace(")","\\29")+"))";
                ds.PropertiesToLoad.Add("distinguishedName"); SearchResult u=ds.FindOne();
                if(u==null||u.Properties["distinguishedName"].Count==0)return false;
                using(DirectorySearcher gs=new DirectorySearcher(root)) {
                    gs.Filter="(&(objectCategory=group)(sAMAccountName=webadmins)(member:1.2.840.113556.1.4.1941:="+u.Properties["distinguishedName"][0].ToString().Replace("(","\\28").Replace(")","\\29")+"))";
                    return gs.FindOne()!=null;
                }
            }
        } catch { return false; }
    }

    string ConfigPath(){ return Server.MapPath("../config/carousel.xml"); }
    string TemplatePath(){ return Server.MapPath("../config/carousel.template.xml"); }
    void EnsureConfig()
    {
        string path=ConfigPath();
        if(!System.IO.File.Exists(path)) {
            System.IO.Directory.CreateDirectory(System.IO.Path.GetDirectoryName(path));
            if(System.IO.File.Exists(TemplatePath())) System.IO.File.Copy(TemplatePath(),path,false);
        }
    }
    string HistoryPath(){ return Server.MapPath("../config/customise-history.xml"); }

    void AddHistory(string action, System.Collections.Generic.List<XElement> changes)
    {
        try {
            if(changes==null||changes.Count==0) return;
            string path=HistoryPath(); Directory.CreateDirectory(Path.GetDirectoryName(path));
            XDocument h=File.Exists(path)?XDocument.Load(path):new XDocument(new XElement("history"));
            XElement entry=new XElement("entry",new XAttribute("time",DateTime.Now.ToString("o")),new XAttribute("user",UserName()),new XAttribute("action",action));
            foreach(XElement change in changes) entry.Add(change);
            h.Root.AddFirst(entry); h.Save(path);
        } catch { }
    }

    XElement Change(string field,string before,string after,string message)
    {
        XElement x=new XElement("change",new XAttribute("field",field),new XElement("before",before??""),new XElement("after",after??""));
        if(!String.IsNullOrEmpty(message)) x.Add(new XElement("message",message));
        return x;
    }

    void LoadConfig()
    {
        try {
            EnsureConfig();
            if(!System.IO.File.Exists(ConfigPath())) return;
            XDocument d=XDocument.Load(ConfigPath());
            XElement env=d.Root.Element("environmentName"); if(env!=null) EnvironmentName=env.Value;
            XElement pwd=d.Root.Element("passwordExpiryDays"); int pd; if(pwd!=null&&Int32.TryParse(pwd.Value,out pd)&&pd>0) PasswordExpiryDays=pd;
            XElement recovery=d.Root.Element("passwordRecovery");
            if(recovery!=null) {
                bool re; XElement enabled=recovery.Element("enabled"); if(enabled!=null&&Boolean.TryParse(enabled.Value,out re)) PasswordRecoveryEnabled=re;
                XElement smtp=recovery.Element("smtpServer"); if(smtp!=null) SmtpServer=smtp.Value.Trim();
                int sp; XElement port=recovery.Element("smtpPort"); if(port!=null&&Int32.TryParse(port.Value,out sp)&&sp>=1&&sp<=65535) SmtpPort=sp;
                XElement from=recovery.Element("fromAddress"); if(from!=null) FromAddress=from.Value.Trim();
                int ce; XElement expiry=recovery.Element("codeExpiryMinutes"); if(expiry!=null&&Int32.TryParse(expiry.Value,out ce)&&ce>=1&&ce<=60) RecoveryCodeExpiryMinutes=ce;
            }
            XElement colour=d.Root.Element("colour");
            if(colour!=null&&!String.IsNullOrWhiteSpace(colour.Value)) {
                string cv=colour.Value.Trim();
                if(cv.StartsWith("#")) CarouselColour=cv;
            }
            for(int i=1;i<=3;i++){ XElement s=d.Root.Elements("slide").FirstOrDefault(x=>(string)x.Attribute("id")==i.ToString()); if(s==null)continue; Titles[i]=(string)s.Element("title")??Titles[i]; Texts[i]=(string)s.Element("text")??Texts[i]; Expires[i]=(string)s.Attribute("expires")??"";
                DateTime exp;
                if(String.IsNullOrWhiteSpace(Expires[i])) States[i]="NO EXPIRY";
                else if(DateTime.TryParse(Expires[i], null, DateTimeStyles.RoundtripKind, out exp))
                    States[i]=exp > DateTime.Now ? "ACTIVE" : "EXPIRED - default currently displayed";
                else States[i]="INVALID EXPIRY";
            }
        } catch(Exception ex){ Status="Could not read configuration: "+ex.Message; }
    }

    void ResetOne(string item)
    {
        try {
            LoadConfig();
            string oldEnv=EnvironmentName, oldColour=CarouselColour; int oldPwd=PasswordExpiryDays;
            bool oldRecoveryEnabled=PasswordRecoveryEnabled; string oldSmtpServer=SmtpServer, oldFromAddress=FromAddress; int oldSmtpPort=SmtpPort, oldCodeExpiry=RecoveryCodeExpiryMinutes;
            string[] oldTitles=(string[])Titles.Clone(), oldTexts=(string[])Texts.Clone(), oldExpires=(string[])Expires.Clone();
            if(item=="environment") EnvironmentName="";
            else if(item=="password") PasswordExpiryDays=30;
            else if(item=="colour") CarouselColour="#2d1450";
            else if(item=="recovery") { PasswordRecoveryEnabled=false; SmtpServer=""; SmtpPort=25; FromAddress=""; RecoveryCodeExpiryMinutes=10; }
            else if(item.StartsWith("slide")) {
                int i; if(!Int32.TryParse(item.Substring(5),out i)||i<1||i>3) throw new Exception("Invalid slide.");
                string[] dt={ "", "Maintenence Outage", "HELP", "Security" };
                string[] dm={ "", "Notifications for outages will also be here in future", "If you having any issues with login please click 'Help'", "Warning: By logging in to this web page, you confirm that this computer complies with your organization's security policy." };
                Titles[i]=dt[i]; Texts[i]=dm[i]; Expires[i]="";
            } else throw new Exception("Unknown setting.");

            XDocument d=new XDocument(new XElement("carousel",new XElement("environmentName",EnvironmentName),new XElement("passwordExpiryDays",PasswordExpiryDays),new XElement("colour",CarouselColour),new XElement("passwordRecovery",new XElement("enabled",PasswordRecoveryEnabled.ToString().ToLowerInvariant()),new XElement("smtpServer",SmtpServer),new XElement("smtpPort",SmtpPort),new XElement("fromAddress",FromAddress),new XElement("codeExpiryMinutes",RecoveryCodeExpiryMinutes))));
            for(int i=1;i<=3;i++) d.Root.Add(new XElement("slide",new XAttribute("id",i),new XAttribute("expires",Expires[i]??""),new XElement("title",Titles[i]),new XElement("text",Texts[i])));
            string path=ConfigPath(); Directory.CreateDirectory(Path.GetDirectoryName(path)); d.Save(path);
            var changes=new System.Collections.Generic.List<XElement>();
            if(oldEnv!=EnvironmentName) changes.Add(Change("Environment name",oldEnv,EnvironmentName,""));
            if(oldPwd!=PasswordExpiryDays) changes.Add(Change("Password expiry days",oldPwd.ToString(),PasswordExpiryDays.ToString(),""));
            if(oldColour!=CarouselColour) changes.Add(Change("Carousel colour",oldColour,CarouselColour,""));
            if(oldRecoveryEnabled!=PasswordRecoveryEnabled) changes.Add(Change("Password recovery enabled",oldRecoveryEnabled.ToString(),PasswordRecoveryEnabled.ToString(),""));
            if(oldSmtpServer!=SmtpServer) changes.Add(Change("SMTP server",oldSmtpServer,SmtpServer,""));
            if(oldSmtpPort!=SmtpPort) changes.Add(Change("SMTP port",oldSmtpPort.ToString(),SmtpPort.ToString(),""));
            if(oldFromAddress!=FromAddress) changes.Add(Change("Recovery from address",oldFromAddress,FromAddress,""));
            if(oldCodeExpiry!=RecoveryCodeExpiryMinutes) changes.Add(Change("Recovery code expiry minutes",oldCodeExpiry.ToString(),RecoveryCodeExpiryMinutes.ToString(),""));
            for(int i=1;i<=3;i++){
                if(oldTitles[i]!=Titles[i]) changes.Add(Change("Slide "+i+" title",oldTitles[i],Titles[i],""));
                if(oldTexts[i]!=Texts[i]) changes.Add(Change("Slide "+i+" message",oldTexts[i],Texts[i],Texts[i]));
                if(oldExpires[i]!=Expires[i]) changes.Add(Change("Slide "+i+" expiry",oldExpires[i],Expires[i],""));
            }
            AddHistory("Reset "+item,changes);
            Status="Setting reset to default.";
        } catch(Exception ex){ Status="Reset failed: "+ex.Message; }
    }

    void Save()
    {
        try {
            LoadConfig();
            string oldEnv=EnvironmentName, oldColour=CarouselColour; int oldPwd=PasswordExpiryDays;
            bool oldRecoveryEnabled=PasswordRecoveryEnabled; string oldSmtpServer=SmtpServer, oldFromAddress=FromAddress; int oldSmtpPort=SmtpPort, oldCodeExpiry=RecoveryCodeExpiryMinutes;
            string[] oldTitles=(string[])Titles.Clone(), oldTexts=(string[])Texts.Clone(), oldExpires=(string[])Expires.Clone();
            string colour=Request.Form["carouselColour"]??"#2d1450";
            bool recoveryEnabled=(Request.Form["passwordRecoveryEnabled"]=="on");
            string smtpServer=(Request.Form["smtpServer"]??"").Trim();
            string fromAddress=(Request.Form["fromAddress"]??"").Trim();
            int smtpPort; if(!Int32.TryParse(Request.Form["smtpPort"]??"25",out smtpPort)||smtpPort<1||smtpPort>65535) throw new Exception("SMTP port must be between 1 and 65535.");
            int codeExpiry; if(!Int32.TryParse(Request.Form["recoveryCodeExpiryMinutes"]??"10",out codeExpiry)||codeExpiry<1||codeExpiry>60) throw new Exception("Recovery code expiry must be between 1 and 60 minutes.");
            if(recoveryEnabled && String.IsNullOrWhiteSpace(smtpServer)) throw new Exception("SMTP server is required when password recovery is enabled.");
            if(recoveryEnabled && (String.IsNullOrWhiteSpace(fromAddress)||!fromAddress.Contains("@"))) throw new Exception("A valid From address is required when password recovery is enabled.");
            string environment=(Request.Form["environmentName"]??"").Trim();
            int passwordDays; if(!Int32.TryParse(Request.Form["passwordExpiryDays"]??"30",out passwordDays)||passwordDays<1||passwordDays>3650) throw new Exception("Password expiry days must be between 1 and 3650.");
            if(!System.Text.RegularExpressions.Regex.IsMatch(colour, "^#[0-9A-Fa-f]{6}$")) throw new Exception("Carousel colour must be a valid colour.");
            XDocument d=new XDocument(new XElement("carousel",new XElement("environmentName",environment),new XElement("passwordExpiryDays",passwordDays),new XElement("colour",colour),new XElement("passwordRecovery",new XElement("enabled",recoveryEnabled.ToString().ToLowerInvariant()),new XElement("smtpServer",smtpServer),new XElement("smtpPort",smtpPort),new XElement("fromAddress",fromAddress),new XElement("codeExpiryMinutes",codeExpiry))));
            string[] newTitles={ "", "", "", "" }, newTexts={ "", "", "", "" }, newExpires={ "", "", "", "" };
            for(int i=1;i<=3;i++){
                string title=Request.Form["title"+i]??"", text=Request.Form["text"+i]??"", raw=Request.Form["expires"+i]??"", expiry="";
                DateTime dt; if(!String.IsNullOrWhiteSpace(raw)){if(!DateTime.TryParse(raw,out dt))throw new Exception("Slide "+i+" has an invalid expiry date/time.");expiry=dt.ToString("o");}
                newTitles[i]=title; newTexts[i]=text; newExpires[i]=expiry;
                d.Root.Add(new XElement("slide",new XAttribute("id",i),new XAttribute("expires",expiry),new XElement("title",title),new XElement("text",text)));
            }
            string path=ConfigPath(); Directory.CreateDirectory(Path.GetDirectoryName(path)); d.Save(path);
            var changes=new System.Collections.Generic.List<XElement>();
            if(oldEnv!=environment) changes.Add(Change("Environment name",oldEnv,environment,""));
            if(oldPwd!=passwordDays) changes.Add(Change("Password expiry days",oldPwd.ToString(),passwordDays.ToString(),""));
            if(oldColour!=colour) changes.Add(Change("Carousel colour",oldColour,colour,""));
            if(oldRecoveryEnabled!=recoveryEnabled) changes.Add(Change("Password recovery enabled",oldRecoveryEnabled.ToString(),recoveryEnabled.ToString(),""));
            if(oldSmtpServer!=smtpServer) changes.Add(Change("SMTP server",oldSmtpServer,smtpServer,""));
            if(oldSmtpPort!=smtpPort) changes.Add(Change("SMTP port",oldSmtpPort.ToString(),smtpPort.ToString(),""));
            if(oldFromAddress!=fromAddress) changes.Add(Change("Recovery from address",oldFromAddress,fromAddress,""));
            if(oldCodeExpiry!=codeExpiry) changes.Add(Change("Recovery code expiry minutes",oldCodeExpiry.ToString(),codeExpiry.ToString(),""));
            for(int i=1;i<=3;i++){
                if(oldTitles[i]!=newTitles[i]) changes.Add(Change("Slide "+i+" title",oldTitles[i],newTitles[i],""));
                if(oldTexts[i]!=newTexts[i]) changes.Add(Change("Slide "+i+" message",oldTexts[i],newTexts[i],newTexts[i]));
                if(oldExpires[i]!=newExpires[i]) changes.Add(Change("Slide "+i+" expiry",oldExpires[i],newExpires[i],""));
            }
            AddHistory("Saved settings",changes);
            Status=changes.Count==0?"No settings were changed.":"Carousel settings saved.";
        } catch(Exception ex){ Status="Save failed: "+ex.Message; }
    }
</script>
<!doctype html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>RDWeb Carousel Customisation</title><link href="../css/bootstrap-5.3.8.min.css" rel="stylesheet"/>
<style>body{background:url('../images/EngOne.jpg') center center/cover fixed no-repeat;min-height:100vh}.panel{background:rgba(255,255,255,.92);border-radius:1rem}.form-control{background:rgba(255,255,255,.95)}</style></head>
<body><main class="container py-4"><div class="panel p-4 shadow"><div class="d-flex justify-content-between align-items-center mb-4"><div><h1 class="h3 mb-1">Carousel Customisation</h1><p class="text-muted mb-0">Custom messages automatically revert to the built-in defaults after their expiry time.</p></div><div class="d-flex gap-2"><a class="btn btn-outline-primary" href="customise-history.aspx">History</a><a class="btn btn-outline-secondary" href="default.aspx">Back to RDWeb</a></div></div>
<% if(!String.IsNullOrEmpty(Status)){ %><div class="alert alert-info"><%=HttpUtility.HtmlEncode(Status)%></div><% } %>
<form method="post" action="customise.aspx">
<div class="card mb-3"><div class="card-body"><h2 class="h5">Environment settings</h2>
<div class="mb-3"><label class="form-label" for="environmentName">Display name</label><div class="d-flex gap-2 align-items-start"><input class="form-control" style="max-width:420px" id="environmentName" name="environmentName" value="<%=HttpUtility.HtmlAttributeEncode(EnvironmentName)%>" maxlength="100"/><button class="btn btn-outline-secondary text-nowrap" type="submit" name="action" value="reset-environment">Reset to default</button></div><div class="form-text">Optional. Default uses the automatically detected domain name.</div></div>
<div><label class="form-label" for="passwordExpiryDays">Password expiry days</label><div class="d-flex gap-2 align-items-start"><input class="form-control" style="max-width:160px" type="number" min="1" max="3650" id="passwordExpiryDays" name="passwordExpiryDays" value="<%=PasswordExpiryDays%>"/><button class="btn btn-outline-secondary text-nowrap" type="submit" name="action" value="reset-password">Reset to default</button></div><div class="form-text">Used to calculate the password expiry date shown to users. Default: 30 days.</div></div>
</div></div>
<div class="card mb-3"><div class="card-body"><div class="d-flex justify-content-between align-items-center"><h2 class="h5">Password recovery</h2><button class="btn btn-outline-secondary text-nowrap" type="submit" name="action" value="reset-recovery">Reset to default</button></div>
<div class="form-check form-switch mb-3"><input class="form-check-input" type="checkbox" role="switch" id="passwordRecoveryEnabled" name="passwordRecoveryEnabled" <%=PasswordRecoveryEnabled ? "checked" : ""%>><label class="form-check-label" for="passwordRecoveryEnabled">Enable password recovery</label></div>
<div class="row g-3"><div class="col-md-8"><label class="form-label" for="smtpServer">SMTP relay</label><input class="form-control" id="smtpServer" name="smtpServer" value="<%=HttpUtility.HtmlAttributeEncode(SmtpServer)%>" maxlength="255" placeholder="mailrelay.example.local"/></div><div class="col-md-4"><label class="form-label" for="smtpPort">SMTP port</label><input class="form-control" type="number" min="1" max="65535" id="smtpPort" name="smtpPort" value="<%=SmtpPort%>"/></div>
<div class="col-md-8"><label class="form-label" for="fromAddress">From address</label><input class="form-control" type="email" id="fromAddress" name="fromAddress" value="<%=HttpUtility.HtmlAttributeEncode(FromAddress)%>" maxlength="254" placeholder="rdweb@example.org"/></div><div class="col-md-4"><label class="form-label" for="recoveryCodeExpiryMinutes">Code expiry (minutes)</label><input class="form-control" type="number" min="1" max="60" id="recoveryCodeExpiryMinutes" name="recoveryCodeExpiryMinutes" value="<%=RecoveryCodeExpiryMinutes%>"/></div></div>
<div class="form-text mt-3">Stage 1 configuration only. Enabling this setting does not yet expose password reset or send email. SMTP credentials and VIP/RADIUS secrets are not stored here.</div>
</div></div>
<div class="card mb-3"><div class="card-body"><h2 class="h5">Carousel colour</h2>
<div class="d-flex align-items-center gap-3"><input type="color" class="form-control form-control-color" id="carouselColour" name="carouselColour" value="<%=HttpUtility.HtmlAttributeEncode(CarouselColour)%>" title="Choose carousel colour"/><button class="btn btn-outline-secondary text-nowrap" type="submit" name="action" value="reset-colour">Reset to default</button><span class="text-muted">Choose the carousel colour for this environment.</span></div>
</div></div>
<% for(int i=1;i<=3;i++){ %><div class="card mb-3"><div class="card-body"><div class="d-flex justify-content-between align-items-center"><h2 class="h5">Slide <%=i%></h2><span class="badge <%= States[i].StartsWith("EXPIRED") ? "bg-secondary" : (States[i]=="ACTIVE" ? "bg-success" : "bg-info text-dark") %>"><%=HttpUtility.HtmlEncode(States[i])%></span></div>
<div class="mb-3"><label class="form-label" for="title<%=i%>">Title</label><input class="form-control" id="title<%=i%>" name="title<%=i%>" value="<%=HttpUtility.HtmlAttributeEncode(Titles[i])%>" maxlength="120"/></div>
<div class="mb-3"><label class="form-label" for="text<%=i%>">Message</label><textarea class="form-control" id="text<%=i%>" name="text<%=i%>" rows="3" maxlength="1000"><%=HttpUtility.HtmlEncode(Texts[i])%></textarea></div>
<div><label class="form-label" for="expires<%=i%>">Expiry date/time (optional)</label><input class="form-control" style="max-width:320px" type="datetime-local" id="expires<%=i%>" name="expires<%=i%>" value="<% DateTime ed; if(DateTime.TryParse(Expires[i],null,DateTimeStyles.RoundtripKind,out ed)){ %><%=ed.ToString("yyyy-MM-ddTHH:mm")%><% } %>"/><div class="form-text">Leave blank to keep this message until it is changed.</div></div><div class="mt-3"><button class="btn btn-outline-secondary" type="submit" name="action" value="reset-slide<%=i%>">Reset this message to default</button></div>
</div></div><% } %>
<div class="d-flex gap-2"><button class="btn btn-primary" type="submit" name="action" value="save">Save settings</button></div></form></div></main></body></html>