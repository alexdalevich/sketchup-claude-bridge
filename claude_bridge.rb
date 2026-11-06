# SketchUp terminal bridge
#
# Lets you (or an AI agent such as Claude Code) run Ruby inside a running SketchUp
# from the terminal. Every 0.5 s SketchUp checks a folder for `cmd.rb`, evaluates it,
# deletes it and writes the result (or the error with backtrace) to `out.txt`.
#
# Start SketchUp with this file as a startup script (macOS):
#   open -a "SketchUp 2026" model.skp --args -RubyStartup /path/to/claude_bridge.rb
# or load it from the Ruby Console:
#   load '/path/to/claude_bridge.rb'
#
# Folder: $SKETCHUP_BRIDGE_DIR or ~/.sketchup-bridge
#
# SECURITY: any code placed in cmd.rb is executed with SketchUp's permissions.
# The bridge only lives until SketchUp quits. Stop it with ClaudeBridge.stop.

module ClaudeBridge
  DIR = File.expand_path(ENV['SKETCHUP_BRIDGE_DIR'] || '~/.sketchup-bridge')
  CMD = File.join(DIR, 'cmd.rb')
  OUT = File.join(DIR, 'out.txt')
  INTERVAL = 0.5

  def self.tick
    return unless File.exist?(CMD)

    code = File.read(CMD, encoding: 'UTF-8')
    File.delete(CMD)
    result = begin
      'OK: ' + TOPLEVEL_BINDING.eval(code, 'cmd.rb').inspect[0, 20_000]
    rescue Exception => e # rubocop:disable Lint/RescueException
      "ERROR: #{e.class}: #{e.message}\n" + Array(e.backtrace).first(15).join("\n")
    end
    # atomic write so the client never reads a half-written file
    File.write(OUT + '.tmp', result)
    File.rename(OUT + '.tmp', OUT)
  end

  def self.start
    Dir.mkdir(DIR, 0o700) unless Dir.exist?(DIR)
    stop
    @timer = UI.start_timer(INTERVAL, true) do
      tick
    rescue Exception => e # rubocop:disable Lint/RescueException
      puts "ClaudeBridge: #{e.message}"
    end
    puts "ClaudeBridge listening in #{DIR}"
  end

  def self.stop
    UI.stop_timer(@timer) if @timer
    @timer = nil
  end
end

ClaudeBridge.start
