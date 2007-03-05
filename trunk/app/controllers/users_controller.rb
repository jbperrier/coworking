class UsersController < ApplicationController
  def view
    @user = User.find(params[:id])
  end
  
  def approve
    ActiveRecord::Base.connection().execute("update spaces_users set status = 'approved' where user_id = #{params[:user]} and space_id = #{params[:space]}")
    redirect_to :controller => 'spaces', :action => 'admin', :id => params[:space]
  end
  
  def reject
    ActiveRecord::Base.connection().execute("update spaces_users set status = 'declined' where user_id = #{params[:user]} and space_id = #{params[:space]}")
    redirect_to :controller => 'spaces', :action => 'admin', :id => params[:space]
  end
  
  def admin
    ActiveRecord::Base.connection().execute("update spaces_users set admin = 'yes' where user_id = #{params[:user]} and space_id = #{params[:space]}")
    redirect_to :controller => 'spaces', :action => 'admin', :id => params[:space]
  end
end
