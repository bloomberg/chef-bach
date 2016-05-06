require 'net/http'
require 'open-uri'
require 'timeout'
require 'uri'

module Hdfsdu
  module Helper
  extend self

    def wait_until_ready(service, endpoint, timeout)
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
      raise "#{service} service at #{endpoint} has not become ready in #{timeout} seconds."
    end

  end
end

Chef::Recipe.send(:include, Hdfsdu::Helper)
