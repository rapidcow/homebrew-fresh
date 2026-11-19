require_relative "../lib/git_subtree_download_strategy"

class SiteconfL10nZh < Formula
  desc "Chinese message catalog for siteconf"
  homepage "https://foss.rapidcow.org/project/siteconf/"
  url "https://github.com/rapidcow/siteconf.git",
      using:   GitSubtreeDownloadStrategy,
      tag:     "siteconf-l10n/v0.00_00",
      subtree: "siteconf-l10n"
  version "0.00.00"
  sha256 "37db2a4beb164004179e98ca404d28792882ef01476e17934d5b838505c119d0"
  license "GPL-3.0-only"

  depends_on "gettext" => [:build, :test]
  depends_on "rapidcow/fresh/siteconf-l10n"
  depends_on "rapidcow/fresh/textdomain"

  def install
    system "msgfmt", "--check", "-o", "siteconf.mo", "po/zh.po"
    (share/"locale/zh/LC_MESSAGES").install "siteconf.mo"
  end

  test do
    catalog = share/"locale/zh/LC_MESSAGES/siteconf.mo"
    assert_match "Language: zh", shell_output("#{formula_opt_bin("gettext")}/msgunfmt #{catalog}")
  end
end
