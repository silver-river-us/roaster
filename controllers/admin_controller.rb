class AdminController
  def self.index(response)
    response[:stats] = stats
    response[:success] ||= nil
    response[:error] ||= nil
    { template: :admin, locals: response }
  end

  def self.download_example(response)
    response[:content_type] = 'text/csv'
    response[:attachment] = 'example_emails.csv'
    response[:body] = File.read('assets/example_emails.csv')
    response
  end

  def self.upload(params, response)
    # Validate file upload
    unless params[:csv_file] && params[:csv_file][:tempfile]
      response[:error] = 'Please select a CSV file'
      response[:success] = nil
      response[:stats] = stats
      return { template: :admin, locals: response }
    end

    # Import CSV
    organization_name = params[:organization_name]&.strip
    csv_path = params[:csv_file][:tempfile].path

    begin
      result = VerifiedEmail.import_from_csv(csv_path, organization_name)

      success_message = "Successfully imported #{result[:imported]} emails"
      success_message += " (#{result[:duplicates]} duplicates skipped)" if result[:duplicates].positive?

      response[:success] = success_message
      response[:error] = nil
    rescue StandardError => e
      response[:error] = "Error importing CSV: #{e.message}"
      response[:success] = nil
    end

    response[:stats] = stats
    { template: :admin, locals: response }
  end

  def self.stats
    {
      total_emails: VerifiedEmail.count,
      organizations: VerifiedEmail.select(:organization_name).distinct.count
    }
  end
  private_class_method :stats
end
