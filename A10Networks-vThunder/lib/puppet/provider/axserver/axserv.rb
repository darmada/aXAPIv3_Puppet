# Custom provider for creating/deleting real servers on A10
# Copyright 2015, A10 Networks provided as is
#
# All rights reserved - Do Not Redistribute
# send bugs to darmada@a10networks.com
#


require 'net/https'
require 'net/http'

Puppet::Type.type(:axserver).provide(:axserv) do
	
	def exists?
		@session_id = self.connect(@resource[:axdevice], @resource[:username], @resource[:password])
		ret = get_server(@resource[:axdevice], @resource[:username], @resource[:password], @session_id, @resource[:name])
		close_session(@resource[:axdevice], @session_id)
		return ret
	end

	def create
		@session_id = self.connect(@resource[:axdevice], @resource[:username], @resource[:password])
		ret = create_server(@resource[:axdevice], @resource[:username], @resource[:password], @session_id, @resource[:name], @resource[:ipaddress])
		if ret == true
			create_server_port(@resource[:axdevice], @resource[:username], @resource[:password], @session_id, @resource[:name], @resource[:httpport])
		end	
		close_session(@resource[:axdevice], @session_id)
		Puppet::debug("creating server " + @resource[:name])
	end

	def destroy
		@session_id = self.connect(@resource[:axdevice], @resource[:username], @resource[:password])
		delete_server(@resource[:axdevice], @resource[:username], @resource[:password], @session_id, @resource[:name])
		Puppet::debug("destroying server " + @resource[:name]) 
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

	def create_server(axdevice, username, password, sessionid, servername, serveraddress)
		post_body = {"server-list" => [{"name" => servername, "host" => serveraddress, "health-check-disable" => 1}]}
		signature = 'A10 ' + sessionid
		headers = {"Authorization" => signature, "Content-Type" => "application/json"}
		base_uri= '/axapi/v3/slb/server/'
		resp = run_https(axdevice, base_uri, headers, "post", post_body.to_json)		
		decoded_json = JSON.parse(resp.body)
		handle_response(resp)
	end

	def create_server_port(axdevice, username, password, sessionid, servername, port)
		post_body = {"port-list" => [{"port-number" => port, "protocol" => "tcp", "health-check-disable" => 1}]}
		signature = 'A10 ' + sessionid
		headers = {"Authorization" => signature, "Content-Type" => "application/json"}
		base_uri= '/axapi/v3/slb/server/' + servername + '/port/'
		resp = run_https(axdevice, base_uri, headers, "put", post_body.to_json)
	end

	def delete_server(axdevice, username, password, sessionid, servername)
		signature = 'A10 ' + sessionid
		headers = {"Authorization" => signature, "Content-Type" => "application/json"}
		base_uri= '/axapi/v3/slb/server/' + servername + '/'
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
		if decoded_json.has_key?("server")
			Puppet::debug('A10 says: server ' + decoded_json["server"]["name"] + ', IP address ' + decoded_json["server"]["host"])			
			return true
		elsif decoded_json.has_key?("response")
			if decoded_json["response"]["status"] == "fail"
				error = decoded_json["response"]["err"]
				if error["code"] == 1023443968
					# server not exists
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

	def get_server(axdevice, username, password, sessionid, servername)
		signature = 'A10 ' + sessionid
		headers = {"Authorization" => signature, "Content-Type" => "application/json"}
		base_uri= '/axapi/v3/slb/server/' + servername + '/'
		resp = run_https(axdevice, base_uri, headers, "get") 
		handle_response(resp)		
	end

end
