using System;
using System.DirectoryServices;
using System.DirectoryServices.ActiveDirectory;
using System.Diagnostics;
using System.IO;
using System.IO.Pipes;
using System.Net.Mail;
using System.Security.AccessControl;
using System.Security.Principal;
using System.ServiceProcess;
using System.Text;
using System.Threading;

namespace RDWebRecoveryHelper
{
 internal static class Program { static void Main() { ServiceBase.Run(new RecoveryService()); } }
 internal sealed class RecoveryService : ServiceBase
 {
  private Thread worker; private volatile bool stopping; private const string PipeName="RDWebRecoveryHelper";
  public RecoveryService(){ServiceName="RDWebRecoveryHelper";CanStop=true;AutoLog=true;}
  protected override void OnStart(string[] args){stopping=false;worker=new Thread(ListenLoop);worker.IsBackground=true;worker.Start();}
  protected override void OnStop(){stopping=true;try{using(var wake=new NamedPipeClientStream(".",PipeName,PipeDirection.Out))wake.Connect(250);}catch{} if(worker!=null&&worker.IsAlive)worker.Join(2000);}
  private void ListenLoop(){while(!stopping){try{
   var security=new PipeSecurity();
   security.AddAccessRule(new PipeAccessRule(new SecurityIdentifier(WellKnownSidType.LocalSystemSid,null),PipeAccessRights.FullControl,AccessControlType.Allow));
   security.AddAccessRule(new PipeAccessRule(new NTAccount(@"IIS APPPOOL\RDWebAccess"),PipeAccessRights.ReadWrite,AccessControlType.Allow));
   using(var pipe=new NamedPipeServerStream(PipeName,PipeDirection.InOut,1,PipeTransmissionMode.Message,PipeOptions.None,4096,4096,security)){
    pipe.WaitForConnection(); if(stopping)continue; pipe.ReadMode=PipeTransmissionMode.Message;
    using(var reader=new StreamReader(pipe,Encoding.UTF8,false,4096,true))
    using(var writer=new StreamWriter(pipe,new UTF8Encoding(false),4096,true)){writer.AutoFlush=true;writer.WriteLine(ProcessRequest(reader.ReadLine()));}
   }}catch(Exception ex){try{EventLog.WriteEntry("RDWebRecoveryHelper",ex.ToString(),EventLogEntryType.Error);}catch{} Thread.Sleep(500);}}}
  private static string ProcessRequest(string request){try{
   if(String.IsNullOrWhiteSpace(request))return "ERROR|Empty request";
   string[] parts=request.Split(new[]{'|'},3); if(parts.Length!=3||parts[0]!="SETMAIL")return "ERROR|Unsupported request";
   string sam=parts[1].Trim(),email=parts[2].Trim(); if(!IsValidSam(sam))return "ERROR|Invalid account name"; if(!IsValidEmail(email))return "ERROR|Invalid email address";
   SetMail(sam,email); return "OK|Recovery email saved";
  }catch(Exception ex){return "ERROR|"+Safe(ex.Message);}}
  private static bool IsValidSam(string v){if(String.IsNullOrWhiteSpace(v)||v.Length>64)return false;foreach(char c in v)if(!(Char.IsLetterOrDigit(c)||c=='.'||c=='-'||c=='_'))return false;return true;}
  private static bool IsValidEmail(string v){if(String.IsNullOrWhiteSpace(v)||v.Length>254)return false;try{var a=new MailAddress(v);return String.Equals(a.Address,v,StringComparison.OrdinalIgnoreCase);}catch{return false;}}
  private static string EscapeLdap(string v){return v.Replace(@"\",@"\5c").Replace("*", @"\2a").Replace("(",@"\28").Replace(")",@"\29").Replace("\0",@"\00");}
  private static void SetMail(string sam,string email){
   string fqdn=Domain.GetCurrentDomain().Name;
   using(var root=new DirectoryEntry("LDAP://"+fqdn))using(var searcher=new DirectorySearcher(root)){
    searcher.Filter="(&(objectCategory=person)(objectClass=user)(sAMAccountName="+EscapeLdap(sam)+"))"; searcher.PropertiesToLoad.Add("distinguishedName");
    SearchResult result=searcher.FindOne(); if(result==null||result.Properties["distinguishedName"].Count==0)throw new InvalidOperationException("Account not found");
    string dn=result.Properties["distinguishedName"][0].ToString(); string dc=Domain.GetCurrentDomain().FindDomainController().Name;
    using(var account=new DirectoryEntry("LDAP://"+dc+"/"+dn)){object bind=account.NativeObject;account.Properties["mail"].Value=email;account.CommitChanges();}
   }}
  private static string Safe(string v){if(String.IsNullOrEmpty(v))return "Operation failed";return v.Replace("|","/").Replace("\r"," ").Replace("\n"," ");}
 }
}