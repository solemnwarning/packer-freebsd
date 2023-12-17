# packer-freebsd

Packer template to build FreeBSD (with zfsroot) images.

This is based on the [packer-freebsd](https://github.com/uchida/packer-freebsd) by [Akihiro Uchida](https://github.com/uchida).

## Building Images

To build images, simply run:

```console
$ git clone https://github.com/solemnwarning/packer-freebsd
$ cd packer-freebsd
$ packer init freebsd-14.pkr.hcl
$ packer build freebsd-14.pkr.hcl
```

If you want to build only virtualbox, vmware or qemu.

```console
# To build disk images for using directly with the hypervisor
$ packer build -only=base.virtualbox-iso.freebsd freebsd-14.pkr.hcl
$ packer build -only=base.vmware-iso.freebsd freebsd-14.pkr.hcl
$ packer build -only=base.qemu.freebsd freebsd-14.pkr.hcl

# To build "boxes" for use with Vagrant
$ packer build -only=vagrant.virtualbox-iso.freebsd freebsd-14.pkr.hcl
$ packer build -only=vagrant.vmware-iso.freebsd freebsd-14.pkr.hcl
$ packer build -only=vagrant.qemu.freebsd freebsd-14.pkr.hcl
```

## License

[![CC0](http://i.creativecommons.org/p/zero/1.0/88x31.png "CC0")](http://creativecommons.org/publicdomain/zero/1.0/deed)

dedicated to public domain, no rights reserved.
