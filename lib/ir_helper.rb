require 'ir_helper/version'
require 'ir_helper/helper'
require 'ir_helper/engine' if defined?(Rails)

module IrHelper

  class << self
    attr_accessor :cdn
    attr_reader :js_class, :js_image_tag, :js_background, :js_url

    def configure(&block)
      yield self
    end

    def reset_config
      @cdn = nil
      @ir_image_tag = nil
      @ir_background = nil
      @ir_url = nil
      @js_class = 'IR'
      @js_image_tag = nil
      @js_background = nil
      @js_url = nil
      @modifiers = default_modifiers
    end

    def modifiers
      @modifiers ||= default_modifiers
    end

    def add_modifier(key, img_tag = '', values = [])
      modifiers[key.to_sym] = { alias: img_tag, values: values }
    end

    def add_source(name, option)
      modifiers[:e][:values][name.to_sym] = option.to_sym
    end

    def js_class
      @js_class ||= 'IR'
    end

    def add_alias(type, name)
      Helper.class_eval do |base|
        base.send(:alias_method, name.to_sym, type.to_sym)
      end
    end

    def add_js_alias(type, name)
      instance_variable_set "@#{type.to_s}", name
    end

    def to_hash
      {
        cdn: cdn,
        ir_image_tag: ir_image_tag,
        ir_background: ir_background,
        ir_url: ir_url,
        js_class: js_class,
        js_image_tag: js_image_tag,
        js_background: js_background,
        js_url: js_url,
        modifiers: modifiers
      }
    end

    private

    def default_modifiers
      {
        w: { alias: :width },  h: { alias: :height },
        s: { alias: :square },
        c: { alias: :crop, values: %w(fit fill cut scale) },
        g: { alias: :gravity, values: %w(c n s e w ne nw se sw) },
        y: { alias: :top }, x: { alias: :left },
        e: { alias: :external, values: default_sources },
        f: { alias: :filter }
      }
    end

    def default_sources
      {
        facebook: :fb_uid,
        twitter:  :tw_uid,
        youtube:  :youtube_id,
        vimeo:    :vimeo_id
      }
    end

  end

end
