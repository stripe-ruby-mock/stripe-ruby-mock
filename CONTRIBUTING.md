# Contributor's Guide

## Installation

Install package dependencies:

```sh
bundle install
```

## Setup

Run `cp .env.example .env`, then customize `.env` variables using your own Stripe credentials.

## Development

Start a mock server (optionally pass `-p` flag for custom port):

```sh
bin/stripe-mock-server
```

Start a development console:

```sh
bin/console
```

## Testing

Run tests:

```sh
bundle exec rspec spec/
```
