# Roaster

Email verification service with privacy-preserving hashed storage.

## Structure

```
roaster/
├── config.ru                        # Application entry point
├── assets/
│   └── example_emails.csv           # Example CSV template
├── config/
│   ├── database.rb                  # Database configuration
│   └── routes.rb                    # Route definitions
├── controllers/
│   ├── admin_controller.rb          # Admin business logic
│   └── verification_controller.rb   # Verification business logic
├── models/
│   └── verified_email.rb           # Email verification model
├── views/
│   ├── index.erb                    # Verification page
│   └── admin.erb                    # Admin dashboard
└── db/
    └── migrate/                     # Database migrations
```

## Setup

```bash
bundle install
rake db:migrate
```

## Import Emails

```bash
rake db:import[path/to/emails.csv,OrganizationName]
```

Example:
```bash
rake db:import[assets/example_emails.csv,MFA]
```

CSV format should have one column with header "email":
```csv
email
user@example.com
member@museum.org
```

## Check Email

```bash
rake db:check[user@example.com]
```

## Run Server

```bash
bin/dev
```

Visit `http://localhost:4567`

## How It Works

- Emails are hashed using SHA256 before storage
- Only hashes are stored in the database (privacy-preserving)
- Verification checks if hash of submitted email exists
- Original emails are never stored
