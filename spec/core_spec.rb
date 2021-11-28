# Dummy
class View
  attr_accessor :top, :height
end

include EditorCore

RSpec.describe EditorCore::Core do

  let(:editor) {
    c = EditorCore::Core.new
    c.cursor = Cursor.new
    c.buffer = Buffer.new(1,"foo", [
        "class Editor < EditorCore::Core",
        "    include Search"
      ]
    )
    c.view = View.new
    c
  }

  describe "#next_word" do
    it "advances to the first non-A-Z character if it points to a word" do
      expect(editor.cursor.col).to eq(0)
      editor.next_word
      expect(editor.cursor.col).to eq(5)
      expect(editor.cursor.row).to eq(0)
    end


    it "it skips whitespace before it attempts to advance past the next word" do
      editor.move(0,5)
      editor.next_word
      expect(editor.cursor.col).to eq(12)
      expect(editor.cursor.row).to eq(0)
    end

    it "it skips non-AZ characters *and* whitespace before it attempts to advance" do
      editor.move(0,12)
      editor.next_word
      expect(editor.cursor.col).to eq(25)
      editor.next_word
      expect(editor.cursor.col).to eq(31)
      expect(editor.cursor.row).to eq(0)
    end
  end

  describe "#prev_word" do
    it "moves backwards to the first A-Z character if it points to a word" do
      editor.move(0,31)
      expect(editor.cursor.col).to eq(31)
      editor.prev_word
      expect(editor.cursor.col).to eq(27)
      expect(editor.cursor.row).to eq(0)
    end

    it "it skips non-AZ characters *and* whitespace before it attempts to move" do
      editor.move(0,27)
      editor.prev_word
      expect(editor.cursor.col).to eq(15)
      editor.prev_word
      expect(editor.cursor.col).to eq(6)
      expect(editor.cursor.row).to eq(0)
    end

    it "it skips whitespace before it attempts to move" do
      editor.move(0,6)
      editor.prev_word
      expect(editor.cursor.col).to eq(0)
      expect(editor.cursor.row).to eq(0)
    end

    it "moves to the first word on the preceeding line if no further words on current line" do
      editor.move(1,4)
      editor.prev_word
      expect(editor.cursor.col).to eq(27)
      expect(editor.cursor.row).to eq(0)
    end
  end
end
