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

  def test_admin_page_loads
    get '/admin'
    assert last_response.ok?
    assert_match(/Roaster Admin/, last_response.body)
    assert_match(/Total Verified Emails/, last_response.body)
  end

  def test_verify_email_not_found
    post '/verify', email: 'notfound@example.com'
    assert last_response.ok?
    assert_match(/Email not found in verified list/, last_response.body)
  end

  def test_verify_email_success
    email = 'verified@example.com'
    VerifiedEmail.create(
      email_hash: VerifiedEmail.hash_email(email),
      organization_name: 'Test Org'
    )

    post '/verify', email: email
    assert last_response.ok?
    assert_match(/Email verified successfully/, last_response.body)
    assert_match(/#{email}/, last_response.body)
  end

  def test_verify_email_empty
    post '/verify', email: ''
    assert last_response.ok?
    assert_match(/Please enter an email address/, last_response.body)
  end

  def test_download_example_csv
    get '/admin/download-example'
    assert last_response.ok?
    assert_match(%r{text/csv}, last_response.content_type)
    assert_equal 'attachment; filename="example_emails.csv"', last_response.headers['Content-Disposition']
  end

  def test_upload_csv_without_file
    post '/admin/upload'
    assert last_response.ok?
    assert_match(/Please select a CSV file/, last_response.body)
  end

  def test_upload_csv_with_valid_file
    csv_content = "email\ntest@example.com\n"

    post '/admin/upload',
         csv_file: Rack::Test::UploadedFile.new(StringIO.new(csv_content), 'text/csv', original_filename: 'test.csv'),
         organization_name: 'Test Org'

    assert last_response.ok?
    assert_match(/Successfully imported/, last_response.body)
    assert_equal 1, VerifiedEmail.count
  end
end
