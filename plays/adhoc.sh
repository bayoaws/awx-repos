#!/bin/bash

ansible all -m yum_repository -b -a 'name=EXAM_RHEL description="EX407 software" baseurl=http://rhgls.labx.example.com/rhel gpgcheck=true enabled=false' 

ansible all -m rpm_key -b -a 'state=present key=http://rhgls.lab.example.com/rhel/RPM-GPG-KEY-redhat-release'
  
