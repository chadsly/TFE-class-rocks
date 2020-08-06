#!/bin/bash
echo "Hello World, ${name}"

readonly DOWNLOAD_PACKAGE_PATH="/tmp/guardian.zip"
readonly app_dest_path="/usr/local/bin"
readonly APP_PATH="tmp/guardian"
readonly APP_USER="guardian"

function fetch_binary {
  local download_url="$1"

  retry \
    "curl -L -u ${nexus_username}:'${nexus_password}' -o '$DOWNLOAD_PACKAGE_PATH' '$download_url' --location --fail --show-error" \
    "Downloading Guardian to $DOWNLOAD_PACKAGE_PATH by curl -L -u ${nexus_username}:'${nexus_password}' -o '$DOWNLOAD_PACKAGE_PATH' '$download_url' --location --fail --show-error" \
    5
}

function install_binary {
  local -r install_path="$1"
  local -r username="$2"
  local -r version="$3"

  unzip -d /tmp "$DOWNLOAD_PACKAGE_PATH"

  if $(has_apt_get); then
    sudo alien –i /tmp/$version/puppet/media/puppet-agent-5.5.19-1.el7.x86_64.rpm
  elif $(has_yum); then
    sudo yum install /tmp/$version/puppet/media/puppet-agent-5.5.19-1.el7.x86_64.rpm -y
  else
    #log_error "Could not find apt-get or yum. Cannot install dependencies on this OS."
    echo "ERROR: Could not find apt-get or yum. Cannot install dependencies on this OS."
    exit 1
  fi

  sudo chmod 0666 /etc/profile.d/puppet-agent.sh
  sudo echo "export PATH=/opt/puppetlabs/bin:$PATH" >> /etc/profile.d/puppet-agent.sh
  source /etc/profile.d/puppet-agent.sh
  #log_info "Checking Puppet version"
  echo "Checking Puppet version"
  #check puppet install
  puppet help

  #log_info "Unzip Guardian Puppet Modules"
  echo "Unzip Guardian Puppet Modules"
  sudo mkdir /$APP_PATH/puppet
  sudo tar -xf /tmp/$version/Guardian/guardian-puppet.tar.gz -C /$APP_PATH/puppet


  #install puppet modules
  #log_info "Applying Guardian Puppet Modules"
  echo "Applying Guardian Puppet Modules"
  su -l $APP_USER
  puppet apply /$APP_PATH/puppet/guardian-puppet/site/guardian/manifests/*

}

function retry {
  local -r cmd="$1"
  local -r description="$2"
  local -r max_tries="$3"

  for i in $(seq 1 $max_tries); do
    #log_info "$description"
    echo "$description"

    # The boolean operations with the exit status are there to temporarily circumvent the "set -e" at the
    # beginning of this script which exits the script immediatelly for error status while not losing the exit status code
    output=$(eval "$cmd") && exit_status=0 || exit_status=$?
    #log_info "$output"
    echo "$output"
    if [[ $exit_status -eq 0 ]]; then
      echo "$output"
      return
    fi
    #log_warn "$description failed. Will sleep for 10 seconds and try again."
    echo "WARNING: $description failed. Will sleep for 10 seconds and try again."
    sleep 10
  done;

  #log_error "ERROR: $description failed after $max_tries attempts."
  echo "ERROR: $description failed after $max_tries attempts."
  exit $exit_status
}

function has_yum {
  [ -n "$(command -v yum)" ]
}

function has_apt_get {
  [ -n "$(command -v apt-get)" ]
}

function install_dependencies {
  #log_info "Installing dependencies"
  echo "Installing dependencies"

  if $(has_apt_get); then
    sudo apt-get update -y
    sudo apt-get install -y awscli curl unzip jq alien
  elif $(has_yum); then
    sudo yum update -y
    sudo yum install -y aws curl unzip jq
  else
    #log_error "Could not find apt-get or yum. Cannot install dependencies on this OS."
    echo "Error: Could not find apt-get or yum. Cannot install dependencies on this OS."
    exit 1
  fi
}

function log_info {
  local -r message="$1"
  log "INFO" "$message"
}

function log_warn {
  local -r message="$1"
  log "WARN" "$message"
}

function log_error {
  local -r message="$1"
  log "ERROR" "$message"
}

function user_exists {
  local -r username="$1"
  id "$username" >/dev/null 2>&1
}

function create_user {
  local -r username="$1"

  if $(user_exists "$username"); then
    echo "User $username already exists. Will not create again."
  else
    #log_info "Creating user named $username"
    echo "Creating user named $username"
    sudo useradd "$username"
  fi
}

function create_install_paths {
  local -r path="$1"
  local -r username="$2"

  #log_info "Creating install dirs for Consul at $path"
  echo "Creating install dirs for $APP_USER at $path"
  sudo mkdir -p "$path"
  sudo mkdir -p "$path/bin"
  sudo mkdir -p "$path/config"
  sudo mkdir -p "$path/data"
  sudo mkdir -p "$path/tls/ca"

  #log_info "Changing ownership of $path to $username"
  echo "Changing ownership of $path to $username"
  sudo chown -R "$username:$username" "$path"
}

function main {
  #log_info "Set Proxies"
  echo "Set Proxies"
  # Set proxy address
  sudo echo "export http_proxy=${http_proxy}" > /etc/profile.d/http_proxy.sh
  sudo echo "export https_proxy=${http_proxy}" >> /etc/profile.d/http_proxy.sh
  sudo echo "export no_proxy=${no_proxy}" >> /etc/profile.d/http_proxy.sh
  sudo echo "export HTTP_PROXY=${http_proxy}" >> /etc/profile.d/http_proxy.sh
  sudo echo "export HTTPS_PROXY=${http_proxy}" >> /etc/profile.d/http_proxy.sh
  sudo echo "export NO_PROXY=${no_proxy}" >> /etc/profile.d/http_proxy.sh
  source /etc/profile.d/http_proxy.sh
  echo "Verying that the http_proxy is set as: $http_proxy"

  sudo mkdir /etc/apt
  echo 'Acquire::http::Proxy "${http_proxy}";' | sudo tee /etc/apt/apt.conf
  echo 'Acquire::https::Proxy "${http_proxy}";' | sudo tee -a /etc/apt/apt.conf

  #log_info "${nexus_username}"
  echo "Nexus username is: ${nexus_username}"

  #log_info "Starting Guardian install"
  echo "Starting Guardian install"
  sudo chmod 0666 /etc/yum.conf
  sudo echo "proxy=${http_proxy}" >> /etc/yum.conf
  install_dependencies
  create_user "$APP_USER"
  create_install_paths "$APP_PATH" "$APP_USER"

  fetch_binary "${app_download_url}"
  install_binary "$APP_PATH" "$APP_USER" "${app_version}"
  echo "The app is up after:"
  uptime -p
}

main $@