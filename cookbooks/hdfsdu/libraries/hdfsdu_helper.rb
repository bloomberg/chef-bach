require 'net/http'
require 'open-uri'
require 'timeout'
require 'uri'

module Hdfsdu
  module Helper
    def wait_until_ready!(service, endpoint, timeout)
      Timeout.timeout(timeout) do
        begin
          open(endpoint)
        rescue SocketError,
               Errno::ECONNREFUSED,
               Errno::ECONNRESET,
               Errno::ENETUNREACH,
               OpenURI::HTTPError => e
          Chef::Log.debug("#{service} is not accepting requests - #{e.message}")
          sleep(10)
          retry
        end
      end
    rescue Timeout::Error
      raise "#{service} service at #{endpoint} has not become " \
            "ready in #{timeout} seconds."
    end

    # if path contains a wildcard use directory globbing
    # to find the desired file(s)
    # Arguments: A an array of shell glob patterns (must include *) or paths
    # Returns: An array of paths found matching the glob or path if not a glob
    def find_paths(paths)
      paths.map do |path|
        if path.include?('*')
          Dir.glob(path)
        else
          path
        end
      end.flatten
    end
  end
end
