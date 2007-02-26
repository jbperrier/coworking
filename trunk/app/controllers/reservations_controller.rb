class ReservationsController < ApplicationController
  def create
    reservation = Reservation.create!(params[:reservation])
    reservation.update_attributes(:space_id => params[:id], :user_id => current_user.id)
    flash[:notice] = 'Reservation Confirmed.'
    redirect_to :controller => 'spaces', :action => 'schedule', :id => params[:id]
  end
end
