Gem::Specification.new do |s|
  s.name        = 'dabcup'
  s.version     = '0.1.2'
  s.platform    = Gem::Platform::RUBY
  s.summary     = 'Dabcup is a tool in order to handle databases backups easily'
  s.description = 'You can centralize all you backup policies on a single server, and then store dumps to many different hosts (SSH, S3, FTP).'

  s.required_ruby_version     = '>= 1.8.7'

  s.author            = 'Alexis Bernard'
  s.email             = 'alexis@obloh.com'
  s.homepage          = 'http://dabcup.rubyforge.org/'
  s.rubyforge_project = 'dabcup'

  s.bindir            = 'bin'
  s.executables       = %w(dabcup)
  s.files             = Dir.glob("{bin,lib,config}/**/*") + %w(LICENSE README.rdoc)

  s.add_dependency('aws-s3', '>= 0.6.2')
  s.add_dependency('net-sftp', '>= 2.0.5')
  s.add_dependency('addressable', '>= 2.2.5')
end