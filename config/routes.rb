require 'sinatra'
require_relative '../lib/auth'
require_relative '../models/organization'
require_relative '../controllers/admin_controller'
require_relative '../controllers/super_admin_controller'
require_relative '../controllers/verification_controller'

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
    erb response[:template]
  end
end

# Home
get '/' do
  render_controller VerificationController.index({})
end

post '/verify' do
  render_controller VerificationController.verify(params, {})
end

# Super Admin (Basic Auth with env variables)
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

# Organization Admin (Basic Auth with org credentials)
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
