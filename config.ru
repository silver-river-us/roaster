require 'sinatra'

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
