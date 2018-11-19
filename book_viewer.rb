require "sinatra"
require "sinatra/reloader"

helpers do
  def in_paragraphs(text)
    paragraphs = text.split("\n\n")
    paragraphs.map.with_index { |paragraph, id| "<p id=#{id}>#{paragraph}</p>" }.join
  end

  def highlight(text, term)
    text.gsub(term, "<strong>#{term}</strong>")
  end
end

before do
  @contents = File.readlines('data/toc.txt')
end

get "/" do
  @title = 'The Adventures of Sherlock Holmes'

  erb :home
end

get "/chapter/:number" do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]

  redirect "/" unless (1..@contents.size).cover? number

  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end

def each_chapter
  @contents.each_with_index do |name, index|
    chapter_num = index + 1
    text = File.read("data/chp#{chapter_num}.txt")
    yield chapter_num, name, text
  end
end

def paragraphs_matching(text, query)
  results = []
  text.split("\n\n").each.with_index do |paragraph, id|
    results << { id: id, text: paragraph } if paragraph.include?(query)
  end
  results
end

def chapters_matching(query)
  results = []

  return results if !query || query.empty?

  each_chapter do |num, name, text|
    if text.include?(query)
      paragraphs = paragraphs_matching(text, query)
      results << { number: num, name: name, paragraphs: paragraphs }
    end
  end

  results
end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end

not_found do
  redirect "/"
end
