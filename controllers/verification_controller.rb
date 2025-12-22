class VerificationController
  def self.index(response)
    response[:success] ||= nil
    response[:error] ||= nil
    response[:email] ||= nil
    response[:organization_username] ||= nil
    { template: :index, locals: response }
  end

  def self.verify(params, response)
    email = params[:email]&.strip
    org_username = params[:organization_username]&.strip

    if inputs_invalid?(email, org_username)
      set_validation_error(response, email, org_username)
    else
      check_email_verification(email, org_username, response)
    end

    { template: :index, locals: response }
  end

  def self.inputs_invalid?(email, org_username)
    email.nil? || email.empty? || org_username.nil? || org_username.empty?
  end
  private_class_method :inputs_invalid?

  def self.set_validation_error(response, email, org_username)
    response[:error] = 'Please enter both organization username and email address'
    response[:success] = nil
    response[:email] = email
    response[:organization_username] = org_username
  end
  private_class_method :set_validation_error

  def self.check_email_verification(email, org_username, response)
    org = Organization.find(username: org_username)

    # Don't leak whether organization exists - always show generic message
    if org && VerifiedEmail.verified?(email, org.name)
      set_success_response(response, email, org.name)
    else
      set_error_response(response, email, org_username)
    end
  end
  private_class_method :check_email_verification

  def self.set_success_response(response, email, org_name)
    response[:success] = true
    response[:email] = email
    response[:organization_name] = org_name
    response[:error] = nil
  end
  private_class_method :set_success_response

  def self.set_error_response(response, email, org_username)
    response[:error] = 'Email not verified'
    response[:success] = nil
    response[:email] = email
    response[:organization_username] = org_username
  end
  private_class_method :set_error_response
end
