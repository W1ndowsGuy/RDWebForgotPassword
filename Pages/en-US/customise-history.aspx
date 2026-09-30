<%@ Page Language="C#" Debug="false" ResponseEncoding="utf-8" ContentType="text/html" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Xml.Linq" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.DirectoryServices" %>
<%@ Import Namespace="System.DirectoryServices.ActiveDirectory" %>
<%@ Import Namespace="Microsoft.TerminalServices.Publishing.Portal.FormAuthentication" %>
<script runat="server">
public XElement[] Entries=new XElement[0]; public string Status="";
protected void Page_Load(object sender,EventArgs e){
 if(!HttpContext.Current.User.Identity.IsAuthenticated){Response.Redirect("login.aspx?ReturnUrl="+HttpUtility.UrlEncode(Request.Path));return;}
 if(!IsWebAdmin()){Response.StatusCode=403;Response.End();return;}
 string p=Server.MapPath("../config/customise-history.xml");
 if(Request.HttpMethod=="POST"&&(Request.Form["action"]??"")=="clear"){
   try{if(File.Exists(p))File.Delete(p);Status="Customisation history cleared.";}catch(Exception ex){Status="Could not clear history: "+ex.Message;}
 }
 try{if(File.Exists(p)){XDocument d=XDocument.Load(p);Entries=d.Root.Elements("entry").ToArray();}}catch(Exception ex){Status="Could not read history: "+ex.Message;}
}
string UserName(){try{TSFormAuthTicketInfo t=new TSFormAuthTicketInfo(HttpContext.Current);string a=t.DomainUserName??"";return a.Contains("@")?a.Split('@')[0]:(a.Contains("\\")?a.Split('\\')[1]:a);}catch{string a=HttpContext.Current.User.Identity.Name??"";return a.Contains("\\")?a.Split('\\')[1]:a;}}
bool IsWebAdmin(){try{string fqdn=Domain.GetCurrentDomain().Name;using(DirectoryEntry root=new DirectoryEntry("LDAP://"+fqdn))using(DirectorySearcher ds=new DirectorySearcher(root)){ds.Filter="(&(objectCategory=person)(objectClass=user)(sAMAccountName="+UserName().Replace("(","\\28").Replace(")","\\29")+"))";ds.PropertiesToLoad.Add("distinguishedName");SearchResult u=ds.FindOne();if(u==null||u.Properties["distinguishedName"].Count==0)return false;using(DirectorySearcher gs=new DirectorySearcher(root)){gs.Filter="(&(objectCategory=group)(sAMAccountName=webadmins)(member:1.2.840.113556.1.4.1941:="+u.Properties["distinguishedName"][0].ToString().Replace("(","\\28").Replace(")","\\29")+"))";return gs.FindOne()!=null;}}}catch{return false;}}
</script>
<!doctype html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>RDWeb Customisation History</title><link href="../css/bootstrap-5.3.8.min.css" rel="stylesheet"/>
<style>body{background:url('../images/EngOne.jpg') center center/cover fixed no-repeat;min-height:100vh}.panel{background:rgba(255,255,255,.92);border-radius:1rem}</style></head>
<body><main class="container py-4"><div class="panel p-4 shadow">
<div class="d-flex justify-content-between align-items-center mb-4"><div><h1 class="h3 mb-1">Customisation History</h1><p class="text-body-secondary mb-0">Changes made through the RDWeb customisation page.</p></div><div class="d-flex gap-2"><a class="btn btn-outline-secondary" href="customise.aspx">Back to Customisation</a><form method="post" class="m-0" onsubmit="return confirm('Clear all customisation history?');"><button class="btn btn-outline-danger" name="action" value="clear" type="submit">Clear history</button></form></div></div>
<%if(!String.IsNullOrEmpty(Status)){%><div class="alert alert-info"><%=HttpUtility.HtmlEncode(Status)%></div><%}%>
<%if(Entries.Length==0){%><div class="alert alert-secondary mb-0">No customisation history has been recorded yet.</div><%}else{%>
<div class="table-responsive"><table class="table table-striped align-middle"><thead><tr><th>Date / time</th><th>User</th><th>Changed</th></tr></thead><tbody>
<%foreach(XElement e in Entries){DateTime dt;DateTime.TryParse((string)e.Attribute("time"),out dt); XElement[] changes=e.Elements("change").ToArray(); if(changes.Length==0) continue;%><tr><td class="text-nowrap"><%=HttpUtility.HtmlEncode(dt==DateTime.MinValue?(string)e.Attribute("time"):dt.ToString("dd/MM/yyyy HH:mm:ss"))%></td><td><%=HttpUtility.HtmlEncode((string)e.Attribute("user"))%></td><td>
<%foreach(XElement ch in changes){string field=(string)ch.Attribute("field")??"Setting"; string before=(string)ch.Element("before")??""; string after=(string)ch.Element("after")??""; string msg=(string)ch.Element("message")??"";%>
<div class="mb-3"><strong><%=HttpUtility.HtmlEncode(field)%></strong><div class="small text-body-secondary">From: <%=HttpUtility.HtmlEncode(String.IsNullOrEmpty(before)?"(blank)":before)%></div><div>To: <%=HttpUtility.HtmlEncode(String.IsNullOrEmpty(after)?"(blank)":after)%></div>
<%if(!String.IsNullOrEmpty(msg)){%><div class="mt-1 p-2 rounded bg-body-secondary"><span class="small text-body-secondary">Message:</span><br/><%=HttpUtility.HtmlEncode(msg)%></div><%}%></div>
<%}%></td></tr><%}%>
</tbody></table></div><%}%></div></main></body></html>