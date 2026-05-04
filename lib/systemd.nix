{lib}: {
  MemoryMax ? "512M",
  ProtectSystem ? "full",
  ProtectHome ? true,
  ReadWritePaths ? [],
  RestrictNamespaces ? true,
  NoNewPrivileges ? true,
  CapabilityBoundingSet ? "",
  ...
}: let
  isOverride = v: builtins.isAttrs v && v ? _type && v._type == "override";
  mkDefault' = v:
    if isOverride v
    then v
    else lib.mkDefault v;
in {
  PrivateTmp = lib.mkDefault true;
  ProtectClock = lib.mkDefault true;
  ProtectHostname = lib.mkDefault true;
  ProtectKernelLogs = lib.mkDefault true;
  RestrictSUIDSGID = lib.mkDefault true;
  LockPersonality = lib.mkDefault true;
  ProtectSystem = mkDefault' ProtectSystem;
  ProtectHome = mkDefault' ProtectHome;
  MemoryMax = mkDefault' MemoryMax;
  ReadWritePaths = mkDefault' ReadWritePaths;
  RestrictNamespaces = mkDefault' RestrictNamespaces;
  NoNewPrivileges = mkDefault' NoNewPrivileges;
  CapabilityBoundingSet = mkDefault' CapabilityBoundingSet;
}
