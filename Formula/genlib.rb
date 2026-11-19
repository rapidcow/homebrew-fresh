require_relative "../lib/git_subtree_download_strategy"

class Genlib < Formula
  desc "Perl static website generation utilities"
  homepage "https://foss.rapidcow.org/project/siteconf/"
  url "https://github.com/rapidcow/siteconf.git",
      using:   GitSubtreeDownloadStrategy,
      tag:     "genlib/v0.03_00",
      subtree: "genlib"
  version "0.03.00"
  sha256 "f702bd8477b1afd547801a805161cb53f4764106456e91966be0cf5c50ca5d6e"
  license "GPL-3.0-only"

  depends_on "perl"
  depends_on "rapidcow/fresh/codesets"
  depends_on "rapidcow/fresh/textdomain"

  resource "MIME-Base32" do
    url "https://cpan.metacpan.org/authors/id/R/RE/REHSACK/MIME-Base32-1.303.tar.gz"
    sha256 "ab21fa99130e33a0aff6cdb596f647e5e565d207d634ba2ef06bdbef50424e99"
  end

  resource "URI" do
    url "https://cpan.metacpan.org/authors/id/O/OA/OALDERS/URI-5.40.tar.gz"
    sha256 "ef5d2ef099a1a24a6e83ffe543de73337805d3d39c00b84fa205d725ad1a1b63"
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
    system formula_opt_bin("perl")/"perl", "-MRdKw::WwW::GenLib=file2uri", "-e",
           "die unless file2uri('hello world.html') eq 'hello%20world.html'"
  end
end
