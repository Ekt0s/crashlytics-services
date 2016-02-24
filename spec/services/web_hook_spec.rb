require 'spec_helper'

describe Service::WebHook do
  before do
    allow_any_instance_of(Faraday::RestrictIPAddressesMiddleware).to receive(:denied?).and_return(false)
  end

  it 'has a title' do
    expect(Service::WebHook.title).to eq('Web Hook')
  end

  describe 'schema and display configuration' do
    subject { Service::WebHook }

    it { is_expected.to include_string_field :url }
  end

  let(:service) { Service::WebHook.new(:url => 'https://example.org') }

  describe 'receive_verification' do
    it 'should succeed upon successful api response' do
      stub_request(:post, 'https://example.org?verification=1').
        to_return(:status => 200, :body => 'fake_body')

      resp = service.receive_verification
      expect(resp).to eq([true,  'Successfully verified Web Hook settings'])
    end

    it 'should fail upon unsuccessful api response' do
      stub_request(:post, 'https://example.org?verification=1').
        to_return(:status => 500, :body => 'fake_body')

      resp = service.receive_verification
      expect(resp).to eq([false, "Oops! Please check your settings again."])
    end
  end

  describe 'receive_issue_impact_change' do
    let(:payload) do
      {
        :title => 'foo title',
        :impact_level => 1,
        :impacted_devices_count => 1,
        :crashes_count => 1,
        :app => {
          :name => 'foo name',
          :bundle_identifier => 'foo.bar.baz'
        }
      }
    end

    it 'should succeed upon successful api response' do
      stub_request(:post, 'https://example.org').
        to_return(:status => 201, :body => 'fake_body')

      resp = service.receive_issue_impact_change(payload)
      expect(resp).to be true
    end

    it 'should fail with extra information upon unsuccessful api response' do
      stub_request(:post, 'https://example.org').
        to_return(:status => 500, :body => 'fake_body')

      expect {
        service.receive_issue_impact_change(payload)
      }.to raise_error('WebHook issue create failed - HTTP status code: 500')
    end

    it 'suppresses the body of a failed api response if it appears to be an HTML document' do
      stub_request(:post, 'https://example.org').
        to_return(:status => 500, :body => '<!DOCTYPE html><html><body>Stuff</body></html>')

      expect {
        service.receive_issue_impact_change(payload)
      }.to raise_error('WebHook issue create failed - HTTP status code: 500')
    end
  end
end
