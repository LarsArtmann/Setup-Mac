{
  lib,
  fetchurl,
  runCommand,
}: let
  # Parse hosts-format blocklist into list of domains (pure Nix)
  parseHostsText = text: let
    lines = lib.splitString "\n" text;
    parseLine = line: let
      trimmed = lib.trim line;
      # Skip comments and empty
      isComment = trimmed == "" || lib.hasPrefix "#" trimmed;
      # Split on whitespace
      parts = lib.filter (p: p != "") (lib.splitString " " (lib.replaceStrings ["\t"] [" "] trimmed));
      # Domain is second field (after IP like 0.0.0.0 or 127.0.0.1)
      domain =
        if builtins.length parts >= 2
        then lib.elemAt parts 1
        else null;
    in
      if isComment || domain == null
      then null
      else if domain == "localhost" || domain == "localhost.localdomain"
      then null
      else if lib.hasSuffix ".lan" domain
      then null
      else domain;
    domains = map parseLine lines;
  in
    lib.filter (d: d != null) domains;

  # Convert domains to unbound local-data format
  domainsToUnbound = domains: ip:
    lib.concatMapStringsSep "\n"
    (d: ''local-data: "${d} A ${ip}"'')
    domains;
in {
  inherit parseHostsText domainsToUnbound;

  # Fetch a hosts-format blocklist and convert to unbound include file
  mkBlocklist = {
    name,
    url,
    hash,
    blockIP ? "127.0.0.2",
  }: let
    raw = fetchurl {inherit url hash;};
    text = builtins.readFile raw;
    domains = parseHostsText text;
    unboundData = domainsToUnbound domains blockIP;
  in
    runCommand "${name}-unbound.conf" {} ''
      echo "# Blocklist: ${name}" >> $out
      echo "# Source: ${url}" >> $out
      echo "# Domains: ${toString (builtins.length domains)}" >> $out
      echo "" >> $out
      cat <<'EOF' >> $out
      ${unboundData}
      EOF
    '';

  # Combine multiple blocklists
  combineBlocklists = name: blocklists:
    runCommand "${name}-combined.conf" {} ''
      echo "# Combined DNS Blocklist" >> $out
      echo "# Blocklists: ${toString (builtins.length blocklists)}" >> $out
      echo "" >> $out
      ${lib.concatMapStrings (bl: "cat ${bl} >> $out\necho '' >> $out\n") blocklists}
    '';
}
