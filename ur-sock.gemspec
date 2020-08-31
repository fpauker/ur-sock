Gem::Specification.new do |s|
  s.name             = "ur-sock"
  s.version          = "1.0.2"
  s.platform         = Gem::Platform::RUBY
  s.license          = "LGPL-3.0"
  s.summary          = "Preliminary release of Universal Robot (UR) Socket Communication."

  s.description      = "see https://github.com/fpauker/ur-sock"

  s.files            = Dir['{example/**/*,lib/**/*.rb,contrib/logo*}'] + %w(COPYING Rakefile ur-sock.gemspec README.md)
  s.extensions       = Dir["ext/**/extconf.rb"]
  s.require_path     = 'lib'
  s.extra_rdoc_files = ['README.md']

  s.required_ruby_version = '>=2.3.0'

  s.authors          = ['Florian Pauker','Juergen eTM Mangler']

  s.email            = 'florian.pauker@gmail.com'
  s.homepage         = 'https://github.com/fpauker/ur-sock'

	s.add_runtime_dependency 'xml-smart', '>=0.3.6', '~>0'
end
