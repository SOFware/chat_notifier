# frozen_string_literal: true

module ChatNotifier
  # Groups test failures by file and packs them into reasonably sized
  # batches suitable for posting as individual Slack thread replies.
  class FailureGroups
    def initialize(failures, group_size: 10, char_limit: 3000)
      @failures = failures
      @group_size = group_size
      @char_limit = char_limit
    end

    attr_reader :failures, :group_size, :char_limit

    # One rendered string per thread reply: file blocks packed into batches
    # bounded by group_size (file count) and char_limit (rendered length).
    def reply_texts
      batches.map { |blocks| blocks.join("\n") }
    end

    private

    def batches
      file_blocks.each_with_object([]) do |block, packed|
        current = packed.last
        if current.nil? ||
            current.size >= group_size ||
            (current.join("\n").length + 1 + block.length) > char_limit
          packed << [block]
        else
          current << block
        end
      end
    end

    # Render each file (with its failing lines) into a text block.
    def file_blocks
      by_file.map do |file, lines|
        bullets = lines.map { |line| "  • #{File.basename(file)}:#{line}" }
        ([file] + bullets).join("\n")
      end
    end

    # { "path/to/file.rb" => ["42", "88"], ... } preserving first-seen order.
    def by_file
      failures.each_with_object({}) do |failure, groups|
        file, line = normalize(failure.location)
        (groups[file] ||= []) << line
      end
    end

    # RSpec locations are "path:line" strings; Minitest locations are
    # [file, line] arrays. Normalize both to [file, line].
    def normalize(location)
      if location.is_a?(Array)
        [location[0], location[1]]
      else
        file, _, line = location.to_s.rpartition(":")
        [file, line]
      end
    end
  end
end
