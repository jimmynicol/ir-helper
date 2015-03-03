# IrHelper

This gem includes helpers to build the appropriate URLs for images served via an [image-resizer](https://github.com/jimmynicol/image-resizer) instance.

## Installation

Add this line to your application's Gemfile:

    gem 'ir_helper'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ir_helper

## Configuration
Configuring this gem is done via:

    IrHelper.configure do |config|
      # add your configuration here...
    end

For a rails project this is best done via an [initializer](http://guides.rubyonrails.org/configuring.html).

The available config options are:

### CDN
This is a required setting.

    config.cdn = 'https://my.cdn.com'


### Modifiers
This gem comes with all the available modifiers that are supported natively by `image-resizer` but also allows you add your own modifier strings if you have built custom options into your own implementation.

    # config.add_modifier(key, alias='', values=[])
    config.add_modifier(:x, :xtra, ['one', 'two'])

### Sources
As with modifiers you can add more external source options. Natively Facebook, Twitter, Youtube and Vimeo are supported but should you chose to add another to that list you can configure the gem with them

    # config.add_source(name, option)
    config.add_source(:myspace, :ms_id)

### Ruby method aliases
If you need for whatever reason to alias the helper methods provided you can do that via config aswell.

    config.add_alias :ir_image_tag, :something_else

### Javascript aliases
You can also override any of the JS method names, including the global object name.

    config.add_js_alias :js_class, 'MyAwesomeResizer'
    config.add_js_alias :js_image_tag, 'something'

## Usage

The functionality in this gem has two parts, a ruby view helper and a javascript helper.

### Ruby View Helper

You can generate an image tag in the same way the regular [helper](http://guides.rubyonrails.org/layouts_and_rendering.html#asset-tag-helpers) does, just with adding a valid set of modifiers

    <div class="content">
      <%= ir_image_tag('https://s3.amazonaws.com/sample.bucket/path/to/image.jpg', h:200, w:300) %>
      <%= ir_image_tag(fb_uid: 'missnine', s:100) %>
    </div>

You can generate a background image string

    <div style="<%= ir_background('https://s3.amazonaws.com/sample.bucket/path/to/image.jpg', h:200, w:300) %>"></div>

Or just return the url as needed

    <div class="content">
      <%= ir_url('https://s3.amazonaws.com/sample.bucket/path/to/image.jpg', h:200, w:300) %>
    </div>

### Javascript Helper

The Javascript helper is generated from the config data as an `.erb` file on load. So all of the new modifiers or sources added will be reflected, as well as any aliases set.

The JS helper (`image_resizer.js`) is either attached as a global, or can be loaded via AMD or CommonJS if you are using those techniques. It has the same helper methods as the ruby helper.

    <script>
      var imgUrl = 'https://s3.amazonaws.com/sample.bucket/path/to/image.jpg';
      $('#image-tag').append(IR.irImageTag(imgUrl, {s:200}));
      $('#image-bg').attr('style', IR.irBackground(imgUrl, {s:200}));
      $('#image-url').text(IR.irImageTag(imgUrl, {s:200}));
    </script>
    <div id="image-tag"></div>
    <div id="image-bg"></div>
    <div id="image-url"></div>

## Tests
The ruby helpers are tested with RSpec and they can be run with either:

    $ guard
    $ rspec


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
