require 'net/http'
require 'rexml/document'
require 'yaml'

module GeoKit
  # Contains a set of geocoders which can be used independently if desired.  The list contains:
  # 
  # * Google Geocoder - requires an API key.
  # * Yahoo Geocoder - requires an API key.
  # * Geocoder.us - may require authentication if performing more than the free request limit.
  # * Geocoder.ca - for Canada; may require authentication as well.
  # * IP Geocoder - geocodes an IP address using hostip.info's web service.
  # * Multi Geocoder - provides failover for the physical location geocoders.
  # 
  # Some configuration is required for these geocoders and can be located in the environment
  # configuration files.
  module Geocoders
    # Error which is thrown in the event a geocoding error occurs.
    class GeocodeError < StandardError; end
    
    # The Geocoder base class which defines the interface to be used by all
    # other geocoders.
    class Geocoder   
      # Main method which calls the do_geocode template method which subclasses
      # are responsible for implementing.  Returns a populated GeoLoc or an
      # empty one with a failed success code.
      def self.geocode(address)  
        res = do_geocode(address)
        return res.success ? res : GeoLoc.new
      end  

      protected

      def self.logger() RAILS_DEFAULT_LOGGER; end
      
      private
      
      # Adds subclass' geocode method making it conveniently available through 
      # the base class.
      def self.inherited(clazz)
        class_name = clazz.name.split('::').last
        src = <<-END_SRC
          def self.#{class_name.underscore}(address)
            #{class_name}.geocode(address)
          end
        END_SRC
        class_eval(src)
      end
    end
    
    # Geocoder CA geocoder implementation.  Requires the GeoKit::Geocoders::GEOCODER_CA variable to
    # contain true or false based upon whether authentication is to occur.  Conforms to the 
    # interface set by the Geocoder class.
    #
    # Returns a response like:
    # <?xml version="1.0" encoding="UTF-8" ?>
    # <geodata>
    #   <latt>49.243086</latt>
    #   <longt>-123.153684</longt>
    # </geodata>
    class CaGeocoder < Geocoder

      private

      # Template method which does the geocode lookup.
      def self.do_geocode(address)
        raise ArgumentError 'Geocoder.ca requires a GeoLoc argument' unless address.is_a?(GeoLoc)
        url = construct_request(address)
        res = Net::HTTP.get_response(URI.parse(url))
        return GeoLoc.new if !res.is_a?(Net::HTTPSuccess)
        xml = res.body
        logger.debug "Geocoder.ca geocoding. Address: #{address}. Result: #{xml}"
        # Parse the document.
        doc = REXML::Document.new(xml)    
        address.lat = doc.elements['//latt'].text
        address.lng = doc.elements['//longt'].text
        address.success = true
        return address
      rescue
        logger.error "Caught an error during Geocoder.ca geocoding call: "+$!
        return GeoLoc.new  
      end  

      # Formats the request in the format acceptable by the CA geocoder.
      def self.construct_request(location)
        url = ""
        url += add_ampersand(url) + "stno=#{location.street_number}" if location.street_address
        url += add_ampersand(url) + "addresst=#{CGI.escape(location.street_name)}" if location.street_address
        url += add_ampersand(url) + "city=#{CGI.escape(location.city)}" if location.city
        url += add_ampersand(url) + "prov=#{location.state}" if location.state
        url += add_ampersand(url) + "postal=#{location.zip}" if location.zip
        url += add_ampersand(url) + "auth=#{GeoKit::Geocoders::GEOCODER_CA}" if GeoKit::Geocoders::GEOCODER_CA
        url += add_ampersand(url) + "geoit=xml"
        'http://geocoder.ca/?' + url
      end

      def self.add_ampersand(url)
        url && url.length > 0 ? "&" : ""
      end
    end    
    
    # Google geocoder implementation.  Requires the GeoKit::Geocoders::GOOGLE variable to
    # contain a Google API key.  Conforms to the interface set by the Geocoder class.
    class GoogleGeocoder < Geocoder

      private 

      # Template method which does the geocode lookup.
      def self.do_geocode(address)
        address_str = address.is_a?(GeoLoc) ? address.to_geocodeable_s : address
        res = Net::HTTP.get_response(URI.parse("http://maps.google.com/maps/geo?q=#{CGI.escape(address_str)}&output=xml&key=#{GeoKit::Geocoders::GOOGLE}&oe=utf-8"))
        return GeoLoc.new if !res.is_a?(Net::HTTPSuccess)
        xml=res.body
        logger.debug "Google geocoding. Address: #{address}. Result: #{xml}"
        doc=REXML::Document.new(xml)

        if doc.elements['//kml/Response/Status/code'].text == '200'
          res = GeoLoc.new
          coordinates=doc.elements['//coordinates'].text.to_s.split(',')

          #basics
          res.lat=coordinates[1]
          res.lng=coordinates[0]
          res.country_code=doc.elements['//CountryNameCode'].text
          res.provider='google'

          #extended -- false if not not available
          res.city = doc.elements['//LocalityName'].text if doc.elements['//LocalityName']
          res.state = doc.elements['//AdministrativeAreaName'].text if doc.elements['//AdministrativeAreaName']
          res.full_address = doc.elements['//address'].text if doc.elements['//address'] # google provides it
          res.zip = doc.elements['//PostalCodeNumber'].text if doc.elements['//PostalCodeNumber']
          res.street_address = doc.elements['//ThoroughfareName'].text if doc.elements['//ThoroughfareName']
          # Translate accuracy into Yahoo-style token address, street, zip, zip+4, city, state, country
          # For Google, 1=low accuracy, 8=high accuracy
          # TODO: why won't ReXML find the AddressDetails element?
          # accuracy = doc.elements['//AddressDetails'].attributes['Accuracy'] if doc.elements['//AddressDetails']
          #res.precision=%w{unknown country state state city zip zip+4 street address}[accuracy]
          res.success=true

          return res
        else 
          logger.info "Google was unable to geocode address: "+address
          return GeoLoc.new
        end

        rescue
          logger.error "Caught an error during Google geocoding call: "+$!
          return GeoLoc.new
      end  
    end
    
    # Provides geocoding based upon an IP address.  The underlying web service is a hostip.info
    # which sources their data through a combination of publicly available information as well
    # as community contributions.
    class IpGeocoder < Geocoder 

      private 

      # Given an IP address, returns a GeoLoc instance which contains latitude,
      # longitude, city, and country code.  Sets the success attribute to false if the ip 
      # parameter does not match an ip address.  
      def self.do_geocode(ip)
        return GeoLoc.new unless /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})?$/.match(ip)
        response = Net::HTTP.get_response('api.hostip.info', "/get_html.php?ip=#{ip}&position=true")
        response.is_a?(Net::HTTPSuccess) ? parse_body(response.body) : GeoLoc.new
      rescue
        logger.error "Caught an error during HostIp geocoding call: "+$!
        return GeoLoc.new
      end

      # Converts the body to YAML since its in the form of:
      #
      # Country: UNITED STATES (US)
      # City: Sugar Grove, IL
      # Latitude: 41.7696
      # Longitude: -88.4588
      #
      # then instantiates a GeoLoc instance to populate with location data.
      def self.parse_body(body) # :nodoc:
        yaml = YAML.load(body)
        res = GeoLoc.new
        res.provider = 'hostip'
        res.city, res.state = yaml['City'].split(', ')
        country, res.country_code = yaml['Country'].split(' (')
        res.lat = yaml['Latitude'] 
        res.lng = yaml['Longitude']
        res.country_code.chop!
        res.success = res.city != "(Private Address)"
        res
      end
    end
    
    # Geocoder Us geocoder implementation.  Requires the GeoKit::Geocoders::GEOCODER_US variable to
    # contain true or false based upon whether authentication is to occur.  Conforms to the 
    # interface set by the Geocoder class.
    class UsGeocoder < Geocoder

      private

      # For now, the geocoder_method will only geocode full addresses -- not zips or cities in isolation
      def self.do_geocode(address)
        address_str = address.is_a?(GeoLoc) ? address.to_geocodeable_s : address
        url = "http://"+(GeoKit::Geocoders::GEOCODER_US || '')+"geocoder.us/service/csv/geocode?address=#{CGI.escape(address_str)}"
        res = Net::HTTP.get_response(URI.parse(url))
        return GeoLoc.new if !res.is_a?(Net::HTTPSuccess)
        data = res.body
        logger.debug "Geocoder.us geocoding. Address: #{address}. Result: #{data}"
        array = data.chomp.split(',')

        if array.length == 6  
          res=GeoLoc.new
          res.lat,res.lng,res.street_address,res.city,res.state,res.zip=array
          res.country_code='US'
          res.success=true 
          return res
        else 
          logger.info "geocoder.us was unable to geocode address: "+address
          return GeoLoc.new      
        end
        rescue 
          logger.error "Caught an error during geocoder.us geocoding call: "+$!
          return GeoLoc.new
      end
    end
    
    # Yahoo geocoder implementation.  Requires the GeoKit::Geocoders::YAHOO variable to
    # contain a Yahoo API key.  Conforms to the interface set by the Geocoder class.
    class YahooGeocoder < Geocoder

      private 

      # Template method which does the geocode lookup.
      def self.do_geocode(address)
        address_str = address.is_a?(GeoLoc) ? address.to_geocodeable_s : address
        url="http://api.local.yahoo.com/MapsService/V1/geocode?appid=#{GeoKit::Geocoders::YAHOO}&location=#{CGI.escape(address_str)}"
        res = Net::HTTP.get_response(URI.parse(url))
        return GeoLoc.new if !res.is_a?(Net::HTTPSuccess)
        xml = res.body
        doc = REXML::Document.new(xml)
        logger.debug "Yahoo geocoding. Address: #{address}. Result: #{xml}"

        if doc.elements['//ResultSet']
          res=GeoLoc.new

          #basic      
          res.lat=doc.elements['//Latitude'].text
          res.lng=doc.elements['//Longitude'].text
          res.country_code=doc.elements['//Country'].text
          res.provider='yahoo'  

          #extended - false if not available
          res.city=doc.elements['//City'].text if doc.elements['//City'] && doc.elements['//City'].text != nil
          res.state=doc.elements['//State'].text if doc.elements['//State'] && doc.elements['//State'].text != nil
          res.zip=doc.elements['//Zip'].text if doc.elements['//Zip'] && doc.elements['//Zip'].text != nil
          res.street_address=doc.elements['//Address'].text if doc.elements['//Address'] && doc.elements['//Address'].text != nil
          res.precision=doc.elements['//Result'].attributes['precision'] if doc.elements['//Result']
          res.success=true
          return res
        else 
          logger.info "Yahoo was unable to geocode address: "+address
          return GeoLoc.new
        end   

        rescue 
          logger.info "Caught an error during Yahoo geocoding call: "+$!
          return GeoLoc.new
      end
    end     
    
    # Provides methods to geocode with a variety of geocoding service providers, plus failover
    # among providers in the order you configure.
    # 
    # Goal:
    # - homogenize the results of multiple geocoders
    # 
    # Limitations:
    # - currently only provides the first result. Sometimes geocoders will return multiple results.
    # - currently discards the "accuracy" component of the geocoding calls
    class MultiGeocoder < Geocoder 

      private

      # This method will call one or more geocoders in the order specified in the 
      # configuration until one of the geocoders work.
      # 
      # The failover approach is crucial for production-grade apps, but is rarely used.
      # 98% of your geocoding calls will be successful with the first call  
      def self.do_geocode(address)
        GeoKit::Geocoders::PROVIDER_ORDER.each do |provider|
          res = eval("#{provider.to_s.capitalize}Geocoder.geocode(\"#{address}\")")
          return res if res.success
        end
        # If we get here, we failed completely.
        GeoLoc.new
      end
    end   
  end
end