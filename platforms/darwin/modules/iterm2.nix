# iTerm2 Configuration Module
# Extracted from system.nix for modular architecture
_: {
  # iTerm2 configuration extracted from monolithic system.nix
  # This module contains the complete iTerm2 Status Bar Layout configuration
  # from lines 720-862 of system.nix

  # iTerm2 Status Bar Layout configuration
  home.file.".config/iterm2/com.googlecode.iterm2.plist".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Status Bar Layout</key>
      <dict>
        <key>components</key>
        <array>
          <dict>
            <key>class</key>
            <string>iTermStatusBarCPUUtilizationComponent</string>
            <key>configuration</key>
            <dict>
              <key>knobs</key>
              <dict>
                <key>base: priority</key>
                <integer>5</integer>
                <key>base: compression resistance</key>
                <integer>1</integer>
                <key>shared text color</key>
                <dict>
                  <key>Red Component</key>
                  <real>0.86000317335128784</real>
                  <key>Color Space</key>
                  <string>P3</string>
                  <key>Blue Component</key>
                  <real>0.63590961694717407</real>
                  <key>Alpha Component</key>
                  <integer>1</integer>
                  <key>Green Component</key>
                  <real>0.6414334774017334</real>
                </dict>
              </dict>
              <key>layout advanced configuration dictionary value</key>
              <dict>
                <key>auto-rainbow style</key>
                <integer>0</integer>
                <key>algorithm</key>
                <integer>0</integer>
                <key>remove empty components</key>
                <false/>
              </dict>
            </dict>
          </dict>
          <dict>
            <key>class</key>
            <string>iTermStatusBarMemoryUtilizationComponent</string>
            <key>configuration</key>
            <dict>
              <key>knobs</key>
              <dict>
                <key>base: priority</key>
                <integer>5</integer>
                <key>base: compression resistance</key>
                <integer>1</integer>
                <key>shared text color</key>
                <dict>
                  <key>Red Component</key>
                  <real>0.8796347975730896</real>
                  <key>Color Space</key>
                  <string>P3</string>
                  <key>Blue Component</key>
                  <real>0.65958398580551147</real>
                  <key>Alpha Component</key>
                  <integer>1</integer>
                  <key>Green Component</key>
                  <real>0.89919322729110718</real>
                </dict>
              </dict>
              <key>layout advanced configuration dictionary value</key>
              <dict>
                <key>auto-rainbow style</key>
                <integer>0</integer>
                <key>algorithm</key>
                <integer>0</integer>
                <key>remove empty components</key>
                <false/>
              </dict>
            </dict>
          </dict>
          <dict>
            <key>class</key>
            <string>iTermStatusBarNetworkUtilizationComponent</string>
            <key>configuration</key>
            <dict>
              <key>knobs</key>
              <dict>
                <key>base: priority</key>
                <integer>5</integer>
                <key>base: compression resistance</key>
                <integer>1</integer>
                <key>shared text color</key>
                <dict>
                  <key>Red Component</key>
                  <real>0.68831330537796021</real>
                  <key>Color Space</key>
                  <string>P3</string>
                  <key>Blue Component</key>
                  <real>0.69797295331954956</real>
                  <key>Alpha Component</key>
                  <integer>1</integer>
                  <key>Green Component</key>
                  <real>0.89270001649856567</real>
                </dict>
              </dict>
              <key>layout advanced configuration dictionary value</key>
              <dict>
                <key>auto-rainbow style</key>
                <integer>0</integer>
                <key>algorithm</key>
                <integer>0</integer>
                <key>remove empty components</key>
                <false/>
              </dict>
            </dict>
          </dict>
          <dict>
            <key>class</key>
            <string>iTermStatusBarGitComponent</string>
            <key>configuration</key>
            <dict>
              <key>knobs</key>
              <dict>
                <key>maxwidth</key>
                <real>1.7976931348623157e+308</real>
                <key>iTermStatusBarGitComponentPollingIntervalKey</key>
                <integer>2</integer>
                <key>base: priority</key>
                <integer>5</integer>
                <key>shared text color</key>
                <dict>
                  <key>Red Component</key>
                  <real>0.67023450136184692</real>
                  <key>Color Space</key>
                  <string>P3</string>
                  <key>Blue Component</key>
                  <real>0.89110654592514038</real>
                  <key>Alpha Component</key>
                  <integer>1</integer>
                  <key>Green Component</key>
                  <real>0.81993860006332397</real>
                </dict>
                <key>base: compression resistance</key>
                <integer>1</integer>
                <key>minwidth</key>
                <integer>0</integer>
              </dict>
              <key>layout advanced configuration dictionary value</key>
              <dict>
                <key>auto-rainbow style</key>
                <integer>0</integer>
                <key>algorithm</key>
                <integer>0</integer>
                <key>remove empty components</key>
                <false/>
              </dict>
            </dict>
          </dict>
          <dict>
            <key>class</key>
            <string>iTermStatusBarWorkingDirectoryComponent</string>
            <key>configuration</key>
            <dict>
              <key>knobs</key>
              <dict>
                <key>path</key>
                <string>path</string>
                <key>maxwidth</key>
                <real>1.7976931348623157e+308</real>
                <key>base: priority</key>
                <integer>5</integer>
                <key>shared text color</key>
                <dict>
                  <key>Red Component</key>
                  <real>0.71302109956741333</real>
                  <key>Color Space</key>
                  <string>P3</string>
                  <key>Blue Component</key>
                  <real>0.88136154413223267</real>
                  <key>Alpha Component</key>
                  <integer>1</integer>
                  <key>Green Component</key>
                  <real>0.63362252712249756</real>
                </dict>
                <key>base: compression resistance</key>
                <integer>1</integer>
                <key>minwidth</key>
                <integer>0</integer>
              </dict>
              <key>layout advanced configuration dictionary value</key>
              <dict>
                <key>auto-rainbow style</key>
                <integer>0</integer>
                <key>algorithm</key>
                <integer>0</integer>
                <key>remove empty components</key>
                <false/>
              </dict>
            </dict>
          </dict>
          <dict>
            <key>class</key>
            <string>iTermStatusBarClockComponent</string>
            <key>configuration</key>
            <dict>
              <key>knobs</key>
              <dict>
                <key>base: priority</key>
                <integer>5</integer>
                <key>shared text color</key>
                <dict>
                  <key>Red Component</key>
                  <real>0.86000508069992065</real>
                  <key>Color Space</key>
                  <string>P3</string>
                  <key>Blue Component</key>
                  <real>0.76881867647171021</real>
                  <key>Alpha Component</key>
                  <integer>1</integer>
                  <key>Green Component</key>
                  <real>0.64143049716949463</real>
                </dict>
                <key>base: compression resistance</key>
                <integer>1</integer>
                <key>format</key>
                <string>M/dd h:mm</string>
              </dict>
              <key>layout advanced configuration dictionary value</key>
              <dict>
                <key>auto-rainbow style</key>
                <integer>0</integer>
                <key>algorithm</key>
                <integer>0</integer>
                <key>remove empty components</key>
                <false/>
              </dict>
            </dict>
          </dict>
        </array>
        <key>advanced configuration</key>
        <dict>
          <key>remove empty components</key>
          <false/>
          <key>font</key>
          <string>.SFNS-Regular 12</string>
          <key>algorithm</key>
          <integer>0</integer>
          <key>auto-rainbow style</key>
          <integer>3</integer>
        </dict>
      </dict>
    </dict>
    </plist>
  '';
}
