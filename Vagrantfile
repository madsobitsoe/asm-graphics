# -*- mode: ruby -*-
# vi: set ft=ruby :

# First we define two (multiline) strings, $script and $msg, to be
# used later

$script = <<-'SCRIPT'
set -xe
export DEBIAN_FRONTEND=noninteractive
apt-get -qq update
apt-get -qq upgrade -y
apt-get -qq install -y apt-transport-https ca-certificates curl \
        software-properties-common

# Install a few other packages
apt-get -qq install -y \
        nasm zip gdb strace binutils build-essential \
        flex bison \
        emacs-nox nano bash-completion git \
        curl wget gcc-multilib
SCRIPT

$msg = <<~MSG
------------------------------------------------------
The rASMycaster VM is ready

Get ssh access with the command
    vagrant ssh

The files in the current directory can be found
in the /vagrant directory
------------------------------------------------------
MSG

Vagrant.configure(2) do |config|

  # Every Vagrant virtual environment requires a box to build off
  # of. We build of Ubuntu 20.04 (Focal Fossa)
  config.vm.box = "ubuntu/focal64"


  config.vm.hostname = "rASMycaster"
  config.vm.network "forwarded_port", guest: 22, host: 2222,
                    host_ip: "127.0.0.1", id: 'ssh'
  config.vm.provider "virtualbox" do |vb|
    vb.name = "rASMycaster"
    vb.memory = "4096"
    vb.cpus = 2
    # Fix console
    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ["modifyvm", :id, "--uartmode1", "file", "./pcs-f2020_ttyS0.log"]
  end


  # Define the script: A shell script that runs after first
  # setup of your box (= provisioning). Here using the inline script defined in
  # the top of the file.

  # Install the some useful tools and compile demo.c
  config.vm.provision :shell, name: "Install tools", inline: $script

  # Add minimal .gdbinit
  config.vm.provision :shell, name: "Add minimal .gdbinit for the normal user",
                      privileged: false, inline: <<-'SHELL'
set -xe
cat <<'EOF' > .gdbinit
# Settings
set disassembly-flavor intel
set disable-randomization off
set pagination off
set follow-fork-mode child

# History
set history filename ~/.gdbhistory
set history save
set history expansion

# Output format
set output-radix 0x10
EOF
git clone https://github.com/longld/peda.git ~/peda
echo "source ~/peda/peda.py" >> ~/.gdbinit
SHELL

  config.vm.post_up_message = $msg

end
