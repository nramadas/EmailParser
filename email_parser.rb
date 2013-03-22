require_relative "./add_word"

module EmailParser
  TREE_MAP_FILE = "treemap"

  class Directory
    def self.parse(pathname)
      set_up_tree_map_file

      Dir.foreach(pathname) do |username_dir|
        next if username_dir[0] == "."

        Dir.foreach("#{pathname}/#{username_dir}") do |mail_dir|
          next unless mail_dir == "all_documents"

          Dir.foreach("#{pathname}/#{username_dir}/#{mail_dir}") do |file|
            next if file[0] == "."

            puts "#{pathname}/#{username_dir}/#{mail_dir}/#{file}"
            Email.parse("#{pathname}/#{username_dir}/#{mail_dir}/#{file}")
          end
        end
      end
    end

    def self.set_up_tree_map_file
      f = File.open(TREE_MAP_FILE, 'w')
      ('a'..'z').to_a.each do |letter|
        f.puts letter
      end
      f.close
    end
  end

  class Email
    def self.parse(file)
      puts "parsing... #{file}"
      f = File.open(file)
      f.read.split(" ").each do |word|
        begin
          Word.add(word, file)
        rescue ArgumentError
          next
        rescue RuntimeError
          next
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV[2] && ARGV[2] == "true"
    EmailParser::Directory.set_up_tree_map_file
    EmailParser::Directory.parse(ARGV[0])
    puts EmailParser::Word.find(ARGV[1])
  else
    puts EmailParser::Word.find(ARGV[1])
  end
end