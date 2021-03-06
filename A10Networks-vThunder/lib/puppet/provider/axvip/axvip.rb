# Custom provider for creating/deleting vips on A10
# Copyright 2015, A10 Networks provided as is
#
# All rights reserved - Do Not Redistribute
# send bugs to darmada@a10networks.com
#


require 'net/https'
require 'net/http'


Puppet::Type.type(:axvip).provide(:axvip) do

    def exists?
        @session_id = self.connect(@resource[:axdevice], @resource[:username], @resource[:password])
        ret = get_vip(@resource[:axdevice], @resource[:username], @resource[:password], @session_id, @resource[:name])
        close_session(@resource[:axdevice], @session_id)
        return ret
    end

    def create
        @session_id = self.connect(@resource[:axdevice], @resource[:username], @resource[:password])
        create_vip(@resource[:axdevice], @resource[:username], @resource[:password], @session_id, @resource[:name], @resource[:ipaddress])
        if @resource[:natpool] != nil
        	create_nat_pool(@resource[:axdevice], @resource[:username], @resource[:password], @session_id, @resource[:natpool], @resource[:startaddress], @resource[:endaddress], @resource[:netmask])
        end
	puts 'About to create vport'
        create_vports(@resource[:axdevice], @resource[:username], @resource[:password], @session_id, @resource[:name], @resource[:group], @resource[:port], 
			@resource[:type], @resource[:natpool], @resource[:ssltemplate])
        close_session(@resource[:axdevice], @session_id)
    end

    def destroy
        @session_id = self.connect(@resource[:axdevice], @resource[:username], @resource[:password])
        delete_vip(@resource[:axdevice], @resource[:username], @resource[:password], @session_id, @resource[:name])
        if @resource[:natpool] != nil
			delete_nat_pool(@resource[:axdevice], @resource[:username], @resource[:password], @session_id, @resource[:natpool])
		end
		close_session(@resource[:axdevice], @session_id)
	end

	def connect(axdevice, username, password)
		post_body = {"credentials" => {"username" => username, "password" => password }}
		headers = {"Content-Type" => "application/json"}
		base_uri = '/axapi/v3/auth'
		resp = run_https(axdevice, base_uri, headers, "post", post_body.to_json)
		decoded_json = JSON.parse(resp.body)
		return decoded_json["authresponse"]["signature"]
    end

	def delete_vip(axdevice, username, password, sessionid, vipname)
		signature = 'A10 ' + sessionid
		headers = {"Authorization" => signature, "Content-Type" => "application/json"}
		base_uri= '/axapi/v3/slb/virtual-server/' + vipname + '/'
		resp = run_https(axdevice, base_uri, headers, "delete")
		handle_response(resp)
	end

	def delete_nat_pool(axdevice, username, password, sessionid, natpool)
		signature = 'A10 ' + sessionid
		headers = {"Authorization" => signature, "Content-Type" => "application/json"}
		base_uri= '/axapi/v3/ip/nat/pool/' + natpool + '/'
		resp = run_https(axdevice, base_uri, headers, "delete")
		handle_response(resp)
	end

	def close_session(axdevice, sessionid)
		signature = 'A10 ' + sessionid
		headers = {"Authorization" => signature, "Content-Type" => "application/json"}
		base_uri = '/axapi/v3/logoff'
		resp = run_https(axdevice, base_uri, headers, "post", {}.to_json)
		handle_response(resp)
	end

	def run_https(axdevice, base_uri, headers, http_method, http_body=nil)
		request_url = 'https://' + axdevice + base_uri
		uri= URI.parse(request_url)
		req = Net::HTTP.new(uri.host, uri.port)             
		req.use_ssl = true
		req.verify_mode = OpenSSL::SSL::VERIFY_NONE
		
		# To call the correct http method using the variable http_method. It's equivalent to resp = req.http_method(*args). *args will be two or three arguments depending on whether there's http payload or not
		if http_body != nil
			resp = req.send(http_method, uri.path, http_body, headers)
		else
			resp = req.send(http_method, uri.path, headers)			
		end
		return resp	
	end

	def handle_response(resp)
		decoded_json = JSON.parse(resp.body)
		if decoded_json.has_key?("virtual-server")
			Puppet::debug('A10 says: virtual-server ' + decoded_json["virtual-server"]["name"])
			return true
		elsif decoded_json.has_key?("response")
			if decoded_json["response"]["status"] == "fail"
				error = decoded_json["response"]["err"]
				if error["code"] == 1023443968
					# vip not exists
					Puppet::debug(error["msg"])
					return false
				else
					raise 'A10 says: ' + decoded_json["response"] +  "\n"        	
					Puppet::debug("Dumping: "+ decoded_json)
				end
			end
		else
			raise 'Unknown error occurred'
			Puppet::debug("Dumping: "+ decoded_json)	
		end	
	end

	def create_vip(axdevice, username, password, sessionid, vipname, vipaddress)
		post_body = {"virtual-server-list" => [{"name" => vipname, "ip-address" => vipaddress}]}
		signature = 'A10 ' + sessionid
		headers = {"Authorization" => signature, "Content-Type" => "application/json"}
		base_uri= '/axapi/v3/slb/virtual-server/'
		resp = run_https(axdevice, base_uri, headers, "post", post_body.to_json)		
		handle_response(resp)
	end
	
	def create_nat_pool(axdevice, username, password, sessionid, natpool, startaddress, endaddress, netmask)
		post_body = {"pool-list" => [{"pool-name" => natpool, "start-address" => startaddress, 
									  "end-address" => endaddress, "netmask" => netmask}]}
		signature = 'A10 ' + sessionid
		headers = {"Authorization" => signature, "Content-Type" => "application/json"}
		base_uri= '/axapi/v3/ip/nat/pool/'
		resp = run_https(axdevice, base_uri, headers, "post", post_body.to_json)
	end
	
	def create_vports(axdevice, username, password, sessionid, vipname, servicegroup, port, type, natpool, ssltemplate)
		if type == 'http'
      		if natpool == nil
      			post_body = {"port-list" => [{"protocol" => type, "port-number" => port.to_i, 
      										  "service-group" => servicegroup}]}
      		else
                post_body = {"port-list" => [{"protocol" => type, "port-number" => port.to_i, 
      										  "service-group" => servicegroup, 
      										  "pool" => natpool}]}
        	end
    	elsif type == 'https'
    		if natpool == nil  				
    			post_body = {"port-list" => [{"protocol" => type, "port-number" => port.to_i, 
      										  "service-group" => servicegroup,
      										  "template-client-ssl" => ssltemplate}]}
      		else
				post_body = {"port-list" => [{"protocol" => type, "port-number" => port.to_i, 
      										  "service-group" => servicegroup, 
      										  "pool" => natpool,
      										  "template-client-ssl" => ssltemplate}]}
        	end
     	end
    	signature = 'A10 ' + sessionid
		headers = {"Authorization" => signature, "Content-Type" => "application/json"}
		base_uri= '/axapi/v3/slb/virtual-server/' + vipname + '/port/'		
		resp = run_https(axdevice, base_uri, headers, "post", post_body.to_json)	
	end

	def get_vip(axdevice, username, password, sessionid,vipname)
		signature = 'A10 ' + sessionid
		headers = {"Authorization" => signature, "Content-Type" => "application/json"}
		base_uri= '/axapi/v3/slb/virtual-server/' + vipname + '/'
		resp = run_https(axdevice, base_uri, headers, "get") 
		handle_response(resp)
	end
end
