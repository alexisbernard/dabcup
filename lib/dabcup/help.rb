class Dabcup::Help
  def self.message(name)
    @@messages[name]
  end
  
  default_help = <<__HELP__
Usage:
  dabcup <profile> <operation> [parameters]

Operations:
  clean
  clear
  delete
  get
  list
  populate
  restore
  store

Try 'dabcup help <operation>' to get details.
Visit http://dabcup.obloh.com for more informations.
__HELP__
 
  @@messages = Hash.new(default_help)
  
  @@messages['clean'] = <<__HELP__
Removes old dumps from the storage and the spare storage. Clean rules are
specified int the 'keep' section of your profile.

my-profile:
  keep:
    days_of_week: 1     # Keeps all dumps of the first day of the week
    less_days_than: 50  # Keep dumps younger than 50 days

dabcup <profile> clean
__HELP__

  @@messages['clear'] = <<__HELP__
Delete all dumps from the main and the spare storages. Use safely this operation
because no confirmation is asked.

dabcup <profile> clear
__HELP__
  
  @@messages['delete'] = <<__HELP__
Deletes the specified dump.

dabcup <profile> <dump>
__HELP__
  
  @@messages['get'] = <<__HELP__
Retrieves the specified dump from the main or the spare storage. The local path
represents where you want to retrieve the dump. If not specified the dump will
be downloaded into the current directory.

dabcup <profile> get <dump> [<local_path>]
__HELP__

  @@messages['list'] = <<__HELP__
Lists dumps of the both storages. The flags 'M' and 'S' means if the dump is
in the main and/or the spare storage.

dabcup <profile> list
__HELP__

  @@messages['populate'] = <<__HELP__
The purpose of this operation is only to help you to test clean rules. It 
populates the main and the spare storages with n backups. Each backup get back a
day before.

dabcup <profile> populate <n>
__HELP__
  
  @@messages['restore'] = <<__HELP__
Download the specified dump from the storage, or the spare storage,
and restore it to the database. Use 'list' operation to see dumps.

dabcup <profile> restore <dump>
__HELP__

  @@messages['store'] = <<__HELP__
Dump the database, and upload it to the storage, and sare storage it set.

dabcup <profile> store
__HELP__
end