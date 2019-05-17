require 'rubygems/package_task'

spec = eval(File.read('ur-sock.gemspec'))

task :default => [:gem]

pkg = Gem::PackageTask.new(spec) { |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
  `mkdir pkg`
  `rm pkg/* -rf`
  `ln -sf #{pkg.name}.gem pkg/#{spec.name}.gem`
}

task :push => :gem do |r|
  `gem push pkg/ur-sock.gem`
end

task :install => :gem do |r|
  `gem install pkg/ur-sock.gem`
end
