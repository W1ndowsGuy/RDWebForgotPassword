<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:appfeed="http://schemas.microsoft.com/ts/2007/05/tswf"
                xmlns:str="urn:microsoft.com:rdwastrings">
  <xsl:output method="html" doctype-public="-//W3C//DTD HTML 4.01//EN" doctype-system="http://www.w3.org/TR/html4/strict.dtd" encoding="UTF-8"/>

  <xsl:variable name="baseurl" select="/RDWAPage/@baseurl"/>
  <xsl:variable name="rdcinstallurl" select="/RDWAPage/AppFeed[1]/@rdcinstallurl"/>
  <xsl:variable name="showpubliccheckbox" select="/RDWAPage/AppFeed[1]/@showpubliccheckbox = 'true'"/>
  <xsl:variable name="showoptimizeexperience" select="/RDWAPage/AppFeed[1]/@showoptimizeexperience = 'true'"/>
  <xsl:variable name="optimizeexperiencestate" select="/RDWAPage/AppFeed[1]/@optimizeexperiencestate = 'true'"/>
  <xsl:variable name="privatemode" select="/RDWAPage/AppFeed[1]/@privatemode = 'true'"/>
  <xsl:variable name="appfeedcontents" select="/RDWAPage/AppFeed[1]"/>
  <xsl:variable name="strings" select="document(concat($baseurl,'RDWAStrings.xml'))/str:strings/string"/>
  <xsl:variable name="userdisplayname" select="/RDWAPage/@userdisplayname"/>
  <xsl:variable name="userexpiration" select="/RDWAPage/@userexpiration"/>
  <xsl:variable name="myString" select="/RDWAPage/@myString"/>
  <xsl:variable name="domainName" select="/RDWAPage/@domainName"/>

  <!-- News Text Variables-->
  <xsl:variable name="footerTextTitle1">Maintenance Outage</xsl:variable>
  <xsl:variable name="footerText1">Notifications for outages will also be here in future</xsl:variable>
  <xsl:variable name="footerTextTitle2">HELP</xsl:variable>
  <xsl:variable name="footerText2">If you having any issues with login please click 'Help'</xsl:variable>
  <xsl:variable name="footerTextTitle3">Security</xsl:variable>
  <xsl:variable name="footerText3">Warning: By logging in to this web page, you confirm that this computer complies with your organization's security policy.</xsl:variable>
  <!-- Variable for Environment login page-->

  <xsl:variable name="logonHeader" select="/RDWAPage/@logonHeader"/>


  <!-- top level document structure this is the one that affects all under /RDWAPage namespace  -->
  <xsl:template match="/RDWAPage">
    <html>
      <head id="Head1">
        <xsl:if test="$baseurl">
        <base><xsl:attribute name="href"><xsl:value-of select="$baseurl"/></xsl:attribute></base>
        </xsl:if>
        <title ID="PAGE_TITLE"><xsl:value-of select="$strings[@id = 'PageTitle']"/></title>
        <meta name="ROBOTS" content="NOINDEX, NOFOLLOW"/>
        <meta http-equiv="X-UA-Compatible" content="IE=9"/>
        <link href="tswa.css" rel="stylesheet" type="text/css" />
        <!-- Insert Link for bootstrap here -->
        <link href="../css/bootstrap.min.css" rel="stylesheet"/>



        <xsl:apply-templates select="Style"/>
        <!-- Insert Link for bootstrap JS here -->
        <script language="javascript" type="text/javascript" src='../js/bootstrap.bundle.min.js'/>
        
        <script language="javascript" type="text/javascript" src='../renderscripts.js'/>
        <script language="javascript" type="text/javascript" src='../webscripts-domain.js'/>
        <script language="javascript" type="text/javascript">
     
          var sHelpSource = &quot;<xsl:value-of select="@helpurl"/>&quot;;          
          <xsl:value-of select="HeaderJS[1]"/>
          <xsl:if test="$baseurl">
          strBaseUrl = &quot;<xsl:value-of select="$baseurl"/>&quot;;
          </xsl:if>
        </script>
      </head>

      <body>
        
        <xsl:apply-templates select="BodyAttr/@*"/>

        <noscript><xsl:copy-of select="$strings[@id = 'NoScriptWarning']/node()"/></noscript>

        <xsl:apply-templates select="@domainuser"/>

        <xsl:comment>Page Table</xsl:comment>
        

          <xsl:if test="$userdisplayname">
          <nav class="navbar navbar-expand navbar-light " aria-label="Second navbar example">
            <div class="container-fluid">
              <img src="../images/Rural_Payments_Agency_Black.png" alt="RPA logo" style=" height:80px;margin-right: 15px;" />

              <div class="d-flex align-items-center mx-auto justify-content-center "> <!-- Use flex utilities to align items vertically -->
                
                <a class="navbar-brand" style="  margin-top:10px;font-family: 'Segoe UI', 'Calibri', Tahoma, sans-serif; font-size: 22px;font-weight:475;"><xsl:value-of select="$logonHeader"/></a>
                <div class="divider-vertical"></div> <!-- Add a divider between the image and text -->
              </div>

    
              <div class="collapse navbar-collapse justify-content-end" id="navbarsExample02"> <!-- Align items to the end (right) -->
                <xsl:comment>4th Row - Navigation Table</xsl:comment>
                <xsl:choose>
                  <xsl:when test="NavBar[1]">
                    <xsl:apply-templates select="NavBar[1]"/>
                  </xsl:when>
                  <xsl:otherwise>
                                    
                    <xsl:comment>Login Page only contains Help link</xsl:comment>
                    <div class="collapse navbar-collapse justify-content-end" id="navbarsExample02"> <!-- Align items to the end (right) -->
                      <ul class="navbar-nav">
                        <li class="nav-item">
                          <a class="nav-link active" aria-current="page" href="javascript:onClickHelp()"> <xsl:value-of select="$strings[@id = 'Help']"/> </a>
                        </li>
                      </ul>
                    </div>
                  </xsl:otherwise>
                </xsl:choose>
              </div>
            </div>
          </nav>
       
                  
                   
         
          <nav class="navbar navbar-expand-lg navbar-light  rounded" aria-label="Eleventh navbar example">
            <div class="container-fluid">
                <a class="navbar-brand">Welcome <xsl:value-of select="$userdisplayname"/></a>
                <a class="navbar-brand"></a>

                <div class="collapse navbar-collapse show" id="navbarsExample09">
                    <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                        <!-- Your list items here -->
                        <li class="nav-item">
                            <a class="nav-link active" aria-current="page"></a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link active">
                                <xsl:if test="contains($userexpiration, 'Click here to reset now')">
                                    <!-- Extract days remaining from userexpiration -->
                                    <xsl:variable name="remainingDays" select="substring-before(substring-after($userexpiration, 'expires in '), ' days')"/>
                                    <xsl:value-of select="concat('Password Expires in ', $remainingDays, ' Days')"/>
                                </xsl:if>
                                <!-- If 'Click here to reset now' is not present, keep the original link -->
                                <xsl:if test="not(contains($userexpiration, 'Click here to reset now'))">
                                    <xsl:value-of select="$userexpiration"/>
                                </xsl:if>
                            </a>
                        </li>
                        <xsl:if test="contains($userexpiration, 'Click here to reset now')">
                            <li class="nav-item">
                                <a class="nav-link active" style="color: red; text-decoration: underline; font-weight: bold;" href="password.aspx" tabindex="-1" aria-disabled="true">Click Here To Reset</a>
                            </li>
                        </xsl:if>
                    </ul>
                  </div>
                </div>
          </nav>

          </xsl:if>
        
        <xsl:if test="not($userdisplayname)">
        <a style="display: inline-block; width: 10px; height: 5rem; background-color: transparent; border: none; "></a>
          </xsl:if>
              <xsl:if test="$userdisplayname">
        <a style="display: inline-block; width: 10px; height: 2rem; background-color: transparent; border: none; "></a>
        </xsl:if>

        <div border="0" align="center" cellpadding="0" cellspacing="0" style="border-collapse:unset !important;">

          <xsl:comment>3rd Row (Main)</xsl:comment>
          <div>
            <div>
                
     
              <xsl:comment>Contents and Controls Table (1 Row, 3 Columns)</xsl:comment>
              <div >

                <div>

                <xsl:comment>Col 2 - Contents and Controls</xsl:comment>
                  <div >


                    <xsl:comment>Inner Contents and Controls Table (8 Rows, 1 Column)</xsl:comment>
                    <div>


                      <xsl:comment>7th Row - Visible Controls</xsl:comment>
                      <div>
                        <div>
                          <xsl:choose>
                            <xsl:when test="HTMLMainContent[1]">
                              <xsl:copy-of select="HTMLMainContent[1]/*"/>
                            </xsl:when>
                            <xsl:when test="AppFeed[1]">
                              <div id="homemain">
                                <div id="content">
                                  <xsl:apply-templates select="AppFeed[1]"/>
                                </div>
                              </div>
                            </xsl:when>
                          </xsl:choose>
                        </div>
                      </div>

                      <xsl:copy-of select="ExtraRows[1]/*"/>

                    </div>
                   
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <xsl:if test="not($userdisplayname)">
        <a style="display: inline-block; width: 10px; height: 10rem; background-color: transparent; border: none; "></a>
        </xsl:if>
         <xsl:if test="$userdisplayname">
        <a style="display: inline-block; width: 10px; height: 1rem; background-color: transparent; border: none; "></a>
        </xsl:if>
        
        <xsl:comment>Page Bottom</xsl:comment>
        <xsl:if test="$userdisplayname or $myString">
          <div id="myCarousel" class="carousel slide" data-bs-ride="carousel" style="position: fixed; bottom: 0; width: 100%;" >
          <div class="carousel-indicators">
            <button type="button" data-bs-target="#myCarousel" data-bs-slide-to="0" class="active" aria-label="Slide 1" aria-current="true"></button>
            <button type="button" data-bs-target="#myCarousel" data-bs-slide-to="1" aria-label="Slide 2" class=""></button>
            <button type="button" data-bs-target="#myCarousel" data-bs-slide-to="2" aria-label="Slide 3" class=""></button>
          </div>
          <div class="carousel-inner">
            <div class="carousel-item active">
              <svg class="bd-placeholder-img" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" preserveAspectRatio="xMidYMid slice" focusable="false"><rect width="100%" height="100%" fill="rgba(8, 209, 18, 0.2)"></rect></svg>
              
              <div class="container">
                <div class="carousel-caption">
                  <h1><xsl:value-of select="$footerTextTitle1"/></h1>
                  <p><xsl:value-of select="$footerText1"/></p>
            
                </div>
              </div>
            </div>
          <div class="carousel-item">
            <svg class="bd-placeholder-img" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" preserveAspectRatio="xMidYMid slice" focusable="false"><rect width="100%" height="100%" fill="rgba(8, 209, 18, 0.2)"></rect></svg>

            <div class="container">
              <div class="carousel-caption">
                <h1><xsl:value-of select="$footerTextTitle2"/></h1>
                <p><xsl:value-of select="$footerText2"/>.</p>
        
              </div>
            </div>
          </div>
          <div class="carousel-item">
          <svg class="bd-placeholder-img" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" preserveAspectRatio="xMidYMid slice" focusable="false"><rect width="100%" height="100%" fill="rgba(8, 209, 18, 0.2)"></rect></svg>

            <div class="container">
              <div class="carousel-caption">
                <h1><xsl:value-of select="$footerTextTitle3"/></h1>
                <p><xsl:value-of select="$footerText3"/>.</p>

              </div>
            </div>
          </div>
          </div>
            <button class="carousel-control-prev" type="button" data-bs-target="#myCarousel" data-bs-slide="prev">
              <span class="carousel-control-prev-icon" aria-hidden="true"></span>
              <span class="visually-hidden">Previous</span>
            </button>
            <button class="carousel-control-next" type="button" data-bs-target="#myCarousel" data-bs-slide="next">
              <span class="carousel-control-next-icon" aria-hidden="true"></span>
              <span class="visually-hidden">Next</span>
            </button>
          </div>
        </xsl:if>

        <script language="javascript" type="text/javascript">
          <xsl:value-of select="PostHtmlLoadJS[1]"/>
        </script>

      </body>      
    </html>
  </xsl:template>
  
  <xsl:template match="/RDWAPage/Style">
    <xsl:choose>
      <xsl:when test="@condition">
        <xsl:comment>[<xsl:value-of select="@condition"/>]&gt;
          &lt;style&gt;
            <xsl:value-of select="."/>
          &lt;/style&gt;
          &lt;![endif]</xsl:comment>
      </xsl:when>
      <xsl:otherwise>
        <style>
          <xsl:value-of select="."/>
        </style>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/RDWAPage/BodyAttr/@*">
    <xsl:attribute name="{name(.)}"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>
   <!-- Something to do with domain user input  -->
  <xsl:template match="/RDWAPage/@domainuser">
    <form name="FrmUserInfo" id="FrmUserInfo">
      <input type="hidden" id="DomainUserName" name="DomainUserName">
        <xsl:attribute name="value"><xsl:value-of select="."/></xsl:attribute>
      </input>
    </form>
  </xsl:template>
   <!-- Below For Navigation Bar format  -->
   
  <xsl:template match="/RDWAPage/NavBar">
    <xsl:if test="@showsignout = 'true'">
      <div class="collapse navbar-collapse justify-content-end" id="navbarsExample02"> <!-- Align items to the end (right) -->
        <ul class="navbar-nav">
            <li class="nav-item">
              <a class="nav-link" aria-current="page" href="javascript:onUserDisconnect()">
              <xsl:value-of select="$strings[@id = 'SignOut']"/>
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="javascript:onClickHelp()">
                <xsl:value-of select="$strings[@id = 'Help']"/>
                </a>
            </li>
          </ul>
      </div>
    </xsl:if>
  </xsl:template>

  <!-- Below For Navigation Tab format 
  <xsl:template match="/RDWAPage/NavBar/Tab">
    <xsl:if test="position() != 1">
      <div width="15">&#160;</div>
      <div class="dividerInNavigationBar">|</div>
      <div width="15">&#160;</div>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="../@activetab = @id">
        <div class="headingForActivePageInNavigationBar">
          <xsl:attribute name='id'><xsl:value-of select='@id'/></xsl:attribute>
          <xsl:value-of select='.'/>
        </div>
      </xsl:when>
      <xsl:otherwise>
        <div>
          <a target="_self">
            <xsl:attribute name='href'><xsl:value-of select='@href'/></xsl:attribute>
            <xsl:attribute name='id'><xsl:value-of select='@id'/></xsl:attribute>
            <xsl:value-of select='.'/>
          </a>
        </div>
      </xsl:otherwise>
    </xsl:choose>
      
  </xsl:template>
-->
  <!-- Below For app feed format  -->
  <xsl:template match="/RDWAPage/AppFeed">    
    <xsl:apply-templates select="$appfeedcontents/appfeed:ResourceCollection"/>
  </xsl:template>

  <xsl:template match="appfeed:ResourceCollection">
    <xsl:variable name="feedidprefix">AppFeed_<xsl:value-of select="generate-id()"/></xsl:variable>
    <div style="display:none;height:0px; width:0px; background-color:Transparent;">
      <xsl:attribute name="id"><xsl:value-of select="$feedidprefix"/>oDivMsRdpClient</xsl:attribute>

      <script type="text/javascript" language="javascript">
        var MsRdpClientShell;
        var ActiveXMode;

        function <xsl:value-of select="$feedidprefix"/>window_onload() {

          ActiveXMode = <xsl:value-of select="$feedidprefix"/>LoadControl();
          
          if (ActiveXMode &amp;&amp; <xsl:value-of select="$feedidprefix"/>Controls.PORTAL_REMOTE_DESKTOPS != null)
          {
            <xsl:value-of select="$feedidprefix"/>Controls.PORTAL_REMOTE_DESKTOPS.style.display = "inline";
          }

          <xsl:value-of select="$feedidprefix"/>Controls.PleaseWait.style.display="none";
          
          <xsl:value-of select="$feedidprefix"/>EnableAppDisplay();
        }

        
        function <xsl:value-of select="$feedidprefix"/>EnableAppDisplay() {
          <xsl:value-of select="$feedidprefix"/>Controls.AppDisplay.style.display = "block";
        
          if (ActiveXMode)
          {
            <xsl:if test="$showpubliccheckbox">
            <xsl:value-of select="$feedidprefix"/>Controls.contentPublicCheckbox.style.display = "block";
            </xsl:if>

            <xsl:if test="$showoptimizeexperience">
            <xsl:value-of select="$feedidprefix"/>Controls.contentShowOptimizeExperience.style.display = "block";
            </xsl:if>
          }
        }
        
        
        function <xsl:value-of select="$feedidprefix"/>LoadControl() {
          var retval = true;
          
          try
          {
            var WebAccessControlPresent = <xsl:value-of select="$feedidprefix"/>IsWebAccessControlPresent();
          
            var obj = "&lt;object type='application/x-oleobject'";
            obj += "id='MsRdpClient' name='MsRdpClient'";
            obj += "onerror='<xsl:value-of select="$feedidprefix"/>OnControlLoadError'";
            obj += "height='0' width='0'";
            if ( WebAccessControlPresent ) {
              obj += "classid='CLSID:6A5B0C7C-5CCB-4F10-A043-B8DE007E1952'>";
            }
            else {
              obj += "classid='CLSID:7390f3d8-0439-4c05-91e3-cf5cb290c3d0'>";
            }
            obj += "&lt;/object&gt;";
            obj += "&lt;script language='javascript' type='text/javascript'&gt; var MsRdpClient = document.getElementById('MsRdpClient'); &lt;\/script&gt;";
           
            document.getElementById("<xsl:value-of select="$feedidprefix"/>oDivMsRdpClient").insertAdjacentHTML("beforeEnd",obj); 
            if ( WebAccessControlPresent ) {
              MsRdpClientShell = MsRdpClient;
            }
            else {
              MsRdpClientShell = MsRdpClient.MsRdpClientShell;
            }
              
            if (!MsRdpClient || MsRdpClientShell == null) {
              retval = false;
              <xsl:value-of select="$feedidprefix"/>OnControlLoadError();
            }
          }
          catch(e)
          {
            retval = false;
          }         
          
          return retval;
        }

        
        function <xsl:value-of select="$feedidprefix"/>OnControlLoadError() {
          <xsl:value-of select="$feedidprefix"/>ActiveXMode = false;
        }


        function <xsl:value-of select="$feedidprefix"/>IsWebAccessControlPresent() {
          var retval = false;
          try {
              var WebAccessControl = new ActiveXObject("MsRdpWebAccess.MsRdpClientShell");
              if ( WebAccessControl ) {
                  retval = true;
              }
          }
          catch(e) {
              retval = false;
          }
          return retval;
        }

        
        <xsl:if test="$showpubliccheckbox">
        function <xsl:value-of select="$feedidprefix"/>toggle(e) {
          if (e.id == "<xsl:value-of select="$feedidprefix"/>p2M") {
            <xsl:value-of select="$feedidprefix"/>Controls.p2M.style.display = "none";
            <xsl:value-of select="$feedidprefix"/>Controls.p2L.style.display = "";
            <xsl:value-of select="$feedidprefix"/>Controls.privateMore.style.display = "";
            <xsl:value-of select="$feedidprefix"/>Controls.contentPublicCheckbox.className = "tswa_PublicCheckboxMore";
          <xsl:choose>
            <xsl:when test="$showoptimizeexperience = 'true'">
            <xsl:value-of select="$feedidprefix"/>Controls.contentShowOptimizeExperience.className = "tswa_ShowOptimizeExperienceShiftedUp";
            <xsl:value-of select="$feedidprefix"/>Controls.AppDisplay.style.height = (<xsl:value-of select="$feedidprefix"/>Controls.AppDisplay.offsetHeight - 60) + "px"; //  440px
          </xsl:when>
            <xsl:otherwise>
            <xsl:value-of select="$feedidprefix"/>Controls.AppDisplay.style.height = (<xsl:value-of select="$feedidprefix"/>Controls.AppDisplay.offsetHeight - 40) + "px"; //  440px
          </xsl:otherwise>
          </xsl:choose>
          } else if (e.id == "<xsl:value-of select="$feedidprefix"/>p2L") {
            <xsl:value-of select="$feedidprefix"/>Controls.p2M.style.display = "";
            <xsl:value-of select="$feedidprefix"/>Controls.p2L.style.display = "none";
            <xsl:value-of select="$feedidprefix"/>Controls.privateMore.style.display = "none";
            <xsl:value-of select="$feedidprefix"/>Controls.contentPublicCheckbox.className = "tswa_PublicCheckboxLess";

          <xsl:choose>
            <xsl:when test="$showoptimizeexperience = 'true'">
            <xsl:value-of select="$feedidprefix"/>Controls.contentShowOptimizeExperience.className = "tswa_ShowOptimizeExperience";
            <xsl:value-of select="$feedidprefix"/>Controls.AppDisplay.style.height = (<xsl:value-of select="$feedidprefix"/>Controls.AppDisplay.offsetHeight + 60) + "px"; //  440px
          </xsl:when>
            <xsl:otherwise>
            <xsl:value-of select="$feedidprefix"/>Controls.AppDisplay.style.height = (<xsl:value-of select="$feedidprefix"/>Controls.AppDisplay.offsetHeight + 40) + "px"; //  440px
          </xsl:otherwise>
          </xsl:choose>
          }
        }
        </xsl:if>
      </script>
    </div>

    <div>
      <xsl:attribute name='id'><xsl:value-of select="$feedidprefix"/>content</xsl:attribute>

      <div class="tswa_appboard" style="display:none;">
        <xsl:attribute name='id'><xsl:value-of select="$feedidprefix"/>PleaseWait</xsl:attribute>
        <div cellspacing="0" cellpadding="0" border="0" width="100%" height="100%">
          <div>
            <div align="center" valign="middle">
              <xsl:copy-of select="$strings[@id = 'SearchingForApps']/node()"/><img src="../images/rapwait.gif" style="width:122px;height:32px;vertical-align:middle;"/>
            </div>
          </div>
        </div>
      </div>

      <script type="text/javascript" language="javascript">
        document.getElementById("<xsl:value-of select="$feedidprefix"/>PleaseWait").style.display="block";
      </script>

      <div class="tswa_appboard tswa_appdisplay" style="display:none;top:0px;overflow:auto;">
        <xsl:attribute name='id'><xsl:value-of select="$feedidprefix"/>AppDisplay</xsl:attribute>
        
        <!-- deal with folder icons and labels 
        <div class="tswa_CurrentFolderLabel"><xsl:value-of select="$strings[@id = 'CurrentFolder']"/><span><xsl:attribute name='id'><xsl:value-of select="$feedidprefix"/>CurrentFolderPath</xsl:attribute><xsl:value-of select="appfeed:Publisher[1]/@DisplayFolder"/></span></div>
        --> 
        <!-- Display the parent folder icon, if needed -->
        <xsl:if test="appfeed:Publisher[1]/@DisplayFolder != '/'">
          <div tabindex="0"
               onkeypress="onmouseup()"
               class="tswa_up_boss" 
               onmouseover='tswa_bossOver(this)' 
               onmouseout='tswa_bossOut(this)'
               title='Up'>
            <xsl:attribute name='onmouseup'>window.location.href='<xsl:value-of select='$baseurl'/>Default.aspx'</xsl:attribute>
            <div class="tswa_boss_spacer">
              <img class="tswa_vis0" src='../images/ivmo.png' />
              <img class="tswa_iconimg" src="../images/up.png"/>
              <div class="tswa_ttext">
                <xsl:value-of select="$strings[@id = 'ParentFolder']"/>
              </div>
            </div>
          </div>
        </xsl:if>

        <!-- display icons for any subfolders -->
        <xsl:apply-templates select="appfeed:Publisher[1]/appfeed:SubFolders[1]/appfeed:Folder">
          <xsl:sort select="@Name"/>
        </xsl:apply-templates>
        
        <xsl:apply-templates select="appfeed:Publisher[1]/appfeed:Resources[1]/appfeed:Resource"/>
      </div>

      <xsl:if test="$showoptimizeexperience = 'true'">
        <div class='tswa_ShowOptimizeExperience' style="display:none;">
          <xsl:attribute name='id'><xsl:value-of select="$feedidprefix"/>contentShowOptimizeExperience</xsl:attribute>
          <div width="100%" cellspacing="0" cellpadding="0" border="0">
            <div>
              <div valign="top" style="width:30px;font-size:12px;">
                <input type="checkbox" value="ON">
                  <xsl:attribute name='id'><xsl:value-of select="$feedidprefix"/>chkShowOptimizeExperience</xsl:attribute>
                  <xsl:if test="$optimizeexperiencestate = 'true'">
                    <xsl:attribute name="checked">checked</xsl:attribute>
                  </xsl:if>
                </input>
              </div>
              <div valign="top" style="padding-top:2px;font-size:12px;">
                <xsl:attribute name='id'><xsl:value-of select="$feedidprefix"/>ShowOptimizeExperienceText</xsl:attribute>
                <xsl:value-of select="$strings[@id = 'OptimizeMyExperience']"/>
              </div>
            </div>
          </div>
        </div>
      </xsl:if>

      <xsl:if test="$showpubliccheckbox">
        <div class='tswa_PublicCheckboxLess' style="display:none;">
          <xsl:attribute name='id'><xsl:value-of select="$feedidprefix"/>contentPublicCheckbox</xsl:attribute>

          <div width="100%" cellspacing="0" cellpadding="0" border="0">
            <div>
              <div valign="top" style="width:30px;font-size:12px;">
                <input type="checkbox" value="ON">
                  <xsl:attribute name='id'><xsl:value-of select="$feedidprefix"/>PublicCheckbox</xsl:attribute>
                  <xsl:if test="$privatemode = 'true'">
                    <xsl:attribute name="checked">checked</xsl:attribute>
                  </xsl:if>
                </input>
              </div>
              <div valign="top" style="padding-top:2px;font-size:12px;">
                <xsl:attribute name='id'><xsl:value-of select="$feedidprefix"/>SecurityText2</xsl:attribute>
                <xsl:value-of select="$strings[@id = 'PrivateComputer']"/>
                <span>
                  <xsl:attribute name='id'><xsl:value-of select="$feedidprefix"/>p2M</xsl:attribute>
                  <xsl:attribute name='onclick'><xsl:value-of select="$feedidprefix"/>toggle(this);</xsl:attribute>
                  (<a><xsl:attribute name="href">javascript:<xsl:value-of select="$feedidprefix"/>toggle(this)</xsl:attribute><xsl:value-of select="$strings[@id = 'MoreInformation']"/></a>)


                </span><span style="display:none">
                  <xsl:attribute name='id'><xsl:value-of select="$feedidprefix"/>privateMore</xsl:attribute>
                  <br />
                  <xsl:value-of select="$strings[@id = 'PrivateMore']"/>
                  <span>
                    <xsl:attribute name='id'><xsl:value-of select="$feedidprefix"/>p2L</xsl:attribute>
                    <xsl:attribute name='onclick'><xsl:value-of select="$feedidprefix"/>toggle(this);</xsl:attribute>
                    (<a><xsl:attribute name="href">javascript:<xsl:value-of select="$feedidprefix"/>toggle(this)</xsl:attribute><xsl:value-of select="$strings[@id = 'HideMore']"/></a>)
                  </span>
                </span>
              </div>
            </div>
          </div>
        </div>
      </xsl:if>

    </div>
    <script type="text/javascript" language="javascript">
      
      var <xsl:value-of select="$feedidprefix"/>Controls = {
            AppDisplay: document.getElementById("<xsl:value-of select="$feedidprefix"/>AppDisplay"),
            contentPublicCheckbox: document.getElementById("<xsl:value-of select="$feedidprefix"/>contentPublicCheckbox"),
            PublicCheckbox: document.getElementById("<xsl:value-of select="$feedidprefix"/>PublicCheckbox"),
            contentShowOptimizeExperience: document.getElementById("<xsl:value-of select="$feedidprefix"/>contentShowOptimizeExperience"),
            chkShowOptimizeExperience: document.getElementById("<xsl:value-of select="$feedidprefix"/>chkShowOptimizeExperience"),
            p2M: document.getElementById("<xsl:value-of select="$feedidprefix"/>p2M"),
            p2L: document.getElementById("<xsl:value-of select="$feedidprefix"/>p2L"),
            privateMore: document.getElementById("<xsl:value-of select="$feedidprefix"/>privateMore"),
            PleaseWait: document.getElementById("<xsl:value-of select="$feedidprefix"/>PleaseWait"),
      PORTAL_REMOTE_DESKTOPS: document.getElementById("PORTAL_REMOTE_DESKTOPS")
      };

      function tswa_bossOver(obj){
        obj.children[0].children[0].className = 'tswa_vis1';
        obj.children[0].style.padding = "10px 3px 2px 2px";
      }
      function tswa_bossOut(obj){
        obj.children[0].children[0].className = "tswa_vis0";
        obj.children[0].style.padding = "12px 1px 0px 4px";
      }

      function goRDP(pid, rdpContents, url) {
      if (ActiveXMode) {
        try {
          goRDPAx(pid, rdpContents);
        } catch (e) {
          location.href = url;
        }
      }
      else {
      location.href = url;
      }
      }


      function goRDPAx(pid, arg) {
      var strRdpFileContents = arg;

      // Try adding the User Name to RdpContents.
      if ( typeof getUserNameRdpProperty == 'function' ) {
      strRdpFileContents += getUserNameRdpProperty();
      }

      <xsl:choose>
          <xsl:when test="$showpubliccheckbox">        
        MsRdpClientShell.PublicMode = !<xsl:value-of select="$feedidprefix"/>Controls.PublicCheckbox.checked;
        </xsl:when>
          <xsl:otherwise>
        MsRdpClientShell.PublicMode = <xsl:choose>
              <xsl:when test="not($privatemode)">true</xsl:when>
              <xsl:otherwise>false</xsl:otherwise>
            </xsl:choose>;
          </xsl:otherwise>
        </xsl:choose>
      
        <xsl:if test="$showoptimizeexperience">
        if (<xsl:value-of select="$feedidprefix"/>Controls.chkShowOptimizeExperience.checked) {
          var objRegExp = new RegExp("connection type:i:([0-9]+)", "i");
          var iIndex = strRdpFileContents.search( objRegExp );
          <!-- Add 'connection type' if it does exist otherwise replace. -->
          if ( -1 == iIndex ) {
            if ( "\\n" != strRdpFileContents.charAt(strRdpFileContents.length-1) ) { 
              strRdpFileContents += "\\r\\n"; 
            }
            strRdpFileContents += "connection type:i:6\\r\\n";
            } else { 
              strRdpFileContents = strRdpFileContents.replace(objRegExp, "connection type:i:6");
            }
        }
        </xsl:if>
      
        MsRdpClientShell.RdpFileContents = unescape(strRdpFileContents);
     
        try {
            MsRdpClientShell.Launch();
        }
        catch(e){
            throw e;
        }
      }

      
      function goNonRDP(pid, arg) {
        try {
          location.href = unescape(arg);
        }
        catch(e){
          throw e;
        }
      }

      

      <xsl:value-of select="$feedidprefix"/>window_onload();
    </script>
      
  </xsl:template>

  <xsl:template match="appfeed:Resource">
    <div 
      class="tswa_boss" 
      tabindex="0"
      onkeypress="onmouseup()" 
      onmouseover='tswa_bossOver(this)' 
      onmouseout='tswa_bossOut(this)'>
      <xsl:attribute name='onmouseup'>
        <xsl:choose>
          <xsl:when test="appfeed:HostingTerminalServers/appfeed:HostingTerminalServer[1]/appfeed:ResourceFile/@FileExtension = '.rdp' and appfeed:HostingTerminalServers/appfeed:HostingTerminalServer[1]/appfeed:ResourceFile/appfeed:Content and appfeed:HostingTerminalServers/appfeed:HostingTerminalServer[1]/appfeed:ResourceFile/@URL">goRDP(this, '<xsl:value-of select='appfeed:HostingTerminalServers/appfeed:HostingTerminalServer[1]/appfeed:ResourceFile/appfeed:Content'/>', '<xsl:value-of select='appfeed:HostingTerminalServers/appfeed:HostingTerminalServer[1]/appfeed:ResourceFile/@URL'/>');</xsl:when>
          <xsl:otherwise>goNonRDP(this, '<xsl:value-of select='appfeed:HostingTerminalServers/appfeed:HostingTerminalServer[1]/appfeed:ResourceFile/appfeed:Content'/>');</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name='title'><xsl:value-of select="@Title"/></xsl:attribute>
      <div class="tswa_boss_spacer">
        <img class="tswa_vis0" src='../images/ivmo.png' />
        <img class="tswa_iconimg">
          <xsl:attribute name="src">
            <xsl:value-of select="appfeed:Icons/appfeed:Icon32[@Dimensions = '32x32' and @FileType = 'Png']/@FileURL"/>
          </xsl:attribute>
        </img>
        <div class="tswa_ttext">
          <xsl:value-of select="@Title"/>
        </div>
      </div>
    </div>
  </xsl:template>

  
  <xsl:template match="appfeed:Folder">
    <xsl:variable name="folderName" select="substring-after(@Name, '/')"/>
    <div
      class="tswa_folder_boss"
      tabindex="0"
      onkeypress="onmouseup()"
      onmouseover='tswa_bossOver(this)'
      onmouseout='tswa_bossOut(this)'>
      <xsl:attribute name='onmouseup'>window.location.href='<xsl:value-of select='$baseurl'/>Default.aspx/' + encodeURIComponent('<xsl:value-of select='$folderName'/>')</xsl:attribute>
      <xsl:attribute name='title'>
        <xsl:value-of select="$folderName"/>
      </xsl:attribute>
      <div class="tswa_boss_spacer">
        <img class="tswa_vis0" src='../images/ivmo.png' />
        <img class="tswa_iconimg" src="../images/folder.png"/>
        <div class="tswa_ttext">
          <xsl:value-of select="$folderName"/>
        </div>
      </div>
    </div>
  </xsl:template>
  
</xsl:stylesheet>











