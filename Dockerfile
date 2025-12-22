# Use Ruby 3.4 Alpine as base image
FROM ruby:3.4-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    sqlite-dev

WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Final stage
FROM ruby:3.4-alpine

# Install runtime dependencies and LiteFS requirements
RUN apk add --no-cache \
    ca-certificates \
    fuse3 \
    sqlite \
    sqlite-dev \
    tzdata

WORKDIR /app

# Copy installed gems from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy LiteFS binary
COPY --from=flyio/litefs:0.5 /usr/local/bin/litefs /usr/local/bin/litefs

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p db public tmp

# Set LiteFS directory environment variable
ENV LITEFS_DIR="/litefs"

# Expose port (Fly.io uses 8080 by default internally)
EXPOSE 8080

# LiteFS will mount and start the application
ENTRYPOINT litefs mount
