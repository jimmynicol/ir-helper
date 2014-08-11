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
      url = "#{cdn}/s50-efacebook/missnine.jpg"
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
      url = "#{cdn}/s50-efacebook/missnine.jpg"
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
  end

end
