require_relative '../test_helper'
require_relative '../../controllers/verification_controller'

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
    response = VerificationController.verify({ email: '' }, {})

    assert_equal :index, response[:template]
    assert_equal 'Please enter an email address', response[:locals][:error]
    assert_nil response[:locals][:success]
  end

  def test_verify_with_nil_email
    response = VerificationController.verify({}, {})

    assert_equal :index, response[:template]
    assert_equal 'Please enter an email address', response[:locals][:error]
  end

  def test_verify_with_verified_email
    email = 'verified@example.com'
    VerifiedEmail.create(
      email_hash: VerifiedEmail.hash_email(email),
      organization_name: 'Test Org'
    )

    response = VerificationController.verify({ email: email }, {})

    assert_equal :index, response[:template]
    assert_equal true, response[:locals][:success]
    assert_equal email, response[:locals][:email]
    assert_nil response[:locals][:error]
  end

  def test_verify_with_unverified_email
    response = VerificationController.verify({ email: 'notfound@example.com' }, {})

    assert_equal :index, response[:template]
    assert_equal 'Email not found in verified list', response[:locals][:error]
    assert_nil response[:locals][:success]
  end

  def test_verify_strips_whitespace
    email = 'verified@example.com'
    VerifiedEmail.create(
      email_hash: VerifiedEmail.hash_email(email),
      organization_name: 'Test Org'
    )

    response = VerificationController.verify({ email: "  #{email}  " }, {})

    assert_equal true, response[:locals][:success]
    assert_equal email, response[:locals][:email]
  end
end
