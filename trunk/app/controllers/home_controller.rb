class HomeController < ApplicationController
  def index
    @spaces = Space.find(:all)
    @events = Event.find(:all)
    @users = User.find(:all)
  end
end
