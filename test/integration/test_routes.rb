ENV['RACK_ENV'] = 'test'

require_relative '../test_helper'

require 'sinatra'
require_relative '../../controllers/admin_controller'
require_relative '../../controllers/verification_controller'

# Set the views directory to the root views folder
Sinatra::Application.set :views, File.expand_path('../../views', __dir__)
Sinatra::Application.set :root, File.expand_path('../..', __dir__)

require_relative '../../config/routes'

class TestRoutes < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_home_page_loads
    get '/'
    assert last_response.ok?
    assert_match(/Roaster/, last_response.body)
    assert_match(/Verify your email/, last_response.body)
  end

  def test_admin_page_redirects_without_auth
    get '/admin'
    assert last_response.redirect?
    follow_redirect!
    assert_match(/login/, last_request.url)
  end

  def test_verify_email_not_found
    # Create organization
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    post '/verify', email: 'notfound@example.com', organization_username: 'testorg'
    assert last_response.ok?
    assert_match(/Email not verified/, last_response.body)
  end

  def test_verify_email_success
    # Create organization
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    email = 'verified@example.com'
    VerifiedEmail.create(
      email_hash: VerifiedEmail.hash_email(email),
      organization_name: 'Test Org'
    )

    post '/verify', email: email, organization_username: 'testorg'
    assert last_response.ok?
    assert_match(/Email verified successfully/, last_response.body)
    assert_match(/#{email}/, last_response.body)
  end

  def test_verify_email_empty
    post '/verify', email: '', organization_username: 'testorg'
    assert last_response.ok?
    assert_match(/Please enter both organization username and email address/, last_response.body)
  end

  def test_download_example_csv_requires_auth
    get '/admin/download-example'
    assert last_response.redirect?
  end

  def test_upload_csv_requires_auth
    post '/admin/upload'
    assert last_response.redirect?
  end
end
