#!/bin/bash
yum -y update
yum -y install httpd

myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

cat <<EOF > /var/www/html/index.html
<html>
<h2>WebServer with IP: $myip</h2><br>Build by Terraform!<br>
This month is ${this_month}, next month is ${next_month}<br>

<br>

%{ for val in week_days ~}
I like ${val}<br>
%{ endfor ~}

</html>
EOF

sudo service httpd start
chkconfig httpd on