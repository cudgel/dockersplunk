# Splunk testing in Docker

This is just a small project to test the Splunk module in Docker.

Here I deploy a clean rocky8 test host using Vagrant.

```bash
~/Projects/vagrant/rocky8
❯ vagrant init rocky8-base
A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment! Please read
the comments in the Vagrantfile as well as documentation on
`vagrantup.com` for more information on using Vagrant.

~/Projects/vagrant/rocky8
❯ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'rocky8-base'...
==> default: Matching MAC address for NAT networking...
==> default: Setting the name of the VM: rocky8_default_1563372654765_8515
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
    default:
    default: Vagrant insecure key detected. Vagrant will automatically replace
    default: this with a newly generated keypair for better security.
    default:
    default: Inserting generated public key within guest...
    default: Removing insecure key from the guest if it's present...
    default: Key inserted! Disconnecting and reconnecting using new SSH key...
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
==> default: Mounting shared folders...
    default: /vagrant => /Users/caldwell/Projects/vagrant/rocky8
```

Connect to the new machine and install the necessary software to build the Docker image - Docker, Packer, and git.

```bash
~/Projects/vagrant/rocky8
❯ vagrant ssh
Last login: Thu Jan 31 17:17:22 2019 from gateway
vagrant@c7 ~]$ sudo yum -y install docker git
[vagrant@c7 ~]$ curl https://releases.hashicorp.com/packer/1.4.2/packer_1.4.2_linux_amd64.zip -o packer.zip
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 40.9M  100 40.9M    0     0  1134k      0  0:00:37  0:00:37 --:--:-- 1406k
[vagrant@c7 ~]$ unzip packer
Archive:  packer.zip
  inflating: packer
```

Clone this repo - really just a Packerfile and a Puppet manifest.

```bash
[vagrant@c7 ~]$ git clone https://github.com/cudgel/dockersplunk.git
Cloning into 'dockersplunk'...
remote: Enumerating objects: 11, done.
remote: Counting objects: 100% (11/11), done.
remote: Compressing objects: 100% (9/9), done.
remote: Total 11 (delta 2), reused 7 (delta 0), pack-reused 0
Unpacking objects: 100% (11/11), done.
```

Get the Splunk module (docker branch) and it's dependency (stdlib) and put them in a modules/ directory somehow. Here I use the installed puppet agent included on this base image to grab the modules. I replace the splunk module with the docker branch for now until this feature has been tested and released.

```bash
[vagrant@c7 ~]$ cd dockersplunk
[vagrant@c7 dockersplunk]$ puppet module install cudgel-splunk
Notice: Preparing to install into /home/vagrant/.puppetlabs/etc/code/modules ...
Notice: Created target directory /home/vagrant/.puppetlabs/etc/code/modules
Notice: Downloading from https://forgeapi.puppet.com ...
Notice: Installing -- do not interrupt ...
/home/vagrant/.puppetlabs/etc/code/modules
└─┬ cudgel-splunk (v1.6.2)
  └── puppetlabs-stdlib (v4.25.1)
[vagrant@c7 dockersplunk]$ ln -s ~/.puppetlabs/etc/code/modules modules
```

Start the installed Docker service.

```bash
[vagrant@c7 dockersplunk]$ sudo systemctl start docker
[vagrant@c7 dockersplunk]$ ps -ef | grep docker
root      5967     1  3 10:44 ?        00:00:00 /usr/bin/dockerd-current --add-runtime docker-runc=/usr/libexec/docker/docker-runc-current --default-runtime=docker-runc --exec-opt native.cgroupdriver=systemd --userland-proxy-path=/usr/libexec/docker/docker-proxy-current --init-path=/usr/libexec/docker/docker-init-current --seccomp-profile=/etc/docker/seccomp.json --selinux-enabled --log-driver=journald --signature-verification=false --storage-driver overlay2
root      5972  5967  0 10:44 ?        00:00:00 /usr/bin/docker-containerd-current -l unix:///var/run/docker/libcontainerd/docker-containerd.sock --metrics-interval=0 --start-timeout 2m --state-dir /var/run/docker/libcontainerd/containerd --shim docker-containerd-shim --runtime docker-runc --runtime-args --systemd-cgroup=true
vagrant   6093  5545  0 10:44 pts/0    00:00:00 grep --color=auto docker
```

Run Packer.

```bash
[vagrant@c7 dockersplunk]$ sudo ../packer build machine_puppet.json

==> docker: Creating a temporary directory for sharing data...
==> docker: Pulling Docker image: rocky:7
    docker: Trying to pull repository docker.io/library/rocky ...
    docker: 7: Pulling from docker.io/library/rocky
    docker: 8ba884070f61: Pulling fs layer
    docker: 8ba884070f61: Verifying Checksum
    docker: 8ba884070f61: Download complete
    docker: 8ba884070f61: Pull complete
    docker: Digest: sha256:a799dd8a2ded4a83484bbae769d97655392b3f86533ceb7dd96bbac929809f3c
    docker: Status: Downloaded newer image for docker.io/rocky:7
==> docker: Starting docker container...
    docker: Run command: docker run -v splunk_data:/srv/data -v /root/.packer.d/tmp:/packer-files -d -i -t --entrypoint=/bin/sh -- rocky:7
    docker: Container ID: 2e2f36c777b8a8300307aab4ebc96b7d0048dc1e272df40de82f2000435b734e
==> docker: Using docker communicator to connect: 172.17.0.2
==> docker: Provisioning with shell script: /tmp/packer-shell800033165
==> docker: warning: /var/tmp/rpm-tmp.v22Z0O: Header V4 RSA/SHA256 Signature, key ID ef8d349f: NOKEY
    docker: Retrieving https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm
    docker: Preparing...                          ########################################
    docker: Updating / installing...
    docker: puppet5-release-5.0.0-4.el7           ########################################
    docker: Loaded plugins: fastestmirror, ovl
    docker: Determining fastest mirrors
    docker:  * base: mirror.wdc1.us.leaseweb.net
    docker:  * extras: ftpmirror.your.org
    docker:  * updates: mirrors.umflint.edu
    docker: Resolving Dependencies
    docker: --> Running transaction check
    docker: ---> Package bind-license.noarch 32:9.9.4-73.el7_6 will be updated
    docker: ---> Package bind-license.noarch 32:9.9.4-74.el7_6.1 will be an update
    docker: ---> Package dbus.x86_64 1:1.10.24-12.el7 will be updated
    docker: ---> Package dbus.x86_64 1:1.10.24-13.el7_6 will be an update
    docker: ---> Package dbus-libs.x86_64 1:1.10.24-12.el7 will be updated
        docker: ---> Package dbus-libs.x86_64 1:1.10.24-13.el7_6 will be an update
    docker: ---> Package device-mapper.x86_64 7:1.02.149-10.el7_6.3 will be updated
    docker: ---> Package device-mapper.x86_64 7:1.02.149-10.el7_6.8 will be an update
    docker: ---> Package device-mapper-libs.x86_64 7:1.02.149-10.el7_6.3 will be updated
    docker: ---> Package device-mapper-libs.x86_64 7:1.02.149-10.el7_6.8 will be an update
    docker: ---> Package glib2.x86_64 0:2.56.1-2.el7 will be updated
    docker: ---> Package glib2.x86_64 0:2.56.1-4.el7_6 will be an update
    docker: ---> Package glibc.x86_64 0:2.17-260.el7_6.3 will be updated
    docker: ---> Package glibc.x86_64 0:2.17-260.el7_6.6 will be an update
    docker: ---> Package glibc-common.x86_64 0:2.17-260.el7_6.3 will be updated
    docker: ---> Package glibc-common.x86_64 0:2.17-260.el7_6.6 will be an update
    docker: ---> Package libblkid.x86_64 0:2.23.2-59.el7 will be updated
    docker: ---> Package libblkid.x86_64 0:2.23.2-59.el7_6.1 will be an update
    docker: ---> Package libgcc.x86_64 0:4.8.5-36.el7 will be updated
    docker: ---> Package libgcc.x86_64 0:4.8.5-36.el7_6.2 will be an update
    docker: ---> Package libmount.x86_64 0:2.23.2-59.el7 will be updated
    docker: ---> Package libmount.x86_64 0:2.23.2-59.el7_6.1 will be an update
    docker: ---> Package libsmartcols.x86_64 0:2.23.2-59.el7 will be updated
    docker: ---> Package libsmartcols.x86_64 0:2.23.2-59.el7_6.1 will be an update
    docker: ---> Package libssh2.x86_64 0:1.4.3-12.el7 will be updated
    docker: ---> Package libssh2.x86_64 0:1.4.3-12.el7_6.2 will be an update
    docker: ---> Package libstdc++.x86_64 0:4.8.5-36.el7 will be updated
    docker: ---> Package libstdc++.x86_64 0:4.8.5-36.el7_6.2 will be an update
    docker: ---> Package libuuid.x86_64 0:2.23.2-59.el7 will be updated
    docker: ---> Package libuuid.x86_64 0:2.23.2-59.el7_6.1 will be an update
    docker: ---> Package nss-pem.x86_64 0:1.0.3-5.el7 will be updated
    docker: ---> Package nss-pem.x86_64 0:1.0.3-5.el7_6.1 will be an update
    docker: ---> Package openssl-libs.x86_64 1:1.0.2k-16.el7 will be updated
    docker: ---> Package openssl-libs.x86_64 1:1.0.2k-16.el7_6.1 will be an update
    docker: ---> Package puppet5-release.noarch 0:5.0.0-4.el7 will be updated
    docker: ---> Package puppet5-release.noarch 0:5.0.0-7.el7 will be an update
    docker: ---> Package python.x86_64 0:2.7.5-76.el7 will be updated
    docker: ---> Package python.x86_64 0:2.7.5-80.el7_6 will be an update
    docker: ---> Package python-libs.x86_64 0:2.7.5-76.el7 will be updated
    docker: ---> Package python-libs.x86_64 0:2.7.5-80.el7_6 will be an update
    docker: ---> Package shadow-utils.x86_64 2:4.1.5.1-25.el7 will be updated
    docker: ---> Package shadow-utils.x86_64 2:4.1.5.1-25.el7_6.1 will be an update
    docker: ---> Package systemd.x86_64 0:219-62.el7_6.5 will be updated
    docker: ---> Package systemd.x86_64 0:219-62.el7_6.7 will be an update
    docker: ---> Package systemd-libs.x86_64 0:219-62.el7_6.5 will be updated
    docker: ---> Package systemd-libs.x86_64 0:219-62.el7_6.7 will be an update
    docker: ---> Package tzdata.noarch 0:2018i-1.el7 will be updated
    docker: ---> Package tzdata.noarch 0:2019b-1.el7 will be an update
    docker: ---> Package util-linux.x86_64 0:2.23.2-59.el7 will be updated
    docker: ---> Package util-linux.x86_64 0:2.23.2-59.el7_6.1 will be an update
    docker: ---> Package vim-minimal.x86_64 2:7.4.160-5.el7 will be updated
    docker: ---> Package vim-minimal.x86_64 2:7.4.160-6.el7_6 will be an update
    docker: --> Finished Dependency Resolution
    docker:
    docker: Dependencies Resolved
    docker:
    docker: ================================================================================
    docker:  Package                Arch       Version                    Repository   Size
    docker: ================================================================================
    docker: Updating:
    docker:  bind-license           noarch     32:9.9.4-74.el7_6.1        updates      87 k
    docker:  dbus                   x86_64     1:1.10.24-13.el7_6         updates     245 k
    docker:  dbus-libs              x86_64     1:1.10.24-13.el7_6         updates     169 k
    docker:  device-mapper          x86_64     7:1.02.149-10.el7_6.8      updates     293 k
    docker:  device-mapper-libs     x86_64     7:1.02.149-10.el7_6.8      updates     321 k
    docker:  glib2                  x86_64     2.56.1-4.el7_6             updates     2.5 M
    docker:  glibc                  x86_64     2.17-260.el7_6.6           updates     3.7 M
    docker:  glibc-common           x86_64     2.17-260.el7_6.6           updates      12 M
    docker:  libblkid               x86_64     2.23.2-59.el7_6.1          updates     181 k
    docker:  libgcc                 x86_64     4.8.5-36.el7_6.2           updates     102 k
    docker:  libmount               x86_64     2.23.2-59.el7_6.1          updates     182 k
    docker:  libsmartcols           x86_64     2.23.2-59.el7_6.1          updates     140 k
    docker:  libssh2                x86_64     1.4.3-12.el7_6.2           updates     135 k
    docker:  libstdc++              x86_64     4.8.5-36.el7_6.2           updates     305 k
    docker:  libuuid                x86_64     2.23.2-59.el7_6.1          updates      82 k
    docker:  nss-pem                x86_64     1.0.3-5.el7_6.1            updates      74 k
    docker:  openssl-libs           x86_64     1:1.0.2k-16.el7_6.1        updates     1.2 M
    docker:  puppet5-release        noarch     5.0.0-7.el7                puppet5     9.7 k
    docker:  python                 x86_64     2.7.5-80.el7_6             updates      95 k
    docker:  python-libs            x86_64     2.7.5-80.el7_6             updates     5.6 M
    docker:  shadow-utils           x86_64     2:4.1.5.1-25.el7_6.1       updates     1.1 M
    docker:  systemd                x86_64     219-62.el7_6.7             updates     5.1 M
    docker:  systemd-libs           x86_64     219-62.el7_6.7             updates     407 k
    docker:  tzdata                 noarch     2019b-1.el7                updates     491 k
    docker:  util-linux             x86_64     2.23.2-59.el7_6.1          updates     2.0 M
    docker:  vim-minimal            x86_64     2:7.4.160-6.el7_6          updates     437 k
    docker:
    docker: Transaction Summary
    docker: ================================================================================
    docker: Upgrade  26 Packages
    docker:
    docker: Total download size: 36 M
    docker: Downloading packages:
    docker: Delta RPMs disabled because /usr/bin/applydeltarpm not installed.
    docker: Public key for bind-license-9.9.4-74.el7_6.1.noarch.rpm is not installed
==> docker: warning: /var/cache/yum/x86_64/7/updates/packages/bind-license-9.9.4-74.el7_6.1.noarch.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
==> docker: warning: /var/cache/yum/x86_64/7/puppet5/packages/puppet5-release-5.0.0-7.el7.noarch.rpm: Header V4 RSA/SHA256 Signature, key ID ef8d349f: NOKEY
    docker: Public key for puppet5-release-5.0.0-7.el7.noarch.rpm is not installed
    docker: --------------------------------------------------------------------------------
    docker: Total                                              1.3 MB/s |  36 MB  00:28
    docker: Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rocky-7
==> docker: Importing GPG key 0xF4A80EB5:
==> docker:  Userid     : "rocky-7 Key (rocky 7 Official Signing Key) <security@rocky.org>"
==> docker:  Fingerprint: 6341 ab27 53d7 8a78 a7c2 7bb1 24c6 a8a7 f4a8 0eb5
==> docker:  Package    : rocky-release-7-6.1810.2.el7.rocky.x86_64 (@rocky)
==> docker:  From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-rocky-7
    docker: Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppet5-release
==> docker: Importing GPG key 0xEF8D349F:
==> docker:  Userid     : "Puppet, Inc. Release Key (Puppet, Inc. Release Key) <release@puppet.com>"
==> docker:  Fingerprint: 6f6b 1550 9cf8 e59e 6e46 9f32 7f43 8280 ef8d 349f
==> docker:  Package    : puppet5-release-5.0.0-4.el7.noarch (installed)
==> docker:  From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-puppet5-release
    docker: Running transaction check
    docker: Running transaction test
    docker: Transaction test succeeded
    docker: Running transaction
==> docker: Warning: RPMDB altered outside of yum.
    docker:   Updating   : libgcc-4.8.5-36.el7_6.2.x86_64                              1/52
    ...
    docker:   vim-minimal.x86_64 2:7.4.160-6.el7_6
    docker:
    docker: Complete!
    docker: Loaded plugins: fastestmirror, ovl
    docker: Loading mirror speeds from cached hostfile
    docker:  * base: mirror.wdc1.us.leaseweb.net
    docker:  * extras: ftpmirror.your.org
    docker:  * updates: mirrors.umflint.edu
    docker: No packages marked for update
    docker: Loaded plugins: fastestmirror, ovl
    docker: Loading mirror speeds from cached hostfile
    docker:  * base: mirror.wdc1.us.leaseweb.net
    docker:  * extras: ftpmirror.your.org
    docker:  * updates: mirrors.umflint.edu
    docker: Resolving Dependencies
    docker: --> Running transaction check
    docker: ---> Package puppet-agent.x86_64 0:5.5.16-1.el7 will be installed
    docker: --> Finished Dependency Resolution
    docker:
    docker: Dependencies Resolved
    docker:
    docker: ================================================================================
    docker:  Package              Arch           Version              Repository       Size
    docker: ================================================================================
    docker: Installing:
    docker:  puppet-agent         x86_64         5.5.16-1.el7         puppet5          20 M
    docker:
    docker: Transaction Summary
    docker: ================================================================================
    docker: Install  1 Package
    docker:
    docker:
    docker: Total download size: 20 M
    docker: Installed size: 88 M
    docker: Downloading packages:
    docker: Running transaction check
    docker: Running transaction test
    docker: Transaction test succeeded
    docker: Running transaction
    docker:   Installing : puppet-agent-5.5.16-1.el7.x86_64                             1/1
    docker:   Verifying  : puppet-agent-5.5.16-1.el7.x86_64                             1/1
    docker:
    docker: Installed:
    docker:   puppet-agent.x86_64 0:5.5.16-1.el7
    docker:
    docker: Complete!
    docker: Loaded plugins: fastestmirror, ovl
    docker: Cleaning repos: base extras puppet5 updates
    docker: Cleaning up list of fastest mirrors
==> docker: Provisioning with Puppet...
    docker: Creating Puppet staging directory...
    docker: Creating directory: /tmp/packer-puppet-masterless
    docker: Uploading local modules from: modules
    docker: Creating directory: /tmp/packer-puppet-masterless/module-0
    docker: Uploading manifests...
    docker: Creating directory: /tmp/packer-puppet-masterless/manifests
    docker: Uploading manifest file from: manifests/default.pp
    docker: Running Puppet: cd /tmp/packer-puppet-masterless && FACTER_packer_build_name='docker' FACTER_packer_builder_type='docker' /opt/puppetlabs/bin/puppet
 apply --detailed-exitcodes --modulepath='/tmp/packer-puppet-masterless/module-0' /tmp/packer-puppet-masterless/manifests/default.pp
    docker: Notice: Compiled catalog for 2e2f36c777b8 in environment production in 0.23 seconds
    docker: Notice: /Stage[main]/Splunk::User/Group[splunk]/ensure: created
    docker: Notice: /Stage[main]/Splunk::User/User[splunk]/ensure: created
    docker: Notice: /Stage[main]/Splunk::Install/Exec[splunkDir]/returns: executed successfully
    docker: Notice: /Stage[main]/Splunk::Install/Splunk::Fetch[sourcefile]/Exec[retrieve_splunk-7.2.5.1-962d9a8e1586-Linux-x86_64.tgz]/returns: executed success
fully
    docker: Notice: /Stage[main]/Splunk::Install/Splunk::Fetch[sourcefile]/File[/opt/splunk-7.2.5.1-962d9a8e1586-Linux-x86_64.tgz]/owner: owner changed 'root' t
o 'splunk'
    docker: Notice: /Stage[main]/Splunk::Install/Splunk::Fetch[sourcefile]/File[/opt/splunk-7.2.5.1-962d9a8e1586-Linux-x86_64.tgz]/group: group changed 'root' t
o 'splunk'
    docker: Notice: /Stage[main]/Splunk::Install/Splunk::Fetch[sourcefile]/File[/opt/splunk-7.2.5.1-962d9a8e1586-Linux-x86_64.tgz]/mode: mode changed '0644' to
'0750'
    docker: Notice: /Stage[main]/Splunk::Install/Exec[unpackSplunk]/returns: executed successfully
    docker: Notice: /Stage[main]/Splunk::Install/Exec[unpackSplunk]: Triggered 'refresh' from 6 events
    docker: Notice: /Stage[main]/Splunk::Install/File[/opt/splunk/etc/splunk-launch.conf]/ensure: defined content as '{md5}a5db94512e8dc2b28067254467fe3dae'
    docker: Notice: /Stage[main]/Splunk::Install/Exec[serviceStart]: Triggered 'refresh' from 2 events
    docker: Notice: /Stage[main]/Splunk::Install/Exec[installSplunkService]/returns: executed successfully
    docker: Notice: /Stage[main]/Splunk::Install/Exec[installSplunkService]: Triggered 'refresh' from 2 events
    docker: Notice: /Stage[main]/Splunk::Config/File[/.bashrc.custom]/ensure: defined content as '{md5}e78f942e9ba51f9e8a7f17f6a6de6a9d'
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/inputs.d]/ensure: created
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/inputs.d/000_default]/ensure: defined content as '{md5}4d4b142a9d8f1111c07fc2d
4de77be83'
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/inputs.d/000_splunkssl]/ensure: defined content as '{md5}58c2b06e9f64e16cc3917
7f8ece41edb'
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/server.d]/ensure: created
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/server.d/000_header]/ensure: defined content as '{md5}e6f65802a60245b2fe75fc09
a21f91e4'
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/server.d/001_license]/ensure: defined content as '{md5}21167b8fa00b2bbeaacdb24
ef5af21bc'
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/server.d/998_ssl]/ensure: defined content as '{md5}fba52b7978dfaed864d0e89f8cbe40ce'
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/server.d/999_default]/ensure: defined content as '{md5}cd770876b927658aa3fc72cb0e80c012'
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/web.conf]/ensure: defined content as '{md5}834a662efe4ec9e75f00d5213976a0f0'
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/default-mode.conf]/ensure: defined content as '{md5}87b615075ae249c1ca42d45f69fbac22'
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/alert_actions.conf]/ensure: defined content as '{md5}cdf63a9176a1ef4a58b1d7516
1bd30e4'
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/ui-prefs.conf]/ensure: defined content as '{md5}7a9a4fbb183114b455494971991eff
3d'
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/limits.conf]/ensure: defined content as '{md5}34e17e330387d15cd05ed087986532e7
'
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/server.d/996_shclustering]/ensure: defined content as '{md5}2228e977ebea8966e2
7929f43e39cb67'
    docker: Notice: /Stage[main]/Splunk::Config/File[/opt/splunk/etc/system/local/server.d/995_replication]/ensure: defined content as '{md5}68b329da9893e34099c
7d8ad5cb9c940'
    docker: Notice: /Stage[main]/Splunk::Service/File[/etc/systemd/system/multi-user.target.wants/splunk.service]/ensure: defined content as '{md5}ed8b0bbcad368
225a0de2b4a24056a92'
    docker: Notice: /Stage[main]/Splunk/Exec[update-inputs]: Triggered 'refresh' from 2 events
    docker: Notice: /Stage[main]/Splunk/Exec[update-server]: Triggered 'refresh' from 5 events
    docker: Notice: /Stage[main]/Splunk::Service/Service[splunk]: Triggered 'refresh' from 8 events
    docker: Notice: Applied catalog in 270.75 seconds
==> docker: Exporting the container
==> docker: Killing the container: 4a2e0aa65733cb08bb1a2a7e0a91301695224921a97080ab26aaf9917069a29d
==> docker: Running post-processor: docker-import
    docker (docker-import): Importing image: Container
    docker (docker-import): Repository: cudgel/splunk:0.1
    docker (docker-import): Imported ID: sha256:a5c175345d7052a8ce332c310fe2413b078ada97fd6e6ee3142e4e88bf09e6f2
Build 'docker' finished.

==> Builds finished. The artifacts of successful builds are:
--> docker: Imported Docker image: cudgel/splunk:0.1
[vagrant@c7 dockersplunk]$
```
