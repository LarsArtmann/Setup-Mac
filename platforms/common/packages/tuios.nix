{
  pkgs,
  lib,
  fetchFromGitHub,
}:
pkgs.buildGoModule rec {
  pname = "tuios";
  version = "0.3.4";

  src = fetchFromGitHub {
    owner = "Gaurav-Gosain";
    repo = "tuios";
    rev = "v${version}";
    hash = "sha256-4lJ7e1JZvZzZvZvZvZvZvZvZvZvZvZvZvZvZvZvZvZvZ=";
  };

  vendorHash = "sha256-tu8GXE/wMq2i61gTlgdbfL38ehVppa/fz1WVXrsX+vk=";

  meta = with lib; {
    description = "Terminal UI Operating System (Terminal Multiplexer)";
    longDescription = ''
      TUIOS is a terminal-based window manager that provides a modern,
      efficient interface for managing multiple terminal sessions. Built
      with Go using the Charm stack (Bubble Tea v2 and Lipgloss v2),
      TUIOS offers a vim-like modal interface with comprehensive keyboard
      shortcuts, workspace support, and mouse interaction.
    '';
    homepage = "https://github.com/Gaurav-Gosain/tuios";
    license = licenses.mit;
    mainProgram = "tuios";
    platforms = platforms.unix;
    maintainers = with maintainers; [];
  };
}
