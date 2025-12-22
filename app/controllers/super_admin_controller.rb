# rubocop:disable Metrics/ClassLength
class SuperAdminController
  def self.index(response)
    response[:organizations] = Organization.order(:name).all
    response[:api_keys] = ApiKey.order(Sequel.desc(:created_at)).all
    response[:title] = 'Roaster - Super Admin'
    response[:show_super_admin_nav] = true
    { template: :super_admin, locals: response }
  end

  def self.edit(params, response)
    org_id = params[:id]
    org = Organization[org_id]

    if org
      response[:organization] = org
      response[:title] = 'Edit Organization - Roaster'
      response[:show_super_admin_nav] = true
      { template: :edit_organization, locals: response }
    else
      response[:error] = 'Organization not found'
      response[:organizations] = Organization.order(:name).all
      response[:title] = 'Roaster - Super Admin'
      response[:show_super_admin_nav] = true
      { template: :super_admin, locals: response }
    end
  end

  def self.create_organization(params, response)
    name = params[:name]&.strip
    username = params[:username]&.strip
    password = params[:password]&.strip

    validation_error = validate_organization_params(name, username, password)
    if validation_error
      response[:error] = validation_error
    else
      create_org_record(name, username, password, response)
    end

    render_super_admin_response(response)
  end

  def self.validate_organization_params(name, username, password)
    return 'Organization name is required' if name.nil? || name.empty?
    return 'Username is required' if username.nil? || username.empty?
    return 'Password is required' if password.nil? || password.empty?

    nil
  end
  private_class_method :validate_organization_params

  def self.create_org_record(name, username, password, response)
    org = Organization.new(name: name, username: username)
    org.password = password
    org.save
    response[:success] = "Organization '#{name}' created successfully"
  rescue Sequel::UniqueConstraintViolation
    response[:error] = 'Username or organization name already exists'
  rescue StandardError => e
    response[:error] = "Error creating organization: #{e.message}"
  end
  private_class_method :create_org_record

  def self.update_organization(params, response)
    org_id = params[:id]
    name = params[:name]&.strip
    username = params[:username]&.strip
    password = params[:password]&.strip

    org = Organization[org_id]
    unless org
      response[:error] = 'Organization not found'
      return render_super_admin_response(response)
    end

    validation_error = validate_update_params(name, username)
    if validation_error
      response[:error] = validation_error
    else
      update_org_record(org, name, username, password, response)
    end

    render_super_admin_response(response)
  end

  def self.validate_update_params(name, username)
    return 'Organization name is required' if name.nil? || name.empty?
    return 'Username is required' if username.nil? || username.empty?

    nil
  end
  private_class_method :validate_update_params

  def self.update_org_record(org, name, username, password, response)
    org.name = name
    org.username = username
    org.password = password if password && !password.empty?
    org.save
    response[:success] = "Organization '#{name}' updated successfully"
  rescue Sequel::UniqueConstraintViolation
    response[:error] = 'Username or organization name already exists'
  rescue StandardError => e
    response[:error] = "Error updating organization: #{e.message}"
  end
  private_class_method :update_org_record

  def self.delete_organization(params, response)
    org_id = params[:id]

    begin
      org = Organization[org_id]
      if org
        org.delete
        response[:success] = "Organization '#{org.name}' deleted successfully"
      else
        response[:error] = 'Organization not found'
      end
    rescue StandardError => e
      response[:error] = "Error deleting organization: #{e.message}"
    end

    render_super_admin_response(response)
  end

  def self.stats
    {
      total_emails: VerifiedEmail.count,
      total_organizations: Organization.count,
      organizations_breakdown: VerifiedEmail
        .select(:organization_name)
        .select_append { count(Sequel.lit('*')).as(:email_count) }
        .where(Sequel.~(organization_name: nil))
        .group(:organization_name)
        .order(Sequel.desc(:email_count))
        .all
    }
  end

  def self.create_api_key(params, response)
    name = params[:name]&.strip

    if name.nil? || name.empty?
      response[:error] = 'API key name is required'
    else
      result = ApiKey.generate(name)
      response[:success] = "API key '#{name}' created successfully"
      response[:new_api_key] = result[:raw_key]
    end

    render_super_admin_response(response)
  end

  def self.delete_api_key(params, response)
    api_key_id = params[:id]

    api_key = ApiKey[api_key_id]
    if api_key
      api_key.delete
      response[:success] = "API key '#{api_key.name}' deleted successfully"
    else
      response[:error] = 'API key not found'
    end

    render_super_admin_response(response)
  end

  def self.render_super_admin_response(response)
    response[:organizations] = Organization.order(:name).all
    response[:api_keys] = ApiKey.order(Sequel.desc(:created_at)).all
    response[:title] = 'Roaster - Super Admin'
    response[:show_super_admin_nav] = true
    { template: :super_admin, locals: response }
  end
  private_class_method :render_super_admin_response
end
# rubocop:enable Metrics/ClassLength
