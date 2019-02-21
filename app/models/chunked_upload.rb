class ChunkedUpload < Upload
  has_many :chunks, foreign_key: 'upload_id'
end
