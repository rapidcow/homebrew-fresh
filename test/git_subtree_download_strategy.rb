# typed: strict
# frozen_string_literal: true

# Run with: brew ruby test/git_subtree_download_strategy.rb
require "resource"
require_relative "../lib/git_subtree_download_strategy"

git = lambda do |repo, *args|
  system("git", "-C", repo.to_s, *args, out: File::NULL) || raise("git failed: #{args.inspect}")
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
  git.call(repo, "tag", "package/v1")

  resource = Resource.new("subtree-test")
  resource.url repo.to_s, using: GitSubtreeDownloadStrategy, tag: "package/v1", subtree: "package",
               cache: root/"cache"
  resource.version "1"
  resource.downloader.fetch
  archive = resource.cached_download
  checksum = Digest::SHA256.file(archive).hexdigest
  resource.sha256 checksum
  resource.verify_download_integrity(archive)

  # Retagging a different commit with the same package must preserve the hash.
  (repo/"unrelated.txt").write("second\n")
  git.call(repo, "add", ".")
  git.call(repo, "commit", "--quiet", "-m", "unrelated change")
  git.call(repo, "tag", "--force", "package/v1")
  resource.downloader.clear_cache
  sleep 1 # A tree archive without --mtime would now have a different timestamp.
  resource.downloader.fetch
  resource.verify_download_integrity(resource.cached_download)

  # A package change under that same tag must fail SHA-256 verification.
  (repo/"package/source.txt").write("changed\n")
  git.call(repo, "add", ".")
  git.call(repo, "commit", "--quiet", "-m", "package change")
  git.call(repo, "tag", "--force", "package/v1")
  resource.downloader.clear_cache
  resource.downloader.fetch
  begin
    resource.verify_download_integrity(resource.cached_download)
  rescue ChecksumMismatchError
    puts "PASS: unchanged subtree survives retagging; changed subtree fails SHA-256"
  else
    raise "changed subtree passed checksum verification"
  end
end
