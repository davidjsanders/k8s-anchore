#!/bin/bash
# -------------------------------------------------------------------
#
# Module:         k8s-jenkins
# Submodule:      load-anchore.sh
# Environments:   all
# Purpose:        Bash shell script to load anchore engine.
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

log_banner "load-postgres.sh" "Load postgres"

short_banner "Checking mandatory variables"
if [ -z "$postgres_db" ] || \
   [ -z "$postgres_user" ] || \
   [ -z "$postgres_password" ] || \
   [ -z "$postgres_endpoint" ]
then
    short_banner "Mandatory variables were *NOT* found; unable to continue."
    short_banner "The following env. vars. must be set:"
    short_banner "  postgres_db"
    short_banner "  postgres_user"
    short_banner "  postgres_password"
    short_banner "  postgres_endpoint"
    echo
    exit 1
fi

short_banner "Applying answers file for anchore-engine"
sed '
    s/\${postgres_db}/'"${postgres_db}"'/g;
    s/\${postgres_user}/'"${postgres_user}"'/g;
    s/\${postgres_password}/'"${postgres_password}"'/g;
    s/\${postgres_endpoint}/'"${postgres_endpoint}"'/g;
    s/\${postgres_port}/'"${postgres_port:-5432}"'/g;
    s/\${admin_user}/'"${admin_user:-azadmin}"'/g;
    s/\${admin_email}/'"${admin_email:-foo@bar.com}"'/g;
' k8s-vaules.yaml > /tmp/k8s-values.yaml
ret_stat="$?"
if [ "$ret_stat" != "0" ]; 
then 
    short_banner "*****"; 
    short_banner "Error applying $file - skipping"; 
    short_banner "*****"; 
    error_list=$error_list" ${file}---${ret_stat}"
fi

short_banner "Helm install anchore-engine"
helm install --name anchore -f /tmp/k8s-values.yaml stable/anchore-engine

short_banner "Error list:"
for err in $error_list
do
  echo ">>> ERROR: $err"
done

short_banner "Done."
echo
