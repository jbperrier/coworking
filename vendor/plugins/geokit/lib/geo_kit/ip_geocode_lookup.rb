require 'yaml'

module GeoKit 
  # Contains a class method geocode_ip_address which can be used to enable automatic geocoding
  # for request IP addresses.  The geocoded information is stored in a cookie and in the 
  # session to minimize web service calls.  The point of the helper is to enable location-based
  # websites to have a best-guess for new visitors.
  module IpGeocodeLookup
    # Mix below class methods into ActionController.
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end
    
    # Class method to mix into active record.
    module ClassMethods # :nodoc:
      def geocode_ip_address(filter_options = {})
        before_filter :store_ip_location
      end
    end
 
    private   
         
    # Places the IP address' geocode location into the session if it 
    # can be found.  Otherwise, looks for a geo location cookie and
    # uses that value.  The last resort is to call the web service to
    # get the value.
    def store_ip_location
      session[:geo_location] ||= retrieve_location_from_cookie_or_service
      cookies[:geo_location] = { :value => session[:geo_location].to_yaml, :expires => 30.days.from_now } if session[:geo_location]
    end    
    
    # Uses the stored location value from the cookie if it exists.  If
    # no cookie exists, calls out to the web service to get the location. 
    def retrieve_location_from_cookie_or_service
      return YAML.load(cookies[:geo_location]) if cookies[:geo_location]
      location = Geocoders::IpGeocoder.geocode(get_ip_address)
      return location.success ? location : nil
    end
    
    # Either returns the real ip address or a fake one in the case where
    # doing live testing via localhost.
    def get_ip_address
      
      address = request.remote_ip
      address == '127.0.0.1' ? '12.215.42.19' : address
    end
  end
end