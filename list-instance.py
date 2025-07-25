#!/usr/bin/env python3
import json
import subprocess
import os

import gspread
from gspread_dataframe import set_with_dataframe
from google.oauth2.credentials import Credentials
import pandas

# Replace these with your own values
SHEET_ID = ""
GOOGLE_SERVICE_ACCOUNT_FILE = ".json"
# ADMIN_OPENRC_FILE = ""

# List computes
computes = [
    'lab-r01-oscompute-01',
    'lab-r01-oscompute-02',
    'lab-r01-oscompute-03',
]


# with open(ADMIN_OPENRC_FILE) as f:
#     for line in f:
#         if line != '\n':
#             var = line.split(' ', 1)[1].split('=', 1)[0]
#             val = line.split(' ', 1)[1].split('=', 1)[1].replace('\n', '')
#             os.environ[var] = val

# Set environment variables from admin-openrc file
def admin_openrc(path):
    with open(path) as o:
        for line in o:
            if line != '\n':
                var = line.split(' ', 1)[1].split('=', 1)[0]
                val = line.split(' ', 1)[1].split('=', 1)[1].replace('\n', '')
                os.environ[var] = val
            else:
                pass

# Authenticate with Google Sheets API
creds = Credentials.from_service_account_file(GOOGLE_SERVICE_ACCOUNT_FILE)
gc = gspread.authorize(creds)

def get_instances_and_volumes():
    instances_and_volumes = []
    cmd = "openstack server list --all-projects -f json"
    output = subprocess.run(cmd.split(), capture_output=True).stdout.decode("utf-8")
    results = json.loads(output)
    for result in results:
        instance_id = result["ID"]
        instance_name = result["Name"]
        project = result["Project"]
        volume_ids = result["Attached Volumes"]
        # Get the details for the instance
        instance_cmd = f"openstack server show {instance_id} -f json"
        instance_output = subprocess.run(instance_cmd.split(), capture_output=True).stdout.decode("utf-8")
        instance_result = json.loads(instance_output)
        image_id = instance_result["image"]["id"]
        image_name = instance_result["image"]["name"]
        flavor = instance_result["flavor"]["name"]
        for volume_id in volume_ids:
            # Get the details for the volume
            volume_cmd = f"openstack volume show {volume_id.strip()} -f json"
            volume_output = subprocess.run(volume_cmd.split(), capture_output=True).stdout.decode("utf-8")
            volume_result = json.loads(volume_output)
            volume_size = volume_result["size"]
            instance_and_volume = {
                "instance_id": instance_id,
                "instance_name": instance_name,
                "project": project,
                "image_id": image_id,
                "image_name": image_name,
                "flavor": flavor,
                "volume_id": volume_id,
                "volume_size": volume_size,
        }
        instances_and_volumes.append(instance_and_volume)
    return instances_and_volumes

# def instance_by_compute(computes):
#     instances = {}
#     for comp in computes:
#         print(f'>>>> Collecting {comp} instances...')
#         raw = getoutput(f'openstack server list --long --all-project --host {comp} -f json')
#         load = json.loads(raw)

#         # if compute not available or no instance at compute
#         if len(load) < 1:
#             print(f'>>>> No instances at {comp}, skipping...\n')
#         else:
#             instances[comp] = load
#             print(f'>>>> Finish collecting {comp} instances...\n')

#     return instances

# def main():
#     # Instance by computes
#     # compute_data = instance_by_compute(computes)

#     # Read the admin-openrc file and set the environment variables
#     admin_openrc('~/admin-openrc')

#     # Get the list of instances and volumes
#     instances_and_volumes = get_instances_and_volumes()

#     # Convert the list of dictionaries to a Pandas dataframe
#     df = pandas.DataFrame(instances_and_volumes)

#     # Group the data by project
#     df = df.groupby("project", as_index=False).apply(pandas.DataFrame.sort_values, "instance_name")

#     # Open the worksheet
#     worksheet = gc.open_by_key(SHEET_ID).sheet1

#     # Clear the worksheet
#     worksheet.clear()

#     # Write the data to the worksheet
#     set_with_dataframe(worksheet, df)

def main():
    # Get the worksheet
    worksheet = gc.open_by_key(SHEET_ID).sheet1

    # Read the admin-openrc file and set the environment variables
    admin_openrc('~/admin-openrc')

    # Get the list of instances and volumes
    instances_and_volumes = get_instances_and_volumes()

    # Convert the list to a DataFrame
    df = pandas.DataFrame(instances_and_volumes)

    # Group the DataFrame by project
    df_grouped_project = df.groupby("project")

    # Merge and center the cells in the project column
    start_row = 1
    for project, group in df_grouped_project:
        end_row = start_row + len(group) - 1
        worksheet.merge_cells(start_row=start_row, start_col=1, end_row=end_row, end_col=1)
        start_row = end_row + 2

    # Write the DataFrame to the worksheet
    set_with_dataframe(worksheet, df)

if __name__ == "__main__":
    main()

