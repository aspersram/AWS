import-module awspowershell
if(!(test-path c:\temp)) {md c:\temp}
start-transcript c:\temp\transcript.txt
$attrs=@{}
$object={} | select Hostname, Domain, IPaddress, ServiceID, InstanceID, Uptime, Attrs

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

write-host "Connecting to Ansible Tower:"
import-module c:\ps\ansibletower\ansibletower.psm1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$username="admin"
$password="passwordOniHAL19" #AWX
$secPw = ConvertTo-SecureString $password -AsPlainText -Force
$cred1 = New-Object PSCredential -ArgumentList $username, $secPw
connect-ansibletower -credential $cred1 -towerurl 'http://172.31.25.161/' -DisableCertificateVerification

$object | convertto-json > c:\temp\$u
stop-transcript
