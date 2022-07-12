Gem::Specification.new do |spec|
  spec.name = "persistent_http_client"
  spec.version = File.read(File.expand_path("../VERSION", __FILE__)).strip
  spec.authors = ["Brian Durand"]
  spec.email = ["bbdurand@gmail.com"]

  spec.summary = "Library for automatically maintaining a pool of persistent connections for the http gem"
  spec.homepage = "https://github.com/bdurand/persistent_http_client"

  # Specify which files should be added to the gem when it is released.
  ignore_files = %w[
    .
    Appraisals
    Gemfile
    Gemfile.lock
    Rakefile
    bin/
    gemfiles/
    spec/
    web_ui.png
  ]
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| ignore_files.any? { |path| f.start_with?(path) } }
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "http", ">= 2.0"
  spec.add_dependency "ref"

  spec.add_development_dependency "bundler"

  spec.required_ruby_version = ">= 2.5"
end
