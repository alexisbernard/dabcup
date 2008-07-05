class Dabcup::Help
  def self.message(name)
    @@messages[name]
  end
  
  default_help = <<__HELP__
Usage:
  dabcup <profile> <operation> [parameters]

Operations:
  clean
  delete
  list
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

$ dabcup <profile> clean
__HELP__

  @@messages['delete'] = <<__HELP__
Deletes the specified dump.

dabcup <profile> <dump>
__HELP__

  @@messages['list'] = <<__HELP__
Lists dumps.

dabcup <profile> list
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