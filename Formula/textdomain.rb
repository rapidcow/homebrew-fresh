require_relative "../lib/git_subtree_download_strategy"

class Textdomain < Formula
  desc "Perl UTF-8 gettext text domains"
  homepage "https://foss.rapidcow.org/project/siteconf/"
  url "https://github.com/rapidcow/siteconf.git",
      using:   GitSubtreeDownloadStrategy,
      tag:     "textdomain/v0.00_00",
      subtree: "textdomain"
  version "0.00.00"
  sha256 "f81aee21141fb99cf3c9154658d92c7a8e69e78e9352bb81fc9f7e828a52b9ca"
  license "GPL-3.0-only"

  depends_on "gettext"
  depends_on "perl"

  resource "libintl-perl" do
    url "https://cpan.metacpan.org/authors/id/G/GU/GUIDO/libintl-perl-1.37.tar.gz"
    sha256 "a49b08d56813789e5f03289a3f949459eafe9e40a1a9fc066c42c90009a322cf"
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
    ENV["LC_ALL"] = "C"
    (testpath/"test.pl").write <<~PERL
      use RdKw::L10N::TextDomain 'homebrew-test';
      print __n('one item', 'many items', 2);
    PERL
    assert_equal "many items", shell_output("#{formula_opt_bin("perl")}/perl test.pl")
  end
end
