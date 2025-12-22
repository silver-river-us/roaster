class VerificationController
  def self.index(response)
    response[:success] ||= nil
    response[:error] ||= nil
    response[:email] ||= nil
    response[:organization_username] ||= nil
    { template: :index, locals: response }
  end

  def self.verify(params, response)
    # Sanitize input
    email = params[:email]&.strip
    org_username = params[:organization_username]&.strip

    # Validate
    if email.nil? || email.empty? || org_username.nil? || org_username.empty?
      response[:error] = 'Please enter both organization username and email address'
      response[:success] = nil
      response[:email] = email
      response[:organization_username] = org_username
    else
      # Find organization by username
      org = Organization.find(username: org_username)

      # Don't leak whether organization exists - always show generic message
      if org && VerifiedEmail.verified?(email, org.name)
        response[:success] = true
        response[:email] = email
        response[:organization_name] = org.name
        response[:error] = nil
      else
        response[:error] = 'Email not verified'
        response[:success] = nil
        response[:email] = email
        response[:organization_username] = org_username
      end
    end

    { template: :index, locals: response }
  end
end
