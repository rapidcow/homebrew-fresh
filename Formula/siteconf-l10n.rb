require_relative "../lib/git_subtree_download_strategy"

class SiteconfL10n < Formula
  desc "Perl locale directory configuration for siteconf"
  homepage "https://foss.rapidcow.org/project/siteconf/"
  url "https://github.com/rapidcow/siteconf.git",
      using:   GitSubtreeDownloadStrategy,
      tag:     "siteconf-l10n/v0.00_00",
      subtree: "siteconf-l10n"
  version "0.00.00"
  sha256 "de81c9d73b8d5146da800df7472b13748c288055de07b7536b3cd287016f4b9f"
  license "GPL-3.0-only"

  depends_on "perl"

  resource "File-Which" do
    url "https://cpan.metacpan.org/authors/id/P/PL/PLICEASE/File-Which-1.27.tar.gz"
    sha256 "3201f1a60e3f16484082e6045c896842261fc345de9fb2e620fd2a2c7af3a93a"
  end

  def install
    ENV.delete "PERL_MM_OPT"
    ENV.delete "PERL_MB_OPT"

    resource("File-Which").stage buildpath/"build-deps/file-which"
    ENV.prepend_path "PERL5LIB", buildpath/"build-deps/file-which/lib"

    system "perl", "Makefile.PL", "INSTALLDIRS=vendor", "PREFIX=#{prefix}",
           "LOCALEDIR=#{HOMEBREW_PREFIX}/share/locale"
    system "make"
    system "make", "test", "TEST_FILES=t/00-load.t"
    system "make", "install"
  end

  test do
    assert_equal "#{HOMEBREW_PREFIX}/share/locale",
                 shell_output("#{formula_opt_bin("perl")}/perl -Mversion " \
                              "-MRdKw::WwW::SiteConf::L10N " \
                              "-e 'print $RdKw::WwW::SiteConf::L10N::LOCALEDIR'")
  end
end
