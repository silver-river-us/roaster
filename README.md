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

## Documentation

- 📖 **[Setup Guide](docs/setup.md)** - Installation, development, and deployment instructions
- 🏗️ **[Architecture](docs/architecture.md)** - Technical architecture and data flow diagrams
