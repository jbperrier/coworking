class UsersController < ApplicationController
  def icon
    begin
      statuses = Twitter::Base.new('phil@coutorture.com', 'coworking').followers
      for status in statuses
        if status.user.screen_name == params[:id]
          render :layout => false, :inline => '<img src="' + status.user.profile_image_url + '" />'
        end
      end
    rescue
    end
    render :layout => false, :inline => '<img src="http://assets1.twitter.com/system/user/profile_image/795695/normal/Ritual_Working_128.png" />'
  end
end
