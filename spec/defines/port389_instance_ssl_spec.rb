require 'spec_helper'

#describe 'port389::instance::ssl', :type => :define do
describe 'port389::instance', :type => :define do
  let(:facts) {{ :osfamily => 'RedHat' }}
  let(:pre_condition) { 'include port389' }
  let(:title) { 'ldap1' }

  context 'enable_ssl =>' do
    context 'true' do
      let(:params) do
        {
  #        :root_dn     => 'admin',
  #        :root_dn_pwd => 'admin',
  #        :server_port => 389,
          :enable_ssl   => true,
          :ssl_cert     => '/dne/cert.pem',
          :ssl_key      => '/dne/key.pem',
          :ssl_ca_certs => {
            'AlphaSSL CA'        => '/tmp/alphassl_intermediate.pem',
            'GlobalSign Root CA' => '/tmp/globalsign_root.pem',
          }
        }
      end

      it do
        should contain_file('enable_ssl.ldif').with({
          :ensure => 'file',
          :path   => '/var/lib/dirsrv/setup/enable_ssl.ldif',
          :owner  => 'nobody',
          :group  => 'nobody',
          :mode   => '0600',
          :backup => false,
        })
      end

      it do
        should contain_file('ldap1-set_secureport.ldif').with({
          :ensure  => 'file',
          :path    => '/var/lib/dirsrv/setup/ldap1-set_secureport.ldif',
          :owner   => 'nobody',
          :group   => 'nobody',
          :mode    => '0600',
          :backup  => false,
          :content => <<-EOS
dn: cn=config
changetype: modify
add: nsslapd-secureport
nsslapd-secureport: 636
          EOS
        })
      end

      it do
        should contain_exec('ldap1-enable_ssl.ldif').with({
          :path      => [ '/bin', '/usr/bin' ],
          :logoutput => true,
        })
      end

      it do
        should contain_exec('ldap1-set_secureport.ldif').with({
          :path      => [ '/bin', '/usr/bin' ],
          :logoutput => true,
        })
      end

      it do
        should contain_file('ldap1-pin.txt').with({
          :ensure  => 'file',
          :path    => '/etc/dirsrv/slapd-ldap1/pin.txt',
          :owner   => 'nobody',
          :group   => 'nobody',
          :mode    => '0400',
          :content => 'Internal (Software) Token:admin',
        })
      end

      it do
        should contain_nssdb__create('/etc/dirsrv/slapd-ldap1').with({
          :owner_id       => 'nobody',
          :group_id       => 'nobody',
          :mode           => '0600',
          :password       => 'admin',
          :manage_certdir => false,
        })
      end

      it do
        should contain_nssdb__add_cert_and_key('/etc/dirsrv/slapd-ldap1').with({
          :nickname => 'Server-Cert',
          :cert     => '/dne/cert.pem',
          :key      => '/dne/key.pem',
        })
      end

      # note that the nssdb::add_cert resources are dynamically generated by the
      # port389_nssdb_add_cert() function
      it do
        should contain_nssdb__add_cert('/etc/dirsrv/slapd-ldap1-AlphaSSL CA').with({
          :certdir  => '/etc/dirsrv/slapd-ldap1',
          :nickname => 'AlphaSSL CA',
          :cert     => '/tmp/alphassl_intermediate.pem',
        })
      end

      it do
        should contain_nssdb__add_cert('/etc/dirsrv/slapd-ldap1-GlobalSign Root CA').with({
          :certdir  => '/etc/dirsrv/slapd-ldap1',
          :nickname => 'GlobalSign Root CA',
          :cert     => '/tmp/globalsign_root.pem',
        })
      end

      # XXX highly internal implimentation specific
      it do
        should contain_port389__instance__ssl('ldap1').
          that_notifies('Service[ldap1]')
      end
    end # true

    context 'false' do
      let(:params) {{ :enable_ssl  => false }}

      it { should_not contain_file('enable_ssl_enable.ldif') }
      it { should_not contain_exec('ldap1-enable_ssl.ldif') }
      it { should_not contain_file('pin.txt-ldap1') }
      it { should_not contain_nssdb__create('/etc/dirsrv/slapd-ldap1') }
      it { should_not contain_nssdb__add_cert_and_key('/etc/dirsrv/slapd-ldap1') }
      it { should_not contain_nssdb__add_cert('/etc/dirsrv/slapd-ldap1-AlphaSSL CA') }
      it { should_not contain_nssdb__add_cert('/etc/dirsrv/slapd-ldap1-GlobalSign Root CA') }
    end # false

    context 'foo' do
      let(:params) {{ :enable_ssl  => 'foo' }}

      it 'should fail' do
        expect { should compile }.to raise_error(/is not a boolean/)
      end
    end # foo
  end # enable_ssl =>

  context 'ssl_cert =>' do
    let(:params) do
      {
        :enable_ssl => true,
        :ssl_key    => '/dne/key.pem',
      }
    end

    context '/dne/cert.pem' do
      before { params[:ssl_cert] = '/dne/cert.pem' }

      it do
        should contain_nssdb__add_cert_and_key('/etc/dirsrv/slapd-ldap1').with({
          :nickname => 'Server-Cert',
          :cert     => '/dne/cert.pem',
          :key      => '/dne/key.pem',
        })
      end
    end

    context '../dne/cert.pem' do
      before { params[:ssl_cert] = '../dne/cert.pem' }

      it 'should fail' do
        expect { should compile }.to raise_error(/is not an absolute path./)
      end
    end
  end # ssl_cert =>

  context 'ssl_key =>' do
    let(:params) do
      {
        :enable_ssl => true,
        :ssl_cert   => '/dne/cert.pem',
      }
    end

    context '/dne/key.pem' do
      before { params[:ssl_key] = '/dne/key.pem' }

      it do
        should contain_nssdb__add_cert_and_key('/etc/dirsrv/slapd-ldap1').with({
          :nickname => 'Server-Cert',
          :cert     => '/dne/cert.pem',
          :key      => '/dne/key.pem',
        })
      end
    end

    context '../dne/key.pem' do
      before { params[:ssl_key] = '../dne/key.pem' }

      it 'should fail' do
        expect { should compile }.to raise_error(/is not an absolute path./)
      end
    end
  end # ssl_key =>

  context 'ca_certs =>' do
    let(:params) do
      {
        :enable_ssl => true,
        :ssl_cert   => '/dne/cert.pem',
        :ssl_key    => '/dne/key.pem',
      }
    end

    context '{}' do
      before { params[:ssl_ca_certs] = {} }

      it { should have_nssdb__add_cert_resource_count(0) }
    end

    context '{ ... }' do
      before do
        params[:ssl_ca_certs] = {
          'AlphaSSL CA'        => '/tmp/alphassl_intermediate.pem',
          'GlobalSign Root CA' => '/tmp/globalsign_root.pem',
        }
      end

      it { should have_nssdb__add_cert_resource_count(2) }

      it do
        should contain_nssdb__add_cert('/etc/dirsrv/slapd-ldap1-AlphaSSL CA').with({
          :nickname => 'AlphaSSL CA',
          :certdir  => '/etc/dirsrv/slapd-ldap1',
          :cert     => '/tmp/alphassl_intermediate.pem',
        })
      end

      it do
        should contain_nssdb__add_cert('/etc/dirsrv/slapd-ldap1-GlobalSign Root CA').with({
          :nickname => 'GlobalSign Root CA',
          :certdir  => '/etc/dirsrv/slapd-ldap1',
          :cert     => '/tmp/globalsign_root.pem',
        })
      end
    end

    context 'foo' do
      before { params[:ssl_ca_certs] = 'foo' }

      it 'should fail' do
        expect { should compile }.to raise_error(/is not a Hash./)
      end
    end

  end # ca_certs =>

end
