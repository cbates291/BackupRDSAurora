require 'aws-sdk'
require 'date'

#Variables for this script
rdsclient = Aws::RDS::Client.new
resp = rdsclient.describe_db_instances
dbarray = resp.db_instances
currentdate = Date.today.to_s
REGION = 'us-east-1'
ACCOUNT_NUMBER = 'XXXXXXXXXXXXXX'
matching_tables = Array.new
BACKUP_KEY = "Backup"
BACKUP_VALUE = "True"
clusteridarray = Array.new

# Creates array of DB identifer objects/names
identifiers = dbarray.map { |db| db.db_instance_identifier }

# Goes through each identifier and pulls the tags and builds them into the matching_tables array if they match the criteria
identifiers.each do |id|
   tags = rdsclient.list_tags_for_resource({
      resource_name: "arn:aws:rds:#{REGION}:#{ACCOUNT_NUMBER}:db:#{id}"
   })
   shouldBackup = false
   backupTags = tags["tag_list"].select {|tag| tag["key"] == BACKUP_KEY} # should only be one, but will be nil or an array
   shouldBackup = backupTags[0]["value"] unless (backupTags.nil? || backupTags[0].nil?)
   matching_tables.push(id) if shouldBackup == BACKUP_VALUE #Pushes the matching id into the array for processing the backups  
end

# Goes through matching_tables and finds the cluster ID which is needed to perform the snapshot
matching_tables.each do |id|
   cluster = rdsclient.describe_db_instances({
      db_instance_identifier: id
   })
   clusterarray = cluster.db_instances
   clusterid = clusterarray.map { |cluster| cluster.db_cluster_identifier } #Maps the cluster ID to the clusterid variable
   clusteridarray.push(clusterid)
end

#Function to perform the snapshots of the DB's in the clusteridarray, array
clusteridarray.each do |id|
   snap = rdsclient.create_db_cluster_snapshot({
    db_cluster_identifier: id.join(", "),
    db_cluster_snapshot_identifier: id.join(", ") + "-" + currentdate + "-" + "rubyscript",
       tags: [
       {
          key: "DBSnapCreationMethod",
          value: "RubyScript",
       },
       ]
   })
end
