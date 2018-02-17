require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/test_acts_as_versioner.rb']
  t.verbose = true
end

desc "Run tests"
task :default => :test