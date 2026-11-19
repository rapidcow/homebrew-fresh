require_relative "../lib/git_subtree_download_strategy"

class Siteconf < Formula
  desc "Configurable incremental build script generator"
  homepage "https://foss.rapidcow.org/project/siteconf/"
  url "https://git.rapidcow.org/pub/project/siteconf.git",
      using:   GitSubtreeDownloadStrategy,
      tag:     "siteconf/v0.03_00",
      subtree: "siteconf"
  version "0.03.00"
  sha256 "9e27e1830e7266dafa37e0cc84466a7c52d7c7a84d7a23c90dd00123044ab8b4"
  license "GPL-3.0-only"

  depends_on "perl"
  depends_on "rapidcow/fresh/codesets"
  depends_on "rapidcow/fresh/gengenlib"
  depends_on "rapidcow/fresh/genlib"
  depends_on "rapidcow/fresh/textdomain"

  resource "File-ShareDir-Install" do
    url "https://cpan.metacpan.org/authors/id/E/ET/ETHER/File-ShareDir-Install-0.14.tar.gz"
    sha256 "8f9533b198f2d4a9a5288cbc7d224f7679ad05a7a8573745599789428bc5aea0"
  end

  resource "Class-Inspector" do
    url "https://cpan.metacpan.org/authors/id/P/PL/PLICEASE/Class-Inspector-1.36.tar.gz"
    sha256 "cc295d23a472687c24489d58226ead23b9fdc2588e522f0b5f0747741700694e"
  end

  resource "File-ShareDir" do
    url "https://cpan.metacpan.org/authors/id/R/RE/REHSACK/File-ShareDir-1.118.tar.gz"
    sha256 "3bb2a20ba35df958dc0a4f2306fc05d903d8b8c4de3c8beefce17739d281c958"
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
    (testpath/"html/index.html").write <<~HTML
      [% # HAVE: ${A}/${a}/index.html
      -%]
      Hello [% O.site_url %]
    HTML
    (testpath/"Makefile.in").write <<~MAKE
      index.html: ${A}/render
      	cd -- ${A:Q} && ${^X} render -B ${B:Q} ${a}/${.TARGET} ${B:Q}/${b}/${.TARGET}
    MAKE
    (testpath/"MANIFEST").write "MAKE all\n\tNEED index.html\n"
    system bin/"siteconf", "-i", "-P", "web", "-Osite_url=https://example.org"
    assert_path_exists testpath/"configure"
    assert_path_exists testpath/"render"
    system "./configure"
    system bin/"siteconf", "-g"
    system "make"
    assert_equal "Hello https://example.org\n", (testpath/"site/index.html").read
  end
end
