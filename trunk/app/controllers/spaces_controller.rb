class SpacesController < ApplicationController
  before_filter :login_required, :only => [ :join, :schedule ]
  
  def index
    @spaces = Space.find(:all)
  end
  
  def view
    @space = Space.find(params[:id])
  end
  
  def create
    Space.create!(params[:space])
    redirect_to :action => 'index'
  end
  
  def edit
    @space = Space.find(params[:id])
  end
  
  def update
    Space.find(params[:id]).update_attributes(params[:space])
    redirect_to :action => 'index'
  end
  
  def join
    @user = current_user
    @space = Space.find(params[:id])
    if @request.method == :post
      @space.users.push_with_attributes(current_user, :status => 'pending', :note => params[:note])
      flash[:notice] = 'Your request to join is pending approval.'
      redirect_to :action => 'view', :id => @space.id
    end
  end
  
  def schedule
    @user = current_user
    @space = Space.find(params[:id])
    member = User.find_by_sql("select * from spaces_users where user_id = #{@user.id} and space_id = #{@space.id} and status = 'approved'")
    if member.size < 1
      flash[:notice] = 'You are not a member of this space.'
      redirect_to :action => 'view', :id => @space.id
    end
  end
  
  def admin
    @space = Space.find(params[:id])
  end
end
