<div align="center">
  <div style="display: flex; align-items: center; justify-content: center; gap: 20px;">
    <img src="public/roaster-logo.webp" alt="Roaster Logo" width="150"/>
    <h1 style="margin: 0;">Roaster</h1>
  </div>

  <br/>

  **Privacy-first email verification for organizations that care about data protection.**

  [![CI](https://github.com/silver-river-us/roaster/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/silver-river-us/roaster/actions/workflows/ci.yml)
  [![Test Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](https://github.com/silver-river-us/roaster)
  [![License: O'Saasy](https://img.shields.io/badge/License-O'Saasy-blue.svg)](LICENSE.md)
</div>

---

Roaster is an open-source email verification service that uses SHA-256 hashing to verify email addresses without storing any personal data. Organizations can maintain verified email lists while ensuring complete privacy and GDPR compliance.

## Features

- **Privacy-Preserving**: Emails are hashed using SHA-256 before storage - plaintext emails are never stored
- **Multi-Organization Support**: Manage multiple organizations with isolated email lists
- **Session-Based Admin**: Secure organization admin panels with bcrypt password hashing
- **API Access**: RESTful API with key-based authentication for programmatic access
- **Rate Limiting**: IP-based throttling to prevent abuse and ensure fair usage
- **CSV Import**: Bulk import verified emails via CSV upload
- **100% Test Coverage**: Comprehensive test suite with MiniTest
- **Open Source**: Licensed under the [O'Saasy License](LICENSE.md)

## Documentation

- 📖 **[Setup Guide](docs/setup.md)** - Installation, development, and deployment instructions
- 🏗️ **[Architecture](docs/architecture.md)** - Technical architecture and data flow diagrams

## Contributing

We welcome contributions! Here's how to get started:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Ensure tests pass with 100% coverage
5. Run RuboCop and fix any issues
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## License

This project is licensed under the [O'Saasy License](LICENSE.md).
