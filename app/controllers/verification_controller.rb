class VerificationController
  def self.verify_page(params)
    reset_state
    @email = params[:email]
    @organization_username = params[:organization_username]
    @api_key = params[:api_key]
    @title = 'Verify Email - Roaster'

    { template: :verify, locals: build_locals }
  end

  def self.verify(params)
    reset_state
    api_key = params[:api_key]&.strip
    email = params[:email]&.strip
    org_username = params[:organization_username]&.strip

    if missing_required_fields?(api_key, email, org_username)
      set_error('Please enter API key, organization username, and email address', api_key, email, org_username)
    elsif invalid_api_key?(api_key)
      set_error('Email not verified', api_key, email, org_username)
    else
      check_verification(email, org_username, api_key)
    end

    @title = 'Verify Email - Roaster'
    { template: :verify, locals: build_locals }
  end

  private_class_method def self.missing_required_fields?(api_key, email, org_username)
    [api_key, email, org_username].any? { |field| field.nil? || field.empty? }
  end

  private_class_method def self.invalid_api_key?(api_key)
    ApiKey.authenticate(api_key).nil?
  end

  private_class_method def self.check_verification(email, org_username, api_key)
    org = Organization.find(username: org_username)

    if org && VerifiedEmail.verified?(email, org.name)
      set_success(email, org_username, org.name, api_key)
    else
      # Don't leak whether organization exists
      set_error('Email not verified', api_key, email, org_username)
    end
  end

  private_class_method def self.set_success(email, org_username, org_name, api_key)
    @success = true
    @email = email
    @organization_username = org_username
    @organization_name = org_name
    @api_key = api_key
    @error = nil
  end

  private_class_method def self.set_error(message, api_key, email, org_username)
    @error = message
    @success = nil
    @api_key = api_key
    @email = email
    @organization_username = org_username
  end

  private_class_method def self.reset_state
    @success = nil
    @error = nil
    @email = nil
    @organization_username = nil
    @organization_name = nil
    @api_key = nil
    @title = nil
  end

  private_class_method def self.build_locals
    {
      success: @success,
      error: @error,
      email: @email,
      organization_username: @organization_username,
      organization_name: @organization_name,
      api_key: @api_key,
      title: @title
    }
  end
end
