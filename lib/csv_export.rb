class CsvExport
  attr_reader :vote_counts

  def initialize(vote_counts)
    @vote_counts = vote_counts
  end

  def to_csv
    headers = ['uuid', 'female', 'male', 'other', 'skip', 'total']
    rows = vote_counts.to_hash.map do |politician_id, votes|
      [
        politician_id,
        votes['female'],
        votes['male'],
        votes['other'],
        votes['skip'],
        votes.values.reduce(&:+)
      ]
    end
    CSV.generate do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
  end
end
