# Architecture

This document describes the technical architecture of Roaster and how it achieves privacy-first email verification.

## Overview

Roaster is built as a classic Ruby/Sinatra web application with a focus on privacy preservation through cryptographic hashing. The application never stores plaintext email addresses, instead storing only SHA-256 hashes.

## Technology Stack

- **Web Framework**: Sinatra 4.2
- **Database**: SQLite with LiteFS for distributed replication
- **ORM**: Sequel
- **Server**: Puma
- **Session Management**: Rack::Session::Cookie
- **Authentication**: bcrypt for password hashing, API key authentication
- **Testing**: MiniTest with SimpleCov (100% coverage requirement)
- **Deployment**: Fly.io with LiteFS for multi-region distribution

## Data Flow

### Email Storage Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    ORGANIZATION UPLOADS CSV                      │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Parse CSV File     │
              │   Extract Emails     │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   For Each Email:    │
              │   SHA-256 Hash       │
              │   email.downcase     │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Store Hash + Org    │
              │  in Database         │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  ❌ PLAINTEXT EMAIL  │
              │  NEVER STORED        │
              └──────────────────────┘
```

### Email Verification Flow

```
┌─────────────────────────────────────────────────────────────────┐
│              USER SUBMITS EMAIL FOR VERIFICATION                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Normalize Email    │
              │   email.downcase     │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   SHA-256 Hash       │
              │   email.downcase     │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Query Database      │
              │  for Hash + Org      │
              └──────────┬───────────┘
                         │
                ┌────────┴────────┐
                │                 │
                ▼                 ▼
         ┌──────────┐      ┌──────────┐
         │  Found   │      │ Not Found│
         │ ✅ Verified │   │ ❌ Not   │
         │          │      │ Verified │
         └──────────┘      └──────────┘
```

## Database Schema

### Tables

#### `verified_emails`
Stores hashed email addresses associated with organizations.

| Column | Type | Description |
|--------|------|-------------|
| `id` | Integer | Primary key |
| `email_hash` | String(64) | SHA-256 hash of lowercased email |
| `organization_name` | String | Organization identifier |
| `created_at` | DateTime | Timestamp of creation |
| `updated_at` | DateTime | Timestamp of last update |

**Indexes:**
- Unique index on `(email_hash, organization_name)` - prevents duplicates
- Index on `email_hash` - fast lookup during verification

#### `organizations`
Stores organization credentials and metadata.

| Column | Type | Description |
|--------|------|-------------|
| `id` | Integer | Primary key |
| `name` | String | Organization display name |
| `username` | String | Unique login username |
| `password_hash` | String | bcrypt hashed password |
| `created_at` | DateTime | Timestamp of creation |
| `updated_at` | DateTime | Timestamp of last update |

**Indexes:**
- Unique index on `username`

#### `api_keys`
Stores API keys for programmatic access.

| Column | Type | Description |
|--------|------|-------------|
| `id` | Integer | Primary key |
| `name` | String | Descriptive name for the key |
| `key_hash` | String | SHA-256 hash of the API key |
| `key_prefix` | String | First 8 characters for identification |
| `created_at` | DateTime | Timestamp of creation |
| `updated_at` | DateTime | Timestamp of last update |
| `last_used_at` | DateTime | Timestamp of last use |

**Indexes:**
- Index on `key_hash` - fast API key lookup

## Application Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         config.ru (Entry Point)                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
  ┌────────────┐  ┌────────────┐  ┌────────────┐
  │  Rack      │  │  Session   │  │  Routes    │
  │  Middleware│  │  Cookie    │  │  config/   │
  └────────────┘  └────────────┘  └─────┬──────┘
                                        │
                         ┌──────────────┼──────────────┐
                         │              │              │
                         ▼              ▼              ▼
                  ┌────────────┐ ┌────────────┐ ┌────────────┐
                  │Verification│ │   Admin    │ │Super Admin │
                  │Controller  │ │ Controller │ │ Controller │
                  └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
                        │              │              │
                        └──────────────┼──────────────┘
                                       │
                         ┌─────────────┼─────────────┐
                         │             │             │
                         ▼             ▼             ▼
                  ┌────────────┐ ┌────────────┐ ┌────────────┐
                  │Verified    │ │Organization│ │  API Key   │
                  │Email Model │ │   Model    │ │   Model    │
                  └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
                        │              │              │
                        └──────────────┼──────────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │  SQLite + LiteFS│
                              │  Database       │
                              └─────────────────┘
```

## Key Components

### Controllers

#### VerificationController
- Handles email verification requests
- Hashes submitted emails
- Queries database for matches
- Returns verification status

#### AdminController
- Organization-specific admin panel
- CSV upload for bulk email import
- Email list management
- Requires session authentication

#### SuperAdminController
- System-wide administration
- Organization CRUD operations
- API key management
- Requires super admin authentication

### Models

#### VerifiedEmail
- Stores hashed emails with organization association
- Class methods for verification and CSV import
- Automatically hashes emails before storage

#### Organization
- Manages organization credentials
- bcrypt password hashing
- Organization-specific data isolation

#### ApiKey
- Generates and validates API keys
- SHA-256 hashing for secure storage
- Tracks last usage timestamp

## Security Features

### Password Security
- All passwords hashed with bcrypt (cost factor 12)
- No plaintext passwords stored
- Secure session cookies with HttpOnly flag

### Email Privacy
- SHA-256 hashing before storage
- Lowercase normalization for consistency
- No plaintext emails ever persisted
- Hash-only database queries

### API Security
- API keys hashed with SHA-256
- Key prefix stored for identification
- Bearer token authentication
- Last used timestamp tracking

### Session Security
- Secure session cookies
- HttpOnly and SameSite flags
- 24-hour expiration
- CSRF protection via Rack::Protection

## Privacy Guarantees

1. **No Plaintext Storage**: Email addresses are hashed immediately and never stored in plaintext
2. **One-Way Hashing**: SHA-256 is cryptographically secure and cannot be reversed
3. **Collision Resistance**: SHA-256 makes hash collisions computationally infeasible
4. **Data Minimization**: Only necessary data (hashes) is stored
5. **Organization Isolation**: Each organization's data is completely separate

## Deployment Architecture

### LiteFS Distribution

```
┌─────────────────────────────────────────────────────────────────┐
│                         Fly.io Platform                          │
└─────────────────────────────────────────────────────────────────┘

        Primary Region (iad)              Replica Region (optional)
┌────────────────────────────┐    ┌────────────────────────────┐
│  ┌──────────────────────┐  │    │  ┌──────────────────────┐  │
│  │   Roaster App        │  │    │  │   Roaster App        │  │
│  │   (Sinatra/Puma)     │  │    │  │   (Sinatra/Puma)     │  │
│  └──────────┬───────────┘  │    │  └──────────┬───────────┘  │
│             │              │    │             │              │
│             ▼              │    │             ▼              │
│  ┌──────────────────────┐  │    │  ┌──────────────────────┐  │
│  │   LiteFS (Primary)   │  │    │  │  LiteFS (Replica)    │  │
│  │   - Accepts Writes   │◄─┼────┼─►│  - Read-Only         │  │
│  │   - Replicates Data  │  │    │  │  - Syncs from Primary│  │
│  └──────────┬───────────┘  │    │  └──────────┬───────────┘  │
│             │              │    │             │              │
│             ▼              │    │             ▼              │
│  ┌──────────────────────┐  │    │  ┌──────────────────────┐  │
│  │  SQLite Database     │  │    │  │  SQLite Database     │  │
│  │  (Volume: litefs)    │  │    │  │  (Volume: litefs)    │  │
│  └──────────────────────┘  │    │  └──────────────────────┘  │
└────────────────────────────┘    └────────────────────────────┘
                │                                  │
                └────────────┬─────────────────────┘
                             │
                             ▼
                   ┌──────────────────┐
                   │  Consul (Fly.io) │
                   │  Coordination    │
                   └──────────────────┘
```

### Request Flow

1. User requests hits Fly.io edge
2. Routed to nearest available region
3. LiteFS proxy intercepts database operations
4. Writes forwarded to primary region
5. Reads served from local replica
6. Changes replicated to all regions

## Performance Considerations

### Database Indexing
- Hash lookups are O(log n) due to B-tree indexes
- Unique constraint prevents duplicates efficiently
- Composite index on `(email_hash, organization_name)` optimizes verification queries

### Caching
- Session data cached in encrypted cookies
- No server-side session store needed
- Reduces database load

### LiteFS Replication
- Read-heavy workloads benefit from local replicas
- Write operations forwarded to primary
- Eventual consistency for global distribution

## Future Enhancements

Potential areas for expansion:

1. **Rate Limiting**: Add per-IP rate limiting for verification endpoints
2. **Analytics**: Track verification attempts and success rates
3. **Webhooks**: Notify organizations of verification events
4. **Multi-Database Support**: PostgreSQL option for larger deployments
5. **Audit Logging**: Track all administrative actions
6. **Backup System**: Automated LiteFS backups to S3

## License

This architecture is part of Roaster, licensed under the [O'Saasy License](../LICENSE.md).
