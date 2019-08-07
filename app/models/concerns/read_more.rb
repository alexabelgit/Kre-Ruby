module ReadMore
  require 'ostruct'
  extend ActiveSupport::Concern

  def read_more(attr, length: 100, ellipsis: false, highlights: true)
    OpenStruct.new ({ excerpt: self.read_more_excerpt(attr, length: length, ellipsis: ellipsis, highlights: highlights),
                      rest:    self.read_more_rest(   attr, length: length,                     highlights: highlights) })
  end

  def read_more?(attr, length: 100, highlights: true)
    self[attr].size > length && (!highlights || !self.has_highlights?(attr))
  end

  def read_more_excerpt(attr, length: , ellipsis: false, highlights: true)
    if self.read_more?(attr, length: length, highlights: highlights)
      feedback           = self[attr].dup
      excerpt, read_more = feedback.slice!(0...length), feedback
      excerpt += '…' if ellipsis
      excerpt
    else
      self[attr]
    end
  end

  def read_more_rest(attr, length: , highlights: true)
    if self.read_more?(attr, length: length, highlights: highlights)
      feedback           = self[attr].dup
      excerpt, read_more = feedback.slice!(0...length), feedback
      read_more
    else
      self[attr]
    end
  end
end
