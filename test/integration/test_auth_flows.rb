ENV['RACK_ENV'] = 'test'

require_relative '../test_helper'

require 'sinatra'
require_relative '../../app/controllers/admin_controller'
require_relative '../../app/controllers/super_admin_controller'
require_relative '../../app/controllers/verification_controller'
require_relative '../../app/lib/auth'

# Set the views directory to the root views folder
Sinatra::Application.set :views, File.expand_path('../../app/views', __dir__)
Sinatra::Application.set :root, File.expand_path('../..', __dir__)

require_relative '../../config/routes'

# rubocop:disable Metrics/ClassLength
class TestAuthFlows < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  # Super Admin Tests
  def test_super_admin_login_page_loads
    get '/super-admin/login'
    assert last_response.ok?
    assert_match(/login/i, last_response.body)
  end

  def test_super_admin_login_success
    ENV['SUPER_ADMIN_USERNAME'] = 'admin'
    ENV['SUPER_ADMIN_PASSWORD'] = 'secret123'

    post '/super-admin/login', username: 'admin', password: 'secret123'

    assert last_response.redirect?
    follow_redirect!
    assert_equal '/super-admin', last_request.path
  end

  def test_super_admin_login_failure
    ENV['SUPER_ADMIN_USERNAME'] = 'admin'
    ENV['SUPER_ADMIN_PASSWORD'] = 'secret123'

    post '/super-admin/login', username: 'admin', password: 'wrongpassword'

    assert last_response.ok?
    assert_match(/Invalid username or password/, last_response.body)
  end

  def test_super_admin_page_requires_auth
    get '/super-admin'
    assert last_response.redirect?
    follow_redirect!
    assert_equal '/super-admin/login', last_request.path
  end

  def test_super_admin_logout
    ENV['SUPER_ADMIN_USERNAME'] = 'admin'
    ENV['SUPER_ADMIN_PASSWORD'] = 'secret123'

    # Login first
    post '/super-admin/login', username: 'admin', password: 'secret123'

    # Then logout
    get '/super-admin/logout'

    assert last_response.redirect?
    follow_redirect!
    assert_equal '/', last_request.path

    # Verify can't access admin page anymore
    get '/super-admin'
    assert last_response.redirect?
  end

  def test_super_admin_can_access_protected_routes
    ENV['SUPER_ADMIN_USERNAME'] = 'admin'
    ENV['SUPER_ADMIN_PASSWORD'] = 'secret123'

    # Login
    post '/super-admin/login', username: 'admin', password: 'secret123'
    follow_redirect!

    # Verify we're on super admin page
    assert last_response.ok?
    assert_match(/Super Admin Panel/i, last_response.body)
  end

  # Organization Admin Tests
  def test_admin_login_page_loads
    get '/admin/login'
    assert last_response.ok?
    assert_match(/login/i, last_response.body)
  end

  def test_admin_login_success
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    post '/admin/login', username: 'testorg', password: 'password123'

    assert last_response.redirect?
    follow_redirect!
    assert_equal '/admin', last_request.path
  end

  def test_admin_login_failure
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    post '/admin/login', username: 'testorg', password: 'wrongpassword'

    assert last_response.ok?
    assert_match(/Invalid username or password/, last_response.body)
  end

  def test_admin_login_nonexistent_user
    post '/admin/login', username: 'nonexistent', password: 'password123'

    assert last_response.ok?
    assert_match(/Invalid username or password/, last_response.body)
  end

  def test_admin_page_requires_auth
    get '/admin'
    assert last_response.redirect?
    follow_redirect!
    assert_equal '/admin/login', last_request.path
  end

  def test_admin_logout
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    # Login first
    post '/admin/login', username: 'testorg', password: 'password123'

    # Then logout
    get '/admin/logout'

    assert last_response.redirect?
    follow_redirect!
    assert_equal '/', last_request.path

    # Verify can't access admin page anymore
    get '/admin'
    assert last_response.redirect?
  end

  def test_admin_can_access_protected_routes
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    # Login
    post '/admin/login', username: 'testorg', password: 'password123'
    follow_redirect!

    # Verify we're on admin page and can see organization name
    assert last_response.ok?
    assert_match(/Test Org/i, last_response.body)
  end

  def test_admin_upload_requires_auth
    post '/admin/upload'
    assert last_response.redirect?
    follow_redirect!
    assert_equal '/admin/login', last_request.path
  end

  def test_admin_download_requires_auth
    get '/admin/download-example'
    assert last_response.redirect?
    follow_redirect!
    assert_equal '/admin/login', last_request.path
  end
end
# rubocop:enable Metrics/ClassLength
