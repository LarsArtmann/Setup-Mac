//go:build linux

package main

import (
	"golang.org/x/sys/unix"
)

type sockaddrNl struct {
	Family uint16
	Pad    uint16
	Port   uint32
	Groups uint32
}

func unixOpenNetlinkKobjectUevent() (int, error) {
	fd, err := unix.Socket(unix.AF_NETLINK, unix.SOCK_RAW|unix.SOCK_NONBLOCK, unix.NETLINK_KOBJECT_UEVENT)
	if err != nil {
		return -1, err
	}

	sa := &unix.SockaddrNetlink{
		Groups: 1,
	}
	if bindErr := unix.Bind(fd, sa); bindErr != nil {
		_ = unix.Close(fd)

		return -1, bindErr
	}

	return fd, nil
}
