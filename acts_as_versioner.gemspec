Gem::Specification.new do |s|
  s.name = "acts_as_versioner"
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Markus Hediger"]
  s.date = "2018-01-01"
  s.description = "Versioning of ar tables"
  s.email = "m.hed@gmx.ch"
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    "Gemfile",
    "README.md",
    "Rakefile",
    "VERSION",
    "lib/acts_as_versioner/acts_as_versioner.rb",
    "lib/acts_as_versioner/userstamp.rb",
    "lib/acts_as_versioner.rb",
    "acts_as_versioner.gemspec"
  ]
  s.homepage = "http://github.com/kusihed/acts_as_versioner"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.summary = "Versioning of ar tables"

  s.add_development_dependency "rails", "~> 5.0"
  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
  s.add_development_dependency "sqlite3"
end

