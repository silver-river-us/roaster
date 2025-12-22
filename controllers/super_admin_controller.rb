class SuperAdminController
  def self.index(response)
    response[:organizations] = Organization.order(:name).all
    { template: :super_admin, locals: response }
  end

  def self.edit(params, response)
    org_id = params[:id]
    org = Organization[org_id]

    if org
      response[:organization] = org
      { template: :edit_organization, locals: response }
    else
      response[:error] = 'Organization not found'
      response[:organizations] = Organization.order(:name).all
      { template: :super_admin, locals: response }
    end
  end

  def self.create_organization(params, response)
    name = params[:name]&.strip
    username = params[:username]&.strip
    password = params[:password]&.strip

    # Validate
    if name.nil? || name.empty?
      response[:error] = 'Organization name is required'
    elsif username.nil? || username.empty?
      response[:error] = 'Username is required'
    elsif password.nil? || password.empty?
      response[:error] = 'Password is required'
    else
      begin
        org = Organization.new(
          name: name,
          username: username
        )
        org.password = password
        org.save

        response[:success] = "Organization '#{name}' created successfully"
      rescue Sequel::UniqueConstraintViolation
        response[:error] = 'Username or organization name already exists'
      rescue StandardError => e
        response[:error] = "Error creating organization: #{e.message}"
      end
    end

    response[:organizations] = Organization.order(:name).all
    { template: :super_admin, locals: response }
  end

  def self.update_organization(params, response)
    org_id = params[:id]
    name = params[:name]&.strip
    username = params[:username]&.strip
    password = params[:password]&.strip

    begin
      org = Organization[org_id]
      unless org
        response[:error] = 'Organization not found'
        response[:organizations] = Organization.order(:name).all
        return { template: :super_admin, locals: response }
      end

      # Validate
      if name.nil? || name.empty?
        response[:error] = 'Organization name is required'
      elsif username.nil? || username.empty?
        response[:error] = 'Username is required'
      else
        org.name = name
        org.username = username
        org.password = password if password && !password.empty?
        org.save

        response[:success] = "Organization '#{name}' updated successfully"
      end
    rescue Sequel::UniqueConstraintViolation
      response[:error] = 'Username or organization name already exists'
    rescue StandardError => e
      response[:error] = "Error updating organization: #{e.message}"
    end

    response[:organizations] = Organization.order(:name).all
    { template: :super_admin, locals: response }
  end

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

    response[:organizations] = Organization.order(:name).all
    { template: :super_admin, locals: response }
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
end
