class ReservationsController < ApplicationController
  def create
    space = Space.find(params[:space])
    reservation = Reservation.new(params[:reservation])
    reservations = Reservation.find(:all, :conditions => ["date = ? and space_id = ?", reservation.date, space.id])
    member = User.find_by_sql("select * from spaces_users where user_id = #{current_user.id} and space_id = #{space.id} and status = 'approved'")
    if member.size < 1
      render :layout => false, :inline => 'You are not a member of this space.'
    elsif reservations.size < space.capacity
		  reservation.save!
      reservation.update_attributes(:space_id => params[:space], :user_id => current_user.id)
      #Twitter.post("#{current_user.login} will be at #{space.name} on #{reservation.date}")
      render :layout => false, :inline => '<h4>Reservation complete.</h4>'
    else
      render :layout => false, :inline => '<h4>Reservation failed. Space is full that day.</h4>'
    end
  end
end
