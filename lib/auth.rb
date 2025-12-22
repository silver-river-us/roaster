module Auth
  def require_super_admin
    @auth ||= Rack::Auth::Basic::Request.new(request.env)

    unless @auth.provided? && @auth.basic? && @auth.credentials && valid_super_admin?(@auth.credentials)
      response['WWW-Authenticate'] = 'Basic realm="Super Admin"'
      halt 401, "Unauthorized\n"
    end
  end

  def require_organization
    @auth ||= Rack::Auth::Basic::Request.new(request.env)

    unless @auth.provided? && @auth.basic? && @auth.credentials
      response['WWW-Authenticate'] = 'Basic realm="Organization Login"'
      halt 401, "Unauthorized\n"
    end

    username, password = @auth.credentials
    @current_organization = Organization.authenticate(username, password)

    unless @current_organization
      response['WWW-Authenticate'] = 'Basic realm="Organization Login"'
      halt 401, "Unauthorized\n"
    end

    @current_organization
  end

  def valid_super_admin?(credentials)
    username, password = credentials
    username == ENV['SUPER_ADMIN_USERNAME'] && password == ENV['SUPER_ADMIN_PASSWORD']
  end
end
