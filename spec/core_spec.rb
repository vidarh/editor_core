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
      expect(editor.cursor.row).to eq(0)
    end
  end
end
