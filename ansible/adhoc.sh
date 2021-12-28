#Adhoc commands

ansible all -i /home/admin/ansible/inventory -u admin -b -m yum_repository -a 'name=EX294_BASE description="EX294 base software" baseurl=http://server.network.example.com/BaseOs enabled=yes gpgkey=http://server.network.example.com/RHEL/RPM-GPG-KEY-redhat-release gpgcheck=yes'


ansible all -i /home/admin/ansible/inventory -u admin -b -m command -a 'yum clean all warn=no'
