# Email Organizer

Email Organizer is an Elixir/Phoenix application that helps you organize and categorize your emails from Gmail. It uses machine learning to automatically categorize incoming emails and provides a clean web interface to manage your email subscriptions.

## Features

- Gmail integration via OAuth2
- Automatic email categorization using LLM
- Email subscription management
- Real-time email processing with Broadway and Google Pub/Sub
- Beautiful web interface built with Phoenix LiveView and Tailwind CSS

## Prerequisites

- Elixir 1.14 or later
- PostgreSQL
- Google Cloud Platform account with Gmail API enabled
- Google Cloud Pub/Sub configured

## Setup

### 1. Clone the repository

```bash
git clone git@github.com:ejscunha/email_organizer.git
cd email_organizer
```

### 2. Configure Google Cloud

You can follow the guide provided [here](https://hexdocs.pm/broadway/google-cloud-pubsub.html) to configure your Google Cloud project to use Google Cloud Pub/Sub.
You may also need to enable the Gmail API for your project.

### 3. Configure environment variables

Create a `.env` file based on the provided `.envrc` template with your Google Cloud credentials configuration and Open API API Key.

- `GOOGLE_APPLICATION_CREDENTIALS` should be the path to the file with the credentials for Google Cloud service account created in the step above.
- `GOOGLE_CLOUD_PUBSUB_PROJECT_ID` should be the Google Cloud project id created in the step above.
- `GOOGLE_CLOUD_PUBSUB_TOPIC` should be the topic name created for Google Cloud Pub/Sub in the step above.
- `GOOGLE_CLOUD_PUBSUB_SUBSCRIPTION` should be the subscription name created for Google Cloud Pub/Sub in the step above.

Note: You will need something like `direnv` to automatically export the environment variables defined in the `.env` file.

### 4. Install dependencies and setup the database

```bash
mix setup
```

This will:
- Install all dependencies
- Create and migrate the database
- Install and build frontend assets (Tailwind CSS and esbuild)

### 5. Start the Phoenix server

```bash
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Authentication

The application uses Google OAuth for authentication. Visit the homepage and if you are not authenticated you will be redirected to Google authentication screen to authenticate. You will be redirected back to the page after authenticating.

## Development

- Run tests: `mix test`
- Run linter: `mix credo`
- Reset database: `mix ecto.reset`
- Update assets: `mix assets.build`

## Deployment

For production deployment, please refer to the [Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

- [Elixir Language](https://elixir-lang.org/)
- [Phoenix Framework](https://www.phoenixframework.org/)
- [Broadway](https://github.com/dashbitco/broadway) for data processing pipelines
- [Oban](https://github.com/sorentwo/oban) for background jobs
