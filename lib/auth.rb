module Auth
  def require_super_admin
    unless session[:super_admin]
      redirect '/super-admin/login'
    end
  end

  def require_organization
    unless session[:organization_id]
      redirect '/admin/login'
    end

    @current_organization = Organization[session[:organization_id]]
    unless @current_organization
      session.clear
      redirect '/admin/login'
    end

    @current_organization
  end

  def authenticate_super_admin(username, password)
    if username == ENV['SUPER_ADMIN_USERNAME'] && password == ENV['SUPER_ADMIN_PASSWORD']
      session[:super_admin] = true
      true
    else
      false
    end
  end

  def authenticate_organization(username, password)
    org = Organization.authenticate(username, password)
    if org
      session[:organization_id] = org.id
      org
    else
      false
    end
  end

  def logout
    session.clear
  end
end
