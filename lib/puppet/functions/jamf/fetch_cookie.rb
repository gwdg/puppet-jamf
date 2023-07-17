require 'net/https'
require 'openssl'
require 'ipaddr'
require 'json'

Puppet::Functions.create_function(:'jamf::fetch_cookie') do
  dispatch :fetch_cookie do
    required_param 'String', :api_url
    return_type 'String'
  end

  def fetch_cookie(api_url)
    return_cookie = ''

    url = "#{api_url}/api/startup-status"
    method = 'get'

    # setup our HTTP class
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    # build request
    req = Net::HTTP.const_get(method.capitalize, false).new(uri)

    # execute
    resp = http.request(req)

    # check for success
    case resp
    when Net::HTTPSuccess then
      # Get cookie
      cookie_value = ''
      all_cookies = resp.get_fields('set-cookie')
      all_cookies.each do |cookie|
        cookie_name = cookie.split('; ')[0].split('=')[0]
        cookie_value = cookie.split('; ')[0] if cookie_name == 'APBALANCEID'
      end

      return_cookie = cookie_value
    end
    return_cookie
  end
end
