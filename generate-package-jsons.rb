#!/usr/bin/ruby

require 'digest'
require 'fileutils'
require 'json'

def arch name
  return "x86_64" if name == "amd64"
  return "i386" if ["x86", "i686"].include? name
  return name
end

input_dir = ARGV[0] or nil
output_dir = ARGV[1] or nil
output = {}

unless input_dir.nil?
  Dir.glob("#{input_dir}/**/*") do |path|
    next unless File.file? path

    basename = File.basename path
    extension = File.extname path

    regex = nil

    file_info = nil
    package = nil
    version = nil

    case extension
    when ".deb"
      regex = /^(?<package>[a-z0-9-]+)_(?<version>[0-9.]+)_(?<arch>i386|amd64|all)\.(?<type>deb)$/

    when ".gz", ".zip"
      regex = /^(?<package>[a-z0-9-]+)-(?<version>[0-9.]+)(-(?<os>linux))?-(?<arch>i386|x86_64|src)\.(?<type>tar\.gz|zip)$/

    when ".dmg"
      regex = /^(?<package>[a-z0-9-]+)-(?<version>[0-9.]+)-(?<os>osx)-universal\.(?<type>dmg)$/

    when ".exe", ".msi"
      regex = /^(?<package>[a-z0-9-]+)-(?<version>[0-9.]+)-(?<os>windows)-(?<arch>x86|x86_64)\.(?<type>msi|exe)$/

    when ".rpm"
      regex = /^(?<package>[a-z0-9-]+)-(?<version>[0-9.]+)-\d+\.(?<arch>i686|x86_64|noarch)\.(?<type>rpm)$/
    end

    if regex.nil?
      puts "Skipping #{path}"
      next
    end

    match = regex.match(basename)
    md = Hash[match.names.zip(match.captures)] unless match.nil?

    next if md.nil?

    package = md["package"]
    version = md["version"]

    file_info = {
      :os => md["os"],
      :arch => arch(md["arch"]),
      :type => md["type"],
      :filename => basename,
      :url => "http://files.axrproject.org/packages/#{package}/#{version}/#{basename}",
      :size => File.size?(path),
      :checksums => {
        :md5 => Digest::MD5.file(path).hexdigest,
        :sha1 => Digest::SHA1.file(path).hexdigest
      }
    }

    file_info[:os] = "linux" if [".deb", ".rpm"].include? extension

    if md["os"] == "osx" and md["arch"] == "universal"
      file_info[:arch] = "intel"
    end

    if md["arch"] == "src"
      file_info[:os] = "src"
      file_info[:arch] = "none"
    end

    output[package] = output[package] || {}
    output[package][version] = output[package][version] || []
    output[package][version].push file_info
  end

  output.each do |package, versions|
    unless File.directory? "#{output_dir}/#{package}"
      FileUtils.mkdir_p "#{output_dir}/#{package}"
    end

    versions.each do |version, files|
      path = "#{output_dir}/#{package}/release-#{version}.json"

      release_info = {
        :package => package,
        :version => version,
        :files => files
      }

      File.open("#{output_dir}/#{package}/release-#{version}.json", "w") do |file|
        file.write JSON.pretty_generate(release_info, {
          :indent => "\t"
        })
      end
    end
  end
else
  puts "Usage: #{File.basename(__FILE__)} INPUT [OUTPUT]"
  puts "Recursively scan the INPUT directory and generate JSON files describing the found packages."
end
