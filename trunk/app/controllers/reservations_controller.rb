class ReservationsController < ApplicationController
  def create
    reservation = Reservation.create!(params[:reservation])
    space = Space.find(params[:id])
    reservation.update_attributes(:space_id => space.id, :user_id => current_user.id)
    begin
      Twitter::Base.new('phil@coutorture.com', 'coworking').update("#{current_user.login} will be at #{space.name} on #{reservation.date}")
    rescue
      #twitter will raise an exception but still post.
    end
    flash[:notice] = 'Reservation Confirmed.'
    redirect_to :controller => 'spaces', :action => 'schedule', :id => params[:id]
  end
end
