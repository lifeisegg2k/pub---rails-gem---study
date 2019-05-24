# Rails の Engine(gem) を Docker 使って作成する方法

Rails の Engine(gem) を理解するには、[Rails チュートリアル](https://railstutorial.jp/) を完走して、[Rails ガイド](https://railsguides.jp/) を理解して、そして GitHub の gem のコードを読みます。
学習コストは高いですが、複数のプロダクトに共通の機能を提供するのにとても有効な手段です。今回は Engine の gem を開発のサイクルができるまでをワークショップで紹介します。

## Rails の Gem の種類

- Rails で使われる Gem には大きく３種類に分けられる。

### [Ruby Gem](https://www.ruby-lang.org/ja/libraries/)

- [bcrypt](https://github.com/codahale/bcrypt-ruby) や [rack](https://github.com/rack/rack) のように Ruby を拡張するためのライブラリ。
- `bundle gem` コマンドで作成することが多い。

### [Rails Railtie](https://railsguides.jp/plugins.html)

- [Active Model](https://github.com/rails/rails/tree/master/activemodel) や [Action Mailer](https://github.com/rails/rails/tree/master/actionmailer) のように Rails を拡張するためのライブラリ。
- `rails plugin new` コマンドで作成することが多い。

### [Rails Engine](https://railsguides.jp/engines.html)

- [Active Storage](https://github.com/rails/rails/tree/master/activestorage) や [Action Cable](https://github.com/rails/rails/tree/master/actioncable) のように Rails に機能を追加するためのライブラリ。
- Engine は `Isolated Engine` と `Full Engine` で役割の違う機能の追加方法がある。
  - [devise](https://github.com/plataformatec/devise) や [Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper) は `Full Engine` の方式のライブラリ。

## Rails Engine の作成

- `Isolated Engine` で簡易な gem を作る。

### Initial

- 作業フォルダを作成する。

```bash
$ mkdir my_app && cd my_app/
$ git init && touch README.md && git add README.md
$ git config --local user.name "your-name"
$ git config --local user.email "your-name@example.com"
$ git commit -m "Initial commit" && rm README.md
$ git log --pretty=format:"%an <%ae> : %s"
your-name <your-name@example.com> : Initial commit
```

### Gemfile

- `Gemfile` ファイルに gem を追加する。

```bash
$ echo "source 'https://rubygems.org'" >  Gemfile
$ echo "gem 'rails', '~> 5.2.3'" >>  Gemfile
```

### Docker

- Docker に Ruby や Rails の環境を構築する。

```bash
$ touch Dockerfile && touch docker-compose.yml
```

- `Dockerfile` ファイルを編集する。

```Dockerfile
FROM ruby:2.6.3
RUN apt-get update -qq && apt-get install -y locales
RUN sed -i 's/#.*ja_JP\.UTF/ja_JP\.UTF/' /etc/locale.gen
RUN locale-gen && update-locale LANG=ja_JP.UTF-8
RUN mkdir /my_app
WORKDIR /my_app
COPY . /my_app
RUN bundle install
```

- `docker-compose.yml` ファイルを編集する。

```yaml
version: "3"
services:
  app:
    build: .
    volumes:
      - .:/my_app
    environment:
      - LANG=ja_JP.UTF-8
      - LC_CTYPE=ja_JP.UTF-8
```

### Rails Plugin New

- `rails plugin new` コマンドで gem の雛形を作る。
  - `--mountable`: Isolated Engine のテンプレートを使う。
    - `--full`: Full Engine のテンプレートを使う。
  - `--skip-test`: test_unit を使わない。
  - `--dummy-path`: ダミーのパスを変更する。

```bash
$ docker-compose run app rails plugin new . --mountable --skip-test --dummy-path=spec/dummy --force
```

- `my_app.gemspec` ファイルを編集する。
  - `TODO` を削除して、`factory_bot_rails` と `rspec-rails` を追加する。

```diff
   spec.email       = ["your-name@example.com"]
-  spec.homepage    = "TODO"
-  spec.summary     = "TODO: Summary of MyApp."
-  spec.description = "TODO: Description of MyApp."
+  spec.homepage    = ""
+  spec.summary     = ": Summary of MyApp."
+  spec.description = ": Description of MyApp."

   if spec.respond_to?(:metadata)
-    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
+    spec.metadata["allowed_push_host"] = ": Set to 'http://mygemserver.com'"

   spec.add_development_dependency "sqlite3"
+  spec.add_development_dependency "factory_bot_rails"
+  spec.add_development_dependency "rspec-rails"
```

- `docker-compose build` コマンドで gem を追加する。

```bash
$ docker-compose build
```

### RSpec init

- RSpec でテストを実行する準備をする。

```bash
$ docker-compose run app rails generate rspec:install
```

- `spec/rails_helper.rb` を編集する。

```diff
-require File.expand_path('../../config/environment', __FILE__)
+require File.expand_path('../dummy/config/environment', __FILE__)
-# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }
+Dir[Rails.root.join('spec', '..', '..', 'support', '**', '*.rb')].each { |f| require f}
```

```bash
$ mkdir spec/support
$ touch spec/support/factory_bot.rb
```

- `spec/support/factory_bot.rb` を編集する。

```ruby
require 'factory_bot_rails'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
```

### Rails Generate

- `lib/my_app/engine.rb` を編集する。

```ruby
module MyApp
  class Engine < ::Rails::Engine
    isolate_namespace MyApp

    config.generators do |g|
      g.test_framework :rspec,
                        view_specs: false,
                        helper_specs: false,
                        routing_specs: false,
                        controller_specs: false,
                        request_specs: false
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end
  end
end
```

```bash
$ docker-compose run app rails generate scaffold user name
```

### Rails Server

- `docker-compose.yml` ファイルを編集する。

```yaml
version: "3"
services:
  app:
    build: .
    volumes:
      - .:/my_app
    environment:
      - LANG=ja_JP.UTF-8
      - LC_CTYPE=ja_JP.UTF-8
    command: bash -c "rm -f spec/dummy/tmp/pids/server.pid && bundle exec rails s -p 3000 -b '0.0.0.0'"
    ports:
      - "3000:3000"
```

```bash
$ docker-compose run app rails db:migrate
$ docker-compose up
```

- http://localhost:3000/rails/info/routes にアクセスする。
- http://localhost:3000/my_app/users にアクセスする。

### RSpec exec

```bash
$ docker-compose run app rspec -fd
```

- `spec/factories/my_app/users.rb`

```ruby
FactoryBot.define do
  factory :my_app_user, class: 'MyApp::User' do
    sequence(:name) { |n| "name:#{n}" }
  end
end
```

- `spec/models/my_app/user_spec.rb`

```ruby
require 'rails_helper'

module MyApp
  RSpec.describe User, type: :model do
    let(:user) { build(:my_app_user) }

    describe '#name' do
      subject { user.name }

      context 'is_expected' do
        it { is_expected.to match(/^name:\d+/) }
      end
    end
  end
end
```

- docker を終了する。

```bash
$ docker-compose down
```

## Rails Engine の開発

### Rails の dummy を使う

- `spec/dummy/bin/rails` のコマンドを使う

```bash
$ docker-compose run app spec/dummy/bin/rails generate controller user/session show new
$ docker-compose up
```

- `spec/dummy/app/controllers/application_controller.rb`

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user
  helper_method :current_user

  private

  def authenticate_user
    @current_user = if session[:user_id].present?
      MyApp::User.find(session[:user_id])
    end

    if @current_user.blank?
      session.delete :user_id
      redirect_to user_sign_in_path
    end
  end

  def current_user
    @current_user
  end
end
```

- `spec/dummy/app/controllers/user/session_controller.rb`

```ruby
class User::SessionController < ApplicationController
  skip_before_action :authenticate_user, except: :show

  def show
  end

  def new
  end

  def create
    user = MyApp::User.find_by(user_params)
    if user.present?
      session[:user_id] = user.id
      redirect_to root_path
    else
      render :new
    end
  end

  def destroy
    session.delete :user_id
    redirect_to root_path
  end

  private
    def user_params
      params.permit(:name)
    end
end
```

- `spec/dummy/config/routes.rb`

```ruby
Rails.application.routes.draw do
  root 'user/session#show'
  namespace :user do
    get    :sign_in,  to: 'session#new'
    post   :sign_in,  to: 'session#create'
    delete :sign_out, to: 'session#destroy'
  end
  mount MyApp::Engine => "/my_app"
end
```

- `spec/dummy/app/views/user/session/new.html.erb`

```ruby
<h1>Please sign in</h1>
<%= form_tag user_sign_in_path do %>
<dl>
  <dt><strong>Uame:</strong></dt>
  <dd><%= text_field_tag :name %></dd>
</dl>
<%= submit_tag 'Sign in' %>
<% end %>
```

- `spec/dummy/app/views/user/session/show.html.erb`

```ruby
<h1>Profile</h1>
<dl>
  <dt><strong>Name:</strong></dt>
  <dd><%= current_user.name %></dd>
</dl>
<%= button_to 'Sign out', user_sign_out_path, method: :delete %>
```

- `MyApp::User` に登録済みの `name` のみ `sign in` が可能。

# まとめ

- Rails Engine の gem は Rails のレールが利用できる。
- Rails dummy を使って、Rails に実装した状態のテストができる。
- Mountable の方式はネームスペースが使えるので、責務が分離できる。

