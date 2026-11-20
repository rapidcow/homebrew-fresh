# typed: strict
# frozen_string_literal: true

require "download_strategy"
require "tmpdir"

# Fetch a movable package tag, then let Homebrew verify the subtree archive's
# SHA-256. Entries use the tagged commit's strict ISO author date (%aI).
class GitSubtreeDownloadStrategy < AbstractFileDownloadStrategy
  sig { override.returns(Pathname) }
  def cached_location
    identity = ["author-date-v1", url, meta.fetch(:tag), meta.fetch(:subtree)].join("\n")
    key = Digest::SHA256.hexdigest(identity)
    cache/"downloads/#{key}--#{name}-#{version}.tar.gz"
  end

  sig { override.params(timeout: T.nilable(T.any(Float, Integer))).void }
  def fetch(timeout: nil)
    lock = DownloadLock.new(temporary_path)
    lock.lock_or_wait(quiet: quiet?, timeout: timeout)
    begin
      unless cached_location.exist?
        cached_location.dirname.mkpath
        Dir.mktmpdir("homebrew-git-subtree-") do |directory|
          repo = Pathname(directory)/"source.git"
          system_command! "git", args: ["init", "--bare", repo], timeout: timeout
          system_command! "git",
                          args:    ["-C", repo, "fetch", "--no-tags", url,
                                    "refs/tags/#{meta.fetch(:tag)}:refs/tags/package"],
                          timeout: timeout
          author_date = system_command!("git",
                                        args:    ["-C", repo, "show", "-s", "--format=%aI",
                                                  "refs/tags/package^{commit}"],
                                        timeout: timeout).stdout.strip
          system_command! "git",
                          args:    ["-C", repo, "-c", "tar.umask=0002",
                                    "-c", "tar.tar.gz.command=git archive gzip",
                                    "archive", "--format=tar.gz", "--mtime=#{author_date}",
                                    "--output=#{temporary_path}",
                                    "refs/tags/package:#{meta.fetch(:subtree)}"],
                          timeout: timeout
        end
        temporary_path.rename(cached_location)
      end
      create_symlink_to_cached_download(cached_location)
    ensure
      lock.unlock(unlink: true)
    end
  end
end
