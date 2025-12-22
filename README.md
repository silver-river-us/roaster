# Roaster

[![CI](https://github.com/silver-river-us/roaster/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/silver-river-us/roaster/actions/workflows/ci.yml)
[![Test Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](https://github.com/silver-river-us/roaster)

**Privacy-first email verification for organizations that care about data protection.**

Roaster is an open-source email verification service that uses SHA-256 hashing to verify email addresses without storing any personal data. Organizations can maintain verified email lists while ensuring complete privacy and GDPR compliance.

## Features

- **Privacy-Preserving**: Emails are hashed using SHA-256 before storage - plaintext emails are never stored
- **Multi-Organization Support**: Manage multiple organizations with isolated email lists
- **Session-Based Admin**: Secure organization admin panels with bcrypt password hashing
- **API Access**: RESTful API with key-based authentication for programmatic access
- **CSV Import**: Bulk import verified emails via CSV upload
- **100% Test Coverage**: Comprehensive test suite with MiniTest
- **Open Source**: Licensed under the [O'Saasy License](LICENSE.md)

## Structure

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
│   │   ├── admin_controller.rb      # Admin business logic
│   │   └── verification_controller.rb # Verification business logic
│   ├── models/
│   │   └── verified_email.rb       # Email verification model
│   └── views/
│       ├── index.erb                # Landing page
│       ├── verify.erb               # Verification page
│       └── admin.erb                # Admin dashboard
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
rake db:import[public/example_emails.csv,MFA]
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
