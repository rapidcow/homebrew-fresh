require_relative "../lib/git_subtree_download_strategy"

class Gengenlib < Formula
  desc "Perl generation utilities and Template Toolkit dependency provider"
  homepage "https://foss.rapidcow.org/project/siteconf/"
  url "https://github.com/rapidcow/siteconf.git",
      using:   GitSubtreeDownloadStrategy,
      tag:     "gengenlib/v0.01_00",
      subtree: "gengenlib"
  version "0.01.00"
  sha256 "53addfadfad2a9a4412f583fc2202adc049e167a8b9569056a0a3b5a9ae7e58c"
  license "GPL-3.0-only"

  depends_on "perl"
  depends_on "rapidcow/fresh/codesets"
  depends_on "rapidcow/fresh/textdomain"

  resource "AppConfig" do
    url "https://cpan.metacpan.org/authors/id/N/NE/NEILB/AppConfig-1.71.tar.gz"
    sha256 "1177027025ecb09ee64d9f9f255615c04db5e14f7536c344af632032eb887b0f"
  end

  resource "Template-Toolkit" do
    url "https://cpan.metacpan.org/authors/id/T/TO/TODDR/Template-Toolkit-3.106.tar.gz"
    sha256 "c7474050be80201f1fb55f0a569b9c0ab6c1c3f0cebbd7e601bda9b4046eec85"
  end

  resource "template-provider" do
    url "https://github.com/rapidcow/siteconf.git",
        using:   GitSubtreeDownloadStrategy,
        tag:     "template-provider/v0.00_00",
        subtree: "template-provider"
    version "0.00.00"
    sha256 "3631d13ba6361200906269be295f209c22ac23c5f03ed1c445d85520fa551b60"
  end

  def install
    ENV.delete "PERL_MM_OPT"
    ENV.delete "PERL_MB_OPT"
    ENV["PERL_MM_USE_DEFAULT"] = "1"

    # Make freshly installed resources visible before Homebrew links the keg.
    perl_version = Formula["perl"].version.major_minor
    ENV.prepend_path "PERL5LIB", lib/"perl5/vendor_perl"/perl_version

    resources.reject { |r| r.name == "template-provider" }.each do |r|
      r.stage do
        args = ["INSTALLDIRS=vendor", "PREFIX=#{prefix}"]
        args += ["TT_ACCEPT=y", "TT_XS_ENABLE=n"] if r.name == "Template-Toolkit"
        system "perl", "Makefile.PL", *args
        system "make", "install"
      end
    end

    system "perl", "Makefile.PL", "INSTALLDIRS=vendor", "PREFIX=#{prefix}"
    system "make"
    system "make", "test"
    system "make", "install"

    resource("template-provider").stage do
      system "perl", "Makefile.PL", "INSTALLDIRS=vendor", "PREFIX=#{prefix}"
      system "make"
      system "make", "test"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.pl").write <<~'PERL'
      use RdKw::WwW::GenGenLib qw(read_make);
      use RdKw::WwW::GenGenLib::Template::Provider;
      use Template;
      my $output;
      Template->new->process(\'Hello [% name %]', {name => 'Homebrew'}, \$output)
          or die Template->error;
      print $output;
    PERL
    assert_equal "Hello Homebrew", shell_output("#{formula_opt_bin("perl")}/perl test.pl")
  end
end
