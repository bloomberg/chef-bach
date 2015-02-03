require 'net/http'
require 'open-uri'
require 'timeout'
require 'uri'

def wait_until_ready(endpoint, timeout)
   Timeout.timeout(timeout) do
      begin
         open(endpoint)
      rescue SocketError,
             Errno::ECONNREFUSED,
             Errno::ECONNRESET,
             Errno::ENETUNREACH,
             OpenURI::HTTPError => e
         Chef::Log.debug("Hannibal is not accepting requests - #{e.message}")
         sleep(10)
         retry
      end
   end
   rescue Timeout::Error
   raise "Hannibal service at #{endpoint} has not become ready in #{timeout} seconds."
end

