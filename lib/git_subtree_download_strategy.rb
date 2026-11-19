# typed: strict
# frozen_string_literal: true

require "download_strategy"
require "tmpdir"

# Fetch a movable package tag, then let Homebrew verify the subtree archive's
# SHA-256. Commit IDs and commit timestamps are deliberately absent from it.
class GitSubtreeDownloadStrategy < AbstractFileDownloadStrategy
  sig { override.returns(Pathname) }
  def cached_location
    identity = [url, meta.fetch(:tag), meta.fetch(:subtree)].join("\n")
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
          system_command! "git",
                          args:    ["-C", repo, "-c", "tar.umask=0002",
                                    "-c", "tar.tar.gz.command=git archive gzip",
                                    "archive", "--format=tar.gz", "--mtime=1970-01-01T00:00:00Z",
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
