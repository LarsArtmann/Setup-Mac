{
  MemoryMax ? "512M",
  ProtectSystem ? "strict",
  ProtectHome ? true,
  ReadWritePaths ? [],
  CapabilityBoundingSet ? "",
  ...
}: {
  PrivateTmp = true;
  NoNewPrivileges = true;
  inherit CapabilityBoundingSet;
  ProtectClock = true;
  ProtectHostname = true;
  ProtectKernelLogs = true;
  RestrictNamespaces = true;
  RestrictSUIDSGID = true;
  LockPersonality = true;
  inherit ProtectSystem ProtectHome MemoryMax ReadWritePaths;
}
