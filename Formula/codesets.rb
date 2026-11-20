require_relative "../lib/git_subtree_download_strategy"

class Codesets < Formula
  desc "Perl character encoding contexts and argument parsing"
  homepage "https://foss.rapidcow.org/project/siteconf/"
  url "https://github.com/rapidcow/siteconf.git",
      using:   GitSubtreeDownloadStrategy,
      tag:     "codesets/v0.00_00",
      subtree: "codesets"
  version "0.00.00"
  sha256 "e1459599da77413f51debd54866745ffb607d237607696d7430abae9a7bc7159"
  license "GPL-3.0-only"

  depends_on "perl"

  resource "Encode-Locale" do
    url "https://cpan.metacpan.org/authors/id/G/GA/GAAS/Encode-Locale-1.05.tar.gz"
    sha256 "176fa02771f542a4efb1dbc2a4c928e8f4391bf4078473bd6040d8f11adb0ec1"
  end

  def install
    ENV.delete "PERL_MM_OPT"
    ENV.delete "PERL_MB_OPT"
    ENV["PERL_MM_USE_DEFAULT"] = "1"

    # Make freshly installed resources visible before Homebrew links the keg.
    perl_version = Formula["perl"].version.major_minor
    ENV.prepend_path "PERL5LIB", lib/"perl5/vendor_perl"/perl_version

    resources.each do |r|
      r.stage do
        args = ["INSTALLDIRS=vendor", "PREFIX=#{prefix}"]
        system "perl", "Makefile.PL", *args
        system "make", "install"
      end
    end

    system "perl", "Makefile.PL", "INSTALLDIRS=vendor", "PREFIX=#{prefix}"
    system "make"
    system "make", "test"
    system "make", "install"
  end

  test do
    system formula_opt_bin("perl")/"perl", "-MRdKw::I18N::CodeSets", "-e",
           "die unless RdKw::I18N::CodeSets->new->to_fs('hello') eq 'hello'"
  end
end
