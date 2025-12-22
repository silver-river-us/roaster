require_relative '../test_helper'

class TestOrganization < Minitest::Test
  def test_create_organization_with_password
    org = Organization.create_with_password(name: 'Test Org', username: 'testuser', password: 'password123')

    assert org.password_hash, 'Password hash should be set'
    refute_equal 'password123', org.password_hash, 'Password should be hashed, not stored in plain text'
  end

  def test_authenticate_with_correct_password
    org = Organization.create_with_password(name: 'Test Org', username: 'testuser', password: 'password123')

    assert org.password_match?('password123'), 'Should authenticate with correct password'
  end

  def test_authenticate_with_incorrect_password
    org = Organization.create_with_password(name: 'Test Org', username: 'testuser', password: 'password123')

    refute org.password_match?('wrongpassword'), 'Should not authenticate with incorrect password'
  end

  def test_authenticate_class_method_with_valid_credentials
    org = Organization.create_with_password(name: 'Test Org', username: 'testuser', password: 'password123')

    authenticated_org = Organization.authenticate('testuser', 'password123')
    assert authenticated_org, 'Should return organization with valid credentials'
    assert_equal org.id, authenticated_org.id
  end

  def test_authenticate_class_method_with_invalid_username
    result = Organization.authenticate('nonexistent', 'password123')
    assert_nil result, 'Should return nil with invalid username'
  end

  def test_authenticate_class_method_with_invalid_password
    Organization.create_with_password(name: 'Test Org', username: 'testuser', password: 'password123')

    result = Organization.authenticate('testuser', 'wrongpassword')
    assert_nil result, 'Should return nil with invalid password'
  end

  def test_unique_username_constraint
    Organization.create_with_password(name: 'Org 1', username: 'testuser', password: 'password123')

    assert_raises(Sequel::UniqueConstraintViolation) do
      Organization.create_with_password(name: 'Org 2', username: 'testuser', password: 'password123')
    end
  end

  def test_unique_name_constraint
    Organization.create_with_password(name: 'Test Org', username: 'user1', password: 'password123')

    assert_raises(Sequel::UniqueConstraintViolation) do
      Organization.create_with_password(name: 'Test Org', username: 'user2', password: 'password123')
    end
  end
end
