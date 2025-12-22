require_relative '../test_helper'
require_relative '../../app/controllers/verification_controller'

class TestVerificationController < Minitest::Test
  def test_index_returns_template_and_locals
    response = VerificationController.index({})

    assert_equal :index, response[:template]
    assert response[:locals].is_a?(Hash)
    assert_nil response[:locals][:success]
    assert_nil response[:locals][:error]
    assert_nil response[:locals][:email]
  end

  def test_verify_with_empty_email
    response = VerificationController.verify({ email: '', organization_username: 'testorg' }, {})

    assert_equal :verify, response[:template]
    assert_equal 'Please enter both organization username and email address', response[:locals][:error]
    assert_nil response[:locals][:success]
  end

  def test_verify_with_nil_email
    response = VerificationController.verify({ organization_username: 'testorg' }, {})

    assert_equal :verify, response[:template]
    assert_equal 'Please enter both organization username and email address', response[:locals][:error]
  end

  def test_verify_with_verified_email
    # Create organization
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    email = 'verified@example.com'
    VerifiedEmail.create(
      email_hash: VerifiedEmail.hash_email(email),
      organization_name: 'Test Org'
    )

    response = VerificationController.verify({ email: email, organization_username: 'testorg' }, {})

    assert_equal :verify, response[:template]
    assert_equal true, response[:locals][:success]
    assert_equal email, response[:locals][:email]
    assert_nil response[:locals][:error]
  end

  def test_verify_with_unverified_email
    # Create organization
    Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    response = VerificationController.verify({ email: 'notfound@example.com', organization_username: 'testorg' }, {})

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

    response = VerificationController.verify({ email: "  #{email}  ", organization_username: '  testorg  ' }, {})

    assert_equal true, response[:locals][:success]
    assert_equal email, response[:locals][:email]
  end
end
