{pkgs, ...}: {
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;

    config = {
      confirmation = false;
      recurrence = {
        enabled = "yes";
        confirmation = false;
      };

      report.minimal = {
        filter = "status:pending";
        columns = "id,project,tags,start.age,description";
        labels = "ID,Project,Tags,Started,Description";
        sort = "project+,description+";
      };

      report.next = {
        filter = "status:pending limit:20";
        columns = "id,start.age,entry.age,project,tags,recur,wait.remaining,scheduled,urgency,due,description";
        labels = "ID,Active,Age,Project,Tag,Recur,Wait,Sched,Urg,Due,Description";
        sort = "urgency-";
      };

      report.agent = {
        filter = "status:pending +agent limit:50";
        columns = "id,source,start.age,description";
        labels = "ID,Source,Active,Description";
        sort = "entry+";
      };

      uda.source.type = "string";
      uda.source.label = "Source";

      sync.server.url = "https://tasks.home.lan";
    };

    extraConfig = ''
      # TaskChampion sync client ID and encryption secret
      # Generate per-device: uuidgen
      # sync.server.client_id = <your-uuid-here>
      # sync.encryption_secret = <your-secret-here>
    '';
  };
}
