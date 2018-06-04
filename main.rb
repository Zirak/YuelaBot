gem 'json', '=1.8.6'

require 'discordrb'
require 'rbnacl/libsodium'
require 'google/apis/customsearch_v1'
require 'fourchan/kit'
require 'redd'
require 'require_all'
require 'data_mapper'
require 'csv'
require 'rufus-scheduler'

require_all './commands'
require_all './reactions'
require_all './models'
require_all './routines'

include Routines
DataMapper.setup(:default, "sqlite://#{Dir.home}/yuela")
DataMapper.repository(:default).adapter.select("PRAGMA synchronous=OFF")
DataMapper.repository(:default).adapter.select("PRAGMA journal_mode=WAL")
DataMapper::Model.raise_on_save_failure = true
DataMapper.finalize.auto_upgrade!


CONFIG = File.read('config').lines.each_with_object({}) do |l,o|
  parts = l.split('=')
  o[parts[0]] = parts[1].strip
end

BOT = Discordrb::Commands::CommandBot.new({
  token: CONFIG['discord'],
  prefix: '!!',
  advanced_functionality: true,
  chain_delimiter: '',
  chain_args_delim: '',
})

BOT.set_user_permission(CONFIG['admin_id'].to_i, 1)

Afk.all.destroy
UserCommand.all.each do |command|
  BOT.command(command.name.to_sym, &command.run)
end

Commands.constants.map do |c|
  command = Commands.const_get(c)
  command.is_a?(Class) ? command : nil
end.compact.each do |command|
  BOT.command(command.name, command.attributes, &command.command)
end

Reactions.constants.map do |r|
  reaction = Reactions.const_get(r)
  reaction.is_a?(Class) ? reaction : nil
end.compact.each do |reaction|
  BOT.message(reaction.attributes, &reaction.command)
end

BOT.message do |event|
  urs = UserReaction.all.find_all do |ur|
    Regexp.new(ur.regex).match event.message.content
  end
  urs.each { |ur| event.respond(ur.output) }

  user_ids = event.message.mentions.map(&:id)
  user_ids.each do |uid|
    user = User.get(uid)
    if user&.afk
      out = ''
      out << "#{user.name} is afk"
      out << ": #{user.afk.message}" if user.afk.message
      event << out
    end
  end
end

scheduler = Rufus::Scheduler.new

scheduler.every '1d', first: :now do
  birthday_routine(BOT)
end

BOT.run
