# Troubleshooting

## Debugging your webpack config

1. Read the error message carefully. The error message will tell you the precise key value
   that is not matching what Webpack expects.

2. Put a `debugger` statement in your Webpack configuration and run `bin/shakapacker --debug-shakapacker`.
   If you have a node debugger installed, you'll see the Chrome debugger for your webpack
   config. For example, install the Chrome extension
   [NiM](https://chrome.google.com/webstore/detail/nodejs-v8-inspector-manag/gnhhdgbaldcilmgcpfddgdbkhjohddkj) and
   set the option for the dev tools to open automatically. Or put `chrome://inspect` in the URL bar.
   For more details on debugging, see the official
   [Webpack docs on debugging](https://webpack.js.org/contribute/debugging/#devtools)

3. Any arguments that you add to bin/shakapacker get sent to webpack. For example, you can pass `--debug` to switch loaders to debug mode. See [webpack CLI debug options](https://webpack.js.org/api/cli/#debug-options) for more information on the available options.

4. You can also pass additional options to the command to run the webpack-dev-server and start the webpack-dev-server with the option `--debug-shakapacker`

## Incorrect peer dependencies
The latest version of Shakapacker uses peer dependencies to make upgrading easier. However, there's a catch.

If you fail to update peer dependencies, you'll see an easy-to-overlook warning from `yarn install`. 

```
warning " > shakapacker@6.1.1" has incorrect peer dependency "compression-webpack-plugin@^9.0.0".
```

This omission resulted in an error in the browser:
```
Failed to load resource: net::ERR_CONTENT_DECODING_FAILED
```

The error was caused by an old version of the peer dependency webpack-compression-plugin.

So, be sure to investigate warnings from `yarn install`!

## ENOENT: no such file or directory - node-sass

If you get the error `ENOENT: no such file or directory - node-sass` on deploy with
`assets:precompile` or `bundle exec rails shakapacker:compile` you may need to
move Sass to production `dependencies`.

Move any packages that related to Sass (e.g. `node-sass` or `sass-loader`) from
`devDependencies` to `dependencies` in `package.json`. This is because
shakapacker is running on a production system with the Rails workflow to build
the assets. Particularly on hosting providers that try to detect and do the right
thing, like Heroku.

However, if you get this on local development, or not during a deploy then you
may need to rebuild `node-sass`. It's a bit of a weird error; basically, it
can't find the `node-sass` binary.  An easy solution is to create a postinstall
hook to ensure `node-sass` is rebuilt whenever new modules are installed.

In `package.json`:

```json
"scripts": {
  "postinstall": "npm rebuild node-sass"
}
```

## Can't find hello_react.js in manifest.json

* If you get this error `Can't find hello_react.js in manifest.json`
when loading a view in the browser it's because webpack is still compiling packs.
Shakapacker uses a `manifest.json` file to keep track of packs in all environments,
however since this file is generated after packs are compiled by webpack. So,
if you load a view in browser whilst webpack is compiling you will get this error.
Therefore, make sure webpack
(i.e `./bin/shakapacker-dev-server`) is running and has
completed the compilation successfully before loading a view.


## throw er; // Unhandled 'error' event

* If you get this error while trying to use Elm, try rebuilding Elm. You can do
  so with a postinstall hook in your `package.json`:

```json
"scripts": {
  "postinstall": "npm rebuild elm"
}
```

## webpack or webpack-dev-server not found

* This could happen if `shakapacker:install` step is skipped. Please run `bundle exec rails shakapacker:install` to fix the issue.

* If you encounter the above error on heroku after upgrading from Rails 4.x to 5.1.x, then the problem might be related to missing `yarn` binstub. Please run following commands to update/add binstubs:

```bash
bundle config --delete bin
./bin/rails app:update:bin # or rails app:update:bin
```

## Running webpack on Windows

If you are running webpack on Windows, your command shell may not be able to interpret the preferred interpreter
for the scripts generated in `bin/shakapacker` and `bin/shakapacker-dev-server`. Instead you'll want to run the scripts
manually with Ruby:

```
C:\path>ruby bin\webpack
C:\path>ruby bin\webpack-dev-server
```

## Invalid configuration object. webpack has been initialised using a configuration object that does not match the API schema.

If you receive this error when running `$ ./bin/shakapacker-dev-server` ensure your configuration is correct; most likely the path to your "packs" folder is incorrect if you modified from the original "source_path" defined in `config/shakapacker.yml`.

## Running Elm on Continuous Integration (CI) services such as CircleCI, CodeShip, Travis CI

If your tests are timing out or erroring on CI it is likely that you are experiencing the slow Elm compilation issue described here: [elm-compiler issue #1473](https://github.com/elm-lang/elm-compiler/issues/1473)

The issue is related to CPU count exposed by the underlying service. The basic solution involves using [libsysconfcpus](https://github.com/obmarg/libsysconfcpus) to change the reported CPU count.

Basic fix involves:

```bash
# install sysconfcpus on CI

git clone https://github.com/obmarg/libsysconfcpus.git $HOME/dependencies/libsysconfcpus
cd libsysconfcpus
.configure --prefix=$HOME/dependencies/sysconfcpus
make && make install

# use sysconfcpus with elm-make
mv $HOME/your_rails_app/node_modules/.bin/elm-make $HOME/your_rails_app/node_modules/.bin/elm-make-old
printf "#\041/bin/bash\n\necho \"Running elm-make with sysconfcpus -n 2\"\n\n$HOME/dependencies/sysconfcpus/bin/sysconfcpus -n 2 $HOME/your_rails_app/node_modules/.bin/elm-make-old \"\$@\"" > $HOME/your_rails_app/node_modules/.bin/elm-make
chmod +x $HOME/your_rails_app/node_modules/.bin/elm-make
```

## Rake assets:precompile fails. ExecJS::RuntimeError
This error occurs because you are trying to minify by `terser` a pack that's already been minified by Shakapacker. To avoid this conflict and prevent appearing of `ExecJS::RuntimeError` error, you will need to disable uglifier from Rails config:

```ruby
# In production.rb

# From
Rails.application.config.assets.js_compressor = :uglifier

# To
Rails.application.config.assets.js_compressor = Uglifier.new(harmony: true)
```

### Angular: WARNING in ./node_modules/@angular/core/esm5/core.js, Critical dependency: the request of a dependency is an expression

To silent these warnings, please update `config/webpack/webpack.config.js`:
```js
const webpack = require('webpack')
const { resolve } = require('path')
const { webpackConfig, merge } = require('shakapacker')

module.exports = merge(webpackConfig, {
  plugins: [
    new webpack.ContextReplacementPlugin(
      /angular(\\|\/)core(\\|\/)(@angular|esm5)/,
      resolve(config.source_path)
    )
  ]
})
```

### Compilation Fails Silently

If compiling is not producing output files and there are no error messages to help troubleshoot. Setting the `webpack_compile_output` configuration variable to `true` in shakapacker.yml may add some helpful error information to your log file (Rails `log/development.log` or `log/production.log`)

```yml
# shakapacker.yml
default: &default
  source_path: app/javascript
  source_entry_path: packs
  public_root_path: public
  public_output_path: complaints_packs
  webpack_compile_output: true
```

### Using global variables for dependencies

If you want to access any dependency without importing it everywhere or use it directly in your dev tools, please check: [https://webpack.js.org/plugins/provide-plugin/](https://webpack.js.org/plugins/provide-plugin/) and the [webpack docs on shimming globals](https://webpack.js.org/guides/shimming/#shimming-globals).

Note, if you are exposing globals, like jQuery, to non-webpack dependencies (like an inline script) via the [expose-loader](https://webpack.js.org/loaders/expose-loader/), you will need to override the default of `defer: true` to be `defer:false` your call to the `javascript_pack_tag` so that the browser will load your bundle to setup the global variable before other code depends on it. However, you really should try to remove the dependendency on such globals.

Thus ProvidePlugin manages build-time dependencies to global symbols whereas the expose-loader manages runtime dependencies to global symbols.

**You don't need to assign dependencies on `window`.**

For instance, with [jQuery](https://jquery.com/):
```diff
// app/javascript/entrypoints/application.js

- import jQuery from 'jquery'
- window.jQuery = jQuery
```

Instead do:
```js
// config/webpack/webpack.config.js

const webpack = require('webpack')
const { webpackConfig, merge } = require('shakapacker')

module.exports = merge(webpackConfig, {
  plugins: [
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
    })
  ],
})
```

## Wrong CDN src from javascript_pack_tag

If your deployment doesn't rebuild assets between environments (such as when
using Heroku's Pipeline promote feature). You might find that your production
application is using your staging `config.asset_host` host when using
`javascript_pack_tag`.

This can be fixed by setting the environment variable `SHAKAPACKER_ASSET_HOST` to
an empty string where your assets are compiled. On Heroku this is done under
*Settings* -> *Config Vars*.

This way shakapacker won't hard-code the CDN host into the manifest file used by
`javascript_pack_tag`, but instead fetch the CDN host at runtime, resolving the
issue.

See [this issue](https://github.com/rails/webpacker/issues/3005) for more
details.
