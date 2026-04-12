{
  pkgs,
  lib,
  config,
  ...
}: let
  machineSeed = "${config.home.username}@${pkgs.stdenv.hostPlatform.system}";

  deriveUuid = seed: let
    h = builtins.hashString "sha256" "taskchampion-${seed}";
    p1 = lib.strings.substring 0 8 h;
    p2 = lib.strings.substring 8 4 h;
    p3 = lib.strings.substring 12 4 h;
    p4 = lib.strings.substring 16 4 h;
    p5 = lib.strings.substring 20 12 h;
  in "${p1}-${p2}-${p3}-${p4}-${p5}";

  syncEncryptionSecret = builtins.hashString "sha256" "taskchampion-sync-encryption-systemnix";
in {
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;

    config = {
      confirmation = false;
      recurrence = {
        enabled = "yes";
        confirmation = false;
      };

      report = {
        minimal = {
          filter = "status:pending";
          columns = "id,project,tags,start.age,description";
          labels = "ID,Project,Tags,Started,Description";
          sort = "project+,description+";
        };

        next = {
          filter = "status:pending limit:20";
          columns = "id,start.age,entry.age,project,tags,recur,wait.remaining,scheduled,urgency,due,description";
          labels = "ID,Active,Age,Project,Tag,Recur,Wait,Sched,Urg,Due,Description";
          sort = "urgency-";
        };

        agent = {
          filter = "status:pending +agent limit:50";
          columns = "id,source,start.age,description";
          labels = "ID,Source,Active,Description";
          sort = "entry+";
        };
      };

      uda.source.type = "string";
      uda.source.label = "Source";

      sync = {
        server = {
          url = "https://tasks.home.lan";
          client_id = deriveUuid machineSeed;
        };
        encryption_secret = syncEncryptionSecret;
      };
    };

    extraConfig = ''
      # Catppuccin Mocha color theme
      color.title=on color0
      color.header=on color0
      color.footnote=on color0
      color.message=on color0
      color.error=on color0
      color.debug=on color0

      color.overdue=rgbF38
      color.due.today=rgbF9E
      color.due=rgbF9E
      color.scheduled=rgbA6E
      color.active=rgbB4B
      color.recurring=rgbCBA
      color.blocked=rgbF38
      color.blocking=rgbFAB

      color.tagged=on rgb313
      color.tag.none=
      color.project.none=

      color.uda.priority.H=rgbF38
      color.uda.priority.M=rgbF9E
      color.uda.priority.L=rgbA6E

      color.summary.background=on rgb1E1
      color.summary.bar=on rgb89B
      color.history.add=rgbA6E
      color.history.done=rgbA6E
      color.history.delete=rgbF38

      color.burndown.pending=rgb89B
      color.burndown.done=rgbA6E
      color.burndown.started=rgbFAB

      color.sync.added=rgbA6E
      color.sync.changed=rgbF9E
      color.sync.rejected=rgbF38

      color.calendar.today=rgb111 on rgbF9E
      color.calendar.due=rgb111 on rgbF38
      color.calendar.overdue=rgb111 on rgbF38
      color.calendar.weekend=rgb6C7
      color.calendar.holiday=rgbCBA

      color.report.minimal.filter=on rgb454
      color.report.next.filter=on rgb454
      color.report.agent.filter=on rgb454

      color.alternate=on rgb313
    '';
  };
}
