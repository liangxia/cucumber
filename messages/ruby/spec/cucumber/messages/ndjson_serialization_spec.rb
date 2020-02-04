require 'cucumber/messages'

module Cucumber
  module Messages
    describe Messages do

      it "json-roundtrips messages with bytes fields" do
        a1 = Attachment.new(binary: [1,2,3,4].pack('C*'))
        expect(a1.binary.length).to eq(4)
        a2 = Attachment.new(JSON.parse(a1.to_json))
        expect(a2).to(eq(a1))
      end

      it "omits empty string fields in output" do
        io = StringIO.new
        message = Envelope.new(source: Source.new(data: ''))
        message.write_ndjson_to(io)

        io.rewind
        json = io.read

        expect(json).to eq("{\"source\":{}}\n")
      end

      it "can be serialised over an ndjson stream" do
        outgoing_messages = [
          Envelope.new(source: Source.new(data: 'Feature: Hello')),
          Envelope.new(attachment: Attachment.new(binary: [1,2,3,4].pack('C*')))
        ]

        io = StringIO.new
        write_outgoing_messages(outgoing_messages, io)

        io.rewind
        incoming_messages = NdjsonToMessageEnumerator.new(io)

        expect(incoming_messages.to_a).to(eq(outgoing_messages))
      end

      it "marshals int64 as strings" do
        message = Cucumber::Messages::Envelope.new(
          test_run_started: Cucumber::Messages::TestRunStarted.new(
            timestamp: Cucumber::Messages::Timestamp.new(
              seconds: 10,
              nanos: 123
            )
          )
        )

        io = StringIO.new
        message.write_ndjson_to(io)

        io.rewind
        json = io.read

        expect(json).to eq('{"testRunStarted":{"timestamp":{"seconds":"10","nanos":123}}}'+"\n")
      end

      def write_outgoing_messages(messages, out)
        messages.each do |message|
          message.write_ndjson_to(out)
        end
      end
    end
  end
end
