# Homebrew Cask formula for MMetrics
# Hosted directly in the MMetrics repo — no separate tap repo needed.
#
# Install:
#   brew tap lollipopkit/mmetrics https://github.com/lollipopkit/mac-power-metric
#   brew install --cask mmetrics
#
# Upgrade (after a new GitHub Release is published):
#   brew upgrade --cask mmetrics

cask "mmetrics" do
  version "2.0.5"
  sha256 "750099ac6ac1d432bcde06a89494b637980de3ed54b5fc828abd03b59c6382a8"

  url "https://github.com/lollipopkit/mac-power-metric/releases/download/v#{version}/MMetrics-#{version}.dmg"
  name "MMetrics"
  desc "Real-time Apple Silicon system monitor — menu bar app and desktop widget"
  homepage "https://github.com/lollipopkit/mac-power-metric"

  # Apple Silicon only — M1 through M5+, macOS 13 Ventura and later
  depends_on macos: ">= :ventura"
  depends_on arch:  :arm64

  app "MMetrics.app"

  # Post-install: install the privileged helper that powers GPU, temps, and power rails.
  # The helper reads IOReport and SMC directly — no third-party tools required.
  postflight do
    helper_dir  = "/Users/Shared/MMetrics"
    helper_path = "#{helper_dir}/mmetrics-helper"

    # Only install if the helper isn't already present and working
    unless File.executable?(helper_path)
      system_command "/bin/mkdir", args: ["-p", helper_dir], sudo: true
      system_command "/bin/cp",
                     args: ["#{staged_path}/MMetrics.app/Contents/MacOS/mmetrics-helper", helper_path],
                     sudo: true
      system_command "/bin/chmod", args: ["755", helper_path], sudo: true
    end
  end

  # Uninstall: quit app and remove helper
  uninstall quit:   "com.lollipopkit.MMetrics",
            delete: "/Users/Shared/MMetrics/mmetrics-helper"

  zap trash: [
    "~/Library/Preferences/com.lollipopkit.MMetrics.plist",
    "~/Library/Application Support/MMetrics",
    "~/Library/Caches/com.lollipopkit.MMetrics",
    "/etc/sudoers.d/mmetrics-helper",
  ]
end
