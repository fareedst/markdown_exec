# frozen_string_literal: true

# encoding=utf-8

class StreamsOut
  attr_accessor :streams

  def initialize
    @streams = []
  end

  def append_stream_line(stream, line)
    @streams << OpenStruct.new(stream: stream, line: line, timestamp: Time.now)
  end

  def stream_lines(stream)
    @streams.select do |v|
      v[:stream] == stream
    end.map(&:line)
  end

  def write_execution_output_to_file(filespec)
    FileUtils.mkdir_p File.dirname(filespec)

    output = @streams.map do |entry|
      case entry[:stream]
      when ExecutionStreams::STD_OUT
        entry[:line]
        # "OUT: #{entry[:line]}"
      when ExecutionStreams::STD_ERR
        entry[:line]
        # "ERR: #{entry[:line]}"
      when ExecutionStreams::STD_IN
        entry[:line]
        # " IN: #{entry[:line]}"
      end
    end.join("\n")

    File.write(filespec, output)
  end
end
