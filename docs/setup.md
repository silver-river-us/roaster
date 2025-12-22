# Setup Guide

This guide will help you set up Roaster for local development.

## Prerequisites

- Ruby 3.4+
- Bundler
- SQLite3

## Initial Setup

1. **Clone the repository**

```bash
git clone https://github.com/silver-river-us/roaster.git
cd roaster
```

2. **Install dependencies**

```bash
bundle install
```

3. **Set up the database**

```bash
rake db:migrate
```

4. **Configure environment variables** (optional)

Create a `.env` file in the root directory:

```bash
SUPER_ADMIN_USERNAME=admin
SUPER_ADMIN_PASSWORD=your_password
SESSION_SECRET=your_secret_key
```

If not set, the session secret will be auto-generated.

## Running the Application

Start the development server:

```bash
bin/dev
```

Visit `http://localhost:4567` in your browser.

## Running Tests

Run the full test suite:

```bash
bundle exec rake test
```

Tests must pass with 100% coverage for CI to succeed.

## Database Tasks

### Import Emails

Import emails from a CSV file:

```bash
rake db:import[path/to/emails.csv,OrganizationName]
```

Example:
```bash
rake db:import[public/example_emails.csv,MFA]
```

CSV format should have one column with header "email":
```csv
email
user@example.com
member@museum.org
```

### Check Email Verification

Check if an email is verified:

```bash
rake db:check[user@example.com]
```

### Run Migrations

Apply database migrations:

```bash
rake db:migrate
```

For the test database:

```bash
rake db:migrate_test
```

## Code Quality

### Linting

Run RuboCop to check code style:

```bash
bundle exec rubocop
```

Auto-fix issues where possible:

```bash
bundle exec rubocop -A
```

## Project Structure

```
roaster/
├── config.ru                        # Application entry point
├── public/
│   └── example_emails.csv           # Example CSV template
├── config/
│   ├── database.rb                  # Database configuration
│   └── routes.rb                    # Route definitions
├── app/
│   ├── controllers/
│   │   ├── admin_controller.rb      # Organization admin logic
│   │   ├── super_admin_controller.rb # Super admin logic
│   │   └── verification_controller.rb # Email verification logic
│   ├── models/
│   │   ├── verified_email.rb        # Email hash model
│   │   ├── organization.rb          # Organization model
│   │   └── api_key.rb               # API key model
│   ├── lib/
│   │   └── auth.rb                  # Authentication helpers
│   └── views/
│       ├── layout.erb                # Main layout template
│       ├── index.erb                 # Landing page
│       ├── verify.erb                # Verification page
│       ├── admin.erb                 # Organization admin dashboard
│       └── super_admin.erb           # Super admin dashboard
└── db/
    └── migrate/                      # Database migrations
```

## How It Works

Roaster uses a privacy-first approach to email verification:

1. **Email Hashing**: When emails are imported or verified, they are hashed using SHA-256
2. **No Plaintext Storage**: Only the hash is stored in the database - the original email is never persisted
3. **Hash Comparison**: During verification, the submitted email is hashed and compared against stored hashes
4. **Organization Isolation**: Each organization has its own set of verified email hashes

This approach ensures:
- **Privacy**: No personal data (email addresses) is stored
- **GDPR Compliance**: Hash-only storage minimizes data protection requirements
- **Security**: Even if the database is compromised, original emails cannot be recovered

## Admin Panels

### Super Admin

- Access: `/super-admin`
- Manages organizations and API keys
- Credentials set via environment variables

### Organization Admin

- Access: `/admin`
- Upload verified email lists (CSV)
- View email counts
- Download example CSV templates
- Credentials set per organization

## API Access

API keys can be generated through the Super Admin panel and used for programmatic access:

```bash
curl -X POST https://roaster.fly.dev/api/v1/verify \
  -H "Authorization: Bearer your_api_key" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "organization_username": "org_username"
  }'
```

## Deployment

See [Deployment Guide](deployment.md) for production deployment instructions.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Ensure tests pass with 100% coverage
5. Run RuboCop and fix any issues
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## License

This project is licensed under the [O'Saasy License](../LICENSE.md).
