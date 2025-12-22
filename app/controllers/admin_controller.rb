class AdminController
  def self.index(current_organization)
    reset_state
    @organization = current_organization
    @stats = stats_for(current_organization)
    @title = 'Roaster - Admin'
    @show_admin_nav = true
    @logout_path = '/admin/logout'

    { template: :admin, locals: build_locals }
  end

  def self.download_example
    {
      content_type: 'text/csv',
      attachment: 'example_emails.csv',
      body: File.read('public/example_emails.csv')
    }
  end

  def self.upload(current_organization, params)
    reset_state
    @organization = current_organization

    unless params[:csv_file]&.[](:tempfile)
      @error = 'Please select a CSV file'
      return render_admin(current_organization)
    end

    handle_csv_upload(current_organization, params)
    render_admin(current_organization)
  end

  private_class_method def self.handle_csv_upload(org, params)
    csv_path = params[:csv_file][:tempfile].path
    overwrite = params[:overwrite] == 'true'

    deleted_count = delete_existing_emails(org) if overwrite
    result = VerifiedEmail.import_from_csv(csv_path, org.name)

    @success = build_success_message(result, overwrite, deleted_count)
  rescue StandardError => e
    @error = "Error importing CSV: #{e.message}"
  end

  private_class_method def self.delete_existing_emails(org)
    VerifiedEmail.where(organization_name: org.name).delete
  end

  private_class_method def self.build_success_message(result, overwrite, deleted_count)
    message = "Successfully imported #{result[:imported]} emails"
    message = "Deleted #{deleted_count} existing emails. #{message}" if overwrite && deleted_count
    message += " (#{result[:duplicates]} duplicates skipped)" if result[:duplicates].positive?
    message
  end

  private_class_method def self.render_admin(org)
    @stats = stats_for(org)
    @organization = org
    @title = 'Roaster - Admin'
    @show_admin_nav = true
    @logout_path = '/admin/logout'

    { template: :admin, locals: build_locals }
  end

  private_class_method def self.stats_for(org)
    last_upload = VerifiedEmail
                  .where(organization_name: org.name)
                  .order(Sequel.desc(:created_at))
                  .first

    {
      total_emails: VerifiedEmail.where(organization_name: org.name).count,
      organization_name: org.name,
      last_upload_at: last_upload&.created_at
    }
  end

  private_class_method def self.reset_state
    @stats = nil
    @organization = nil
    @success = nil
    @error = nil
    @title = nil
    @show_admin_nav = nil
    @logout_path = nil
  end

  private_class_method def self.build_locals
    {
      stats: @stats,
      organization: @organization,
      success: @success,
      error: @error,
      title: @title,
      show_admin_nav: @show_admin_nav,
      logout_path: @logout_path
    }
  end
end
