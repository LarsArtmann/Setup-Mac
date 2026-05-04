{lib, ...}: {
  MemoryMax ? "512M",
  ProtectSystem ? "full",
  ProtectHome ? true,
  ReadWritePaths ? [],
  RestrictNamespaces ? true,
  NoNewPrivileges ? true,
  CapabilityBoundingSet ? "",
  ...
}: {
  PrivateTmp = lib.mkDefault true;
  ProtectClock = lib.mkDefault true;
  ProtectHostname = lib.mkDefault true;
  ProtectKernelLogs = lib.mkDefault true;
  RestrictSUIDSGID = lib.mkDefault true;
  LockPersonality = lib.mkDefault true;
  ProtectSystem = lib.mkDefault ProtectSystem;
  ProtectHome = lib.mkDefault ProtectHome;
  MemoryMax = lib.mkDefault MemoryMax;
  ReadWritePaths = lib.mkDefault ReadWritePaths;
  RestrictNamespaces = lib.mkDefault RestrictNamespaces;
  NoNewPrivileges = lib.mkDefault NoNewPrivileges;
  CapabilityBoundingSet = lib.mkDefault CapabilityBoundingSet;
}
