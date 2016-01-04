require 'test_helper'

class LetsencryptPluginTest < ActiveSupport::TestCase
  setup do
    Dummy::Application.load_tasks
  end

  test 'truth' do
    assert_kind_of Module, LetsencryptPlugin
  end

  test 'certificate_generator' do
    LetsencryptPlugin::CertGenerator.new
  end
end
