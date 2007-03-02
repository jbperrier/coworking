class UsersController < ApplicationController
  def icon
    render :layout => false, :inline => Twitter.icon(params[:id])
  end
end
