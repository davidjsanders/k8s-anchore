#!/bin/bash
# -------------------------------------------------------------------
#
# Module:         k8s-jenkins
# Submodule:      load-postgres.sh
# Environments:   all
# Purpose:        Bash shell script to apply any yaml files found in
#                 the jenkins directory. 
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
# 19 Aug 2019  | David Sanders               | Chmod of data drive to
#              |                             | root for docker.
# -------------------------------------------------------------------
# 26 Aug 2019  | David Sanders               | Add mandatory variable
#              |                             | checking.
# -------------------------------------------------------------------

# Include the banner function for logging purposes (see
# templates/banner.sh)
#
source ${datapath:-/datadrive/azadmin/k8s-anchore}/banner.sh
error_list=""

log_banner "load-postgre-sql.sh" "Load postgre-sql"

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

short_banner "Load YAML manifests"
yaml_files=$(ls -1 ${datapath:-/datadrive/azadmin/k8s-anchore/postgres}/[0-9]*.yaml)
for file in $yaml_files
do
    short_banner "Applying yaml for: $file"
    sed '
      s/\${domain_name}/'"${domain_name}"'/g;
      s/\${storageclass}/'"${storageclass:-local-storage}"'/g;
      s/\${selectorkey}/'"${selectorkey:-role}"'/g;
      s/\${selectorvalue}/'"${selectorvalue:-worker}"'/g;
      s/\${registry}/'"${registry:-k8s-master:32080\/}"'/g;
    ' $file | kubectl apply -f -
    ret_stat="$?"
    if [ "$ret_stat" != "0" ]; 
    then 
        short_banner "*****"; 
        short_banner "Error applying $file - skipping"; 
        short_banner "*****"; 
        error_list=$error_list" ${file}---${ret_stat}"
    fi
    echo
done

for err in $error_list
do
  echo ">>> ERROR: $err"
done

short_banner "Done."
echo
