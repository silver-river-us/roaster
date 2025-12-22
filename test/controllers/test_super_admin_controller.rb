require_relative '../test_helper'
require_relative '../../app/controllers/super_admin_controller'

# rubocop:disable Metrics/ClassLength
class TestSuperAdminController < Minitest::Test
  def test_index_returns_organizations
    # Create test organizations
    org1 = Organization.create(name: 'Org A', username: 'orga', password: 'password123')
    org1.password = 'password123'
    org1.save

    org2 = Organization.create(name: 'Org B', username: 'orgb', password: 'password123')
    org2.password = 'password123'
    org2.save

    response = SuperAdminController.index({})

    assert_equal :super_admin, response[:template]
    assert_equal 2, response[:locals][:organizations].count
    assert_equal 'Org A', response[:locals][:organizations].first.name
  end

  def test_create_organization_success
    params = {
      name: 'New Org',
      username: 'neworg',
      password: 'password123'
    }

    response = SuperAdminController.create_organization(params, {})

    assert_equal :super_admin, response[:template]
    assert_match(/created successfully/, response[:locals][:success])
    assert_nil response[:locals][:error]
    assert_equal 1, Organization.count
  end

  def test_create_organization_missing_name
    params = {
      name: '',
      username: 'neworg',
      password: 'password123'
    }

    response = SuperAdminController.create_organization(params, {})

    assert_equal :super_admin, response[:template]
    assert_equal 'Organization name is required', response[:locals][:error]
    assert_nil response[:locals][:success]
    assert_equal 0, Organization.count
  end

  def test_create_organization_missing_username
    params = {
      name: 'New Org',
      username: '',
      password: 'password123'
    }

    response = SuperAdminController.create_organization(params, {})

    assert_equal 'Username is required', response[:locals][:error]
    assert_equal 0, Organization.count
  end

  def test_create_organization_missing_password
    params = {
      name: 'New Org',
      username: 'neworg',
      password: ''
    }

    response = SuperAdminController.create_organization(params, {})

    assert_equal 'Password is required', response[:locals][:error]
    assert_equal 0, Organization.count
  end

  def test_create_organization_duplicate_username
    Organization.create_with_password(name: 'Existing Org', username: 'testorg', password: 'password123')

    params = {
      name: 'New Org',
      username: 'testorg',
      password: 'password123'
    }

    response = SuperAdminController.create_organization(params, {})

    assert_match(/already exists/, response[:locals][:error])
    assert_equal 1, Organization.count
  end

  def test_edit_returns_organization
    org = Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    response = SuperAdminController.edit({ id: org.id }, {})

    assert_equal :edit_organization, response[:template]
    assert_equal org.id, response[:locals][:organization].id
  end

  def test_edit_nonexistent_organization
    response = SuperAdminController.edit({ id: 9999 }, {})

    assert_equal :super_admin, response[:template]
    assert_equal 'Organization not found', response[:locals][:error]
  end

  def test_update_organization_success
    org = Organization.create_with_password(name: 'Old Name', username: 'olduser', password: 'password123')

    params = {
      id: org.id,
      name: 'New Name',
      username: 'newuser',
      password: 'newpassword'
    }

    response = SuperAdminController.update_organization(params, {})

    assert_match(/updated successfully/, response[:locals][:success])
    org.reload
    assert_equal 'New Name', org.name
    assert_equal 'newuser', org.username
    assert org.password_match?('newpassword')
  end

  def test_update_organization_without_password
    org = Organization.create_with_password(name: 'Test Org', username: 'testuser', password: 'password123')

    params = {
      id: org.id,
      name: 'Updated Name',
      username: 'updateduser',
      password: ''
    }

    response = SuperAdminController.update_organization(params, {})

    assert_match(/updated successfully/, response[:locals][:success])
    org.reload
    assert_equal 'Updated Name', org.name
    assert org.password_match?('password123'), 'Password should remain unchanged'
  end

  def test_update_organization_missing_name
    org = Organization.create_with_password(name: 'Test Org', username: 'testuser', password: 'password123')

    params = {
      id: org.id,
      name: '',
      username: 'testuser'
    }

    response = SuperAdminController.update_organization(params, {})

    assert_equal 'Organization name is required', response[:locals][:error]
  end

  def test_delete_organization_success
    org = Organization.create_with_password(name: 'Test Org', username: 'testuser', password: 'password123')

    response = SuperAdminController.delete_organization({ id: org.id }, {})

    assert_match(/deleted successfully/, response[:locals][:success])
    assert_equal 0, Organization.count
  end

  def test_delete_nonexistent_organization
    response = SuperAdminController.delete_organization({ id: 9999 }, {})

    assert_equal 'Organization not found', response[:locals][:error]
  end

  def test_update_organization_not_found
    params = { id: 9999, name: 'Test', username: 'test', password: 'pass' }

    response = SuperAdminController.update_organization(params, {})

    assert_equal 'Organization not found', response[:locals][:error]
  end

  def test_update_organization_with_duplicate_constraint
    org1 = Organization.create_with_password(name: 'Org 1', username: 'org1', password: 'pass')
    org2 = Organization.create_with_password(name: 'Org 2', username: 'org2', password: 'pass')

    params = { id: org2.id, name: 'Org 1', username: 'org2', password: '' }

    response = SuperAdminController.update_organization(params, {})

    assert_match(/already exists/, response[:locals][:error])
  end

  def test_stats_method
    # Create some test data
    org1 = Organization.create_with_password(name: 'Org 1', username: 'org1', password: 'pass')
    org2 = Organization.create_with_password(name: 'Org 2', username: 'org2', password: 'pass')

    VerifiedEmail.create(email_hash: 'hash1', organization_name: org1.name)
    VerifiedEmail.create(email_hash: 'hash2', organization_name: org1.name)
    VerifiedEmail.create(email_hash: 'hash3', organization_name: org2.name)

    stats = SuperAdminController.stats

    assert_equal 3, stats[:total_emails]
    assert_equal 2, stats[:total_organizations]
    assert_equal 2, stats[:organizations_breakdown].count
  end

  def test_create_organization_handles_save_errors
    params = { name: 'Test Org', username: 'testorg', password: 'password123' }

    # Stub the Organization model to raise an error during save
    Organization.stub :new, ->(*_args) do
      org = Object.new
      def org.password=(_val); end
      def org.save
        raise StandardError, 'Simulated database error'
      end
      org
    end do
      response = SuperAdminController.create_organization(params, {})
      assert_match(/Error creating organization/, response[:locals][:error])
      assert_match(/Simulated database error/, response[:locals][:error])
    end
  end

  def test_update_organization_handles_save_errors
    org = Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')
    params = { id: org.id, name: 'Updated Name', username: 'updateduser', password: '' }

    # Stub Organization[] to return a mock that fails on save
    Organization.stub :[], ->(_id) do
      mock_org = Object.new
      def mock_org.name=(_val); end
      def mock_org.username=(_val); end
      def mock_org.password=(_val); end
      def mock_org.save
        raise StandardError, 'Simulated update error'
      end
      mock_org
    end do
      response = SuperAdminController.update_organization(params, {})
      assert_match(/Error updating organization/, response[:locals][:error])
      assert_match(/Simulated update error/, response[:locals][:error])
    end
  end

  def test_delete_organization_handles_delete_errors
    org = Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    # Stub Organization[] to return a mock that fails on delete
    Organization.stub :[], ->(_id) do
      mock_org = Object.new
      def mock_org.delete
        raise StandardError, 'Simulated delete error'
      end
      mock_org
    end do
      response = SuperAdminController.delete_organization({ id: org.id }, {})
      assert_match(/Error deleting organization/, response[:locals][:error])
      assert_match(/Simulated delete error/, response[:locals][:error])
    end
  end
end
# rubocop:enable Metrics/ClassLength
