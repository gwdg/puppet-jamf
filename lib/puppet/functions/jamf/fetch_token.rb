require 'net/https'
require 'openssl'
require 'ipaddr'
require 'json'

Puppet::Functions.create_function(:'jamf::fetch_token') do
  dispatch :fetch_token do
    required_param 'String', :username
    required_param 'String', :password
    required_param 'String', :api_url
    required_param 'Boolean', :is_cloud
    return_type 'String'
  end

  def fetch_token(username, password, api_url, is_cloud)
    # NOTE: we must not grab the authentication token if we are dealing
    #       with an uninitialized internal jamf server. this is where
    #       we deal with that case
    is_initialized = true
    unless is_cloud
      health_url = "#{api_url}/healthCheck.html"
      health_method = 'get'

      health_uri = URI.parse(health_url)
      health_http = Net::HTTP.new(health_uri.host, health_uri.port)
      health_http.use_ssl = health_uri.scheme == 'https'
      health_http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      health_req = Net::HTTP.const_get(health_method.capitalize, false).new(health_uri)

      health_resp = health_http.request(health_req)

      case health_resp
      when Net::HTTPSuccess then
        health_data = JSON.parse(health_resp.body)
        if health_data.size >= 1
          is_initialized = false
        end
      end
    end

    # create return string
    auth_token = ''

    if is_initialized
      url = "#{api_url}/api/v1/auth/token"
      method = 'post'

      # setup our HTTP class
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      # build request
      req = Net::HTTP.const_get(method.capitalize, false).new(uri)
      req.basic_auth(username, password)

      # execute
      resp = http.request(req)

      # check for success
      case resp
      when Net::HTTPSuccess then
        # parse body and get token
        body_json = JSON.parse(resp.body)
        token = body_json['token']

        auth_token = token
      end
    end
    auth_token
  end
end
