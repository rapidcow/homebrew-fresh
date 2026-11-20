# typed: strict
# frozen_string_literal: true

# Run with: brew ruby test/git_subtree_download_strategy.rb
require "resource"
require "rubygems/package"
require "time"
require "zlib"
require_relative "../lib/git_subtree_download_strategy"

dates = { "GIT_AUTHOR_DATE" => "2001-02-03T04:05:06+02:00", "GIT_COMMITTER_DATE" => "2002-03-04T05:06:07Z" }
git = lambda do |repo, *args|
  system(dates, "git", "-C", repo.to_s, *args, out: File::NULL) || raise("git failed: #{args.inspect}")
end

Dir.mktmpdir("git-subtree-test-") do |directory|
  root = Pathname(directory)
  repo = root/"repo"
  repo.mkpath
  git.call(repo, "init", "--quiet")
  git.call(repo, "config", "user.name", "Archive test")
  git.call(repo, "config", "user.email", "archive@example.invalid")
  (repo/"package").mkpath
  (repo/"package/source.txt").write("original\n")
  (repo/"unrelated.txt").write("first\n")
  git.call(repo, "add", ".")
  git.call(repo, "commit", "--quiet", "-m", "initial")
  git.call(repo, "tag", "-a", "package/v1", "-m", "package release")

  resource = Resource.new("subtree-test")
  resource.url repo.to_s, using: GitSubtreeDownloadStrategy, tag: "package/v1", subtree: "package",
               cache: root/"cache"
  resource.version "1"
  resource.downloader.fetch
  archive = resource.cached_download
  expected_mtime = Time.iso8601(dates.fetch("GIT_AUTHOR_DATE")).to_i
  Zlib::GzipReader.open(archive) do |gzip|
    Gem::Package::TarReader.new(gzip) do |tar|
      tar.each do |entry|
        raise "entry does not use author date" if entry.header.mtime != expected_mtime
      end
    end
  end
  resource.sha256 Digest::SHA256.file(archive).hexdigest
  resource.verify_download_integrity(archive)

  # A new commit and committer date preserve the hash when the author date and subtree stay the same.
  (repo/"unrelated.txt").write("second\n")
  dates["GIT_COMMITTER_DATE"] = "2003-04-05T06:07:08Z"
  git.call(repo, "add", ".")
  git.call(repo, "commit", "--quiet", "-m", "unrelated change")
  git.call(repo, "tag", "--force", "package/v1")
  resource.downloader.clear_cache
  resource.downloader.fetch
  resource.verify_download_integrity(resource.cached_download)

  reject_changed_archive = lambda do
    resource.downloader.clear_cache
    resource.downloader.fetch
    begin
      resource.verify_download_integrity(resource.cached_download)
    rescue ChecksumMismatchError
      next
    end
    raise "changed archive passed checksum verification"
  end

  # The author date is part of the archive even when package content is unchanged.
  dates["GIT_AUTHOR_DATE"] = "2004-05-06T07:08:09Z"
  git.call(repo, "commit", "--quiet", "--allow-empty", "-m", "author date change")
  git.call(repo, "tag", "--force", "package/v1")
  reject_changed_archive.call
  resource.sha256 Digest::SHA256.file(resource.cached_download).hexdigest

  # Changed package content must also fail verification when its author date stays the same.
  (repo/"package/source.txt").write("changed\n")
  git.call(repo, "add", ".")
  git.call(repo, "commit", "--quiet", "-m", "package change")
  git.call(repo, "tag", "--force", "package/v1")
  reject_changed_archive.call
  puts "PASS: archives use the author date; changed author dates or package content fail SHA-256"
end
