require_relative '../test_helper'
require_relative '../../app/controllers/verification_controller'

class TestVerificationController < Minitest::Test
  def setup
    super
    # Create a test API key for all tests
    result = ApiKey.generate('Test API Key')
    @api_key = result[:raw_key]
  end

  def test_index_returns_template_and_locals
    response = VerificationController.index({})

    assert_equal :index, response[:template]
    assert response[:locals].is_a?(Hash)
    assert_nil response[:locals][:success]
    assert_nil response[:locals][:error]
    assert_nil response[:locals][:email]
  end

  def test_verify_page_returns_template_and_accepts_params
    response = VerificationController.verify_page({ api_key: @api_key, email: 'test@example.com' }, {})

    assert_equal :verify, response[:template]
    assert_equal @api_key, response[:locals][:api_key]
    assert_equal 'test@example.com', response[:locals][:email]
  end

  def test_verify_with_empty_email
    response = VerificationController.verify({ api_key: @api_key, email: '', organization_username: 'testorg' }, {})

    assert_equal :verify, response[:template]
    assert_equal 'Please enter API key, organization username, and email address', response[:locals][:error]
    assert_nil response[:locals][:success]
  end

  def test_verify_with_nil_email
    response = VerificationController.verify({ api_key: @api_key, organization_username: 'testorg' }, {})

    assert_equal :verify, response[:template]
    assert_equal 'Please enter API key, organization username, and email address', response[:locals][:error]
  end

  def test_verify_with_missing_api_key
    response = VerificationController.verify({ email: 'test@example.com', organization_username: 'testorg' }, {})

    assert_equal :verify, response[:template]
    assert_equal 'Please enter API key, organization username, and email address', response[:locals][:error]
  end

  def test_verify_with_invalid_api_key
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    response = VerificationController.verify({ api_key: 'invalid_key', email: 'test@example.com', organization_username: 'testorg' }, {})

    assert_equal :verify, response[:template]
    assert_equal 'Email not verified', response[:locals][:error]
    assert_nil response[:locals][:success]
  end

  def test_verify_with_verified_email
    # Create organization
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    email = 'verified@example.com'
    VerifiedEmail.create(
      email_hash: VerifiedEmail.hash_email(email),
      organization_name: 'Test Org'
    )

    response = VerificationController.verify({ api_key: @api_key, email: email, organization_username: 'testorg' }, {})

    assert_equal :verify, response[:template]
    assert_equal true, response[:locals][:success]
    assert_equal email, response[:locals][:email]
    assert_equal 'testorg', response[:locals][:organization_username]
    assert_equal @api_key, response[:locals][:api_key]
    assert_nil response[:locals][:error]
  end

  def test_verify_with_unverified_email
    # Create organization
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    response = VerificationController.verify({ api_key: @api_key, email: 'notfound@example.com', organization_username: 'testorg' }, {})

    assert_equal :verify, response[:template]
    assert_equal 'Email not verified', response[:locals][:error]
    assert_nil response[:locals][:success]
  end

  def test_verify_strips_whitespace
    # Create organization
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    email = 'verified@example.com'
    VerifiedEmail.create(
      email_hash: VerifiedEmail.hash_email(email),
      organization_name: 'Test Org'
    )

    response = VerificationController.verify({ api_key: "  #{@api_key}  ", email: "  #{email}  ", organization_username: '  testorg  ' }, {})

    assert_equal true, response[:locals][:success]
    assert_equal email, response[:locals][:email]
  end
end
