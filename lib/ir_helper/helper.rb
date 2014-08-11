require 'uri'

module IrHelper
  # Series of view helpers building url strings for image-resizer endpoints
  module Helper
    def ir_image_tag(*args)
      src = generate_ir_endpoint(args)
      return nil if src.nil?
      if respond_to?(:image_tag)
        image_tag src
      else
        "<img src='#{src}' />"
      end
    end

    def ir_background(*args)
      url = generate_ir_endpoint(args)
      url ? "background-image:url(#{url})" : nil
    end

    def ir_url(*args)
      generate_ir_endpoint(args)
    end

    private

    def parse_arguments(args)
      if args[0].is_a?(String) || args[0].nil?
        [args[0], args[1..-1]]
      else
        [nil, args]
      end
    end

    def cdn
      ::IrHelper.cdn
    end

    def self.img_tag_name
      ::IrHelper.image_tag_name
    end

    def mods
      ::IrHelper.modifiers
    end

    def mod_set(key)
      mods.each do |k, v|
        return v if key.to_sym == k || v[:alias] == key
      end
      nil
    end

    def sources
      mods[:e][:values]
    end

    def source_option(key)
      sources.each do |k, v|
        return [k, v] if key == v
      end
      nil
    end

    def generate_ir_endpoint(args)
      fail NoCDNException if cdn.nil?

      source, modifiers = parse_arguments(args)
      uri = source ? URI(source) : nil
      modifier_str = mod_str(uri, modifiers)
      path = build_path(uri, modifiers)

      if path
        "#{cdn.gsub(/\/$/, '')}#{modifier_str}#{path}"
      else
        nil
      end
    end

    def mod_str(uri, modifiers)
      mod_arr = []
      unless modifiers.nil? || modifiers[0].nil?
        mod_arr = build_mod_arr(modifiers)
      end
      mod_arr << 'efacebook' if uri && url_domain(uri.host) == :facebook
      mod_arr.compact
      mod_arr = cdn_mod_arr(uri, mod_arr)
      mod_arr = mod_arr.sort
      mod_arr.length > 0 ? "/#{mod_arr.join('-')}" : ''
    end

    def build_mod_arr(modifiers)
      modifiers[0].map do |k, v|
        mset = mod_set(k)
        src = source_option(k)
        if mset
          if mset.include? :values
            mset[:values].include?(v) ? "#{k}#{v}" : nil
          else
            "#{k}#{v}"
          end
        elsif src
          "e#{src.first}"
        else
          nil
        end
      end
    end

    def cdn_mod_arr(uri, mod_arr)
      if uri && url_domain(uri.host) == :cdn
        mod = uri.path.split('/')[1]
        if has_modifier_str(mod)
          mods = mod.split('-')
          # if no mods are specified then use those from the existing url
          if mod_arr.length == 0
            mod_arr = mods

          # if there are mods specified then only add any existing external
          # source or filter modifiers
          else
            mods.each do |m|
              mod_arr << m if ['e','f'].include?(m[0])
            end
          end
        end
      end

      mod_arr
    end

    def build_path(uri, modifiers)
      if uri
        case url_domain(uri.host)
        when :cdn
          cdn_object uri
        when :s3
          s3_object uri
        when :facebook
          "/#{fb_uid(uri)}.jpg"
        else
        end
      else
        modifiers[0].each do |k, v|
          return "/#{v}.jpg" if source_option(k)
        end
        nil
      end
    end

    def url_domain(host)
      return :cdn if /#{URI(cdn).host}/i =~ host
      return :s3 if /s3.amazonaws.com/i =~ host
      return :facebook if /facebook.com/i =~ host
      :other
    end

    # Get the path of an already IR'd url, basically make sure we remove the
    # modifier string if it is present
    def cdn_object(uri)
      parts = uri.path.split('/')

      # test to see if there is an existing modifier string in place
      if has_modifier_str(parts[1])
        "/#{parts[2..-1].join('/')}"
      else
        uri.path
      end
    end

    def has_modifier_str(part)
      part.split('-').each do |item|
        key = item[0]
        value = item[1..-1]
        flag = if v = mod_set(key)
          if v.include?(:values)
            v[:values].include?(value)
          else
            value.to_i > 0
          end
        else
          false
        end
        return true if flag
      end

      false
    end

    def s3_object(uri)
      # test to see which type of s3 url we have
      if uri.host == 's3.amazonaws.com'
        # this version has the bucket at the first part of the path
        "/#{uri.path.split('/')[2..-1].join('/')}"
      else
        # this version has the bucket included in the host
        uri.path
      end
    end

    def fb_uid(uri)
      uri.path.split('/')[1]
    end
  end

  class NoCDNException < Exception; end
  class NotS3SourceException < Exception; end
end
