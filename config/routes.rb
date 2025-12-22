require 'sinatra'
require_relative '../app/lib/auth'
require_relative '../app/models/organization'
require_relative '../app/controllers/admin_controller'
require_relative '../app/controllers/super_admin_controller'
require_relative '../app/controllers/verification_controller'

helpers Auth

# Helper to render controller response
def render_controller(response)
  if response[:body]
    content_type response[:content_type] if response[:content_type]
    attachment response[:attachment] if response[:attachment]
    response[:body]
  else
    # Set instance variables from locals hash
    response[:locals]&.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
    erb response[:template], layout: :layout
  end
end

# Home - Landing Page
get '/' do
  # Check if organization is logged in
  if session[:organization_id]
    @current_organization = Organization[session[:organization_id]]
    @show_admin_nav = true
    @logout_path = '/admin/logout'
  elsif session[:super_admin]
    @show_super_admin_nav = true
  end
  erb :index, layout: :layout
end

# Verify Page
get '/verify' do
  render_controller VerificationController.verify_page({})
end

post '/verify' do
  render_controller VerificationController.verify(params, {})
end

# Super Admin Login
get '/super-admin/login' do
  @title = 'Super Admin Login - Roaster'
  erb :super_admin_login, layout: :layout
end

post '/super-admin/login' do
  if login_super_admin(params[:username], params[:password])
    redirect '/super-admin'
  else
    @error = 'Invalid username or password'
    @title = 'Super Admin Login - Roaster'
    erb :super_admin_login, layout: :layout
  end
end

get '/super-admin/logout' do
  logout
  redirect '/'
end

# Unified logout for both admin and super admin
get '/logout' do
  logout
  redirect '/'
end

# Super Admin (Session-based auth)
get '/super-admin' do
  require_super_admin
  render_controller SuperAdminController.index({})
end

post '/super-admin/organizations' do
  require_super_admin
  render_controller SuperAdminController.create_organization(params, {})
end

get '/super-admin/organizations/:id/edit' do
  require_super_admin
  render_controller SuperAdminController.edit(params, {})
end

post '/super-admin/organizations/:id/update' do
  require_super_admin
  render_controller SuperAdminController.update_organization(params, {})
end

post '/super-admin/organizations/:id/delete' do
  require_super_admin
  render_controller SuperAdminController.delete_organization(params, {})
end

# Organization Admin Login
get '/admin/login' do
  @title = 'Organization Login - Roaster'
  erb :admin_login, layout: :layout
end

post '/admin/login' do
  if login_organization(params[:username], params[:password])
    redirect '/admin'
  else
    @error = 'Invalid username or password'
    @title = 'Organization Login - Roaster'
    erb :admin_login, layout: :layout
  end
end

get '/admin/logout' do
  logout
  redirect '/'
end

# Organization Admin (Session-based auth)
get '/admin' do
  current_org = require_organization
  render_controller AdminController.index(current_org, {})
end

get '/admin/download-example' do
  require_organization
  render_controller AdminController.download_example({})
end

post '/admin/upload' do
  current_org = require_organization
  render_controller AdminController.upload(current_org, params, {})
end
