require_relative '../test_helper'
require_relative '../../app/controllers/admin_controller'

# rubocop:disable Metrics/ClassLength
class TestAdminController < Minitest::Test
  def test_index_returns_stats
    # Create test organization
    org = Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    # Add some test data
    VerifiedEmail.create(email_hash: 'hash1', organization_name: 'Test Org')
    VerifiedEmail.create(email_hash: 'hash2', organization_name: 'Test Org')
    VerifiedEmail.create(email_hash: 'hash3', organization_name: 'Other Org')

    response = AdminController.index(org)

    assert_equal :admin, response[:template]
    assert_equal 2, response[:locals][:stats][:total_emails]
    assert_equal 'Test Org', response[:locals][:stats][:organization_name]
    assert_nil response[:locals][:success]
    assert_nil response[:locals][:error]
  end

  def test_download_example_returns_csv
    response = AdminController.download_example

    assert_equal 'text/csv', response[:content_type]
    assert_equal 'example_emails.csv', response[:attachment]
    assert response[:body].is_a?(String)
  end

  def test_upload_without_file
    # Create test organization
    org = Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    params = {}
    response = AdminController.upload(org, params)

    assert_equal :admin, response[:template]
    assert_equal 'Please select a CSV file', response[:locals][:error]
    assert_nil response[:locals][:success]
    assert response[:locals][:stats].is_a?(Hash)
  end

  def test_upload_with_valid_csv
    # Create test organization
    org = Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    csv_path = '/tmp/upload_test.csv'
    File.write(csv_path, "email\ntest1@example.com\ntest2@example.com\n")

    tempfile = Minitest::Mock.new
    tempfile.expect(:path, csv_path)

    params = {
      csv_file: { tempfile: tempfile }
    }

    response = AdminController.upload(org, params)

    assert_equal :admin, response[:template]
    assert_match(/Successfully imported 2 emails/, response[:locals][:success])
    assert_nil response[:locals][:error]
    assert_equal 2, VerifiedEmail.count

    File.delete(csv_path)
    tempfile.verify
  end

  def test_upload_with_duplicates
    # Create test organization
    org = Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    csv_path = '/tmp/upload_test.csv'
    File.write(csv_path, "email\ntest@example.com\ntest@example.com\n")

    tempfile = Minitest::Mock.new
    tempfile.expect(:path, csv_path)

    params = {
      csv_file: { tempfile: tempfile }
    }

    response = AdminController.upload(org, params)

    assert_match(/1 duplicates skipped/, response[:locals][:success])
    assert_equal 1, VerifiedEmail.count

    File.delete(csv_path)
    tempfile.verify
  end

  def test_upload_with_invalid_csv
    # Create test organization
    org = Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    csv_path = '/tmp/invalid.csv'
    File.write(csv_path, "wrong_header\ntest@example.com\n")

    tempfile = Minitest::Mock.new
    tempfile.expect(:path, csv_path)

    params = {
      csv_file: { tempfile: tempfile }
    }

    response = AdminController.upload(org, params)

    assert_equal :admin, response[:template]
    # The CSV will import but with 0 emails since there's no "email" column
    if response[:locals][:error]
      assert_match(/Error importing CSV/, response[:locals][:error])
    else
      assert_match(/Successfully imported 0 emails/, response[:locals][:success])
    end

    File.delete(csv_path)
    tempfile.verify
  end

  def test_upload_with_overwrite_flag
    # Create test organization
    org = Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    # Add existing emails
    VerifiedEmail.create(email_hash: 'oldhash1', organization_name: 'Test Org')
    VerifiedEmail.create(email_hash: 'oldhash2', organization_name: 'Test Org')

    csv_path = '/tmp/upload_test.csv'
    File.write(csv_path, "email\ntest1@example.com\ntest2@example.com\n")

    tempfile = Minitest::Mock.new
    tempfile.expect(:path, csv_path)

    params = {
      csv_file: { tempfile: tempfile },
      overwrite: 'true'
    }

    response = AdminController.upload(org, params)

    assert_match(/Deleted 2 existing emails/, response[:locals][:success])
    assert_match(/Successfully imported 2 emails/, response[:locals][:success])
    assert_equal 2, VerifiedEmail.where(organization_name: 'Test Org').count

    File.delete(csv_path)
    tempfile.verify
  end

  def test_upload_with_import_error
    # Create test organization
    org = Organization.create_with_password(name: 'Test Org', username: 'testorg', password: 'password123')

    tempfile = Minitest::Mock.new
    tempfile.expect(:path, '/nonexistent/path.csv')

    params = {
      csv_file: { tempfile: tempfile }
    }

    response = AdminController.upload(org, params)

    assert_match(/Error importing CSV/, response[:locals][:error])
    assert_nil response[:locals][:success]

    tempfile.verify
  end
end
# rubocop:enable Metrics/ClassLength
