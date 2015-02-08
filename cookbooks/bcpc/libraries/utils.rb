#
# Cookbook Name:: bcpc
# Library:: utils
#
# Copyright 2013, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'openssl'
require 'base64'
require 'thread'
require 'ipaddr'

module Bcpc
  module Helper
    def power_of_2(number)
    	result = 1
    	while (result < number) do result <<= 1 end
    	return result
    end
    module_function :power_of_2
    
    def secure_password(len=20)
    	pw = String.new
    	while pw.length < len
    		pw << ::OpenSSL::Random.random_bytes(1).gsub(/\W/, '')
    	end
    	pw
    end
    module_function :secure_password
    
    def secure_password_alphanum_upper(len=20)
        # Chef's syntax checker doesn't like multiple exploders in same line. Sigh.
        alphanum_upper = [*'0'..'9']
        alphanum_upper += [*'A'..'Z']
        # We could probably optimize this to be in one pass if we could easily
        # handle the case where random_bytes doesn't return a rejected char.
        raw_pw = String.new
        while raw_pw.length < len
            raw_pw << ::OpenSSL::Random.random_bytes(1).gsub(/\W/, '')
        end
        pw = String.new
        while pw.length < len
            pw << alphanum_upper[raw_pw.bytes().to_a()[pw.length] % alphanum_upper.length]
        end
        pw
    end
    module_function :secure_password_alphanum_upper
    
  end
end

Chef::Recipe.send(:include, Bcpc::Helper)
