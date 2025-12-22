# rubocop:disable Metrics/ClassLength
class SuperAdminController
  def self.index
    reset_state
    @organizations = Organization.order(:name).all
    @api_keys = ApiKey.order(Sequel.desc(:created_at)).all
    @title = 'Roaster - Super Admin'
    @show_super_admin_nav = true

    { template: :super_admin, locals: build_locals }
  end

  def self.edit(params)
    reset_state
    org = Organization[params[:id]]

    if org
      @organization = org
      @title = 'Edit Organization - Roaster'
      @show_super_admin_nav = true
      { template: :edit_organization, locals: build_locals }
    else
      @error = 'Organization not found'
      render_super_admin
    end
  end

  def self.create_organization(params)
    reset_state
    name = params[:name]&.strip
    username = params[:username]&.strip
    password = params[:password]&.strip

    if (validation_error = validate_org_params(name, username, password))
      @error = validation_error
    else
      create_org(name, username, password)
    end

    render_super_admin
  end

  def self.update_organization(params)
    reset_state
    org = Organization[params[:id]]

    unless org
      @error = 'Organization not found'
      return render_super_admin
    end

    name = params[:name]&.strip
    username = params[:username]&.strip
    password = params[:password]&.strip

    if (validation_error = validate_org_update_params(name, username))
      @error = validation_error
    else
      update_org(org, name, username, password)
    end

    render_super_admin
  end

  def self.delete_organization(params)
    reset_state
    org = Organization[params[:id]]

    if org
      begin
        org.delete
        @success = "Organization '#{org.name}' deleted successfully"
      rescue StandardError => e
        @error = "Error deleting organization: #{e.message}"
      end
    else
      @error = 'Organization not found'
    end

    render_super_admin
  end

  def self.create_api_key(params)
    reset_state
    name = params[:name]&.strip

    if name.nil? || name.empty?
      @error = 'API key name is required'
    else
      result = ApiKey.generate(name)
      @success = "API key '#{name}' created successfully"
      @new_api_key = result[:raw_key]
    end

    render_super_admin
  end

  def self.delete_api_key(params)
    reset_state
    api_key = ApiKey[params[:id]]

    if api_key
      api_key.delete
      @success = "API key '#{api_key.name}' deleted successfully"
    else
      @error = 'API key not found'
    end

    render_super_admin
  end

  private_class_method def self.validate_org_params(name, username, password)
    return 'Organization name is required' if name.nil? || name.empty?
    return 'Username is required' if username.nil? || username.empty?
    return 'Password is required' if password.nil? || password.empty?

    nil
  end

  private_class_method def self.validate_org_update_params(name, username)
    return 'Organization name is required' if name.nil? || name.empty?
    return 'Username is required' if username.nil? || username.empty?

    nil
  end

  private_class_method def self.create_org(name, username, password)
    org = Organization.new(name: name, username: username)
    org.password = password
    org.save
    @success = "Organization '#{name}' created successfully"
  rescue Sequel::UniqueConstraintViolation
    @error = 'Username or organization name already exists'
  rescue StandardError => e
    @error = "Error creating organization: #{e.message}"
  end

  private_class_method def self.update_org(org, name, username, password)
    org.name = name
    org.username = username
    org.password = password if password && !password.empty?
    org.save
    @success = "Organization '#{name}' updated successfully"
  rescue Sequel::UniqueConstraintViolation
    @error = 'Username or organization name already exists'
  rescue StandardError => e
    @error = "Error updating organization: #{e.message}"
  end

  private_class_method def self.render_super_admin
    @organizations = Organization.order(:name).all
    @api_keys = ApiKey.order(Sequel.desc(:created_at)).all
    @title = 'Roaster - Super Admin'
    @show_super_admin_nav = true

    { template: :super_admin, locals: build_locals }
  end

  private_class_method def self.reset_state
    @organizations = nil
    @api_keys = nil
    @organization = nil
    @success = nil
    @error = nil
    @new_api_key = nil
    @title = nil
    @show_super_admin_nav = nil
  end

  private_class_method def self.build_locals
    {
      organizations: @organizations,
      api_keys: @api_keys,
      organization: @organization,
      success: @success,
      error: @error,
      new_api_key: @new_api_key,
      title: @title,
      show_super_admin_nav: @show_super_admin_nav
    }
  end
end
# rubocop:enable Metrics/ClassLength
