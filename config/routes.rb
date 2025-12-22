require 'sinatra'
require_relative '../controllers/admin_controller'
require_relative '../controllers/verification_controller'

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

# Admin
get '/admin' do
  render_controller AdminController.index({})
end

get '/admin/download-example' do
  render_controller AdminController.download_example({})
end

post '/admin/upload' do
  render_controller AdminController.upload(params, {})
end
