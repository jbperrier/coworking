class Twitter < ActiveRecord::Base
  require 'net/http'
  require 'twitter'
  require 'fileutils'
  
  def post(text)
    begin
      Twitter::Base.new('phil@coutorture.com', 'coworking').update(text)
    rescue
      #twitter will raise an exception but still post.
    end
  end
  
  def icon(username)
    statuses = Twitter::Base.new('coworking', 'coworking').friends
    begin
      for status in statuses
        if status.user.screen_name == username
          '<img src="' + status.user.profile_image_url + '" />'
        end
      end
    rescue
      'http://assets2.twitter.com/system/user/profile_image/795695/original/Ritual_Working_128.png'
    end
  end
  
end
