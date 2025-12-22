class AdminController
  def self.index(current_organization, response)
    response[:stats] = stats(current_organization)
    response[:organization] = current_organization
    response[:success] ||= nil
    response[:error] ||= nil
    { template: :admin, locals: response }
  end

  def self.download_example(response)
    response[:content_type] = 'text/csv'
    response[:attachment] = 'example_emails.csv'
    response[:body] = File.read('public/example_emails.csv')
    response
  end

  def self.upload(current_organization, params, response)
    # Validate file upload
    unless params[:csv_file] && params[:csv_file][:tempfile]
      response[:error] = 'Please select a CSV file'
      response[:success] = nil
      return render_admin_response(current_organization, response)
    end

    # Import CSV with organization name
    csv_path = params[:csv_file][:tempfile].path

    begin
      result = VerifiedEmail.import_from_csv(csv_path, current_organization.name)
      success_message = "Successfully imported #{result[:imported]} emails"
      success_message += " (#{result[:duplicates]} duplicates skipped)" if result[:duplicates].positive?
      response[:success] = success_message
      response[:error] = nil
    rescue StandardError => e
      response[:error] = "Error importing CSV: #{e.message}"
      response[:success] = nil
    end

    render_admin_response(current_organization, response)
  end

  def self.render_admin_response(current_organization, response)
    response[:stats] = stats(current_organization)
    response[:organization] = current_organization
    { template: :admin, locals: response }
  end
  private_class_method :render_admin_response

  def self.stats(current_organization)
    {
      total_emails: VerifiedEmail.where(organization_name: current_organization.name).count,
      organization_name: current_organization.name
    }
  end
  private_class_method :stats
end
