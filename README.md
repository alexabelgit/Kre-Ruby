# HelpfulCrowd

Jump to:
- [General information](#general-information)
- [Getting started](#getting-started)
- [Running app](#running-app)
- [Running tests](#running-tests)
- [Sample store](#sample-store)

## General information
**HelpfulCrowd** (HC hereafter) is a cloud-based application allowing merchants to add customer reviews and Q&A features to their online stores via various widgets.

HC is available as a plugin (app) on following ecommerce platforms: [Shopify](https://apps.shopify.com/helpfulcrowd), [Ecwid](https://www.ecwid.com/apps/featured/helpful-crowd) and LemonStand. In addition, merchants can sign up for HC directly and integrate it on any website regardless its platform (we call this **custom platform** or **custom website**).

This repository serves as a codebase for HelpfulCrowd core application and its supporting apps.

### Example usage
[whiskyandgrape.ecwid.com](https://whiskyandgrape.ecwid.com/) sells some fine Scotch whisky. To boost their sales the store owner needs to let potential customers know what others had to say about their products.

To do that the merchant installs HC on their store. From now on, every customer that buys something on [whiskyandgrape.ecwid.com](https://whiskyandgrape.ecwid.com/), will receive an email notification by HC, asking them to review the purchased product. Customer clicks call-to-action button in the email and is sent to a HC web page where they write a review. The review is published automatically and becomes available on [whiskyandgrape.ecwid.com](https://whiskyandgrape.ecwid.com/). The review is also available to the merchant in their HC control panel.

**Product Rating** widget on product listing page:

![Whisky&Grape screenshot](https://snag.gy/smDLkc.jpg)

**Product Tabs** widget on product details page:

![Whisky&Grape screenshot2](https://i.snag.gy/2Ej7Xo.jpg)

There are also a number of other places where product ratings & reviews appear (and most likely this number will keep increasing) but in short, HelpfulCrowd is an app that enables store owners to have those fancy golden stars next to their products.

**Note:** [whiskyandgrape.ecwid.com](https://whiskyandgrape.ecwid.com/) is our test store so you can play there and do whatever you like including placing orders (no credit card will be required). But don't expect to receive the whisky you ordered.. or should you? ; )

### Project resources

If you are reading this, you are most likely a member of the awesome team behind HelpfulCrowd, so you should already have access to following resources:

- https://trello.com/b/lIHMYy33/helpfulcrowd - this is where task/bug management happens
- https://github.com/billabongboy69/Kredo - this is project's Github repository
- https://dashboard.heroku.com/orgs/helpfulcrowd - this is where HC is deployed

If you don't yet have access to those resources, please ask for assistance from the person who hired you : )

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

To run the project locally you should have following software installed on your machine:

- Git
- Ruby 2.6.1
- Ruby-bundler
- PostgreSQL 9+
- Elasticsearch (here's [Elasticsearch installation guide](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-elasticsearch-on-ubuntu-16-04))

### Installing and configuring app

#### Step 1: In your terminal, navigate to your projects directory and clone this repository

```shell
cd YOUR-RAILS-PROJECTS
git clone git@github.com:billabongboy69/Kredo.git
```
#### Step 2: Install prerequisites system dependencies (If not already installed on system)

<!-- Required for gem idn-ruby -->
```shell
  sudo apt-get install libldap2-dev
  sudo apt-get install libidn11-dev
```

<!-- Required for gem Rugged -->
```shell
sudo apt-get install cmake
```

#### Step 3: Now navigate to the created directory `Kredo` and run `bundle install`

```shell
cd Kredo
bundle install
```
#### Step 4: Configure your app

**.env**

To run the app you will need to configure some environment variables. We are using **dotenv-rails** gem to manage those on local machines.

Default variables are already defined in `.env` file. You can use them or override with your own values defined in your own .env file (for example: `.env.local`).

**Note:** With our setup, `.env` file is checked in git and any changes to it will affect other deployments so unless that's the goal, you should not edit this file directly. Production environments do not use  `.env` and are managed by **Heroku config**.

**Note 2**: If there's a need to add an environment variable that cannot be added to `.env` due to any reason, add it as as a commented out example and add info as a sub-chapter to this very chapter.

#### Step 5: Set up databases

```shell
rails db:create db:migrate db:seed
```
Above command will create your development and test databases with a default user (in admin role and with a [sample store](#sample-store)) that you can use to sign in to the app:

**Note**: If you get an error to run migration `PG::UndefinedTable: ERROR:  relation "tolk_locales" does not exist` then comment code from `config/initializers/tolk.rb` and run migration again. After migration checkout changes.

```
user: admin@example.com
pass: asdfqwer
```

Reindex redis database using searchkick:

```shell
rails searchkick:reindex:all
```

## Running app

Run Rails server:

```shell
rails s
```

Run Sidekiq in separate terminal window (and keep it open):

```shell
bundle exec sidekiq
```

Start Elasticsearch:
```shell
sudo systemctl start elasticsearch
```

## Running tests

ToDo

## Development guidelines
### Write tests

UPDATE: If what you read below sounds like too much and you don't believe all other developers follow those instructions, you are.. right. So maybe it's up to you to start the revolution?

When working on a new task / fixing a bug, start with a test. If you don't know whether or not this particular task really needs to have a test, most likely it does. You will know when it does not need a test (..probably never?).

Don't just write tests for the sake of checking this step in the flow. Write some damn good tests you will be proud of.

Passing the test should mean that the issue it belongs to should be closed. If test does not pass unless you write some code, then go and

### Write code

This project may not have super clean code but it tries to. Don't commit code that you know is unclean, or you don't know is clean or not. Only commit bits of code you are proud of and will defend by teeth.

..And when you do, don't relax just yet, there's a big chance you will need to

### Update README

This README is a live document. Anyone contributing to this project has / will have updated the README multiple times.

- You have to update the README when you change something that relates to existing part of README, thus making it no longer correct.
- You have to update the README when you change something that makes current README unusable / incomplete for deplying the app to a new machine in a way that ALL features work at their 100%

## Sample store

When you run `rails db:seed` a sample store is also created for you and is attached to your user.
The seeded store is already synced with a demo site that you can download here:
https://github.com/billabongboy69/hc-demo-for-widgets
This site will come handy if you are working on custom platform integration
or front widgets in general.
