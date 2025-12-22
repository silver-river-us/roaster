class VerificationController
  def self.index(response)
    response[:success] ||= nil
    response[:error] ||= nil
    response[:email] ||= nil
    { template: :index, locals: response }
  end

  def self.verify(params, response)
    # Sanitize input
    email = params[:email]&.strip

    # Validate
    if email.nil? || email.empty?
      response[:error] = 'Please enter an email address'
      response[:success] = nil
      response[:email] = nil
    elsif VerifiedEmail.verified?(email)
      response[:success] = true
      response[:email] = email
      response[:error] = nil
    else
      response[:error] = 'Email not found in verified list'
      response[:success] = nil
      response[:email] = nil
    end

    { template: :index, locals: response }
  end
end
