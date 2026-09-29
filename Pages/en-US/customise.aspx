<%@ Page Language="C#" Debug="false" ResponseEncoding="utf-8" ContentType="text/html" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Xml.Linq" %>
<%@ Import Namespace="System.DirectoryServices" %>
<%@ Import Namespace="System.DirectoryServices.ActiveDirectory" %>
<%@ Import Namespace="Microsoft.TerminalServices.Publishing.Portal.FormAuthentication" %>
<script runat="server">
    public string[] Titles = { "", "Maintenence Outage", "HELP", "Security" };
    public string[] Texts = { "", "Notifications for outages will also be here in future", "If you having any issues with login please click 'Help'", "Warning: By logging in to this web page, you confirm that this computer complies with your organization's security policy." };
    public string[] Expires = { "", "", "", "" };
    public string Status = "";
    public string CarouselColour = "#2d1450";
    public string[] States = { "", "NO EXPIRY", "NO EXPIRY", "NO EXPIRY" };

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!HttpContext.Current.User.Identity.IsAuthenticated) { Response.Redirect("login.aspx?ReturnUrl=" + HttpUtility.UrlEncode(Request.Path)); return; }
        if (!IsWebAdmin()) { Response.StatusCode = 403; Response.End(); return; }
        if (IsPostBack && Request.HttpMethod == "POST") Save();
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

    void LoadConfig()
    {
        try {
            if(!System.IO.File.Exists(ConfigPath())) return;
            XDocument d=XDocument.Load(ConfigPath());
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

    void Save()
    {
        try {
            string colour=Request.Form["carouselColour"]??"#2d1450";
            if(!System.Text.RegularExpressions.Regex.IsMatch(colour, "^#[0-9A-Fa-f]{6}$")) throw new Exception("Carousel colour must be a valid colour.");
            XDocument d=new XDocument(new XElement("carousel", new XElement("colour", colour)));
            for(int i=1;i<=3;i++){
                string title=Request.Form["title"+i]??""; string text=Request.Form["text"+i]??""; string raw=Request.Form["expires"+i]??""; string expiry="";
                DateTime dt; if(!String.IsNullOrWhiteSpace(raw)){ if(!DateTime.TryParse(raw, out dt)) throw new Exception("Slide "+i+" has an invalid expiry date/time."); expiry=dt.ToString("o"); }
                d.Root.Add(new XElement("slide",new XAttribute("id",i),new XAttribute("expires",expiry),new XElement("title",title),new XElement("text",text)));
            }
            string path=ConfigPath(); System.IO.Directory.CreateDirectory(System.IO.Path.GetDirectoryName(path));
            d.Save(path); Status="Carousel settings saved.";
        } catch(Exception ex){ Status="Save failed: "+ex.Message; }
    }
</script>
<!doctype html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>RDWeb Carousel Customisation</title><link href="../css/bootstrap.min.css" rel="stylesheet"/>
<style>body{background:url('../images/EngOne.jpg') center center/cover fixed no-repeat;min-height:100vh}.panel{background:rgba(255,255,255,.92);border-radius:1rem}.form-control{background:rgba(255,255,255,.95)}</style></head>
<body><main class="container py-4"><div class="panel p-4 shadow"><div class="d-flex justify-content-between align-items-center mb-4"><div><h1 class="h3 mb-1">Carousel Customisation</h1><p class="text-muted mb-0">Custom messages automatically revert to the built-in defaults after their expiry time.</p></div><a class="btn btn-outline-secondary" href="default.aspx">Back to RDWeb</a></div>
<% if(!String.IsNullOrEmpty(Status)){ %><div class="alert alert-info"><%=HttpUtility.HtmlEncode(Status)%></div><% } %>
<form method="post" action="customise.aspx">
<div class="card mb-3"><div class="card-body"><h2 class="h5">Carousel colour</h2>
<div class="d-flex align-items-center gap-3"><input type="color" class="form-control form-control-color" id="carouselColour" name="carouselColour" value="<%=HttpUtility.HtmlAttributeEncode(CarouselColour)%>" title="Choose carousel colour"/><span class="text-muted">Choose the carousel colour for this environment.</span></div>
</div></div>
<% for(int i=1;i<=3;i++){ %><div class="card mb-3"><div class="card-body"><div class="d-flex justify-content-between align-items-center"><h2 class="h5">Slide <%=i%></h2><span class="badge <%= States[i].StartsWith("EXPIRED") ? "bg-secondary" : (States[i]=="ACTIVE" ? "bg-success" : "bg-info text-dark") %>"><%=HttpUtility.HtmlEncode(States[i])%></span></div>
<div class="mb-3"><label class="form-label" for="title<%=i%>">Title</label><input class="form-control" id="title<%=i%>" name="title<%=i%>" value="<%=HttpUtility.HtmlAttributeEncode(Titles[i])%>" maxlength="120"/></div>
<div class="mb-3"><label class="form-label" for="text<%=i%>">Message</label><textarea class="form-control" id="text<%=i%>" name="text<%=i%>" rows="3" maxlength="1000"><%=HttpUtility.HtmlEncode(Texts[i])%></textarea></div>
<div><label class="form-label" for="expires<%=i%>">Expiry date/time (optional)</label><input class="form-control" style="max-width:320px" type="datetime-local" id="expires<%=i%>" name="expires<%=i%>" value="<% DateTime ed; if(DateTime.TryParse(Expires[i],null,DateTimeStyles.RoundtripKind,out ed)){ %><%=ed.ToString("yyyy-MM-ddTHH:mm")%><% } %>"/><div class="form-text">Leave blank to keep this message until it is changed.</div></div>
</div></div><% } %>
<button class="btn btn-primary" type="submit">Save carousel settings</button></form></div></main></body></html>