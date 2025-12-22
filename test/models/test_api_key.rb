require_relative '../test_helper'

class TestApiKey < Minitest::Test
  def test_generate_creates_api_key
    result = ApiKey.generate('Test Key')

    assert result[:api_key]
    assert result[:raw_key]
    assert_equal 64, result[:raw_key].length
    assert_equal 1, ApiKey.count
  end

  def test_generate_stores_hash_not_raw_key
    result = ApiKey.generate('Test Key')
    api_key = result[:api_key]

    refute_equal result[:raw_key], api_key.key_hash
    assert_equal 64, api_key.key_hash.length
  end

  def test_generate_stores_prefix
    result = ApiKey.generate('Test Key')
    api_key = result[:api_key]

    assert_equal result[:raw_key][0, 8], api_key.key_prefix
    assert_equal 8, api_key.key_prefix.length
  end

  def test_authenticate_with_valid_key
    result = ApiKey.generate('Test Key')
    raw_key = result[:raw_key]

    authenticated = ApiKey.authenticate(raw_key)

    assert authenticated
    assert_equal result[:api_key].id, authenticated.id
  end

  def test_authenticate_with_invalid_key
    ApiKey.generate('Test Key')

    authenticated = ApiKey.authenticate('invalid_key')

    assert_nil authenticated
  end

  def test_authenticate_with_nil_key
    authenticated = ApiKey.authenticate(nil)

    assert_nil authenticated
  end

  def test_authenticate_with_empty_key
    authenticated = ApiKey.authenticate('')

    assert_nil authenticated
  end

  def test_authenticate_updates_last_used_at
    result = ApiKey.generate('Test Key')
    raw_key = result[:raw_key]
    api_key = result[:api_key]

    assert_nil api_key.last_used_at

    ApiKey.authenticate(raw_key)

    api_key.reload
    assert api_key.last_used_at
  end

  def test_masked_key_shows_prefix_and_asterisks
    result = ApiKey.generate('Test Key')
    api_key = result[:api_key]

    masked = api_key.masked_key

    assert_equal "#{api_key.key_prefix}#{'*' * 56}", masked
    assert_equal 64, masked.length
  end
end
