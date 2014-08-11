require 'spec_helper'

describe 'IrHelper' do
  let(:cdn) { 'https://my.cdn.com' }
  subject { IrHelper }

  context '#configure' do
    before do
      subject.reset_config
    end

    it 'should have no cdn set' do
      expect(subject.cdn).to eq nil
    end

    it 'should set the cdn url' do
      subject.configure do |config|
        config.cdn = cdn
      end
      expect(subject.cdn).to eq cdn
    end

    it 'should set a default for the js_class' do
      expect(subject.js_class).to eq 'IR'
    end

    it 'should set the js_class' do
      subject.configure do |config|
        config.add_js_alias :js_class, 'IRAwesome'
      end
      expect(subject.js_class).to eq 'IRAwesome'
    end

    it 'should set the js_image_tag' do
      subject.configure do |config|
        config.add_js_alias :js_image_tag, 'something_ir_tag'
      end
      expect(subject.js_image_tag).to eq 'something_ir_tag'
    end

    it 'should set the js_background' do
      subject.configure do |config|
        config.add_js_alias :js_background, 'something_background'
      end
      expect(subject.js_background).to eq 'something_background'
    end

    it 'should set the js_url' do
      subject.configure do |config|
        config.add_js_alias :js_url, 'something_url'
      end
      expect(subject.js_url).to eq 'something_url'
    end

    it 'should include modifiers' do
      expect(subject.modifiers).to include(:w, :h, :s, :c, :g, :y, :x, :e, :f)
    end

    it 'should allow adding of new modifier' do
      subject.configure do |config|
        config.add_modifier 'something', 'else'
      end

      expect(subject.modifiers).to include(:something)
      expect(subject.modifiers[:something][:alias]).to eq 'else'
    end

    it 'should allow adding of new source' do
      subject.configure do |config|
        config.add_modifier 'something', 'else'
        config.add_source 'myspace', 'myspace_id'
      end
      expect(subject.modifiers[:e][:values]).to include(:myspace)
    end
  end

end
