# BackupRDSAurora
### Backup AWS Aurora Databases that have the correct tags

#### aws-rds-monthly-backup.rb
- This file creates a backup of any Aurora RDS instance that is tagged as the following:
   - Backup = True
- It will also tag the snapshot that is created so that you can easily identify what was made via this method and can also be used to delete them as well.

#### DeleteRDSBackup.rb
- This file by default will delete any Snapshot that is older than 31 days and is tagged as the following:
   - DBSnapCreationMethod = RubyScript (this is created using the rb script above)
- This can be edited to only delete if its older or newer. Simply edit the monthold variable
