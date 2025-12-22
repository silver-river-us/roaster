module Auth
  def require_super_admin
    return if session[:super_admin]

    redirect '/super-admin/login'
  end

  def require_organization
    redirect '/admin/login' unless session[:organization_id]

    @current_organization = Organization[session[:organization_id]]
    unless @current_organization
      session.clear
      redirect '/admin/login'
    end

    @current_organization
  end

  def super_admin_authenticated?(username, password)
    username == ENV['SUPER_ADMIN_USERNAME'] && password == ENV['SUPER_ADMIN_PASSWORD']
  end

  # rubocop:disable Naming/PredicateMethod
  def login_super_admin(username, password)
    if super_admin_authenticated?(username, password)
      session[:super_admin] = true
      true
    else
      false
    end
  end

  def login_organization(username, password)
    org = Organization.authenticate(username, password)
    if org
      session[:organization_id] = org.id
      org
    else
      false
    end
  end
  # rubocop:enable Naming/PredicateMethod

  def logout
    session.clear
  end
end
