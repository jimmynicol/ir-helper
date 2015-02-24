require 'ir_helper/helper'
require 'spec_helper'
require 'uri'

helper_class = Class.new do
  include IrHelper::Helper
end

describe 'IrHelper::Helper' do
  let(:cdn) { 'https://my.cdn.com' }
  let(:s3_obj) { '/test/image.png' }
  let(:s3) { "https://s3.amazonaws.com/sample.bucket#{s3_obj}" }
  let(:s3_inv) { "https://sample.bucket.s3.amazonaws.com#{s3_obj}" }
  let(:fb_url) { 'https://graph.facebook.com/missnine/picture' }

  subject { helper_class.new }

  context 'no configuration set' do
    it 'should throw an exception if no CDN specified' do
      expect { subject.ir_image_tag s3, s: 50 }.to raise_exception(
        IrHelper::NoCDNException
      )
    end
  end

  context 'configuration set' do
    before do
      IrHelper.reset_config
      IrHelper.configure do |config|
        config.cdn = cdn
      end
    end

    it 'should not raise an exception when cdn set' do
      expect { subject.ir_image_tag s3, s: 50 }.not_to raise_error
    end

    it 'should build an s3 url correctly' do
      expect(subject.ir_url(s3)).to eq "#{cdn}#{s3_obj}"
    end

    it 'should build an inverse s3 url correctly' do
      expect(subject.ir_url(s3_inv)).to eq "#{cdn}#{s3_obj}"
    end

    it 'should determine an s3 object correctly' do
      expect(subject.send(:s3_object, URI(s3))).to eq s3_obj
    end

    it 'should determine an object correctly from an inverse s3 url' do
      expect(subject.send(:s3_object, URI(s3_inv))).to eq s3_obj
    end

    it 'should detect a Facebook url and set the endpoint correctly' do
      url = "#{cdn}/efacebook/missnine.jpg"
      expect(subject.ir_url(fb_url)).to eq url
    end

    it 'should detect a Facebook url and set the modifiers correctly' do
      url = "#{cdn}/efacebook-s50/missnine.jpg"
      expect(subject.ir_url(fb_url, s: 50)).to eq url
    end

    it 'should respond to alias methods when they are set' do
      IrHelper.configure do |config|
        config.add_alias :ir_image_tag, :simagetag
        config.add_alias :ir_background, :sbg
        config.add_alias :ir_url, :surl
      end
      expect(subject).to respond_to :simagetag
      expect(subject).to respond_to :sbg
      expect(subject).to respond_to :surl
    end

    it 'should set alias methods appropriately' do
      IrHelper.configure do |config|
        config.add_alias :ir_url, :surl
      end
      url = "#{cdn}/efacebook-s50/missnine.jpg"
      expect(subject.ir_url(fb_url, s: 50)).to eq url
      expect(subject.surl(fb_url, s: 50)).to eq url
    end

    context 'set modifier strings correctly' do
      it 'should set square correctly' do
        expect(subject.ir_url(s3, s: 50)).to eq "#{cdn}/s50#{s3_obj}"
      end
      it 'should set height, width correctly' do
        expect(subject.ir_url(s3, h: 200, w: 300)).to eq "#{cdn}/h200-w300#{s3_obj}"
      end
      it 'should set crop properly' do
        expect(subject.ir_url(s3, c: 'fit')).to eq "#{cdn}/cfit#{s3_obj}"
      end
      it 'should not set an invalid crop value' do
        expect(subject.ir_url(s3, c: 'else')).to_not eq "#{cdn}/celse#{s3_obj}"
      end
      it 'should set gravity properly' do
        expect(subject.ir_url(s3, g: 'ne')).to eq "#{cdn}/gne#{s3_obj}"
      end
      it 'should not set an invalid gravity value' do
        expect(subject.ir_url(s3, g: 'else')).to_not eq "#{cdn}/gelse#{s3_obj}"
      end
      it 'should normalize an alias to the single letter modifier' do
        expect(subject.ir_url(s3, width: 400)).to eq subject.ir_url(s3, w:400)
        expect(subject.ir_url(s3, height: 400)).to eq subject.ir_url(s3, h:400)
        expect(subject.ir_url(s3, square: 40)).to eq subject.ir_url(s3, s:40)
      end
    end

    context 'set external source correctly' do
      it 'should set facebook when fb_uid present' do
        url = "#{cdn}/efacebook/missnine.jpg"
        expect(subject.ir_url(fb_uid: 'missnine')).to eq url
      end
      it 'should set twitter when tw_uid present' do
        url = "#{cdn}/etwitter/djmissnine.jpg"
        expect(subject.ir_url(tw_uid: 'djmissnine')).to eq url
      end
      it 'should set youtube when tw_uid present' do
        url = "#{cdn}/eyoutube/3KIZUuvnQFY.jpg"
        expect(subject.ir_url(youtube_id: '3KIZUuvnQFY')).to eq url
      end
      it 'should set vimeo when tw_uid present' do
        url = "#{cdn}/evimeo/69445362.jpg"
        expect(subject.ir_url(vimeo_id: '69445362')).to eq url
      end
    end

    context 'should handle having ir url as source' do
      let(:ir_url){ subject.ir_url(s3, s:200)}
      let(:ir_uri){ URI(ir_url) }

      it 'should recognise the cdn domain' do
        expect(subject.send(:url_domain, ir_uri.host)).to eq :cdn
      end

      it 'should recognise a modifier string' do
        part = ir_uri.path.split('/')[1]
        expect(subject.send(:has_modifier_str, part)).to be true
      end

      it 'should not recognise a modifier string if none present' do
        part = URI(subject.ir_url(s3)).path.split('/')[1]
        expect(subject.send(:has_modifier_str, part)).to be false
      end

      it 'should return the correct path' do
        expect(subject.send(:build_path, ir_uri, {})).to eq s3_obj
      end

      it 'should return new ir_url with modifiers set' do
        expect(subject.ir_url(ir_url, h:300)).to eq subject.ir_url(s3, h:300)
      end

      it 'should keep an external mod in place but change the dimension' do
        fb_url = subject.ir_url fb_uid: 'missnine', h:200
        fb_url2 = subject.ir_url fb_uid: 'missnine', s:50
        expect(subject.ir_url(fb_url, s:50)).to eq fb_url2
      end

      it 'should keep a filter in place but change the dimension' do
        f_url = subject.ir_url f:'sepia', h:200
        f_url2 = subject.ir_url f:'sepia', s:50
        expect(subject.ir_url(f_url, s:50)).to eq f_url2
      end

      it 'should not alter a mod string when no new modifiers are set' do
        expect(subject.ir_url(ir_url)).to eq ir_url
      end

    end

    context 'returning blank or nil sources' do
      it 'should return nil if nil source provided' do
        expect(subject.ir_image_tag(nil, s:50)).to eq nil
        expect(subject.ir_url(nil, s:50)).to eq nil
        expect(subject.ir_background(nil, s:50)).to eq nil
      end
      it 'should return nil if blank source provided' do
        expect(subject.ir_image_tag('', s:50)).to eq nil
        expect(subject.ir_url('', s:50)).to eq nil
        expect(subject.ir_background('', s:50)).to eq nil
      end
    end

    context 'setting html options on ir_image_tag' do
      it 'should not fail when html options are set' do
        expect{ subject.ir_image_tag s3, s: 50, alt: 'something' }.not_to raise_error
      end

      it 'should build the html options into the string' do
        tag = subject.ir_image_tag s3, s:50, alt:'Something', id:'one-id', class: 'my-big-class'
        expect(tag).to include("alt='Something'")
        expect(tag).to include("id='one-id'")
        expect(tag).to include("class='my-big-class'")
      end
    end

  end

end
