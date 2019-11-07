$erroractionpreference="continue"
#import-module awspowershell
if(!(test-path c:\temp)) {md c:\temp}
start-transcript c:\temp\transcript.txt -force
$attrs=@{}
$object={} | select Hostname, Domain, IPaddress, ServiceID, InstanceID, Uptime, Attrs, towerhosts

write-host "Getting Local Data"
$c=Get-CimInstance win32_computersystem 
$d=Get-CimInstance -ClassName win32_operatingsystem | select csname, lastbootuptime
$ip=(get-netipaddress | ?{$_.prefixorigin -eq "dhcp"}).ipaddress #[0]
$object.hostname=$c.dnshostname
$object.domain=$c.domain
$object.ipaddress=$ip
$uptime=(((get-date) - $d.lastbootuptime))
$u="Uptime-$($uptime.hours.tostring())" + "H" + "$($uptime.minutes.tostring())" + "M" + "$($uptime.seconds.tostring())" + "s" + ".json"

write-host "Getting AWS Service/Instance Data"
#$serviceID=(get-sdservicelist -region us-east-1 | ?{$_.name -eq "QuorumService"}).id
#$instanceID=(get-ec2instance -region us-east-1 | ?{$_.instances.privateipaddress -eq $ip}).instances.instanceid
$object.uptime=($u.split("-")[1]).trimend(".txt")
#$object.serviceid=$serviceid
#$object.instanceid=$instanceid
$attrs.add("AWS_INSTANCE_IPV4", $ip)
$object.attrs=$attrs
$object | convertto-json > c:\temp\$u
stop-transcript
