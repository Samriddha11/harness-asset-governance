#!/bin/bash

# Capture Harness pipeline variables
account_id="<+pipeline.variables.account_id>"
region="<+pipeline.variables.region>"
resource="<+pipeline.variables.resource>"

echo "*****Show Account*****"
echo "$account_id"
echo "******END*****"
echo "*****Show Region*****"
echo "$region"
echo "******END*****"

echo "*****Show resources*****"
echo "$resource"
echo "******END*****"

# The resource is not strictly valid JSON. We attempt to convert it into valid JSON.
# This example assumes the structure remains consistent.
# Variables

email_content=$(echo "$resource" | \
  sed -e 's/^{volumes:\[\[{//' -e 's/}\]\]}$//' | \
  sed 's/},{/\n/g' | \
  grep -v '^[[:space:]]*$' | \
  awk -F, -v tz="America/New_York" -v account_id="$account_id" '
    BEGIN {
      print "<html><head><title>AWS Unattached EBS Volumes Report</title></head><body>"
      print "<h2 style=\"font-family:Arial, sans-serif; color:blue;\">AWS Unattached EBS Volumes Report</h2>"
      print "<p style=\"font-family:Arial, sans-serif; color:#555;\">The following EBS volumes are not attached to any EC2 instances and are currently in an unattached state. Please review the volumes listed below:</p>"
    }
    {
      vol_id=""
      create_time=""
      owner=""
      for (i=1; i<=NF; i++) {
        if ($i ~ /VolumeId:/) { vol_id=substr($i,index($i,":")+1) }
        if ($i ~ /CreateTime:/) { create_time=substr($i,index($i,":")+1) }
        if ($i ~ /Owner:/) { owner=substr($i,index($i,":")+1) }
      }

      if (vol_id != "") {
        cmd="TZ=" tz " date -d \"" create_time "\" +\"%Y-%m-%d %H:%M:%S %Z\""
        cmd | getline est_time
        close(cmd)

        row_color = ((NR % 2) == 0) ? "#f9f9f9" : "#ffffff"
        rows = rows "<tr style=\"background-color:" row_color ";\">"
        rows = rows "<td style=\"font-family:Arial,sans-serif; padding:8px; border:1px solid #ccc;\">" vol_id "</td>"
        rows = rows "<td style=\"font-family:Arial,sans-serif; padding:8px; border:1px solid #ccc;\">" owner "</td>"
        rows = rows "<td style=\"font-family:Arial,sans-serif; padding:8px; border:1px solid #ccc;\">" est_time "</td></tr>\n"
      }
    }
    END {
      print "<p style=\"font-family:Arial, sans-serif; color:#555;\"><strong>AWS Account:</strong> " account_id "</p>"
      print "<table style=\"border-collapse:collapse; width:80%; font-family:Arial,sans-serif; border:1px solid #ccc;\">"
      print "<tr style=\"background-color:#f2f2f2;\"><th style=\"padding:8px; border:1px solid #ccc; text-align:left;\">Volume ID</th><th style=\"padding:8px; border:1px solid #ccc; text-align:left;\">Owner</th><th style=\"padding:8px; border:1px solid #ccc; text-align:left;\">Create Time (EST)</th></tr>"
      print rows
      print "</table>"
      print "</body></html>"
    }
  '
)

export $email_content
