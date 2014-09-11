require 'spec_helper'

describe 'jetty', :type => 'define' do
  let(:title) {'jetty'}
  let(:params) {{
    :version => "9.0.4.v20130625",
    :home    => "/opt",
    :user    => "jettyuser",
    :group   => "jettygroup",
    :name    => "jetty",
  }}

  it { should compile.with_all_deps }

  it { should contain_file("/opt/jetty").with_ensure("/opt/jetty-distribution-9.0.4.v20130625") }
  it { should contain_service("jetty").with_ensure("running") }
  it { should contain_exec("jetty_untar_jetty").with_command(/chown -R jettyuser:jettygroup/) }
  it { should contain_exec("replace JETTY_HOME for jetty in jetty.sh") }
  it { should contain_exec("replace JETTY_PID for jetty.pid in jetty.sh") }

end
