class GitAnnexRemoteRcloneBuiltin < Formula
  desc "Git-annex rclone-builtin special remote"
  homepage "https://rclone.org/commands/rclone_gitannex/"
  # Pinned to v1.67.0, the release that introduced the gitannex command.
  # No need to update this as the formula just creates a symlink to rclone.
  url "https://raw.githubusercontent.com/rclone/rclone/v1.67.0/VERSION",
      using: :nounzip
  version "1.67.0"
  sha256 "cc46285dc2ea60c31e0702ea2347c5473deaa1cb1dd281158dcc841defafe87b"
  # Same as rclone itself.
  license "MIT"

  depends_on "rclone"

  def install
    (buildpath/"git-annex-remote-rclone-builtin.1").write <<~EOS
      .TH GIT\\-ANNEX\\-REMOTE\\-RCLONE\\-BUILTIN 1 "2024\\-06\\-14" "rclone #{version}" "User Commands"
      .SH NAME
      git\\-annex\\-remote\\-rclone\\-builtin \\- rclone\\-based git\\-annex external special remote
      .SH SYNOPSIS
      .B git\\-annex\\-remote\\-rclone\\-builtin
      .SH DESCRIPTION
      .B git\\-annex\\-remote\\-rclone\\-builtin
      is a symlink to
      .BR rclone (1).
      When invoked under this name, rclone acts as a git\\-annex external special remote,
      implementing the git\\-annex external special remote protocol over standard input
      and output.
      .PP
      This allows git\\-annex to store and retrieve content on any storage backend
      supported by rclone, without requiring a separate helper script.
      .PP
      In normal use this program is invoked by
      .BR git\\-annex (1)
      automatically and should not be run directly.
      .SH SEE ALSO
      .BR git\\-annex (1),
      .BR rclone (1)
    EOS
    man1.install "git-annex-remote-rclone-builtin.1"
    bin.install_symlink Formula["rclone"].opt_bin/"rclone" => "git-annex-remote-rclone-builtin"
  end

  test do
    # Matches protocol version string; e.g., "VERSION 1"
    assert_match(/\AVERSION \d+\n\z/,
                 IO.popen([bin/"git-annex-remote-rclone-builtin"], in: File::NULL, &:read))
  end
end
