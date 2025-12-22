require_relative '../test_helper'

class TestVerifiedEmail < Minitest::Test
  def test_hash_email
    email = 'test@example.com'
    hash1 = VerifiedEmail.hash_email(email)
    hash2 = VerifiedEmail.hash_email('TEST@EXAMPLE.COM')
    hash3 = VerifiedEmail.hash_email('  test@example.com  ')

    assert_equal hash1, hash2, 'Email hashing should be case insensitive'
    assert_equal hash1, hash3, 'Email hashing should strip whitespace'
    assert_equal 64, hash1.length, 'SHA256 hash should be 64 characters'
  end

  def test_verified_when_email_exists
    email = 'verified@example.com'
    VerifiedEmail.create(
      email_hash: VerifiedEmail.hash_email(email),
      organization_name: 'Test Org'
    )

    assert VerifiedEmail.verified?(email, 'Test Org'), 'Should return true for verified email'
  end

  def test_verified_when_email_does_not_exist
    refute VerifiedEmail.verified?('notfound@example.com', 'Test Org'), 'Should return false for unverified email'
  end

  def test_import_from_csv
    csv_path = '/tmp/test_emails.csv'
    File.write(csv_path, "email\ntest1@example.com\ntest2@example.com\n")

    result = VerifiedEmail.import_from_csv(csv_path, 'Test Organization')

    assert_equal 2, result[:imported], 'Should import 2 emails'
    assert_equal 0, result[:duplicates], 'Should have 0 duplicates'
    assert_equal 2, VerifiedEmail.count, 'Database should have 2 records'

    File.delete(csv_path)
  end

  def test_import_from_csv_with_duplicates
    csv_path = '/tmp/test_emails.csv'
    File.write(csv_path, "email\ntest@example.com\ntest@example.com\n")

    result = VerifiedEmail.import_from_csv(csv_path, 'Test Organization')

    assert_equal 1, result[:imported], 'Should import 1 unique email'
    assert_equal 1, result[:duplicates], 'Should skip 1 duplicate'
    assert_equal 1, VerifiedEmail.count, 'Database should have 1 record'

    File.delete(csv_path)
  end

  def test_import_from_csv_skips_empty_emails
    csv_path = '/tmp/test_emails.csv'
    File.write(csv_path, "email\ntest@example.com\n\n   \n")

    result = VerifiedEmail.import_from_csv(csv_path)

    assert_equal 1, result[:imported], 'Should only import valid email'
    assert_equal 1, VerifiedEmail.count, 'Database should have 1 record'

    File.delete(csv_path)
  end

  def test_find_by_email_returns_verified_email
    email = 'test@example.com'
    created = VerifiedEmail.create(
      email_hash: VerifiedEmail.hash_email(email),
      organization_name: 'Test Org'
    )

    found = VerifiedEmail.find_by_email(email)

    assert found
    assert_equal created.id, found.id
    assert_equal 'Test Org', found.organization_name
  end

  def test_find_by_email_returns_nil_when_not_found
    found = VerifiedEmail.find_by_email('notfound@example.com')

    assert_nil found
  end
end
