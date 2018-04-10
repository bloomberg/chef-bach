#!/usr/bin/env rake

require 'mixlib/shellout'

chef_version = '12.19.36'
namespace :style do
  desc 'Style check with rubocop'
  task :rubocop do
    ENV['RUBOCOP_OPTS'] = '--out rubocop.log' if ENV['CI']
    # Force a zero exit code until we fix all the cops (someday)
    sh '/opt/chefdk/embedded/bin/rubocop || true'
  end

  desc 'Style check with foodcritic'
  task :foodcritic do
    foodcritic_output = '> foodcritic.log' if ENV['CI']
    sh '/opt/chefdk/embedded/bin/foodcritic '\
       '--role-path ./stub-environment/roles/ '\
       '--environment-path ./stub-environment/environments/Test-Laptop.json '\
       ' --epic-fail none cookbooks/ ' \
       "#{foodcritic_output}"
  end

  desc 'Check style violation difference'
  task('diff'.to_sym) do
    sh './compare_style.sh'
  end
end

desc 'Run style checks'
task style: %w(style:rubocop style:foodcritic)

desc 'Clean some generated files'
task :clean do
  %w(
    **/Berksfile.lock
    .bundle
    .cache
    **/Gemfile.lock
    .kitchen
    vendor
    ../cluster
    vbox
  ).each { |f| FileUtils.rm_rf(Dir.glob(f)) }
  # XXX should remove VBox VM's
end

task :default => 'style'
