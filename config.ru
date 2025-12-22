require 'dotenv/load'
require 'sinatra'
require 'rack/session'

# Set views directory
set :views, File.expand_path('app/views', __dir__)

# Set public directory for static files
set :public_folder, File.expand_path('public', __dir__)

# Configure Sinatra protection for Fly.io
# Set permitted hosts for Rack::Protection::HostAuthorization
set :protection, host_authorization: { permitted_hosts: ['roaster.fly.dev', 'localhost'] }

# Enable sessions
use Rack::Session::Cookie,
    key: 'roaster.session',
    secret: ENV.fetch('SESSION_SECRET', "change_me_in_production_please_#{SecureRandom.hex(32)}"),
    expire_after: 86_400, # 24 hours
    same_site: :lax,
    httponly: true

# Database
require_relative 'config/database'

# Models
require_relative 'app/models/verified_email'
require_relative 'app/models/api_key'

# Controllers
require_relative 'app/controllers/admin_controller'
require_relative 'app/controllers/verification_controller'

# Routes
require_relative 'config/routes'

run Sinatra::Application
