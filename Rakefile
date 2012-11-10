# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.spec 'cove' do
  developer('Jeremie Castagna', 'yaksnrainbows@gmail.com')
  self.readme_file      = "README.rdoc"
  self.history_file     = "History.rdoc"
  self.extra_rdoc_files = FileList['*.rdoc']
  self.spec_extras[:extensions] = ["cove/extconf.rb"]
end

desc "Uses extconf.rb and make to build the extension"
task :extension do
  old_dir = Dir.pwd
  begin
    Dir.chdir('ext/cove')
    system("ruby extconf.rb --with-R-dir=$R_HOME")
    system("make")
  ensure
    Dir.chdir(old_dir)
  end
end

# vim: syntax=ruby
