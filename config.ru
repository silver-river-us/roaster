require 'dotenv/load'
require 'sinatra'
require 'rack/session'

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
require_relative 'models/verified_email'

# Controllers
require_relative 'controllers/admin_controller'
require_relative 'controllers/verification_controller'

# Routes
require_relative 'config/routes'

run Sinatra::Application
