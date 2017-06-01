### WebSyntheticDetailedAlerts.ps1
### 
### by Michael Humphrey 
### mhumphre@rackspace.com
### yoyodyn3@humphreytx.com
### 9/25/2012
### 
### 


[xml]$xml = Get-Content ".\Detailed.Alerts.xml" #Load The Management Pack

#### Set your Alert Description

$Description = "*
*

****Request Data and Parameters****

RequestUrl: {0}

RequestHeaders: {1}

****End Request Data and Parameters****


****Response Data****

ResponseUrl: {2}

StatusCode: {3}

ErrorCode: {4} : See Error Code Guide @ http://yourknowledgebasehere.com

ResponseHeaders: {5}

ResponseBody: {6}

****End Response Data****


****Network Reponse****

DNSResolutionTime: {7}

Raw Context Data: {8}"

#Load the Schmea into Variables

$MgmtPack = $xml.ManagementPack
$MPname = $MgmtPack.Manifest.Name


$ClassType = $MgmtPack.TypeDefinitions.EntityTypes.ClassTypes.ClassType

$WebApplications = $ClassType | Where-Object {($_.Hosted -eq "true") -and ($_.ID -like "*WebApplication*")}


$Monitoring = $MgmtPack.Monitoring
$UnitMonitors = $Monitoring.Monitors.UnitMonitor
$AggregateMonitors = $Monitoring.Monitors.AggregateMonitor



$Presentation = $MgmtPack.Presentation
$StringResources = $Presentation.StringResources
$FolderItems = $Presentation.FolderItems

$LanguagePacks = $MgmtPack.LanguagePacks
$LanguagePack = $LanguagePacks.LanguagePack
$DisplayStrings = $LanguagePack.DisplayStrings


Foreach ($UnitMonitor in $UnitMonitors) #Load All of the Unit Monitors in the MP

{
#Check If the Unit Monitor is One created by the Web Application Template.
#Only Make Changes to the monitor if it is. This prevents damage to UnitMonitors not created
#by the Web Application Template.

If ($UnitMonitor.ID -like "*WebApplication*") 



{
#Check If the UnitMonitor has Alert Settings Already Configured.
#Skip Making Changes to the Unit Monitor if it is.  This prevents making changes to Unit Monitors
#that have already been turned on manually or by this script.

If (!$UnitMonitor.AlertSettings) 

{
####Add the Alert Settings Child Node to the UnitMonitor

$UnitMonitorID = $UnitMonitor.ID


$Category = $UnitMonitor.SelectSingleNode('Category')
$AlertMessage = $UnitMonitorID + "_AlertMessageResourceID"
$elAlertSettings = $xml.CreateElement("AlertSettings")
$elAlertSettings.SetAttribute('AlertMessage', $AlertMessage)
$UnitMonitor.InsertAfter($elAlertSettings, $Category)

####Add the Alert Settings Configuration Child Nodes and Values.

$AlertSettings = $UnitMonitor.AlertSettings
$elAlertOnState = $xml.CreateElement("AlertOnState")
$elAlertOnState.set_InnerXML("Error")
$AlertSettings.AppendChild($elAlertOnState)

$elAutoResolve = $xml.CreateElement("AutoResolve")
$elAutoResolve.set_InnerXml("true")
$AlertSettings.AppendChild($elAutoResolve)

$elAlertPriority = $xml.CreateElement("AlertPriority")
$elAlertPriority.set_InnerXML("Normal")
$AlertSettings.AppendChild($elAlertPriority)

$elAlertSeverity = $xml.CreateElement("AlertSeverity")
$elAlertSeverity.set_InnerXML("Error")
$AlertSettings.AppendChild($elAlertSeverity)

####Add the Alert Paramaters Child Node to the Alert Settings Node

$elAlertParameters = $xml.CreateElement("AlertParameters") 
$AlertSettings.AppendChild($elAlertParameters)

#### Add the AlertParamter{#} Child Node to the AlertParameters Node


$RequestID = $UnitMonitorID.ToString()
$RequestID = $RequestID.Split(".")
$RequestID = $RequestID[1].Split("t")
$RequestID = $RequestID[1]

#Build the array of parameters of the alert description.

$Parameters = @("`$Data/Context/RequestResults/RequestResult[@Id=$RequestID]/BasePageData/RequestUrl$", "`$Data/Context/RequestResults/RequestResult[@Id=$RequestID]/BasePageData/RequestHeaders$", "`$Data/Context/RequestResults/RequestResult[@Id=$RequestID]/BasePageData/ResponseUrl$", "`$Data/Context/RequestResults/RequestResult[@Id=$RequestID]/BasePageData/StatusCode$", "`$Data/Context/RequestResults/RequestResult[@Id=$RequestID]/BasePageData/ErrorCode$", "`$Data/Context/RequestResults/RequestResult[@Id=$RequestID]/BasePageData/ResponseHeaders$", "`$Data/Context/RequestResults/RequestResult[@Id=$RequestID]/BasePageData/ResponseBody$", "`$Data/Context/RequestResults/RequestResult[@Id=$RequestID]/BasePageData/DNSResolutionTime$", "`$Data/Context$")


$count = 1

Foreach ($Parameter in $Parameters)

{


$AlertParameter = "AlertParameter" + $count

$AlertParameters = $AlertSettings.LastChild
$elAlertParameter1 = $xml.CreateElement($AlertParameter)
$elAlertParameter1.set_InnerXML($Parameter) #this Parameter put detailed reponse data in the alert.
$AlertParameters.AppendChild($elAlertParameter1)

$count = $count + 1

}


#### Create the String Resource for the Alert Message
$elStringResource = $xml.CreateElement("StringResource")
$elStringResource.SetAttribute('ID', $AlertMessage)
$StringResources.AppendChild($elStringResource)

#Create the Display String for the Alert Message.

$elDisplayString = $xml.CreateElement("DisplayString")
$elDisplayString.SetAttribute('ElementID', $AlertMessage)
$DisplayStrings.AppendChild($elDisplayString)

#Grab the Display String Name to use as the Alert Name.

$MonitorName = $xml | Select-Xml -XPath "//DisplayString" | where-object {$_.Node.ElementID -contains $UnitMonitorID} #redundant?
$AlertName =  $MonitorName.Node.Name + " - " + $MPname

#Create the LanguagePack Display string, Name, and description.

$DisplayString = $DisplayStrings.LastChild
$elName = $xml.CreateElement("Name")
$elName.set_InnerXML($AlertName)
$DisplayString.AppendChild($elName)

$elDescription = $xml.CreateElement("Description")
$elDescription.set_InnerXML($Description)
$DisplayString.AppendChild($elDescription)
}
}


}

#Clear-Variable $AlertMessage #Clear variable for use in deletion loop.

# Turn Off the default Rollup Alerts, and delete associated Folders, String Resouce, and Display Sting. The last three are not strictly required.
# However, this will make for a cleaner MP.

ForEach ($AggregateMonitor in $AggregateMonitors) #### Collect the Rollup Monitors

{


If ($AggregateMonitor.ID -like "*WebApplication*") #### Confirm this is a Webapplicaion Rollup.  Continue if it is.

{

If ($AggregateMonitor.AlertSettings) #See if alerting is turned on Continue if it is.

{

# Grab the alert message name.  This is the identifier used to link together the Alert, Folder, Display String and String Resouce, allowing deletion
# of the correct items.

$test = $AggregateMonitor

$AlertMessage = $AggregateMonitor.AlertSettings.AlertMessage # Grab the Allertmessage.

$removeFolderItem = $FolderItems.FolderItem | Where-Object {$_.ElementID -eq $AlertMessage} # Grab the folder where ElementID =  AlertMessage
$FolderItems.RemoveChild($removeFolderItem) #Remove the Folder Item

$removeStringResorce = $StringResources.StringResource | Where-Object {$_.ID -eq $AlertMessage} #Grab the StringResource where ID = AlertMessage
$StringResources.RemoveChild($removeStringResorce) #Remove the String Resource

$removeDisplayString = $DisplayStrings.DisplayString | Where-Object {$_.ElementID -eq $AlertMessage} #Grab the DisplayString where ElementID = AlertMessage
$DisplayStrings.RemoveChild($removeDisplayString) #Remove DisplayString


$AggregateMonitor.RemoveChild($AggregateMonitor.AlertSettings) # Turn Off Alert


}

}
}

#Write the changes to a new file.

$xml.Save('.\test.xml')