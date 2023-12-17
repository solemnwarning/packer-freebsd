packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = "~> 1"
    }
    vmware = {
      source  = "github.com/hashicorp/vmware"
      version = "~> 1"
    }
  }
}

variable "output_dir" {
  type    = string
  default = "output"
}

variable "output_name" {
  type    = string
  default = "freebsd-14"
}

variable "boot_wait" {
  type    = string
  default = "60s"
}

variable "disk_size" {
  type    = string
  default = "16384"
}

variable "headless" {
  type    = string
  default = "true"
}

variable "iso_checksum" {
  type    = string
  default = "7200214030125877561e70718781b435b703180c12575966ad1c7584a3e60dc6"
}

variable "iso_url" {
  type    = string
  default = "http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/ISO-IMAGES/14.0/FreeBSD-14.0-RELEASE-amd64-disc1.iso"
}

variable "shutdown_command" {
  type    = string
  default = "shutdown -p now"
}

variable "ssh_password" {
  type    = string
  default = "packer"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "ssh_wait_timeout" {
  type    = string
  default = "1000s"
}

source "qemu" "freebsd" {
  boot_command      = ["<right><enter><wait>", "dhclient -p /tmp/dhclient.pid -l /tmp/dhclient.lease vtnet0<enter><wait5>", "fetch -o /tmp/installerconfig http://{{ .HTTPIP }}:{{ .HTTPPort }}/installerconfig<enter><wait>", "bsdinstall script /tmp/installerconfig; shutdown -r now<enter>"]
  boot_wait         = "${var.boot_wait}"
  disk_size         = "${var.disk_size}"
  headless          = "${var.headless}"
  http_directory    = "http"
  iso_checksum      = "${var.iso_checksum}"
  iso_url           = "${var.iso_url}"
  shutdown_command  = "${var.shutdown_command}"
  ssh_password      = "${var.ssh_password}"
  ssh_username      = "${var.ssh_username}"
  ssh_wait_timeout  = "${var.ssh_wait_timeout}"

  # Builds a compact image
  disk_compression   = true
  disk_discard       = "unmap"
  skip_compaction    = false
  disk_detect_zeroes = "unmap"

  format           = "qcow2"
  output_directory = "${var.output_dir}"
  vm_name          = "${var.output_name}.qcow2"
}

source "virtualbox-iso" "freebsd" {
  boot_command      = ["<right><enter><wait>", "dhclient -p /tmp/dhclient.pid -l /tmp/dhclient.lease em0<enter><wait5>", "fetch -o /tmp/installerconfig http://{{ .HTTPIP }}:{{ .HTTPPort }}/installerconfig<enter><wait>", "bsdinstall script /tmp/installerconfig; shutdown -r now<enter>"]
  boot_wait         = "${var.boot_wait}"
  disk_size         = "${var.disk_size}"
  guest_os_type     = "FreeBSD_64"
  headless          = "${var.headless}"
  http_directory    = "http"
  iso_checksum      = "${var.iso_checksum}"
  iso_url           = "${var.iso_url}"
  shutdown_command  = "${var.shutdown_command}"
  ssh_password      = "${var.ssh_password}"
  ssh_username      = "${var.ssh_username}"
  ssh_wait_timeout  = "${var.ssh_wait_timeout}"
  vm_name           = "${var.output_name}"
}

source "vmware-iso" "freebsd" {
  boot_command      = ["<right><enter><wait>", "dhclient -p /tmp/dhclient.pid -l /tmp/dhclient.lease em0<enter><wait5>", "fetch -o /tmp/installerconfig http://{{ .HTTPIP }}:{{ .HTTPPort }}/installerconfig<enter><wait>", "bsdinstall script /tmp/installerconfig; shutdown -r now<enter>"]
  boot_wait         = "${var.boot_wait}"
  disk_size         = "${var.disk_size}"
  guest_os_type     = "freebsd-64"
  headless          = "${var.headless}"
  http_directory    = "http"
  iso_checksum      = "${var.iso_checksum}"
  iso_url           = "${var.iso_url}"
  shutdown_command  = "${var.shutdown_command}"
  ssh_password      = "${var.ssh_password}"
  ssh_username      = "${var.ssh_username}"
  ssh_wait_timeout  = "${var.ssh_wait_timeout}"
  vm_name           = "${var.output_name}"
}

build {
  name = "base"

  sources = [
    "source.qemu.freebsd",
    "source.virtualbox-iso.freebsd",
    "source.vmware-iso.freebsd",
  ]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; /bin/sh -c '{{ .Vars }} {{ .Path }}'"
    scripts         = ["scripts/base.sh"]
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; /bin/sh -c '{{ .Vars }} {{ .Path }}'"
    only            = ["virtualbox-iso", "vmware-iso"]
    script          = "scripts/vmguest.sh"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; /bin/sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "scripts/cleanup.sh"
  }

  post-processor "shell-local" {
    keep_input_artifact = true
    inline = [
      "cd ${var.output_dir}/",
      "sha256sum * > SHA256SUMS",
    ]
  }
}

build {
  name = "vagrant"

  sources = [
    "source.qemu.freebsd",
    "source.virtualbox-iso.freebsd",
    "source.vmware-iso.freebsd",
  ]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; /bin/sh -c '{{ .Vars }} {{ .Path }}'"
    scripts         = ["scripts/base.sh", "scripts/vagrant.sh"]
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; /bin/sh -c '{{ .Vars }} {{ .Path }}'"
    only            = ["virtualbox-iso", "vmware-iso"]
    script          = "scripts/vmguest.sh"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; /bin/sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "scripts/cleanup.sh"
  }

  post-processors {
    post-processor "vagrant" {
      keep_input_artifact  = false
      vagrantfile_template = "vagrantfile.template"
    }

    # post-processor "atlas" {
    #   artifact      = "${var.atlas_username}/${var.output_name}"
    #   artifact_type = "vagrant.box"
    #   metadata = {
    #     provider = "vmware_desktop"
    #     version  = "${var.version}"
    #   }
    #   only = ["vmware-iso"]
    # }
    # post-processor "atlas" {
    #   artifact      = "${var.atlas_username}/${var.output_name}"
    #   artifact_type = "vagrant.box"
    #   metadata = {
    #     provider = "libvirt"
    #     version  = "${var.version}"
    #   }
    #   only = ["qemu"]
    # }
    # post-processor "atlas" {
    #   artifact      = "${var.atlas_username}/${var.output_name}"
    #   artifact_type = "vagrant.box"
    #   metadata = {
    #     provider = "virtualbox"
    #     version  = "${var.version}"
    #   }
    #   only = ["virtualbox-iso"]
    # }
  }
}
