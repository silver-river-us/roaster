class AdminController
  def self.index(current_organization, response)
    response[:stats] = stats(current_organization)
    response[:organization] = current_organization
    response[:success] ||= nil
    response[:error] ||= nil
    response[:title] = 'Roaster - Admin'
    response[:show_admin_nav] = true
    response[:logout_path] = '/admin/logout'
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

    csv_path = params[:csv_file][:tempfile].path
    overwrite = params[:overwrite] == 'true'

    process_csv_upload(current_organization, csv_path, overwrite, response)
    render_admin_response(current_organization, response)
  end

  def self.process_csv_upload(current_organization, csv_path, overwrite, response)
    deleted_count = handle_overwrite(current_organization, overwrite)
    result = VerifiedEmail.import_from_csv(csv_path, current_organization.name)

    response[:success] = build_success_message(result, overwrite, deleted_count)
    response[:error] = nil
  rescue StandardError => e
    response[:error] = "Error importing CSV: #{e.message}"
    response[:success] = nil
  end
  private_class_method :process_csv_upload

  def self.handle_overwrite(current_organization, overwrite)
    return nil unless overwrite

    VerifiedEmail.where(organization_name: current_organization.name).delete
  end
  private_class_method :handle_overwrite

  def self.build_success_message(result, overwrite, deleted_count)
    message = "Successfully imported #{result[:imported]} emails"
    message = "Deleted #{deleted_count} existing emails. #{message}" if overwrite && deleted_count
    message += " (#{result[:duplicates]} duplicates skipped)" if result[:duplicates].positive?
    message
  end
  private_class_method :build_success_message

  def self.render_admin_response(current_organization, response)
    response[:stats] = stats(current_organization)
    response[:organization] = current_organization
    { template: :admin, locals: response }
  end
  private_class_method :render_admin_response

  def self.stats(current_organization)
    last_upload = VerifiedEmail.where(organization_name: current_organization.name)
                               .order(Sequel.desc(:created_at))
                               .first

    {
      total_emails: VerifiedEmail.where(organization_name: current_organization.name).count,
      organization_name: current_organization.name,
      last_upload_at: last_upload&.created_at
    }
  end
  private_class_method :stats
end
