ENV['RACK_ENV'] = 'test'

require_relative '../test_helper'

require 'sinatra'
require_relative '../../app/controllers/admin_controller'
require_relative '../../app/controllers/verification_controller'

# Set the views directory to the root views folder
Sinatra::Application.set :views, File.expand_path('../../app/views', __dir__)
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
    assert_match(/Privacy-First/, last_response.body)
  end

  def test_verify_page_loads
    get '/verify'
    assert last_response.ok?
    assert_match(/Verify Your Email/, last_response.body)
  end

  def test_admin_page_redirects_without_auth
    get '/admin'
    assert last_response.redirect?
    follow_redirect!
    assert_match(/login/, last_request.url)
  end

  def test_verify_email_not_found
    # Create organization and API key
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')
    result = ApiKey.generate('Test Key')

    post '/verify', email: 'notfound@example.com', organization_username: 'testorg', api_key: result[:raw_key]
    assert last_response.ok?
    assert_match(/Email not verified/, last_response.body)
  end

  def test_verify_email_success
    # Create organization and API key
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')
    result = ApiKey.generate('Test Key')

    email = 'verified@example.com'
    VerifiedEmail.create(
      email_hash: VerifiedEmail.hash_email(email),
      organization_name: 'Test Org'
    )

    post '/verify', email: email, organization_username: 'testorg', api_key: result[:raw_key]
    assert last_response.ok?
    assert_match(/Email verified successfully/, last_response.body)
    assert_match(/#{email}/, last_response.body)
  end

  def test_verify_email_empty
    result = ApiKey.generate('Test Key')
    post '/verify', email: '', organization_username: 'testorg', api_key: result[:raw_key]
    assert last_response.ok?
    assert_match(/Please enter API key, organization username, and email address/, last_response.body)
  end

  def test_verify_email_missing_api_key
    post '/verify', email: 'test@example.com', organization_username: 'testorg'
    assert last_response.ok?
    assert_match(/Please enter API key, organization username, and email address/, last_response.body)
  end

  def test_api_verify_with_valid_key
    # Create organization and API key
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')
    result = ApiKey.generate('Test Key')

    email = 'verified@example.com'
    VerifiedEmail.create(
      email_hash: VerifiedEmail.hash_email(email),
      organization_name: 'Test Org'
    )

    header 'Authorization', "Bearer #{result[:raw_key]}"
    header 'Content-Type', 'application/json'
    post '/api/v1/verify', { email: email, organization_username: 'testorg' }.to_json

    assert last_response.ok?
    json = JSON.parse(last_response.body)
    assert_equal true, json['verified']
    assert_equal 'Test Org', json['organization']
  end

  def test_api_verify_with_invalid_key
    header 'Authorization', 'Bearer invalid_key'
    header 'Content-Type', 'application/json'
    post '/api/v1/verify', { email: 'test@example.com', organization_username: 'testorg' }.to_json

    assert_equal 400, last_response.status
    json = JSON.parse(last_response.body)
    assert_equal 'Bad request', json['error']
  end

  def test_api_verify_with_missing_key
    header 'Content-Type', 'application/json'
    post '/api/v1/verify', { email: 'test@example.com', organization_username: 'testorg' }.to_json

    assert_equal 400, last_response.status
    json = JSON.parse(last_response.body)
    assert_equal 'Bad request', json['error']
  end

  def test_api_verify_with_missing_email
    result = ApiKey.generate('Test Key')
    header 'Authorization', "Bearer #{result[:raw_key]}"
    header 'Content-Type', 'application/json'
    post '/api/v1/verify', { organization_username: 'testorg' }.to_json

    assert_equal 400, last_response.status
    json = JSON.parse(last_response.body)
    assert_equal 'Bad request', json['error']
  end

  def test_api_verify_with_missing_organization_username
    result = ApiKey.generate('Test Key')
    header 'Authorization', "Bearer #{result[:raw_key]}"
    header 'Content-Type', 'application/json'
    post '/api/v1/verify', { email: 'test@example.com' }.to_json

    assert_equal 400, last_response.status
    json = JSON.parse(last_response.body)
    assert_equal 'Bad request', json['error']
  end

  def test_api_verify_with_unverified_email
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')
    result = ApiKey.generate('Test Key')
    header 'Authorization', "Bearer #{result[:raw_key]}"
    header 'Content-Type', 'application/json'
    post '/api/v1/verify', { email: 'unverified@example.com', organization_username: 'testorg' }.to_json

    assert last_response.ok?
    json = JSON.parse(last_response.body)
    assert_equal false, json['verified']
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
