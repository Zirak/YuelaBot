module Commands
  class ListKeys
    class << self
      def name
        :list_keys
      end

      def attributes
        {
            usage: 'list_keys',
            description: "List available keys to claim",
            aliases: [:lk]
        }
      end

      def command(event)
        if event.server.nil?
          return "Initiate this command in a server"
        end
        keys = GameKey.where(server: event.server.id)
        if keys.empty?
          event.respond "No keys are available"
        else
          response = StringIO.new
          response.puts "The following games are available:"
          response.puts '```'
          response.printf "%-5s %s\n", "ID", "Name"
          keys.each do |k|
            response.printf "(%03d) %s\n", k.id, k.name
          end
          response.puts '```'
          response.puts "You can claim any of these games with !!claim <id>"
          event.respond response.string
        end
      end
    end
  end
end