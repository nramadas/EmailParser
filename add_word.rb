module EmailParser
  require 'tempfile'
  require 'fileutils'

  class Word
    def self.find(word)
      word = word.split("")

      currentNode = find_root(word.shift.downcase)

      while letter = word.shift
        begin
          currentNode = find_child_from_node(letter.downcase, currentNode)
        rescue
          return "Word not found"
        end
      end

      line = grab_line(currentNode[:line_number])
      line.chomp.split(", ")[1].split("|")
    end


    def self.add(word, filename)
      word = word.split("")

      currentNode = find_root(word.shift.downcase)

      while letter = word.shift
        currentNode = return_child_from_node(letter.downcase, currentNode, filename)
      end
    end

    def self.find_root(letter)
      file = File.open(TREE_MAP_FILE, 'r')

      line_number = 0
      file.each_line do |line|
        line = line.chomp.split(", ")

        if line[0] == letter
          return { value: line[0], line_number: line_number, children: line[1..-1] }
        elsif line_number > 25
          raise "Root not found"
        end

        line_number += 1
      end

      raise "Root not found"
    end

    def self.grab_line(target_line_number)
      file = File.open(TREE_MAP_FILE, 'r')

      line_number = 0
      file.each_line do |line|
        return line if line_number == target_line_number
        line_number += 1
      end

      raise "Could not find line"
    end

    def self.parse_line(line, line_number)
      temp = line.chomp.split(", ")
      { value: temp[0], line_number: line_number, children: temp[2..-1] }
    end

    def self.find_child_from_node(letter, node)
      child = node[:children].select {|c| c[0] == letter }[0]

      if child
        line_number = child[1..-1].to_i
        line = grab_line(line_number)
        parse_line(line, line_number)
      else
        raise "Child not found"
      end
    end

    def self.return_child_from_node(letter, node, filename)
      child = node[:children].select {|c| c[0] == letter }[0]

      if child
        line_number = child[1..-1].to_i
        line = grab_line(line_number)
        add_file_to_line(line_number, filename)
        parse_line(line, line_number)
      else
        return create_child(node[:line_number], letter, filename)
      end
    end

    def self.create_child(parent_line_number, letter, filename)
      child = add_child_to_end(letter, filename)
      update_parent(parent_line_number, child[:line_number], letter)

      child
    end

    def self.add_child_to_end(letter, filename)
      tempfile = Tempfile.new("temp")
      line_number = 0

      begin
        file = File.open(TREE_MAP_FILE, 'r')

        file.each_line do |line|
          tempfile.puts line
          line_number += 1
        end

        tempfile.puts "#{letter}, |#{filename}"
        tempfile.rewind
        FileUtils.mv(tempfile.path, TREE_MAP_FILE)
      ensure
        tempfile.close
        tempfile.unlink
      end

      { value: letter, line_number: line_number, children: [] }
    end

    def self.add_file_to_line(target_line_number, filename)
      tempfile = Tempfile.new("temp")
      line_number = 0

      begin
        file = File.open(TREE_MAP_FILE, 'r')

        file.each_line do |line|
          if line_number == target_line_number
            line_array = line.chomp.split(", ")
            line_array[1] << "|#{filename}" unless line_array[1].include?(filename)
            tempfile.puts line_array.join(", ")
          else
            tempfile.puts line
          end

          line_number += 1
        end

        tempfile.rewind
        FileUtils.mv(tempfile.path, TREE_MAP_FILE)
      ensure
        tempfile.close
        tempfile.unlink
      end
    end

    def self.update_parent(parent_line_number, child_line_number, letter)
      tempfile = Tempfile.new("temp")
      line_number = 0

      begin
        file = File.open(TREE_MAP_FILE, 'r')

        file.each_line do |line|
          if line_number == parent_line_number
            tempfile.puts line.chomp + ", #{letter}#{child_line_number}"
          else
            tempfile.puts line
          end

          line_number += 1
        end

        tempfile.rewind
        FileUtils.mv(tempfile.path, TREE_MAP_FILE)
      ensure
        tempfile.close
        tempfile.unlink
      end
    end
  end
end