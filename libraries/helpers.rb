module Chocolatey
  module Helpers
    # Get the ChocolateyInstall directory from the environment.
    def chocolatey_install
      ENV.fetch('ChocolateyInstall') { |env_var| machine_env_var(env_var) }
    end

    # The Chocolatey command.
    #
    # Reference: https://github.com/chocolatey/chocolatey-cookbook/pull/16#issuecomment-47975896
    def chocolatey_executable
      "\"#{::File.join(chocolatey_install, 'bin', 'choco')}\""
    end

    def chocolatey_lib_dir
      File.join(chocolatey_install, 'lib', 'chocolatey')
    end

    # Check if Chocolatey is installed
    def chocolatey_installed?
      return @is_chocolatey_installed if @is_chocolatey_installed
      return false if chocolatey_install.nil?
      # choco /? returns an exit status of -1 with chocolatey 0.9.9 => use list
      cmd = Mixlib::ShellOut.new("#{chocolatey_executable} list -l chocolatey")
      cmd.run_command
      @is_chocolatey_installed = (cmd.exitstatus == 0)
    end

    private

    def machine_env_var(env_var)
        env_var(env_var, 'MACHINE')
    end

    def env_var(env_var, scope)
      env_var = powershell_out!(
        "[System.Environment]::GetEnvironmentVariable('#{env_var}', '#{scope}')"
      )
      env_var.stdout.chomp
    end

    # combine the local path with the user and machine paths
    def env_path(local_path)
        machine  = env_var('PATH', 'MACHINE').split(';')
        user     = env_var('PATH', 'USER').split(';')
        local    = local_path.split(';')
        combined = local.concat(user).concat(machine).uniq().compact()
        return combined.join(';')
    end


  end
end
