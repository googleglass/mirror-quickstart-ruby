# Deprecation Notice
This sample project has been deprecated. It is no longer being actively maintained and is probably out of date.

In other words, if you decide to clone this repository, you're on your own.

# Google Mirror API's Quick Start for Ruby (using Sinatra)

This project shows you how to implement a simple
piece of Glassware that demos the major functionality of the Google Mirror API.

## Prerequisites

- Ruby 1.9 or higher
- To use subscriptions, you also need an Internet accessible hosting
  environment with a valid SSL certificate signed by a trusted certificate
  authority.

Note: You can start developing with a localhost instance of your HTTP server,
  but you must have an Internet accessible host to use the subscription features
  of the API.

## Configuring the project

Enter your client ID, secret, and an OAuth2 redirect URL in `client_secrets.json`:

    {
        "web": {
            "client_id": "1234.apps.googleusercontent.com",
            "client_secret": "ITS_A_SECRET_TO_EVERYBODY",
            "redirect_uris": [
                "http://example.com/oauth2callback"
            ],
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://accounts.google.com/o/oauth2/token"
        }
    }

### Installing gem dependencies

This example uses [Bundler](http://bundler.io) to manage gem
dependencies. Before running the script for the first time, run the
following command from a terminal in the directory containing the Quick
Start files to install the required gems:

    $ bundle install


## Running a local development server

Before deploying to your production server, you can run the Quick Start project
as a local development server for testing. This application is written using
the [Sinatra](http://www.sinatrarb.com/) micro-framework, and you can launch it
as a standard Ruby script from the terminal:

1. From a terminal in the directory containing your Quick Start files, run:

        $ ruby mirror_quick_start.rb

2. Start using the Quick Start on your default browser at
   [http://localhost:4567](http://localhost:4567).


## Deploying the project

To deploy the Quick Start to your host server, copy the Ruby Quick Start
directory to your web server and configure it as a Rack application per
your server's instructions. [Phusion Passenger](http://www.modrails.com/)
along with [Apache httpd](http://httpd.apache.org/) or
[nginx](http://nginx.org/) work great. For detailed instructions on deploying
a Sinatra application to either of these servers, please refer to the *Phusion
Passenger users guide* for
[Apache](http://www.modrails.com/documentation/Users%20guide%20Apache.html) or
[nginx](http://www.modrails.com/documentation/Users%20guide%20Nginx.html).

