# Deployment

Shakapacker hooks up a new `shakapacker:compile` task to `assets:precompile`, which gets run whenever you run `assets:precompile`.
If you are not using Sprockets `shakapacker:compile` is automatically aliased to `assets:precompile`.

```

## Heroku

In order for your Shakapacker app to run on Heroku, you'll need to do a bit of configuration before hand.

```bash
heroku create my-shakapacker-heroku-app
heroku addons:create heroku-postgresql:hobby-dev
heroku buildpacks:add heroku/nodejs
heroku buildpacks:add heroku/ruby
git push heroku master
```

We're essentially doing the following here:

* Creating an app on Heroku
* Creating a Postgres database for the app (this is assuming that you're using Heroku Postgres for your app)
* Adding the Heroku NodeJS and Ruby buildpacks for your app. This allows the `npm` or `yarn` executables to properly function when compiling your app - as well as Ruby.
* Pushing your code to Heroku and kicking off the deployment

Your production build process is responsible for running `yarn install` before `rake assets:precompile`. For example, if you are on Heroku, the `heroku/nodejs` buildpack must run **prior** to the `heroku/ruby` buildpack for precompilation to run successfully.

## Nginx

Shakapacker doesn't serve anything in production. You’re expected to configure your web server to serve files in public/ directly.

Some servers support sending precompressed versions of files when they're available. For example, nginx offers a `gzip_static` directive that serves files with the `.gz` extension to supported clients. With an optional module, nginx can also serve Brotli compressed files with the `.br` extension (see below for installation and configuration instructions).

Here's a sample nginx site config for a Rails app using Shakapacker:

```nginx
upstream app {
  # server unix:///path/to/app/tmp/puma.sock;
}

server {
  listen 80;
  server_name www.example.com;
  root /path/to/app/public;

  location @app {
    proxy_pass http://app;
    proxy_redirect off;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  location / {
    try_files $uri @app;
  }

  location = /favicon.ico { access_log off; log_not_found off; }
  location = /robots.txt  { access_log off; log_not_found off; }

  location ~ /\.(?!well-known).* {
    deny all;
  }

  location ~ ^/(assets|packs)/ {
    gzip_static on;
    brotli_static on; # Optional, see below
    expires max;
    add_header Cache-Control public;
  }
}
```

### Installing the ngx_brotli module

If you want to serve Brotli compressed files with nginx, you will need to install the `nginx_brotli` module. Installation instructions from source can be found in the official [google/ngx_brotli](https://github.com/google/ngx_brotli) git repository. Alternatively, depending on your platform, the module might be available via a pre-compiled package.

Once installed, you need to load the module. As we want to serve the pre-compressed files, we only need the static module. Add the following line to your `nginx.conf` file and reload nginx:

```
load_module modules/ngx_http_brotli_static_module.so;
```

Now, you can set `brotli_static on;` in your nginx site config, as per the config in the last section above.

## CDN

Shakapacker out-of-the-box provides CDN support using your Rails app `config.action_controller.asset_host` setting. If you already have [CDN](http://guides.rubyonrails.org/asset_pipeline.html#cdns) added in your Rails app
you don't need to do anything extra for Shakapacker, it just works.

## Capistrano

### Assets compiling on every deployment even if JavaScript and CSS files are not changed

Make sure you have your public outputh path (default `public/packs`), the shakapacker cache path (default `tmp/shakapacker`) and `node_modules` in `:linked_dirs`

```ruby
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/shakapacker", "public/packs", ".bundle", "node_modules"
```

If you have `node_modules` added to `:linked_dirs` you'll need to run yarn install before `deploy:assets:precompile`, so you can add this code snippet at the bottom deploy.rb

```ruby
before "deploy:assets:precompile", "deploy:yarn_install"
namespace :deploy do
  desc "Run rake yarn install"
  task :yarn_install do
    on roles(:web) do
      within release_path do
        execute("cd #{release_path} && yarn install --silent --no-progress --no-audit --no-optional")
      end
    end
  end
end
```
