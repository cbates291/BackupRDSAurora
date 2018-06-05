require 'aws-sdk'
require 'date'

#Variables for this script
rdsclient = Aws::RDS::Client.new
resp = rdsclient.describe_db_cluster_snapshots
dbarray = resp.db_cluster_snapshots
currentdate = Date.today
monthold = currentdate  - 31
REGION = 'us-east-1'
ACCOUNT_NUMBER = 'XXXXXXXXXXXXXXX'
matching_tables = Array.new
matchingSnaps = Array.new
BACKUP_KEY = "DBSnapCreationMethod"
BACKUP_VALUE = "RubyScript"

# Creates array of DB cluster snapshot  identifer objects/names
identifiers = dbarray.map { |db| db.db_cluster_snapshot_identifier }

# Goes through each identifier and pulls the tags and builds them into the matching_tables array if they match the criteria
identifiers.each do |id|
   tags = rdsclient.list_tags_for_resource({
      resource_name: "arn:aws:rds:#{REGION}:#{ACCOUNT_NUMBER}:cluster-snapshot:#{id}"
   })
   shouldBackup = false
   backupTags = tags["tag_list"].select {|tag| tag["key"] == BACKUP_KEY} # should only be one, but will be nil or an array
   shouldBackup = backupTags[0]["value"] unless (backupTags.nil? || backupTags[0].nil?)
   matching_tables.push(id) if shouldBackup == BACKUP_VALUE #Pushes the matching id into the array for processing the backups  
end

# Goes through the matching_tables array and finds the creation time for each snapshot
matching_tables.each do |id|
   clustersnaps = rdsclient.describe_db_cluster_snapshots({ db_cluster_snapshot_identifier: id })
   clustersnapsarray = clustersnaps.db_cluster_snapshots
   clustersnaptime = clustersnapsarray.map { |cluster| cluster.snapshot_create_time}
   if DateTime.parse("#{clustersnaptime}").to_date <= monthold
      matchingSnaps.push(id) 
   else
      puts "Not old enough, not deleting snapshot #{id}"
   end
end

#Go through the matchingSnaps array and delete the snapshot as it is old enough, etc.
matchingSnaps.each do |id|
   deleteSnaps = rdsclient.delete_db_cluster_snapshot ({
      db_cluster_snapshot_identifier: id
   })
   puts "Deleted Snapshot #{id}"
end
