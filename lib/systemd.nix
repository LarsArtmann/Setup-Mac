{
  MemoryMax ? "512M",
  ProtectSystem ? "full",
  ProtectHome ? true,
  ReadWritePaths ? [],
  RestrictNamespaces ? true,
  NoNewPrivileges ? true,
  CapabilityBoundingSet ? "",
  ...
}: {
  PrivateTmp = true;
  inherit CapabilityBoundingSet NoNewPrivileges;
  ProtectClock = true;
  ProtectHostname = true;
  ProtectKernelLogs = true;
  RestrictSUIDSGID = true;
  LockPersonality = true;
  inherit ProtectSystem ProtectHome MemoryMax ReadWritePaths RestrictNamespaces;
}
