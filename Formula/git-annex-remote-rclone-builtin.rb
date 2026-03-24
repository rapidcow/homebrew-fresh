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
      When invoked under this name, rclone implements the git\\-annex external
      special remote protocol over standard input and output, allowing
      .BR git\\-annex (1)
      to store and retrieve content on any rclone\\-supported backend.
      .PP
      git\\-annex 10.20240430 and later can invoke rclone directly using
      .BR type=rclone ,
      without needing this symlink.
      Older versions require
      .B type=external externaltype=rclone\\-builtin
      and the symlink on
      .BR $PATH .
      .PP
      In normal use this program is invoked by git\\-annex automatically
      and should not be run directly.
      .SH CONFIGURATION
      Parameters are supplied to
      .B git annex initremote
      or
      .BR "git annex enableremote" .
      .TP
      .B rcloneremotename
      Name of the rclone remote as configured in
      .IR rclone.conf " (see " "rclone config" ")."
      .TP
      .B rcloneprefix
      Path prefix within the remote under which content is stored.
      .TP
      .B rclonelayout
      Directory layout for stored objects.
      One of
      .BR nodir ", " lower ", " directory ", or " mixed .
      .B lower
      is recommended for new remotes.
      .TP
      .B encryption
      git\\-annex encryption mode, e.g.\\&
      .BR none ", " shared ", or " pubkey .
      .TP
      .B chunk
      Optional chunk size for splitting large files, e.g.\\&
      .BR 50MiB .
      .SH EXAMPLES
      Create a remote using git\\-annex 10.20240430 or later:
      .PP
      .RS
      .nf
      git annex initremote MyRemote type=rclone encryption=none \\\\
          rcloneremotename=SomeRcloneRemote \\\\
          rcloneprefix=git\\-annex\\-content rclonelayout=lower
      .fi
      .RE
      .PP
      Create a remote using an older git\\-annex (requires this symlink):
      .PP
      .RS
      .nf
      git annex initremote MyRemote type=external externaltype=rclone\\-builtin \\\\
          encryption=none rcloneremotename=SomeRcloneRemote \\\\
          rcloneprefix=git\\-annex\\-content rclonelayout=lower
      .fi
      .RE
      .SH DIFFERENCES FROM git-annex-remote-rclone
      The original
      .I git\\-annex\\-remote\\-rclone
      shell script uses different parameter names:
      .TP
      .B target
      Renamed to
      .BR rcloneremotename .
      .TP
      .B prefix
      Renamed to
      .BR rcloneprefix .
      .TP
      .B rclone_layout
      Renamed to
      .BR rclonelayout .
      .TP
      .B externaltype=rclone
      Renamed to
      .BR externaltype=rclone\\-builtin .
      .PP
      Note that
      .B git\\-annex\\-remote\\-rclone\\-builtin
      can reuse an existing remote's configuration verbatim if its parameter
      names are compatible; check with
      .BR "git annex initremote \\-\\-whatelse" .
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
