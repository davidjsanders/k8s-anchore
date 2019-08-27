#!/bin/bash
# -------------------------------------------------------------------
#
# Module:         k8s-jenkins
# Submodule:      delete-postgres.sh
# Environments:   all
# Purpose:        Bash shell script to delete any yaml files found in
#                 the k8s-anchore/postgres directory. 
#
# Created on:     30 July 2019
# Created by:     David Sanders
# Creator email:  dsanderscanada@nospam-gmail.com
#
# -------------------------------------------------------------------
# Modifed On   | Modified By                 | Release Notes
# -------------------------------------------------------------------
# 30 Jul 2019  | David Sanders               | First release.
# -------------------------------------------------------------------
# 06 Aug 2019  | David Sanders               | Fix location of banner
#              |                             | source.
# -------------------------------------------------------------------
# 18 Aug 2019  | David Sanders               | Change error handling
#              |                             | to skip.
# -------------------------------------------------------------------

# Include the banner function for logging purposes (see
# templates/banner.sh)
#
source ${datapath:-/datadrive/azadmin/k8s-anchore}/banner.sh

log_banner "load-jenkins.sh" "Apply NFS Provisioner"

short_banner "Checking mandatory variables"
if [ -z "$domain_name" ]
then
    short_banner "domain_name *NOT* found; unable to continue."
    short_banner "Rerun setting domain_name=\".thedomain.com\" before running"
    short_banner "Note: no . is added between the service name and the domain; "
    short_banner "      include it if you need it, e.g. .mydomain.com"
    echo
    exit 1
fi

short_banner "Remove YAML manifests"
yaml_files=$(ls -r1 ${datapath:-/datadrive/azadmin/k8s-anchore/postgres}/[0-9]*.yaml)
for file in $yaml_files
do
    short_banner "Applying yaml for: $file"
    sed '
      s/\${domain_name}/'"${domain_name}"'/g;
      s/\${storageclass}/'"${storageclass:-local-storage}"'/g;
      s/\${selectorkey}/'"${selectorkey:-role}"'/g;
      s/\${selectorvalue}/'"${selectorvalue:-worker}"'/g;
      s/\${registry}/'"${registry:-k8s-master:32080\/}"'/g;
    ' $file | kubectl delete -f -
    if [ "$?" != "0" ];
    then 
        short_banner "*****";
        short_banner "Error applying $file - skipping";
        short_banner "*****";
    fi
    echo
done

short_banner "Done."
echo
