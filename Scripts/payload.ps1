cls
$error.clear()
start-transcript c:\PS\AnsibleTranscript.txt
$erroractionpreference="silentlycontinue"
#import-module awspowershell
whoami
#md c:\temp
$attrs=@{}
$object={} | select Hostname, Domain, IPaddress, ServiceID, InstanceID, Uptime, Attrs, ADData
write-host "Getting Local Data"
$c=Get-CimInstance win32_computersystem 
$d=Get-CimInstance -ClassName win32_operatingsystem | select csname, lastbootuptime
$ip=(get-netipaddress | ?{$_.prefixorigin -eq "dhcp"}).ipaddress #[0]
$object.hostname=$c.dnshostname
$object.domain=$c.domain
$object.ipaddress=$ip
$uptime=(((get-date) - $d.lastbootuptime))
$u="AnsibleUptime-$($uptime.hours.tostring())" + "H" + "$($uptime.minutes.tostring())" + "M" + "$($uptime.seconds.tostring())" + "s" + ".json"
write-host "Getting AWS Service/Instance Data"
$serviceID=(get-sdservicelist -region us-east-1 | ?{$_.name -eq "QuorumService"}).id
$instanceID=(get-ec2instance -region us-east-1 | ?{$_.instances.privateipaddress -eq $ip}).instances.instanceid
$object.uptime=($u.split("-")[1]).trimend(".txt")
$object.serviceid=$serviceid
$object.instanceid=$instanceid

write-host "querying AD"
$ComputerName = $object.hostname;
$Computer = Get-WmiObject -Namespace 'root\directory\ldap' -Query "Select DS_distinguishedName from DS_computer where DS_cn = '$ComputerName'";
$OU = $Computer.DS_distinguishedName.Substring($Computer.DS_distinguishedName.IndexOf('OU='));

$Searcher=New-Object System.DirectoryServices.DirectorySearcher
$Searcher.Filter="(objectcategory=user)"
$Searcher.PageSize = 1000
$Results=$Searcher.FindAll()
$object.addata=$results

$attrs.add("AWS_INSTANCE_IPV4", $ip)
$object.attrs=$attrs
write-host "Adding EC2 Instance to CloudMap"
new-sdinstanceregistration -instanceid $instanceid -attribute $attrs -serviceid $serviceid
$object | convertto-json > c:\PS\$u

$erroractionpreference="continue"
$error
stop-transcript
