class GitAnnexRemoteRcloneBuiltin < Formula
  desc "the rclone-builtin git-annex special remote"
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
    bin.install_symlink Formula["rclone"].opt_bin/"rclone" => "git-annex-remote-rclone-builtin"
  end

  test do
    # Matches protocol version string; e.g., "VERSION 1"
    assert_match(/\AVERSION \d+\n\z/,
                 IO.popen([bin/"git-annex-remote-rclone-builtin"], in: File::NULL, &:read))
  end
end
