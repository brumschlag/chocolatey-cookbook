#
# Cookbook Name:: chocolatey
# recipe:: default
# Author:: Guilhem Lettron <guilhem.lettron@youscribe.com>
#
# Copyright 2012, Societe Publica.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
unless node['platform_family'] == 'windows'
  return "Chocolatey install not supported on #{node['platform_family']}"
end

Chef::Resource::RubyBlock.send(:include, Chocolatey::Helpers)

NUGET_PKG = 'chocolatey.nupkg'
nuget_package_path = File.join(Chef::Config['file_cache_path'], NUGET_PKG)
extract_dir = File.join(ENV['TEMP'], 'chocolatey')

#if File.exist?('C:\windows\sysnative\cmd.exe')
#  arch = :x86_64
#  cmd = 'C:\windows\sysnative\cmd.exe'
#else
#  arch = nil
#  cmd = 'cmd.exe'
#end

# Add ability to download Chocolatey install script behind a proxy
# This also works if you are not behind a proxy
command = <<-EOS
  $wc = New-Object Net.WebClient
  $wp=[system.net.WebProxy]::GetDefaultProxy()
  $wp.UseDefaultCredentials=$true
  $wc.Proxy=$wp
  Invoke-Expression ($wc.DownloadString('#{node['chocolatey']['Uri']}'))
EOS

encoded_script = command.encode('UTF-16LE', 'UTF-8')
chocolatey_install_script = Base64.strict_encode64(encoded_script)

batch 'install chocolatey' do
#  architecture arch
#  interpreter cmd
  code <<-EOH
    powershell -noprofile -inputformat none -noninteractive -executionpolicy bypass -EncodedCommand #{chocolatey_install_script}
  EOH
  not_if { ChocolateyHelpers.chocolatey_installed? }
end

windows_zipfile extract_dir do
  action :nothing
  source nuget_package_path
  overwrite true
end

powershell_script 'Install Chocolatey' do
  action :nothing
  cwd File.join(extract_dir, 'tools')
  code install_ps1
end

ruby_block 'Ensure chocolatey.nupkg is in chocolatey/lib/chocolatey/' do
  action :nothing
  block do
    require 'fileutils'
    FileUtils.mv(nuget_package_path, chocolatey_lib_dir)
  end
end
