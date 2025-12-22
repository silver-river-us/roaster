class VerificationController
  def self.index(response)
    response[:success] ||= nil
    response[:error] ||= nil
    response[:email] ||= nil
    response[:organization_username] ||= nil
    { template: :index, locals: response }
  end

  def self.verify_page(params, response)
    response[:success] ||= nil
    response[:error] ||= nil
    response[:email] = params[:email] if params[:email]
    response[:organization_username] = params[:organization_username] if params[:organization_username]
    response[:api_key] = params[:api_key] if params[:api_key]
    response[:title] = 'Verify Email - Roaster'
    { template: :verify, locals: response }
  end

  def self.verify(params, response)
    api_key = params[:api_key]&.strip
    email = params[:email]&.strip
    org_username = params[:organization_username]&.strip

    if inputs_invalid?(api_key, email, org_username)
      set_validation_error(response, api_key, email, org_username)
    elsif !valid_api_key?(api_key)
      # Don't leak that API key is invalid - show generic error
      set_error_response(response, api_key, email, org_username)
    else
      response[:api_key] = api_key
      check_email_verification(email, org_username, response)
    end

    response[:title] = 'Verify Email - Roaster'
    { template: :verify, locals: response }
  end

  def self.inputs_invalid?(api_key, email, org_username)
    api_key.nil? || api_key.empty? || email.nil? || email.empty? || org_username.nil? || org_username.empty?
  end
  private_class_method :inputs_invalid?

  def self.valid_api_key?(api_key)
    !ApiKey.authenticate(api_key).nil?
  end
  private_class_method :valid_api_key?

  def self.set_validation_error(response, api_key, email, org_username)
    response[:error] = 'Please enter API key, organization username, and email address'
    response[:success] = nil
    response[:api_key] = api_key
    response[:email] = email
    response[:organization_username] = org_username
  end
  private_class_method :set_validation_error

  def self.check_email_verification(email, org_username, response)
    org = Organization.find(username: org_username)
    api_key = response[:api_key]

    # Don't leak whether organization exists - always show generic message
    if org && VerifiedEmail.verified?(email, org.name)
      set_success_response(response, api_key, email, org_username, org.name)
    else
      set_error_response(response, api_key, email, org_username)
    end
  end
  private_class_method :check_email_verification

  def self.set_success_response(response, api_key, email, org_username, org_name)
    response[:success] = true
    response[:api_key] = api_key
    response[:email] = email
    response[:organization_username] = org_username
    response[:organization_name] = org_name
    response[:error] = nil
  end
  private_class_method :set_success_response

  def self.set_error_response(response, api_key, email, org_username)
    response[:error] = 'Email not verified'
    response[:success] = nil
    response[:api_key] = api_key
    response[:email] = email
    response[:organization_username] = org_username
  end
  private_class_method :set_error_response
end
